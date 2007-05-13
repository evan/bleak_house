#!/usr/bin/env ruby-bleak-house

require 'rubygems'
require 'bleak_house/c'
$memlogger = BleakHouse::CLogger.new
File.delete($logfile = "/tmp/log") rescue nil

puts "1"
$memlogger.snapshot($logfile, "tag", true)
puts "2"
$memlogger.snapshot($logfile, "tag", true)
