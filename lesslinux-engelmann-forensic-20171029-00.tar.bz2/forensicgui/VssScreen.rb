#!/usr/bin/ruby
# encoding: utf-8

require 'exifr'
require 'fileutils'
require 'id3tag'

class VssScreen

	def initialize(layers, fixed)
		@layers = layers
		@fixed = fixed
		@target_combo = nil 
		@target_devices = Array.new 
		@ntfs_parts = Array.new 
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "VssScreen.xml") 
		@start_label = @tl.get_translation("start_label") 
		create_first_layer 
		create_locking_layer
	end
	attr_reader :start_label
	
	def create_first_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		ok = Gtk::Button.new(Gtk::Stock::APPLY)
		fx.put(bgimg, 0, 0)
		reread = Gtk::Button.new(@tl.get_translation("reread")) 
		reread.width_request = 200
		reread.height_request = 32
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("vss_start")) 
		fx.put(infolabel, 250, 100)
		# Target
		target_label = Gtk::Label.new(@tl.get_translation("target") )
		@target_combo = Gtk::ComboBox.new
		@target_combo.width_request = 526
		@target_combo.height_request = 32
		fx.put(@target_combo, 250, 260)
		fx.put(reread, 780, 260)
		fx.put(target_label, 250, 228)
		
		[ ok, cancel ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		reread.signal_connect("clicked") { reread_drivelist }
		cancel.signal_connect("clicked") { 
			#unless kill_recovery
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
			#end
		}
		ok.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["vss_locking"].show_all 
			mount_all(@target_devices[@target_combo.active])
		}
		fx.put(ok, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		@fixed.put(fx, 0, 0)
		@layers["vss_start"] = fx
	end
	
	def create_locking_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		[ cancel ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("vss_locking")) 
		fx.put(infolabel, 250, 100)
		fx.put(bgimg, 0, 0)
		fx.put(cancel, OK_X, OK_Y)
		@fixed.put(fx, 0, 0)
		@layers["vss_locking"] = fx
		cancel.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			# Unmount everything
			umount_all(@target_devices[@target_combo.active])
			@layers["start"].show_all 
		}
	end
	
	
	def reread_drivelist 
		1000.downto(0) { |n|
			begin
				@target_combo.remove_text(n)
			rescue
			end
		}
		@target_devices = Array.new 
		@ntfs_parts = Array.new 
		drives = Array.new
		partitions = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/
		}
		datcount = 0 
		drives.reverse.each { |d|
			label = "#{d.vendor} #{d.model}"
			if d.usb == true
				label = label + " (USB) "
			else
				label = label + " (SATA/eSATA/IDE) "
			end
			label = label + "#{d.device} #{d.human_size}"
			d.partitions.each  { |p|
				label = "#{d.vendor} #{d.model}"
				if d.usb == true
					label = label + " (USB) "
				else
					label = label + " (SATA/eSATA/IDE) "
				end
				label = label + "#{p.device} #{p.human_size}"
				pmnt = p.mount_point
				unless pmnt.nil?
					p.umount unless pmnt.nil?
					pmnt = p.mount_point
				end
				if ( p.fs =~ /vfat/ || p.fs =~ /ntfs/ || p.fs =~ /ext/ || p.fs =~ /btrfs/ ) && pmnt.nil?
					if p.label.to_s == "USBDATA"
						label = @tl.get_translation("backup_medium") + " " + label
						datcount = @target_devices.size 
					end
					label = label + " #{p.fs}"
					partitions.push p.device
					@target_combo.append_text(label)
					@target_devices.push p
					if p.fs =~ /ntfs/
						@ntfs_parts.push p 
					end
				end
			}
		}
		@target_combo.active = datcount 
	end
	
	def mount_all(backup_part)
		FileUtils::mkdir_p("/media/backup") 
		vss_devs = 0
		@ntfs_parts.each { |p|
			if p.device == backup_part.device 
				puts "Skipping backup device: #{backup_part.device}"
			else
				if p.vss?
					vss_devs += 1
					p.vss_mount_all 
				end
			end
		}
		if vss_devs > 0
			backup_part.mount("rw", "/media/backup", 1000, 1000) 
			system("su surfer -c \"thunar /media/vss\" &")
			system("su surfer -c \"thunar /media/backup\" &")
		else
			TileHelpers.error_dialog(@tl.get_translation("no_vss_found"), "Error") 
		end
	end
	
	def umount_all(backup_part)
		system("killall thunar")
		sleep 0.5
		system("killall -9 thunar")
		backup_part.force_umount 
		@ntfs_parts.each { |p|
			if p.device == backup_part.device 
				puts "Skipping backup device: #{backup_part.device}"
			else
				p.vss_umount_all if p.vss? 
			end
		}
	end
	
end