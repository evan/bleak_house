
require 'rubygems'
require 'fileutils'
require 'base64'

gem 'gruff', '= 0.2.8'
require 'gruff'

# require, but make rdoc not whine
load "#{File.dirname(__FILE__)}/gruff_hacks.rb"
load "#{File.dirname(__FILE__)}/support_methods.rb"

Gruff::Base::LEFT_MARGIN = 200
Gruff::Base::NEGATIVE_TOP_MARGIN = 30
Gruff::Base::MAX_LEGENDS = 28

class BleakHouse
  class Analyze    
  
    MEM_KEY = "memory usage"
    
    DIR = "#{RAILS_ROOT}/log/bleak_house/"
    
    def initialize(data, increments, name)
      @data = data
      @increments = increments
      @name = name
    end 
    
    def draw    
      g = Gruff::Line.new("1024x768")
      g.title = @name
      g.x_axis_label = "time"
      g.legend_font_size = g.legend_box_size = 14
      g.title_font_size = 24
      g.marker_font_size = 14
            
      @data.map do |key, values|        
        ["#{(key.to_s.empty? ? '[Unknown]' : key).gsub(/.*::/, '')} (#{key == MEM_KEY ? "relative" : values.to_i.max})", values] # hax
      end.sort_by do |key, values|
        0 - key[/.*?([\d]+)\)$/, 1].to_i
      end.each do |key, values|
        g.data(key, values.to_i)
      end
      
      labels = {}
      mod = (@increments.size / 4.0).ceil
      @increments.each_with_index do |increment, index|
        labels[index] = increment.split(" ").last if (index % mod).zero?
      end
      g.labels = labels
      
      g.minimum_value = 0
#      g.maximum_value = @maximum
      
      g.write(@name.to_filename + ".png")
    end
    
    def self.aggregate(data, selector, namer)
      aggregate_data = {}
      increments = []
      data.each_with_index do |frameset, index|
        increments << frameset.time
        frameset.data.keys.select do |key| 
          key =~ selector #or key =~ Regexp.new(specials.keys.join('|'))
        end.each do |key|
          aggregate_data[key.to_s[namer, 1]] ||= []
          aggregate_data[key.to_s[namer, 1]][index] += frameset.data[key].to_i
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

        puts "parsing data"
        data = File.open(filename).readlines.map do |line|
          Marshal.load Base64.decode64(line)
        end
        
        puts "entire app"
        controller_data, increments = aggregate(data, //, /^(.*?)($|\/|::::)/)
        if controller_data.has_key? MEM_KEY
          controller_data_without_memory = controller_data.dup
          controller_data_without_memory.delete(MEM_KEY)
          scale_factor = controller_data_without_memory.values.flatten.to_i.max / controller_data[MEM_KEY].max.to_f * 0.8 rescue 1
          controller_data[MEM_KEY] = controller_data[MEM_KEY].map{|x| (x * scale_factor).to_i }
        end
        Analyze.new(controller_data, increments, "objects by controller").draw
                
        # in each controller, by action
        controller_data.keys.each do |controller|
          @mem = (controller == MEM_KEY)
          puts(@mem ? "  #{controller}" : "  action for #{controller} controller")
          Dir.descend(controller) do             
            action_data, increments = aggregate(data, /^#{controller}($|\/|::::)/, /\/(.*?)($|\/|::::)/)
            Analyze.new(action_data, increments, @mem ?  "#{controller} in kilobytes" : "objects by action in /#{controller}_controller").draw          
          
            # in each action, by object class
            action_data.keys.each do |action|
              action = "unknown" if action.to_s == ""
              puts "    class for #{action} action"
              Dir.descend(action) do
                class_data, increments = aggregate(data, /^#{controller}#{"\/#{action}" unless action == "unknown"}($|\/|::::)/, 
                  /::::(.*)/)
                Analyze.new(class_data, increments, "objects by class in /#{controller}/#{action}").draw
              end
            end unless @mem
          
          end          
        end
      end    
    end 
    
  end
end
