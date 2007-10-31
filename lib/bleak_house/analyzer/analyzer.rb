
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
        
    INITIAL_SKIP = 15
    
    CLASS_KEYS = eval('[nil, ' + # skip 0
      open(
        File.dirname(__FILE__) + '/../../../ext/bleak_house/logger/snapshot.h'
      ).read[/\{(.*?)\}/m, 1] + ']')
    
    def self.calculate!(frame, index, total, obj_count = nil)
      bsize = frame['births'].size
      dsize = frame['deaths'].size
      
      # Avoid divide by zero errors
      frame['meta']['ratio'] = ratio = (bsize - dsize) / (bsize + dsize + 1).to_f
      frame['meta']['impact'] = begin
        result = Math.log10((bsize - dsize).abs.to_i / 10.0)
        raise Errno::ERANGE if result.nan? or result.infinite?
        result
      rescue Errno::ERANGE
        0
      end
      
      puts "  F#{index}:#{total} (#{index * 100 / total}%): #{frame['meta']['tag']} (#{obj_count.to_s + ' population, ' if obj_count}#{bsize} births, #{dsize} deaths, ratio #{format('%.2f', frame['meta']['ratio'])}, impact #{format('%.2f', frame['meta']['impact'])})"
    end
    
    # Parses and correlates a BleakHouse::Logger output file.
    def self.run(logfile)
      logfile.chomp!(".cache")
      cachefile = logfile + ".cache"

      unless File.exists? logfile or File.exists? cachefile
        puts "No data file found: #{logfile}"
        exit 
      end
      
      puts "Working..."
      
      frames = []
      last_population = []
      frame = nil
      ix = nil
      
      if File.exist?(cachefile) and (!File.exists? logfile or File.stat(cachefile).mtime > File.stat(logfile).mtime)
        # Cache is fresh
        puts "Using cache"
        frames = Marshal.load(File.open(cachefile).read)
        puts "#{frames.size - 1} frames"        
        frames[0..-2].each_with_index do |frame, index|
          calculate!(frame, index + 1, frames.size - 1)
        end
        
      else                        
        # Rebuild frames
        total_frames = `grep '^-1' #{logfile} | wc`.to_i - 2
        
        puts "#{total_frames} frames"     
        
        Ccsv.foreach(logfile) do |row|                
        
          # Stupid is fast
          i = row[0].to_i
          row[0] = i if i != 0
          i = row[1].to_i
          row[1] = i if i != 0
          
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
                frame['births'] = frame['objects'].slice(births).to_a # XXX Work around a Marshal bug
                
                # assign deaths to previous frame
                if final = frames[-2]
                  final['deaths'] = final['objects'].slice(deaths).to_a # XXX Work around a Marshal bug
                  obj_count = final['objects'].size
                  final.delete 'objects'
                  calculate!(final, frames.size - 1, total_frames, obj_count)
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
        
        frames = frames[0..-2]       
        frames.last['objects'] = frames.last['objects'].to_a # XXX Work around a Marshal bug
        
        # Cache the result
        File.open(cachefile, 'w') do |f|
          f.write Marshal.dump(frames)
        end
        
      end
                             
      # See what objects are still laying around
      population = frames.last['objects'].reject do |key, value|
        frames.first['births'][key] == value
      end      

      puts "\n#{frames.size - 1} full frames. Removing #{INITIAL_SKIP} frames from each end of the run to account for\nstartup overhead and GC lag."

      # Remove border frames
      frames = frames[INITIAL_SKIP..-INITIAL_SKIP]
      
      total_births = frames.inject(0) do |births, frame|
        births + frame['births'].size
      end
      total_deaths = frames.inject(0) do |deaths, frame|
        deaths + frame['deaths'].size
      end
      
      puts "\n#{total_births} total births, #{total_deaths} total deaths, #{population.size} uncollected objects."
      
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
      
      if leakers.any?
        puts "\nTags sorted by persistent uncollected objects. These objects did not exist at\nstartup, were instantiated by the associated tags, but were never garbage\ncollected:"
        leakers.each do |tag, value|
          requests = frames.select do |frame|
            frame['meta']['tag'] == tag
          end.size
          puts "  #{tag} leaked (over #{requests} requests):"
          value.each do |klass, count|
            puts "    #{count} #{klass}"
          end
        end
      else
        puts "\nNo persistent uncollected objects found for any tags."
      end
            
      impacts = {}
      
      frames.each do |frame|
        impacts[frame['meta']['tag']] ||= []
        impacts[frame['meta']['tag']] << frame['meta']['impact'] * frame['meta']['ratio']
      end      
      impacts = impacts.map do |tag, values|
        [tag, values.inject(0) {|acc, i| acc + i} / values.size.to_f]
      end.sort_by do |tag, impact|
        impact.nan? ? 0 : -impact
      end
      
      puts "\nTags sorted by average impact * ratio. Impact is the log10 of the size of the"
      puts "change in object count for a frame:"
      
      impacts.each do |tag, total|
        puts "  #{format('%.4f', total).rjust(7)}: #{tag}"
      end
    end
    
  end
end
