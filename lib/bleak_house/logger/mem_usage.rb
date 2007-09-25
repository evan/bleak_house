
module BleakHouse
  
  class Logger
   
    # Returns an array of the running process's real and virtual memory usage, in kilobytes.
    def mem_usage
      a = `ps -o vsz,rss -p #{Process.pid}`.split(/\s+/)[-2..-1].map{|el| el.to_i}
      [a.first - a.last, a.last]
    end

  end  
end