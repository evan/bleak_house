
require 'base64'

class BleakHouse::MemLogger
  class << self

    SEEN = {}
    CURRENT = {}
    TAGS = Hash.new(0)
    TIMEFORMAT = '%Y-%m-%d %H:%M:%S'
    VSZ = "memory usage/virtual"
    RSS = "memory usage/real"

    def log(path, with_mem = false)
      File.open(path, 'a+') do |log|
        log.sync = true
        TAGS[VSZ], TAGS[RSS] = mem_usage if with_mem
        log.puts Base64.encode64(Marshal.dump([Time.now.strftime(TIMEFORMAT), TAGS])).gsub("\n", '')
      end
      GC.start
    end
    
    def snapshot(tag)
#      puts "bleak_house: seen: #{SEEN.size}"
      CURRENT.clear
      ObjectSpace.each_object do |obj|
        CURRENT[obj_id = obj._bleak_house_object_id] = true
        unless SEEN[obj_id]
          # symbols will rapidly stabilize; don't worry
          SEEN[obj_id] = "#{tag}::::#{obj._bleak_house_class}".to_sym 
          TAGS[SEEN[obj_id]] += 1
        end
      end
#      puts "bleak_house: current: #{CURRENT.size}"
      SEEN.keys.each do |obj_id|
        TAGS[SEEN.delete(obj_id)] -= 1 unless CURRENT[obj_id]          
      end
 #     puts "bleak_house: done"
      CURRENT.clear
      GC.start
    end        
    
    def mem_usage
      `ps -x -o 'rss vsz' -p #{Process.pid}`.split(/\s+/)[-2..-1].map{|el| el.to_i}
    end
    
  end
end

class Object
  alias :_bleak_house_object_id :object_id
  alias :_bleak_house_class  :class
end

