require 'fileutils'

module BleakHouse

  LOGDIR = File.expand_path('../../log', __FILE__)
  LOGFILE = File.join(LOGDIR, 'bleak_house.log')
  
  FileUtils.mkdir_p(LOGDIR)
  
  def self.write_to_log(message)
    File.open(LOGFILE, 'a') { |f| f.puts message }
  end

  def self.execute(command)    
    unless system(command)
      puts File.open(LOGFILE).read
      exit -1 
    end
  end
end

BleakHouse.write_to_log('-%{ BUILDING RUBY }%-')
BleakHouse.execute("ruby build_ruby.rb >> #{BleakHouse::LOGFILE} 2>&1")

BleakHouse.write_to_log('-%{ BUILDING SNAPSHOT }%-')
BleakHouse.execute("ruby-bleak-house build_snapshot.rb >> #{BleakHouse::LOGFILE} 2>&1")