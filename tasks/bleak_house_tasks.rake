
namespace :bleak_house do
  desc 'Analyze and chart all data'  
  task :analyze do
    require "#{File.dirname(__FILE__)}/../lib/bleak_house/analyze"
    BleakHouse::Analyze.build_all("#{RAILS_ROOT}/log/#{RAILS_ENV}_bleak_house.log")
  end  
end