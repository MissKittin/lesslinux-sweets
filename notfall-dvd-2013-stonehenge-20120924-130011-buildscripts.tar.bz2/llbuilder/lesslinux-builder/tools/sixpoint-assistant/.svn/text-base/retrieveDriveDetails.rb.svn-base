#!/usr/bin/ruby
# encoding: utf-8

class DriveDetails
	def initialize(device, vendor, model, blocks, bs, attached, optical, labels, encrypted)
		@device = device
		@vendor = vendor
		@vendor = "unknown" if vendor.nil?
		@model = model
		@blocks = blocks
		@bs = bs
		@attached = attached
		@optical = optical
		# puts device + " " + vendor + " " + model + " " + blocks.to_s + " " + bs.to_s + " " + attached
		# if @optical == false
			@partitions, @superfloppy = get_partitions(labels, encrypted)
			find_extended_partitions
		# else
			
		# end
	end
	attr_reader(:device, :vendor, :model, :blocks, :bs, :attached, :partitions, :superfloppy)
	
	def get_partitions(labels, encrypted)
		all_partitions = Hash.new
		superfloppy = false
		mounted_parts = Array.new
		mount_options = Hash.new
		mount_points = Hash.new
		IO.popen("cat /proc/mounts") { |line|
			while line.gets
				tokens = $_.strip.split
				if tokens[0] == @device
					superfloppy = true
					# puts $_.strip
					fslabel = ""
					fslabel = ` dosfslabel #{@device} ` unless labels == false
					all_partitions[0] = PartitionDetails.new(
						@device, 0, @blocks * @bs, @blocks * @bs, tokens[2], true, tokens[1], tokens[3], false, nil, fslabel)
				end
				check_reg = Regexp.new("^" + @device + "\\d")
				# puts check_reg.to_s
				if tokens[0] =~ check_reg 
					mounted_parts.push(tokens[0])
					mount_options[tokens[0]] = tokens[3]
					mount_points[tokens[0]] = tokens[1]
					# puts tokens[0] + " mounted on " +  tokens[1] + " with opts " +  tokens[3]
				end
			end
		}
		IO.popen("parted -sm " + @device + " unit B print") { |line|
			while line.gets
				if $_ =~ /^\d/
					tokens = $_.strip.split(":")
					id = @device + tokens[0].to_s
					isluks = false
					luks_uuid = nil
					part_label = nil
					start = tokens[1].gsub("B", "").to_i
					fin =  tokens[2].gsub("B", "").to_i
					size = tokens[3].gsub("B", "").to_i
					fs = tokens[4]
					bootable = false
					bootable = true if tokens[6] =~ /boot/
					fslabel = ""
					mounted = false
					mountpoint = nil
					mountopts = nil
					if mounted_parts.include?(id) 
						mounted = true
						mountpoint = mount_points[id]
						mountopts = mount_options[id]
					end
					if fs == "" 
						if encrypted == true && system("cryptsetup isLuks " + id)
							isluks = true
							luks_uuid = ` cryptsetup luksUUID #{id} `
							luks_mounted = ` cat /proc/mounts | grep #{luks_uuid} `
							unless luks_mounted.strip == ""
								ltoks = luks_mounted.strip.split
								mounted = true
								mountpoint = ltoks[1]
								mountopts = ltoks[3]
							end
						end
					elsif fs =~ /fat/ && labels == true
						auxlabel = ` dosfslabel #{id} `
						fslabel = auxlabel.strip unless auxlabel.strip =~ /differences between boot sector and its backup/ 
					elsif fs =~ /ntfs/ && labels == true
						auxlabel = ` ntfslabel #{id} `
						fslabel = auxlabel.strip
					end
					all_partitions[tokens[0].to_i] = PartitionDetails.new(id, start, fin, size, fs, 
						mounted, mountpoint, mountopts, isluks, luks_uuid, fslabel, bootable)
				end
			end
		}
		if superfloppy == false && all_partitions.size < 1
			system("mkdir -p /var/run/lesslinux/" + $$.to_s + "/testmount")
			if system("mount -t vfat -o ro " + @device + " /var/run/lesslinux/" + $$.to_s + "/testmount")
				# puts "Superfloppy!"
				fslabel = ""
				fslabel = ` dosfslabel #{@device} ` if labels == true
				all_partitions[0] = PartitionDetails.new(
						@device, 0, @blocks * @bs, @blocks * @bs, "fat", false, nil, nil, false, nil, fslabel.strip)
			elsif system("mount -t ntfs-3g -o ro " + @device + " /var/run/lesslinux/" + $$.to_s + "/testmount")
				fslabel = ""
				fslabel = ` ntfslabel #{@device} ` if labels == true
				all_partitions[0] = PartitionDetails.new(
						@device, 0, @blocks * @bs, @blocks * @bs, "ntfs", false, nil, nil, false, nil, fslabel.strip)		
			elsif system("mount -t iso9660 -o ro " + @device + " /var/run/lesslinux/" + $$.to_s + "/testmount")
				# puts "Superfloppy!"
				all_partitions[0] = PartitionDetails.new(
						@device, 0, @blocks * @bs, @blocks * @bs, "iso9660", false, nil, nil, false, nil, "")
				
			end
			system("umount /var/run/lesslinux/" + $$.to_s + "/testmount")
			# system("mount -t iso9660 " + @device + " /var/run/lesslinux/" + $$.to_s + "/testmount")
			
			
		end	
		return all_partitions, superfloppy
	end
	
	def find_extended_partitions
		@partitions.each { |k, v|
			if k <= 4
				@partitions.each { |l, w|
					if l >= 5
						if v.start <= w.start && v.fin >= w.fin
							# puts k.to_s + " contains " + l.to_s
							@partitions[k].mark_extended
							@partitions[l].mark_logical
						end
					end
				}
			end
		}
	end
	
	def identify_windows
		ostype = nil
		ospart = nil
		osarch = nil
		@partitions.each { |k, v|
			if v.fs =~ /^ntfs/ || v.fs =~ /^fat/ 
				mountpoint = nil
				unless @mounted == true
					system("mkdir -p /var/run/lesslinux/" + $$.to_s + "/testmount")
					system("mount -o ro " + v.device + " /var/run/lesslinux/" + $$.to_s + "/testmount")
					mountpoint = "/var/run/lesslinux/" + $$.to_s + "/testmount"
				else
					mountpoint = v.mountpoint
				end
				if File.exist?(mountpoint + "/boot.ini") && 
						File.exist?(mountpoint + "/ntldr") && 
						File.exist?(mountpoint + "/WINDOWS")
					ostype = "winxp"
					ospart = v.device
				end
				system("umount /var/run/lesslinux/" + $$.to_s + "/testmount")
			end
		}
		@partitions.each { |k, v|
			if v.fs =~ /^ntfs/ || v.fs =~ /^fat/ 
				mountpoint = nil
				unless @mounted == true
					system("mkdir -p /var/run/lesslinux/" + $$.to_s + "/testmount")
					system("mount -o ro " + v.device + " /var/run/lesslinux/" + $$.to_s + "/testmount")
					mountpoint = "/var/run/lesslinux/" + $$.to_s + "/testmount"
				else
					mountpoint = v.mountpoint
				end
				if File.exist?(mountpoint + "/Windows/System32/Boot/winload.exe") &&  
						!File.exist?(mountpoint + "/Windows/System32/Boot/winload.efi")
					ostype = "vista"
					ospart = v.device
				elsif File.exist?(mountpoint + "/Windows/System32/Boot/winload.exe") &&  
						File.exist?(mountpoint + "/Windows/System32/Boot/winload.efi")
					ostype = "win7"
					ospart = v.device
				end
				system("umount /var/run/lesslinux/" + $$.to_s + "/testmount")
			end
		}
		@partitions.each { |k, v|
			if v.fs =~ /^ntfs/ || v.fs =~ /^fat/ 
				mountpoint = nil
				unless @mounted == true
					system("mkdir -p /var/run/lesslinux/" + $$.to_s + "/testmount")
					system("mount -o ro " + v.device + " /var/run/lesslinux/" + $$.to_s + "/testmount")
					mountpoint = "/var/run/lesslinux/" + $$.to_s + "/testmount"
				else
					mountpoint = v.mountpoint
				end
				if File.exist?(mountpoint + "/Boot/memtest.exe") &&  
						File.exist?(mountpoint + "/Boot/BCD") &&
						File.exist?(mountpoint + "/bootmgr")
					ostype = "win7"
					ospart = v.device
				end
				system("umount /var/run/lesslinux/" + $$.to_s + "/testmount")
			end
		}
		return ospart, ostype
	end
	
	def has_mounted_partitions
		@partitions.each { |k, v|
			return true if v.mounted == true
		}
		return false
	end
	
	def has_ntfs_partitions
		
	end
		
	def has_fat_partitions
		
	end
	
	def has_other_partitions
		
	end
	
	def last_partend
		partend = -1
		@partitions.each { |k, p|
			partend = p.fin if p.fin > partend
		}
		return partend
	end
	
	def size
		return @blocks * @bs
	end
	
	def dump
		puts device.to_s + " " + vendor.to_s + " " + model.to_s + " " + blocks.to_s + " " + bs.to_s + " " + attached
		puts "      " + device + " is optical!" if @optical == true
		0.upto(99) { |i|
			@partitions[i].dump unless partitions[i].nil?
		}
	end
	
	def boot_partitions
		boot_parts = Array.new
		@partitions.each { |k, v|
			boot_parts.push(v.device) if v.active == true
		}
		return boot_parts
	end
	
	def occupied_space
		occupied = 0
		@partitions.each { |k,v| occupied = occupied + v.occupied_space }
		return occupied
	end
end

class PartitionDetails
	def initialize(id, start, fin, size, fs, mounted, mountpoint, options, isluks, luksuuid, fslabel, active=false)
		@id = id
		@device = id
		@start = start
		@fin = fin
		@size = size 
		@fs = fs
		@extended = false
		@logical = false
		@mounted = mounted
		@mountpoint = mountpoint
		@mountopts = options
		@isluks = isluks
		@luksuuid = luksuuid
		@fslabel = fslabel.strip
		@active = active
	end
	attr_reader(:id, :device, :start, :fin, :size, :fs, :extended, :logical, :mounted, :mountpoint, :mountopts, :isluks, :luksuuid, :fslabel, :active)
	
	def mark_extended
		@extended = true
	end

	def mark_logical
		@logical = true
	end
	
	def free_space 
		free_blocks = 0
		if @mounted == true
			free_blocks = ` df -B 512  "#{@mountpoint}" | tail -n1 | awk '{print $4}' ` 
		else
			system("mkdir -p /var/run/lesslinux/" + $$.to_s + "/testmount")
			system("mount -o ro #{@id} /var/run/lesslinux/" + $$.to_s + "/testmount")
			free_blocks = ` df -B 512 /var/run/lesslinux/#{$$.to_s}/testmount  | tail -n1 | awk '{print $4}' `
			system("umount /var/run/lesslinux/" + $$.to_s + "/testmount")
		end
		free_bytes = free_blocks.to_i * 512
		return free_bytes
	end
	
	def occupied_space 
		occupied_blocks = 0
		if @mounted == true
			occupied_blocks = ` df -B 512  "#{@mountpoint}" | tail -n1 | awk '{print $3}' ` 
			system("df -B 512 " + @mountpoint)
		else
			system("mkdir -p /var/run/lesslinux/" + $$.to_s + "/testmount")
			system("mount -o ro #{@id} /var/run/lesslinux/" + $$.to_s + "/testmount")
			occupied_blocks = ` df -B 512 /var/run/lesslinux/#{$$.to_s}/testmount  | tail -n1 | awk '{print $3}' `
			system("df -B 512 /var/run/lesslinux/" + $$.to_s + "/testmount")
			system("umount /var/run/lesslinux/" + $$.to_s + "/testmount")
		end
		occupied_bytes = occupied_blocks.to_i * 512
		puts "partition " + @id + " occupied: " + occupied_bytes.to_s
		return occupied_bytes
	end
	
	def dump 
		if @fs.to_s.strip == ""
			fs = "unknown"
		else
			fs = @fs
		end
		puts "   " + @id + " " + @start.to_s + " " + @fin.to_s + " " + fs + " " + @extended.to_s + 
			" " + @logical.to_s
		puts "      " + @id + " has label: " + @fslabel unless fslabel == ""
		puts "      " + @id + " is mounted: " + @mountpoint.to_s + " " + @mountopts.to_s if @mounted == true
		puts "      " + @id + " is encrypted: " + @luksuuid if @isluks == true
	end
end

class AllDrives
	def initialize( labels, encrypted, optical )
		@drive_list = Hash.new
		hwinfo_cmd = "hwinfo --disk --cdrom"
		hwinfo_cmd = "hwinfo --disk" if optical == false
		IO.popen(hwinfo_cmd) { |line|
			device = nil
			vendor = nil
			model = nil
			blocks = -1
			bs = 0
			attached = nil
			optical = false
			while line.gets 
				if $_ =~ /^\d/
					device = nil
					vendor = nil
					model = nil
					blocks = -1
					bs = 0
					attached = nil
				elsif $_ =~ /^\s+Vendor:.*?\"(.*?)\"/ 
					vendor = $1
					# puts $1.strip
				elsif $_ =~ /^\s+Device:.*?\"(.*?)\"/ 
					model = $1
					# puts $1.strip
				elsif $_ =~ /^\s+Size:\s(\d+?)\s.*?\s(\d+?)\s/ # .*?(\d*?)/
					blocks = $1.to_i
					bs = $2.to_i
					# puts $1.strip + " " + $2.strip
				elsif $_ =~ /^\s+Attached\sto:/
					if $_ =~ /USB/
						attached = "usb"
					else
						attached = "internal"
					end
				elsif $_ =~ /^\s+Device\sFile:\s/
					device = $_.strip.split[2]
					if device =~ /^\/dev\/sr\d/
						optical = true
					else
						optical = false
					end
				elsif $_ =~ /^\s*$/
					# puts ""
					drive_list[device] = DriveDetails.new(device, vendor, model, blocks, bs, attached, optical, labels, encrypted) if blocks > 0
				end
			end
			drive_list[device] = DriveDetails.new(device, vendor, model, blocks, bs, attached, optical, labels, encrypted) if blocks > 0
		}
		# return drive_list
	end
	attr_reader(:drive_list)
	
	def dump
		@drive_list.each { |k,v| v.dump }
	end
end
