
require 'rubygems'
require 'fileutils'
require 'base64'

gem 'gruff', '= 0.2.8'
require 'gruff'

require "#{File.dirname(__FILE__)}/gruff_hacks"
require "#{File.dirname(__FILE__)}/support_methods"

Gruff::Base::LEFT_MARGIN = 200
Gruff::Base::NEGATIVE_TOP_MARGIN = 30
Gruff::Base::MAX_LEGENDS = 28

class BleakHouse
  class Analyze    
    
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
        name = if key.to_s == ""
          '[Unknown]' 
        else
#        elsif key =~ Regexp.new(@specials.keys.join('|'))
#          name = "#{key} (#{values.to_i.max / (2**10)} MB)"
#          @specials.each do |regex, scale|
#            values.map! {|x| x * scale} if key =~ regex
#          end              
#        else
          "#{key.gsub(/.*::/, '')} (#{values.to_i.max})"
        end
        [name, values]
      end.sort_by do |key, values|
        0 - key[/.*?([\d]+)\)$/, 1].to_i
      end.each do |key, values|
        g.data(key, values)
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

        puts "Parsing data"
        data = File.open(filename).readlines.map do |line|
          Marshal.load Base64.decode64(line)
        end
        
#        data_maximum = data.flatten.inject(0) do |max, el|
#          if el.is_a? Hash
#            current_max = el.merge({:"real memory" => 0, :"virtual memory" => 0}).values.to_i.max
#            current_max if max < current_max
#          end or max
#        end
#        mem_maximum = data.flatten.inject(0) do |max, el| # only real memory (RSS) for now
#          (el["real memory"] if el.is_a?(Hash) and max < el["real memory"]) or max
#        end
#        mem_scale = data_maximum / mem_maximum.to_f
#        scales = {/memory$/ => mem_scale}
        
        puts "By controller"
        controller_data, increments = aggregate(data, //, /^(.*?)($|\/|::::)/)
        Analyze.new(controller_data, increments, "objects by controller").draw
                
        # in each controller, by action
        puts "By action"
        controller_data.keys.each do |controller|
          puts "  ...in #{controller} controller"
          Dir.descend(controller) do             
            action_data, increments = aggregate(data, /^#{controller}($|\/|::::)/, /\/(.*?)($|\/|::::)/)
            Analyze.new(action_data, increments, "objects by action in /#{controller}").draw
          
          # in each action, by object class
          action_data.keys.each do |action|
            action = "unknown" if action.to_s == ""
            puts "    ...in #{action} action"
            Dir.descend(action) do
              class_data, increments = aggregate(data, /^#{controller}#{"\/#{action}" unless action == "unknown"}($|\/|::::)/, 
                /::::(.*)/)
              Analyze.new(class_data, increments, "objects by class in /#{controller}/#{action}").draw
            end
          end
          
          end          
        end
      end    
    end 
    
  end
end
