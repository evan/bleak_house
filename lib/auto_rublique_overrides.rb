
require 'dispatcher'
require 'rublique'
require 'rublique_logger'
RubliqueLogger.file = "#{RAILS_ROOT}/log/#{RAILS_ENV}_rublique.log"
  
class RubliqueLogger
  cattr_accessor :last_request_name
  cattr_accessor :dispatch_count
  cattr_accessor :log_interval

  self.dispatch_count = 0
  self.log_interval = 1
end

class Dispatcher
  class << self
    def prepare_application_with_rublique
      prepare_application_without_rublique
      Rublique.snapshot('core')
    end
    alias_method_chain :prepare_application, :rublique
    
    def reset_after_dispatch_with_rublique
      Rublique.snapshot(RubliqueLogger.last_request_name || 'unknown')
      RubliqueLogger.dispatch_count += 1
      if RubliqueLogger.dispatch_count == RubliqueLogger.log_interval
        RubliqueLogger.dispatch_count = 0
        RubliqueLogger.log
      end
      reset_after_dispatch_without_rublique
    end
    alias_method_chain :reset_after_dispatch, :rublique
  end
end

class ApplicationController
  class << self
    def process_with_rublique
      RubliqueLogger.last_request_name = "#{name}/#{action_name}"
    end
    alias_method_chain :process, :rublique
    
    def process_with_exception_with_rublique
      RubliqueLogger.last_request_name = "#{name}/#{action_name}/exception"        
    end
    alias_method_chain :process_with_exception, :rublique    
  end
end
