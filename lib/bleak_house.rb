
require 'bleak_house/logger'

if ENV['RAILS_ENV'] and ENV['BLEAK_HOUSE']
  require 'bleak_house/rails'
  BleakHouse::Rails.warn "enabled (log/bleak_house_#{RAILS_ENV}.dump)"    
end
