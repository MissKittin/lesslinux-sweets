#!/usr/bin/ruby
# encoding: utf-8

class CloneScreen	
	def initialize(extlayers, nwscreen)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "CloneScreen.xml")
		@layers = Array.new
		### Kill cloning or run into errors
		@killclone = false
		@readwriteerror = false
		### ComboBox for source drives
		@sourcecombo = Gtk::ComboBox.new
		@sourcedrives = Array.new
		### ComboBox for target drives
		@targetcombo = Gtk::ComboBox.new
		@targetdrives = Array.new
		### ProgressBar for running dd
		@cloneprogress = Gtk::ProgressBar.new
		### Vte to run nbd server in and progress bar
		@nbdvte = Vte::Terminal.new 
		@nbdprogress = Gtk::ProgressBar.new
		
		# Do we clone locally or via network?
		@clonelocally = true 
		
		# attach source screen
		source = create_source_screen(extlayers)
		extlayers["clonesource"] = source
		@layers.push source
		# attach target screen
		target = create_target_screen(extlayers)
		extlayers["clonetarget"] = target
		@layers.push target
		# attach progress screen
		cloning = create_progress_screen(extlayers)
		extlayers["cloneprogress"] = cloning
		@layers.push cloning
		
		# Select network or local
		netlocal = create_select_screen(extlayers, nwscreen)
		extlayers["DEAD_selectclonemethod"] = netlocal
		@layers.push netlocal
		
		netsrctgt = source_or_target(extlayers)
		extlayers["selectclonesrctgt"] = netsrctgt
		@layers.push netsrctgt
		
		# Progress screen when nbd server is running
		nbdserve = create_nbd_serve_screen(extlayers)
		extlayers["nbdserver"] = nbdserve
		@layers.push nbdserve 
	end
	attr_reader :layers
	
	def get_ip
		ips = Array.new
		IO.popen("ip addr show") { |line|
			while line.gets
				l = $_
				if l.strip =~ /^inet\s/ 
					ltoks = l.strip.split
					ip = ltoks[1].split("/")[0] 
					ips.push(ip) unless ip =~ /^127\.0\.0/ 
				end
			end
		}
		return ips.join(", ") 
	end
	
	def find_nbd_servers
		nbdservers = Array.new
		ips = Array.new
		IO.popen("ip addr show") { |line|
			while line.gets
				l = $_
				if l.strip =~ /^inet\s/ 
					ltoks = l.strip.split
					ip = ltoks[1].split("/")[0] 
					ips.push(ip) unless ip =~ /^127\.0\.0/ 
				end
			end
		}
		ips.each { |ip|
			iptoks = ip.split(".")
			system("nmap -oG /var/log/lesslinux/nmap.30003.log -p 30003 #{iptoks[0]}.#{iptoks[1]}.#{iptoks[2]}.0/24")
			File.open("/var/log/lesslinux/nmap.30003.log").each { |line|
				if line =~ /^Host/
					ltoks = line.split 
					nbdservers.push(ltoks[1]) if ltoks[4] =~ /30003\/open/ 
				end
			}
		}
		return nbdservers 
	end
	
	def source_dialog
		ip = ""
		title = @tl.get_translation("please_enter_ip")
		dialog = Gtk::Dialog.new(title,
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ] )
		dialog.has_separator = false
		label = Gtk::Label.new(@tl.get_translation("enter_ip_description"))
		label.wrap = true
		# image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
		box = Gtk::VBox.new(false, 5)
		box.border_width = 10
		entry = Gtk::Entry.new
		entry.width_request = 200
		box.pack_start_defaults(label);
		box.pack_start_defaults(entry);
		dialog.vbox.add(box)
		dialog.show_all
		dialog.run do |response|
			ip = entry.text.strip 
		end
		dialog.destroy
		return ip 
	end
	
	def create_select_screen(extlayers, nwscreen)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		### First panel, selection of tasks
		# First tile, rescue on file system level
		button1 = Gtk::EventBox.new.add Gtk::Image.new("rescuewine.png")
		text1 = Gtk::Label.new
		text1.width_request = 320
		text1.wrap = true
		text1.set_markup("<span foreground='white'><b>" + @tl.get_translation("localclonehead") + "</b>\n" + @tl.get_translation("localclonebody") + "</span>")
	
		# Second tile, rescue to cloud
		button2 = Gtk::EventBox.new.add Gtk::Image.new("rescueturq.png")
		text2 = Gtk::Label.new
		text2.width_request = 320
		text2.wrap = true
		text2.set_markup("<span foreground='white'><b>" + @tl.get_translation("netclonehead") + "</b>\n"+ @tl.get_translation("netclonebody") + "</span>")
		
		fixed.put(button1, 0, 0)
		fixed.put(button2, 0, 140)
		fixed.put(text1, 130, 0)
		fixed.put(text2, 130, 140)
		
		button1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@clonelocally = true
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				TileHelpers.umount_all 
				extlayers.each { |k,v|v.hide_all }
				extlayers["clonesource"].show_all
			end
		}
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@clonelocally = false
				extlayers.each { |k,v|v.hide_all }
				if nwscreen.test_link == false
					nwscreen.nextscreen = "selectclonesrctgt"
					nwscreen.fill_wlan_combo 
					# Check for networks first...
					extlayers["networks"].show_all
				else
					extlayers["selectclonesrctgt"].show_all
				end
				
			end
		}
		return fixed
	end
	
	def prepare_clonesource
		@clonelocally = true
		TileHelpers.umount_all 
	end	
	
	def prepare_selectclonesrctgt(nwscreen)
		@clonelocally = false
		if nwscreen.test_link == false
			nwscreen.nextscreen = "selectclonesrctgt"
			nwscreen.fill_wlan_combo 
			return "networks"
		end
		return "selectclonesrctgt"
	end
	
	def source_or_target(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		### First panel, selection of tasks
		 
		
		# description:
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		dirtext = TileHelpers.create_label("<b>" + @tl.get_translation("directionhead") + "</b>\n\n" + @tl.get_translation("directionbody"), 510)
		# fixed.put(tile, 0, 0)
		fixed.put(dirtext, 0, 0)
		back = TileHelpers.place_back(fixed, extlayers) # , false)
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		forwtext = Gtk::Label.new
		forwtext.width_request = 250
		forwtext.wrap = true
		targettext = TileHelpers.create_label(@tl.get_translation("selecttarget"), 250)
		forwtext.set_markup("<span color='white'>" + @tl.get_translation("gotonext") + "</span>")
		fixed.put(forw, 650, 352)
		fixed.put(forwtext, 402, 358)

		selradio1 = Gtk::RadioButton.new
		selradio2 = Gtk::RadioButton.new(selradio1)
		fixed.put(selradio1, 0, 120)
		fixed.put(selradio2, 0, 150)
		
		selsource = TileHelpers.create_label(@tl.get_translation("thisissource"), 400)
		seltarget = TileHelpers.create_label(@tl.get_translation("thisistarget"), 400)
		fixed.put(selsource, 30, 120)
		fixed.put(seltarget, 30, 150)
		
		forw.signal_connect("button-release-event") { |x, y|
			if y.button == 1 
				# extlayers.each { |k,v|v.hide_all }
				if selradio1.active?
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					@sourcedrives = reread_drivelist(@sourcecombo)
					TileHelpers.umount_all 
					extlayers.each { |k,v|v.hide_all }
					extlayers["clonesource"].show_all
				else
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					srvrs = find_nbd_servers
					if srvrs.size == 1
						ip = srvrs[0]
					else
						ip = source_dialog
					end
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					@targetdrives = reread_drivelist(@targetcombo, @sourcedrives[@sourcecombo.active] )
					if system("nbd-client \"#{ip}\" 30003 /dev/nbd11") && @targetdrives.size > 0
						extlayers.each { |k,v|v.hide_all }
						extlayers["clonetarget"].show_all
					elsif @targetdrives.size < 1
						extlayers.each { |k,v|v.hide_all }
						extlayers["selectclonesrctgt"].show_all
						TileHelpers.error_dialog(@tl.get_translation("onedrivebody"), @tl.get_translation("nodrivehead"))
					end
				end
			end
		}
		
		return fixed	
	end
	
	def create_nbd_serve_screen(extlayers)
		fixed = Gtk::Fixed.new
		killswitch = TileHelpers.place_back(fixed, extlayers, false)
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("nbdservehead") + "</b>\n\n" + @tl.get_translation("nbdservebody"), 510)
		@nbdprogress.width_request = 510
		@nbdprogress.height_request = 32
		@nbdvte.signal_connect("child_exited") {
			unless @killclone == true
				TileHelpers.success_dialog(@tl.get_translation("nbdclonefinishedorterminated"))
			end
			@killclone = false
			extlayers.each { |k,v|v.hide_all }
			TileHelpers.back_to_group
		}
		killswitch.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# Some checks here!
				@killclone = true 
				system("killall -s SIGTERM nbd-server")
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		fixed.signal_connect("show") {
			if $startup_finished == true
				deltext.set_markup("<span color='white'><b>" + @tl.get_translation("nbdservehead") + "</b>\n\n" + @tl.get_translation("nbdservebody").gsub("IPADDRESS", get_ip) + "</span>")
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		# fixed.put(@nbdprogress, 130, 108)
		return fixed	
	end
	
	def create_source_screen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gototarget") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		@sourcecombo.height_request = 32
		@sourcecombo.width_request = 380
		deltext = TileHelpers.create_label(@tl.get_translation("selectsource"), 510)
		# @sourcedrives = reread_drivelist(@sourcecombo)
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @sourcedrives.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("nodrivebody"), @tl.get_translation("nodrivehead"))
				else
					@targetdrives = reread_drivelist(@targetcombo, @sourcedrives[@sourcecombo.active] )
					if @targetdrives.size < 1 && @clonelocally == true
						TileHelpers.error_dialog(@tl.get_translation("onedrivebody"), @tl.get_translation("nodrivehead"))
					else	
						extlayers.each { |k,v|v.hide_all }
						if @clonelocally == true
							extlayers["clonetarget"].show_all
						else
							@killclone = false 
							@nbdprogress.text = @tl.get_translation("nbdwaitingforconnection")
							@nbdprogress.pulse
							comm = [  "nbd-server", "30003", "/dev/" + @sourcedrives[@sourcecombo.active].device, "-r", "-d" ] 
							$stderr.puts comm.join(" ") 
							@nbdvte.fork_command(comm[0], comm )  
							extlayers["nbdserver"].show_all
						end
					end
				end
			end
		}
		reread.signal_connect('clicked') { 
			@sourcedrives = reread_drivelist(@sourcecombo)
		}
		fixed.signal_connect("show") {
			if $startup_finished == true
				if @clonelocally == true
					text5.set_markup("<span color='white'>" + @tl.get_translation("gototarget") + "</span>")
				else						
					text5.set_markup("<span color='white'>" + @tl.get_translation("startnbdserver") + "</span>")
				end
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(@sourcecombo, 0, 108)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 108)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_target_screen(extlayers)
		fixed = Gtk::Fixed.new
		backbutton = TileHelpers.place_back(fixed, extlayers, false)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotoclone") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		@targetcombo.height_request = 32
		@targetcombo.width_request = 380
		deltext = TileHelpers.create_label(@tl.get_translation("selecttarget"), 510)
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		reread.signal_connect('clicked') { 
			@targetdrives = reread_drivelist(@targetcombo, @sourcedrives[@sourcecombo.active] )
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# Some checks here!
				if TileHelpers.yes_no_dialog(@tl.get_translation("confirmbody"), @tl.get_translation("confirmhead"))
					if @clonelocally == true
						source = @sourcedrives[@sourcecombo.active] 
					else
						source = MfsDiskDrive.new("nbd11") 
					end
					target = @targetdrives[@targetcombo.active] 
					if source.size <= target.size ||  TileHelpers.yes_no_dialog(@tl.get_translation("toobigbody"), @tl.get_translation("toobighead"))
						extlayers.each { |k,v|v.hide_all }
						extlayers["cloneprogress"].show_all
						run_clone(@cloneprogress)
						system("nbd-client -d /dev/nbd11")
						if @killclone == false
							TileHelpers.success_dialog(@tl.get_translation("successbody"), @tl.get_translation("successhead"))
						elsif @readwriteerror == true 	
							TileHelpers.success_dialog(@tl.get_translation("readwriteerror"), @tl.get_translation("failedhead"))
						else
							TileHelpers.success_dialog(@tl.get_translation("failedbody"), @tl.get_translation("failedhead"))
						end
						extlayers.each { |k,v|v.hide_all }
						TileHelpers.back_to_group
					end
				end
			end
		}
		backbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("nbd-client -d /dev/nbd11")
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(@targetcombo, 0, 148)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 148)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_progress_screen(extlayers)
		fixed = Gtk::Fixed.new
		killswitch = TileHelpers.place_back(fixed, extlayers, false)
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		deltext = TileHelpers.create_label(@tl.get_translation("progresslabel"), 510)
		@cloneprogress.width_request = 510
		@cloneprogress.height_request = 32
		killswitch.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# Some checks here!
				@killclone = true 
			
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		 fixed.put(@cloneprogress, 0, 108)
		return fixed
	end
	
	def reread_drivelist(combobox, ignoredrive=nil)
		TileHelpers.set_lock 
		TileHelpers.umount_all
		100.downto(0) { |i| 
			begin
				combobox.remove_text(i) 
			rescue
			end
		}
		drives = Array.new
		auxdrives = Array.new
		Dir.entries("/sys/block").each { |l|
			auxdrives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		auxdrives.each { |d|
			if ignoredrive.nil?
				drives.push(d) unless d.mounted
			else
				drives.push(d) unless d.device == ignoredrive.device || d.mounted
			end
		}  
		drives.each { |d|
			label = label = "#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
			if d.usb == true
				label = label + " (USB)"
			else
				label = label + " (SATA/eSATA/IDE/NVME)"
			end
			combobox.append_text(label)
		}
		combobox.active = 0
		TileHelpers.remove_lock 
		return drives
	end
	
	def run_clone(progress)
		TileHelpers.set_lock 
		@killclone = false
		@readwriteerror = false 
		progress.text = @tl.get_translation("start_cloning") 
		progress.fraction = 0.0
		starttime = Time.now.to_i
		# threshold for certain block sizes - in bytes
		thres = 32 * 1024 ** 3 
		# chunk size - in megabytes
		chunk = 128
		if @clonelocally == true
			source = @sourcedrives[@sourcecombo.active] 
		else
			source = MfsDiskDrive.new("nbd11") 
		end
		target = @targetdrives[@targetcombo.active] 
		min = [source.size, target.size].min
		puts "Source size: #{source.size.to_s}"
		puts "Target size: #{target.size.to_s}"
		puts "Min size:    #{min.to_s}"
		if min < thres 
			chunk = 16
		end
		# real number is one higher!
		num_chunks = ( min / chunk / ( 1024 ** 2) )
		puts num_chunks.to_s 
		0.upto(num_chunks) { |n|
			unless File.blockdev?("/dev/#{source.device}") && File.blockdev?("/dev/#{target.device}")
				@killclone = true
				@readwriteerror = true 
			end
			unless @killclone == true
				current_time = Time.now.to_i
				position = n * chunk * 1024 ** 2
				chunkbytes = chunk * 1024 ** 2
				progress.fraction = n.to_f / num_chunks.to_f
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				command = "ddrescue --force --retry-passes=5 -i #{position.to_s} -o #{position.to_s} -s #{chunkbytes.to_s} /dev/#{source.device} /dev/#{target.device}"
				puts "RUNNING: #{command}"
				system command
				t = @tl.get_translation("percentdone").gsub("PERCENTAGE",  (n * 100 / num_chunks).to_s )
				# t = (n * 100 / num_chunks).to_s + "% abgeschlossen" 
				delta_time = current_time - starttime
				if delta_time > 20 && n > 2
					time_per_chunk = delta_time.to_f / n.to_f
					time_remaining = ( num_chunks.to_f - n.to_f ) * time_per_chunk
					minutes_remaining = ( time_remaining + 30.0 ) / 60.0 
					nice_minutes = minutes_remaining.to_i % 60
					nice_hours = minutes_remaining.to_i / 60
					if nice_hours < 1 && nice_minutes < 3
						t = t + " - " +  @tl.get_translation("remain1") # ca. eine Minute verbleibend"
					elsif nice_hours < 2
						t = t + " - " + @tl.get_translation("remain2").gsub("MINUTES", minutes_remaining.to_i.to_s)
					else
						t = t + " - " + @tl.get_translation("remain2").gsub("MINUTES", nice_minutes.to_s).gsub("HOURS", nice_hours.to_s) 
					end
				end
				progress.text = t
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
			end
		}
		TileHelpers.remove_lock
	end
	
end

