
DIR = File.dirname(__FILE__) + "/../../"

require 'rubygems'
require 'test/unit'
require 'yaml'
require 'ruby-debug'
require 'ccsv'
Debugger.start
  
class BleakHouseTest < Test::Unit::TestCase
  require "#{DIR}lib/bleak_house/logger"

  SNAPSHOT_FILE = "/tmp/bleak_house.dump"

  def setup
    File.delete SNAPSHOT_FILE rescue nil
  end

  def test_snapshot
    symbol_count = Symbol.all_symbols.size
    ::BleakHouse::Logger.new.snapshot(SNAPSHOT_FILE, "test", false, 0)
    assert_equal symbol_count, Symbol.all_symbols.size # Test that no symbols leaked
    assert File.exist?(SNAPSHOT_FILE)
    assert_equal 0, sample_ratio(SNAPSHOT_FILE)
  end
  
  def test_sampling
    ::BleakHouse::Logger.new.snapshot(SNAPSHOT_FILE, "test", false, 0.5)  
    ratio = sample_ratio(SNAPSHOT_FILE) 
    assert(ratio > 0.45)
    assert(ratio < 0.55)
  end
  
  def test_exception
    assert_raises(RuntimeError) do
      ::BleakHouse::Logger.new.snapshot("/", "test", false, 0)
    end    
  end
  
  def sample_ratio(file)
    rows = 0
    samples = 0
    Ccsv.foreach(file) do |row|
      rows += 1
      samples += 1 if row[2]
    end
    samples / rows.to_f
  end
  
end