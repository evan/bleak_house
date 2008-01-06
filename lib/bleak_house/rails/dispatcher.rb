
# Insert callbacks so that each request makes before-and-after usage snapshots.
class Dispatcher

  if self.respond_to? :callbacks     
    # Rails 2.0
      
    def core_rails_snapshot
      BleakHouse::Rails::MEMLOGGER.snapshot(BleakHouse::Rails::LOGFILE, 'core rails', BleakHouse::Rails::WITH_SPECIALS, BleakHouse::Rails::SAMPLE_RATE)
    end
    callbacks[:before].unshift('core_rails_snapshot')
        
    def controller_snapshot
      BleakHouse::Rails::MEMLOGGER.snapshot(BleakHouse::Rails::LOGFILE, BleakHouse::Rails.last_request_name || 'unknown', BleakHouse::Rails::WITH_SPECIALS, BleakHouse::Rails::SAMPLE_RATE)   
    end
    callbacks[:after].unshift('controller_snapshot')
    
  else
    # Rails 1.2.x
    
    class << self
      def prepare_application_with_bleak_house
        prepare_application_without_bleak_house
        BleakHouse::Rails::MEMLOGGER.snapshot(BleakHouse::Rails::LOGFILE, 'core rails', BleakHouse::Rails::WITH_SPECIALS, BleakHouse::Rails::SAMPLE_RATE)
      end
      alias_method_chain :prepare_application, :bleak_house
      
      def reset_after_dispatch_with_bleak_house
        BleakHouse::Rails::MEMLOGGER.snapshot(BleakHouse::Rails::LOGFILE, BleakHouse::Rails.last_request_name || 'unknown', BleakHouse::Rails::WITH_SPECIALS, BleakHouse::Rails::SAMPLE_RATE)
        reset_after_dispatch_without_bleak_house
      end
      alias_method_chain :reset_after_dispatch, :bleak_house
    end
    
  end
end
