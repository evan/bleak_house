
require 'rubygems'
require 'fileutils'
require 'yaml'
require 'pp'
require 'ruby-debug'

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
    
    CLASS_KEYS = eval('[nil, ' + # skip 0
      open(
        File.dirname(__FILE__) + '/../../../ext/bleak_house/logger/snapshot.h'
      ).read[/\{(.*?)\}/m, 1] + ']')
            
    # Parses and correlates a BleakHouse::Logger output file.
    def self.run(logfile)
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
      frames = frames[1..-3]       
      
      total_births = frames.inject(0) do |births, frame|
        births + frame['births'].size
      end
      total_deaths = frames.inject(0) do |deaths, frame|
        deaths + frame['deaths'].size
      end
      
      puts "#{total_births} total meaningful births, #{total_deaths} total meaningful deaths.\n\n"
      
      leakers = {}
      
      # Find the sources of the leftover objects in the final population
      population.each do |id, klass|
        leaker = frames.detect do |frame|
          frame['births'][id] == klass
        end
        if leaker
          tag = leaker['meta']['tag']
          klass = CLASS_KEYS[klass] if klass.is_a? Fixnum
          leakers[tag] ||= Hash.new(0)
          leakers[tag][klass] += 1
        end
      end
      
      # Sort
      leakers = leakers.map do |tag, value| 
        [tag, value.sort_by do |klass, count| 
          -count
        end]
      end.sort_by do |tag, value|
        Hash[*value.flatten].values.inject(0) {|i, v| i - v}
      end
      
      puts "Here are your leaks:"
      leakers.each do |tag, value|
        puts "  #{tag} leaked:"
        value.each do |klass, count|
          puts "    #{count} #{klass}"
        end
      end      
      puts "\nBye"

    end
    
  end
end
