
require 'rubygems'
require 'fileutils'
require 'yaml'
require 'active_support'

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
  
    SMOOTHNESS = ENV['SMOOTHNESS'].to_i.zero? ? 1 : ENV['SMOOTHNESS'].to_i
    MEM_KEY = "memory usage"
    HEAP_KEY = "heap usage"
    DIR = "#{RAILS_ROOT}/log/bleak_house/"
    
    def initialize(data, increments, name)
      @data = data
      @increments = increments
      @name = name
    end 
    
    def d
      self.class.d
    end
    
    def draw    
      g = Gruff::Line.new("1024x768")
      g.title = @name
      g.x_axis_label = "time"
      g.legend_font_size = g.legend_box_size = 14
      g.title_font_size = 24
      g.marker_font_size = 14
            
      @data.map do |key, values|        
        ["#{(key.to_s.empty? ? '[Unknown]' : key).gsub(/.*::/, '')} (#{ if 
          [MEM_KEY, HEAP_KEY].include?(key) 
            'relative'
          else
            values.to_i.max
          end })", values] # hax
      end.sort_by do |key, values|
        0 - key[/.*?([\d]+)\)$/, 1].to_i
      end.each do |key, values|
        g.data(key, values.to_i)
      end
      
      labels = {}
      mod = (@increments.size / 4.0).ceil
      @increments.each_with_index do |increment, index|
        labels[index] = increment if (index % mod).zero?
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
          # aggregate common keys based on the selection regexs
          key =~ selector
        end.each do |key|
          aggregate_data[key.to_s[namer, 1]] ||= []
          aggregate_data[key.to_s[namer, 1]][index] += frameset.data[key].to_i
        end
      end
      aggregate_data.each do |key, value|
        # extend the length of every value set to the end of the run
        aggregate_data[key][increments.size - 1] ||= nil
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
        data = YAML.load_file(filename)                
        
        # subtract core counts from action
        data = data[0..(-1 - data.size % 2)]
        data = data.in_groups_of(2).map do |frames|
          core, action = frames.first, frames.last
          action.data.each do |key, value|
            action.data[key] = value - core.data[key[/::::(.*)/,1]].to_i
          end          
          [action.time, core.data.merge(action.data)]
        end
                
        # smooth
        data = data[0..(-1 - data.size % SMOOTHNESS)]
        data = data.in_groups_of(SMOOTHNESS).map do |frames|
          timestamp = frames.map(&:time).sum / SMOOTHNESS
          values = frames.map(&:data).inject(Hash.new(0)) do |total, this_frame|
            this_frame.each do |key, value|
              total[key] += value / SMOOTHNESS.to_f
            end
          end
          [Time.at(timestamp).strftime("%H:%M:%S"), values]
        end                     
        puts "#{data.size} frames after smoothing"
        
        # generate initial controller graph
        puts "entire app"
        
        controller_data, increments = aggregate(data, //, /^(.*?)($|\/|::::)/)
        controller_data_without_specials = controller_data.dup
        controller_data_without_specials.delete(MEM_KEY)
        controller_data_without_specials.delete(HEAP_KEY)
        [HEAP_KEY, MEM_KEY].each do |key|
#          next unless controller_data[key]
          scale_factor = controller_data_without_specials.values.flatten.to_i.max / controller_data[key].max.to_f * 0.8 rescue 1
          controller_data[key] = controller_data[key].map{|x| (x * scale_factor).to_i }
        end
        Analyze.new(controller_data, increments, "objects by controller").draw

        # in each controller, by action
        controller_data.keys.each do |controller|
#          next unless controller == HEAP_KEY
          @special = [MEM_KEY, HEAP_KEY].include? controller
          puts(@special ? "  #{controller}" : "  action for #{controller} controller")
          Dir.descend(controller) do             
            action_data, increments = aggregate(data, /^#{controller}($|\/|::::)/, /\/(.*?)($|\/|::::)/)
            Analyze.new(action_data, increments, case controller
              when MEM_KEY then "#{controller} in kilobytes" 
              when HEAP_KEY then "#{controller} in slots"
              else "objects by action in /#{controller}_controller"
            end).draw          
          
            # in each action, by object class
            action_data.keys.each do |action|
              action = "unknown" if action.to_s == ""
              puts "    class for #{action} action"
              Dir.descend(action) do
                class_data, increments = aggregate(data, /^#{controller}#{"\/#{action}" unless action == "unknown"}($|\/|::::)/, 
                  /::::(.*)/)
                Analyze.new(class_data, increments, "objects by class in /#{controller}/#{action}").draw
              end
            end unless @special
          
          end          
        end
      end    
    end 
    
    def self.d
      require 'ruby-debug'; Debugger.start; debugger
    end
        
  end
end
