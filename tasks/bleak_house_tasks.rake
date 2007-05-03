
namespace :bleak_house do
  desc 'Analyze and chart all data'  
  task :analyze do    
    begin
      gem 'gruff', '= 0.2.8'
      require "#{File.dirname(__FILE__)}/../lib/bleak_house/analyze"
    rescue LoadError
      require 'bleak_house/analyze' 
    end        
    BleakHouse::Analyze.build_all("#{RAILS_ROOT}/log/bleak_house_#{RAILS_ENV}.dump")
  end  
end

