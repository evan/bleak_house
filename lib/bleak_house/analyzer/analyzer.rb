
require 'ccsv'
# require 'memory'
require 'fileutils'
require 'yaml'
require 'pp'

module BleakHouse

  class Analyzer

    SPECIALS = {
      -1 => :timestamp,
      -2 => :'mem usage/swap', # Not used
      -3 => :'mem usage/real',  # Not used
      -4 => :tag,
      -5 => :'heap/filled',
      -6 => :'heap/free'
    }

    # Might be better as a per-tag skip but that gets kinda complicated
    initial_skip = (ENV['INITIAL_SKIP'] || 15).to_i
    INITIAL_SKIP = initial_skip < 2 ? 2 : initial_skip

    DISPLAY_SAMPLES = (ENV['DISPLAY_SAMPLES'] || 5).to_i

    class_key_source = File.dirname(__FILE__) + '/../../../ext/bleak_house/logger/snapshot.h'
    class_key_string = open(class_key_source).read[/\{(.*?)\}/m, 1]
    # Skip 0 so that the output of String#to_s is useful
    CLASS_KEYS = eval("[nil, #{class_key_string} ]").map do |class_name|
      class_name.to_sym if class_name
    end

    class << self

      def reverse_detect(array)
        i = array.size - 1
        while i >= 0
          item = array[i]
          return item if yield(item)
          i -= 1
        end
      end

      def calculate!(frame, index, total, population = nil)
        bsize = frame[:births].size
        dsize = frame[:deaths].size

        # Avoid divide by zero errors
        frame[:meta][:ratio] = ratio = (bsize - dsize) / (bsize + dsize + 1).to_f
        frame[:meta][:impact] = begin
          result = Math.log10((bsize - dsize).abs.to_i / 10.0)
          raise Errno::ERANGE if result.nan? or result.infinite?
          result
        rescue Errno::ERANGE
          0
        end

        puts "  F#{index}:#{total} (#{index * 100 / total}%): #{frame[:meta][:tag]} (#{population.to_s + ' population, ' if population}#{bsize} births, #{dsize} deaths, ratio #{format('%.2f', frame[:meta][:ratio])}, impact #{format('%.2f', frame[:meta][:impact])})"
      end

      # Read a frames object from a cache file.
      def read_cache(cachefile)
        frames = Marshal.load(File.open(cachefile).read)[0..-2]        
        total_frames = frames.size - 1
        announce_total(total_frames)
        
        frames[0..-2].each_with_index do |frame, index|
          calculate!(frame, index + 1, total_frames)
        end
        frames
      end
      
      def announce_total(total_frames)
        puts "#{total_frames} frames"

        if total_frames < INITIAL_SKIP * 3
          puts "Not enough frames for accurate results. Please record at least #{INITIAL_SKIP * 3} frames."
          exit # Should be exit! but that messes up backticks capturing in the tests
        end
      end      

      # Cache an object to disk.
      def write_cache(object, cachefile)
        Thread.exclusive do
          File.open(cachefile, 'w') do |f|
            f.write Marshal.dump(object)
          end
        end
      end

      # Rebuild frames
      def read(logfile, cachefile)
        total_frames = `grep '^-1' #{logfile} | wc`.to_i - 2
        announce_total(total_frames)        
        
        frames = loop(logfile, cachefile, total_frames)
      end

      # Convert the class and id columns to Fixnums, if possible, and remove memory
      # addresses from inspection samples.
      def normalize_row(row)

        # Broken out for speed (we don't want to generate a closure)
        if (int = row[0].to_i) != 0
          row[0] = int
        else
          row[0] = row[0].to_sym
        end

        if (int = row[1].to_i) != 0
          row[1] = int
        else
          row[1] = row[1].to_sym
        end

        if row[2]
          row[2] = row[2].gsub(/0x[\da-f]{8,16}/, "0xID").to_sym
        end

        row
      end

      # Inner loop of the raw log reader. The implementation is kind of a mess.
      def loop(logfile, cachefile, total_frames)

        frames = []
        last_population = []
        frame = nil

        Ccsv.foreach(logfile) do |row|

          class_index, id_or_tag, sampled_content = normalize_row(row)

          # Check for frame headers
          if class_index < 0

            # Get frame meta-information
            if SPECIALS[class_index] == :timestamp

              # The frame has ended; process the last one
              if frame
                population = frame[:objects].keys
                births = population - last_population
                deaths = last_population - population
                last_population = population

                # Assign births
                frame[:births] = [] # Uses an Array to work around a Marshal bug
                births.each do |key|
                  frame[:births] << [key, frame[:objects][key]]
                end

                # Assign deaths to previous frame
                final = frames[-2]
                if final

                  final[:deaths] = [] # Uses an Array to work around a Marshal bug
                  deaths.each do |key|
                    final[:deaths] << [key, [final[:objects][key].first]] # Don't need the sample content for deaths
                  end

                  # Try to reduce memory footprint
                  final.delete :objects
                  GC.start
                  sleep 1 # Give the GC thread a chance to do something

                  calculate!(final, frames.size - 1, total_frames, population.size)
                end
              end
              
              # Set up a new frame
              frame = {}
              frames << frame
              frame[:objects] ||= {}
              frame[:meta] ||= {}

              # Write out an in-process cache, in case you run out of RAM
              if frames.size % 20 == 0
                write_cache(frames, cachefile)
              end              
            end

            frame[:meta][SPECIALS[class_index]] = id_or_tag
          else
            # XXX Critical section
            if sampled_content
              # Normally object address strings and convert to a symbol
              frame[:objects][id_or_tag] = [class_index, sampled_content]
            else
              frame[:objects][id_or_tag] = [class_index]
            end
          end

        end

        # Work around for a Marshal/Hash bug on x86_64
        frames[-2][:objects] = frames[-2][:objects].to_a

        # Write the cache
        write_cache(frames, cachefile)

        # Junk last frame (read_cache also does this)
        frames[0..-2]
      end

      # Convert births back to hashes, necessary due to the Marshal workaround
      def rehash(frames)
        frames.each do |frame|
          frame[:births_hash] = {}
          frame[:births].each do |key, value|
            frame[:births_hash][key] = value
          end
          frame.delete(:births)
        end
        nil
      end

      # Parses and correlates a BleakHouse::Logger output file.
      def run(logfile)
        logfile.chomp!(".cache")
        cachefile = logfile + ".cache"

        unless File.exists? logfile or File.exists? cachefile
          puts "No data file found: #{logfile}"
          exit
        end

        puts "Working..."

        frames = []

        if File.exist?(cachefile) and (!File.exists? logfile or File.stat(cachefile).mtime > File.stat(logfile).mtime)
          puts "Using cache"
          frames = read_cache(cachefile)
        else
          frames = read(logfile, cachefile)
        end

        puts "\nRehashing."

        rehash(frames)

        # See what objects are still laying around
        population = frames.last[:objects].reject do |key, value|
          frames.first[:births_hash][key] and frames.first[:births_hash][key].first == value.first
        end

        puts "\n#{frames.size - 1} full frames. Removing #{INITIAL_SKIP} frames from each end of the run to account for\nstartup overhead and GC lag."

        # Remove border frames
        frames = frames[INITIAL_SKIP..-INITIAL_SKIP]

        # Sum all births
        total_births = frames.inject(0) do |births, frame|
          births + frame[:births_hash].size
        end

        # Sum all deaths
        total_deaths = frames.inject(0) do |deaths, frame|
          deaths + frame[:deaths].size
        end

        puts "\n#{total_births} total births, #{total_deaths} total deaths, #{population.size} uncollected objects."

        leakers = {}

        # Find the sources of the leftover objects in the final population
        population.each do |id, value|
          klass = value[0]
          content = value[1]
          leaker = reverse_detect(frames) do |frame|
            frame[:births_hash][id] and frame[:births_hash][id].first == klass
          end
          if leaker
            tag = leaker[:meta][:tag]
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
              frame[:meta][:tag] == tag
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
          impacts[frame[:meta][:tag]] ||= []
          impacts[frame[:meta][:tag]] << frame[:meta][:impact] * frame[:meta][:ratio]
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
end
