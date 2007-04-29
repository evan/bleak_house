
namespace :bleak_house do
  desc 'Analyze and chart all data'  
  task :analyze do
    require "#{File.dirname(__FILE__)}/../lib/bleak_house/analyze"
    BleakHouse::Analyze.build_all("#{RAILS_ROOT}/log/bleak_house_#{RAILS_ENV}.dump")
  end  
end