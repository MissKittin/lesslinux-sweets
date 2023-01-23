#!/usr/bin/ruby
# encoding: utf-8

class MfsDiskDrive
	
	def initialize(device, debug=false)
		@device = device
		@size = -1
		@partitions = Array.new
		@removable = nil
		@usb = nil
		@debug = debug
		@vendor = nil
		@model = nil
		@smart_errors = nil
		@smart_info = nil
		@smart_support = false
		get_info
		read_partitions
	end
	attr_reader :device, :size, :partitions, :removable, :usb, :vendor, :model
	
	def read_partitions
		fullblocks = 0
		IO.popen("cat /proc/partitions") { |line|
			while line.gets
				ltoks = $_.strip.split
				pmatch = Regexp.new("^" + @device + "\\d+$")
				rmatch = Regexp.new("^" + @device + "$")
				if ltoks[3] =~ pmatch
					blocks = ltoks[2].to_i
					@partitions.push(MfsSinglePartition.new(@device, ltoks[3], blocks, true))
				elsif ltoks[3] =~ rmatch
					fullblocks = ltoks[2].to_i
				end
			end
		}
		if @partitions.size < 1 && system("blkid '/dev/#{@device}' ")
			@partitions.push(MfsSinglePartition.new(@device, @device, fullblocks, true))
		end
	end
	
	def get_info
		@vendor = File.new("/sys/block/" + @device + "/device/vendor").read.strip
		@model = File.new("/sys/block/" + @device + "/device/model").read.strip
		@removable = false
		@removable = true if File.new("/sys/block/" + @device + "/removable").read.strip.to_i > 0
		@size = File.new("/sys/block/" + @device + "/size").read.strip.to_i * 512
		@usb = false
		@usb = true if File.readlink("/sys/block/" + @device) =~ /usb/ 
		
		if @debug == true
			puts "  vendor: " + @vendor.to_s + " " + @model.to_s
			puts "  size:   " + @size.to_s 
			puts "  remov.: " + @removable.to_s  
			puts "  usb:    " + @usb.to_s 
		end
	end
	
	def human_size 
		if @size.to_f / 1024 ** 3 > 3
			return (@size.to_f / 1024 ** 3 + 0.5).to_i.to_s + "GB"
		elsif @size.to_f / 1024 ** 2 > 3
			return (@size.to_f / 1024 ** 2 + 0.5).to_i.to_s + "MB"
		end
		return @size.to_s + "B" 
	end
	
	def umount
		@partitions.each { |p| p.umount unless p.system_partition? }
	end
	
	def error_log
		return @smart_support, @smart_info, @smart_errors unless @smart_errors.nil? 
		system("smartctl --smart=on --offlineauto=on --saveauto=on /dev/#{@device}")
		@smart_info = Array.new
		@smart_errors = Array.new
		IO.popen("smartctl -i /dev/#{@device}") { |l| @smart_info.push($_) while l.gets }
		IO.popen("smartctl --attributes --log=selftest --quietmode=errorsonly  /dev/#{@device}") { |l|
			while l.gets
				line = $_ 
				@smart_errors.push(line) unless line.strip == ""
			end
		}
		@smart_support = true if @smart_info.join(" ") =~ /SMART support is: Available/
		return @smart_support, @smart_info, @smart_errors
	end
	
end