
module BleakHouse
  module Rails  
    @@last_request_name = nil

    class << self

      def last_request_name
        @@last_request_name
      end
      
      def last_request_name=(obj)
        @@last_request_name = obj
      end
      
      # Avoid making four more strings on each request.
      CONTROLLER_KEY = 'controller'
      ACTION_KEY = 'action'
      GSUB_SEARCH = '/'
      GSUB_REPLACEMENT = '__'
    
      # Sets the request name on the BleakHouse object to match this Rails request. Called from <tt>ActionController::Base.process</tt>. Assign to <tt>last_request_name</tt> yourself if you are not using BleakHouse within Rails.
      def set_request_name(request, other = nil)
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
    
      def debug(s) #:nodoc:
        s = "** bleak_house: #{s}"
        RAILS_DEFAULT_LOGGER.debug s if RAILS_DEFAULT_LOGGER
      end
        
      def warn(s) #:nodoc:
        s = "** bleak_house: #{s}"
        if RAILS_DEFAULT_LOGGER
          RAILS_DEFAULT_LOGGER.warn s
        else
          $stderr.puts s
        end
      end
    end
  
    LOGFILE = "#{RAILS_ROOT}/log/bleak_house_#{RAILS_ENV}.dump"
    if File.exists?(LOGFILE)
      File.rename(LOGFILE, "#{LOGFILE}.old") 
      warn "renamed old logfile"
    end
    
    WITH_SPECIALS = false
    
    SAMPLE_RATE = ENV['SAMPLE_RATE'].to_f
    
    MEMLOGGER = Logger.new    
  end
end
