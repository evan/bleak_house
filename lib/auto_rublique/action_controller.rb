
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
