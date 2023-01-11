#!/usr/bin/ruby
# encoding: utf-8

class SambaScreen	
	def initialize(extlayers, button, nwscreen)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "SambaScreen.xml")
		@layers = Array.new
		# First panel with warning
		infopane = Gtk::Label.new
		infopane.width_request = 510
		infopane.wrap = true
		infopane.set_markup("<span foreground='white'><b>" + @tl.get_translation("sambahead") + "</b>\n\n" + @tl.get_translation("sambabody") + "</span>")
		fixed = Gtk::Fixed.new
		
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		forwtext = TileHelpers.create_label(@tl.get_translation("gotoshare"), 220)
		
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		
		infogreen = Gtk::Image.new("sambagreen.png")
		infored = Gtk::EventBox.new.add Gtk::Image.new("sambagreen.png")
		@iscsicheck = Gtk::CheckButton.new
		@rwcheck = Gtk::CheckButton.new
		@rwcheck.active = true
		@rwcheck.sensitive = false 
		iscsitext = Gtk::Label.new
		iscsitext.set_markup("<span color='white'>" + @tl.get_translation("useiscsi") + "</span>")
		rwtext = Gtk::Label.new
		rwtext.set_markup("<span color='white'>" + @tl.get_translation("iscsirw") + "</span>")
		
		# fixed.put(infogreen, 0, 0)
		# fixed.put(infored, 0, 130)
		fixed.put(infopane, 0, 20)
		fixed.put(@iscsicheck, 0, 260)
		fixed.put(iscsitext, 30, 265)
		fixed.put(@rwcheck, 30, 295)
		fixed.put(rwtext, 60, 300)
		# fixed.put(cancelpane, 135, 170)
		#panel.put(back, 650, 402)
		#panel.put(text, 402, 408)
		fixed.put(text4, 402, 408)
		fixed.put(back, 650, 402)
		fixed.put(forw, 650, 352)
		fixed.put(forwtext, 402, 358)
		
		extlayers["sambaquest"] = fixed
		@layers[0] = fixed
		
		#################################
		
		# Second panel stop server
		fixed2 = Gtk::Fixed.new
		stoppane = Gtk::Label.new
		stoppane.width_request = 510
		stoppane.wrap = true
		stoppane.set_markup("<span foreground='white'><b>"+ @tl.get_translation("shareactivehead") + "</b>\n\n" + @tl.get_translation("shareactivebody") + "</span>")
		
		
		
		stopbutton = Gtk::Image.new("sambagreen.png")
		cancelbutton = TileHelpers.place_back(fixed2, extlayers, false)
		
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("cancel") +"</span>")
		back2 = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		
		fixed2.put(stoppane, 5, 32)
		# fixed2.put(stopbutton, 0, 0)
		# fixed2.put(text5, 402, 358)
		# fixed2.put(back2, 650, 352)
		
		extlayers["sambarunning"] = fixed2
		@layers[1] = fixed2
		
		@iscsicheck.signal_connect("clicked") {
			@rwcheck.sensitive = @iscsicheck.active? 
		}
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				if nwscreen.test_link == false
					nwscreen.nextscreen = "sambaquest"
					nwscreen.fill_wlan_combo 
					# Check for networks first...
					extlayers["networks"].show_all
				else
					extlayers["sambaquest"].show_all
				end
			end
		}
		infored.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		cancelbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				puts "Stopping SAMBA"
				TileHelpers.back_to_group
			end
		}
		back2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				puts "Stopping SAMBA"
				system("killall -15 nmbd")
				system("killall -15 smbd")
				system("killall -15 istgt")
				sleep 2
				system("killall -9 nmbd")
				system("killall -9 smbd")
				system("killall -9 istgt")
				TileHelpers.umount_all 
				system("sync")
				sleep 0.5
				TileHelpers.umount_all
				TileHelpers.back_to_group
			end
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				if @iscsicheck.active? == true 
					puts "Starting ISCSI"
					start_istgt(nwscreen.get_addresses[0])
					extlayers["sambarunning"].show_all
				else
					puts "Starting SAMBA"
					mount_all
					system("nmbd -D")
					system("smbd -D")
				end
				extlayers["sambarunning"].show_all
			end
		}
		# FIXME: translate "oder"
		stoppane.signal_connect('show') { 
			stoppane.set_markup("<span foreground='white'><b>" + @tl.get_translation("shareactivehead") + "</b>\n\n" + @tl.get_translation("shareactivebody").gsub("JOINEDADRESSES", nwscreen.get_addresses.join(" oder ")) + "</span>") # if $startup_finished 
		}
	end
	
	attr_reader :layers
	
	def prepare_sambaquest(nwscreen)
		if nwscreen.test_link == false
			nwscreen.nextscreen = "sambaquest"
			nwscreen.fill_wlan_combo 
			return "networks"
		end
		return "sambaquest"
	end
	
	def start_istgt(ipaddr)
		puts "Using IP address #{ipaddr}"
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ || l =~ /mmcblk[0-9]$/
		}
		# Copy base configuration:
		configout = File.new("/etc/istgt/istgt.conf.cbrescue", "w")
		File.open("config/istgt.conf").each { |line|
			configout.write(line.gsub("IPADDRESS", ipaddr))
		}
		lun = 0
		drives.each { |d|
			if d.mounted == false
				lun += 1
				configout.write("[LogicalUnit#{lun}]\n")
				configout.write("  Comment \"Hard Disk #{lun}\"\n")
				configout.write("  TargetName #{d.device}\n")
				configout.write("  TargetAlias \"Data Disk#{lun}\"\n")
				configout.write("  Mapping PortalGroup1 InitiatorGroup1\n")
				configout.write("  AuthMethod Auto\n")
				configout.write("  AuthGroup AuthGroup1\n")
				if @rwcheck.active? == true
					configout.write("  ReadOnly No\n")
				else
					configout.write("  ReadOnly Yes\n")
				end
				configout.write("  UseDigest Auto\n")
				configout.write("  UnitType Disk\n")
				configout.write("  LUN0 Storage /dev/#{d.device} Auto\n\n")
			end
		}
		configout.close
		system("cp -v config/auth.conf /etc/istgt/auth.conf.cbrescue")
		system("istgt -c /etc/istgt/istgt.conf.cbrescue")
	end
	
	
	def mount_all(writeable_part=nil)
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ || l =~ /mmcblk[0-9]$/
		}
		drives.each { |d|
			d.partitions.each { |p|
				if p.device == writeable_part
					system("mkdir -p /media/" + @tl.get_translation("backupdir")) 
					p.mount("rw", "/media/" + @tl.get_translation("backupdir"), 1000, 1000)
				else
					system("mkdir -p /media/#{p.device}")
					p.mount("ro", "/media/#{p.device}", 1000, 1000)
				end
			}
		}
	end
	
end