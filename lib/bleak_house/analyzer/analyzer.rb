
require 'rubygems'
require 'fileutils'
require 'yaml'
require 'pp'

$LOAD_PATH << File.dirname(__FILE__)

Gruff::Base.send(:remove_const, "LEFT_MARGIN") # silence a warning
Gruff::Base::LEFT_MARGIN = 200
Gruff::Base::NEGATIVE_TOP_MARGIN = 30
Gruff::Base::MAX_LEGENDS = 28

module BleakHouse

  class Analyzer 
  
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
    
    CLASS_KEYS = eval('[nil, ' + # skip 0
      open(
        File.dirname(__FILE__) + '/../../../ext/bleak_house/logger/snapshot.h'
      ).read[/\{(.*?)\}/m, 1] + ']')
            
    # Generates a chart for each tag (by subtag) and subtag (by object type). Output is written to <tt>bleak_house/</tt> in the same folder as the passed <tt>logfile</tt> attribute.
    def self.build_all(logfile)
      unless File.exists? logfile
        puts "No data file found: #{logfile}"
        exit 
      end 
            
      frames = []
      last_population = []
      frame = nil
      ix = nil
      
      puts "Examining objects"
      
      LightCsv.foreach(logfile) do |row|        
      
        # Stupid is fast
        row[0] = row[0].to_i if row[0].to_i != 0
        row[1] = row[1].to_i if row[1].to_i != 0
        
        if row[0].to_i < 0          
          # Get frame meta-information
          if MAGIC_KEYS[row[0]] == 'timestamp'

            # The frame has ended; process the last one            
            if frame
              population = frame['objects'].keys
              births = population - last_population
              deaths = last_population - population
              last_population = population
  
              # assign births
              frame['births'] = frame['objects'].slice(births)

              if final = frames[-2]
                final['deaths'] = final['objects'].slice(deaths)
                bsize = final['births'].size
                dsize = final['deaths'].size
                final['velocity'] = bsize * 100 / dsize / 100.0
                puts "  Frame #{frames.size - 1} finalized: #{bsize} births, #{dsize} deaths, velocity #{final['velocity']}, population #{final['objects'].size}"
                final.delete 'objects'
              end
            end

            # Set up a new frame
            frame = {}
            frames << frame
            frame['objects'] ||= {}
            frame['meta'] ||= {}
            
            #puts "  Frame #{frames.size} opened"
          end
          
          frame['meta'][MAGIC_KEYS[row[0]]] = row[1]
        else
          # Assign live objects
          frame['objects'][row[1]] = row[0]
        end
      end
            
      # See what objects are still laying around
      population = frames.last['objects'].reject do |key, value|
        frames.first['births'][key] == value
      end

      # Remove bogus frames
      frames = frames[1..-2]       
      
      total_births = frames.inject(0) do |births, frame|
        births + frame['births'].size
      end
      total_deaths = frames.inject(0) do |deaths, frame|
        deaths + frame['deaths'].size
      end
      
      puts "#{total_births} total births, #{total_deaths} total deaths."
      
      leakers = {}
      
      # Find the sources of the leftover objects in the final population
      population.each do |id, klass|
        leaker = frames.detect do |frame|
          frame['births']['id'] == klass
        end['tag']
        klass = CLASS_KEYS[klass] if klass.is_a? Fixnum
        leakers[leaker] ||= Hash.new(0)
        leakers[leaker][klass] += 1
      end
      
      leakers.map do |tag, value| 
        [tag, value.sort_by do |klass, count| 
          -count
        end]
      end.sort_by do |tag, value|
        -Hash[*value.flatten].values.inject(0) {|i, v| i + v}
      end
      
      puts "\nHere are your leaks:\n"
      leakers.each do |tag, value|
        puts "  #{tag} leaked:"
        value.each do |klass, count|
          puts "    #{count} #{klass}s"
        end
      end      
      puts "\nBye"
      
    end
    
  end
end
