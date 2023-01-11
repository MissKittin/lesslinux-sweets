#!/usr/bin/ruby
# encoding: utf-8

class WindowsScreen	
	def initialize(extlayers, button, nwscreen)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@lang = lang
		@tl = MfsTranslator.new(lang, "WindowsScreen.xml")
		@extlayers = extlayers
		@layers = Array.new
		@nwscreen = nwscreen 
		## table for first SMART read out
		@smarttab = nil
		@smart_quick_icons = Array.new
		@smart_quick_descriptions = Array.new
		## progressbar for SMART self test routine
		@smart_progress = nil
		@break_smart_test = nil
		## table for second SMART readout
		@smartsumtab = nil
		@smart_detail_icons = Array.new
		@smart_detail_descriptions = Array.new
		## Button and description to jump to save function
		@save_button = nil
		@save_text = nil
		## Button and progress bar for CPU burn
		@cpuburnprogress = Gtk::ProgressBar.new
		@killcpuburn = Gtk::Button.new(@tl.get_translation("cancelcpuburn"))
		@killcpuburn.sensitive = false
		@cooling = false
		@cpuburn_next = "winfixsmart"
		## Shell fix
		@wincombo = nil 
		@winparts = nil
		@regfiles = nil
		## Gpart
		@gpartcombo = nil
		@gpartdrives = nil
		@break_partrecover = nil
		@partrecover_progress = nil
		@rawparts = Array.new 
		@partrecover_killed = false 
		@mountloopradio = nil
		@writeparttableradio = nil 
		@gparttargetcombo = nil
		@gparttargetparts = Array.new
		@gpartdisk = nil 
		@partdonefinishedtext = nil
		## DVD burn
		@tempcombo = nil 
		@tempparts = nil 
		@dvdcombo = nil 
		@dvdprogress = nil 
		@dvdworking = false
		@dvdvte = Vte::Terminal.new
		@dvdvte.signal_connect("child_exited") { @dvdworking = false }
		@dvdkeepiso = Gtk::CheckButton.new
		@dvdkeepiso.active = true 
		@dvdusexfburn = Gtk::CheckButton.new
		@dvdusexfburn.active = true
		# Mode to use? 0 = installationdisk, 1 = repairdisk
		@dvdburnmode = 0
		@dvdburnlabel = nil
		@otherdvdlabel = nil 
		@isonames = [
			[ "Windows 10", "Windows 8.1", "Windows 7" ],
			[       "Windows 10 (64 Bit, UEFI)",
				"Windows 10 (64 Bit, BIOS)",
				"Windows 10 (32 Bit)", 
				"Windows 7 (64 Bit)",
				"Windows 7 (32 Bit)", 
				"Windows 8 (64 Bit, UEFI)",
				"Windows 8 (64 Bit, BIOS)"
			]
		]
		@isourls = [
			[ "https://www.microsoft.com/de-de/software-download/windows10ISO",
			"https://www.microsoft.com/de-de/software-download/windows8ISO",
			"https://www.microsoft.com/de-de/software-download/windows7" ],
			[  "https://c.computerbild.de/download/notfalldvd/Windows_10_Reparaturdatentraeger_64_Bit.iso", 
			"https://c.computerbild.de/download/notfalldvd/bios_Windows_10_Reparaturdatentraeger_64_Bit.iso",
			"https://c.computerbild.de/download/notfalldvd/Windows_10_Reparaturdatentraeger_32_Bit.iso",
			"https://c.computerbild.de/download/notfalldvd/reparaturdatentraeger_windows_7_64_bit.iso",
			"https://c.computerbild.de/download/notfalldvd/reparaturdatentraeger_windows_7_32_bit.iso",
			"https://c.computerbild.de/download/notfalldvd/reparaturdatentraeger_windows_8_64_Bit.iso",
			"https://c.computerbild.de/download/notfalldvd/bios_reparaturdatentraeger_windows_8_64_Bit.iso" 
			]
		]
		if @lang == "pl"
			@isourls[0][0] = "https://www.microsoft.com/pl-pl/software-download/windows10ISO"
			@isourls[0][1] = "https://www.microsoft.com/pl-pl/software-download/windows8ISO"
			@isourls[0][2] = "https://www.microsoft.com/pl-pl/software-download/windows7"
		end
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenwine.png")
		button2 = Gtk::EventBox.new.add Gtk::Image.new("reparierenorange.png")
		button3 = Gtk::EventBox.new.add Gtk::Image.new("reparierenpurple.png")
		button5 = Gtk::EventBox.new.add Gtk::Image.new("reparierenlight.png")
		button6 = Gtk::EventBox.new.add Gtk::Image.new("reparierenpurple.png")
		@gpartbutton = Gtk::EventBox.new.add Gtk::Image.new("recoverx3.png")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		
		text1 = Gtk::Label.new
		text1.width_request = 320
		text1.wrap = true
		text1.set_markup("<span foreground='white'>" + @tl.get_translation("freeze") + "</span>")
		
		text2 = Gtk::Label.new
		text2.width_request = 320
		text2.wrap = true
		text2.set_markup("<span foreground='white'>" + @tl.get_translation("ntldr") + "</span>")
		
		text3 = Gtk::Label.new
		text3.width_request = 320
		text3.wrap = true
		text3.set_markup("<span foreground='white'>" + @tl.get_translation("noos") + "</span>")
		
		text5 = Gtk::Label.new
		text5.width_request = 320
		text5.wrap = true
		text5.set_markup("<span foreground='white'>" + @tl.get_translation("shell") + "</span>")
		
		text6 = Gtk::Label.new
		text6.width_request = 320
		text6.wrap = true
		text6.set_markup("<span foreground='white'>" + @tl.get_translation("burninstalldvd") + "</span>")
	
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		
		fixed = Gtk::Fixed.new
		fixed.put(button1, 0, 0)
		fixed.put(button2, 0, 130)
		fixed.put(button3, 460, 0)
		fixed.put(button5, 460, 130)
		fixed.put(back, 852, 332)
		
		fixed.put(text1, 130, 20)
		fixed.put(text2, 130, 130)
		fixed.put(text3, 590, 20)
		fixed.put(text5, 590, 130)
		fixed.put(text4, 605, 338)
		
		unless @lang =~ /pl/i 
			fixed.put(text6, 130, 280)
			fixed.put(button6, 0, 260)
		end
		
		@layers[0] = fixed
		extlayers["DEAD_winfixstart"] = fixed 
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["DEAD_winfixstart"].show_all
				# extlayers["winfixstart"].show_all
				# @cpuburn_next = "winfixstart"
				# run_cpuburn(extlayers)
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		button1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["winfixcpuburn"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				@smart_quick_icons, @smart_quick_descriptions, @smarttab = fill_smart_tab(@smart_quick_icons, @smart_quick_descriptions, @smarttab)
				@cpuburn_next = "winfixsmart"
				run_cpuburn(extlayers)
			end
		}
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["winfixntldr"].show_all
			end
		}
		button3.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["winfixmssys"].show_all
			end
		}
		button5.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				fill_win_combo(@wincombo) 
				extlayers["winfixshell"].show_all
			end
		}
		button6.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
			#	if nwscreen.test_connection == false
			#		nwscreen.nextscreen = "winfixstart"
			#		nwscreen.fill_wlan_combo 
			#		# Check for networks first...
			#		extlayers.each { |k,v|v.hide_all }
			#		extlayers["networks"].show_all
			#		0.upto(50) { |n|
			#			while (Gtk.events_pending?)
			#				Gtk.main_iteration
			#			end
			#			sleep 0.2
			#		}
			#	end
			#	system("su surfer -c 'firefox file:///usr/share/doc/notfall-dvd/WinFAQ/winfaq/WinFAQ.htm' &")
				
				if @nwscreen.test_connection == false
					@nwscreen.nextscreen = "dvdstartpanel"
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					@dvdburnmode = 0
					fill_temp_drives
					@nwscreen.fill_wlan_combo 
					extlayers.each { |k,v|v.hide_all }
					extlayers["networks"].show_all
				else
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					@dvdburnmode = 0
					fill_temp_drives
					extlayers.each { |k,v|v.hide_all }
					extlayers["dvdstartpanel"].show_all
				end
			end
		}
		@gpartbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				reread_gpartdrives
				extlayers["winfindpartitions"].show_all
				# system("su surfer -c 'firefox file:///lesslinux/cdrom/winfaq.html' &")
			end
		}
		#### Panel for NTLDR ...
		
		ntldrpane = Gtk::Fixed.new
		ntldrtext = Gtk::Label.new
		ntldrtext.width_request = 640
		ntldrtext.wrap = true
		ntldrtext.set_markup("<span foreground='white'>" + @tl.get_translation("ntldrbody") + "</span>")
		textxp = Gtk::Label.new
		textxp.width_request = 250
		textxp.wrap = true
		textxp.set_markup("<span foreground='white'>" + @tl.get_translation("create_rep_isos") + "</span>")
		text7x = Gtk::Label.new
		text7x.width_request = 120
		text7x.wrap = true
		text7x.set_markup("<span foreground='white'>" + @tl.get_translation("ntldrvista") + "</span>")
		manualxp = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		manual7 = Gtk::EventBox.new.add Gtk::Image.new("qrwin7repair.png") # pdforange.png")
		checkhd = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		checktext = Gtk::Label.new
		checktext.width_request = 250
		checktext.wrap = true
		checktext.set_markup("<span foreground='white'>" + @tl.get_translation("ntldrsmart") + "</span>")
		back2 = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		text5x = Gtk::Label.new
		text5x.width_request = 250
		text5x.wrap = true
		text5x.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		text810 = Gtk::Label.new
		text810.width_request = 120
		text810.wrap = true
		text810.set_markup("<span foreground='white'>" + @tl.get_translation("ntldr810") + "</span>")
		manual810 = Gtk::EventBox.new.add Gtk::Image.new("qrwin8repair.png") # pdfwine.png")
		
		ntldrpane.put(ntldrtext, 0, 0)
		
		# Eventbox Reparaturdatenträger erstellen
		ntldrpane.put(manualxp, 650, 352)
		ntldrpane.put(textxp, 402, 358)
		
		ntldrpane.put(manual7, 0, 300)
		ntldrpane.put(text7x, 130, 332)
		
		#ntldrpane.put(checkhd, 650, 352)
		#ntldrpane.put(checktext, 402, 358)
		
		ntldrpane.put(back2, 650, 402)
		ntldrpane.put(text5x, 402, 408)
		
		ntldrpane.put(text810, 130, 182)
		ntldrpane.put(manual810, 0, 150)
		
		@layers[1] = ntldrpane
		extlayers["winfixntldr"] = ntldrpane 
		
		back2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		manualxp.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				if @nwscreen.test_connection == false
					@nwscreen.nextscreen = "dvdstartpanel"
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					@dvdburnmode = 1
					fill_temp_drives
					@nwscreen.fill_wlan_combo 
					extlayers.each { |k,v|v.hide_all }
					extlayers["networks"].show_all
				else
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					@dvdburnmode = 1
					fill_temp_drives
					extlayers.each { |k,v|v.hide_all }
					extlayers["dvdstartpanel"].show_all
				end
			end
		}
		manual7.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				if File.exists?("Anleitungen/RepairVista7.#{@lang}.pdf") 
					TileHelpers.open_pdf("Anleitungen/RepairVista7.#{@lang}.pdf") 
				else
					TileHelpers.open_pdf("Anleitungen/Vista- und 7-Reparatur.pdf")
				end
			end
		}
		manual810.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				if File.exists?("Anleitungen/RepairWin810.#{@lang}.pdf") 
					TileHelpers.open_pdf("Anleitungen/RepairWin810.#{@lang}.pdf") 
				else
					TileHelpers.open_pdf("Anleitungen/Windows-8-10-Reparatur.pdf")
				end
			end
		}
		checkhd.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				@smart_quick_icons, @smart_quick_descriptions, @smarttab = fill_smart_tab(@smart_quick_icons, @smart_quick_descriptions, @smarttab)
				extlayers["winfixsmart"].show_all
			end
		}
		
		#### Panel for CPUBURN
		cpuburnpanel = create_cpuburn_panel(extlayers)
		extlayers["winfixcpuburn"] = cpuburnpanel 
		@layers[7] = cpuburnpanel 
		
		#### Panel for SMART check
		
		smartpanel = create_smart_panel(extlayers)
		extlayers["winfixsmart"] = smartpanel 
		@layers[2] = smartpanel 
		
		#### Panel for running SMART check
		smartcheck = create_smart_running(extlayers)
		extlayers["winfixcheck"] = smartcheck 
		@layers[3] = smartcheck
		
		#### Panel for SMART summary
		smartsummary = create_smart_summary(extlayers)
		extlayers["winfixsummary"] = smartsummary 
		@layers[4] = smartsummary
		
		#### Panel for ms-sys
		mssyspanel = create_mssys_panel(extlayers)
		extlayers["winfixmssys"] = mssyspanel 
		@layers[5] = mssyspanel
		
		#### Panel for ms-sys done
		mbrdonepanel = create_mbrdone_panel(extlayers)
		extlayers["winfixmbrdone"] = mbrdonepanel 
		@layers[6] = mbrdonepanel
		
		#### Panel for shell
		shellpanel = create_shell_panel(extlayers)
		extlayers["winfixshell"] = shellpanel 
		@layers[8] = shellpanel
		
		#### Panel for shell done
		shelldone = create_shelldone_panel(extlayers)
		extlayers["winfixshelldone"] = shelldone
		@layers[9] = shelldone
		
		#### Panel for search of lost partitions
		partitionpanel = create_gpart_drivelist(extlayers)
		extlayers["winfindpartitions"] = partitionpanel
		@layers[10] = partitionpanel
		
		#### Panel for progress on partition search
		partprogpanel = create_partprogress_panel(extlayers)
		extlayers["winfindpartprogress"] = partprogpanel
		@layers[11] = partprogpanel
		
		#### Panel for summary of partition search
		partdonepanel = create_partdone_panel(extlayers)
		extlayers["winfindpartdone"] = partdonepanel
		@layers[12] = partdonepanel
		
		#### Panel for DVD creation start
		dvdstartpanel = create_dvd_panel(extlayers)
		extlayers["dvdstartpanel"] = dvdstartpanel
		@layers[13] = dvdstartpanel
		
		#### Panel for DVD creation progress
		dvdprogresspanel = create_dvd_progress_panel(extlayers)
		extlayers["dvdburnprogress"] = dvdprogresspanel
		@layers[14] = dvdprogresspanel
		
	end
	
	attr_reader :layers, :gpartbutton 
	
	def prepare_winfindpartitions
		reread_gpartdrives
	end
	
	def prepare_winfixcpuburn(extlayers)
		@smart_quick_icons, @smart_quick_descriptions, @smarttab = fill_smart_tab(@smart_quick_icons, @smart_quick_descriptions, @smarttab)
		@cpuburn_next = "winfixsmart"
		run_cpuburn(extlayers)
	end
	
	def prepare_dvdstartpanel(burnmode=1)
		if @nwscreen.test_connection == false
			@nwscreen.nextscreen = "dvdstartpanel"
			@dvdburnmode = burnmode
			fill_temp_drives
			@nwscreen.fill_wlan_combo
			return "networks"
		else
			@dvdburnmode = burnmode
			fill_temp_drives
			return "dvdstartpanel"
		end
	end
	
	def create_ntldr_panel
		
	end
	
	def create_cpuburn_panel(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("burnhead") + "</b>\n\n" + @tl.get_translation("burnbody"), 510)
		@cpuburnprogress.width_request = 380
		@cpuburnprogress.height_request = 32
		@killcpuburn.width_request = 120
		@killcpuburn.height_request = 32
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@cpuburnprogress, 0, 170)
		fixed.put(@killcpuburn, 385, 170)
		back = TileHelpers.place_back(fixed, extlayers, false)
		@killcpuburn.signal_connect("clicked") {
			# kill cpu burn
			@cpuburn_next = "winfixsmart"
			system("killall -9 cpuburn")
			TileHelpers.remove_lock
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# kill cpu burn
				@cpuburn_next = "start"
				system("killall -9 cpuburn")
			end
		}
		return fixed
	end
	
	def read_temp(kill=true)
		cputemp = 0
		critical = 80
		lcount = 0
		cpuline = -1
		IO.popen("sensors") { |line|
			while line.gets 
				# CPU Temperature:    +49.0°C  (high = +60.0°C, crit = +95.0°C)
				# temp1: +70.0°C (crit = +92.0°C)
				# 
				# temp1: +44.8°C (high = +70.0°C)
				#                (crit = +100.0°C, hyst = +97.0°C) 
				if $_ =~ /cpu temperature.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 
					puts "Core: " + $1
					puts "Crit: " + $2
					cputemp = $1.to_i 
					critical = $2.to_i 
				elsif $_ =~ /^temp\d.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 	
					puts "Core: " + $1
					puts "Crit: " + $2
					cputemp = $1.to_i 
					critical = $2.to_i
				elsif $_ =~ /^temp\d.*?\+(\d+)\.\d°C.*?high.*?(\d+)\.\d°C/i 
					puts "Core: " + $1
					puts "High: " + $2
					cpuline = lcount
					cputemp = $1.to_i
				elsif  lcount - cpuline == 1 
					puts $_
					if $_ =~ /^\s*\(.*?crit.*?(\d+)\.\d°C/i 
						puts "Crit: " + $1
						critical = $1.to_i
					end
				end
				lcount += 1
			end
			if critical - cputemp < 6 && kill == true
				system("killall -9 cpuburn")
				@cooling = true
				TileHelpers.error_dialog(@tl.get_translation("toohotbody"), @tl.get_translation("toohothead"))
			end
		}
		return cputemp, critical
	end
	
	def run_cpuburn(extlayers)
		TileHelpers.set_lock 
		pgbar = @cpuburnprogress
		pgbar.text = @tl.get_translation("burnhead") 
		sensors_found = false
		IO.popen("sensors") { |line|
			while line.gets
				sensors_found = true if $_ =~ /cpu temperature.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 
				sensors_found = true if $_ =~ /temp\d.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 	
				sensors_found = true if $_ =~ /temp\d.*?\+(\d+)\.\d°C.*?high.*?(\d+)\.\d°C/i 
			end
		}
		# sensors_found = false unless system("which sensors")
		if sensors_found == false
			TileHelpers.error_dialog(@tl.get_translation("nosensorbody"), @tl.get_translation("nosensorhead"))
			extlayers.each { |k,v|v.hide_all }
			extlayers[@cpuburn_next].show_all
			TileHelpers.remove_lock
			return false
		end
		vte = Vte::Terminal.new
		running = true
		vte.signal_connect("child_exited") { running = false }
		vte.fork_command("cpuburn", [ "cpuburn"] )
		@killcpuburn.sensitive = true
		cycle = 0
		pgbar.fraction = 0.0
		cputemp = 0
		critical = 80
		while running == true && cycle < 1800  
			remaining = ( 1800 - cycle ) / 10  
			if cycle % 10 == 0
				pgbar.fraction = cycle.to_f / 1800.to_f 
				pgbar.text = @tl.get_translation("cpuburnprog1").gsub("REMAINING", remaining.to_s) 
				pgbar.text = @tl.get_translation("cpuburnprog2").gsub("REMAINING", remaining.to_s).gsub("TEMPERATURE", cputemp.to_s)  if cputemp > 0
			end
			if cycle % 30 == 0
				cputemp, critical = read_temp
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.1
			cycle += 1 
		end
		system("killall -9 cpuburn")
		@killcpuburn.sensitive = false
		pgbar.fraction = 1.0
		# Cool down
		cycle = 0
		while cycle < 300 && cputemp > 60
			remaining = ( 300 - cycle ) / 10  
			if cycle % 10 == 0
				pgbar.fraction = cycle.to_f / 300.to_f 
				pgbar.text = @tl.get_translation("cooldown").gsub("REMAINING", remaining.to_s).gsub("TEMPERATURE", cputemp.to_s)
			end
			if cycle % 30 == 0
				cputemp, critical = read_temp(false)
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.1
			cycle += 1 
		end
		TileHelpers.remove_lock 
		extlayers.each { |k,v|v.hide_all }
		extlayers[@cpuburn_next].show_all
	end
	
	def create_smart_panel(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		# fixed.put(button1, 0, 0)
		smarttext = TileHelpers.create_label("<b>" + @tl.get_translation("smarthead") +"</b>\n\n" + @tl.get_translation("smartbody") , 700)
		fixed.put(smarttext, 0, 0)
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotosmart") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		smartscroll = Gtk::ScrolledWindow.new
		smartscroll.height_request = 175
		smartscroll.width_request = 700
		@smarttab = Gtk::Table.new(1, 2, false)
		@smarttab.column_spacings = 10 
		@smarttab.row_spacings = 10 
		smartalign = Gtk::Alignment.new(0, 0, 0.1, 0.1)
		smartalign.add @smarttab
		smartscroll.add_with_viewport smartalign
		smartscroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC ) 
		fixed.put(smartscroll, 0, 96)
		anc = @smarttab.get_ancestor(Gtk::Viewport)
		anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#052f4c') )
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["winfixcheck"].show_all
				# TileHelpers.success_dialog("DUMMY: In der finalen Version läuft jetzt der Fortschrittsbalken durch, dann springt der Assistent auf den nächsten Bildschirm.", "DUMMY-Hinweis")
				res = run_smart_test(@smart_progress, @break_smart_test)
				extlayers["winfixcheck"].hide_all
				if res == true
					@smart_detail_icons, @smart_detail_descriptions, @smartsumtab, errors = fill_smart_tab(@smart_detail_icons, @smart_detail_descriptions, @smartsumtab, true)
					extlayers["winfixsummary"].show_all
					[ @save_button, @save_text ].each { |w| w.hide_all }
					if errors == true
						[ @save_button, @save_text ].each { |w| w.show_all }
					end
				end
			end
		}
		return fixed
	end
	
	def create_smart_running(extlayers)
		fixed = Gtk::Fixed.new
		@break_smart_test = TileHelpers.place_back(fixed, extlayers, false)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		# fixed.put(button1, 0, 0)
		@smart_progress = Gtk::ProgressBar.new
		@smart_progress.width_request = 510
		@smart_progress.height_request = 32
		fixed.put(@smart_progress, 0, 98)
		progresstext = TileHelpers.create_label("<b>" + @tl.get_translation("smartproghead") + "</b>\n\n" + @tl.get_translation("smartprogbody"), 510)
		fixed.put(progresstext, 0, 0)
		@smart_progress.text = @tl.get_translation("smartstart") 
		return fixed
	end
	
	def create_smart_summary(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		# fixed.put(button1, 0, 0)
		smarttext = TileHelpers.create_label("<b>" + @tl.get_translation("smartresulthead") +"</b>\n\n" +@tl.get_translation("smartresultbody") , 700)
		fixed.put(smarttext, 0, 0)
		@save_text = TileHelpers.create_label(@tl.get_translation("gotorescue"), 230)
		@save_button  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		fixed.put(@save_button, 650, 352)
		fixed.put(@save_text, 402, 358)
		smartscroll = Gtk::ScrolledWindow.new
		smartscroll.height_request = 255
		smartscroll.width_request = 700
		# Now some dummy content: 
		# vbox = Gtk::VBox.new
		# 
		@smartsumtab = Gtk::Table.new(2, 2, false)
		@smartsumtab.column_spacings = 10 
		@smartsumtab.row_spacings = 10 
		smartalign = Gtk::Alignment.new(0, 0, 0.1, 0.1)
		smartalign.add @smartsumtab
		smartscroll.add_with_viewport smartalign
		smartscroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC ) 
		fixed.put(smartscroll, 0, 88)
		anc = @smartsumtab.get_ancestor(Gtk::Viewport)
		anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#052f4c') )
		@save_button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["rescuestart"].show_all
			end
		}
		return fixed
		
	end
	
	def create_mssys_panel(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		# fixed.put(button1, 0, 0)
		mssystext = TileHelpers.create_label("<b>" + @tl.get_translation("mbrhead") + "</b>\n\n" + @tl.get_translation("mbrbody"), 450)
		fixed.put(mssystext, 0, 0)
		brokenparttext = TileHelpers.create_label("<b>" + @tl.get_translation("brokenparthead") + "</b>\n\n" + @tl.get_translation("brokenpartbody"), 450)
		fixed.put(brokenparttext, 0, 180)
		
		
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotofixmbr") + "</span>")
		
		text6 = Gtk::Label.new
		text6.width_request = 250
		text6.wrap = true
		text6.set_markup("<span color='white'>" + @tl.get_translation("gotopartrescue") + "</span>")
		
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		gotopart =  Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		fixed.put(forw, 403, 110)
		fixed.put(text5, 152, 116)
		fixed.put(gotopart, 403, 290)
		fixed.put(text6, 152, 296)
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				fix_mbr
				extlayers["winfixmbrdone"].show_all
			end
		}
		gotopart.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				reread_gpartdrives
				extlayers["winfindpartitions"].show_all
			end
		}
		return fixed
	end
	
	def create_mbrdone_panel(extlayers)
		fixed = Gtk::Fixed.new
		ntldrtext = TileHelpers.create_label("<b>" + @tl.get_translation("mbrsuccesshead") + "</b>\n\n" +@tl.get_translation("mbrsuccessbody") , 640)
		
		textxp = Gtk::Label.new
		textxp.width_request = 120
		textxp.wrap = true
		textxp.set_markup("<span foreground='white'>" + @tl.get_translation("repairxp") + "</span>")
		text7 = Gtk::Label.new
		text7.width_request = 120
		text7.wrap = true
		text7.set_markup("<span foreground='white'>" + @tl.get_translation("repairvista") + "</span>")
		text8 = Gtk::Label.new
		text8.width_request = 120
		text8.wrap = true
		text8.set_markup("<span foreground='white'>" + @tl.get_translation("repairwin8") + "</span>")
		text10 = Gtk::Label.new
		text10.width_request = 120
		text10.wrap = true
		text10.set_markup("<span foreground='white'>" + @tl.get_translation("repairwin10") + "</span>")
		text11 = Gtk::Label.new
		text11.width_request = 250
		text11.wrap = true
		text11.set_markup("<span foreground='white'>" +  @tl.get_translation("burninstalldvdshort") + "</span>")
		
		manualxp = Gtk::EventBox.new.add Gtk::Image.new("qrwinxpinstall.png")
		manual7 = Gtk::EventBox.new.add Gtk::Image.new("qrwin7install.png")
		manual8 = Gtk::EventBox.new.add Gtk::Image.new("qrwin8install.png")
		manual10 = Gtk::EventBox.new.add Gtk::Image.new("qrwin10install.png")
		manual11 = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		
		TileHelpers.place_back(fixed, extlayers)
		fixed.put(ntldrtext, 0, 0)
		# fixed.put(manualxp, 0, 130)
		fixed.put(manual7, 0, 130)
		# fixed.put(textxp, 130, 162)
		fixed.put(text7, 130, 162)
		fixed.put(manual8, 260, 130)
		fixed.put(text8, 390, 162)
		#fixed.put(manual10, 520, 130)
		#fixed.put(text10, 650, 162)
		
		fixed.put(manual10, 0, 270)
		fixed.put(text10, 130, 302)
		
		#fixed.put(manual11, 0, 260)
		#fixed.put(text11, 130, 292)
		fixed.put(manual11, 650, 352)
		fixed.put(text11, 402, 358)
		
		manualxp.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				if File.exists?("Anleitungen/ReinstallXP.#{@lang}.pdf")
					TileHelpers.open_pdf("Anleitungen/ReinstallXP.#{@lang}.pdf")
				else
					TileHelpers.open_pdf("Anleitungen/XP-Neuinstallation.pdf")
				end
			end
		}
		manual7.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				if File.exists?("Anleitungen/ReinstallVista7.#{@lang}.pdf")
					TileHelpers.open_pdf("Anleitungen/ReinstallVista7.#{@lang}.pdf")
				else
					TileHelpers.open_pdf("Anleitungen/Neuinstallation-Vista-7.pdf")
				end
			end
		}
		manual8.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				if File.exists?("Anleitungen/ReinstallWin8.#{@lang}.pdf")
					TileHelpers.open_pdf("Anleitungen/ReinstallWin8.#{@lang}.pdf")
				else
					TileHelpers.open_pdf("Anleitungen/Windows8-Installation.pdf")
				end
			end
		}
		manual10.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				if File.exists?("Anleitungen/ReinstallWin10.#{@lang}.pdf")
					TileHelpers.open_pdf("Anleitungen/ReinstallWin10.#{@lang}.pdf")
				else
					TileHelpers.open_pdf("Anleitungen/Win10-Installation.pdf")
				end
			end
		}
		manual11.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @nwscreen.test_connection == false
					@nwscreen.nextscreen = "dvdstartpanel"
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					@dvdburnmode = 0
					fill_temp_drives
					@nwscreen.fill_wlan_combo 
					extlayers.each { |k,v|v.hide_all }
					extlayers["networks"].show_all
				else
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					@dvdburnmode = 0
					fill_temp_drives
					extlayers.each { |k,v|v.hide_all }
					extlayers["dvdstartpanel"].show_all
				end
			end
		}
		return fixed
		
	end
	
	##### Fill the first table for smart quick readouts
	
	def fill_smart_tab(icons, descriptions, table, ntfsfix=false)
		TileHelpers.set_lock 
		icons.each { |i| table.remove i }
		descriptions.each { |i| table.remove i }
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		# drives.each {|d| puts "#{d.vendor} #{d.model} #{d.human_size} #{d.device}" }
		table.resize(drives.size, 2)
		icons = Array.new
		descriptions = Array.new
		errors = false
		0.upto(drives.size - 1) { |n|
			drive_errors = false
			icon = "smiley_green.png"
			# Create a label for each drive
			d = drives[n]
			label = "<b>#{d.vendor} #{d.model} #{d.human_size} #{d.device}"
			if d.usb == true
				label = label + " (USB)</b>\n"
			else
				label = label + " (SATA/eSATA/IDE/NVME)</b>\n"
			end
			smart_support, smart_info, smart_errors = d.error_log
			smart_test_types, smart_test_results, smart_bad_sectors, smart_reallocated, smart_seek_error = d.smart_details
			if smart_support == true 
				label = label + @tl.get_translation("smartavailable") +" " 
			else
				label = label + @tl.get_translation("nosmartavailable") +" " 
			end
			if smart_test_types == "short" 
				label = label + @tl.get_translation("smartshort") +" " 
			elsif smart_test_types == "long" 
				label = label + @tl.get_translation("smartlong") +" " 
			else
				label = label + @tl.get_translation("smartnever") +" " 
			end
			if smart_bad_sectors.to_i > 0 || smart_reallocated.to_i > 0 || smart_seek_error.to_i > 0
				label = label + @tl.get_translation("smartrealloc") +" " 
				errors = true
				drive_errors = true
				icon = "smiley_red.png"
			end
			if smart_test_results =~ /error/ 
				label = label + @tl.get_translation("smartdanger") +" " 
				icon = "smiley_red.png"
				errors = true
				drive_errors = true
			end
			if drive_errors == true && ntfsfix == true
				d.partitions.each { |p|
					system("ntfsfix /dev/#{p.device}") if p.fs =~ /ntfs/ 
				}
			end
 			l = TileHelpers.create_label(label, 600)
			descriptions.push l
			table.attach(l, 1, 2, n, n+1)
			img = Gtk::Image.new(icon)
			icons.push img
			table.attach(img, 0, 1, n, n+1)
		}
		TileHelpers.remove_lock
		return icons, descriptions, table, errors
	end
	
	##### Run the SMART test
	
	def run_smart_test(progbar, breakbutton)
		TileHelpers.set_lock 
		drives = Array.new
		breaked = false
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		breakbutton.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				drives.each { |d|
					puts "Cancel test for: #{d.device}"
					system("smartctl -X /dev/#{d.device}")
				}
				breaked = true
			end
			@extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
		}
		max_duration = -1
		durations = Hash.new
		remaining = Hash.new
		finished = Hash.new
		drives.each { |d|
			system("smartctl -s on /dev/#{d.device}")
			system("smartctl -X /dev/#{d.device}")	
			inside = false
			IO.popen("smartctl -c /dev/#{d.device}") { |l|
				while l.gets
					line = $_.strip
					if line =~ /recommended polling time.*\((.*?)\)/ && inside == true
						durations[d] = $1.to_i
						max_duration = $1.to_i if $1.to_i > max_duration
						break
					end
					inside = true if line =~ /Extended self-test routine/
				end
			}
			finished[d] = false
			system("smartctl -t long /dev/#{d.device}")
		}
		sleepcount = 0
		while finished.has_value?(false) && breaked == false
			remtime = -1
			progbar.pulse
			sleep 0.2
			progbar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			if sleepcount % 100 == 0
				drives.each { |d|
					test_running = false
					IO.popen("smartctl -c /dev/#{d.device}") { |l|
						while l.gets
							line = $_.strip
							if line =~ /Self-test execution status/ && line =~ /Self-test routine in progress/ 
								test_running = true
							end
							if line =~ /(\d*)% of test remaining/
								remaining[d] = $1.to_i
							end
						end
					}
					finished[d] = true if test_running == false
					this_remaining = remaining[d].to_i * durations[d].to_i / 100 
					remtime = this_remaining if this_remaining > remtime
				}
				progbar.text = @tl.get_translation("smartavailable").gsub("REMAINING", remtime.to_s)  
			end
			sleepcount += 1
		end
		TileHelpers.remove_lock
		return false if breaked == true
		return true
	end
	
	def fix_mbr
		TileHelpers.set_lock 
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		drives.each { |d|
			# puts d.device unless d.usb 
			gpt = false
			IO.popen("parted -sm /dev/#{d.device} unit B print ") { |l|
				while l.gets
					line = $_.strip
					if line =~ Regexp.new("^/dev/#{d.device}") 
						ltoks = line.split(":") 
						puts ltoks[5]
						gpt = true unless ltoks[5] =~ /msdos/
					end
				end
			}
			has_win_parts = false
			d.partitions.each { |p|
				winpart, winvers = p.is_windows
				puts "#{p.device}: #{winvers}, #{winpart}" 
				has_win_parts = true if winpart == true 
			}
			if (d.usb == true)
				puts "Ignore USB drive"
			elsif has_win_parts == false
				puts "No windows found on... #{d.device}"
			elsif (gpt == true)
				# TileHelpers.error_dialog( @tl.get_translation("mbrgpt").gsub("DEVICE", d.device).gsub("VENDOR", d.vendor).gsub("MODEL", d.model).gsub("SIZE", d.human_size) )
				fix_efi(d)
			else
				puts "Write new boot record."
				system("dd if=/usr/share/syslinux/mbr.bin of=/dev/" + d.device)
			end
		}
		TileHelpers.remove_lock
	end
	
	def fix_efi(drive)
		TileHelpers.set_lock 
		puts "Trying to fix EFI boot information"
		# Find partition containing EFI files, check and fix flags
		efinum = drive.efiboot
		efipart = nil 
		if efinum.nil?
			puts "Trying to find partitions with EFI boot files"
			drive.partitions.each { |p|
				if p.fs =~ /vfat/ 
					p.mount
					mnt = p.mount_point
					unless mnt.nil?
						[ "/EFI/BOOT", "/EFI/Boot", "/EFI/boot", "/EFI/Microsoft/Boot" ].each { |dir|
							efipart = p if File.directory?(mnt[0] + dir)
						}
						p.umount 
					end
				end
			}
			if efipart.nil?
				TileHelpers.error_dialog( @tl.get_translation("no_efi_bootfiles").gsub("DEVICE", d.device).gsub("VENDOR", d.vendor).gsub("MODEL", d.model).gsub("SIZE", d.human_size) )
				TileHelpers.remove_lock
				return false
			else
				efipart.device =~ /[a-z]([0-9]*)$/
				efinum = $1.strip.to_i 
				system("parted -s /dev/#{drive.device} set #{efinum.to_s} boot on")
			end
		end
	
		# Check whether windows boot files are present
		r = Regexp.new( '[a-z]' + efinum.to_s + '$')
		drive.partitions.each { |p|
			if r.match(p.device) 
				puts "Trying to find windows EFI boot files"
				p.mount
				mnt = p.mount_point
				unless mnt.nil?
					unless File.exists?(mnt[0] + "/EFI/Microsoft/Boot/bootmgr.efi")
						TileHelpers.error_dialog( @tl.get_translation("no_efi_bootfiles").gsub("DEVICE", d.device).gsub("VENDOR", d.vendor).gsub("MODEL", d.model).gsub("SIZE", d.human_size) )
						system("evince /usr/share/lesslinux/notfallcd4/Anleitungen/Windows-8-10-Reparatur.pdf &")
						p.umount
						return false
					end
				end
			end
		}
		
		unless system("efibootmgr") 
			TileHelpers.error_dialog( @tl.get_translation("please_boot_efi") )
			TileHelpers.remove_lock
			return false
		end
		
		# Check output of efibootmgr for windows entry
		winentry = ` efibootmgr | grep -i windows `.strip
		unless winentry =~ /Boot/ 
			puts "Trying to write EFI NVRAM entry"
			system("efibootmgr --create --bootnum 9038 --disk /dev/#{drive.device} --part #{efinum} --label 'Windows Boot Manager' --loader \\\\EFI\\\\Microsoft\\\\Boot\\\\bootmgr.efi") 
		end
		TileHelpers.remove_lock
		return true 
	end
	
	def create_shell_panel(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		# fixed.put(button1, 0, 0)
		shelltext = TileHelpers.create_label("<b>" + @tl.get_translation("shellhead") + "</b>\n\n" + @tl.get_translation("shellbody"), 510)
		fixed.put(shelltext, 0, 0)
		@wincombo = Gtk::ComboBox.new
		@wincombo.height_request = 32
		@wincombo.width_request = 380
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		fixed.put(reread, 390, 118)
		fixed.put(@wincombo, 0, 118)
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotofixshell") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		reread.signal_connect('clicked') {
			fill_win_combo(@wincombo) 
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 && @winparts.size > 0
				extlayers.each { |k,v|v.hide_all }
				# fix_shell
				success = @regfiles[@winparts[@wincombo.active]].reset_shell(true)	
				$stderr.puts "SUCCESS: " + success.to_s 
				if success == true
					extlayers["winfixshelldone"].show_all
				else
					TileHelpers.error_dialog(@tl.get_translation("shellresetfailed"))
					TileHelpers.back_to_group
				end
			elsif y.button == 1
				TileHelpers.error_dialog(@tl.get_translation("nosuitabledrives"), @tl.get_translation("nosuitablehead"))
			end
		}
		return fixed
	end
	
	def create_shelldone_panel(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		# fixed.put(button1, 0, 0)
		shelltext = TileHelpers.create_label("<b>" + @tl.get_translation("shelldonehead") + "</b>\n\n" + @tl.get_translation("shelldonebody"), 510)
		fixed.put(shelltext, 0, 0)
		return fixed
	end
	
	def fill_win_combo(wincombo, shelllabel=nil)
		TileHelpers.set_lock 
		drives = Array.new
		@winparts = Array.new
		shellentry = Array.new
		isdefault = Array.new
		@regfiles = Hash.new
		activeitem = 0
		199.downto(0) { |n|
			begin
				wincombo.remove_text(n)
			rescue
			end
		}
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				begin
					d =  MfsDiskDrive.new(l, true)
					drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		# Now fill each combo box with the respective 
		drives.each { |d|
			d.partitions.each { |p|
				iswin, winvers = p.is_windows
				if iswin == true
					@winparts.push(p)
					wincombo.append_text("#{p.device}, #{p.human_size} - #{winvers}")
					auxreg = p.regfile
					@regfiles[p] = auxreg 
					shellentry.push  auxreg.get_shell
					isdefault.push auxreg.shell_is_explorer?
				end
			}
		}
		if @winparts.size > 0 
			# gobutton.sensitive = true 
			wincombo.sensitive = true
			# switch_shelllabel(shelllabel, 0, gobutton)
		else
			wincombo.append_text(@tl.get_translation("no_windows_partition_found"))
			wincombo.sensitive = false
			#wincombo.append_text("Windows 8.1 auf sdb1 (SATA/eSATA/IDE)") 
			# wincombo.sensitive = true
		end
		wincombo.active = 0
		TileHelpers.remove_lock
	end
	
	def create_gpart_drivelist(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		# fixed.put(button1, 0, 0)
		text = TileHelpers.create_label("<b>" + @tl.get_translation("gparthead") +"</b>\n\n" +@tl.get_translation("gpartbody") , 700)
		@gpartcombo = Gtk::ComboBox.new
		@gpartcombo.height_request = 32
		@gpartcombo.width_request = 580
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotogpartprog") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		# winfindpartprogress
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["winfindpartprogress"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				if @gpartdrives.size < 1
					TileHelpers.error_dialog @tl.get_translation("no_suitable_drive")
				else
					@partrecover_killed = false
					loopmount(@gpartdrives[@gpartcombo.active])
					extlayers.each { |k,v|v.hide_all }
					if @rawparts.size > 0
						@partdonefinishedtext.set_markup("<span foreground='white'><b>" + @tl.get_translation("partrecoverdonehead") + "</b>\n\n" + @tl.get_translation("partrecoverdonebody").gsub("NUM",   @rawparts.size.to_s) + "</span>")
						extlayers["winfindpartdone"].show_all
						@writeparttableradio.sensitive = true 
					else
						TileHelpers.error_dialog @tl.get_translation("no_partitions_found")
						TileHelpers.back_to_group
					end
				end
			end
		}
		reread.signal_connect('clicked') { reread_gpartdrives }
		fixed.put(@gpartcombo, 0, 108)
		fixed.put(text, 0, 0)
		fixed.put(reread, 585, 108)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def reread_gpartdrives
		TileHelpers.set_lock 
		TileHelpers.umount_all
		100.downto(0) { |i| 
			begin
				@gpartcombo.remove_text(i) 
			rescue
			end
		}
		100.downto(0) { |i| 
			begin
				@gparttargetcombo.remove_text(i) 
			rescue
			end
		}
		alldrives = Array.new
		@gpartdrives = Array.new
		@gparttargetparts = Array.new
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/  || l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				d = MfsDiskDrive.new(l, false)
				@gpartdrives.push d unless d.mounted
				alldrives.push d 
			end
		}
		@gpartdrives.each { |d|
			usable_parts = Array.new
			d.partitions.each { |p|
				p.mount
				usable_parts.push(p) unless p.mount_point.nil?
				p.umount
				p.force_umount
			}
			label =  "#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
			if d.usb == true
				label = label + " (USB)"
			else
				label = label + " (SATA/eSATA/IDE)"
			end
			if d.partitions.size < 1
				if @lang == "de" 
					label = label + " - beschädigte Festplatte (keine Partition angelegt)"
				else
					label = label + " - damaged drive (no partitions found)"
				end
			elsif usable_parts.size == d.partitions.size
				if @lang == "de" 
					label = label + " - unbeschädigte Festplatte (alle Partitionen lesbar)"
				else
					label = label + " - usable drive (all partitions readable)"
				end
			elsif usable_parts.size < 1
				if @lang == "de" 
					label = label + " - wahrscheinlich beschädigte Festplatte (keine Partition lesbar)"
				else
					label = label + " - potentially damaged drive (no partition readable)"
				end
			else
				if @lang == "de" 
					label = label + " - evtl. beschädigte Festplatte (einzelne Partition nicht lesbar)"
				else
					label = label + " - potentially damaged drive (some partitions not readable)"
				end
			end
			@gpartcombo.append_text(label)
		}
		alldrives.each { |d|
			d.partitions.each  { |p|
				label = "#{d.vendor} #{d.model}"
				if d.usb == true
					label = label + " (USB) "
					label = @tl.get_translation("backup_medium")  + " " + label if p.label.to_s =~ /USBDATA/i   
				else
					label = label + " (SATA/eSATA/IDE) "
				end
				puts "Checking: #{label}"
				label = label + "#{p.device} #{p.human_size}"
				if ( p.fs =~ /ntfs/ || p.fs =~ /ext/ || p.fs =~ /btrfs/ ) && p.mount_point.nil?
					label = label + " #{p.fs}"
					@gparttargetparts.push p
					@gparttargetcombo.append_text(label) 
				else
					puts "Ignore #{label}"
				end
			}
		}
		if @gparttargetparts.size < 1
			@gparttargetcombo.append_text( @tl.get_translation("no_suitable_drive") )
			@gparttargetcombo.sensitive = false
		else
			@gparttargetcombo.sensitive = true
		end
		if @gpartdrives.size < 1
			@gpartcombo.append_text( @tl.get_translation("no_suitable_drive") ) 
			@gpartcombo.sensitive = false
		else
			@gpartcombo.sensitive = true
		end
		@gpartcombo.active = 0
		@gparttargetcombo.active = 0 
		TileHelpers.remove_lock
	end
	
	def loopmount(disk)
		TileHelpers.set_lock 
		@gpartdisk = disk
		@rawparts = Array.new 
		nextblock = 0
		freeloop = ` losetup -f `.strip
		system("mkdir -p /tmp/testmount/nextblock")
		@partrecover_progress.fraction = 0
		bytepos = 0
		step = 1024
		tries = 0
		fraction = 0.0 
		while ( bytepos < disk.size   && @partrecover_killed == false ) 
			cmd = "losetup -o #{bytepos} #{freeloop} /dev/#{disk.device}"
			# puts cmd
			system cmd
			if system("mount -o ro #{freeloop} /tmp/testmount/nextblock 2>/dev/null") 
					system("umount #{freeloop}")
					system("mkdir -p /tmp/testmount/#{bytepos}")
					system("mount -o ro #{freeloop} /tmp/testmount/#{bytepos}") 
					freeloop = ` losetup -f `.strip
					# Returns kilobyte blocks
					fsblocks = `df -k --output=size /tmp/testmount/#{bytepos} `.split("\n")[1].strip.to_i 
					@rawparts.push [ bytepos, fsblocks, freeloop ] 
					megblocks = bytepos / 1048576 + fsblocks / 1024 
					if bytepos % 1048576 == 0
						bytepos = megblocks * 1048576
						step = 1048576
					else
						bytepos = bytepos + fsblocks * 1024
						step = 1024 
					end
					# nextblock = nextblock + ( fsblocks / 1024 ) - 1  
			else
				unless system("losetup -d #{freeloop}") 
					system("sync")
					sleep 2.0
					system("losetup -d #{freeloop}")
				end
				step = 1048576 if bytepos == 8388608
				bytepos += step
			end
			if tries % 5 == 0
				fraction =  bytepos.to_f / disk.size.to_f
				percentage = ( fraction * 100.0 ).to_i
				if percentage < 1
					@partrecover_progress.pulse
				else
					@partrecover_progress.fraction = fraction
				end
				@partrecover_progress.text = @tl.get_translation("partrecoverrunning").gsub("NUM", @rawparts.size.to_s).gsub("PERCENTAGE",  percentage.to_s) 
				# freeloop=` losetup -f ` ; losetup -o $(( $n * 1024 )) -r $freeloop /dev/sda
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				# $stderr.puts "Current position: #{bytepos}"
			end
			tries += 1
		end
		TileHelpers.remove_lock
		system("rmdir /tmp/testmount/nextblock")
	end
	
	def create_partprogress_panel(extlayers)
		fixed = Gtk::Fixed.new
		@break_partrecover = TileHelpers.place_back(fixed, extlayers, false)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		# fixed.put(button1, 0, 0)
		@partrecover_progress = Gtk::ProgressBar.new
		@partrecover_progress.width_request = 510
		@partrecover_progress.height_request = 32
		fixed.put(@partrecover_progress, 0, 130)
		progresstext = TileHelpers.create_label("<b>" + @tl.get_translation("partrecoverproghead") + "</b>\n\n" + @tl.get_translation("partrecoverprogbody"), 510)
		fixed.put(progresstext, 0, 0)
		@partrecover_progress.fraction = 0.75
		@partrecover_progress.text = @tl.get_translation("partrecoverrunning") 
		@break_partrecover.signal_connect('button-release-event') { |x, y|
			if y.button == 1
				@partrecover_killed = true
				@writeparttableradio.sensitive = false 
				# system("thunar /tmp/testmount &")
			end
		}
		return fixed
	end
	
	def create_partdone_panel(extlayers)
		fixed = Gtk::Fixed.new
		goback = TileHelpers.place_back(fixed, extlayers)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		# fixed.put(button1, 0, 0)
		@partdonefinishedtext = TileHelpers.create_label("<b>" + @tl.get_translation("partrecoverdonehead") + "</b>\n\n" + @tl.get_translation("partrecoverdonebody") , 510)
		fixed.put(@partdonefinishedtext, 0, 0)
		@mountloopradio = Gtk::RadioButton.new("")
		label1 = TileHelpers.create_label(@tl.get_translation("partrecmountonly"), 450)
		@writeparttableradio = Gtk::RadioButton.new(@mountloopradio, "")
		@writeparttableradio.sensitive = false 
		@gparttargetcombo = Gtk::ComboBox.new
		@gparttargetcombo.height_request = 32
		@gparttargetcombo.width_request = 510
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		label2 = TileHelpers.create_label(@tl.get_translation("partrecwritembr"), 450)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("nextstep") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @writeparttableradio.active?
					if @rawparts[0][0] < 32768 && @rawparts.size > 4
						TileHelpers.error_dialog(@tl.get_translation("unsupportedpartitionscheme"))
					elsif @rawparts[0][0] < 2048
						TileHelpers.error_dialog(@tl.get_translation("unsupportedpartitionscheme"))
					else
						@rawparts.each { |p|
							system("umount /tmp/testmount/#{p[0]}")
							system("sync")
							system("rmdir /tmp/testmount/#{p[0]}")
							system("losetup -d #{p[2]}")
						}
						write_partitiontable
						TileHelpers.success_dialog( @tl.get_translation("partitiontablesuccessfullywritten") )
						extlayers.each { |k,v|v.hide_all }
						TileHelpers.back_to_group
					end
				else
					if @gparttargetparts.size < 1
						TileHelpers.error_dialog @tl.get_translation("no_suitable_drive")
					else
						system("thunar /tmp/testmount &") 
						system("mkdir /cobi/sicherung")
						sleep 1.0 
						@gparttargetparts[@gparttargetcombo.active].mount("rw", "/cobi/sicherung") 
						system("thunar /cobi/sicherung &") 
					end
				end
			end
		}
		goback.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("killall -9 thunar")
				@rawparts.each { |p|
					system("umount /tmp/testmount/#{p[0]}")
					system("sync")
					system("rmdir /tmp/testmount/#{p[0]}")
					TileHelpers.umount_all 
					system("losetup -d #{p[2]}")
				}
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		reread.signal_connect('clicked') { reread_gpartdrives }
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		fixed.put(@mountloopradio, 20, 70)
		fixed.put(@writeparttableradio, 20, 210)
		fixed.put(label1, 40, 70)
		fixed.put(@gparttargetcombo, 40, 160)
		fixed.put(reread, 560, 160)
		fixed.put(label2, 40, 210)
		return fixed
	end
	
	def write_partitiontable 
		return false if @rawparts[0][0] < 32768 && @rawparts.size > 4
		if @rawparts.size > 4
			system("parted -s /dev/#{@gpartdisk.device} mklabel gpt")
		else
			system("parted -s /dev/#{@gpartdisk.device} mklabel msdos")
		end
		ppos = 0
		@rawparts.each { |p|
			partend = "100%"
			if ppos <  ( @rawparts.size - 1 )
				partend = ( @rawparts[ppos + 1][0] - 1 ).to_s 
			end
			system("parted -s /dev/#{@gpartdisk.device} unit b mkpart primary ntfs #{p[0]} #{partend}")
			ppos += 1
		}
		return true 
	end
	
	def create_dvd_panel(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		# fixed.put(button1, 0, 0)
		@dvdburnlabel = TileHelpers.create_label("<b>" + @tl.get_translation("dvdhead") + "</b>\n\n" + @tl.get_translation("dvdbody"), 700)
		fixed.put(@dvdburnlabel, 0, 0)
		
		dvdtext = TileHelpers.create_label("<b>" + @tl.get_translation("whichdvd")  + "</b>", 200)
		fixed.put(dvdtext, 0, 140)
		@dvdcombo = Gtk::ComboBox.new
		@dvdcombo.height_request = 32
		@dvdcombo.width_request = 380
		@dvdcombo.append_text("Windows 7 32 Bit")
		@dvdcombo.active = 0 
		fixed.put(@dvdcombo, 0, 170) 
	
		temptext = TileHelpers.create_label("<b>" + @tl.get_translation("whichtempdrive")  + "</b>", 200)
		fixed.put(temptext, 0, 220)
		@tempcombo = Gtk::ComboBox.new
		@tempcombo.height_request = 32
		@tempcombo.width_request = 380
		@tempcombo.append_text("sda2, NTFS, 12GB frei")
		@tempcombo.active = 0
		fixed.put(@tempcombo, 0, 250) 
		
		fixed.put(@dvdkeepiso, 0, 290)
		keeptext = TileHelpers.create_label(@tl.get_translation("keepdvdiso") , 300)
		fixed.put(keeptext, 30, 294)
		
		fixed.put(@dvdusexfburn, 0, 322)
		xfburntext = TileHelpers.create_label(@tl.get_translation("usexfburn") , 300)
		fixed.put(xfburntext, 30, 326)
		
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotoburn") + "</span>")
		
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		# gotopart =  Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		# fixed.put(forw, 853, 232)
		# fixed.put(text5, 605, 238)
		
		# panel.put(back, 852, 332)
		# panel.put(text, 605, 338)
		
		fixed.put(forw, 650, 302)
		fixed.put(text5, 402, 308)
		
		@otherdvdlabel = Gtk::Label.new
		@otherdvdlabel.width_request = 230
		@otherdvdlabel.wrap = true
		
		othericon = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		
		fixed.put(othericon, 650, 352)
		fixed.put(@otherdvdlabel, 402, 358)
		
		othericon.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				@dvdburnmode = (@dvdburnmode + 1) % 2
				fill_temp_drives
				if @nwscreen.test_connection == false
					@nwscreen.nextscreen = "dvdstartpanel"
					@nwscreen.fill_wlan_combo 
					# Check for networks first...
					extlayers["networks"].show_all
				else
					extlayers["dvdstartpanel"].show_all
				end
			end
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if check_dvd == true  && @nwscreen.test_connection == true
					extlayers.each { |k,v|v.hide_all }
					extlayers["dvdburnprogress"].show_all
					burn_dvd_burn
				elsif @nwscreen.test_connection == false
					extlayers.each { |k,v|v.hide_all }
					@nwscreen.nextscreen = "dvdstartpanel"
					@nwscreen.fill_wlan_combo 
					# Check for networks first...
					extlayers["networks"].show_all
				else
					TileHelpers.error_dialog(@tl.get_translation("enterblankdvd"), @tl.get_translation("enterblankdvdhead"))
				end
			end
		}
		#fixed.signal_connect("show") {
		#	if $startup_finished == true
		#		fill_temp_drives 
		#	end
		#}
		#gotopart.signal_connect('button-release-event') { |x, y|
		#	if y.button == 1 
		#		extlayers.each { |k,v|v.hide_all }
		#		reread_gpartdrives
		#		extlayers["dvdburnprogress"].show_all
		#	end
		#}
		return fixed
	end
	
	def create_dvd_progress_panel(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		# fixed.put(button1, 0, 0)
		devicetext = TileHelpers.create_label("<b>" + @tl.get_translation("dvdburnhead") + "</b>\n\n" + @tl.get_translation("dvdburnbody"), 450)
		fixed.put(devicetext, 0, 0)
		
		@dvdprogress = Gtk::ProgressBar.new
		@dvdprogress.width_request = 510
		@dvdprogress.height_request = 32
		fixed.put(@dvdprogress, 0, 130)
		
		TileHelpers.place_back(fixed, extlayers)
		return fixed 
	end
	
	def fill_temp_drives
		TileHelpers.set_lock 
		drives = Array.new
		@tempparts = Array.new
		199.downto(0) { |n|
			begin
				@tempcombo.remove_text(n)
			rescue
			end
			begin
				@dvdcombo.remove_text(n)
			rescue
			end
		}
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				begin
					d =  MfsDiskDrive.new(l, true)
					drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		# Now fill each combo box with the respective 
		drives.each { |d|
			d.partitions.each { |p|
				# iswin, winvers = p.is_windows
				if (p.fs =~ /ntfs/i || p.fs =~ /btrfs/i || p.fs =~ /ext4/i) && p.size > 6_000_000_000  
					puts "Free: " + p.free_space.to_s 
					if p.free_space > 6_000_000_000  
						@tempparts.push(p)
						#if iswin == true 
						#	@tempcombo.append_text("#{p.device}, #{p.human_size} - #{winvers}")
						#else
							@tempcombo.append_text("#{p.device}, #{p.human_size}, #{p.fs}")
						#end
					end
				end
			}
		}
		@isonames[@dvdburnmode].each { |t|
			@dvdcombo.append_text(t) 
		}
		@tempcombo.active = 0
		@dvdcombo.active = 0 
		if @dvdburnmode > 0
			@dvdburnlabel.set_markup("<span color='white'><b>" + @tl.get_translation("dvdhead") + "</b>\n\n" + @tl.get_translation("dvdbody") + "</span>")
			@otherdvdlabel.set_markup("<span color='white'>" + @tl.get_translation("dvdbetterburninstall") + "</span>")
		else
			@dvdburnlabel.set_markup("<span color='white'><b>" + @tl.get_translation("dvdinstallhead") + "</b>\n\n" + @tl.get_translation("dvdinstallbody") + "</span>")
			@otherdvdlabel.set_markup("<span color='white'>" + @tl.get_translation("dvdbetterburnrepair") + "</span>")
		end
		TileHelpers.remove_lock
	end
	
	def burn_dvd_burn
		TileHelpers.set_lock 
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		@dvdprogress.text = @tl.get_translation("dvddownloading")
		@dvdworking = true
		# Mount temp drive
		p = @tempparts[@tempcombo.active]
		system("umount -f /home/surfer/Downloads")
		p.umount 
		if p.fs =~ /ntfs/
			p.mount("rw", nil, 1000, 1000)
		else
			p.mount("rw")
		end
		mnt = p.mount_point
		if mnt.nil?
			TileHelpers.error_dialog(@tl.get_translation("partition_mount_failed"), "Error" )
			# Go back 
			@extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
			TileHelpers.remove_lock
			return false
		else
			$stderr.puts mnt[0]
		end
		FileUtils.mkdir_p(mnt[0] + "/ISOs")
		system("chown 1000:1000 #{mnt[0]}/ISOs")
		system("mount --bind #{mnt[0]}/ISOs /home/surfer/Downloads")
		# Get URL
		uri = @isourls[@dvdburnmode][@dvdcombo.active]
		# Download ISO
		if @dvdburnmode < 1
			system("killall -9 firefox") 
			TileHelpers.success_dialog(@tl.get_translation("dvddownloadfirefox"), @tl.get_translation("dvdffhead"))
			# FIXME: Show that firefox must be closed before continuing
			system("su surfer -c \"firefox #{uri}\"")
			@dvdworking = false 
			# @dvdvte.fork_command( :argv => [ "/bin/su", "surfer", "-c", "/usr/bin/firefox #{uri}" ] ) 
		else
			@dvdvte.fork_command( :argv => [ "wget", "-O", "#{mnt[0]}/ISOs/" + uri.split("/")[-1] , uri ] )
		end
		while @dvdworking == true 
			@dvdprogress.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2
		end
		@dvdprogress.text = @tl.get_translation("dvdburning")
		@dvdworking = true
		# Find ISO 
		isoname = "#{mnt[0]}/ISOs/" + uri.split("/")[-1] 
		if @dvdburnmode < 1
			isoname = nil
			Dir.foreach("#{mnt[0]}/ISOs") { |f|
				if File.file?("#{mnt[0]}/ISOs/#{f}") && f =~ /\.iso$/
					isoname =  "#{mnt[0]}/ISOs/#{f}" if isoname.nil? || File.mtime("#{mnt[0]}/ISOs/#{f}") > File.mtime(isoname)
					$stderr.puts "Newest ISO: #{isoname}"
				end
			}
		end
		# Mount ISO to check
		system("mkdir -p /var/run/lesslinux/isocheck")
		system("mount -o loop \"#{isoname}\" /var/run/lesslinux/isocheck")
		if system("mountpoint /var/run/lesslinux/isocheck")
			system("umount /var/run/lesslinux/isocheck")
			# Burn ISO
			if @dvdusexfburn.active? == true
				@dvdvte.fork_command( :argv => [ "xfburn", isoname ] ) 
			else
				@dvdvte.fork_command( :argv => [ "xorrecord", "-v", "dev=/dev/sr0", "blank=as_needed",  "padsize=300k", isoname ] )
			end
			while @dvdworking == true 
				@dvdprogress.pulse
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				sleep 0.2
			end
			
			if @dvdusexfburn.active? == false
				sleep 3.0
				system("eject /dev/sr0")
				TileHelpers.success_dialog(@tl.get_translation("please_close_tray"))
				# Busy wait... 
				0.upto(50) { |n|
					@dvdprogress.pulse
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					sleep 0.2
				}	
				checkdvd = ` dd if=/dev/sr0 bs=1M count=16 | sha1sum `.strip.split[0]
				checkiso = ` dd if="#{isoname}" bs=1M count=16 | sha1sum `.strip.split[0]
				unless checkiso == checkdvd
					TileHelpers.error_dialog(@tl.get_translation("dvdburnundefined"))
					system("xfburn \"#{isoname}\"")
				end
			end
			unless @dvdkeepiso.active?
				# Unlink temporary file 
				begin
					File.unlink(isoname)
				rescue
				end
			end
			# Unmount temp drive
			system("umount -f /home/surfer/Downloads")
			p.umount
			# Inform the user
			TileHelpers.success_dialog(@tl.get_translation("dvdburnedhavefun"), title="none")
		else
			unless @dvdkeepiso.active?
				# Unlink temporary file 
				begin
					File.unlink(isoname)
				rescue
				end
			end
			# Unmount temp drive
			system("umount -f /home/surfer/Downloads")
			p.umount
			# Inform the user
			TileHelpers.error_dialog(@tl.get_translation("dvdburnfailed"), title="none")
		end
		# Go back 
		@extlayers.each { |k,v|v.hide_all }
		TileHelpers.back_to_group
		TileHelpers.remove_lock
	end
	
	def check_dvd
		TileHelpers.set_lock 
		dvdfound = false
		cdfound = false 
		writable = false
		0.upto(3) { |n|
			IO.popen("xorrecord -toc dev=/dev/sr#{n}") { |line|
				while line.gets
					if $_.strip =~ /^Media current/
						ltoks = $_.strip.split(":")
						if ltoks[1].strip =~ /^DVD.RW/i
							writable = true 
							dvdfound = true
							cdfound = true 
						elsif ltoks[1].strip =~ /^CD.RW/i
							writable = true 
							cdfound = true
						elsif ltoks[1].strip =~ /^DVD/i
							dvdfound = true
							cdfound = true
						elsif ltoks[1].strip =~ /^CD/i
							cdfound = true
						end
					elsif $_.strip =~ /^Media status/
						writable = true if $_.strip =~ /blank/ 
					end	
				end
			}
		}
		TileHelpers.remove_lock
		if @dvdburnmode > 0
			return cdfound && writable
		else
			return dvdfound && writable
		end
	end
	
end