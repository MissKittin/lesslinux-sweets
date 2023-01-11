#!/usr/bin/ruby
# encoding: utf-8

require 'exifr'
require 'fileutils'
require 'id3tag'

class RescueScreen

	def initialize(layers, fixed)
		@layers = layers
		@fixed = fixed
		@source_combo = nil
		@source_devices = Array.new 
		@target_combo = nil 
		@target_devices = Array.new 
		@vte = nil
		@optboxes = Array.new
		@sortafter = nil
		@pgbar = nil
		@photorec_running = false 
		@killed = false 
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "RescueScreen.xml") 
		@start_label = @tl.get_translation("start_label") 
		create_first_layer 
		create_progress_layer
		create_vte_layer
		create_settings_layer 
	end
	attr_reader :start_label
	
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
	
	def create_first_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		ok = Gtk::Button.new(Gtk::Stock::APPLY)
		set = Gtk::Button.new(Gtk::Stock::PREFERENCES) 
		reread = Gtk::Button.new(@tl.get_translation("reread")) 
		reread.width_request = 200
		reread.height_request = 32
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("rescue_start")) 
		fx.put(infolabel, 250, 100)
		# Source
		source_label = Gtk::Label.new(@tl.get_translation("source") )
		@source_combo = Gtk::ComboBox.new
		@source_combo.width_request = 730
		@source_combo.height_request = 32
		fx.put(@source_combo, 250, 240)
		fx.put(source_label, 250, 208)
		# Target
		target_label = Gtk::Label.new(@tl.get_translation("target") )
		@target_combo = Gtk::ComboBox.new
		@target_combo.width_request = 526
		@target_combo.height_request = 32
		fx.put(@target_combo, 250, 320)
		fx.put(reread, 780, 320)
		fx.put(target_label, 250, 288)
		[ ok, cancel, set ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		cancel.signal_connect("clicked") { 
			#unless kill_recovery
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
			#end
		}
		ok.signal_connect("clicked") { 
			constraints = check_target
			constraints = check_mount if constraints == true
			if constraints == true
				@layers.each { |k,v| v.hide_all }
				@layers["rescue_running"].show_all 
				run_recovery 
				@layers.each { |k,v| v.hide_all }
				@layers["start"].show_all 
			end
		}
		set.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["rescue_settings"].show_all 
		}
		reread.signal_connect("clicked") { reread_drivelist }
		fx.put(ok, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		fx.put(set, SETTINGS_X, SETTINGS_Y)
		@fixed.put(fx, 0, 0)
		@layers["rescue_start"] = fx
	end
	
	def create_progress_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		ok = Gtk::Button.new(Gtk::Stock::OK)
		ok.sensitive = false
		details = Gtk::Button.new(@tl.get_translation("details") )
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("rescue_running"))
		fx.put(infolabel, 250, 100)
		# Progress Bar
		@pgbar = Gtk::ProgressBar.new
		@pgbar.fraction = 0.3 
		@pgbar.width_request = 594
		@pgbar.height_request = 32
		fx.put(@pgbar, 250, 240)
		fx.put(details, 852, 240)
		cancel.signal_connect("clicked") { 
			unless kill_recovery
				@layers.each { |k,v| v.hide_all }
				@layers["start"].show_all 
			end
		}
		details.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["rescue_vte"].show_all 
		}
		[ ok, cancel, details ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		fx.put(ok, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		@fixed.put(fx, 0, 0)
		@layers["rescue_running"] = fx
	end
	
	def reread_drivelist 
		TileHelpers.umount_all
		1000.downto(0) { |n|
			begin
				@target_combo.remove_text(n)
			rescue
			end
			begin
				@source_combo.remove_text(n)
			rescue
			end
		}
		@source_devices = Array.new 
		@target_devices = Array.new 
		drives = Array.new
		partitions = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/
		}
		drives.reverse.each { |d|
			label = "#{d.vendor} #{d.model}"
			if d.usb == true
				label = label + " (USB) "
			else
				label = label + " (SATA/eSATA/IDE) "
			end
			label = label + "#{d.device} #{d.human_size}"
			@source_combo.append_text(label)
			@source_devices.push d
			d.partitions.each  { |p|
				label = "#{d.vendor} #{d.model}"
				if d.usb == true
					label = label + " (USB) "
				else
					label = label + " (SATA/eSATA/IDE) "
				end
				label = label + "#{p.device} #{p.human_size}"
				label = @tl.get_translation("backup_medium") + " " + label if p.label.to_s == "USBDATA"
				pmnt = p.mount_point
				if ( p.fs =~ /vfat/ || p.fs =~ /ntfs/ || p.fs =~ /ext/ || p.fs =~ /btrfs/ ) && pmnt.nil?
					unless p.label.to_s == "LessLinuxBoot" || p.label.to_s == "LessEfiBoot"
						label = label + " #{p.fs}"
						partitions.push p.device
						@target_combo.append_text(label)
						@source_devices.push p
						@source_combo.append_text("    "+ label)
						@target_devices.push p
					end
				end
			}
		}
		@target_combo.active = 0
		@source_combo.active = 0
	end
	
	def create_settings_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		ok = Gtk::Button.new(Gtk::Stock::APPLY)
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("rescue_settings"))
		fx.put(infolabel, 250, 100)
		fvbox = Gtk::VBox.new(false, 6)
		# frame for method
		frames = Array.new
		frames[0] = Gtk::Frame.new(@tl.get_translation("file-types"))
		ftbox = Gtk::VBox.new(false, 6)
		0.upto(5) { |n|
			b = Gtk::CheckButton.new(@tl.get_translation("file-types-" + n.to_s))
			b.active = false
			b.sensitive = false 
			@optboxes.push b
			ftbox.pack_start_defaults b
		}
		b = Gtk::CheckButton.new(@tl.get_translation("file-types-all"))
		b.active = true
		@optboxes.push b
		ftbox.pack_start_defaults b
		b.signal_connect("clicked") {
			if b.active?
				0.upto(5) { |n| @optboxes[n].sensitive = false }
			else
				0.upto(5) { |n| @optboxes[n].sensitive = true }
			end
		}
		frames[0].add ftbox 
		frames[1] = Gtk::Frame.new(@tl.get_translation("search-opts"))
		fobox = Gtk::VBox.new(false, 6)
		@sortafter = Gtk::CheckButton.new(@tl.get_translation("sort-afterwards"))
		@sortafter.active = true 
		fobox.pack_start_defaults @sortafter
		frames[1].add fobox 
		
		# mvbox = Gtk::VBox.new(false, 6)
		# frames[0].add mvbox 
		ok.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["rescue_start"].show_all 
		}
		[ ok ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		frames.each { |f|
			f.width_request = 740
			fvbox.pack_start_defaults(f)
		}
		fx.put(fvbox, 250, 140) 
		fx.put(ok, OK_X, OK_Y)
		@fixed.put(fx, 0, 0)
		@layers["rescue_settings"] = fx
	end
	
	def create_vte_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		ok = Gtk::Button.new(Gtk::Stock::OK)
		ok.sensitive = true
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("rescue_vte"))
		fx.put(infolabel, 250, 100)
		# terminal
		@vte = Vte::Terminal.new
		@vte.set_font("Fixed 12", Vte::TerminalAntiAlias::FORCE_DISABLE)
		@vte.width_request = 730
		@vte.height_request = 330
		fx.put(@vte, 250, 185)
		[ ok ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		ok.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["rescue_running"].show_all 
		}
		fx.put(ok, OK_X, OK_Y)
		@fixed.put(fx, 0, 0)
		@layers["rescue_vte"] = fx
	end
	
	def run_recovery
		@killed = false 
		puts "Source: " + @source_devices[@source_combo.active].device
		puts "Target: " + @target_devices[@target_combo.active].device
		source = @source_devices[@source_combo.active]
		target = @target_devices[@target_combo.active]
		fileopts = ""
		filegroups = [ "office", "image", "video", "audio", "mail", "archive" ]
		active_groups = Array.new
		suffixes = Array.new 
		0.upto(5) { |n|
			active_groups.push(filegroups[n]) if @optboxes[n].active?
		}
		@optboxes[-1].active = true if active_groups.size < 1
		if !@optboxes[-1].active? 
			puts "Reading file"
			File.open("photorec_suffixes.txt").each { |l|
				ltoks = l.split
				suffixes.push ltoks[0].strip if active_groups.include?(ltoks[1]) 
			}
			fileopts = "everything,disable"
			suffixes.each { |s|
				fileopts = fileopts + "," + s + ",enable"
			}
		else
			fileopts = "everything,enable"
		end
		@photorec_running = true
		recupdir = Time.now.strftime("Recovery-%Y%m%d-%H%M%S")
		# Mount recovery partition
		# target.mount("rw")
		FileUtils.mkdir_p(target.mount_point[0] + "/" + recupdir)
		params = [ "photorec", "/d",  target.mount_point[0] + "/" + recupdir + "/recover" , "/cmd", "/dev/#{source.device}",
			"partition_none,fileopt," + fileopts + ",search" ]
		puts params.join(" ") 
		@vte.signal_connect("child_exited") {@photorec_running = false  }
		@vte.fork_command("photorec", params )
		sleepcount = 0
		@pgbar.text = @tl.get_translation("rescuehead") 
		while @photorec_running == true
			@pgbar.pulse
			sleep 0.2
			if sleepcount % 50 == 20
				filecount = 0
				Dir.entries( target.mount_point[0] + "/" + recupdir).each { |d|
					if d =~ /recover/ 
						Dir.entries( target.mount_point[0] + "/" + recupdir + "/" + d).each { |f|
							filecount += 1 if File.file?( target.mount_point[0] + "/" + recupdir + "/" + d + "/" + f)
						}
					end
				}
				@pgbar.text = @tl.get_translation("pgcount").gsub("FILECOUNT", filecount.to_s)  
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleepcount += 1 
		end
		if @sortafter.active? && @killed == false
			sortfiles(target.mount_point[0] + "/" + recupdir) 
		end
		@pgbar.fraction = 1.0
		if @killed == true
			info_dialog(@tl.get_translation("search_cancelled_title"), @tl.get_translation("search_cancelled_text")) 
		else
			info_dialog(@tl.get_translation("search_done_title"), @tl.get_translation("search_done_text")) 
		end
		@killed = false
		target.umount 
	end
	
	def kill_recovery 
		if @photorec_running == true
			if question_dialog(@tl.get_translation("really_kill_title"), @tl.get_translation("really_kill_text"))
				system("killall photorec")
				sleep 1.0
				system("killall -9 photorec")
				@killed = true 
			end
			return true
		else
			return false	
		end
	end
	
	def sortfiles(startfolder)
		traverse_dir(startfolder, startfolder, @pgbar)
	end
	
	def traverse_dir(startdir, basedir, pgbar)
		return true if @killed == true 
		return true if ( startdir == "#{basedir}/asorted" || startdir == "#{basedir}/sortiert" )
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

	def check_target
		puts "Source: " + @source_devices[@source_combo.active].device
		puts "Target: " + @target_devices[@target_combo.active].device
		src = nil
		tgt = nil
		if @source_devices[@source_combo.active].class == MfsDiskDrive
			src = @source_devices[@source_combo.active].device
			tgt = @target_devices[@target_combo.active].parent
		else
			src = @source_devices[@source_combo.active].device
			tgt = @target_devices[@target_combo.active].device
		end
		if src == tgt
			error_dialog(@tl.get_translation("srctgt_nomatch_title"), @tl.get_translation("srctgt_nomatch_text"))
			return false
		end
		return true
	end
	
	def check_mount
		puts "Target: " + @target_devices[@target_combo.active].device
		unless @target_devices[@target_combo.active].mount("rw")
			error_dialog(@tl.get_translation("tgt_mountfail_title"), @tl.get_translation("tgt_mountfail_text"))
			return false
		end
		return true 
	end
	
end











