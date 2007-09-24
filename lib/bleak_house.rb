
if ENV['BLEAK_HOUSE']
  require 'bleak_house/logger'
  require 'bleak_house/rails'
  BleakHouse.warn "enabled (log/bleak_house_#{RAILS_ENV}.dump)"    
end
