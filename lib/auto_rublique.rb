
if ENV['AUTO_RUBLIQUE']

  require 'dispatcher'
  require 'rublique'
  require 'rublique_logger'
  RubliqueLogger.file = file = "#{RAILS_ROOT}/log/#{RAILS_ENV}_rublique.log"
  File.rename(file, "#{file}.old") if File.exists?(file)
    
  class RubliqueLogger
    cattr_accessor :last_request_name
    cattr_accessor :dispatch_count
    cattr_accessor :log_interval

    self.dispatch_count = 0
    self.log_interval = ENV['INTERVAL'] and ENV['INTERVAL'].to_i or 10
  end
  
  # yeah crazyness, in an effort to not just blow away the existing dispatcher methods
  class Dispatcher
    class << self
      def prepare_application_with_auto_rublique
        prepare_application_without_auto_rublique
        Rublique.snapshot('core')
      end
      alias_method_chain :prepare_application, :auto_rublique
      
      def reset_after_dispatch_with_auto_rublique
        Rublique.snapshot(RubliqueLogger.last_request_name || 'unknown')
        RubliqueLogger.dispatch_count += 1
        if RubliqueLogger.dispatch_count == RubliqueLogger.log_interval
          RubliqueLogger.dispatch_count = 0
          RubliqueLogger.log
        end
        reset_after_dispatch_without_auto_rublique
      end
      alias_method_chain :reset_after_dispatch, :auto_rublique
    end
  end
  
  class ActionController::Base
    class << self
      def process_with_auto_rublique(r, *args)        
        RubliqueLogger.last_request_name = "#{r.parameters['controller']}/#{r.parameters['action']}/#{r.request_method}"
        process_without_auto_rublique(r, *args)
      end
      alias_method_chain :process, :auto_rublique
      
      def process_with_exception_with_auto_rublique(r, *args)
        RubliqueLogger.last_request_name = "#{r.parameters['controller']}/#{r.parameters['action']}/#{r.request_method}/error"
        process_with_exception_without_auto_rublique(r, *args)
      end
      alias_method_chain :process_with_exception, :auto_rublique    
    end
  end
      
  ActiveRecord::Base.logger.warn "auto_rublique: enabled (log/#{RAILS_ENV}_rublique.log)"
else
  ActiveRecord::Base.logger.warn "auto_rublique: not enabled"
end
