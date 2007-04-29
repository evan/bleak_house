
if ENV['BLEAK_HOUSE']
  
  require 'dispatcher' # rails  
  
  require 'bleak_house/mem_logger'
  require 'bleak_house/dispatcher'
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
        $stderr.puts s
      end    
    end

    LOGFILE = "#{RAILS_ROOT}/log/bleak_house_#{RAILS_ENV}.dump"
    if File.exists?(LOGFILE)
      File.rename(LOGFILE, "#{LOGFILE}.old") 
      warn "renamed old logfile"
    end
    
  end  
  
  BleakHouse.warn "enabled (log/#{RAILS_ENV}_bleak_house.log) (#{BleakHouse.log_interval} requests per frame)"
end