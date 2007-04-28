
class ActionController::Base
  class << self
    def process_with_auto_rublique(request, *args) 
      AutoRublique.set_request_name request
      process_without_auto_rublique(request, *args)
    end
    alias_method_chain :process, :auto_rublique
    
    def process_with_exception_with_auto_rublique(request, *args)
      AutoRublique.set_request_name request, "/error"
      process_with_exception_without_auto_rublique(request, *args)
    end
    alias_method_chain :process_with_exception, :auto_rublique    
  end
end
