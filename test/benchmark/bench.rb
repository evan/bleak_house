#!/usr/bin/env ruby

require 'rubygems'
require 'dike'
$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../../lib")
require 'bleak_house'

Dike.logfactory("/tmp")
if ARGV[0]
  Dike.finger
  exec('cat /tmp/0')
else
  BleakHouse.snapshot("/tmp/0")
  exec("#{$LOAD_PATH.first}/../bin/bleak /tmp/0")
end

