
namespace :bleak_house do
  desc 'Analyze and chart all data'  
  task :analyze do    
    begin
      gem 'gruff', '= 0.2.8' # fail early if gruff is missing
      require "#{File.dirname(__FILE__)}/../lib/bleak_house/analyze"
      puts "loaded vendor/plugins version"
    rescue LoadError
      require 'bleak_house/analyze' 
      puts "loaded gem version"
    end        
    BleakHouse::Analyze.build_all("#{RAILS_ROOT}/log/bleak_house_#{RAILS_ENV}.yaml.log")
  end  
end

