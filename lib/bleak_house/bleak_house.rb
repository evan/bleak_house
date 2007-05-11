
class BleakHouse  
  cattr_accessor :last_request_name

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

  LOGFILE = "#{RAILS_ROOT}/log/bleak_house_#{RAILS_ENV}.yaml.log"
  if File.exists?(LOGFILE)
    File.rename(LOGFILE, "#{LOGFILE}.old") 
    warn "renamed old logfile"
  end
  
  WITH_SPECIALS = false
  GC = true

  MEMLOGGER = CLogger.new
    
end
