
# crazyness

class Dispatcher
  class << self
    def prepare_application_with_auto_rublique
      prepare_application_without_auto_rublique
      AutoRublique.dispatch_count += 1
      Rublique.snapshot('rails')
    end
    alias_method_chain :prepare_application, :auto_rublique
    
    def reset_after_dispatch_with_auto_rublique
      Rublique.snapshot(AutoRublique.last_request_name || 'unknown')
      if (AutoRublique.dispatch_count % AutoRublique.log_interval).zero?
        AutoRublique.warn "wrote frameset (#{AutoRublique.dispatch_count} dispatches)"
        RubliqueLogger.log
      end
      reset_after_dispatch_without_auto_rublique
    end
    alias_method_chain :reset_after_dispatch, :auto_rublique
  end
end
