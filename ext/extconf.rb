require 'fileutils'

module BleakHouse
  def self.write_to_log(filename, message)
    File.open(filename, 'a') { |fp| fp.write("#{message}\n") }
  end
  
  def self.execute(command)
    puts "$}- #{command}"
    exit -1 unless system(command)
  end
end

logdir = File.expand_path('../../log', __FILE__)

logfile = File.join(logdir, 'bleak_house.log')
FileUtils.mkdir_p(logdir)

BleakHouse.write_to_log(logfile, '-%{ BUILDING RUBY }%-')
BleakHouse.execute("ruby build_ruby.rb >> #{logfile} 2>&1")

BleakHouse.write_to_log(logfile, '-%{ BUILDING SNAPSHOT }%-')
BleakHouse.execute("ruby-bleak-house build_snapshot.rb >> #{logfile} 2>&1")