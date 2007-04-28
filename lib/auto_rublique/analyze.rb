
require 'rubygems'
require 'fileutils'
require 'gruff'
begin 
  require 'fjson'
rescue LoadError
  require 'json'
end

class AutoRublique
  class Analyze
    
    DIR = "#{RAILS_ROOT}/log/auto_rublique/"
    
    def initialize(data, increments, name)
      @data = data
      @increments = increments
      @name = name
    end 
    
    def draw
      g = Gruff::Line.new
      g.title = @name
      
      @data.each do |key, value|        
        g.data(key.to_s == "" ? 'unknown' : key.gsub(/.*::/, ''), value)
      end
      
      labels = {}
      mod = (@increments.size / 4.0).ceil
      @increments.each_with_index do |increment, index|
        labels[index] = increment.split(" ").last if (index % mod).zero?
      end
      g.labels = labels
      
      g.write(@name.to_filename + ".png")
    end
    
    def self.aggregate(data, selector, namer)
      aggregate_data = Hash.new([])
      increments = []
      data.each do |frameset|
        frameset.data.keys.select do |key| 
          key =~ selector
        end.each do |key| 
          aggregate_data[key[namer, 1]] = []
        end
      end
      data.each_with_index do |frameset, index|
        increments << frameset.time
        frameset.data.keys.each do |key|
          aggregate_key = key[namer, 1]
          # add the delta for this key or subkey
          aggregate_data[aggregate_key][index] = 
            aggregate_data[aggregate_key][index].to_i + frameset.data[key]
        end
        aggregate_data.keys.each do |aggregate_key|
          # add the previous value
          aggregate_data[aggregate_key][index] = 
            aggregate_data[aggregate_key][index].to_i + aggregate_data[aggregate_key][index - 1].to_i
        end
      end
      [aggregate_data, increments]
    end
    
    def self.build_all(filename)
      unless File.exists? filename
        puts "No data file found: #{filename}"
        exit 
      end
      FileUtils.rm_r(DIR) rescue nil
      Dir.mkdir(DIR)

      Dir.chdir(DIR) do        
        puts "Parsing data"
        data = []
        # need to flatten the namespace
        JSON.parse("[" + File.open(filename).readlines.join(", ") + "]").each do |frameset|
          subframes = {}
          frameset.data.map do |key, value|
            value.each do |object_key, count|
              subframes["#{key}::::#{object_key}"] = count
            end  
          end
          data << [frameset.time, subframes]
        end        
        
        puts "By controller"
        controller_data, increments = aggregate data, //, /^(.*?)($|\/|::::)/
        Analyze.new(controller_data, increments, "objects per controller").draw
        
        # in each controller, by action
        puts "By action"
        controller_data.keys.each do |controller|
          puts "  ...in #{controller} controller"
          Dir.descend(controller) do             
            action_data, increments = aggregate data, /^#{controller}($|\/)/, /\/(.*?)($|\/|::::)/
            Analyze.new(action_data, increments, "objects per action in /#{controller}").draw
          
          # in each action, by object class
          action_data.keys.each do |action|
            next if action.to_s == ""
            puts "    ... in #{action} action"
            Dir.descend(action) do
              class_data, increments = aggregate data, /^#{controller}\/#{action}($|\/|::::)/, /::::(.*)/
              Analyze.new(class_data, increments, "objects per class in /#{controller}/#{action}").draw
            end
          end
          
          end          
        end
      end    
    end 
    
  end
end

class Array
  alias :time :first
  alias :data :last
end

class Dir
  def self.descend path, &block
    path = path.split("/") unless path.is_a? Array
    top = path.shift
    Dir.mkdir(top) unless File.exists? top
    Dir.chdir(top) do
      if path.any?
        descend path, &block
      else
        block.call
      end
    end
  end
end

class String
  def to_filename
    self.downcase.gsub(/[^\w\d\-]/, '_')
  end
end

