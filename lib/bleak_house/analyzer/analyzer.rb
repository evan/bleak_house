
require 'rubygems'
require 'fileutils'
require 'yaml'
require 'pp'

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
    
    INITIAL_SKIP = 10
    
    CLASS_KEYS = eval('[nil, ' + # skip 0
      open(
        File.dirname(__FILE__) + '/../../../ext/bleak_house/logger/snapshot.h'
      ).read[/\{(.*?)\}/m, 1] + ']')
    
    def self.calculate!(frame, index, total)
      bsize = frame['births'].size
      dsize = frame['deaths'].size
      
      # Avoid divide by zero errors
      frame['meta']['ratio'] = ratio = (bsize - dsize) / (bsize + dsize + 1).to_f
      frame['meta']['impact'] = begin
        Math.log10((bsize - dsize).abs.to_i / 10.0)
      rescue Errno::ERANGE
        0
      end
      
      puts "  #{index * 100 / total}%: #{frame['meta']['tag']} (#{bsize} births, #{dsize} deaths, ratio #{format('%.2f', frame['meta']['ratio'])}, impact #{format('%.2f', frame['meta']['impact'])})"
    end
    
    # Parses and correlates a BleakHouse::Logger output file.
    def self.run(logfile)
      unless File.exists? logfile
        puts "No data file found: #{logfile}"
        exit 
      end
      
      puts "Working..."
      
      cachefile = logfile + ".cache"
      frames = []
      last_population = []
      frame = nil
      ix = nil
      
      if File.exist?(cachefile) and File.stat(cachefile).mtime > File.stat(logfile).mtime
        # Cache is fresh
        puts "Using cache"
        frames = Marshal.load(File.open(cachefile).read)
        
        puts "#{frames.size} frames"
        
        frames[0..-3].each_with_index do |frame, index|
          calculate!(frame, index + 1, frames.size - 1)
        end
        
      else                        
        # Rebuild frames
        total_frames = `grep '^-1' #{logfile} | wc`.to_i
        
        puts "#{total_frames} frames"     
        
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
                
                # assign deaths to previous frame
                if final = frames[-2]
                  final['deaths'] = final['objects'].slice(deaths)
                  final.delete 'objects'
                  calculate!(final, frames.size - 1, total_frames)
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
        
        # Cache the result
        File.open(cachefile, 'w') do |f|
          f.write Marshal.dump(frames)
        end
        
      end
            
      # See what objects are still laying around
      population = frames.last['objects'].reject do |key, value|
        frames.first['births'][key] == value
      end

      # Remove bogus frames
      frames = frames[INITIAL_SKIP..-3]       
      
      total_births = frames.inject(0) do |births, frame|
        births + frame['births'].size
      end
      total_deaths = frames.inject(0) do |deaths, frame|
        deaths + frame['deaths'].size
      end
      
      puts "\n#{total_births} births, #{total_deaths} deaths."
      
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
      
      puts "\nTags sorted by immortal leaks:"
      leakers.each do |tag, value|
        puts "  #{tag} leaked per request:"
        requests = frames.select do |frame|
          frame['meta']['tag'] == tag
        end.size
        value.each do |klass, count|
          count = count/requests          
          puts "    #{count} #{klass}" if count > 0
        end
      end
            
      impacts = {}
      
      frames.each do |frame|
        impacts[frame['meta']['tag']] ||= []
        impacts[frame['meta']['tag']] << frame['meta']['impact'] * frame['meta']['ratio']
      end      
      impacts = impacts.map do |tag, values|
        [tag, values.inject(0) {|acc, i| acc + i} / values.size.to_f]
      end.sort_by do |tag, impact|
        -impact
      end
      
      puts "\nTags sorted by impact ratio:"
      
      impacts.each do |tag, total|
        puts "  #{tag}: #{format('%2f', total)}"
      end

      puts "\nBye"

    end
    
  end
end
