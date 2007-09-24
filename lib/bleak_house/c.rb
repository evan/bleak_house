
class BleakHouse

=begin rdoc
This class performs the actual object logging of BleakHouse. To use it directly, you need to make calls to BleakHouse::CLogger#snapshot. 

== Example

At the start of your app, put:
  require 'rubygems'
  require 'bleak_house/c'
  $memlogger = BleakHouse::CLogger.new
  File.delete($logfile = "/path/to/logfile") rescue nil

(This assumes you are using the gem version.)

Now, at the points of interest, put:
  $memlogger.snapshot($logfile, "tag/subtag", false)

Run your app. Once you are done, analyze your data:
  ruby -r rubygems -e 'require "bleak_house/analyze"; BleakHouse::Analyze.build_all("/path/to/logfile")'

You will get a <tt>bleak_house/</tt> folder in the same folder as your logfile.
  
=end
  
  class CLogger
   
    # Returns an array of the running process's real and virtual memory usage, in kilobytes.
    def mem_usage
      a = `ps -o vsz,rss -p #{Process.pid}`.split(/\s+/)[-2..-1].map{|el| el.to_i}
      [a.first - a.last, a.last]
    end

    # Counts the live objects on the heap and writes a single tagged YAML frame to the logfile. Set <tt>specials = true</tt> if you also want to count AST nodes and var scopes; otherwise, use <tt>false</tt>.
    def snapshot(logfile, tag, specials)
      # RDoc stub
    end
    
  end  
end