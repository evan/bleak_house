
if ENV['BLEAK_HOUSE']

  require 'dispatcher' # rails  
  
  require 'bleak_house/bleak_house'
  require 'bleak_house/mem_logger'
  require 'bleak_house/dispatcher'
  require 'bleak_house/action_controller'

  BleakHouse.warn "enabled (log/bleak_house_#{RAILS_ENV}.dump)"
    
end
