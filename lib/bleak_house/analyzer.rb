
module BleakHouse
  module Analyzer

    # Analyze a compatible <tt>bleak.dump</tt>. Accepts a filename and the number of lines to display.
    def self.run(file, lines)
      filled, free = `tail -n 2 #{file}`.split("\n")
      unless filled =~ /filled/ and free =~ /free/
        raise "#{file} is incomplete or corrupted"
      end

      length = `wc #{file}`.to_i - 2      

      puts "#{length} total objects"
      puts "Final heap size #{filled}, #{free}"
      puts "Displaying top #{lines} most common line/class pairs\n"            
        
      cmd = ENV['NO_TRACE'] ? "awk -F: '{print $3}' " + file : "cat #{file}"      
      cmd += " | sort | uniq -c | sort -nr | head -#{lines}"

      puts `#{cmd}`
    end
    
  end
end
