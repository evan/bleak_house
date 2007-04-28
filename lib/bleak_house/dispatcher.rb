
# crazyness

class Dispatcher
  class << self
    def prepare_application_with_bleak_house
      prepare_application_without_bleak_house
      BleakHouse.dispatch_count += 1
      Rublique.snapshot('rails')
    end
    alias_method_chain :prepare_application, :bleak_house
    
    def reset_after_dispatch_with_bleak_house
      Rublique.snapshot(BleakHouse.last_request_name || 'unknown')
      if (BleakHouse.dispatch_count % BleakHouse.log_interval).zero?
        BleakHouse.warn "wrote frameset (#{BleakHouse.dispatch_count} dispatches)"
        RubliqueLogger.log
      end
      reset_after_dispatch_without_bleak_house
    end
    alias_method_chain :reset_after_dispatch, :bleak_house
  end
end
