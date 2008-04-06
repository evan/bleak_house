#!/usr/bin/env ruby

require 'rubygems'
require 'dike'
$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../../lib")
require 'bleak_house'

Dike.logfactory(".")
if ARGV[0] 
  Dike.finger
  exec('cat 0')
else
  BleakHouse.snapshot("0")
  exec("#{$LOAD_PATH.first}/../bin/bleak 0")
end

