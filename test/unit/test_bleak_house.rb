
$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../../lib")

ENV['NO_EXIT_HANDLER'] = "1"

require 'rubygems'
require 'echoe'
require 'test/unit'
require 'bleak_house'

class BleakHouseTest < Test::Unit::TestCase

  # Match the default hook filename, for convenience
  FILE =  "/tmp/bleak.#{Process.pid}.0.dump"

  def setup
    File.delete FILE rescue nil
  end

  def test_snapshot
    symbol_count = Symbol.all_symbols.size
    BleakHouse.snapshot(FILE)
    assert File.exist?(FILE)
    assert BleakHouse.heaps_used > 0
    assert BleakHouse.heaps_length > 0
  end

  def test_exception
    assert_raises(RuntimeError) do
      BleakHouse.snapshot("/")
    end
  end

  def test_analyze
    BleakHouse.snapshot(FILE)
    Dir.chdir(File.dirname(__FILE__) + "/../../bin") do
      output = `./bleak #{FILE}`.split("\n")
      # require 'ruby-debug/debugger'
      assert_match(/top 20 most common/, output[0])
      assert_match(/free heap/, output[3])
      assert_match(/\d+ __null__:__null__:__node__/, output[4])
    end
  end

  def test_signal
    Echoe.silence do
      system("kill -s SIGUSR2 #{Process.pid}")
    end
    assert File.exist?(FILE)
  end

end