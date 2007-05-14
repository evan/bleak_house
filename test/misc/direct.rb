#!/usr/bin/env ruby-bleak-house

require 'rubygems'
require 'bleak_house/c'
$memlogger = BleakHouse::CLogger.new
File.delete($logfile = "/tmp/log") rescue nil

puts 0
$memlogger.snapshot($logfile, "file", true)
puts 1
$memlogger.snapshot($logfile, "file/one", true)
puts 2
$memlogger.snapshot($logfile, "file/two", true)
