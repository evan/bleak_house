
# crazyness

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
