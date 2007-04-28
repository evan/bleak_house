
# modified - was too clever by half, causing its own leaks

class Rublique
  class << self
    @@object_map = {}
    @@class_map = {}
    @@object_breakdown = {}
    def snapshot(tag)
      new_objects = {}
      object_list = @@object_map.dup

      ObjectSpace.each_object do |obj|
        obj_id = obj.object_id        

        if object_list.has_key? obj_id
          object_list.delete obj_id
        else
          new_objects[obj_id] = tag
          @@class_map[obj_id] = obj.class
        end
      end

      object_list.each_key { |key| @@object_map.delete key }    
      @@object_map.merge! new_objects
    end
    
    def objects
      @@object_map
    end
    
    def breakdown
      @@object_map.to_a.inject({}) do |tag_hash, object_mapping|
        obj, tag = object_mapping
        
        if tag_hash.has_key? tag
          tag_hash[tag][obj] = @@class_map[obj]
        else
          tag_hash[tag] = { obj => @@class_map[obj] }
        end
        
        tag_hash
      end
    end
 
    def delta
      old_object_breakdown = @@object_breakdown
      @@object_breakdown = nil
       
      ObjectSpace.garbage_collect
       
      @@object_breakdown = breakdown
       
      @@object_breakdown.keys.inject({}) do |d, tag|
        old_objects = old_object_breakdown[tag] || {}
        new_objects = @@object_breakdown[tag]
        
        d[tag] = (old_objects.keys - new_objects.keys).inject(Hash.new(0)) do |h,obj| 
          h[@@class_map[obj]] -= 1
          @@class_map.delete obj
          h
        end
        
        new_objects.keys.inject(d[tag]) do |h,obj|
          unless old_objects.has_key? obj
            h[@@class_map[obj]] += 1
          end
          h
        end.delete_if { |k,v| v == 0 }   
        d
      end.delete_if { |k,v| v.empty? }
    end
  end
end
