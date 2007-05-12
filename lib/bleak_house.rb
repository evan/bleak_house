
if ENV['BLEAK_HOUSE']

  # rails  
  require 'dispatcher'
  
  # logger
  require 'bleak_house/c'
  require 'bleak_house/bleak_house'

  # overrides
  require 'bleak_house/dispatcher'
  require 'bleak_house/action_controller'

  BleakHouse.warn "enabled (log/bleak_house_#{RAILS_ENV}.dump)"
    
end
