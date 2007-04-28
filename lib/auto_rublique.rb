
if ['staging', 'development'].include? RAILS_ENV

  require 'initializer'
  
  class Rails::Initializer
    def after_initialize_with_rublique
      after_initialize_without_rublique    
      require 'auto_rublique_overrides'
      ActiveRecord::Base.logger.warn "auto_rublique: enabled"
    end    
    alias_method_chain :after_initialize, :rublique
  end
        
else
  ActiveRecord::Base.logger.warn "auto_rublique: not enabled"
end
