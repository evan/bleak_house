
module BleakHouse

=begin rdoc
This class performs the actual object logging of BleakHouse. To use it directly, you need to make calls to BleakHouse::Logger#snapshot. 

== Example

At the start of your app, put:
  require 'rubygems'
  require 'bleak_house'
  $memlogger = BleakHouse::Logger.new
  File.delete($logfile = "/path/to/logfile") rescue nil

Now, at the points of interest, put:
  $memlogger.snapshot($logfile, "tag/subtag", false)

Run your app. Once you are done, analyze your data:
  bleak /path/to/logfile
  
=end
  
  class Logger
   
    # Returns an array of the running process's real and virtual memory usage, in kilobytes.
    def mem_usage
      a = `ps -o vsz,rss -p #{Process.pid}`.split(/\s+/)[-2..-1].map{|el| el.to_i}
      [a.first - a.last, a.last]
    end

  end  
end