
if ENV['BLEAK_HOUSE']
  
  require 'dispatcher' # rails  

  begin
    require 'json'
  rescue LoadError
    require 'fjson'
  end

  require 'vendor/rublique' # modified Rublique gem
  require 'vendor/rublique_logger'
  
  require 'bleak_house/dispatcher' # our plugin
  require 'bleak_house/action_controller'


  class BleakHouse  
    cattr_accessor :last_request_name
    cattr_accessor :dispatch_count
    cattr_accessor :log_interval

    self.dispatch_count = 0
    self.log_interval = (ENV['INTERVAL'] and ENV['INTERVAL'].to_i or 10)

    def self.set_request_name request, other = nil
      self.last_request_name = "#{request.parameters['controller']}/#{request.parameters['action']}/#{request.request_method}#{other}"
    end

    def self.debug s
      s = "#{name.underscore}: #{s}"
      ::ActiveRecord::Base.logger.debug s if ::ActiveRecord::Base.logger
    end
      
    def self.warn s
      s = "#{name.underscore}: #{s}"
      if ::ActiveRecord::Base.logger
        ::ActiveRecord::Base.logger.warn s
      else
        $stderrequest.puts s
      end    
    end

    LOGFILE = "#{RAILS_ROOT}/log/#{RAILS_ENV}_bleak_house.log"
    RubliqueLogger.file = LOGFILE    
  end  
  
  BleakHouse.warn "enabled (log/#{RAILS_ENV}_bleak_house.log) (#{BleakHouse.log_interval} requests per frame)"
  if File.exists?(BleakHouse::LOGFILE)
    File.rename(BleakHouse::LOGFILE, "#{BleakHouse::LOGFILE}.old") 
    BleakHouse.warn "renamed old logfile"
  end

end