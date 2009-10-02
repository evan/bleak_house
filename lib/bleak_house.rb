
unless RUBY_PATCHLEVEL >= 905
  raise "This build of Ruby has not been successfully patched for BleakHouse."
end

RUBY_VERSION = `ruby -v`.split(" ")[1]
require 'snapshot'
require 'bleak_house/hook'

class << BleakHouse
  private :ext_snapshot
end
  
module BleakHouse

  # Walk the live, instrumented objects on the heap and write them to 
  # <tt>logfile</tt>. Accepts an optional number of GC runs to perform
  # before dumping the heap.
  def self.snapshot(logfile, gc_runs = 3)
    ext_snapshot(logfile, gc_runs)
  end
end
