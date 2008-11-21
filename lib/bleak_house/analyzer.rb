
module BleakHouse
  module Analyzer

    # Analyze a compatible <tt>bleak.dump</tt>. Accepts one or more filename and the number of lines to display.
    def self.run(*args)
      lines = args.last[/^\d+$/] ? args.pop.to_i : 20

      raise "Can't diff more than 2 files" if args.size > 2

      outputs = args.map do |file|
        filled, free = `tail -n 2 #{file}`.split("\n")
        unless filled =~ /filled/ and free =~ /free/
          raise "#{file} is incomplete or corrupted"
        end

        length = `wc #{file}`.to_i - 2
        cmd = ENV['NO_TRACE'] ? "awk -F: '{print $3}' " + file : "cat #{file}"
        cmd += " | sort | uniq -c | sort -nr | head -#{lines}"

        ["#{length} total objects", "#{filled} heap slots", "#{free} heap slots"] + `#{cmd}`.split("\n")
      end

      if outputs.size == 1
        # Just output the data
        puts "Displaying top #{lines} most common line/class pairs"
        puts outputs.first
      else
        puts "Displaying change in top #{lines} most common line/class pairs"
        puts diff(outputs)
      end

    end

    def self.diff(outputs)
      # Calculate the diff
      diff = Hash.new(0)
      # Iterate each item
      outputs.each_with_index do |output, index|
        output[3..-1].each do |line|
          c, key = line.split(" ", 2)
          index.zero? ? diff[key] -= c.to_i : diff[key] += c.to_i
        end
      end
      # Format the lines in descending order
      diff.sort_by do |key, value|
        -value
      end.map do |key, value|
        "#{value.to_s.rjust(6)} #{key}"
      end
    end

  end
end
