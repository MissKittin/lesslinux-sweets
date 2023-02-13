#!/usr/bin/ruby
# encoding: utf-8

require "tmpdir"

class MfsSinglePartition
	
	def initialize(parent, device, blocks, debug=false)
		@parent = parent
		@device = device
		@debug = debug
		@blocks = blocks
		@enc = nil
		@fs = nil
		@uuid = nil
		@label = nil
		@size = -1
		@filesyssize = -1
		@free = -1
		@mounted = nil
		@fct = nil
		@winpart = nil
		@winvers = nil
		blkid
	end
	attr_reader :device, :blocks, :fs, :uuid, :label 
	
	def blkid
		@size = File.new("/sys/block/" + @parent + "/size").read.to_i * 512
		@size = File.new("/sys/block/" + @parent + "/" + @device + "/size").read.to_i * 512 if File.exist?("/sys/block/" + @parent + "/" + @device + "/size") 
		IO.popen("blkid -o udev /dev/" + @device) { |line|
			while line.gets
				ltoks = $_.strip.split('=')
				@uuid = ltoks[1] if ltoks[0] == "ID_FS_UUID"
				@label = ltoks[1] if ltoks[0] == "ID_FS_LABEL"
				@fs = ltoks[1] if ltoks[0] == "ID_FS_TYPE"
				@enc = false
				@enc = true if @fs == "crypto_LUKS"
			end
		}
		if @uuid.nil? && @label.nil?
			@uuid = "nil" + rand(999_999_999).to_s 
		elsif @uuid.nil?
			@uuid = @label
		end
		if @debug == true
			puts "  part:    " + @device.to_s
			puts "    size:  " + @size.to_s
			puts "    uuid:  " + @uuid.to_s 
			puts "    fs:    " + @fs.to_s
			puts "    label: " + @label.to_s
			puts "    enc:   " + @enc.to_s
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
	
	def is_windows
		return false, nil unless @fs =~ /fat/ || @fs =~ /ntfs/
		return @winpart, @winvers unless @winpart.nil?
		mnt = mount_point
		was_mounted = true
		winfiles = Array.new
		return false, nil unless File.exist?("winfiles.txt")
		File.open("winfiles.txt").each { |line| winfiles.push(line.strip) unless line.strip == "" } 
		if mount_point.nil?
			was_mounted = false
			mount
		end
		windir = nil
		sysdir = nil
		[ "Windows", "WINDOWS", "windows"].each { |w| windir = w if File.directory?(mount_point[0] + "/" + w) }
		if windir.nil?
			umount if was_mounted == false
			@winpart = false
			return false, nil
		end
		[ "System32", "SYSTEM32", "system32" ].each { |s| sysdir = mount_point[0] + "/" + windir + "/" + s if File.directory?(mount_point[0] + "/" + windir + "/" + s) }
		if sysdir.nil?
			umount if was_mounted == false
			@winpart = false
			return false, nil
		end
		ntoskrnl = nil
		sixtyfour = false
		foundfiles = Array.new
		# puts "Sysdir: " + sysdir
		Dir.entries(sysdir).each { |f| 
			# puts f.strip.downcase
			foundfiles.push(f.strip.downcase)
			ntoskrnl = sysdir + "/" + f.strip if f.strip.downcase =~ /ntoskrnl\.exe/
		}
		intersect = foundfiles & winfiles
		# puts "Intersection: " + intersect.size.to_s 
		if intersect.size.to_f < winfiles.size.to_f * 0.95 || ntoskrnl.nil?  
			umount if was_mounted == false
			@winpart = false
			return false, nil
		end
		IO.popen("strings '#{ntoskrnl}' ") { |line|
			while line.gets
				@winvers = "Windows XP" if $_.strip =~ /[0-9][0-9][0-9][0-9]\.xp(.*?)(rtm|gdr)\./
				@winvers = "Windows Vista" if $_.strip =~ /[0-9][0-9][0-9][0-9]\.vista(.*?)(rtm|gdr)\./
				@winvers = "Windows 7" if $_.strip =~ /[0-9][0-9][0-9][0-9]\.win7(.*?)(rtm|gdr)\./
			end
		}
		umount if was_mounted == false
		@winpart = true
		@winvers = "Windows (unbekannt)" if @winvers.nil? 
		return @winpart, @winvers
	end
	
	def mount(mode="ro", mntpnt=nil)
		mountpoint = ""
		if mntpnt.nil?
			mountpoint = "/media/" + @uuid
			system("mkdir -p /media/" + @uuid)
		else
			mountpoint = mntpnt
		end
		type = ""
		opts = [ mode ]
		if fs =~ /fat/
			type = "-t vfat"
			opts.push "iocharset=utf8"
		elsif fs =~ /ntfs/
			type = "-t ntfs-3g"
		elsif fs =~ /ext/
			type = "-t ext4"
		else
			type = ""
		end
		mountcmd = "mount " + type + " -o " + opts.join(',') + " /dev/" + @device + " '" + mountpoint + "'"
		return true if system(mountcmd)
		return false
	end
	
	def umount
		return true if system("umount /dev/" + @device)
		return false
	end
	
	def mount_point
		IO.popen("cat /proc/mounts") { |line|
			while line.gets
				ltoks = $_.strip.split 
				device = ltoks[0]
				if File.symlink?(device)
					target = File.readlink(device)
					if target =~ /^\//
						device = target
					else
						abspath = File.dirname(device) + "/" + target 
						device = File.realpath(abspath)
					end
				end
				if device == "/dev/" + @device || device == @device
					# puts @device + " is mounted on " + ltoks[1].gsub('\040', '').gsub('\134', '\\')
					return [ ltoks[1].gsub('\040', '').gsub('\134', '\\'), ltoks[3].split(',') ]
				end
			end
		}
		return nil
	end
	
	def fssize
		return @filesyssize unless @filesyssize < 0
		if mount_point.nil?
			mount("ro")
			retrieve_occupation
			umount
		else
			retrieve_occupation
		end
		return @filesyssize
	end
	
	def free_space
		return @free unless @free < 0
		if mount_point.nil?
			mount("ro")
			retrieve_occupation
			umount
		else
			retrieve_occupation
		end
		return @free
	end
	
	def retrieve_occupation
		IO.popen("df -k '" + mount_point[0] + "' | tail -n1 ") { |line|
			while line.gets
				ltoks = $_.strip.split
				@filesyssize = ltoks[1].to_i * 1024
				@free = ltoks[3].to_i * 1024
			end
		}
		puts "Whole: " + @filesyssize.to_s + " Free: " + @free.to_s 
		return @free
	end
	
	def filecount(pgbar=nil)
		return @fct unless @fct.nil?
		return @fct unless @fs =~ /ext|fat|btrfs|ntfs|reiser/
		unless mount_point.nil?
			puts "Count " + @device
			count_files(pgbar)
		else
			mount("ro")
			puts "Mount and count " + @device
			count_files(pgbar)
			umount
		end
		return @fct
	end
	
	def count_files(pgbar=nil)
		dir = mount_point[0]
		file_counter = 0 
		pgbar.activity_mode = true unless pgbar.nil?
		last_pulse = Time.now.to_f
		IO.popen("find '" + dir + "' -xdev -type f ") { |f|
			while f.gets
				file_counter += 1
				unless pgbar.nil?
					now = Time.now.to_f
					if now - last_pulse > 0.1
						last_pulse = now
						pgbar.text = "Analysiere Laufwerk #{@device} - #{file_counter.to_s} Dateien gefunden" 
						# puts "Dateien auf " + @device + ": " + file_counter.to_s 
						pgbar.pulse
						while Gtk.events_pending?
							Gtk.main_iteration
						end
					end
				end
			end
		}
		file_counter = nil if $?.nil?
		pgbar.activity_mode = false unless pgbar.nil?
		pgbar.fraction = 1.0 unless pgbar.nil?
		@fct = file_counter 
	end
	
	def system_partition?
		mnt = mount_point
		return false if mnt.nil?
		return true if mnt[0] =~ /^\/lesslinux\//
		return false
	end
	
end