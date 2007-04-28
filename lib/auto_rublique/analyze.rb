
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
        g.data key, value
      end
      
      labels = {}
      mod = (@increments.size / 4.0).ceil
      @increments.each_with_index do |increment, index|
        labels[index] = increment.split(" ").last if (index % mod).zero?
      end
      g.labels = labels
      
      g.write(filename = @name.to_filename + ".png")
      puts "Wrote \"#{filename}\""    
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
        data = JSON.parse("[" + File.open(filename).readlines.join(", ") + "]")
        
        # by controller
        controller_data = Hash.new([])
        increments = []
        data.each do |frameset|
          frameset.data.keys.each do |controller|            
            controller_data[controller.gsub(/\/.*$/, '')] = []
          end
        end
        data.each do |frameset|
          increments << frameset.time
          remaining_keys = controller_data.keys
          frameset.data.keys.each do |key|
            controller = key.gsub(/\/.*$/, '')
            # add the delta
            controller_data[controller] << (frameset.data[key].values.inject(0) {|sum, x| sum + x} + controller_data[controller].last.to_i)
            remaining_keys.delete controller              
          end
          remaining_keys.each do |controller|
            # or no change
            controller_data[controller] << controller_data[controller].last.to_i
          end
        end
        Analyze.new(controller_data, increments, "objects per controller").draw
        
        # in each controller, by action
        this_data = Hash.new(0)
        
        # in each action, by method and object class
        this_data = Hash.new(0)      
        
    
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

