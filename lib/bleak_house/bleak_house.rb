
class BleakHouse  
  cattr_accessor :last_request_name
  
  # Avoid making four more strings on each request.
  CONTROLLER_KEY = 'controller'
  ACTION_KEY = 'action'
  GSUB_SEARCH = '/'
  GSUB_REPLACEMENT = '__'

  # Sets the request name on the BleakHouse object to match this Rails request. Called from <tt>ActionController::Base.process</tt>. Assign to <tt>last_request_name</tt> yourself if you are not using BleakHouse within Rails.
  def self.set_request_name request, other = nil
    self.last_request_name = "#{
      request.parameters[CONTROLLER_KEY].gsub(GSUB_SEARCH, GSUB_REPLACEMENT) # mangle namespaced controller names
    }/#{
      request.parameters[ACTION_KEY]
    }/#{
      request.request_method
    }#{
      other
    }"
  end

  def self.debug s #:nodoc:
    s = "** #{name.underscore}: #{s}"
    RAILS_DEFAULT_LOGGER.debug s if RAILS_DEFAULT_LOGGER
  end
    
  def self.warn s #:nodoc:
    s = "** #{name.underscore}: #{s}"
    if RAILS_DEFAULT_LOGGER
      RAILS_DEFAULT_LOGGER.warn s
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
  
  MEMLOGGER = CLogger.new    
end
