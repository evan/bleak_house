
class ActionController::Base
  class << self
    def process_with_bleak_house(request, *args) 
      BleakHouse.set_request_name request
      process_without_bleak_house(request, *args)
    end
    alias_method_chain :process, :bleak_house
    
    def process_with_exception_with_bleak_house(request, *args)
      BleakHouse.set_request_name request, "/error"
      process_with_exception_without_bleak_house(request, *args)
    end
    alias_method_chain :process_with_exception, :bleak_house    
  end
end
