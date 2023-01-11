#!/usr/bin/ruby
# encoding: utf-8

require 'exifr'
require 'fileutils'
require 'id3tag'

class PhotorecScreen	
	def initialize(extlayers, buttons)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "PhotorecScreen.xml")
		@layers = Array.new
		### Are we in the mode for mobile phones?
		@mobilemode = false
		### Selected source device
		@selectedsource = nil
		### ComboBox for drives 
		@drivecombo = nil
		@drivelist = Array.new
		### ComboBox for targets
		@targetcombo = nil
		@targetdrives = Array.new
		@targetlist = Array.new
		### ComboBox for mobile drives
		@mobilecombo = nil
		@mobilelist = Array.new
		### Filetypes, long and short
		@checkbuttons = Hash.new
		@allchecked = nil
		
		# exported buttons
		@mailbutton = nil
		@firefoxbutton = nil
		@imgmountbutton = nil
		@imgtargetcombo = nil
		@wordbutton = buttons[4]
		@chromebutton = nil
		@filerescbutton = nil
		@partitionbutton = nil
		@mobilerecbutton = nil 
		@licenserecbutton = nil
		@buttons = buttons 
		
		@ftypes = {
			"office" => @tl.get_translation("ftypeoffice"),
			"image" => @tl.get_translation("ftypeimage"),
			"video" => @tl.get_translation("ftypevideo"),
			"audio" => @tl.get_translation("ftypeaudio"),
			"mail" => @tl.get_translation("ftypeemail"),
			"archive" => @tl.get_translation("ftypearchive")
		}
		### Progressbar for PhotoRec
		@photorec_progress = nil
		@photorec_exp = nil
		### VTE for running photorec
		@photorec_vte = Vte::Terminal.new
		@vte_shown = false
		@photorec_running = false
		@photorec_vte.signal_connect('child-exited') { @photorec_running = false }
		# License select stuff
		@licensecombo = Gtk::ComboBox.new
		@licenseparts = Array.new
		@licensedummycount = 0
		
		fixed = Gtk::Fixed.new
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotoftypes") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("photorecgreen.png")
		# reread = Gtk::EventBox.new.add Gtk::Image.new("buttongreen.png")
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		
		@drivecombo = Gtk::ComboBox.new
		# @drivecombo.append_text("Yoyodyne Frobolator 500GB SATA (sda)") 
		# drivecombo.active = 0
		@drivecombo.height_request = 32
		@drivecombo.width_request = 380
		
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("sourcehead") + "</b>\n\n" +@tl.get_translation("sourcebody") , 510)
		
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		# fixed.put(orangetile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 128)
		fixed.put(@drivecombo, 0, 128)
		TileHelpers.place_back(fixed, extlayers)
		extlayers["photorecstart"] = fixed
		@layers[0] = fixed
		#buttons[0].signal_connect('button-release-event') { |x, y|
		#	if y.button == 1 
		#		extlayers.each { |k,v|v.hide_all }
		#		extlayers["DEAD_photorecchooser"].show_all
		#	end
		#}
		#buttons[1].signal_connect('button-release-event') { |x, y|
		#	if y.button == 1 
		#		@mobilelist = reread_drivelist(@mobilecombo, true)
		#		#if @mobilelist.size < 1 
		#		#	TileHelpers.error_dialog("Es wurden keine geeigneten Laufwerke gefunden. Bitte ggf. USB-Laufwerke anschließen und auf \"Neu einlesen\" klicken.", "Keine Laufwerke gefunden")
		#		#else
		#			extlayers.each { |k,v|v.hide_all }
		#			@mobilemode = true
		#			extlayers["mobilerecstart"].show_all
		#		#end
		#	end
		#}
		#buttons[2].signal_connect('button-release-event') { |x, y|
		#	if y.button == 1 
		#		extlayers.each { |k,v|v.hide_all }
		#		extlayers["DEAD_filerescscreen"].show_all
		#	end
		#}
		reread.signal_connect('clicked') {
			@drivelist = reread_drivelist(@drivecombo)
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["photorectypes"].show_all
			end
		}
		
		
		#### Screen for filetypes
		photorectypes = create_ftype_screen(extlayers)
		extlayers["photorectypes"] = photorectypes
		@layers[1] = photorectypes
		
		#### Screen for target
		photorectarget = create_target_screen(extlayers)
		extlayers["photorectarget"] = photorectarget
		@layers[2] = photorectarget
		
		#### Screen for progress
		photorecprog = create_progress_screen(extlayers)
		extlayers["photorecprog"] = photorecprog
		@layers[3] = photorecprog
		
		#### Screen for summary
		photorecsummary = create_summary_screen(extlayers)
		extlayers["photorecsummary"] = photorecsummary
		@layers[4] = photorecsummary
		
		#### Screen for mobile recovery
		mobilerecscreen = create_mobilerec_screen(extlayers)
		extlayers["DEAD_mobilerecstart"] = mobilerecscreen
		@layers[5] = mobilerecscreen
		
		chooserscreen = create_chooser_screen(extlayers, buttons[3] )
		extlayers["DEAD_photorecchooser"] = chooserscreen 
		@layers[6] = chooserscreen
		
		imgtgtscreen = create_img_target_screen(extlayers)
		extlayers["imagetargetscreen"] = imgtgtscreen 
		@layers[7] = imgtgtscreen
		
		imgsrcscreen = create_img_chooser_screen(extlayers)
		extlayers["imagesourcechooser"] = imgsrcscreen 
		@layers[8] = imgsrcscreen
		
		imgfinscreen = create_img_finished_screen(extlayers)
		extlayers["imagefinishscreen"] = imgfinscreen 
		@layers[9] = imgfinscreen
		
		filerescscreen = create_fileresc_screen(extlayers)
		extlayers["DEAD_filerescscreen"] = filerescscreen 
		@layers[10] = filerescscreen
	
		licensescreen = create_license_selectscreen(extlayers)
		extlayers["licensescreen"] = licensescreen 
		@layers[11] = licensescreen 
	
	end
	
	attr_reader :layers, :mailbutton, :firefoxbutton, :wordbutton, :chromebutton
	attr_accessor :drivecombo, :drivelist
	
	def create_fileresc_screen(extlayers)
		
		## First tile, rescue mailboxes
		@mailbutton = Gtk::EventBox.new.add Gtk::Image.new("fileresc_turq.png")
		text3 = Gtk::Label.new
		text3.width_request = 320
		text3.wrap = true
		text3.set_markup("<span foreground='white'><b>" + @tl.get_translation("mailhead") + "</b>\n"+ @tl.get_translation("mailbody") + "</span>")
		
		## Second tile, rescue ff profiles
		@firefoxbutton = Gtk::EventBox.new.add Gtk::Image.new("fileresc_orange.png")
		text4 = Gtk::Label.new
		text4.width_request = 320
		text4.wrap = true
		text4.set_markup("<span foreground='white'><b>" + @tl.get_translation("firefoxhead") + "</b>\n"+ @tl.get_translation("firefoxbody") + "</span>")
		
		## Third tile rescue word file
		# @wordbutton = Gtk::EventBox.new.add Gtk::Image.new("recoverx1.png")
		text2 = Gtk::Label.new
		text2.width_request = 320
		text2.wrap = true
		text2.set_markup("<span foreground='white'><b>" + @tl.get_translation("wordreschead") + "</b>\n"+ @tl.get_translation("wordrescbody") + "</span>")
		
		## Fourth tile rescue chrome
		@chromebutton = Gtk::EventBox.new.add Gtk::Image.new("fileresc_turq.png")
		text1 = Gtk::Label.new
		text1.width_request = 320
		text1.wrap = true
		text1.set_markup("<span foreground='white'><b>" + @tl.get_translation("chromereschead") + "</b>\n"+ @tl.get_translation("chromerescbody") + "</span>")
		
		## Fifth tile rescue files from damaged file system
		# @filerescbutton = Gtk::EventBox.new.add Gtk::Image.new("fileresc_turq.png")
		text5 = Gtk::Label.new
		text5.width_request = 320
		text5.wrap = true
		text5.set_markup("<span foreground='white'><b>" + @tl.get_translation("filereschead") + "</b>\n"+ @tl.get_translation("filerescbody") + "</span>")
		
		## Sixth tile, fifth tile…
		## Rescue license keys
		text6 = Gtk::Label.new
		text6.width_request = 320
		text6.wrap = true
		text6.set_markup("<span foreground='white'><b>" + @tl.get_translation("licensereschead") + "</b>\n"+ @tl.get_translation("licenserescbody") + "</span>")
		@licenserescbutton = Gtk::EventBox.new.add Gtk::Image.new("fileresc_green.png")
		@licenserescbutton.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				reread_license_partitions
				extlayers.each { |k,v|v.hide_all }
				extlayers["licensescreen"].show_all
			end
		}
		fixed = Gtk::Fixed.new
		fixed.put(@mailbutton, 0, 0)
		fixed.put(@firefoxbutton, 0, 140)
		# fixed.put(@wordbutton, 460, 0)
		# fixed.put(@chromebutton, 460, 140)
		# fixed.put(@buttons[5], 460, 140)
		fixed.put(text3, 130, 0)
		fixed.put(text4, 130, 140)
		fixed.put(text2, 590, 0)
		# fixed.put(text1, 590, 140)
		fixed.put(text5, 590, 140)
		## fixed.put(text5, 590, 0)
		
		## Postpone license rescue for version 16
		##fixed.put(text6, 130, 280)
		##fixed.put(@licenserescbutton, 0, 280)
		
		TileHelpers.place_back(fixed, extlayers)
		
		return fixed
	end
	
	
	def create_chooser_screen(extlayers, gpartbutton)
		### First panel, selection of tasks
		# First tile, rescue via photorec
		button1 = Gtk::EventBox.new.add Gtk::Image.new("recoverx1.png")
		text1 = Gtk::Label.new
		text1.width_request = 320
		text1.wrap = true
		text1.set_markup("<span foreground='white'><b>" + @tl.get_translation("photorechead") + "</b>\n" + @tl.get_translation("photorecbody") + "</span>")
	
		# Second tile, rescue from vss
		button2 = Gtk::EventBox.new.add Gtk::Image.new("recoverx2.png")
		text2 = Gtk::Label.new
		text2.width_request = 320
		text2.wrap = true
		text2.set_markup("<span foreground='white'><b>" + @tl.get_translation("vsshead") + "</b>\n"+ @tl.get_translation("vssbody") + "</span>")
		
		### Third tile, rescue partitions
		@partitionbutton = Gtk::EventBox.new.add Gtk::Image.new("recoverx3.png")
		text3 = Gtk::Label.new
		text3.width_request = 320
		text3.wrap = true
		text3.set_markup("<span foreground='white'><b>" + @tl.get_translation("partrecoverhead") + "</b>\n"+ @tl.get_translation("partrecoverbody") + "</span>")
		
		### Fourth tile, rescue files from damaged drives
		@filerescbutton = Gtk::EventBox.new.add Gtk::Image.new("recoverx1.png")
		text4 = Gtk::Label.new
		text4.width_request = 320
		text4.wrap = true
		text4.set_markup("<span foreground='white'><b>" + @tl.get_translation("filereschead") + "</b>\n"+ @tl.get_translation("filerescbody") + "</span>")
		
		# Fifth tile, rescue files from images
		@imgmountbutton = Gtk::EventBox.new.add Gtk::Image.new("recoverx1.png")
		text5 = Gtk::Label.new
		text5.width_request = 320
		text5.wrap = true
		text5.set_markup("<span foreground='white'><b>" + @tl.get_translation("imagemounthead") + "</b>\n"+ @tl.get_translation("imagemountbody") + "</span>")
		
		# Next tile rescue images from digicam
		@mobilerecbutton = Gtk::EventBox.new.add Gtk::Image.new("recoverx1.png")
		text6 = TileHelpers.create_label(@tl.get_translation('undeletephoto'), 320)
		#text6.width_request = 320
		#text6.wrap = true
		#text6.set_markup("<span foreground='white'><b>" + @tl.get_translation("mobilerechead") + "</b>\n"+ @tl.get_translation("mobilerecbody") + "</span>")
		#text6.set_markup("<span foreground='white'><b>Fotos retten</b>\nWurden Bilder von einer Kamera oder einem Handy gelöscht, schließen Sie das Gerät per USB-Kabel an oder legen dessen Speicherkarte ins Lesegerät des Computers. Danach können Sie alle Bilder inklusive gelöschter Dateien auf ein anderes Laufwerk kopieren.</span>")
		
		button1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@drivelist = reread_drivelist(@drivecombo)
				extlayers.each { |k,v|v.hide_all }
				@mobilemode = false
				extlayers["photorecstart"].show_all
			end
		}
		
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v| v.hide_all }
				extlayers["rescuefilemanagervss"].show_all
			end
		}
		
		@imgmountbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v| v.hide_all }
				@targetdrives, @targetlist = reread_targetlist(@imgtargetcombo)
				extlayers["imagetargetscreen"].show_all
			end
		}
		@partitionbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v| v.hide_all }
				# @targetdrives, @targetlist = reread_targetlist(@imgtargetcombo)
				extlayers["winfindpartitions"].show_all
			end
		}
		@mobilerecbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@mobilelist = reread_drivelist(@mobilecombo, true)
				#if @mobilelist.size < 1 
				#	TileHelpers.error_dialog("Es wurden keine geeigneten Laufwerke gefunden. Bitte ggf. USB-Laufwerke anschließen und auf \"Neu einlesen\" klicken.", "Keine Laufwerke gefunden")
				#else
					extlayers.each { |k,v|v.hide_all }
					@mobilemode = true
					extlayers["mobilerecstart"].show_all
				#end
			end
		}
		fixed = Gtk::Fixed.new
		fixed.put(button1, 0, 0)
		fixed.put(button2, 0, 140)
		# fixed.put(gpartbutton, 460, 0)
		# fixed.put(@filerescbutton, 460, 0)
		fixed.put(@imgmountbutton, 460, 140)
		fixed.put(@mobilerecbutton, 0, 280)
		fixed.put(text1, 130, 0)
		fixed.put(text2, 130, 140)
		fixed.put(text5, 590, 140)
		fixed.put(text3, 590, 0)
		fixed.put(text6, 130, 280)
		# fixed.put(text5, 590, 140)
		TileHelpers.place_back(fixed, extlayers)
		
		return fixed
	end
	
	def prepare_photorecstart
		@drivelist = reread_drivelist(@drivecombo)
		@mobilemode = false
	end
	
	def prepare_imagetargetscreen
		@targetdrives, @targetlist = reread_targetlist(@imgtargetcombo)
	end
	
	def create_mobilerec_screen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("mobilerecgreen.png")
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotophotorec") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("sourcehead") + "</b>\n\n" + @tl.get_translation("sourcemobile") , 510)
		@mobilecombo = Gtk::ComboBox.new
		@mobilecombo.height_request = 32
		@mobilecombo.width_request = 380
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		reread.signal_connect("clicked") {
			@mobilelist = reread_drivelist(@mobilecombo, true)
		}
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
			forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @mobilelist.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("nosuitabledrives"), @tl.get_translation("nosuitablehead"))
				else
					@selectedsource = @mobilelist[@mobilecombo.active].device
					@targetdrives, @targetlist = reread_targetlist(@targetcombo)
					if @targetlist.size < 1 
						TileHelpers.error_dialog(@tl.get_translation("nosuitabletarget"), @tl.get_translation("nosuitablehead"))
					else
						extlayers.each { |k,v|v.hide_all }
						extlayers["photorectarget"].show_all
					end
				end
			end
		}
		fixed.put(forw, 853, 282)
		fixed.put(text5, 605, 288)
		fixed.put(orangetile, 0, 0)
		fixed.put(deltext, 130, 0)
		fixed.put(reread, 520, 148)
		fixed.put(@mobilecombo, 130, 148)
		TileHelpers.place_back(fixed, extlayers)
		return fixed
	end
	
	def create_ftype_screen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gototarget") + "</span>")
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("photorecgreen.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("ftypeshead") + "</b>", 510)
		
		deltab = Gtk::Table.new(@ftypes.size + 1, 2)
		ct = 0
		@ftypes.each_key { |t|
			l = Gtk::Label.new
			l.set_markup("<span color='white'>" + @ftypes[t] + "</span>")
			a = Gtk::Alignment.new(0, 0, 0, 0.6)
			a.add l 
			c = Gtk::CheckButton.new
			c.active = true
			@checkbuttons[t] = c
			deltab.attach(a, 1, 2, ct, ct+1)
			deltab.attach(c, 0, 1, ct, ct+1)
			ct += 1
		}
		@allchecked = Gtk::CheckButton.new
		dellab = Gtk::Label.new
		dellab.set_markup("<span color='white'>" + @tl.get_translation("ftypesall") + "</span>")
		delalg = Gtk::Alignment.new(0, 0, 0, 0.6)
		delalg.add dellab
		deltab.attach(@allchecked, 0, 1, ct, ct+1)
		deltab.attach(delalg, 1, 2, ct, ct+1)
		@allchecked.signal_connect("clicked") { 
			if @allchecked.active? 
				@checkbuttons.each { |k,v| 
					v.active = true
					v.sensitive = false
				}
			else
				@checkbuttons.each { |k,v|  v.sensitive = true }
			end
		}
		
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
			forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @drivelist.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("nosuitabledrives"), @tl.get_translation("nosuitablehead"))
				else
					@selectedsource = @drivelist[@drivecombo.active].device
					@targetdrives, @targetlist = reread_targetlist(@targetcombo)
					if @targetlist.size < 1 
						TileHelpers.error_dialog(@tl.get_translation("nosuitabletarget"), @tl.get_translation("nosuitablehead"))
					else
						extlayers.each { |k,v|v.hide_all }
						extlayers["photorectarget"].show_all
					end
				end
			end
		}
		# fixed.put(orangetile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		fixed.put(deltab, 0, 33)
		return fixed
	end
	
	def create_target_screen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("photorecgreen.png")
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotophotorec") + "</span>")
		sortradio = Gtk::CheckButton.new
		sortlabel = TileHelpers.create_label(@tl.get_translation("sortfiles"), 400)
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("targethead") + "</b>\n\n" + @tl.get_translation("targetbody"), 700)
		@targetcombo = Gtk::ComboBox.new
		@targetcombo.height_request = 32
		@targetcombo.width_request = 380
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["photorecprog"].show_all
				run_photorec(sortradio.active?)
				extlayers.each { |k,v|v.hide_all }
				extlayers["photorecsummary"].show_all
			end
		}
		reread.signal_connect('clicked') {
			@targetdrives, @targetlist = reread_targetlist(@targetcombo)
		}
		fixed.put(sortradio, 0, 150)
		fixed.put(sortlabel, 26, 156)
		fixed.put(@targetcombo, 0, 182)
		fixed.put(reread, 390, 182)
		# fixed.put(orangetile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_img_target_screen(extlayers)
		fixed = Gtk::Fixed.new
		backbutton = TileHelpers.place_back(fixed, extlayers)
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("photorecgreen.png")
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("imgtargethead") + "</b>\n\n" + @tl.get_translation("imgtargetbody"), 700)
		@imgtargetcombo = Gtk::ComboBox.new
		@imgtargetcombo.height_request = 32
		@imgtargetcombo.width_request = 570
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @targetlist.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("error_notargetfound") )
				else	
					extlayers.each { |k,v|v.hide_all }
					mount_all(@targetlist[@imgtargetcombo.active].device) 
					extlayers["imagesourcechooser"].show_all
				end
			end
		}
		reread.signal_connect('clicked') {
			@targetdrives, @targetlist = reread_targetlist(@imgtargetcombo)
		}
		fixed.put(@imgtargetcombo, 0, 108)
		fixed.put(reread, 580, 108)
		# fixed.put(orangetile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_img_finished_screen(extlayers)
		fixed = Gtk::Fixed.new
		backbutton = TileHelpers.place_back(fixed, extlayers, false)
		button1 = Gtk::Image.new("photorecgreen.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("imgfinishedhead") + "</b>\n\n" + @tl.get_translation("imgfinishedbody") , 510)
		thbutton = Gtk::Button.new(@tl.get_translation("openfilemanager"))
		thbutton.width_request = 150
		thbutton.height_request = 32
		thbutton.signal_connect('clicked') {
			#system("su surfer -c 'Thunar /media/nbd' &") 
			#system("su surfer -c 'Thunar /cobi/" + @tl.get_translation("backupdir") + "' &") 
			system("Thunar /media/nbd &")
			system("Thunar /cobi/" + @tl.get_translation("backupdir") + " &")
		}
		backbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				system("killall Thunar")
				system("killall -9 Thunar")
				umount_image
				system("sync")
				TileHelpers.umount_all
				TileHelpers.back_to_group
			end
		}
		# fixed.put(button1, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(thbutton, 360, 128)
		return fixed
	end
	
	
	def create_img_chooser_screen(extlayers)
		fixed = Gtk::Fixed.new
		backbutton = TileHelpers.place_back(fixed, extlayers, false)
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("photorecgreen.png")
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("imgsourcehead") + "</b>\n\n" + @tl.get_translation("imgsourcebody"), 700)
		#@imgtargetcombo = Gtk::ComboBox.new
		#@imgtargetcombo.height_request = 32
		#@imgtargetcombo.width_request = 380
		#reread = Gtk::Button.new(@tl.get_translation("reread"))
		#reread.width_request = 120
		#reread.height_request = 32
		chooser = Gtk::FileChooserButton.new("", Gtk::FileChooser::ACTION_OPEN)
		chooser.height_request = 32
		chooser.width_request = 700
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if chooser.filename.nil?
					TileHelpers.error_dialog(@tl.get_translation("error_noimageselected") )
				else
					extlayers.each { |k,v|v.hide_all }
					mount_image(chooser.filename) 
					extlayers["imagefinishscreen"].show_all
					system("Thunar /media/nbd &")
					system("Thunar /cobi/" + @tl.get_translation("backupdir") + " &")
					# system("su surfer -c 'Thunar /media/nbd' &") 
					# system("su surfer -c 'Thunar /cobi/" + @tl.get_translation("backupdir") + "' &") 
				end
			end
		}
		backbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				umount_image
				system("sync")
				TileHelpers.umount_all
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		#reread.signal_connect('clicked') {
		#	@targetdrives, @targetlist = reread_targetlist(@imgtargetcombo)
		#}
		fixed.put(chooser, 0, 108)
		#fixed.put(reread, 520, 182)
		# fixed.put(orangetile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_progress_screen(extlayers)
		fixed = Gtk::Fixed.new
		cancelbutton = TileHelpers.place_back(fixed, extlayers, false)
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("photorecgreen.png")
		@photorec_progress = Gtk::ProgressBar.new
		@photorec_progress.width_request = 510
		@photorec_progress.height_request = 32
		progresstext = TileHelpers.create_label("<b>" + @tl.get_translation("rescuehead") + "</b>\n\n" + @tl.get_translation("rescuebody"), 510)
		@photorec_vte.set_font("fixed 6")
		@photorec_exp = Gtk::Expander.new('')
		@photorec_exp.add @photorec_vte
		@photorec_exp.expanded = false
		@photorec_exp.label_widget = TileHelpers.create_label(@tl.get_translation("details"), 150)
		cancelbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("killall photorec")
				system("killall -9 photorec") 
				TileHelpers.error_dialog(@tl.get_translation("cancelledbody"), @tl.get_translation("cancelledhead")) 
			end
		}
		fixed.put(@photorec_progress, 0, 108)
		fixed.put(progresstext, 0, 0)
		# fixed.put(orangetile, 0, 0)
		fixed.put(@photorec_exp, 0, 153)
		
		return fixed
	end
	
	def create_summary_screen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("photorecgreen.png")
		summary = TileHelpers.create_label("<b>" + @tl.get_translation("successhead") + "</b>\n\n"+ @tl.get_translation("successbody") , 510)
		recovery = Gtk::Image.new("recovery.png")
		fixed.put(recovery, 0, 130)
		# fixed.put(orangetile, 0, 0)
		fixed.put(summary, 0, 0)
		return fixed
	end
	
	def reread_drivelist(combobox, usbonly=false, blockdevice=nil)
		TileHelpers.set_lock 
		TileHelpers.umount_all if blockdevice.nil? 
		100.downto(0) { |i| 
			begin
				combobox.remove_text(i) 
			rescue
			end
		}
		drives = Array.new
		auxdrives = Array.new
		if blockdevice.nil?
			Dir.entries("/sys/block").each { |l|
				if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
					d = MfsDiskDrive.new(l, false)
					auxdrives.push(d) unless d.mounted  
				end
			}
		else
			auxdrives.push MfsDiskDrive.new(blockdevice, false)
		end
		if usbonly == true
			auxdrives.each { |d| drives.push d if d.usb == true }  
		else
			drives = auxdrives
		end
		
		drives.each { |d|
			label = "#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
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
	
	def reread_targetlist(combobox)
		TileHelpers.set_lock 
		100.downto(0) { |i| 
			begin
				combobox.remove_text(i) 
			rescue
			end
		}
		drives = Array.new
		partitions = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		drives.reverse.each { |d|
			d.partitions.each  { |p|
				label = label = "#{d.vendor} #{d.model}"
				if d.usb == true
					label = label + " (USB) "
				else
					label = label + " (SATA/eSATA/IDE/NVME) "
				end
				label = label + "#{p.device} #{p.human_size}"
 				pmnt = p.mount_point
				if ( p.fs =~ /vfat/ || p.fs =~ /ntfs/ || p.fs =~ /ext/ || p.fs =~ /btrfs/ ) && ( pmnt.nil? || pmnt[1].include?("rw") )
					unless p.label == "LessLinuxBlob"
						label = label + " #{p.fs}"
						label = @tl.get_translation("backup_medium") + " - " + label if p.label == "USBDATA"
						partitions.push p
						combobox.append_text(label)
					end
				end
			} unless d.device == @selectedsource
		}
		combobox.active = 0
		TileHelpers.remove_lock 
		return drives, partitions
	end
	
	def run_photorec(sortfiles=true)
		TileHelpers.set_lock 
		filegroups = Array.new
		suffixes = Array.new
		@ftypes.each { |k,v|
			puts k + " " + @checkbuttons[k].active?.to_s
			filegroups.push(k) if @checkbuttons[k].active?
		}
		if @mobilemode == false
			source = @drivelist[@drivecombo.active]
		else
			source = @mobilelist[@mobilecombo.active]
			filegroups = [ "video", "image" ] 
		end
		if !@allchecked.active? || @mobilemode 
			puts "Reading file"
			File.open("photorec_suffixes.txt").each { |l|
				ltoks = l.split
				suffixes.push ltoks[0].strip if filegroups.include?(ltoks[1]) 
			}
		end
		target = @targetlist[@targetcombo.active]
		targetdir = "/cobi/photorec"
		tgt_mounted = true unless target.mount_point.nil?
		targetdir = target.mount_point[0] if tgt_mounted == true
		system("mkdir -p #{targetdir}")
		target.mount("rw", targetdir) unless tgt_mounted == true
		#puts "filegroups? " + filegroups.join(", ")
		#puts "source?     " + source.device
		#puts "target?     " + target.device 
		#puts "allchecked? " + @allchecked.active?.to_s 
		#puts "mobilemode? " + @mobilemode.to_s 
		#puts "suffixes?   " + suffixes.join(", ")
		@photorec_running = true
		params = [ "photorec" ]
		recupdir = Time.now.strftime("Recovery-%Y%m%d-%H%M%S")
		fileopts = "everything,disable" 
		suffixes.uniq.each { |p|
			fileopts = fileopts + "," + p + ",enable"
		}
		fileopts = "everything,enable" if @allchecked.active? && @mobilemode == false
		fileopts = "everything,enable" if filegroups.size == 0
		FileUtils::mkdir_p targetdir + "/" + recupdir
		params = [ "photorec", "/d", targetdir + "/" + recupdir + "/rettung" , "/cmd", "/dev/#{source.device}",
			"partition_none,fileopt," + fileopts + ",search" ]
		puts params.join(" ") 
		@photorec_vte.fork_command("photorec", params )
		sleepcount = 0
		@photorec_progress.text = @tl.get_translation("rescuehead") 
		while @photorec_running == true
			@photorec_progress.pulse
			sleep 0.2
			if sleepcount % 50 == 20
				filecount = 0
				Dir.entries(targetdir + "/" + recupdir).each { |d|
					if d =~ /rettung/ 
						Dir.entries(targetdir + "/" + recupdir + "/" + d).each { |f|
							filecount += 1 if File.file?(targetdir + "/" + recupdir + "/" + d + "/" + f)
						}
					end
				}
				@photorec_progress.text = @tl.get_translation("pgcount").gsub("FILECOUNT", filecount.to_s)  
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleepcount += 1 
		end
		# Now sort files if requested
		sortfiles(targetdir + "/" + recupdir) 
		@photorec_progress.text = @tl.get_translation("pgdone")
		df_out = ` df -k #{targetdir} | tail -n1 `
		freespace = df_out.split[3].to_i
		if freespace < 100_000
			@photorec_exp.expanded = true
			TileHelpers.error_dialog(@tl.get_translation("spaceproblem"))
			@photorec_exp.expanded = false
		end
		target.umount unless tgt_mounted == true
		target.force_umount unless tgt_mounted == true
		TileHelpers.remove_lock
	end
	
	def sortfiles(startfolder)
		traverse_dir(startfolder, startfolder, @photorec_progress)
	end
	
	def traverse_dir(startdir, basedir, pgbar)
		return true if startdir == "#{basedir}/sortiert"
		now = Time.now.to_f 
		if now > $lastpulse + 0.3
			pgbar.pulse
			$lastpulse = now
		end
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		Dir.entries(startdir).each { |e|
			puts "Parsing #{startdir}/#{e}"
			if e == "." || e == ".."
				puts "Ignore directory #{e}"
			elsif File.symlink? "#{startdir}/#{e}"
				puts "Ignore symlink #{e}"
			elsif File.directory? "#{startdir}/#{e}" 
				traverse_dir("#{startdir}/#{e}", basedir, pgbar) 
			elsif File.file? "#{startdir}/#{e}"
				rename_file("#{startdir}/#{e}", basedir, pgbar) 
			end
		}
	end

	def rename_file(filepath, basedir, pgbar) 
		now = Time.now.to_f
		if now > $lastpulse + 0.3
			pgbar.pulse
			$lastpulse = now
		end
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		if filepath =~ /\.jpg$/i || filepath =~ /\.jpeg$/i
			img = EXIFR::JPEG.new(filepath)
			# Try to read some exif infos
			if img.exif? && !img.date_time.nil? && img.model.to_s != "" && (img.width + img.height > 1119)
				puts "Renaming #{filepath}"
				begin
					puts img.model
					puts img.width.to_s + " " + img.height.to_s
					puts img.date_time.to_i.to_s
					dest = "#{basedir}" + @tl.get_translation("path_picture") + "/#{img.date_time.year}/#{img.date_time.month}/#{img.model}"
					FileUtils::mkdir_p dest 
					if $actionmove == true
						FileUtils::mv(filepath, "#{dest}/#{img.date_time.year}_#{img.date_time.month}_#{img.date_time.day}_#{File.basename(filepath)}" )
					else
						FileUtils::cp(filepath, "#{dest}/#{img.date_time.year}_#{img.date_time.month}_#{img.date_time.day}_#{File.basename(filepath)}" )
					end
				rescue 
					puts "Broken EXIF tag!"
				end
			end
		elsif filepath =~ /\.xls/i || filepath =~ /\.csv$/i || filepath =~ /\.sxc$/i || filepath =~ /\.xlt$/i   || filepath =~ /\.ods$/i  
			dest = basedir + @tl.get_translation("path_spreadsheet")
			FileUtils::mkdir_p dest 
			if $actionmove == true
				FileUtils::mv(filepath, dest )
			else
				FileUtils::cp(filepath, dest )
			end
		elsif filepath =~ /\.doc/i || filepath =~ /\.rtf$/i || filepath =~ /\.sxw$/i || filepath =~ /\.odt$/i   || filepath =~ /\.ott$/i  
			dest = basedir + @tl.get_translation("path_wordproc")
			FileUtils::mkdir_p dest 
			if $actionmove == true
				FileUtils::mv(filepath, dest )
			else
				FileUtils::cp(filepath, dest )
			end
		elsif filepath =~ /\.ppt/i || filepath =~ /\.odp$/i || filepath =~ /\.otp$/i || filepath =~ /\.odg$/i   || filepath =~ /\.sxi$/i   || filepath =~ /\.pot$/i  
			dest = basedir + @tl.get_translation("path_presentation")
			FileUtils::mkdir_p dest 
			if $actionmove == true
				FileUtils::mv(filepath, dest )
			else
				FileUtils::cp(filepath, dest )
			end
		elsif filepath =~ /\.mp3$/i
			audio = File.open(filepath, "r") 
			tag = ID3Tag.read(audio)
			puts "Renaming #{filepath}"
			artist = tag.artist.to_s.gsub(":", ".").gsub("/", "_")
			artist = "uknown artist" if artist.to_s == ""
			album = tag.album.to_s.gsub(":", ".").gsub("/", "_")
			album = "uknown album" if album.to_s == ""
			begin
				title = tag.title.to_s.gsub(":", ".").gsub("/", "_")
			rescue 
				title = ` uuidgen `
			end
			if title.to_s == ""
				title = "uknown title" 
			end
			begin
				if tag.track_nr.to_i > 0
					title = tag.track_nr.to_i.to_s + " " + title
				end
			rescue
			end
			title = title + " " + File.basename(filepath)
			begin
				if tag.year.to_i > 0
					album = tag.year.to_i.to_s + " " + album
				end
			rescue
			end
			dest = "#{basedir}" + @tl.get_translation("path_mp3") + "/#{artist}/#{album}"
			FileUtils::mkdir_p dest 
			audio.close
			if $actionmove == true
				FileUtils::mv(filepath, "#{dest}/#{title}" )
			else
				FileUtils::cp(filepath, "#{dest}/#{title}" )
			end
		end
	end
	
	def mount_all(writeable_part=nil, vssmount=false, normalmount=true)
		TileHelpers.set_lock 
		bookmarks = File.new("/home/surfer/.gtk-bookmarks", "w")
		bookmarks2 = File.new("/root/.gtk-bookmarks", "w")
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
						bookmarks2.write("file:///cobi/" + @tl.get_translation("backupdir") + "\n")
					else
						if normalmount == true
							system("mkdir -p /media/disk/#{p.device}")
							p.mount("ro", "/media/disk/#{p.device}", 1000, 1000)
							bookmarks.write("file:///media/disk/#{p.device}\n")
							bookmarks2.write("file:///media/disk/#{p.device}\n")
						end
						if vssmount == true && p.vss? == true
							p.vss_mount_all 
						end
					end
				end
			}
		}
		TileHelpers.remove_lock
		bookmarks.close
		bookmarks2.close
		system("chown 1000:1000 /home/surfer/.gtk-bookmarks")
	end
	
	def mount_image(image)
		TileHelpers.set_lock 
		puts "Mounting #{image}" 
		if image =~ /\.iso$/i || image =~ /\.sqs$/i || image =~ /\.squashfs$/i 
			system("losetup -r /dev/loop31 \"#{image}\"")
			system("mkdir -p /media/nbd/iso")
			system("sync")
			system("mount -o ro /dev/loop31 /media/nbd/iso")
		elsif image =~ /\.raw$/i || image =~ /\.ddimage$/i
			system("losetup -r /dev/loop31 \"#{image}\"")
			system("sync")
			system("kpartx -a -s -r /dev/loop31") 
			system("sync")
			sleep 0.5 
			partitions = Array.new 
			Dir.entries("/dev/mapper").each { |d|
				partitions.push(d) if d =~ /^loop31p/ 
			}
			partitions.each { |p|
				fs = ""
				IO.popen("blkid -o udev /dev/mapper/" + p) { |line|
					while line.gets
						ltoks = $_.strip.split('=')
						fs = ltoks[1] if ltoks[0] == "ID_FS_TYPE"
					end
				}
				system("mkdir -p /media/nbd/#{p}")
				sleep 0.5 
				if fs =~ /ntfs/i 
					system("mount -t ntfs-3g -o ro,utf8,uid=1000,gid=1000 /dev/mapper/#{p} /media/nbd/#{p}")
				elsif fs =~ /fat/i	
					system("mount -t vfat -o ro,iocharset=utf8,uid=1000,gid=1000 /dev/mapper/#{p} /media/nbd/#{p}")
				else
					system("mount -o ro /dev/mapper/#{p} /media/nbd/#{p}")
				end
			}
		elsif image =~ /\.wim$/i 
			system("mkdir -p /media/nbd/wim")
			system("wimlib-imagex mount \"#{image}\" /media/nbd/wim")
		else
			system("modprobe nbd")
			system("qemu-nbd -r -c /dev/nbd0 \"#{image}\"")
			system("kpartx -a -s -r /dev/nbd0") 
			partitions = Array.new 
			Dir.entries("/dev/mapper").each { |d|
				partitions.push(d) if d =~ /^nbd0p/ 
			}
			partitions.each { |p|
				fs = ""
				IO.popen("blkid -o udev /dev/mapper/" + p) { |line|
					while line.gets
						ltoks = $_.strip.split('=')
						fs = ltoks[1] if ltoks[0] == "ID_FS_TYPE"
					end
				}
				system("mkdir -p /media/nbd/#{p}")
				if fs =~ /ntfs/i 
					system("mount -t ntfs-3g -o ro,utf8,uid=1000,gid=1000 /dev/mapper/#{p} /media/nbd/#{p}")
				elsif fs =~ /fat/i	
					system("mount -t vfat -o ro,iocharset=utf8,uid=1000,gid=1000 /dev/mapper/#{p} /media/nbd/#{p}")
				else
					system("mount -o ro /dev/mapper/#{p} /media/nbd/#{p}")
				end
			}
		end
		TileHelpers.remove_lock
	end
	
	def umount_image
		0.upto(4) {
			sleep 0.2
			system("sync")
			system("umount -f /media/nbd/wim")
			system("umount -f /media/nbd/iso")
			system("rmdir /media/nbd/wim")
			system("rmdir /media/nbd/iso")
			Dir.entries("/dev/mapper").each { |d|
				if d =~ /^nbd0p/  || d =~ /^loop31p/ 
					system("umount /media/nbd/#{d}")
					system("rmdir /media/nbd/#{d}")
				end
			}
			system("kpartx -d /dev/loop31")
			system("kpartx -d /dev/nbd0")
			system("losetup -d /dev/loop31")
			system("qemu-nbd -d /dev/nbd0")
		}
	end
	
	def create_license_selectscreen(extlayers)
		fixed = Gtk::Fixed.new
		backbutton = TileHelpers.place_back(fixed, extlayers, false)
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("photorecgreen.png")
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("licensesourcehead") + "</b>\n\n" + @tl.get_translation("licensesourcebody"), 510)
		@licensecombo.width_request = 510
		@licensecombo.height_request = 32
		
		forw.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				outfile = File.new("/tmp/license.txt", "w")
				outfile.write("Windows-Produktschluessel:\n\n")
				outfile.write("    ABCDE-12345-FGHIJ-67890-KLMNO\n\n")
				outfile.write("Office-Produktschluessel (12.0)\n\n")
				outfile.write("   FGHIJ-67890-KLMNO-12345-ABCDE\n")
				outfile.close
				if @licensedummycount % 2 < 1
					TileHelpers.success_dialog("Nachfolgend sehen Sie die gefundenen Lizenzschlüssel für Windows und Office. Sie können die Codes abtippen, abfotografieren oder als Textdatei auf einem angeschlossenen USB-Laufwerk sichern. Falls kein Laufwerk angeschlossen ist, lassen Sie das Fenster mit den Schlüsseln geöffnet und wechseln Sie in den Expertenmodus", "Lizenzschlüssel sichern")
					system("su surfer -c \"scite /tmp/license.txt\" &") 
				else
					TileHelpers.error_dialog("Es konnten auf der ausgewählten Windows-Partition keine Lizenzschlüssel gefunden werden!")
				end
				@licensedummycount += 1	
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		
		fixed.put(@licensecombo, 0, 130)
		# fixed.put(orangetile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def reread_license_partitions
		drives = Array.new
		auxdrives = Array.new
		ntparts = Array.new 
		100.downto(0) { |i| 
			begin
				@licensecombo.remove_text(i) 
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
					@licensecombo.append_text label
					p.umount 
				end
			}
		}
		# combobox.append_text("Windows 8.1 auf sdb1 (SATA/eSATA/IDE)") 
		@licensecombo.active = 0 
		@licenseparts = ntparts
	end
end





