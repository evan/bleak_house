
require 'rubygems'
require 'fileutils'
require 'yaml'
require 'active_support'

gem 'gruff', '= 0.2.8'
require 'gruff'

# require, but make rdoc not whine
load "#{File.dirname(__FILE__)}/gruff_hacks.rb"
load "#{File.dirname(__FILE__)}/support_methods.rb"

Gruff::Base.send(:remove_const, "LEFT_MARGIN") # silence a warning
Gruff::Base::LEFT_MARGIN = 200
Gruff::Base::NEGATIVE_TOP_MARGIN = 30
Gruff::Base::MAX_LEGENDS = 28

class BleakHouse
  # Draws the BleakHouse graphs.
  class Analyze    
  
    SMOOTHNESS = ENV['SMOOTHNESS'].to_i.zero? ? 1 : ENV['SMOOTHNESS'].to_i
    MEM_KEY = "memory usage"
    HEAP_KEY = "heap usage"
    CORE_KEY = "core rails"
    
    # Sets up a single graph.
    def initialize(data, increments, name)
      @data = data
      @increments = increments
      @name = name
    end 
    
    def d #:nodoc:
      self.class.d
    end
    
    # Draw <tt>self</tt>. Use some special attributes added to Gruff.  Requires the overrides in <tt>gruff_hacks.rb</tt>.
    def draw #:nodoc:
      g = Gruff::Line.new("1024x768")
      g.title = @name
      g.x_axis_label = "time"
      g.legend_font_size = g.legend_box_size = 14
      g.title_font_size = 24
      g.marker_font_size = 14
       
      # mangle some key names.
      # XXX unreadable
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
    
    # Takes subkeys that match the <tt>selector</tt> regex and adds each subkey's count to the key named by the first group match in the <tt>namer</tt> regex for that subkey.
    def self.aggregate(data, selector = //, namer = //) #:nodoc:
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
        
    # Generates a chart for each tag (by subtag) and subtag (by object type). Output is written to <tt>bleak_house/</tt> in the same folder as the passed <tt>logfile</tt> attribute.
    def self.build_all(logfile)
      unless File.exists? logfile
        puts "No data file found: #{logfile}"
        exit 
      end 
      puts "parsing data"
      data = YAML.load_file(logfile)                
 
      rootdir = File.dirname(logfile) + "/bleak_house/"     
      FileUtils.rm_r(rootdir) rescue nil
      Dir.mkdir(rootdir)      
      Dir.chdir(rootdir) do        
        
        labels = []
        
        # autodetect need for Rails snapshot conflation
        if data.first.last.keys.first =~ /^#{CORE_KEY}::::/
          # Rails snapshots double-count objects that start in the core and persist through the action (which is most core objects), so we need to the subtract core counts from action counts
          data = data[0..(-1 - data.size % 2)]
          data = data.in_groups_of(2).map do |frames|
            core, action = frames.first, frames.last
            action.data.each do |key, value|
              action.data[key] = value - core.data[key[/::::(.*)/,1]].to_i
            end          
            [action.time, core.data.merge(action.data)]
          end
          puts "  conflated core rails snapshots with their actions"
          labels = ["controller", "action"]
        else
          puts "  assuming custom snapshotting"
          labels = ["tag", "subtag"]
        end
                
        # smooth frames (just an average)
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
        puts "  #{data.size} frames after smoothing"
        
        # scale memory/heap frames
        controller_data, increments = aggregate(data, //, /^(.*?)($|\/|::::)/)
        controller_data_without_specials = controller_data.dup
        controller_data_without_specials.delete(MEM_KEY)
        controller_data_without_specials.delete(HEAP_KEY)
        [HEAP_KEY, MEM_KEY].each do |key|
          scale_factor = controller_data_without_specials.values.flatten.to_i.max / controller_data[key].max.to_f * 0.8 rescue 1
          controller_data[key] = controller_data[key].map{|x| (x * scale_factor).to_i }
        end
        
        # generate initial controller graph        
        puts(title = "objects by #{labels[0]}")
        Analyze.new(controller_data, increments, title).draw

        # in each controller, by action
        controller_data.keys.each do |controller|
#          next unless controller == HEAP_KEY
          @mem = [MEM_KEY, HEAP_KEY].include? controller
          @core = [CORE_KEY].include? controller
          Dir.descend(controller) do             
            action_data, increments = aggregate(data, /^#{controller}($|\/|::::)/, /\/(.*?)($|\/|::::)/)
            unless @core
              puts("  " + (title = case controller
                when MEM_KEY then "#{controller} in kilobytes" 
                when HEAP_KEY then "#{controller} in slots"
                else "objects by #{labels[1]} in /#{controller}/"
              end))
              Analyze.new(action_data, increments, title).draw
            end
           
            # in each action, by object class
            action_data.keys.each do |action|
              action = "unknown" if action.to_s == ""
              Dir.descend(@core ? "." : action) do
                puts((@core ? "  " : "    ") + (title = "objects by class in #{@core ? CORE_KEY : "/#{controller}/#{action}"}"))
                class_data, increments = aggregate(data, /^#{controller}#{"\/#{action}" unless action == "unknown"}($|\/|::::)/, 
                  /::::(.*)/)
                Analyze.new(class_data, increments, title).draw
              end
            end unless @mem
          
          end          
        end
      end    
    end 
    
    def self.d #:nodoc:
      require 'ruby-debug'; Debugger.start; debugger
    end
        
  end
end
