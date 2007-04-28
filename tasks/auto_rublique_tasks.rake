
namespace :auto_rublique do
  desc 'Analyze and chart all data'  
  task :analyze do
    require "#{File.dirname(__FILE__)}/../lib/auto_rublique/analyze"
    AutoRublique::Analyze.build_all("#{RAILS_ROOT}/log/#{RAILS_ENV}_auto_rublique.log")
  end  
end