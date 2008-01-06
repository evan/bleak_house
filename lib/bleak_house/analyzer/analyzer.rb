
require 'ccsv'
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
        
    # Might be better as a per-tag skip but that gets kinda complicated
    initial_skip = (ENV['INITIAL_SKIP'] || 15).to_i
    INITIAL_SKIP = initial_skip < 2 ? 2 : initial_skip
    
    DISPLAY_SAMPLES = (ENV['DISPLAY_SAMPLES'] || 5).to_i
    
    CLASS_KEYS = eval('[nil, ' + # Skip 0 so that the output of String#to_s is useful
      open(
        File.dirname(__FILE__) + '/../../../ext/bleak_house/logger/snapshot.h'
      ).read[/\{(.*?)\}/m, 1] + ']')

    def self.backwards_detect(array)
      i = array.size - 1
      while i >= 0
        item = array[i]
        return item if yield(item)
        i -= 1
      end
    end   
    
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

        if total_frames < INITIAL_SKIP * 3
          puts "Not enough frames for accurate results. Please record at least #{INITIAL_SKIP * 3} frames."
          exit # Should be exit! but that messes up backticks capturing in the tests
        end
        
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
                frame['births'] = frame['objects'].slice(births).to_a # Work around a Marshal bug
                
                # assign deaths to previous frame
                if final = frames[-2]
                  final['deaths'] = final['objects'].slice(deaths).to_a # Work around a Marshal bug
                  obj_count = final['objects'].size
                  final.delete 'objects'
                  
                  4.times { GC.start } # Try to reduce memory footprint
                  
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
            # Not done with the frame, so assign this object to the object hash
            
            # Id
            value = [row[0]]            
            # Sample content, if it exists
            value << row[2].gsub(/0x[\da-f]{8}/, "0xID") if row[2]

            frame['objects'][row[1]] = value
          end
        end
        
        frames = frames[0..-2]       
        frames.last['objects'] = frames.last['objects'].to_a # Work around a Marshal bug on x86_64
        
        # Cache the result
        File.open(cachefile, 'w') do |f|
          f.write Marshal.dump(frames)
        end
        
      end
      
      puts "\nRehashing."
      
      # Convert births back to hashes, necessary due to the Marshal workaround    
      frames.each do |frame|
        frame['births_hash'] = {}
        frame['births'].each do |key, value|
          frame['births_hash'][key] = value
        end
        frame.delete('births')
      end

#      require 'ruby-debug'; Debugger.start
#      
#      debugger
                             
      # See what objects are still laying around
      population = frames.last['objects'].reject do |key, value|
        frames.first['births_hash'][key] and frames.first['births_hash'][key].first == value.first
      end

      puts "\n#{frames.size - 1} full frames. Removing #{INITIAL_SKIP} frames from each end of the run to account for\nstartup overhead and GC lag."

      # Remove border frames
      frames = frames[INITIAL_SKIP..-INITIAL_SKIP]
      
      total_births = frames.inject(0) do |births, frame|
        births + frame['births_hash'].size
      end
      total_deaths = frames.inject(0) do |deaths, frame|
        deaths + frame['deaths'].size
      end
      
      puts "\n#{total_births} total births, #{total_deaths} total deaths, #{population.size} uncollected objects."
      
      leakers = {}
      
#      debugger
      
      # Find the sources of the leftover objects in the final population
      population.each do |id, value|
        klass = value[0]
        content = value[1]
        leaker = backwards_detect(frames) do |frame|
          frame['births_hash'][id] and frame['births_hash'][id].first == klass
        end
        if leaker
#          debugger
          tag = leaker['meta']['tag']
          klass = CLASS_KEYS[klass] if klass.is_a? Fixnum
          leakers[tag] ||= Hash.new()
          leakers[tag][klass] ||= {:count => 0, :contents => []}
          leakers[tag][klass][:count] += 1
          leakers[tag][klass][:contents] << content if content
        end
      end      
      
      # Sort the leakers
      leakers = leakers.map do |tag, value|
        # Sort leakiest classes within each tag
        [tag, value.sort_by do |klass, hash| 
          -hash[:count]
        end]
      end.sort_by do |tag, value|
        # Sort leakiest tags as a whole
        Hash[*value.flatten].values.inject(0) {|i, hash| i - hash[:count]}
      end
      
      if leakers.any?
        puts "\nTags sorted by persistent uncollected objects. These objects did not exist at\nstartup, were instantiated by the associated tags during the run, and were\nnever garbage collected:"
        leakers.each do |tag, value|
          requests = frames.select do |frame|
            frame['meta']['tag'] == tag
          end.size
          puts "  #{tag} leaked per request (#{requests}):"
          value.each do |klass, hash|
            puts "    #{sprintf('%.1f', hash[:count] / requests.to_f)} #{klass}"
            
            # Extract most common samples
            contents = begin
              hist = Hash.new(0)
              hash[:contents].each do |content|
                hist[content] += 1 
              end
              hist.sort_by do |content, count| 
                -count
              end[0..DISPLAY_SAMPLES].select do |content, count|
                ENV['DISPLAY_SAMPLES'] or count > 5
              end
            end
            
            if contents.any?
              puts "      Inspection samples:"
              contents.each do |content, count|
                puts "        #{sprintf('%.1f', count / requests.to_f)} #{content}"
              end
            end

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

      puts "\nDone"

    end    
    
  end
end
