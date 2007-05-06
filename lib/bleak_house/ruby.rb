
require 'yaml'

class BleakHouse
  class RubyLogger < MemLogger
    SWAP = :"memory usage/swap"
    RSS = :"memory usage/real"  
    SEEN = {}
    CURRENT = {}
    TAGS = Hash.new(0)
    
    def snapshot(path, tag, _specials)
      CURRENT.clear
      ObjectSpace.each_object do |obj|
        CURRENT[obj_id = obj._bleak_house_object_id] = true
        unless SEEN[obj_id]
          # symbols will rapidly stabilize
          SEEN[obj_id] = "#{tag}::::#{obj._bleak_house_class}".to_sym 
          TAGS[SEEN[obj_id]] += 1
        end
      end
      SEEN.keys.each do |obj_id|
        TAGS[SEEN.delete(obj_id)] -= 1 unless CURRENT[obj_id]          
      end
      CURRENT.clear

      TAGS[SWAP], TAGS[RSS] = mem_usage
                      
      write(path)  
    end        
    
    def write(path)
      exists = File.exist? path
      File.open(path, 'a+') do |log|
        dump = YAML.dump([[Time.now.to_i, TAGS]])
        log.write(exists ? dump[5..-1] : dump)
      end      
    end
    
  end
end

class Object
  alias :_bleak_house_object_id :object_id
  alias :_bleak_house_class  :class
end
