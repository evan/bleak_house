
class BleakHouse
  class MemLogger
    def snapshot
      raise "abstract method; please require 'ruby' or 'c'"
    end
    
    def mem_usage
      a = `ps -o vsz,rss -p #{Process.pid}`.split(/\s+/)[-2..-1].map{|el| el.to_i}
      [a.first - a.last, a.last]
    end

  end
end

