
if ['staging', 'development'].include? RAILS_ENV

  require 'dispatcher'
  require 'rublique'
  require 'rublique_logger'
  RubliqueLogger.file = "#{RAILS_ROOT}/log/#{RAILS_ENV}_rublique.log"
    
  class RubliqueLogger
    cattr_accessor :dispatch_count
    self.dispatch_count = 0
    cattr_accessor :log_interval
    self.log_interval = 1
  end
  
  class Dispatcher
    class << self
#      ActiveRecord::Base.logger.warn "auto_rublique: chaining"
      def prepare_application_with_rublique
#        ActiveRecord::Base.logger.warn "auto_rublique: prepare"
        prepare_application_without_rublique
        Rublique.snapshot('core')
      end
      alias_method_chain :prepare_application, :rublique
      
      def reset_after_dispatch_with_rublique
 #       ActiveRecord::Base.logger.warn "auto_rublique: reset_after_dispatch"
        Rublique.snapshot('controller')
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
      
  ActiveRecord::Base.logger.warn "auto_rublique: enabled"
else
  ActiveRecord::Base.logger.warn "auto_rublique: not enabled"
end
