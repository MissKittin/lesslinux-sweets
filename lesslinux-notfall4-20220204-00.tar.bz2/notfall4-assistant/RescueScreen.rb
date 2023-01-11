#!/usr/bin/ruby
# encoding: utf-8

class RescueScreen	
	def initialize(extlayers, button, drivebutton, nwscreen)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "RescueScreen.xml")
		@lastpulse = Time.now.to_f 
		### Combo for writeable drives when file managers are selected
		@writeablecombo = nil
		@writeablevsscombo = nil
		@writeablelist = Array.new
		@writeableparts = Array.new
		# Try to omit opening of firefox when the cloud layer is shown the first time
		@cloudshowcount = 0
		# Table for profiles
		@profiletable = nil
		@profilechecks = Array.new
		@profilelabels = Array.new
		@profilesources = Array.new 
		@profiletargetlist = Array.new
		@profiletargetcombo = nil
		@bdpass = Hash.new
		# Windows 7 converter
		@sourcecombo = Gtk::ComboBox.new
		@sourcedrives = Array.new
		@overwritecheck = Gtk::CheckButton.new
		@targetcombo = Gtk::ComboBox.new
		@targetdrives = Array.new 
		@cloneprogress = Gtk::ProgressBar.new
		@rescuepath = "Windows-7-Retter"
		@imagename = "win7.vdi"
		@killclone = false  
		
		### First panel, selection of tasks
		# First tile, rescue on file system level
		button1 = Gtk::EventBox.new.add Gtk::Image.new("rescuewine.png")
		text1 = Gtk::Label.new
		text1.width_request = 320
		text1.wrap = true
		text1.set_markup("<span foreground='white'><b>" + @tl.get_translation("localhead") + "</b>\n" + @tl.get_translation("localbody") + "</span>")
	
		# Second tile, rescue to cloud
		button2 = Gtk::EventBox.new.add Gtk::Image.new("rescueturq.png")
		text2 = Gtk::Label.new
		text2.width_request = 320
		text2.wrap = true
		text2.set_markup("<span foreground='white'><b>" + @tl.get_translation("cloudhead1") + "</b>\n"+ @tl.get_translation("cloudbody1") + "</span>")
		
		# Third tile, image 1:1
		button3 = Gtk::EventBox.new.add Gtk::Image.new("rescuewine.png")
		text3 = Gtk::Label.new
		text3.width_request = 320
		text3.wrap = true
		# text3.set_markup("<span foreground='white'><b>Klon Ihrer Festplatte</b>\n\nWählen Sie diese Option bei drohenden Festplattendefekten. Sämtliche Partitionen, Dateien und Programme auf dem Laufwerk werden eins zu eins auf eine externe Festplatte überspielt. Achtung: Alle auf dem Ziel-Laufwerk gespeicherte Daten gehen dadurch verloren!</span>.")
		text3.set_markup("<span foreground='white'><b>" + @tl.get_translation("imagehead") + "</b>\n" + @tl.get_translation("imagebody")  + "</span>")
		
		# Fourth tile, clone 1:1
		button4 = Gtk::EventBox.new.add Gtk::Image.new("rescueturq.png")
		text4 = Gtk::Label.new
		text4.width_request = 320
		text4.wrap = true
		# text3.set_markup("<span foreground='white'><b>Klon Ihrer Festplatte</b>\n\nWählen Sie diese Option bei drohenden Festplattendefekten. Sämtliche Partitionen, Dateien und Programme auf dem Laufwerk werden eins zu eins auf eine externe Festplatte überspielt. Achtung: Alle auf dem Ziel-Laufwerk gespeicherte Daten gehen dadurch verloren!</span>.")
		text4.set_markup("<span foreground='white'><b>" + @tl.get_translation("clonehead") + "</b>\n" + @tl.get_translation("clonebody")  + "</span>")
		
		# Fifth tile, Quick backup
		button5 = Gtk::EventBox.new.add Gtk::Image.new("rescueorange.png")
		text5 = Gtk::Label.new
		text5.width_request = 360
		text5.wrap = true
		text5.set_markup("<span foreground='white'><b>" + @tl.get_translation("quickhead") + "</b>\n" + @tl.get_translation("quickbody")  + "</span>")
		
		# Sixth tile, move windows 7 to an VM image
		button6 = Gtk::EventBox.new.add Gtk::Image.new("rescueorange.png")
		text6 = Gtk::Label.new
		text6.width_request = 350
		text6.wrap = true
		text6.set_markup("<span foreground='white'><b>" + @tl.get_translation("sevenreschead") + "</b>\n" + @tl.get_translation("sevenrescbody")  + "</span>")
		
		
		@layers = Array.new
		
		# First fixed for panel save files
		fixed = Gtk::Fixed.new
		fixed.put(button1, 0, 0)
		fixed.put(button2, 0, 140)
		fixed.put(button5, 460, 0)
		
		fixed.put(text1, 130, 0)
		fixed.put(text2, 130, 140)
		fixed.put(text5, 590, 0)
		
		# Second fixed for panel save drives 
		fixeddrive = Gtk::Fixed.new
		fixeddrive.put(button3, 0, 0)
		fixeddrive.put(button4, 0, 140)
		fixeddrive.put(button6, 460, 0)
		
		fixeddrive.put(text3, 130, 0)
		fixeddrive.put(text4, 130, 140)
		fixeddrive.put(text6, 590, 0)
		
		TileHelpers.place_back(fixed, extlayers)
		TileHelpers.place_back(fixeddrive, extlayers)
		extlayers["DEAD_rescuestart"] = fixed
		@layers[0] = fixed
		extlayers["DEAD_rescuedrivestart"] = fixeddrive
		@layers[1] = fixeddrive 
		
		drivebutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["rescuedrivestart"].show_all
			end
		}
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["rescuestart"].show_all
			end
		}
		button1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				TileHelpers.umount_all 
				@writeablelist, @writeableparts = reread_targetlist(@writeablecombo)
				extlayers.each { |k,v|v.hide_all }
				extlayers["rescuelocal"].show_all
			end
		}
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if nwscreen.test_connection == false
					extlayers.each { |k,v|v.hide_all }
					nwscreen.nextscreen = "rescuecloud"
					nwscreen.fill_wlan_combo 
					# Check for networks first...
					extlayers["networks"].show_all
				else
					extlayers.each { |k,v|v.hide_all }
					extlayers["rescuecloud"].show_all
				end
				
			end
		}
		button3.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				# extlayers["clonesource"].show_all
				extlayers["imagechoice"].show_all
			end
		}
		button4.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				# extlayers["clonesource"].show_all
				# extlayers["clonesource"].show_all
				extlayers["selectclonemethod"].show_all
			end
		}
		button5.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				fill_profile_layer
				extlayers.each { |k,v| v.hide_all }
				# extlayers["clonesource"].show_all
				extlayers["rescueprofile"].show_all
			end
		}
		button6.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				@sourcedrives = reread_drivelist(@sourcecombo)
				extlayers.each { |k,v| v.hide_all }
				# extlayers["clonesource"].show_all
				extlayers["sevensavesourcelayer"].show_all
			end
		}
		
		#### Screen for filetypes
		locallayers = get_local_layer(extlayers)
		extlayers["rescuelocal"] = locallayers
		@layers[2]  = locallayers

		#### Screen for file manager
		fmlayers = get_fm_layer(extlayers)
		extlayers["rescuefilemanager"] = fmlayers
		@layers[3]  = fmlayers
		
		#### Screen for cloud
		cloudlayer = get_cloud_layer(extlayers)
		extlayers["rescuecloud"] = cloudlayer
		@layers[4] = cloudlayer
		
		profilelayer = get_profile_layer(extlayers)
		extlayers["rescueprofile"] = profilelayer
		@layers[5] = profilelayer
		
		proftargetlayer = get_profile_target_layer(extlayers)
		extlayers["rescueprofiletarget"] = proftargetlayer
		@layers[6] = proftargetlayer
		
		proffinishlayer = get_profile_finish_layer(extlayers)
		extlayers["rescueprofilefinish"] = proffinishlayer
		@layers[7] = proffinishlayer
		
		#### Screen for file manager (VSS)
		fmvsslayers = get_vss_layer(extlayers)
		extlayers["rescuefilemanagervss"] = fmvsslayers
		@layers[8]  = fmvsslayers
		
		### Screen for Win 7 to VM conversion
		sevensavesrclayer = get_sevensave_source_layer(extlayers)
		extlayers["sevensavesourcelayer"] = sevensavesrclayer 
		@layers[9] = sevensavesrclayer
		
		sevensavetgtlayer = get_sevensave_target_layer(extlayers)
		extlayers["sevensavetargetlayer"] = sevensavetgtlayer 
		@layers[10] = sevensavetgtlayer
		
		sevensaveproglayer = get_sevensave_progress_layer(extlayers)
		extlayers["sevensaveprogresslayer"] = sevensaveproglayer 
		@layers[11] = sevensaveproglayer
		

	end
	attr_reader :layers, :sourcecombo
	attr_accessor :sourcedrives
	
	def prepare_rescueprofile
		fill_profile_layer
	end
	
	def prepare_sevensavesourcelayer
		@sourcedrives = reread_drivelist(@sourcecombo)
	end
	
	def prepare_rescuelocal
		TileHelpers.umount_all 
		@writeablelist, @writeableparts = reread_targetlist(@writeablecombo)
	end
	
	def prepare_rescuecloud(nwscreen)
		if nwscreen.test_connection == false
			nwscreen.nextscreen = "rescuecloud"
			nwscreen.fill_wlan_combo 
			return "networks"
		else
			return "rescuecloud"
		end
	end
	
	def get_local_layer(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("targethead") + "</b>\n\n" +@tl.get_translation("targetbody") , 510)
		vssradio = Gtk::CheckButton.new
		vssradio.active = false 
		vsslabel = TileHelpers.create_label(@tl.get_translation("vss"), 200)
		@writeablecombo = Gtk::ComboBox.new
		@writeablecombo.height_request = 32
		@writeablecombo.width_request = 380
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		reread.signal_connect('clicked') {
			TileHelpers.umount_all 
			@writeablelist, @writeableparts = reread_targetlist(@writeablecombo)
		}
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotofilemanager") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		button1 = Gtk::Image.new("rescuegreen.png")
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @writeableparts.size < 1
					TileHelpers.error_dialog(@tl.get_translation("nosuitabledrives"), @tl.get_translation("nosuitablehead"))
				else
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					mount_all( @writeableparts[@writeablecombo.active], vssradio.active?, true )
					extlayers.each { |k,v|v.hide_all }
					extlayers["rescuefilemanager"].show_all
					system("su surfer -c 'Thunar /cobi/" + @tl.get_translation("backupdir") + "' &") 
					system("su surfer -c 'Thunar /media/disk' &") 
					system("su surfer -c 'Thunar /media/vss' &") if vssradio.active?
				end
			end
		}
		# fixed.put(button1, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(vssradio, 0, 118)
		fixed.put(vsslabel, 26, 124)
		fixed.put(reread, 390, 150)
		fixed.put(@writeablecombo, 0, 150)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end

	def get_vss_layer(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("vsstargethead") + "</b>\n\n" +@tl.get_translation("vsstargetbody") , 510)
		@writeablevsscombo = Gtk::ComboBox.new
		@writeablevsscombo.height_request = 32
		@writeablevsscombo.width_request = 380
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		reread.signal_connect('clicked') {
			TileHelpers.umount_all 
			@writeablelist, @writeableparts = reread_targetlist(@writeablevsscombo)
		}
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotofilemanager") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		button1 = Gtk::Image.new("rescuegreen.png")
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @writeableparts.size < 1
					TileHelpers.error_dialog(@tl.get_translation("nosuitabledrives"), @tl.get_translation("nosuitablehead"))
				else
					mount_all( @writeableparts[@writeablevsscombo.active], true, false)
					if File.directory?("/media/vss")
						extlayers.each { |k,v|v.hide_all }
						extlayers["rescuefilemanager"].show_all
						system("su surfer -c 'Thunar /cobi/" + @tl.get_translation("backupdir") + "' &") 
						system("su surfer -c 'Thunar /media/vss' &")
					else
						TileHelpers.error_dialog(@tl.get_translation("novssfoundtext"), @tl.get_translation("novssfoundhead"))
					end
				end
			end
		}
		fixed.signal_connect("show") {
			TileHelpers.umount_all if $startup_finished 
			@writeablelist, @writeableparts = reread_targetlist(@writeablevsscombo) if @startup_finished 
		}
		# fixed.put(button1, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 150)
		fixed.put(@writeablevsscombo, 0, 150)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end

	# Layer for filemanager
	def get_fm_layer(extlayers)
		fixed = Gtk::Fixed.new
		backbutton = TileHelpers.place_back(fixed, extlayers, false)
		button1 = Gtk::Image.new("rescuegreen.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("copyhead") + "</b>\n\n" + @tl.get_translation("copybody") , 510)
		thbutton = Gtk::Button.new(@tl.get_translation("openfilemanager"))
		thbutton.width_request = 150
		thbutton.height_request = 32
		thbutton.signal_connect('clicked') {
			system("su surfer -c 'Thunar /media' &") 
			system("su surfer -c 'Thunar /cobi/" + @tl.get_translation("backupdir") + "' &") 
		}
		backbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				system("killall Thunar")
				system("killall -9 Thunar")
				system("killall thunar")
				system("killall -9 thunar")
				TileHelpers.umount_all
				system("sync")
				sleep 0.5
				TileHelpers.umount_all
				TileHelpers.back_to_group 
			end
		}
		# fixed.put(button1, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(thbutton, 360, 128)
		return fixed
	end

	def get_cloud_layer(extlayers)
		fixed = Gtk::Fixed.new
		backbutton = TileHelpers.place_back(fixed, extlayers, false)
		button1 = Gtk::Image.new("rescuegreen.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("cloudhead") + "</b>\n\n" + @tl.get_translation("cloudbody"), 510)
		ffbutton =Gtk::Button.new(@tl.get_translation("openfilemanager"))
		ffbutton.width_request = 150
		ffbutton.height_request = 32
		# Dropdown for preconfigured cloud services
		clouddrop = Gtk::ComboBox.new
		clouddrop.width_request = 425
		droplabel = TileHelpers.create_label(@tl.get_translation("cloudservice"), 80)
		# Add default texts
		cloudservices = [ 
			"Google Drive", 		#  0 FUSE
			"Microsoft OneDrive", 		#  1 FUSE
			"Telekom MagentaCloud", 	#  2 DAV
			"GMX Cloud",  			#  3 DAV
			"1&1 Online-Speicher",  	#  4 DAV
			"Strato HiDrive", 		#  5 DAV
			"WEB.de", 			#  6 DAV
			"Freenet Cloud", 		#  7 DAV
			"Box", 				#  8 DAV
			"Mega", 			#  9 Webseite
			"Samsung Cloud", 		# 10 Webseite 
			"DropBox", 			# 11 Website
			"mobilcom-debitel Cloud", 	# 12 Webseite
			"Apple iCloud", 		# 13 Webseite 
			"Amazon Drive", 		# 14 Webseite 
			@tl.get_translation("other_website"),  
			@tl.get_translation("other_webdav")
		]
		davurls = [ 
			"https://drive.google.com/", 			#  0
			"https://onedrive.live.com/about/de-de/", 	#  1
			"https://webdav.magentacloud.de/",		#  2 
			"https://webdav.mc.gmx.net/", 			#  3
			"https://sd2av.1und1.de/", 			#  4
			"https://webdav.hidrive.strato.com/", 		#  5
			"https://webdav.smartdrive.web.de/", 		#  6
			"https://webmail.freenet.de/webdav", 		#  7
			"https://dav.box.com/dav",			#  8
			"https://mega.nz/",				#  9
			"https://support.samsungcloud.com",		# 10
			"https://www.dropbox.com/de",			# 11
			"https://cloud.md.de/md/login.php", 		# 12
			"https://www.icloud.com/",			# 13
			"https://www.amazon.de/clouddrive/home/",	# 14
			nil, 
			nil 
		] 
		cloudservices.each { |s| clouddrop.append_text(s) }
		
		# Servername (optional)
		cloudserver = Gtk::Entry.new
		cloudserver.width_request = 425
		cloudserver.text = "https://my.owncloud.abc/"
		serverlabel = TileHelpers.create_label(@tl.get_translation("cloudserver"), 80)
		# Auth token (optional)
		cloudtoken = Gtk::Entry.new
		cloudtoken.width_request = 340
		tokenlabel = TileHelpers.create_label(@tl.get_translation("cloudtoken"), 80)
		tokenbutton = Gtk::Button.new(@tl.get_translation("createtoken"))
		tokenbutton.width_request = 80
		# Username
		clouduser = Gtk::Entry.new
		clouduser.width_request = 425
		userlabel = TileHelpers.create_label(@tl.get_translation("clouduser"), 80)
		# Password
		cloudpass = Gtk::Entry.new 
		cloudpass.width_request = 425
		cloudpass.visibility = false 
		passlabel = TileHelpers.create_label(@tl.get_translation("cloudpass"), 80)
		clouddrop.active = 0 
		cloudserver.visible = false
		serverlabel.visible = false
		cloudserver.sensitive = false
		clouddrop.signal_connect('changed') { 
			ffbutton.label = @tl.get_translation("openfilemanager")
			if clouddrop.active == cloudservices.size - 1
				cloudserver.sensitive = true
				cloudserver.visible = true
				serverlabel.visible = true
				[ clouduser, cloudpass, userlabel, passlabel ].each { |w| w.visible = true }
				[ tokenlabel, tokenbutton, cloudtoken ].each { |w| w.visible = false }
			elsif clouddrop.active == cloudservices.size - 2
				ffbutton.label = @tl.get_translation("openfirefox")
				cloudserver.sensitive = false
				cloudserver.visible = false
				serverlabel.visible = false
				[ clouduser, cloudpass, userlabel, passlabel ].each { |w| w.visible = false }
				[ tokenlabel, tokenbutton, cloudtoken ].each { |w| w.visible = false }
			#elsif clouddrop.active == 0
			#	cloudserver.sensitive = false
			#	cloudserver.visible = false
			#	serverlabel.visible = false
			#	[ clouduser, cloudpass, userlabel, passlabel ].each { |w| w.visible = false }
			#	[ tokenlabel, tokenbutton, cloudtoken ].each { |w| w.visible = true }
			elsif clouddrop.active > 8 || clouddrop.active == 0 || clouddrop.active == 1
				ffbutton.label = @tl.get_translation("openfirefox")
				cloudserver.sensitive = false
				cloudserver.visible = false
				serverlabel.visible = false
				[ clouduser, cloudpass, userlabel, passlabel ].each { |w| w.visible = false }
				[ tokenlabel, tokenbutton, cloudtoken ].each { |w| w.visible = false }	
			else
				cloudserver.sensitive = false
				cloudserver.visible = false
				serverlabel.visible = false
				[ clouduser, cloudpass, userlabel, passlabel ].each { |w| w.visible = true }
				[ tokenlabel, tokenbutton, cloudtoken ].each { |w| w.visible = false }
			end
		}
		tokenbutton.signal_connect('clicked') {
			url = nil
			IO.popen("gdfstool auth -u") { |l|
				while l.gets
					url = $_.strip if $_ =~ /^https/ 
				end
			}
			if url.nil?
				TileHelpers.error_dialog(@tl.get_translation("gdfs_auth_failed"))
			else
				system("su surfer -c \"firefox '#{url}' &\"")
			end
		}
		ffbutton.signal_connect('clicked') {
			if clouddrop.active == cloudservices.size - 2
				system("su surfer -c 'firefox &'") # http://www.computerbild-cloud.de/' &") 
			elsif clouddrop.active == cloudservices.size - 1 # other WebDAV or CIFS
				if cloudserver.text.strip =~ /^http\:\/\// || cloudserver.text.strip =~ /^https\:\/\//
					mount_webdav(cloudserver.text.strip, clouduser.text.strip, cloudpass.text.strip)
					system("su surfer -c 'thunar /media/disk' &") 
				elsif cloudserver.text.strip =~ /^cifs\:\/\// || cloudserver.text.strip =~ /^smb\:\/\//
					mount_cifs(cloudserver.text.strip, clouduser.text.strip, cloudpass.text.strip)
					system("su surfer -c 'thunar /media/disk' &") 
				else
					TileHelpers.error_dialog @tl.get_translation("unknown_protocol")
				end
			#elsif clouddrop.active == 0 # Google
			#	if cloudtoken.text.strip.size < 1
			#		TileHelpers.error_dialog(@tl.get_translation("gdfs_token_missing"))
			#	else
			#		success = gdrivefs_mount(cloudtoken.text)
			#		TileHelpers.error_dialog(@tl.get_translation("gdfs_auth_failed")) unless success == true
			#	end
			#elsif clouddrop.active == 1 # Microsoft
			#	system("su surfer -c 'firefox https://onedrive.live.com/' &") 
			#	system("su surfer -c 'thunar /media/disk' &") 
			elsif clouddrop.active > 7 || clouddrop.active == 0 || clouddrop.active == 1
				system("su surfer -c 'firefox #{davurls[clouddrop.active]}' &") 
				system("killall -9 thunar") 
				system("killall -9 Thunar") 
				sleep 0.5
				system("su surfer -c 'thunar /media/disk' &") 
			else # predefined WebDAV
				mount_webdav(davurls[clouddrop.active], clouduser.text.strip, cloudpass.text.strip)
			end
		}
		fixed.signal_connect('show') {
			ffbutton.label = @tl.get_translation("openfilemanager")
			if clouddrop.active == cloudservices.size - 1
				cloudserver.sensitive = true
				cloudserver.visible = true
				serverlabel.visible = true
				[ clouduser, cloudpass, userlabel, passlabel ].each { |w| w.visible = true }
				[ tokenlabel, tokenbutton, cloudtoken ].each { |w| w.visible = false }
			elsif clouddrop.active == cloudservices.size - 2
				ffbutton.label = @tl.get_translation("openfirefox")
				cloudserver.sensitive = false
				cloudserver.visible = false
				serverlabel.visible = false
				[ clouduser, cloudpass, userlabel, passlabel ].each { |w| w.visible = false }
				[ tokenlabel, tokenbutton, cloudtoken ].each { |w| w.visible = false }
			#elsif clouddrop.active == 0
			#	cloudserver.sensitive = false
			#	cloudserver.visible = false
			#	serverlabel.visible = false
			#	[ clouduser, cloudpass, userlabel, passlabel ].each { |w| w.visible = false }
			#	[ tokenlabel, tokenbutton, cloudtoken ].each { |w| w.visible = true }
			elsif clouddrop.active > 7 || clouddrop.active == 0 || clouddrop.active == 1
				ffbutton.label = @tl.get_translation("openfirefox")
				cloudserver.sensitive = false
				cloudserver.visible = false
				serverlabel.visible = false
				[ clouduser, cloudpass, userlabel, passlabel ].each { |w| w.visible = false }
				[ tokenlabel, tokenbutton, cloudtoken ].each { |w| w.visible = false }
			else
				cloudserver.sensitive = false
				cloudserver.visible = false
				serverlabel.visible = false
				[ clouduser, cloudpass, userlabel, passlabel ].each { |w| w.visible = true }
				[ tokenlabel, tokenbutton, cloudtoken ].each { |w| w.visible = false }
			end
			if $startup_finished 
				$stderr.puts("DEBUG: RescueScreen.rb, mounting everything")
				mount_all 
			end
			#	system("su surfer -c 'firefox &'") #  http://www.computerbild-cloud.de/' &") 
		}
		backbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				system("killall -15 firefox")
				sleep 1.0
				system("killall -9 firefox")
				system("killall -9 thunar") 
				system("killall -9 Thunar") 
				TileHelpers.umount_all
				system("sync")
				sleep 0.5
				TileHelpers.umount_all
				if TileHelpers.cloud_count > 0
					TileHelpers.umount_cloud if TileHelpers.yes_no_dialog(@tl.get_translation("umount_cloud")) == true 
				end
				TileHelpers.back_to_group
			end
		}
		# fixed.put(button1, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(clouddrop, 90, 108)
		fixed.put(droplabel, 0, 108)
		fixed.put(cloudserver, 90, 144)
		fixed.put(serverlabel, 0, 144)
		fixed.put(cloudtoken, 90, 144)
		fixed.put(tokenlabel, 0, 144)
		fixed.put(tokenbutton, 4355, 144)
		fixed.put(clouduser, 90, 180)
		fixed.put(userlabel, 0, 180)
		fixed.put(cloudpass, 90, 216)
		fixed.put(passlabel, 0, 216)
		
		fixed.put(ffbutton, 365, 257)
		return fixed
	end
	
	def gdrivefs_mount(authtoken)
		if system("mountpoint -q /media/cloud/googledrive")
			system("nohup su surfer -c \"Thunar '/media/cloud/googledrive'\" &")
		end
		system("mkdir -p /media/cloud/googledrive")
		result = ` gdfstool auth -a /var/cache/googledrive '#{authtoken}' ` 
		system("gdfs -o allow_other /var/cache/googledrive /media/cloud/googledrive")
		if system("mountpoint -q /media/cloud/googledrive")
			system("nohup su surfer -c \"Thunar '/media/cloud/googledrive'\" &")
			return true 
		else
			return false
		end
	end
	
	def mount_webdav(davurl, user, password)
		TileHelpers.set_lock 
		protopath = davurl.split("://")
		hostfolder = protopath[1].split("/")
		if system("mountpoint \"/media/webdav/#{hostfolder[0]}/#{user.gsub("@", ".")}\"")
		#	TileHelpers.error_dialog(@tl.get_translation("already_mounted")) 
		#	return true
		else
			system("mkdir -p \"/media/webdav/#{hostfolder[0]}/#{user.gsub("@", ".")}\"")
			system("echo -e '#{user}\n#{password}\ny' | LANG=en_GB.UTF-8 LANGUAGE=en mount.davfs -o rw,uid=1000,gid=1000,dir_mode=755,file_mode=644 \"#{davurl}\" \"/media/webdav/#{hostfolder[0]}/#{user.gsub("@", ".")}\"")
		end
		if system("mountpoint '/media/webdav/#{hostfolder[0]}/#{user.gsub("@", ".")}'")
			system("nohup su surfer -c \"Thunar '/media/webdav/#{hostfolder[0]}/#{user.gsub("@", ".")}'\" &")
			system("su surfer -c 'thunar /media/disk' &") 
			TileHelpers.remove_lock
			return true
		else
			TileHelpers.error_dialog(@tl.get_translation("error_mounting"))
			TileHelpers.remove_lock
			return false
		end
		TileHelpers.remove_lock
	end
	
	def mount_cifs(cifsurl, user, password)
		TileHelpers.set_lock 
		protopath = cifsurl.split("://")
		hostfolder = protopath[1].split("/")
		if system("mountpoint /media/cifs/#{hostfolder[0]}/#{hostfolder[1]}")
			TileHelpers.error_dialog(@tl.get_translation("already_mounted")) 
			TileHelpers.remove_lock
			return true
		else
			system("mkdir -p /media/cifs/#{hostfolder[0]}/#{hostfolder[1]}")
		end
		if user.strip == "" || password.strip == ""
			system("mount.cifs -o 'rw,uid=1000,gid=1000,file_mode=0644,dir_mode=0755,nounix,guest,iocharset=utf8' '//#{hostfolder[0]}/#{hostfolder[1]}' '/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}'")
		else
			system("mount.cifs -o 'rw,uid=1000,gid=1000,file_mode=0644,dir_mode=0755,nounix,user=#{user},pass=#{password},iocharset=utf8' '//#{hostfolder[0]}/#{hostfolder[1]}' '/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}'")
		end
		if system("mountpoint '/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}'")
			system("nohup su surfer -c 'Thunar \"/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}\"' &")
			TileHelpers.remove_lock
			return true
		else
			TileHelpers.error_dialog(@tl.get_translation("error_mounting"))
			TileHelpers.remove_lock
			return false
		end
		TileHelpers.remove_lock
	end
	
	def get_clonestart_layer(extlayers)
		
	end
	
	def reread_targetlist(combobox)
		TileHelpers.set_lock 
		100.downto(0) { |i| 
			begin
				combobox.remove_text(i) 
			rescue
			end
		}
		TileHelpers.umount_all
		drives = Array.new
		partitions = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		drives.reverse.each { |d|
			d.partitions.each  { |p|
				label = "#{d.vendor} #{d.model}"
				if d.usb == true
					label = label + " (USB) "
				else
					label = label + " (SATA/eSATA/IDE/NVME) "
				end
				label = label + "#{p.device} #{p.human_size}"
				label = @tl.get_translation("backup_medium") + " " + label if p.label.to_s == "USBDATA"
				pmnt = p.mount_point
				if ( p.fs =~ /vfat/ || p.fs =~ /ntfs/ || p.fs =~ /ext/ || p.fs =~ /btrfs/ ) && pmnt.nil?
					label = label + " #{p.fs}"
					partitions.push p.device
					combobox.append_text(label)
				end
			}
		}
		combobox.active = 0
		TileHelpers.remove_lock
		return drives, partitions
	end
	
	# @writeablelist, @writeableparts = reread_targetlist(@writeablecombo)
	def rescuelocal_read_targetlist 
		@writeablelist, @writeableparts = reread_targetlist(@writeablecombo)
	end
	
	def get_profile_layer(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("profilehead") + "</b>\n\n" +@tl.get_translation("profilebody") , 700)
		delscroll = Gtk::ScrolledWindow.new
		delscroll.height_request = 150
		delscroll.width_request = 700
		delscroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC ) 
		@profiletable = Gtk::Table.new(2, 11, false)
		align = Gtk::Alignment.new(0, 0, 0.1, 0.1)
		align.add @profiletable
		delscroll.add_with_viewport align
		anc = @profiletable.get_ancestor(Gtk::Viewport)
		# anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#052f4c') )
		
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gototargetchoice") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		button1 = Gtk::Image.new("rescuegreen.png")
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v| v.hide_all }
				# extlayers["clonesource"].show_all
				@profiletargetlist = fill_profile_targetlist(@profiletargetcombo)
				extlayers["rescueprofiletarget"].show_all
			end
		}
		
		# fixed.put(button1, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(delscroll, 0, 115)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def get_profile_target_layer(extlayers)
		#### Panel for selection of found profiles
		
		selfixed = Gtk::Fixed.new
		selnext = Gtk::Label.new
		selnext.width_request = 230
		selnext.wrap = true
		selnext.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		selforw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		sellogotile = Gtk::Image.new("rescuegreen.png")
		selbodytext = TileHelpers.create_label("<b>" + @tl.get_translation("proftargethead") + "</b>\n\n" + @tl.get_translation("proftargetbody") , 700)
		
		@profiletargetcombo = Gtk::ComboBox.new
		@profiletargetcombo.width_request = 700
		
		selfixed.put(selforw, 650, 352)
		selfixed.put(selnext, 402, 358)
		
		# selfixed.put(sellogotile, 0, 0)
		selfixed.put(selbodytext, 0, 0)
		selfixed.put(@profiletargetcombo, 0, 90)
		TileHelpers.place_back(selfixed, extlayers)
		
		selforw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# extlayers.each { |k,v| v.hide_all }
				# extlayers["clonesource"].show_all
				# partitions = fill_profile_targetlist(@profiletargetcombo)
				allsources = Array.new
				puts @profiletargetcombo.active.to_s 
				puts @profiletargetlist[@profiletargetcombo.active].device 
				# @profilelabels.each { |l| puts l }
				@profiletargetlist.each { |l| puts l.device }
				sourcecount = 0
				profcount = 0
				totalsize = 0
				@profilesources.each { |p|
					if @profilechecks[sourcecount].active?
						puts p[0].device + " " + p[1] + " " + p[2].to_s
						allsources.push p[0].device  
						totalsize += p[2]
						profcount += 1
					end
					sourcecount += 1
				}
				puts "Totalsize:  #{totalsize.to_s}"
				puts "Free space: #{@profiletargetlist[@profiletargetcombo.active].free_space}"
				if allsources.include? @profiletargetlist[@profiletargetcombo.active].device 
					TileHelpers.error_dialog(@tl.get_translation("error_dir_on_target") )
					extlayers.each { |k,v| v.hide_all }
					extlayers["rescueprofile"].show_all
				elsif profcount < 1
					TileHelpers.error_dialog(@tl.get_translation("error_no_selection"))
					extlayers.each { |k,v| v.hide_all }
					extlayers["rescueprofile"].show_all
				elsif totalsize * 1100 > @profiletargetlist[@profiletargetcombo.active].free_space 
					TileHelpers.error_dialog(@tl.get_translation("error_space"))
					extlayers.each { |k,v| v.hide_all }
					extlayers["rescueprofile"].show_all
				else 
					# TileHelpers.error_dialog("ERROR: No size check yet!")
					extlayers.each { |k,v| v.hide_all }
					copy_profiles 
					extlayers["rescueprofilefinish"].show_all
				end
				# extlayers["rescueprofilefinished"].show_all
			end
		}
		return selfixed
	end
	
	def copy_profiles
		TileHelpers.set_lock 
		puts @profiletargetlist[@profiletargetcombo.active].device 
		@profiletargetlist[@profiletargetcombo.active].mount("rw")
		if @profiletargetlist[@profiletargetcombo.active].mount_point.nil?
			TileHelpers.remove_lock 
			return false
		end
		sourcecount = 0
		@profilesources.each { |p|
			if @profilechecks[sourcecount].active? 
				if p[0].fs =~ /bitlocker/ 
					success = false
					password = nil
					ident, prot, desc = p[0].bitlocker_storage
					unless @bdpass[ident].nil? 
						p[0].mount("ro", "/media/disk/#{p[0].device}", 1000, 1000, nil, @bdpass[ident])
					end
				else
					p[0].mount
				end
				if File.directory?(@profiletargetlist[@profiletargetcombo.active].mount_point[0] + "/Schnellsicherung") && Dir.entries(@profiletargetlist[@profiletargetcombo.active].mount_point[0] + "/Schnellsicherung").include?(File.basename(p[1]))
					# TileHelpers.error_dialog("ERROR: Target contains directory #{File.basename(p[1])} - Move first!")
					n = 0
					while Dir.entries(@profiletargetlist[@profiletargetcombo.active].mount_point[0] + "/Schnellsicherung").include?(File.basename(p[1]) + "." + n.to_s )
						n += 1
					end
					FileUtils.mv(@profiletargetlist[@profiletargetcombo.active].mount_point[0] + "/Schnellsicherung/" + File.basename(p[1]), @profiletargetlist[@profiletargetcombo.active].mount_point[0] + "/Schnellsicherung/" + File.basename(p[1]) + "." + n.to_s)
				end
				# FIXME: Check size
				dwin = Gtk::Window.new
				dwin.set_default_size(400, 40)
				pgbar = Gtk::ProgressBar.new
				pgbar.width_request = 300
				dwin.add(pgbar)
				dwin.deletable = false
				dwin.title = @tl.get_translation("be_patient") 
				dwin.show_all
				TileHelpers.progress(pgbar, [ "rsync", "-avHP", "#{p[0].mount_point[0]}/#{p[1]}", "#{@profiletargetlist[@profiletargetcombo.active].mount_point[0]}/Schnellsicherung/" ]  , "Sichere Profil")
				# system("rsync -avHP \"#{p[0].mount_point[0]}/#{p[1]}\" \"#{@profiletargetlist[@profiletargetcombo.active].mount_point[0]}/Schnellsicherung/\" ")
				dwin.destroy 
				p[0].umount
				p[0].force_umount 
			end
			sourcecount += 1
		}
		@profiletargetlist[@profiletargetcombo.active].umount
		@profiletargetlist[@profiletargetcombo.active].force_umount
		TileHelpers.remove_lock
	end
	
	def get_profile_finish_layer(extlayers)
		finfixed =  Gtk::Fixed.new
		finbodytext = TileHelpers.create_label("<b>" + @tl.get_translation("profiledonehead") + "</b>\n\n" + @tl.get_translation("profiledonebody") , 510)
		fintile = Gtk::Image.new("rescuegreen.png")
		# finfixed.put(fintile, 0, 0)
		finfixed.put(finbodytext, 0, 0)
		TileHelpers.place_back(finfixed, extlayers)
		return finfixed 
		
	end
	
	def fill_profile_layer()
		TileHelpers.set_lock 
		profpartlist = Hash.new
		dwin = Gtk::Window.new
		dwin.set_default_size(400, 40)
		pgbar = Gtk::ProgressBar.new
		pgbar.width_request = 300
		dwin.add(pgbar)
		dwin.deletable = false
		dwin.title = @tl.get_translation("be_patient") 
		dwin.show_all
		@profilechecks.each { |n| @profiletable.remove(n) }
		@profilelabels.each { |n| @profiletable.remove(n) }
		@profilechecks = Array.new
		@profilelabels = Array.new 
		@profilesources = Array.new 
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		drives.each { |d|
			d.partitions.each { |p|
				if p.fs =~ /bitlocker/
					success = false
					password = nil
					ident, prot, desc = p.bitlocker_storage
					templ = @tl.get_translation("bitlockerpassword2")
					templ = @tl.get_translation("bitlockerpassword1") if prot.to_s =~ /reco/i
					# IDENT (Partition DEVICE, Größe SIZE, Beschreibung: DESCRIPTION)
					success, password = TileHelpers.password_dialog( templ.gsub("IDENT", ident.to_s).gsub("DEVICE", p.device).gsub("SIZE", p.human_size).gsub("DESCRIPTION", desc.to_s), "http://go.microsoft.com/fwlink/p/?LinkId=237614" )
					if success == true && password.length > 0
						p.mount("ro", "/media/disk/#{p.device}", 1000, 1000, nil, password)
						@bdpass[ident] = password 
					end
				else
					p.mount
				end
				if !p.mount_point.nil? && ( p.fs =~ /ntfs/i || p.fs =~ /bitlocker/i ) 
					puts p.mount_point[0]
					TileHelpers.set_lock
					proflist = traverse_for_profiles(p.mount_point[0], p.mount_point[0], pgbar) 
					profpartlist[p] = proflist if proflist.size > 0 
					p.umount
					TileHelpers.remove_lock 
				end
			}
		}
		dwin.destroy 
		profcount = 0
		profpartlist.each { |k,v|
			v.each { |p|
				check = Gtk::CheckButton.new
				check.active = true unless p[0] =~ /^\/Schnellsicherung\// || p[0] =~ /Quickbackup\// 
				@profilechecks.push check
				@profiletable.attach(check, 0, 1, profcount, profcount+1)
				label = TileHelpers.create_label(k.device + " " + p[0] + " (" + (p[1] / 1024).to_s + "MB)"  , 600)
				@profilelabels.push label
				@profiletable.attach(label, 1, 2, profcount, profcount+1)
				@profilesources.push( [ k, p[0], p[1] ] ) 
				profcount += 1 
				@profiletable.n_rows = profcount
			}
		}
		TileHelpers.remove_lock
	end
	
	def traverse_for_profiles(startdir, basedir, pgbar) 
		proflist = Array.new
		Dir.entries(startdir).each { |e|
			# puts "Parsing #{startdir}/#{e}"
			if e == "." || e == ".."
				# puts "Ignore directory #{e}"
			elsif File.symlink? "#{startdir}/#{e}"
				puts "Ignore symlink #{e}"
			elsif File.directory? "#{startdir}/#{e}"
				now = Time.now.to_f
				if now - @lastpulse > 0.2 
					pgbar.text = @tl.get_translation("traversing") + " " + e  
					pgbar.pulse
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					@lastpulse = now
				end
				checks = [ "AppData", "Desktop", "NTUSER.DAT" ]
				es = Dir.entries("#{startdir}/#{e}")
				if checks - es == [ ]
					profsize = ` du -ks "#{startdir}/#{e}" `.strip.split[0].to_i  
					proflist.push( [ "#{startdir}/#{e}".gsub(basedir, "") , profsize ] ) unless e == "Default"
				else
					proflist = proflist + traverse_for_profiles("#{startdir}/#{e}", basedir, pgbar) unless e == "ServiceProfiles"  
				end
			end
		}
		return proflist.uniq 
	end
	
	def fill_profile_targetlist(combobox)
		TileHelpers.set_lock 
		100.downto(0) { |i| 
			begin
				combobox.remove_text(i) 
			rescue
			end
		}
		TileHelpers.umount_all
		drives = Array.new
		partitions = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		drives.reverse.each { |d|
			d.partitions.each  { |p|
				label = "#{d.vendor} #{d.model}"
				if d.usb == true
					label = label + " (USB) "
				else
					label = label + " (SATA/eSATA/IDE/NVME) "
				end
				label = label + "#{p.device} #{p.human_size}"
				label = @tl.get_translation("backup_medium") + " " + label if p.label.to_s == "USBDATA"
				pmnt = p.mount_point
				if ( p.fs =~ /vfat/ || p.fs =~ /ntfs/ || p.fs =~ /ext/ || p.fs =~ /btrfs/ ) && pmnt.nil?
					label = label + " #{p.fs}"
					partitions.push p
					combobox.append_text(label)
				end
			}
		}
		combobox.active = 0
		TileHelpers.remove_lock
		return partitions
	end
	
	def mount_all(writeable_part=nil, vssmount=false, normalmount=true)
		TileHelpers.set_lock 
		begin
			bookmarks = File.new("/home/surfer/.gtk-bookmarks", "w")
		rescue
			bookmarks = File.new("/tmp/.gtk-bookmarks", "w")
		end
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		TileHelpers.umount_all
		drives.each { |d|
			d.partitions.each { |p|
				pmnt = p.mount_point
				if pmnt.nil?
					$stderr.puts "#{p.device} vs. #{writeable_part}" 
					# p.umount 
					if p.device.strip == writeable_part.to_s.strip
						$stderr.puts "Match!"
						system("mkdir -p /cobi/" + @tl.get_translation("backupdir")) 
						p.mount("rw", "/cobi/" + @tl.get_translation("backupdir"), 1000, 1000)
						bookmarks.write("file:///cobi/" + @tl.get_translation("backupdir") + "\n")
					else
						if normalmount == true
							if p.fs =~ /bitlocker/
								success = false
								password = nil
								ident, prot, desc = p.bitlocker_storage
								templ = @tl.get_translation("bitlockerpassword2")
								templ = @tl.get_translation("bitlockerpassword1") if prot.to_s =~ /reco/i
								# IDENT (Partition DEVICE, Größe SIZE, Beschreibung: DESCRIPTION)
								success, password = TileHelpers.password_dialog( templ.gsub("IDENT", ident.to_s).gsub("DEVICE", p.device).gsub("SIZE", p.human_size).gsub("DESCRIPTION", desc.to_s), "http://go.microsoft.com/fwlink/p/?LinkId=237614" )
								if success == true && password.length > 0
									p.mount("ro", "/media/disk/#{p.device}", 1000, 1000, nil, password)
								end
							else
								system("mkdir -p /media/disk/#{p.device}")
								p.mount("ro", "/media/disk/#{p.device}", 1000, 1000)
								bookmarks.write("file:///media/disk/#{p.device}\n")
							end
						end
						if vssmount == true && p.vss? == true
							p.vss_mount_all 
						end
					end
				end
			}
		}
		bookmarks.close
		system("chown 1000:1000 /home/surfer/.gtk-bookmarks")
		TileHelpers.remove_lock
	end
	
	def get_sevensave_source_layer(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("goto7target") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		@sourcecombo.height_request = 32
		@sourcecombo.width_request = 380
		deltext = TileHelpers.create_label(@tl.get_translation("select7source"), 510)
		# @sourcedrives = reread_drivelist(@sourcecombo)
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		@overwritecheck.active = true 
		overwrite_label = Gtk::Label.new
		overwrite_label.set_markup("<span color='white'>" + @tl.get_translation("overwrite7free") + "</span>")
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @sourcedrives.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("no7drivebody"), @tl.get_translation("no7drivehead"))
				else
					@targetdrives = reread_targetparts # (@targetcombo, @sourcedrives[@sourcecombo.active] )
					#if @targetdrives.size < 1
					#	TileHelpers.error_dialog(@tl.get_translation("no7tgtdrivebody"), @tl.get_translation("no7tgtdrivehead"))
					#else	
						extlayers.each { |k,v|v.hide_all }
						extlayers["sevensavetargetlayer"].show_all
					#end
				end
			end
		}
		reread.signal_connect('clicked') { 
			@sourcedrives = reread_drivelist(@sourcecombo)
		}
		# fixed.put(tile, 0, 0)
		fixed.put(@sourcecombo, 0, 124)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 124)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		fixed.put(@overwritecheck, 0, 164)
		fixed.put(overwrite_label, 26, 168)
		return fixed
	end
	
	def reread_drivelist(combobox, ignoredrive=nil, hint=nil)
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
			if hint.nil?
				auxdrives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
			else
				auxdrives.push(MfsDiskDrive.new(l, false)) if l == hint
			end
		}
		auxdrives.each { |d|
			iswin = false
			unless d.mounted
				d.partitions.each { |p|
					iswin = true if p.is_windows 
				}
			end
			drives.push(d) if iswin 
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
	
	def reread_targetparts
		TileHelpers.set_lock 
		TileHelpers.umount_all
		100.downto(0) { |i| 
			begin
				@targetcombo.remove_text(i) 
			rescue
			end
		}
		drives = Array.new
		drivenames = Array.new
		partitions = Array.new
		#if @sourcedrives[@sourcecombo.active].nil?
		#	@extlayers.each { |k,v|v.hide_all }
		#	@extlayers["imagesrcfiles"].show_all
		#	return false
		#end
		srcdisk = @sourcedrives[@sourcecombo.active].device
		minsize = @sourcedrives[@sourcecombo.active].size
		# minsize = calculate_logical_size(@srcdrives[@srcdrivecombo.active]) if @tgtimagetype.active? == false
		puts srcdisk
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				d = MfsDiskDrive.new(l, false)
				unless d.device == srcdisk 
					drives.push d
				end
			end
		}
		drives.reverse.each { |d|
			d.partitions.each  { |p|
				label = "#{d.vendor} #{d.model}"
				if d.usb == true
					label = label + " (USB) "
					label = @tl.get_translation("backup_medium")  + " " + label if p.label.to_s == "USBDATA"  
				else
					label = label + " (SATA/eSATA/IDE/NVME) "
				end
				puts "Checking: #{label}"
				label = label + "#{p.device} #{p.human_size}"
				if ( p.fs =~ /ntfs/ || p.fs =~ /ext/ || p.fs =~ /btrfs/ || p.fs =~ /vfat/i ) && p.mount_point.nil? && p.size > ( minsize * 105 / 100 )
					if  ( minsize * 105 / 100 ) > p.free_space 
						puts "File to large for remaining free space, skipping"
					else
						unless p.mounted 
							label = label + " #{p.fs}"
							partitions.push p
							@targetcombo.append_text(label) 
						end
					end
				else
					puts "Ignore #{label} #{p.fs}"
				end
			}
		}
		@targetcombo.append_text(@tl.get_translation("nosuitabletarget")) if partitions.size <  1
		@targetcombo.sensitive = true
		@targetcombo.sensitive = false if partitions.size <  1
		@targetparts = partitions 
		@targetcombo.active = 0
		TileHelpers.remove_lock
	end
	
	def get_sevensave_target_layer(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("goto7clone") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		@targetcombo.height_request = 32
		@targetcombo.width_request = 380
		deltext = TileHelpers.create_label(@tl.get_translation("select7target"), 510)
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		#reread.signal_connect('clicked') { 
		#	@targetdrives = reread_drivelist(@targetcombo, @sourcedrives[@sourcecombo.active] )
		#}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@killclone = false
				# start imaging
						@targetparts[@targetcombo.active].mount("rw")
						if @targetparts[@targetcombo.active].mount_point.nil?
							TileHelpers.error_dialog(@tl.get_translation("badtempbody"), @tl.get_translation("badtemphead"))
						else
							@rescuepath = @targetparts[@targetcombo.active].mount_point[0] + "/Windows-7-Retter"
							if File.exists?(@rescuepath + "/" + @imagename) 
								if TileHelpers.yes_no_dialog(@tl.get_translation("askdeletebody"), @tl.get_translation("askdeletehead"))
									File.unlink(@rescuepath + "/" + @imagename) 
									run_vdimage(extlayers)
								else
									TileHelpers.umount_all
								end
							else
								run_vdimage(extlayers)
								TileHelpers.success_dialog(@tl.get_translation("clonevirtualsuccess")) if @killclone == false 
								while (Gtk.events_pending?)
									Gtk.main_iteration
								end
								extlayers.each { |k,v|v.hide_all }
								TileHelpers.back_to_group
							end
						end
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
	
	def get_sevensave_progress_layer(extlayers) 
		fixed = Gtk::Fixed.new
		killswitch = TileHelpers.place_back(fixed, extlayers, false)
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		deltext = TileHelpers.create_label(@tl.get_translation("progress7label"), 510)
		@cloneprogress.width_request = 510
		@cloneprogress.height_request = 32
		killswitch.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# Some checks here!
				@killclone = true 
				system("killall -9 VBoxManage")
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@cloneprogress, 0, 108)
		return fixed
	end
	
	def run_vdimage(extlayers)
		TileHelpers.set_lock 
		extlayers.each { |k,v|v.hide_all }
		extlayers["sevensaveprogresslayer"].show_all
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		#@killimaging.sensitive = false
		minsize = @sourcedrives[@sourcecombo.active].size
		device = @sourcedrives[@sourcecombo.active].device
		write_zeroes(@sourcedrives[@sourcecombo.active],  @cloneprogress) if @overwritecheck.active?
		@cloneprogress.text = @tl.get_translation("vdiprogfirst")
		system("mkdir \"#{@rescuepath}\"") 
		vte = Vte::Terminal.new
		vte.set_size(80, 25)  
		running = true
		vte.signal_connect("child_exited") { running = false }
		args = [ "/usr/local/VirtualBox/VBoxManage", "convertfromraw", "/dev/#{device}", "#{@rescuepath}/#{@imagename}", "--format", "vdi" ] # , "--variant", "Split2G" ]
		puts args.join(" + ")
		vte.fork_command( :argv => args )
		cycles = 0 
		@cloneprogress.fraction = 0.0
		fraction = 0.0
		starttime = Time.now.to_i
		timeremaining = -1
		while running == true
			#if cycles % 250 == 0
			#	system("sync")
			#end
			if File.exists?("#{@rescuepath}/#{@imagename}") && cycles % 10  == 0
				fsize = calculate_size("#{@rescuepath}/#{@imagename}")
				puts ( ( fsize.to_f / minsize.to_f ) * 100 ).to_s 
				fraction = fsize.to_f / minsize.to_f 
				timerunning = Time.now.to_i - starttime 
				begin
					ttotal = 1.0 / fraction * timerunning.to_f
					ttemp = ( ttotal.to_i - timerunning ) / 60 
					puts fraction.to_f.to_s
					puts ttemp 
					timeremaining = ttemp if  ( ttemp < timeremaining || timeremaining < 0 ) && fraction > 0.015
					puts ttemp.to_s 
				rescue
				end
				puts "Remaining: " + timeremaining.to_s 
			end
			if fraction < 0.02
				@cloneprogress.pulse
			else
				@cloneprogress.fraction = fraction
				#@cloneprogress.text = "Erstelle Image - 1. Lauf - ca. #{timeremaining.to_s} Minuten verbleibend" 
				@cloneprogress.text = @tl.get_translation("vdiprogminutes").gsub("MINUTES", timeremaining.to_s) 
				# @cloneprogress.text = "Erstelle Image - 1. Lauf - ca. eine Minute verbleibend" if timeremaining == 1 
				@cloneprogress.text = @tl.get_translation("vdiprogone") if timeremaining == 1 
				# @cloneprogress.text = "Erstelle Image - 1. Lauf - weniger als eine Minute verbleibend" if timeremaining < 1 
				@cloneprogress.text = @tl.get_translation("vdiprogzero") if timeremaining < 1 
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
			cycles += 1 
		end
		if @ddkilled == true 
			TileHelpers.remove_lock 
			return  false
		end
		#@killimaging.sensitive = true	
		install_config("#{@rescuepath}/#{@imagename}")
		@cloneprogress.text = @tl.get_translation("vdiprogdone")
		@cloneprogress.fraction = 1.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		system("sync")
		TileHelpers.umount_all
		#@killimaging.sensitive = false
		command_out = vte.get_text_range( 0, 0, 25 , 79, false)
		TileHelpers.remove_lock
		return false if command_out =~ /VERR_/ 
		return true 
	end
	
	def calculate_size(filename)
		return File.size(filename) if File.exists?(filename)
		return 0 
		#truncfile = filename.gsub(/\.ddimage$/, "")
		#filesize = 0 
		#1.upto(999) { |n|
		#	fname = truncfile + "-s" + sprintf("%03d", n) + ".ddimage"
		#	filesize += File.size(fname) if File.exists?(fname) 
		#}
		#return filesize 
	end
	
	# Write zeroes to free space on target - each partition
	def write_zeroes(windrive, pgbar=nil)
		TileHelpers.set_lock 
		# windrive contains the drive
		pgbar.text = @tl.get_translation("zeroingfree") unless pgbar.nil?
		windrive.partitions.each { |p|
			begin
				p.zero_free(pgbar)
			rescue
			end
		}
		pgbar.text = @tl.get_translation("zeroingfree") unless pgbar.nil?
		TileHelpers.remove_lock
	end
	
	def install_config(vdipath)
		uuid = nil
		IO.popen("/usr/local/VirtualBox/VBoxManage showhdinfo '#{vdipath}'") { |l|
			while l.gets
				ltoks = $_.strip.split
				uuid = ltoks[1] if ltoks[0] == "UUID:"
			end
		}
		cfgfile = vdipath.gsub("win7.vdi", "win7.vbox")
		system("cp -v win7.vbox '#{cfgfile}'") 
		system("sed -i 's/UUIDOFVDI/#{uuid}/g' '#{cfgfile}'")
		vmuuid = ` uuidgen `.strip
		system("sed -i 's/UUIDOFVM/#{vmuuid}/g' '#{cfgfile}'")
	end
end

