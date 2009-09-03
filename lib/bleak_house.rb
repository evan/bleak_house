
unless RUBY_PATCHLEVEL >= 905
  raise "This build of Ruby has not been successfully patched for BleakHouse."
end

RUBY_VERSION = `ruby -v`.split(" ")[1]
require 'snapshot'
require 'bleak_house/hook'
