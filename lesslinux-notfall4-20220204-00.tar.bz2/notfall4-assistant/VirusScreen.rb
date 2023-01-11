#!/usr/bin/ruby
# encoding: utf-8

class VirusScreen	
	def initialize(extlayers, button, nwscreen)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@extraenv = []
		unless [ "en", "de" ].include?(lang) 
			@extraenv = [ "LC_ALL=en_GB.UTF-8", "LANG=en_GB.UTF-8", "LANGUAGE=en_GB:en" ] 
		end
		@tl = MfsTranslator.new(lang, "VirusScreen.xml")
		@layers = Array.new
		@extlayers = extlayers 
		@nwscreen = nwscreen
		#### Partitions etc.
		#### Table for deletion of single partitions
		@parttable = nil
		# list of drives
		@partdrives = Array.new
		# shown partitions
		@partparts = Array.new
		# headers
		@partheaders = Array.new
		# checkboxes
		@partchecks = Array.new
		# labels
		@partlabels = Array.new
		#### progress bar for virus search
		@progressbar = nil
		#### VTE for signature update
		@sigs_vte = Vte::Terminal.new
		@sigs_update_running = false
		@sigs_vte.signal_connect("child-exited") { @sigs_update_running = false } 
		#### VTE for scancl check
		@check_vte = Vte::Terminal.new
		@check_running = false
		@check_vte.signal_connect("child-exited") { @check_running = false } 
		#### VTE for scancl virus scan
		@scan_vte = Vte::Terminal.new
		@scan_running = false
		@scan_vte.signal_connect("child-exited") { @scan_running = false } 
		@scan_log_button = Gtk::Button.new(@tl.get_translation("details"))
		#### Label with scan results at the end
		@resultlabel = nil
		#### Was the scan killed?
		@scan_killed = false
		#### Was a BKA trojan found?
		@bka_found = false
		@assumecobi = true
			File.open("/etc/lesslinux/branding/branding.en.sh").each { |line|
			ltoks = line.strip.split("=")
			@assumecobi = false if ltoks[1] =~ /sadrescue/i
		}
		#### Which virus scanner is available
		@scanner = "clamscan"
		#@scanner = "scancl" if File.exists?("/AntiVir/scancl") 
		if @assumecobi == false
			@scanner = "clamscan"
		elsif File.exists?("/opt/eset/esets/sbin/esets_scan") || File.exists?("/lesslinux/blob/eset.iso")
			if  Time.now > Time.utc(2023, "jul", 1)
				@scanner = "clamscan"	
			else
				@scanner = "eset" 
			end
		end
		@scanner = "clamscan"
		$stderr.puts "virus scanner found: #{@scanner}"
		
		### Radiobuttons for methods 
		@archive_yes_radio = Gtk::RadioButton.new
		@archive_no_radio = Gtk::RadioButton.new(@archive_yes_radio)
		@archive_no_radio.active = true
		@action_delete_radio = Gtk::RadioButton.new
		@action_ignore_radio = Gtk::RadioButton.new(@action_delete_radio)
		@action_ignore_radio.active = true
		@action_show_radio = Gtk::RadioButton.new(@action_delete_radio)
		# @action_show_radio.active = true
		
		# WPA crack/test
		@wpacombo = Gtk::ComboBox.new
		@wifinetworks = Array.new
		@wpacollectvte = Vte::Terminal.new
		@wpadumprunning = false
		@wpabrutevte = Vte::Terminal.new
		@wpabruterunning = false
		@wpashortradio = Gtk::RadioButton.new
		@wpalongradio = Gtk::RadioButton.new(@wpashortradio)
		@wpacrackkilled = false
		
		# Nmap portscanner overview
		@nmaplabel = nil
		@nmaprouterurl = nil
		@nmapprogress = Gtk::ProgressBar.new
		@nmapvte = Vte::Terminal.new
		@nmaprunning = false
		@nmapkilled = false
		@nmapvte.signal_connect("child-exited") {
			@nmaprunning = false
		}
		
		fixed = Gtk::Fixed.new
		throbber = Gtk::EventBox.new.add Gtk::Image.new("throbber.gif")
		throbtext = Gtk::Label.new
		throbtext.width_request = 250
		throbtext.wrap = true
		throbtext.set_markup('<span foreground="white">' + @tl.get_translation("sigupdate") + '</span>')
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotonext") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		archtext = TileHelpers.create_label("<b>" + @tl.get_translation("settingshead") + "</b>\n\n" + @tl.get_translation("settingsbody") , 510)
		actiontext =  TileHelpers.create_label(@tl.get_translation("actionquest"), 510)
		
		yestext = TileHelpers.create_label("<b>" + @tl.get_translation("yes") + "</b>, " + @tl.get_translation("archiveyes"), 380)
		notext = TileHelpers.create_label("<b>" + @tl.get_translation("no") + "</b>, " + @tl.get_translation("archiveno"), 380)
		actdeltext = TileHelpers.create_label(@tl.get_translation("repairdelete"), 380)
		actigntext = TileHelpers.create_label(@tl.get_translation("repairrename"), 380)
		actshowtext = TileHelpers.create_label(@tl.get_translation("justshow"), 380)
	
		button1 = Gtk::Image.new("virusgreen.png")
		button2 = Gtk::Image.new("virusgreen.png")
		if @scanner == "scancl"
			aviralogo = Gtk::Image.new("aviralogo.png")
		elsif @scanner == "eset"
			aviralogo = Gtk::Image.new("esetlogo.png")
		else
			aviralogo = Gtk::Image.new("doesnotexist.png")
		end
		
		# fixed.put(button1, 0, 0)
		fixed.put(aviralogo, 520, 0)
		# fixed.put(button2, 0, 130)
		fixed.put(archtext, 0, 0)
		fixed.put(actiontext, 0, 160)
		fixed.put(@archive_yes_radio, 10, 80)
		fixed.put(@archive_no_radio, 10, 110)
		fixed.put(yestext, 35, 83)
		fixed.put(notext, 35, 113)
		fixed.put(@action_delete_radio, 10, 190)
		fixed.put(@action_ignore_radio, 10, 215)
		fixed.put(@action_show_radio, 10, 240)
		fixed.put(actdeltext, 35, 193)
		fixed.put(actigntext, 35, 218)
		fixed.put(actshowtext, 35, 243)
	
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		TileHelpers.place_back(fixed, extlayers)
		# fixed.put(throbber, 0, 332)
		# fixed.put(throbtext, 52, 338)
		
		extlayers["virusstart"] = fixed
		@layers[0] = fixed
		button.signal_connect('button-release-event') { |x, y|
			#~ if y.button == 1 
				#~ extlayers.each { |k,v|v.hide_all }
				#~ if nwscreen.test_connection == false
					#~ nwscreen.nextscreen = "virusstart"
					#~ nwscreen.fill_wlan_combo 
					#~ # Check for networks first...
					#~ extlayers["networks"].show_all
				#~ else
					#~ system("/etc/rc.d/0611-scancl-blob.sh start") 
					#~ system("/etc/rc.d/0611-eset.sh start") 
					#~ extlayers["virusstart"].show_all
				#~ end
			#~ end
			extlayers.each { |k,v|v.hide_all }
			extlayers["viruschoice"].show_all
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				@partdrives, @partparts, @partheaders, @partchecks, @partlabels = fill_part_tab(@parttable, @partheaders, @partchecks, @partlabels)
				system("/etc/rc.d/0611-scancl-blob.sh start")
				extlayers.each { |k,v|v.hide_all }
				extlayers["virusdrives"].show_all
			end
		}
		extlayers["virusdrives"] = create_drive_screen(extlayers)
		@layers[1] = extlayers["virusdrives"]
		extlayers["virusprogress"] = create_progress_screen(extlayers)
		@layers[2] = extlayers["virusprogress"]
		extlayers["virusresult"] = create_result_screen(extlayers)
		@layers[3] = extlayers["virusresult"]
		extlayers["DEAD_viruschoice"] = create_choice_screen(extlayers, nwscreen)
		@layers[4] = extlayers["DEAD_viruschoice"]
		extlayers["kexecwait"] = create_wait_screen(extlayers)
		@layers[5] = extlayers["kexecwait"]
		extlayers["wpatargetselect"] = create_wpacracklayer(extlayers)
		@layers[6] = extlayers["wpatargetselect"]
		extlayers["wpacollectlayer"] = create_wpamonitorlayer(extlayers)
		@layers[7] = extlayers["wpacollectlayer"]
		extlayers["wpabrutelayer"] = create_wpabrutelayer(extlayers)
		@layers[8] = extlayers["wpabrutelayer"]
		extlayers["nmapstartlayer"] = create_nmap_layer(extlayers)
		@layers[9] = extlayers["nmapstartlayer"]
		extlayers["nmapproglayer"] = create_nmap_proglayer(extlayers)
		@layers[10] = extlayers["nmapproglayer"]
	end
	attr_reader :layers, :scanner, :wpacombo
	
	def create_choice_screen(extlayers, nwscreen)
		fixed = Gtk::Fixed.new
		
		# Check the WPA password
		button1 = Gtk::EventBox.new.add Gtk::Image.new("viruswine.png")
		text1 = Gtk::Label.new
		text1.width_request = 450
		text1.wrap = true
		text1.set_markup("<span foreground='white'><b>" + @tl.get_translation("wpacrackhead") + "</b>\n" + @tl.get_translation("wpacrackbody") + "</span>")
	
		# Scan for viruses
		button2 = Gtk::EventBox.new.add Gtk::Image.new("virusturq.png")
		text2 = Gtk::Label.new
		text2.width_request = 450
		text2.wrap = true
		text2.set_markup("<span foreground='white'><b>" + @tl.get_translation("clamhead") + "</b>\n"+ @tl.get_translation("clambody") + "</span>")

		# Scan for vulnerable network devices
		button3 = Gtk::EventBox.new.add Gtk::Image.new("viruswine.png")
		text3 = Gtk::Label.new
		text3.width_request = 450
		text3.wrap = true
		text3.set_markup("<span foreground='white'><b>" + @tl.get_translation("vulnerablehead") + "</b>\n"+ @tl.get_translation("vulnerablebody") + "</span>")

		fixed.put(button2, 0, 0)
		fixed.put(button1, 0, 140)
		fixed.put(button3, 0, 280)
		fixed.put(text2, 130, 0)
		fixed.put(text1, 130, 140)
		fixed.put(text3, 130, 280)
		
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				continue2scan = true
				meminfo = ` cat /proc/meminfo | grep 'MemTotal' `.strip.split[1].to_i
				if meminfo < 7_000_000 && @assumecobi == true 
					unless system("mountpoint /lesslinux/blobpart") || File.executable?("/opt/eset/esets/bin/esets_gui")
						TileHelpers.error_dialog(@tl.get_translation("lowmem_nousb"))
						continue2scan = false
					end
				end	
				if meminfo < 3_000_000 && continue2scan == true && @assumecobi == true 
					unless system("mountpoint /lesslinux/blobpart")
						continue2scan = TileHelpers.yes_no_dialog(@tl.get_translation("lowmem"))
					end
				elsif continue2scan == true && @assumecobi == true 
					unless File.executable?("/opt/eset/esets/bin/esets_gui")
						if system("mountpoint /lesslinux/blobpart")
							continue2scan = TileHelpers.yes_no_dialog(@tl.get_translation("suffmem_usb"))
							system("/usr/bin/blobinstall.sh --check eset") if continue2scan
						else
							continue2scan = TileHelpers.yes_no_dialog(@tl.get_translation("suffmem_nousb"))
							system("/usr/bin/blobinstall.sh --check eset") if continue2scan
						end
					end
				end
				if continue2scan == true
					fill_wlan_combo
					extlayers.each { |k,v|v.hide_all }
					if nwscreen.test_connection == false
						nwscreen.nextscreen = "virusstart"
						nwscreen.fill_wlan_combo 
						# Check for networks first...
						extlayers["networks"].show_all
					else
						if @assumecobi == true
							system("/etc/rc.d/0611-scancl-blob.sh start") 
							system("/etc/rc.d/0611-eset.sh start") 
						else 
							system("/etc/rc.d/0530-clamav.sh start")
						end
						extlayers["virusstart"].show_all
					end
				end
			end
		}
		
		button1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				fill_wlan_combo
				if @wifinetworks.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("error_no_iface_found"))
				#elsif nwscreen.test_connection == false
				#	extlayers.each { |k,v|v.hide_all }
				#	nwscreen.nextscreen = "wpatargetselect"
				#	nwscreen.fill_wlan_combo 
				#	# Check for networks first...
				#	extlayers["networks"].show_all
				else
					extlayers.each { |k,v|v.hide_all }
					extlayers["wpatargetselect"].show_all
				end
			end
		}
		
		button3.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# TileHelpers.error_dialog("Verdrahte mich!")
				if nwscreen.test_connection == false
					extlayers.each { |k,v|v.hide_all }
					nwscreen.nextscreen = "nmapstartlayer"
					nwscreen.fill_wlan_combo 
					# Check for networks first...
					extlayers["networks"].show_all
				else
					extlayers.each { |k,v|v.hide_all }
					extlayers["nmapstartlayer"].show_all
				end
			end
		}
		TileHelpers.place_back(fixed, extlayers)
		return fixed 
	end
	
	def prepare_virusstart(nwscreen)
		TileHelpers.set_lock 
		extlayers = @extlayers 
		continue2scan = true
		meminfo = ` cat /proc/meminfo | grep 'MemTotal' `.strip.split[1].to_i
		if meminfo < 7_000_000 && @assumecobi == true 
			unless system("mountpoint /lesslinux/blobpart") || File.executable?("/opt/eset/esets/bin/esets_gui")
				TileHelpers.error_dialog(@tl.get_translation("lowmem_nousb"))
				continue2scan = false
			end
		end	
		if meminfo < 3_000_000 && continue2scan == true && @assumecobi == true 
			unless system("mountpoint /lesslinux/blobpart")
				continue2scan = TileHelpers.yes_no_dialog(@tl.get_translation("lowmem"))
			end
		elsif continue2scan == true && @assumecobi == true 
			unless File.executable?("/opt/eset/esets/bin/esets_gui")
				if system("mountpoint /lesslinux/blobpart")
					continue2scan = TileHelpers.yes_no_dialog(@tl.get_translation("suffmem_usb"))
					system("/usr/bin/blobinstall.sh --check eset") if continue2scan
				else
					continue2scan = TileHelpers.yes_no_dialog(@tl.get_translation("suffmem_nousb"))
					system("/usr/bin/blobinstall.sh --check eset") if continue2scan
				end
			end
		end
		TileHelpers.remove_lock
		if continue2scan == true
			fill_wlan_combo
			extlayers.each { |k,v|v.hide_all }
			if nwscreen.test_connection == false
				nwscreen.nextscreen = "virusstart"
				nwscreen.fill_wlan_combo 
				# Check for networks first...
				return "networks"
			else
				if @assumecobi == true
					system("/etc/rc.d/0611-scancl-blob.sh start") 
					system("/etc/rc.d/0611-eset.sh start") 
				else
					system("/etc/rc.d/0530-clamav.sh start") 
				end
			end
			return "virusstart"
		end
		return "start"
	end
	
	def prepare_wpatargetselect
		n = fill_wlan_combo
		if @wifinetworks.size < 1 
			TileHelpers.error_dialog(@tl.get_translation("error_no_iface_found"))
		end
		return n
	end
	
	def create_drive_screen(extlayers)
		### Layer for deletion of single partitions
		fixed = Gtk::Fixed.new
		tile = Gtk::Image.new("virusgreen.png")
		TileHelpers.place_back(fixed, extlayers)
		delscroll = Gtk::ScrolledWindow.new
		delscroll.height_request = 260
		delscroll.width_request = 700
		delscroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC ) 
		drivetext = TileHelpers.create_label("<b>" + @tl.get_translation("drivehead") + "</b>\n\n" + @tl.get_translation("drivebody"), 510)
		# Table for drives
		@parttable = Gtk::Table.new(2, 11, false)
		align = Gtk::Alignment.new(0, 0, 0.1, 0.1)
		align.add @parttable
		delscroll.add_with_viewport align
		anc = @parttable.get_ancestor(Gtk::Viewport)
		anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#052f4c') )
		# puts anc.to_s
		# Forward button:
		text5 = TileHelpers.create_label(@tl.get_translation("gotoscan"), 250)
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				system("/etc/rc.d/0611-scancl-blob.sh start") 
				system("/etc/rc.d/0611-eset.sh start") 
				extlayers["virusprogress"].show_all
				run_virus_check
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(delscroll, 0, 65)
		fixed.put(drivetext, 0, 0)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_progress_screen(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::Image.new("virusgreen.png")
		drivetext = TileHelpers.create_label("<b>" + @tl.get_translation("scanhead") +"</b>\n\n" + @tl.get_translation("scanbody"), 510)
		@progressbar = Gtk::ProgressBar.new
		@progressbar.width_request = 415
		@progressbar.height_request = 32
		@scan_log_button.width_request = 90
		@scan_log_button.height_request = 32
		cancelbutton = TileHelpers.place_back(fixed, extlayers, false)
		# fixed.put(tile, 0, 0)
		fixed.put(@progressbar, 0, 88)
		fixed.put(@scan_log_button, 420, 88)
		@scan_log_button.signal_connect('clicked') {
			system("/usr/bin/Terminal --hide-menubar -e 'tail -f /var/log/virusscan.log' &") 
		}
		cancelbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@scan_killed = true
				system("killall scancl")
				system("killall esets_scan")
				system("killall clamscan")
				sleep 1.0
				system("killall -9 scancl") 
				system("killall -9 esets_scan")
				system("killall -9 clamscan")
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		fixed.put(drivetext, 0, 0)
		return fixed
	end
	
	def create_result_screen(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::Image.new("virusgreen.png")
		@resultlabel = TileHelpers.create_label("<b>" + @tl.get_translation("resulthead") +  "</b>\n\n" + @tl.get_translation("resultbody"), 510)
		log_button = Gtk::Button.new(@tl.get_translation("showprotocol") )
		log_button.width_request = 150
		log_button.height_request = 32
		# fixed.put(tile, 0, 0)
		fixed.put(@resultlabel, 0, 0)		
		fixed.put(log_button, 360, 240)
		log_button.signal_connect('clicked') {
			system("gedit /var/log/virusscan.log &") 
		}
		TileHelpers.place_back(fixed, extlayers)
		return fixed
	end
	
	def create_wait_screen(extlayers)
		fixed = Gtk::Fixed.new
		text4 = Gtk::Label.new
		text4.width_request = 370
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("pleasewait") + "</span>")
		fixed.put(text4, 130, 65)
		icon_wait = Gtk::EventBox.new.add  Gtk::Image.new("pleasewait.png")
		fixed.put(icon_wait, 0, 65)
		return fixed 
	end
	
	def fill_part_tab(table, oldheaders, oldchecks, oldlabels)
		TileHelpers.set_lock 
		TileHelpers.umount_all
		table.row_spacings = 4
		parts = Array.new
		headers = Array.new
		drives = Array.new
		checks = Array.new
		labels = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		oldheaders.each { |h| table.remove h }
		oldlabels.each{ |l| table.remove l } 
		oldchecks.each{ |c| table.remove c } 
		
		table.resize(drives.size * 100, 2)
		rowcount = 0
		drives.each { |d|
			label = "<b>#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
			if d.usb == true
				label = label + " (USB)</b>\n"
			else
				label = label + " (SATA/eSATA/IDE)</b>\n"
			end
			l = TileHelpers.create_label(label, 670)
			l.height_request = 17
			headers.push l
			table.attach(l, 0, 2, rowcount, rowcount+1)
			rowcount += 1
			d.partitions.each { |p|
				unless p.fs.to_s.strip == ""
					pt = "#{p.device} - #{p.human_size} - #{p.fs}"
					mnt, opt = p.mount_point
					iswin, winvers = p.is_windows
					pt = pt + " - " + winvers if iswin
					pt = pt + " - " + @tl.get_translation("backup_medium") if p.label == "USBDATA"
					if p.system_partition? == true
						pt = @tl.get_translation("notesystem").gsub("PARTITIONNAME", pt) 
					elsif mnt.nil? == false
						pt = @tl.get_translation("noteinuse").gsub("PARTITIONNAME", pt) 
					end
					pl = TileHelpers.create_label(pt, 650)
					cb = Gtk::CheckButton.new
					cb.active = true if p.fs =~ /ntfs/ || p.fs =~ /vfat/  # || p.fs =~ /bitlocker/ 
					cb.active = false unless mnt.nil?
					cb.active = false if p.label == "USBDATA"
					cb.sensitive = false unless mnt.nil? 
					cb.sensitive = false if p.fs =~ /bitlocker/ 
					labels.push pl
					checks.push cb
					parts.push p
					table.attach(pl, 1, 2, rowcount, rowcount+1)
					table.attach(cb, 0, 1, rowcount, rowcount+1)
					rowcount += 1
				end
			}
			
		}
		table.resize(rowcount, 2)
		TileHelpers.remove_lock
		return drives, parts, headers, checks, labels
	end
	
	def run_virus_check
		TileHelpers.set_lock 
		if @scanner == "scancl"
			run_virus_check_scancl 
		elsif @scanner == "eset"	
			run_virus_check_eset 
		else
			run_virus_check_clamav
		end
		TileHelpers.remove_lock
	end
	
	def run_virus_check_clamav
		@bka_found = false
		@scan_killed == false
		@scan_log_button.sensitive = false
		update_signatures
		while @sigs_update_running == true
			sleep 0.2
			@progressbar.text = @tl.get_translation("progresssigs")
			@progressbar.pulse 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		# Now run the real check for malicious software
		scanparams = Array.new
		scanparams.push("/opt/bin/clamscan")
		scanparams.push("--recursive=yes")
		scanparams.push("--scan-archive=no") unless @archive_yes_radio.active?
		scanparams.push("--scan-mail=no")
		scanparams.push("--scan-html=no")
		scanparams.push("--follow-dir-symlinks=0")
		scanparams.push("--follow-file-symlinks=0")
		scanparams.push("--remove=yes") if @action_delete_radio.active?
		scanparams.push("--log=/var/log/virusscan.log")
		
		# scanparams.push("--defaultaction=clean,delete,delete-archive") if @action_delete_radio.active?
		# scanparams.push("--defaultaction=clean,rename") if @action_ignore_radio.active?
		# scanparams.push("--defaultaction=ignore") if @action_show_radio.active?
		
		scanparams.push("/media")
		puts scanparams.join(" ")
		if @scan_killed == true
			@extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
			return false
		end
		0.upto(@partchecks.size - 1) { |n|
			if @partchecks[n].active? 
				system("mkdir -p /media/" + @partparts[n].device)
				@partparts[n].mount("rw", "/media/" + @partparts[n].device)
			end
		}
		scan_clamscan(scanparams)
		@scan_log_button.sensitive = true
		while @scan_running == true
			sleep 0.2
			@progressbar.text = @tl.get_translation("progressscan")
			@progressbar.pulse 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		@scan_log_button.sensitive = false
		0.upto(@partchecks.size - 1) { |n|
			if @partchecks[n].active? 
				repair_shell = false
				repair_shell = true if @action_delete_radio.active? || @action_ignore_radio.active?
				@bka_found = true if bka_check(@partparts[n], repair_shell)  == true
				# @partparts[n].umount
			end
		}
		if @scan_killed == true
			TileHelpers.umount_all 
			@extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
			return false
		end
		
		# Now analyze the log file and jump to the result screen
		analyze_log(@action_ignore_radio.active?)
		TileHelpers.umount_all 
		@extlayers.each { |k,v|v.hide_all }
		@extlayers["virusresult"].show_all 
		 
	end
	
	def run_virus_check_eset
		@bka_found = false
		@scan_killed == false
		@scan_log_button.sensitive = false
		update_signatures
		while @sigs_update_running == true
			sleep 0.2
			@progressbar.text = @tl.get_translation("progresssigs")
			@progressbar.pulse 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		# Now run the real check for malicious software
		scanparams = Array.new
		scanparams.push("/opt/eset/esets/sbin/esets_scan")
		scanparams.push("--clean-mode=strict") if @action_delete_radio.active?
		scanparams.push("--clean-mode=standard") if @action_ignore_radio.active?
		scanparams.push("--clean-mode=none") if @action_show_radio.active?
		scanparams.push("--arch") if @archive_yes_radio.active?
		scanparams.push("--no-arch") unless @archive_yes_radio.active?
		scanparams.push("--mail") if @archive_yes_radio.active?
		scanparams.push("--mailbox") if @archive_yes_radio.active?
		scanparams.push("--no-mail") unless @archive_yes_radio.active?
		scanparams.push("--no-mailbox") unless @archive_yes_radio.active?
		scanparams.push("--sfx") if @archive_yes_radio.active?
		scanparams.push("--no-sfx") unless @archive_yes_radio.active?
		scanparams.push("--no-symlink")
		scanparams.push("--log-rewrite")
		scanparams.push("--log-file=/var/log/virusscan.log")
		scanparams.push("/media")
		puts scanparams.join(" ")
		if @scan_killed == true
			@extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
			return false
		end
		0.upto(@partchecks.size - 1) { |n|
			if @partchecks[n].active? 
				system("mkdir -p /media/" + @partparts[n].device)
				@partparts[n].mount("rw", "/media/" + @partparts[n].device)
			end
		}
		scan_eset(scanparams)
		@scan_log_button.sensitive = true
		while @scan_running == true
			sleep 0.2
			@progressbar.text = @tl.get_translation("progressscan")
			@progressbar.pulse 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		@scan_log_button.sensitive = false
		0.upto(@partchecks.size - 1) { |n|
			if @partchecks[n].active? 
				repair_shell = false
				repair_shell = true if @action_delete_radio.active? || @action_ignore_radio.active?
				@bka_found = true if bka_check(@partparts[n], repair_shell)  == true
				# @partparts[n].umount
			end
		}
		if @scan_killed == true
			TileHelpers.umount_all 
			@extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
			return false
		end
		
		# Save the Log to USBDATA
		@partparts.each { |p|
			if p.label =~ /USBDATA/ 
				p.mount("rw")
				mnt = p.mount_point 
				unless mnt.nil?
					system("cp -v /var/log/virusscan.log #{mnt[0]}")
				end
				p.umount 
			end
		}
		# Now analyze the log file and jump to the result screen
		analyze_log(@action_ignore_radio.active?)
		TileHelpers.umount_all 
		@extlayers.each { |k,v|v.hide_all }
		@extlayers["virusresult"].show_all 
		 
	end
	
	def run_virus_check_scancl
		@bka_found = false
		@scan_killed == false
		@scan_log_button.sensitive = false
		# count files
		# filecount = 0
		# 0.upto(@partchecks.size - 1) { |n|
		#	filecount += @partparts[n].filecount(@progressbar) if @partchecks[n].active? 
		# }
		# update signatures - if not already done in background
		update_signatures
		while @sigs_update_running == true
			sleep 0.2
			@progressbar.text = @tl.get_translation("progresssigs") 
			@progressbar.pulse 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		# check usability of scancl
		check_scancl
		while @check_running == true
			sleep 0.2
			@progressbar.text = @tl.get_translation("progresscheck")
			@progressbar.pulse 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		check_success = File.read("/var/log/scancl-check.ret").strip.to_i
		if check_success > 0 && @scan_killed == false
			TileHelpers.error_dialog(@tl.get_translation("scannerdefectbody"), @tl.get_translation("scannerdefecthead"))
			@extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
		end
		# Now run the real check for malicious software
		scanparams = Array.new
		scanparams.push("/AntiVir/scancl")
		scanparams.push("--recursion")
		scanparams.push("-z") if @archive_yes_radio.active? 
		scanparams.push("--defaultaction=clean,delete,delete-archive") if @action_delete_radio.active?
		scanparams.push("--defaultaction=clean,rename") if @action_ignore_radio.active?
		scanparams.push("--defaultaction=ignore") if @action_show_radio.active?
		scanparams.push("--heurlevel=2")
		scanparams.push("--nolinks")
		scanparams.push("--log=/var/log/virusscan.log")
		scanparams.push("--logformat=singleline")
		scanparams.push("/media")
		puts scanparams.join(" ")
		if @scan_killed == true
			@extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
			return false
		end
		0.upto(@partchecks.size - 1) { |n|
			if @partchecks[n].active? 
				system("mkdir -p /media/disk/" + @partparts[n].device)
				@partparts[n].mount("rw", "/media/disk/" + @partparts[n].device)
				#repair_shell = false
				#repair_shell = true if @action_delete_radio.active? || @action_ignore_radio.active?
				#bka_check(@partparts[n], repair_shell) 
			end
		}
		scan_scancl(scanparams)
		@scan_log_button.sensitive = true
		while @scan_running == true
			sleep 0.2
			@progressbar.text = @tl.get_translation("progressscan")
			@progressbar.pulse 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		@scan_log_button.sensitive = false
		0.upto(@partchecks.size - 1) { |n|
			if @partchecks[n].active? 
				repair_shell = false
				repair_shell = true if @action_delete_radio.active? || @action_ignore_radio.active?
				@bka_found = true if bka_check(@partparts[n], repair_shell)  == true
				@partparts[n].umount
			end
		}
		if @scan_killed == true
			@extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
			return false
		end
		
		TileHelpers.umount_all 
		# Now analyze the log file and jump to the result screen
		analyze_log
		TileHelpers.mount_usbdata
		@extlayers.each { |k,v|v.hide_all }
		@extlayers["virusresult"].show_all 
		 
	end
	
	def update_signatures
		TileHelpers.set_lock 
		if @scanner == "scancl"
			update_signatures_scancl 
		elsif @scanner == "eset"
			update_signatures_eset 
		else
			update_signatures_clamav
		end
	end
	
	def update_signatures_clamav
		return false if @sigs_update_running == true
		return false if @nwscreen.test_connection == false
		@sigs_update_running = true
		@sigs_vte.fork_command("/bin/bash", [ "/bin/bash", "freshclam_wrapper.sh" ] )
	end
	
	def update_signatures_scancl
		return false if @sigs_update_running == true
		return false if @nwscreen.test_connection == false
		@sigs_update_running = true
		@sigs_vte.fork_command("/bin/bash", [ "/bin/bash", "avupdate_wrapper.sh" ] )
	end
	
	def update_signatures_eset
		return false if @sigs_update_running == true
		return false if @nwscreen.test_connection == false
		@sigs_update_running = true
		@sigs_vte.fork_command("/bin/bash", [ "/bin/bash", "eset_update_wrapper.sh" ] )
	end
	
	def check_scancl
		return false if @check_running == true
		system("install -m 0644 /etc/avira/hbedv.key /AntiVir/hbedv.key") if File.exists?("/AntiVir/rescue_cd.key") 
		@check_running = true
		@check_vte.fork_command("/bin/bash", [ "/bin/bash", "check_wrapper.sh" ]  )
	end
	
	def scan_scancl(scanparams)
		return false if @scan_running == true
		@scan_running = true
		@scan_vte.fork_command("/AntiVir/scancl", scanparams )
	end
	
	def scan_clamscan(scanparams)
		return false if @scan_running == true
		system("rm /var/log/virusscan.log") 
		@scan_running = true
		@scan_vte.fork_command("/opt/bin/clamscan", scanparams )
	end
	
	def scan_eset(scanparams)
		TileHelpers.set_lock
		return false if @scan_running == true
		@scan_running = true
		@scan_vte.fork_command("/opt/eset/esets/sbin/esets_scan", scanparams, @extraenv )
	end
	
	def analyze_log(move=false)
		TileHelpers.set_lock 
		if @scanner == "scancl"
			analyze_log_scancl 
		elsif @scanner == "eset"
			analyze_log_eset
		else
			analyze_log_clamav(move)
		end
		TileHelpers.remove_lock
	end
	
	def analyze_log_clamav(move)
		inside = false
		infected = 0
		total = 0
		text = ""
		File.open("/var/log/virusscan.log").each { |line|
			ltoks = line.strip.split(': ')
			inside = true if line =~ /SCAN SUMMARY/ 
			if inside == true && line =~ /Scanned files/
				total = line.split(': ')[1].to_i 
			end
			if ltoks[1] =~ /FOUND$/ 
				infected += 1
				unless ( move == false || ltoks[0] =~ /\.vir$/ ) 
					begin
						File.rename(ltoks[0], ltoks[0] + ".vir")
					rescue
					end
				end
			end
		}
		if inside == false 
			text = "<b>" + @tl.get_translation("scancancelledhead") + "</b>\n\n" + @tl.get_translation("scancancelledbody")  
		elsif infected < 1
			text = "<b>" + @tl.get_translation("nomalwarehead") + "</b>\n\n" + @tl.get_translation("nomalwarebody").gsub("FILECOUNT", total.to_s) 
		elsif @action_show_radio.active? == true
			text = "<b>" + @tl.get_translation("malwarehead") + "</b>\n\n" + @tl.get_translation("malwareshow") .gsub("FILECOUNT", total.to_s).gsub("INFECTEDCOUNT", infected.to_s) 
		else
			text = "<b>" + @tl.get_translation("malwarehead") + "</b>\n\n" + @tl.get_translation("malwareremoved") .gsub("FILECOUNT", total.to_s).gsub("INFECTEDCOUNT", infected.to_s) 
		end
		#### BKA-Trojaner-Text
		if @bka_found == true && @action_show_radio.active? == true
			text = text + "\n\n<b>" + @tl.get_translation("ransomhead") + "</b>\n\n" + @tl.get_translation("ransomshow")
		elsif @bka_found == true
			text = text + "\n\n<b>" + @tl.get_translation("ransomhead") + "</b>\n\n" + @tl.get_translation("ransomremove")
		end
		@resultlabel.set_markup("<span color='white'>#{text}</span>") 
	end
	
	def analyze_log_scancl 
		inside = false
		infected = 0
		total = 0
		text = ""
		File.open("/var/log/virusscan.log").each { |line|
			begin 
				inside = true if line.strip =~ /^Statistics/ 
			rescue
			end
			if inside == true
				ltoks = line.strip.split
				if line.strip =~ /^Infected/
					infected = ltoks[-1].to_i 
				elsif line.strip =~ /^Files/
					total = ltoks[-1].to_i 
				end
			end
		}
		if inside == false 
			text = "<b>" + @tl.get_translation("scancancelledhead") + "</b>\n\n" + @tl.get_translation("scancancelledbody")  
		elsif infected < 1
			text = "<b>" + @tl.get_translation("nomalwarehead") + "</b>\n\n" + @tl.get_translation("nomalwarebody").gsub("FILECOUNT", total.to_s) 
		elsif @action_show_radio.active? == true
			text = "<b>" + @tl.get_translation("malwarehead") + "</b>\n\n" + @tl.get_translation("malwareshow") .gsub("FILECOUNT", total.to_s).gsub("INFECTEDCOUNT", infected.to_s) 
		else
			text = "<b>" + @tl.get_translation("malwarehead") + "</b>\n\n" + @tl.get_translation("malwareremoved") .gsub("FILECOUNT", total.to_s).gsub("INFECTEDCOUNT", infected.to_s) 
		end
		#### BKA-Trojaner-Text
		if @bka_found == true && @action_show_radio.active? == true
			text = text + "\n\n<b>" + @tl.get_translation("ransomhead") + "</b>\n\n" + @tl.get_translation("ransomshow")
		elsif @bka_found == true
			text = text + "\n\n<b>" + @tl.get_translation("ransomhead") + "</b>\n\n" + @tl.get_translation("ransomremove")
		end
		
		@resultlabel.set_markup("<span color='white'>#{text}</span>") 
	end
	
	def analyze_log_eset
		inside = false
		infected = 0
		total = 0
		cleaned = 0
		text = ""
		# FIXME: Properly translate to polish!
		File.open("/var/log/virusscan.log").each { |line|
			ltoks = line.strip.split(': ')
			inside = true if line =~ /Scan completed at/i  
			inside = true if line =~ /fung abgeschlossen um/i  
			if inside == true
				ltoks = line.strip.split
				if line.strip =~ /^Infected/ || line.strip =~ /^Infiziert/
					infected = ltoks[3].to_i 
				elsif line.strip =~ /^Total/ || line.strip =~ /^Gesamt/ 
					total = ltoks[3].to_i 
				elsif line.strip =~ /^Cleaned/ || line.strip =~ /Gesäubert/
					infected += ltoks[3].to_i 
				end
			end
		}
		if inside == false 
			text = "<b>" + @tl.get_translation("scancancelledhead") + "</b>\n\n" + @tl.get_translation("scancancelledbody")  
		elsif infected < 1
			text = "<b>" + @tl.get_translation("nomalwarehead") + "</b>\n\n" + @tl.get_translation("nomalwarebody").gsub("FILECOUNT", total.to_s) 
		elsif @action_show_radio.active? == true
			text = "<b>" + @tl.get_translation("malwarehead") + "</b>\n\n" + @tl.get_translation("malwareshow") .gsub("FILECOUNT", total.to_s).gsub("INFECTEDCOUNT", infected.to_s) 
		else
			text = "<b>" + @tl.get_translation("malwarehead") + "</b>\n\n" + @tl.get_translation("malwareremoved") .gsub("FILECOUNT", total.to_s).gsub("INFECTEDCOUNT", infected.to_s) 
		end
		#### BKA-Trojaner-Text
		if @bka_found == true && @action_show_radio.active? == true
			text = text + "\n\n<b>" + @tl.get_translation("ransomhead") + "</b>\n\n" + @tl.get_translation("ransomshow")
		elsif @bka_found == true
			text = text + "\n\n<b>" + @tl.get_translation("ransomhead") + "</b>\n\n" + @tl.get_translation("ransomremove")
		end
		@resultlabel.set_markup("<span color='white'>#{text}</span>") 
	end
	
	
	# Check for BKA Ukash trojan, those modify the SHELL
	
	def bka_check(partition, purge)
		return false unless partition.fs =~ /ntfs/ || partition.fs =~ /vfat/
		# assume partition is mounted
		return false if partition.mount_point.nil?
		reg_file = nil 
		path = partition.mount_point[0]
		Dir.entries(path).each { |w|
			if w =~ /^windows$/i
				path = path + "/" + w 
				Dir.entries(path).each { |s|
					if s =~ /^system32$/i 
						path = path + "/" + s 
						Dir.entries(path).each { |c|
							if c =~ /^config$/i
								path = path + "/" + c
								Dir.entries(path).each { |r|
									reg_file = path + "/" + r if r =~/^software$/i 
								}
							end
						}
					end
				}
			end
		}
		puts "No registry file found!"
		return false if reg_file.nil?
		valid_reg = system('echo -e "q\n" | chntpw -e ' + reg_file ) 
		if valid_reg == false
			TileHelpers.error_dialog(@tl.get_translation("damagedregbody").gsub("REGFILE", reg_file) , @tl.get_translation("damagedreghead") )
			return false
		end
		shell = get_shell(reg_file)
		return false if shell =~ /^explorer\.exe$/i 
		if purge == true
			puts "Repair shell! " + shell 
			reset_shell(reg_file)
			shell = get_shell(reg_file)
		end
		return true 
	end
	
	def get_shell(reg_file)
		valid_reg = system('echo -e "q\n" | chntpw -e ' + reg_file) 
		return nil if valid_reg == false
		lcount = 0
		nline = -1
		shell = nil
		IO.popen("printf \"cat Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\Shell\\nq\\n\" | chntpw -e " + reg_file ) { |l| 
			while l.gets
				nline = lcount if $_ =~ /currentversion.winlogon.shell/i 
				shell = $_.strip if lcount == nline + 1  
				lcount += 1
			end
		}
		puts "Shell found! #{shell.to_s}"
		return shell
	end
	
	def reset_shell(reg_file)
		success = system("printf \"cd Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\ncat Shell\\ned Shell\\nexplorer.exe\\ncat Shell\\nq\\ny\\n\" | chntpw -e " + reg_file) 
		return success 
	end
	
	def create_nmap_layer(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, @extlayers)
		tile = Gtk::EventBox.new.add Gtk::Image.new("virusgreen.png")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("wpacrackgo") + "</span>")
		
		@nmaplabel = TileHelpers.create_label(@tl.get_translation("nmapstartinfo"), 510)
		routerbutton = Gtk::Button.new(@tl.get_translation("nmapopenrouterpage"))
		routerbutton.signal_connect("clicked") { open_routerpage }
		
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@nmapkilled = false
				extlayers.each { |k,v|v.hide_all }
				extlayers["nmapproglayer"].show_all
				run_nmap_scan
			end
		}
		fixed.put(text5, 402, 358)
		fixed.put(@nmaplabel, 0, 0)
		fixed.put(routerbutton, 0, 130) 
		# fixed.put(tile, 0, 0)
		fixed.put(forw, 650, 352)
		return fixed
	end	
		
	def create_nmap_proglayer(extlayers)
		fixed = Gtk::Fixed.new
		back = TileHelpers.place_back(fixed, @extlayers, false)
		tile = Gtk::EventBox.new.add Gtk::Image.new("virusgreen.png")
		progresslabel = TileHelpers.create_label(@tl.get_translation("nmapprogress"), 510)
		@nmapprogress.width_request = 510
		@nmapprogress.height_request = 32
		# FIXME translate
		@nmapprogress.text =  @tl.get_translation("nmaprunning")
		back.signal_connect('button-release-event') { |x,y|
			if y.button = 1
				@nmapkilled = true
				system("killall -9 nmap") 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		fixed.put(progresslabel, 0, 0)
		fixed.put(@nmapprogress, 0, 130)
		# fixed.put(tile, 0, 0)
		return fixed
	end
		
	def run_nmap_scan
		TileHelpers.set_lock
		router = "127.0.0.1"
		IO.popen("ip route") { |line|
			while line.gets
				ltoks = $_.strip.split
				if ltoks[0] =~ /default/
					router = ltoks[2]
				end
			end
		}
		rtoks = router.split(".")
		rtoks[3] = "0"
		@nmaprunning = true
		@nmapvte.fork_command("nmap", [ "nmap", "-p", "*", "-O", "-oN", "/tmp/nmap.txt", rtoks.join(".") + "/24" ])
		heartbeat = 1920
		while @nmaprunning == true
			heartbeat -= 1
			if heartbeat > 240
				remtime = heartbeat / 120
				@nmapprogress.text = @tl.get_translation("nmaprunningxminutes").gsub("REMTIME", remtime.to_s)
				@nmapprogress.fraction = (1920.0 - heartbeat.to_f) / 1920.0 
			else
				@nmapprogress.text = @tl.get_translation("nmaprunningfewminutes")
				@nmapprogress.pulse 
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.5
		end
		@nmapprogress.text = "Analyse abgeschlossen"
		@nmapprogress.fraction = 1.0
		return false if @nmapkilled == true
		if analyze_nmap_log == true
			dtmnt, dtfree = TileHelpers.mount_usbdata
			unless dtmnt.nil?
				system("cp -v /tmp/nmap.html #{dtmnt}/")
			end
			TileHelpers.success_dialog(@tl.get_translation("nmapvulnsfound"), @tl.get_translation("nmapvulnsfoundhead"))
			system("su surfer -c \"firefox file:///tmp/nmap.html\" &") 
		else
			# FIXME translate
			TileHelpers.success_dialog(@tl.get_translation("nmapnovulnsfound"), @tl.get_translation("nmapnovulnsfoundhead"))
		end
		TileHelpers.remove_lock
		@extlayers.each { |k,v|v.hide_all }
		TileHelpers.back_to_group
	end
		
	def analyze_nmap_log
		blocks = Array.new
		thisblock = Array.new
		unsafe = false
		valid_lines = 0
		unless File.exists?("/tmp/nmap.txt")
			TileHelpers.error_dialog(@tl.get_translation("nmapmissingprotocol"))
			return false
		end
		File.open("/tmp/nmap.txt").each { |line|
			unless line =~ /^#/ || line =~ /^Os detection performed/
				if line =~ /Nmap scan report for/ 
					blocks.push(thisblock)
					thisblock = Array.new
				end
				thisblock.push(line.strip) unless line.strip =~ /^$/ 
				if line =~ /netbios/ || line =~ /telnet/ || line =~ /print/ || line =~ /sane/ || line =~ /sip/ || line =~ /vnc/
						unsafe = true
				end	
			end
			valid_lines += 1 unless line.strip.size < 1 
		}
		if valid_lines < 1
			TileHelpers.error_dialog(@tl.get_translation("nmapincompleteprotocol"))
		end
		# FIXME translate
		html = "<html><head>
<meta charset=\"UTF-8\">
<title>Nmap scan</title></head><body>\n"
		html = html + "<h1>Schwachstellen gefunden</h1><p>Es wurden Geräte mit potentiellen Schwachstellen im Netzwerk entdeckt. Die Details finden Sie in der folgenden Liste. Bitte beachten Sie folgende Hinweise: Bei Geräten mit offenen Ports („Port open“) sollten Sie den jeweiligen Netzwerkdienst („Service“) im Internet nachschlagen und prüfen, ob er wirklich benötigt wird – etwa bei Portfreigaben für PC-Spiele. Offene Ports im  Internet-Router – es ist das erste Gerät in der Liste – lassen sich nach einem Klick auf „Startseite dieses Servers öffnen“ direkt im Menü unter „Portfreigaben“ prüfen und gegebenenfalls schließen. Offene Ports auf Computern schließen Sie mit einem Internet-Schutzprogramm beziehungsweise einer Firewall-Software.
</p><p>Der Link „Startseite dieses Servers öffnen“ verdeutlicht, dass auf dem geprüften Netzwerk-Gerät ein Webserver (Protokolle HTTP, HTTPS oder IPP) läuft. Dahinter kann das harmlose Konfigurationsmenü eines Routers oder NAS-Laufwerks stecken – aber auch eine Schadsoftware, die möglicherweise Daten ins Internet sendet. Öffnen Sie entdeckte Webserver per Klick auf „Startseite dieses Servers öffnen“. Anschließend begutachten Sie den Server im Browser.</p>\n"
		blocks.each { |b|
			lnum = 0
			www = false
			warn = Array.new
			currip = "127.0.0.1"
			b.each { |l|
				if lnum < 1
					html += "<h2>" + l.gsub("Nmap scan report for", "Potentielle Schwachstellen auf " ) + "</h2><p>\n<pre>"
					currip = l.strip.split[-1].gsub("(", "").gsub(")", "") 
				end
				html += l
				html += "\n"
				# FIXME translate
				if l =~ /netbios/ 
					warn.push "Windows-Datei- oder Druckerfreigabe (netbios-ssn oder smb)"
				elsif l =~ /telnet/
					warn.push "Telnet-Zugang (!)"
				elsif l =~ /smtp/
					warn.push "Mailserver (SMTP) (!)"
				elsif l =~ /print/ && l =~ /^[0-9]/ 
					warn.push "Druckerfreigaben (IPP, Jetdirect, Printer)"
				elsif l =~ /sane/
					warn.push "Scanner-Dienste (Sane, Samsung oder HP)"
				elsif l =~ /sip/
					warn.push "Internet-Telefonie (SIP)"
				elsif l =~ /vnc/
					warn.push "VNC-Fernzugriff (!)"
				elsif l =~ /ftp/
					warn.push "FTP Datei&uuml;bertragung (!)"
				elsif l =~ /http/
					warn.push "Webserver (HTTP, HTTPS)"
				end
				www = true if l =~ /^80\/tcp/
				lnum += 1
			}
			html += "</pre></p>\n"
			# FIXME translate
			if warn.size > 0 
				html += "<h3>Bitte pr&uuml;fen Sie die folgenden Freigaben:</h3></p> " + warn.join(", ") + "</p>\n"
			end
			if www == true
				html += "<p><a href=\"http://#{currip}/\" target=\"blank\">Startseite dieses Servers &ouml;ffnen.</a></p>\n"
			end
		}
		html += "</body></html>"
		outfile = File.new("/tmp/nmap.html", "w")
		outfile.write(html)
		outfile.close 
		return unsafe
	end
		
	def update_nmap_starttext
		
	end
		
	def open_routerpage
		router = "127.0.0.1"
		IO.popen("ip route") { |line|
			while line.gets
				ltoks = $_.strip.split
				if ltoks[0] =~ /default/
					router = ltoks[2]
				end
			end
		}
		system("su surfer -c \"firefox http://#{router}/\" &") 
	end
	
	
	def create_wpacracklayer(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, @extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("wpacrackgo") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("virusgreen.png")
		@wpacombo.height_request = 32
		@wpacombo.width_request = 380
		
		deltext = TileHelpers.create_label(@tl.get_translation("wpacrackstart"), 510)
		listtext = TileHelpers.create_label(@tl.get_translation("wpacracklist"), 510)
		# @sourcedrives = reread_drivelist(@sourcecombo)
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		tvdl_running = false
		tvdl_vte = Vte::Terminal.new
		tvdl_vte.signal_connect("child_exited") { tvdl_running = false } 
		#@overwritecheck.active = true 
		#overwrite_label = Gtk::Label.new
		#overwrite_label.set_markup("<span color='white'>" + @tl.get_translation("tvtargettext") + "</span>")
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				$stderr.puts("Network to analyze: " + @wifinetworks[@wpacombo.active]) 
				# get_net_params(netname)
				if @wifinetworks[@wpacombo.active] =~ /managed_wep/ || @wifinetworks[@wpacombo.active] =~ /managed_none/
					TileHelpers.error_dialog(@tl.get_translation("error_no_encryption"))
					extlayers.each { |k,v|v.hide_all }
					TileHelpers.back_to_group
				else
					netname = @wifinetworks[@wpacombo.active].split(/\swifi_/)[0].gsub("*AO", "").gsub("*AR", "").strip
					$stderr.puts(netname)
					# Now tell the encryption is sufficient and move on
					TileHelpers.success_dialog(@tl.get_translation("info_sufficient_encryption"))
					extlayers.each { |k,v|v.hide_all }
					extlayers["wpacollectlayer"].show_all
					start_pkgcapture(netname, extlayers)
				end
			end
		}
		reread.signal_connect('clicked') { 
			@wpacombo.sensitive = false
			reread.sensitive = false
			fill_wlan_combo
			reread.sensitive = true
			@wpacombo.sensitive = true
		}
		# fixed.put(tile, 0, 0)
		fixed.put(@wpacombo, 0, 120)
		fixed.put(listtext, 0, 155)
		shortlisttext = TileHelpers.create_label(@tl.get_translation("wpacrackshort"), 400)
		longlisttext = TileHelpers.create_label(@tl.get_translation("wpacracklong"), 400)
		fixed.put(@wpashortradio, 10, 188)
		fixed.put(@wpalongradio, 10, 220)
		fixed.put(shortlisttext, 36, 188)
		fixed.put(longlisttext, 36, 220)
		
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 120)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		#fixed.put(@overwritecheck, 130, 164)
		#fixed.put(overwrite_label, 156, 168)
		#extlayers["wpatargetselect"] = fixed
		#layers.push fixed
		return fixed
	end
	
	def create_wpamonitorlayer(extlayers)
		fixed = Gtk::Fixed.new
		back = TileHelpers.place_back(fixed, @extlayers, false)
		# text5 = Gtk::Label.new
		# text5.width_request = 250
		# text5.wrap = true
		# text5.set_markup("<span color='white'>" + @tl.get_translation("wpacrackcrack") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("virusgreen.png")
		collecttext = TileHelpers.create_label(@tl.get_translation("wpacrackcollect"), 700)
		@wpacollectvte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
		@wpacollectvte.height_request = 270
		@wpacollectvte.width_request = 700
		@wpacollectvte.set_background_image "bg0000px.png"
		@wpacollectvte.set_background_saturation 1.0
		@wpacollectvte.signal_connect("child-exited") {
			@wpadumprunning = false
		}
		# @wpacollectvte.fork_command("/static/bin/top", [ "/static/bin/top"])
		fixed.put(collecttext, 0, 0)
		fixed.put(@wpacollectvte, 0, 60)
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("killall -15 airodump-ng")
				@wpacrackkilled = true 
			end
		}
		# fixed.put(forw, 853, 282)
		# fixed.put(text5, 605, 288)
		#fixed.put(@overwritecheck, 130, 164)
		#fixed.put(overwrite_label, 156, 168)
		#extlayers["wpatargetselect"] = fixed
		#layers.push fixed
		return fixed
	end
	
	def create_wpabrutelayer(extlayers)
		fixed = Gtk::Fixed.new
		back = TileHelpers.place_back(fixed, @extlayers, false)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("wpacrackbrute") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("virusgreen.png")
		collecttext = TileHelpers.create_label(@tl.get_translation("wpacrackbrute"), 700)
		@wpabrutevte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
		@wpabrutevte.height_request = 270
		@wpabrutevte.width_request = 700
		@wpabrutevte.set_background_image "bg0000px.png"
		@wpabrutevte.set_background_saturation 1.0
		@wpabrutevte.signal_connect("child-exited") {
			@wpabruterunning = false
		}
		# @wpacollectvte.fork_command("/static/bin/top", [ "/static/bin/top"])
		fixed.put(collecttext, 0, 0)
		fixed.put(@wpabrutevte, 0, 60)
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("killall -15 aircrack-ng")
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
				@wpacrackkilled = true 
			end
		}
		# fixed.put(forw, 853, 282)
		# fixed.put(text5, 605, 288)
		#fixed.put(@overwritecheck, 130, 164)
		#fixed.put(overwrite_label, 156, 168)
		#extlayers["wpatargetselect"] = fixed
		#layers.push fixed
		return fixed
	end
	
	
	def start_pkgcapture(netname, extlayers)
		keyfound = false
		vtetext = ""
		@wpadumprunning = true
		@wpacrackkilled = false 
		iface, channel, bssid = get_net_params(netname)
		# No interface, exit, move to start page
		if iface.nil?
			TileHelpers.error_dialog(@tl.get_translation("error_no_iface_found"))
			extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
			return false
		end
		TileHelpers.set_lock
		system("airmon-ng start #{iface}")
		# First run the collection:
		@wpacollectvte.fork_command("airodump-ng", [ "airodump-ng", "-c", channel.to_s, "--bssid", bssid, "-w", "/tmp/airodump", iface + "mon" ])
		capturecount = 0 
		while @wpadumprunning == true
			sleep 0.5
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			vtetext = @wpacollectvte.get_text(false) #.join("")
			if vtetext =~ /WPA handshake/ || capturecount > 600  
				system("killall -15 airodump-ng")
				@wpadumprunning == false
			end
			capturecount += 1 
		end
		@wpacollectvte.reset(true, true)
		system("airmon-ng stop #{iface}mon")
		# Killed? Go back!
		if @wpacrackkilled == true
			extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
			@wpacrackkilled = false 
			TileHelpers.remove_lock 
			return false
		end
		# Now switch to analyze:
		extlayers.each { |k,v|v.hide_all }
		extlayers["wpabrutelayer"].show_all
		# Start analyzing:
		# FIXME translate
		if File.exists? "/var/run/lesslinux/wordlist/" + @tl.get_translation("dictfile")
			$stderr.puts("Found wordlist")
		else
			system("mkdir -p /var/run/lesslinux/wordlist")
			if File.exists?("/lesslinux/blobpart/wordlist.sqs")
				system("mount -o loop /lesslinux/blobpart/wordlist.sqs /var/run/lesslinux/wordlist")
			elsif  File.exists?("/lesslinux/isoloop/lesslinux/blob/wordlist.sqs")
				system("mount -o loop /lesslinux/isoloop/lesslinux/blob/wordlist.sqs /var/run/lesslinux/wordlist")
			else
				system("mount -o loop /lesslinux/cdrom/lesslinux/blob/wordlist.sqs /var/run/lesslinux/wordlist")
			end
		end
		wordlist = "everything.txt"
		wordlist = @tl.get_translation("dictfile") if @wpashortradio.active?
		caplist = Array.new
		Dir.entries("/tmp").each { |f|
			caplist.push("/tmp/" + f) if f =~ /airodump.*?\.cap/ 
		}
		@wpabruterunning = true
		@wpabrutevte.fork_command("aircrack-ng", [ "aircrack-ng",  "-w", "/var/run/lesslinux/wordlist/" + wordlist,  "-b", bssid ] + caplist )
		while @wpabruterunning == true
			sleep 0.5
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			vtetext = @wpabrutevte.get_text(false) #.join("")
			if vtetext =~ /KEY FOUND/   
				keyfound = true
			end
		end
		if @wpacrackkilled == true
			extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
			@wpacrackkilled = false 
			TileHelpers.remove_lock 
			return false
		end
		if vtetext =~ /packets contained no eapol data/i || vtetext =~ /got no data packets from target/i
			TileHelpers.error_dialog(@tl.get_translation("result_no_handshake"))
		elsif keyfound == true
			wifipsk = ""
			$stderr.puts("key found")
			if vtetext =~ /KEY FOUND!\s\[\s(.*?)\s\]/
				wifipsk = $1
				$stderr.puts("Key is: " + wifipsk) 
			end
			# Key was found dialog
			$stderr.puts("key found")
			TileHelpers.success_dialog(@tl.get_translation("result_key_cracked").gsub("WIFIPSK", wifipsk), @tl.get_translation("result_key_cracked_head"))
		else
			# Key not found dialog
			$stderr.puts("Key not found")
			TileHelpers.success_dialog(@tl.get_translation("result_couldnt_crack"), @tl.get_translation("result_couldnt_crack_head"))
		end
		extlayers.each { |k,v|v.hide_all }
		TileHelpers.remove_lock 
		TileHelpers.back_to_group
	end
	
	
	
	
	def fill_wlan_combo(combo=nil)
		combo = @wpacombo if combo.nil?
		netcount = 0
		@wifinetworks = Array.new
		100.downto(0) { |n|
			begin
				combo.remove_text(n)
			rescue
			end
		}
		get_networks.each { |n|
			if n.strip.length > 0
				netcount += 1
				combo.append_text n
				@wifinetworks.push n
			end
		}
		# FIXME translate
		combo.append_text(@tl.get_translation("nowifinetsfound")) if netcount < 1 
		combo.active = 0 
		return netcount 
	end
	
	# Get BSSID, channel and usable interface of a certain network
	def get_net_params(netname)
		interfaces = Array.new
		networks = Array.new
		iface = nil
		bssid = nil
		channel = 0
		IO.popen("/usr/sbin/iwconfig 2>&1") { |l|
			while l.gets
				line = $_.strip
				if line =~ /ESSID/
					interfaces.push(line.split[0])
				end
			end
		}
		interfaces.each { |i|
			tmpbssid = nil
			tmpchannel = nil
			IO.popen("iwlist #{i} scan") { |l|
				while l.gets
					line = $_.strip
					if line.split[0] =~ /Cell/ 
						tmpbssid = line.split[-1]
					end
					if line.split[0] =~ /Channel/ 
						tmpchannel = line.split(":")[-1].to_i
					end
					if line.split[0] =~ /ESSID/
						if line == "ESSID:\"#{netname}\""
							iface = i
							channel = tmpchannel
							bssid = tmpbssid
						end
					end
				end
			}
		}
		$stderr.puts("Found: #{iface}, #{channel}, #{bssid}")
		return iface, channel, bssid 
	end
	
	
	def get_networks 
		# First find interfaces:
		interfaces = Array.new
		networks = Array.new
		IO.popen("/usr/sbin/iwconfig 2>&1") { |l|
			while l.gets
				line = $_.strip
				if line =~ /ESSID/
					interfaces.push(line.split[0])
				end
			end
		}
		#interfaces.each { |i|
		#system("connmanctl enable wifi")
		system("connmanctl scan wifi")
		begin
			IO.popen("connmanctl services") { |l|
				while l.gets
					line = $_.strip
					netname = line
					networks.push(netname) if netname.size > 0 
				end
			}
		rescue
			$stderr.puts "Running connmanctl failed"
		end
		return networks
	end
	
end