
require 'rubygems'
require 'fileutils'
require 'yaml'
require 'active_support'

$LOAD_PATH << File.dirname(__FILE__)

Gruff::Base.send(:remove_const, "LEFT_MARGIN") # silence a warning
Gruff::Base::LEFT_MARGIN = 200
Gruff::Base::NEGATIVE_TOP_MARGIN = 30
Gruff::Base::MAX_LEGENDS = 28

module BleakHouse
  # Draws the BleakHouse graphs.
  class Analyze    
  
    MAGIC_KEYS = {
      -1 => 'timestamp',
      -2 => 'mem usage/swap',
      -3 => 'mem usage/real',
      -4 => 'tag',
      -5 => 'heap/filled',
      -6 => 'heap/free'
    }
    
    REVERSE_MAGIC_KEYS = MAGIC_KEYS.invert
    
    MAX_LIFE = 2 # For Rails
    
    CLASS_KEYS = eval('[' + open(
        File.dirname(__FILE__) + '/../../../ext/bleak_house/logger/snapshot.h'
      ).read[/\{(.*?)\}/m, 1] + ']')
    
    # Sets up a single graph.
    def initialize(data, increments, name)
      @data = data
      @increments = increments
      @name = name
    end 
    
    def d #:nodoc:
      self.class.d
    end
    
    # Draw <tt>self</tt>. Use some special attributes added to Gruff.
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
    
        
    # Generates a chart for each tag (by subtag) and subtag (by object type). Output is written to <tt>bleak_house/</tt> in the same folder as the passed <tt>logfile</tt> attribute.
    def self.build_all(logfile)
      unless File.exists? logfile
        puts "No data file found: #{logfile}"
        exit 
      end 
            
      frames = []
      frame = nil
      
      puts "Parsing"
      
      LightCsv.foreach(logfile) do |row|        
        if row[0] < 0          
          # Get frame meta-information
          if MAGIC_KEYS[row[0]] == 'timestamp'
            # The frame has ended
            # Remove any object that has died from the last MAX_LIFE frames
            live_objects = frames[-1]['objects'].keys
            frames[-2-MAX_LIFE..-2].each do |frame|
              frame['objects'].slice!(keys)
            end

            # Set up a new frame
            frame = {}
            frames << frame
            frame['objects'] ||= {}
            frame['meta'] ||= {}
          end
          
          frame['meta'][MAGIC_KEYS[row[0]]] = row[1]
        else
          # Assign live objects
          frame['objects'][row[1]] = row[0]
        end
      end
      
      # Find all tags
      tags = frames.map do |frame|
        frame['meta']['tag']
      end
      
      # Recursively descend and graph each tagset
      
      
      rootdir = File.dirname(logfile) + "/bleak_house/"     
      FileUtils.rm_r(rootdir) rescue nil
      Dir.mkdir(rootdir)      
      Dir.chdir(rootdir) do        
        
      end
      
    end 
    
    def self.d #:nodoc:
      require 'ruby-debug'; Debugger.start; debugger
    end
        
  end
end
