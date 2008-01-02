
# Insert callbacks so that each request makes before-and-after usage snapshots.
class Dispatcher
 
  def core_rails_snapshot
    BleakHouse::Rails::MEMLOGGER.snapshot(BleakHouse::Rails::LOGFILE, 'core rails', BleakHouse::Rails::WITH_SPECIALS)
  end
  callbacks[:before].unshift('core_rails_snapshot')
      
  def controller_snapshot
    BleakHouse::Rails::MEMLOGGER.snapshot(BleakHouse::Rails::LOGFILE, BleakHouse::Rails.last_request_name || 'unknown', BleakHouse::Rails::WITH_SPECIALS)   
  end
  callbacks[:after].unshift('controller_snapshot')

end
