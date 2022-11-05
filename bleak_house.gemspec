$:.push File.expand_path("../lib", __FILE__)

require "bleak_house/version"

Gem::Specification.new do |s|
  s.name        = "bleak_house"
  s.version     = BleakHouse::VERSION
  s.summary     = "bleak_house Helper"
  s.description = "bleak_house Helper"
  s.license     = "bleak_house"
  s.add_dependency "rails"
end
