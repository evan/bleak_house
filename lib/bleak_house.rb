
if ENV['BLEAK_HOUSE']

  require 'dispatcher' # rails  
  
  require 'bleak_house/bleak_house'
  require 'bleak_house/mem_logger'
  require 'bleak_house/dispatcher'
  require 'bleak_house/action_controller'

  BleakHouse.warn "enabled (log/#{RAILS_ENV}_bleak_house.log) (#{BleakHouse.log_interval} requests per frame)"
    
end
