
require "#{File.dirname(__FILE__)}/../test_helper"

class ServerTest < Test::Unit::TestCase

  RAILS_ROOT = HERE + "/integration/app"
  PORT = 43039
  URL = "http://localhost:#{PORT}/"
  LOG = "#{HERE}/integration/app/log/production.log"
  system("touch #{LOG}")

  def test_server_start
    assert_match(/Ok/, browse("items"))
  end
  
  def test_too_few_frames
    browse("items")    
    assert_match(/Not enough frames/, analyze)
  end
  
  def test_enough_frames
    11.times do
      browse("items")
    end

    result = analyze

    # XXX Doesn't test the caching mechanism
 
    assert_match(/leaked per request \(9\)/, result)
    assert_match(/items\/index\/GET leaked/mi, result)
    assert_match(/Inspection samples/, result)
    assert_match(/core rails leaked/, result)
    assert_match(/Impact.*core rails/m, result)
    assert_match(/Impact.*items\/index\/GET/mi, result)
  end
  
  private

  # Mostly copied from Interlock's tests

  def browse(url = "")
    flag = false    
    begin
      open(URL + url).read
    rescue Errno::ECONNREFUSED, OpenURI::HTTPError => e      
      raise "#{e.to_s}: #{URL + url}" if flag
      flag = true
      sleep 3
      retry
    end
  end
  
  def analyze
    ENV['INITIAL_SKIP'] = "2"
    `#{HERE}/../bin/bleak #{HERE}/integration/app/log/bleak_house_production.dump`
  end
  
  def truncate
    Dir["#{RAILS_ROOT}/log/bleak_house*"].each { |f| File.delete f }
    system("> #{LOG}")
  end
  
  def log
    File.open(LOG, 'r') { |f| f.read }
  end  
  
  def setup
    Process.fork do
      Dir.chdir(RAILS_ROOT) do 
        ENV['RAILS_GEM_VERSION'] = ENV['MULTIRAILS_RAILS_VERSION']
        exec("RAILS_ENV=production SAMPLE_RATE=0.5 BLEAK_HOUSE=1 script/server -p #{PORT} &> #{LOG}")
      end
    end    
    
    50.times do |n|
      break if log =~ /available at 0.0.0.0:#{PORT}/
      sleep(0.2) 
      raise "Server didn't start" if n == 49      
    end
    
    truncate
  end
  
  def teardown
    # Process.kill(9, pid) doesn't work because Mongrel has double-forked itself away    
    while (pids = `ps awx | grep #{PORT} | grep -v grep | awk '{print $1}'`.split("\n")).any?
      pids.each {|pid| system("kill #{pid}")}
      sleep(0.2)
    end
  end   
  
end