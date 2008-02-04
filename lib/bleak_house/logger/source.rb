
#:stopdoc:

# Doesn't work

module BleakHouse
  module Source
    def allocate(*args)
      super
      puts "#{self.class},#{self.object_id},#{caller.inspect},#{self.inspect}"
    end
  end
end

class String
  include BleakHouse::Source
end

String.new

#:startdoc:
