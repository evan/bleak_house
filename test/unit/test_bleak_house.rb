
DIR = File.dirname(__FILE__) + "/../../"

require 'rubygems'
require 'test/unit'
require 'yaml'
require 'ruby-debug'
Debugger.start
  
class BleakHouseTest < Test::Unit::TestCase
  require "#{DIR}lib/bleak_house/logger"

  SNAPSHOT_FILE = "/tmp/bleak_house"
  SNAPS = {:c => SNAPSHOT_FILE + ".c.yaml",
    :ruby => SNAPSHOT_FILE + ".rb.yaml"}

  def setup
  end

  def test_c_snapshot
    File.delete SNAPS[:c] rescue nil
    symbol_count = Symbol.all_symbols.size
    ::BleakHouse::Logger.new.snapshot(SNAPS[:c], "c_test", false)
    assert_equal symbol_count, Symbol.all_symbols.size
    assert File.exist?(SNAPS[:c])
  end
  
  def test_c_raises
    assert_raises(RuntimeError) do
      ::BleakHouse::Logger.new.snapshot("/", "c_test", false)
    end    
  end
  
end