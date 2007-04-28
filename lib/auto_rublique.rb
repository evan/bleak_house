
if ENV['AUTO_RUBLIQUE']
  
  require 'dispatcher' # rails  
  require 'rublique' # gem
  require 'rublique_logger' # gem
  
  require 'auto_rublique/dispatcher' # plugin
  require 'auto_rublique/action_controller' # plugin


  class AutoRublique  
    cattr_accessor :last_request_name
    cattr_accessor :dispatch_count
    cattr_accessor :log_interval

    self.dispatch_count = 0
    self.log_interval = ENV['INTERVAL'] and ENV['INTERVAL'].to_i or 10

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

    LOGFILE = "#{RAILS_ROOT}/log/#{RAILS_ENV}_rublique.log"
    if File.exists?(LOGFILE)
      File.rename(LOGFILE, "#{LOGFILE}.old") 
      warn "renamed old logfile"
    end
    RubliqueLogger.file = LOGFILE    
  end  
  
  AutoRublique.warn "enabled (log/#{RAILS_ENV}_rublique.log)"
else
  AutoRublique.warn "not enabled"
end
