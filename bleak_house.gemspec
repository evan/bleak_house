$:.push File.expand_path("../lib", __FILE__)

require "bleak_house/version"

Gem::Specification.new do |s|
  s.name        = "bleak_house"
  s.version     = BleakHouse::VERSION
  s.authors     = ["TEST BY LOMESH"]
  s.email       = ["lomesh.vohra@gmail.com"]
  s.homepage    = "http://github.com/mjacobus/very_simple_menu"
  s.summary     = "bleak_house Helper"
  s.description = "bleak_house Helper"
  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.license     = "bleak_house"
  s.add_dependency "rails"
end
