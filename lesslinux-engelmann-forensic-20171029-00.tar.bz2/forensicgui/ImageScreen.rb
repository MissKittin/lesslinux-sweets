#!/usr/bin/ruby
# encoding: utf-8

class ImageScreen

	def initialize(layers, fixed)
		@layers = layers
		@fixed = fixed
		@target_button = nil
		@source_combo = nil
		@pgbar = nil 
		@source_devices = Array.new
		
		@drives = Array.new
		@devices = Array.new
		@nicedrives = Array.new
		@image_running = false 
		
		@pid = nil
		@target_dir = nil
		@vte = nil
		@ok = nil 
		@done = nil 
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "ImageScreen.xml") 
		@start_label = @tl.get_translation("start_label") 
		create_first_layer 
		# create_vte_layer
		create_progress_layer
	end
	attr_reader :start_label 
	
	def create_first_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		@ok = Gtk::Button.new(Gtk::Stock::APPLY)
		@ok.sensitive = false 
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("image_start")) 
		fx.put(infolabel, 250, 100)
		
		@source_combo = Gtk::ComboBox.new
		@source_combo.active = 0
		@source_combo.width_request = 526
		@source_combo.height_request = 32
		fx.put(@source_combo, 250, 250)
		
		reread = Gtk::Button.new(@tl.get_translation("reread")) 
		reread.width_request = 200
		reread.height_request = 32
		fx.put(reread, 780, 250)
	
		targetlabel = Gtk::Label.new
		targetlabel.wrap = true
		targetlabel.width_request = 730
		targetlabel.set_markup(@tl.get_translation("image_target")) 
		fx.put(targetlabel, 250, 290)
	
		@target_button = Gtk::Button.new(@tl.get_translation("select_target_dir"))
		@target_button.width_request = 526
		@target_button.height_request = 32
		fx.put(@target_button, 250, 320)
		
		mount_button = Gtk::Button.new(@tl.get_translation("mount_drives"))
		mount_button.width_request = 200
		mount_button.height_request = 32
		fx.put(mount_button, 780, 320)
		
		@target_button.signal_connect("clicked") {
			dialog = Gtk::FileChooserDialog.new(@tl.get_translation("select_target_dir"),
			$mainwindow,
			Gtk::FileChooser::ACTION_SELECT_FOLDER,
			nil,
			[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
			[Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
			if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
				@target_dir = dialog.filename
				@target_button.label = dialog.filename 
				@ok.sensitive = true 
				puts "filename = #{dialog.filename}"
			end
			dialog.destroy
		}

		reread.signal_connect('clicked') { fill_target_combo } 
		mount_button.signal_connect('clicked') { system("mmmm2.sh &")  }
		
		cancel.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
		}
		
		@ok.signal_connect("clicked") { 
			@vte.reset(true, true) 
			disk = @devices[@source_combo.active]
			targetfile = @target_dir + "/" + disk.device + ".ddimage"
			if File.exists?(targetfile) 
				error_dialog(@tl.get_translation("target_exists"), @tl.get_translation("target_exists_long").gsub("FILENAME", targetfile))
			elsif check_size(disk, @target_dir) && check_mounted_source(@source_combo)
				# [  @source_combo, @target_button, reread].each { |w| w.sensitive = false } 
				@layers.each { |k,v| v.hide_all }
				@layers["image_running"].show_all 
				create_image(disk, targetfile, @pgbar, @vte)
				# [  drivecombo, targetbutton, reread].each { |w| w.sensitive = true } 
			end
		}
		
		[ @ok, cancel, ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		fx.put(@ok, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		# fx.put(set, SETTINGS_X, SETTINGS_Y)
		@fixed.put(fx, 0, 0)
		@layers["image_start"] = fx
		
		
	end
		
	def create_progress_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		@done = Gtk::Button.new(Gtk::Stock::OK)
		@done.sensitive = false
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("imaging_running"))
		fx.put(infolabel, 250, 100)
		
		ddrescuelabel =  Gtk::Label.new
		ddrescuelabel.wrap = true
		ddrescuelabel.width_request = 730
		ddrescuelabel.set_markup(@tl.get_translation("ddrescue_details")) 
		fx.put(ddrescuelabel, 250, 240)
		
		@vte = Vte::Terminal.new
		@vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
		@vte.height_request = 150
		@vte.width_request = 730
		fx.put(@vte, 250, 270)
		
		
		# Progress Bar
		@pgbar = Gtk::ProgressBar.new
		@pgbar.fraction = 0.3 
		@pgbar.width_request = 730
		@pgbar.height_request = 32
		fx.put(@pgbar, 250, 440)
	
		cancel.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			system("kill -9 #{@pid.to_s}") unless @pid.nil? 
			@layers["start"].show_all 
		}
		@done.signal_connect('clicked') {
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
		}
		[ @done, cancel ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		fx.put(@done, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		@fixed.put(fx, 0, 0)
		@layers["image_running"] = fx
	end
	
	def fill_target_combo
		@drives = Array.new
		@devices = Array.new
		@nicedrives = Array.new
		activeitem = 0
		199.downto(0) { |n|
			begin
				@source_combo.remove_text(n)
			rescue
			end
		}
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ 
				begin
					d =  MfsDiskDrive.new(l, true)
					@drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		Dir.entries("/sys/block").each { |l|
			if ( l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/ )
				begin 
					d =  MfsDiskDrive.new(l, true)
					@drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		itemcount = 0
		@drives.each{ |d|
			type = "(S)ATA/SCSI" 
			type = "MMC (int/ext)" if d.device =~ /mmcblk/ 
			type = "USB" if d.usb == true
			nicename = @tl.get_translation("disk") + " - #{type} - /dev/#{d.device} - #{d.vendor} #{d.model} (#{d.human_size})"
			@source_combo.append_text(nicename) 
			@devices.push(d)
			@nicedrives.push(nicename)
			itemcount += 1
			d.partitions.each { |p|
				unless p.extended
					p.force_umount
					if p.label.to_s == "USBDATA"
						FileUtils::mkdir_p("/media/backup") 
						p.mount("rw", "/media/backup", 1000, 1000)
					end
					nicename = @tl.get_translation("partition") + " - /dev/#{p.device} (#{p.human_size}) #{p.fs}"
					@source_combo.append_text("\t#{nicename}") 
					@devices.push(p) 
					@nicedrives.push(nicename)
					itemcount += 1
				end
			}
		}
		if itemcount == 0
			@source_combo.append_text("No usable drives found!")
			@source_combo.sensitive = false
			@ok.sensitive = false
		else
			@source_combo.sensitive = true
			@ok.sensitive = true unless @target_dir.nil?
		end
		@source_combo.active = 0
	end
	
	def question_dialog(title, text, default=false)
		dialog = Gtk::Dialog.new(
			title,
			$mainwindow,
			Gtk::Dialog::MODAL,
			[ Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES ],
			[ Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO ]
		)
		if default == true
			dialog.default_response = Gtk::Dialog::RESPONSE_YES
		else
			dialog.default_response = Gtk::Dialog::RESPONSE_NO
		end
		dialog.has_separator = false
		label = Gtk::Label.new
		label.set_markup(text)
		label.wrap = true	
		image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image)
		hbox.pack_start_defaults(label)
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run { |resp|
			case resp
			when Gtk::Dialog::RESPONSE_YES
				dialog.destroy
				return true
			else
				dialog.destroy
				return false
			end
		}
	end

	def error_dialog(title, text) 
		dialog = Gtk::Dialog.new(
			title,
			$mainwindow,
			Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.default_response = Gtk::Dialog::RESPONSE_OK
		dialog.has_separator = false
		label = Gtk::Label.new
		label.set_markup(text)
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image)
		hbox.pack_start_defaults(label)
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run { |resp|
			dialog.destroy
			return true
		}
	end

	def info_dialog(title, text) 
		dialog = Gtk::Dialog.new(
			title,
			$mainwindow,
			Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.default_response = Gtk::Dialog::RESPONSE_OK
		dialog.has_separator = false
		label = Gtk::Label.new
		label.set_markup(text)
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image)
		hbox.pack_start_defaults(label)
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run { |resp|
			dialog.destroy
			return true
		}
	end
	
	def get_free_space(dir)
		free = 0
		IO.popen("df -k #{dir}") { |l|
			while l.gets 
				toks = $_.strip.split
				free = toks[3].to_i * 1024
			end
		}
		return free
	end
	
	def check_size(disk, dir)
		if disk.size > get_free_space(dir)
			return question_dialog(@tl.get_translation("target_too_small"), @tl.get_translation("target_too_small_long"))
		end
		return true 
	end

	def check_mounted_source(combo)
		return true unless @devices[combo.active].mounted
		return question_dialog(@tl.get_translation("source_mounted_title"), @tl.get_translation("source_mounted_text"), false)
	end
	
	def create_image(device, targetfile, pgbar, vte)
		@done.sensitive = false
		running = true
		vte.signal_connect("child_exited") { running = false }
		@pid = vte.fork_command("/bin/bash", [ "/bin/bash", "/usr/share/lesslinux/drivetools/ddrescueimage-wrapper.sh", "/dev/"+ device.device, targetfile, "1"] )
		pgbar.text = @tl.get_translation("conversion_running").gsub("PERCENTAGE", "0")
		n = 0
		while running == true
			if (n % 25 == 0) && File.exists?(targetfile)
				percentage = File.size?(targetfile).to_f / device.size.to_f * 100.0
				pgbar.text = @tl.get_translation("conversion_running").gsub("PERCENTAGE", percentage.to_i.to_s)
			end
			pgbar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
			n += 1
		end
		exitcode = 255
		pgbar.fraction = 1.0
		if File.exists?(targetfile + ".exit") && File.size(targetfile + ".exit") > 0
			exitcode = File.new(targetfile + ".exit").read.to_i
			File.unlink(targetfile + ".exit")
		end
		if exitcode > 0
			pgbar.text = @tl.get_translation("failed_pgbar")
			error_dialog(@tl.get_translation("failed"), @tl.get_translation("failed_long"))
		else
			pgbar.text = @tl.get_translation("pgbar_second_run")
			running = true
			@pid = vte.fork_command("/bin/bash", [ "/bin/bash", "/usr/share/lesslinux/drivetools/ddrescueimage-wrapper.sh", "/dev/"+ device.device, targetfile, "2"] )
			while running == true
				pgbar.pulse
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				sleep 0.2 
			end
			pgbar.text = @tl.get_translation("success_pgbar")
			pgbar.fraction = 1.0
			info_dialog(@tl.get_translation("success"), @tl.get_translation("success_long"))
		end
		@done.sensitive = true 
	end
	
end