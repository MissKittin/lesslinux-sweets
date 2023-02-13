#!/usr/bin/ruby
# encoding: utf-8

require "MfsDiskDrive.rb"
require "MfsSinglePartition.rb"

Dir.entries("/sys/block").each { |l|
	if l =~ /[a-z]$/ 
		puts l
		d = MfsDiskDrive.new(l, true)
	end
}