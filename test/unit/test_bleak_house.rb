
DIR = File.dirname(__FILE__) + "/../../"

require 'rubygems'
require 'test/unit'
require 'yaml'
  
class BleakHouseTest < Test::Unit::TestCase
  require "#{DIR}lib/bleak_house/logger"

  SNAPSHOT_FILE = "/tmp/bleak_house"
  SNAPS = {:c => SNAPSHOT_FILE + ".c.yaml",
    :ruby => SNAPSHOT_FILE + ".rb.yaml"}

  def setup
  end

  def test_c_snapshot
    File.delete SNAPS[:c] rescue nil
    ::BleakHouse::Logger.new.snapshot(SNAPS[:c], "c_test", true)
    assert File.exist?(SNAPS[:c])
#    assert_nothing_raised do 
#      assert YAML.load_file(SNAPS[:c]).is_a?(Array)
#    end
  end
  
  def test_c_raises
    assert_raises(RuntimeError) do
      ::BleakHouse::Logger.new.snapshot("/", "c_test", false)
    end    
  end
  
end