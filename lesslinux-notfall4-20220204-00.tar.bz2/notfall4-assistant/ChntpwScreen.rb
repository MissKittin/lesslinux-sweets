#!/usr/bin/ruby
# encoding: utf-8

class ChntpwScreen	
	def initialize(extlayers, button, nwscreen)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "ChntpwScreen.xml")
		@layers = Array.new
		#### Global variables
		# Combobox for selection of partition
		@drivecombo = nil
		@partlist = Array.new
		#### Combobox for selection of Users
		@usercombo = nil
		@userlist = Array.new
		@humanusers = Array.new
		
		###### First layer for selection of windows installation
		
		fixed = Gtk::Fixed.new
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		
		orangetile = Gtk::Image.new("chntpwgreen.png")
		# reread = Gtk::EventBox.new.add Gtk::Image.new("buttongreen.png")
		# reread = Gtk::Button.new("Neu einlesen")
		# reread.width_request = 120
		# reread.height_request = 32
		@drivecombo = Gtk::ComboBox.new
		# @drivecombo.append_text("Yoyodyne Frobolator SATA Partition 2 500GB (sda2)") 
		# @drivecombo.active = 0
		@drivecombo.height_request = 32
		@drivecombo.width_request = 510
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("winhead") + "</b>\n\n" + @tl.get_translation("winbody") , 510)
		
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		# fixed.put(orangetile, 0, 0)
		fixed.put(deltext, 0, 0)
		# fixed.put(reread, 520, 88)
		fixed.put(@drivecombo, 0, 108)
		TileHelpers.place_back(fixed, extlayers)
		extlayers["chntpwstart"] = fixed
		@layers[0] = fixed
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# reread drives here!
				# @partlist = find_win_sysparts(@drivecombo)
				extlayers.each { |k,v|v.hide_all }
				extlayers["DEAD_chntpwchooser"].show_all
			end
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @partlist.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("nowinbody"), @tl.get_translation("nowinhead"))
				else
					# reread users here!
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					@userlist, @humanusers = get_nt_users(@partlist[@drivecombo.active], @usercombo) 
					if @userlist.size < 1
						extlayers.each { |k,v|v.hide_all }
						extlayers["chntpwchooser"].show_all
						TileHelpers.error_dialog(@tl.get_translation("nouserbody"), @tl.get_translation("nouserhead"))
					else
						extlayers.each { |k,v|v.hide_all }
						extlayers["chntpwuser"].show_all
					end
				end
			end
		}
		
		###### Second layer for selection of user
		fixeduser = Gtk::Fixed.new
		text6 = Gtk::Label.new
		text6.width_request = 230
		text6.wrap = true
		text6.set_markup("<span color='white'>" + @tl.get_translation("resetnow") + "</span>")
		forw2  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		orange2tile = Gtk::EventBox.new.add Gtk::Image.new("chntpwgreen.png")
		usertext = TileHelpers.create_label("<b>" + @tl.get_translation("userhead") + "</b>\n\n" + @tl.get_translation("userbody") , 510)
		TileHelpers.place_back(fixeduser, extlayers)
		@usercombo = Gtk::ComboBox.new
		@usercombo.append_text("Heinz Mustermann") 
		@usercombo.active = 0
		@usercombo.height_request = 32
		@usercombo.width_request = 510
		fixeduser.put(forw2, 650, 352)
		fixeduser.put(text6, 402, 358)
		fixeduser.put(usertext, 0, 0)
		# fixeduser.put(orange2tile, 0, 0)
		fixeduser.put(@usercombo, 0, 76)
		onlinetext = TileHelpers.create_label(@tl.get_translation("useronline") , 510)
		fixeduser.put(onlinetext, 0, 120)
		ffbutton = Gtk::Button.new(@tl.get_translation("fflink"))
		ffbutton.width_request = 510
		ffbutton.height_request = 32
		fixeduser.put(ffbutton, 0, 182)
		ffbutton.signal_connect("clicked") {
			if nwscreen.test_connection == false
				nwscreen.nextscreen = "chntpwuser"
				nwscreen.fill_wlan_combo 
				extlayers.each { |k,v|v.hide_all }
				extlayers["networks"].show_all
			end
			system("su surfer -c 'firefox https://account.live.com/resetpassword.aspx?mkt=de-de' &")
		}
		extlayers["chntpwuser"] = fixeduser
		@layers[1] = fixeduser
		
		forw2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				run_chntpw(@partlist[@drivecombo.active], @userlist[@usercombo.active])
				# TileHelpers.success_dialog( @tl.get_translation("successbody").gsub("USERNAME", "Heinz Mustermann").gsub("WINPARTITION", "sda1"), @tl.get_translation("successhead") )
				TileHelpers.success_dialog( @tl.get_translation("successbody").gsub("USERNAME", @humanusers[@usercombo.active]).gsub("WINPARTITION", @partlist[@drivecombo.active].device), @tl.get_translation("successhead") )
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		
		### Layer for choosing between functions
		fixedchooser = Gtk::Fixed.new
		tile1 = Gtk::EventBox.new.add Gtk::Image.new("chntpwpasswd.png")
		tile2 = Gtk::EventBox.new.add Gtk::Image.new("chntpwdislocker.png")
		
		textchntpw = Gtk::Label.new
		textchntpw.width_request = 450
		textchntpw.wrap = true
		textchntpw.set_markup("<span foreground='white'>" + @tl.get_translation("choosergotochntpw") + "</span>")
		
		textbitlock = Gtk::Label.new
		textbitlock.width_request = 450
		textbitlock.wrap = true
		textbitlock.set_markup("<span foreground='white'>" + @tl.get_translation("choosergotobitlock") + "</span>")
		
		TileHelpers.place_back(fixedchooser, extlayers)
		fixedchooser.put(tile1, 0, 0)
		fixedchooser.put(tile2, 0, 130)
		fixedchooser.put(textchntpw, 130, 0)
		fixedchooser.put(textbitlock, 130, 130)
		
		tile1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# reread drives here!
				# @partlist = find_win_sysparts(@drivecombo)
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				@partlist = find_win_sysparts(@drivecombo)
				extlayers.each { |k,v|v.hide_all }
				extlayers["chntpwstart"].show_all
			end
		}
		
		tile2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("su surfer -c \"firefox http://go.microsoft.com/fwlink/p/?LinkId=237614\" &")
			end
		}
		
		extlayers["DEAD_chntpwchooser"] = fixedchooser
		@layers[2] = fixedchooser
	end
	
	attr_reader :layers
	
	def prepare_chntpwstart
		# reread drives here!
		@partlist = find_win_sysparts(@drivecombo)
	end
	
	def find_win_sysparts(combobox)
		TileHelpers.set_lock 
		drives = Array.new
		auxdrives = Array.new
		ntparts = Array.new 
		100.downto(0) { |i| 
			begin
				combobox.remove_text(i) 
			rescue
			end
		}
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				d = MfsDiskDrive.new(l, false)
				auxdrives.push(d) 
			end
		}
		# mountpoint = "/var/run/lesslinux/" + $$.to_s + "/testmount"
		# system("mkdir -p #{mountpoint}") unless  File.exist?(mountpoint)
		auxdrives.each { |d|
			d.partitions.each { |p|
				# p.mount("ro", mountpoint)
				winpart, winvers = p.is_windows
				#if File.exist?("#{mountpoint}/Windows/System32/config/SAM") ||
				#		File.exist?("#{mountpoint}/WINDOWS/system32/config/SAM")
				if winpart == true 
					ntparts.push p
					label = "#{winvers} - #{d.vendor} #{d.model}"
					if d.usb == true
						label = label + " (USB) "
					else
						label = label + " (SATA/eSATA/IDE/NVME) "
					end
					label = label + "#{p.device} #{p.human_size}"
					combobox.append_text label
					p.umount 
				end
			}
		}
		# combobox.append_text("Windows 8.1 auf sdb1 (SATA/eSATA/IDE)") 
		combobox.active = 0 
		TileHelpers.remove_lock
		return ntparts
	end

	def get_nt_users(p, combobox)
		TileHelpers.set_lock 
		winpart, winvers = p.is_windows
		if winpart == false
			TileHelpers.remove_lock
			return nil
		end
		100.downto(0) { |i| 
			begin
				combobox.remove_text(i) 
			rescue
			end
		}
		p.mount("rw")
		samusers = Array.new
		clearusers = Array.new
		
		auxsam = p.samfile
		winusers = Array.new 		
		winusers.push(auxsam.read_users)
		winusers.each { |w|
			w.each { |u|
				samusers.push(u[0])
				clearusers.push(u[1])
				combobox.append_text("#{u[1]} (0x#{u[0]})")
			}
		}
		p.umount
		combobox.active = 0 
		TileHelpers.remove_lock 
		return samusers, clearusers
	end

	def run_chntpw(partition, user)
		TileHelpers.set_lock 
		puts partition.device
		puts user
		partition.mount("rw") 
		mountpoint = partition.mount_point[0] 
		
		windir = nil
		sysdir = nil
		cfgdir = nil
		samfile = nil
		[ "Windows", "WINDOWS", "windows"].each { |w| windir = w if File.directory?(mountpoint + "/" + w) }
		[ "System32", "SYSTEM32", "system32" ].each { |s| sysdir = windir + "/" + s if File.directory?(mountpoint+ "/" + windir + "/" + s) }
		[ "Config", "CONFIG", "config" ].each { |c| cfgdir = sysdir + "/" + c if File.directory?(mountpoint + "/" + sysdir + "/" + c) }
		puts cfgdir.to_s 
		if cfgdir.nil? 
			TileHelpers.remove_lock
			return false
		end
		[ "Sam", "SAM", "sam" ].each { |f| samfile = cfgdir + "/" + f if File.exists?(mountpoint + "/" + cfgdir + "/" + f) }
		if samfile.nil?
			TileHelpers.remove_lock 
			return false
		end
		
		# valid_reg = system('echo -e "q\n" | chntpw -e ' + reg_file) 
		exstring = "printf \"1\\n\\ny\\n\" | chntpw -u 0x" + user  + " '" + mountpoint + "/" + samfile + "'"
		# exstring = 'echo -e "1\ny\n" | chntpw -u 0x' + user + ' ' + samfile
		puts exstring
		retval = system(exstring)
		partition.umount 
		puts retval.to_s
		TileHelpers.remove_lock
		return retval
	end
	
	
	
end