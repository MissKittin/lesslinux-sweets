#!/usr/bin/ruby
# encoding: utf-8

require 'AviraInfectedFile'
require 'sqlite3'

class VirusScreen

	def initialize(layers, fixed)
		@layers = layers
		@fixed = fixed
		@drive_vbox = Gtk::VBox.new
		@drive_widgets = Array.new
		@partitions = Array.new
		@partition_checkboxes = Array.new 
		@internal_drives = Array.new
		@external_drives = Array.new
		@meth_radio = Array.new 
		@cat_check = Array.new 
		@act_radio = Array.new 
		@det_radio = Array.new 
		@file_count = 0 # all files together
		@file_counts = Array.new # files per partition 
		@pgbar = nil 
		@cancel = nil # Button 
		@cancelled = false 
		@action_locked = false
		@avira_version = nil
		@params = Array.new 
		@logdir = "/var/log/avira" 
		@qparams = Array.new
		@infections = Hash.new
		@return_codes = Hash.new
		@statistics = Hash.new
		@extended_short = [ "dial", "heur-dblext", "adspy", "pck", "phish", "bcd", "joke", "game" ]
		@extended_defaults =  [ true, true, true, true, false, false, false, false ]
		@logdb = nil
		@html_log = nil
		@tstamp = Time.now.to_i
		@hrtime = Time.new.strftime("%Y%m%d-%H%M%S") 
		
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "VirusScreen.xml") 
		@start_label = @tl.get_translation("start_label") 
		@finish_label = nil
		create_first_layer 
		create_progress_layer
		create_settings_layer 
		create_finish_layer 
	end
	attr_reader :start_label , :act_radio, :det_radio

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

	def get_archive_maxsize
		tmpstats=` df -k /tmp | tail -n1 `
		free_tmp_megs = tmpstats.split[3].to_i / 1024
		return 4096 if free_tmp_megs - 100 > 4096
		return free_tmp_megs - 100
	end

	def prepare_logdb
		unless @logdb.nil?
			@logdb.execute("DELETE FROM single_infection")
			return true 
		end
		system("mkdir -p /var/log/avira")
		# @logdb = SQLite3::Database.new(@logdir + "/fulllog.sqlite") unless @logdir.nil?
		@logdb = SQLite3::Database.new("/var/log/avira/fulllog-#{@tstamp.to_s}.sqlite") if File.directory?("/var/log/avira")
		@logdb = SQLite3::Database.new("/tmp/fulllog-#{@tstamp.to_s}.sqlite") unless File.directory?("/var/log/avira")
		begin
			@logdb.execute("CREATE TABLE single_infection " + 
				" (id INTEGER PRIMARY KEY ASC, scantime INTEGER(12), uuid VARCHAR(80), fpath VARCHAR(200), bakup VARCHAR(200), "  + 
				"  infection VARCHAR(120), scancl VARCHAR(120), sha1pre CHAR(40), sha1post CHAR(40), retvalue INT(6), " + 
				" fileout VARCHAR(120), scanout VARCHAR(800), action CHAR(20), retval INTEGER(5) ); ")
		rescue
		end
		# FIXME! Create indices!
	end

	def create_first_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		ok = Gtk::Button.new(Gtk::Stock::APPLY)
		set = Gtk::Button.new(Gtk::Stock::PREFERENCES) 
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("virus_start")) 
		fx.put(infolabel, 250, 100)
		
		# Scrollpane for drive selection
		scrl = Gtk::ScrolledWindow.new 
		scrl.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		scrl.width_request = 742
		scrl.height_request = 250
		fx.put(scrl, 250, 260)
		
		# Table containing drives
		drivetab = Gtk::Table.new(1000,2) 
		# drivecombo = Gtk::ComboBox.new
		scrl.add_with_viewport(@drive_vbox) 
		
		[ ok, cancel, set ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		cancel.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
		}
		ok.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["virus_running"].show_all
			prepare_logdb 
			working, retval = check_avira(@pgbar)
			if working == true
				# Reset variable for kill
				@cancelled = false
				success, message = update_signatures(7200, [], @pgbar)
				if success == false && @cancelled == false 
					# system("wicd-gtk --no-tray &")  
					system("connman-gtk &")  
					error_dialog("ERROR", message)  
					update_signatures(7200, [], @pgbar)  
				end
				parameter_array
				count_files unless @cancelled == true
				run_scan unless @cancelled == true 
			else 
				error_dialog(@tl.get_translation("avira_broken_title"), @tl.get_translation("avira_broken_text"))
				@layers.each { |k,v| v.hide_all }
				@layers["start"].show_all 
			end				
			# dump_html_log 
		}
		set.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["virus_settings"].show_all 
		}
		fx.put(ok, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		fx.put(set, SETTINGS_X, SETTINGS_Y)
		@fixed.put(fx, 0, 0)
		@layers["virus_start"] = fx
	end
	
	def create_progress_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		@cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		ok = Gtk::Button.new(Gtk::Stock::OK)
		ok.sensitive = false
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("virus_running"))
		fx.put(infolabel, 250, 100)
		# Progress Bar
		@pgbar = Gtk::ProgressBar.new
		@pgbar.fraction = 0.3 
		@pgbar.width_request = 730
		@pgbar.height_request = 32
		fx.put(@pgbar, 250, 240)
		@cancel.signal_connect("clicked") { 
			@cancelled = true 
			@cancel.sensitive = false
			unless @action_locked
				system("killall -9 scancl")
				system("killall -9 avupdate")
				@layers.each { |k,v| v.hide_all }
				@layers["start"].show_all
				@cancel.sensitive = true
			end			
		}
		[ ok, @cancel ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		fx.put(ok, OK_X, OK_Y)
		fx.put(@cancel, CANCEL_X, CANCEL_Y)
		@fixed.put(fx, 0, 0)
		@layers["virus_running"] = fx
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
		infolabel.set_markup(@tl.get_translation("virus_settings"))
		fx.put(infolabel, 250, 100)
		fvbox = Gtk::VBox.new(false, 6)
		# frame for method
		frames = Array.new
		frames[0] = Gtk::Frame.new(@tl.get_translation("virus_method"))
		mvbox = Gtk::VBox.new(false, 6)
		@meth_radio[0] = Gtk::RadioButton.new(@tl.get_translation("all-files"))
		@meth_radio[1] = Gtk::RadioButton.new(@meth_radio[0] , @tl.get_translation("avira-decides"))
		@meth_radio[2] = Gtk::RadioButton.new(@meth_radio[0] , @tl.get_translation("bootsectors"))
		@meth_radio.each { |m|
			mvbox.pack_start(m, false, false, 0)
		}
		frames[0].add mvbox 
		# frame for categories
		frames[1] = Gtk::Frame.new(@tl.get_translation("virus_categories"))
		cattab = Gtk::Table.new(4, 2)
		[ "dialer", "hidden", "privacy", "packer", "phishing", "backdoor", "fun", "games" ].each { |n|
			@cat_check.push Gtk::CheckButton.new(@tl.get_translation(n))
		}
		0.upto(@cat_check.size-1) { |n|
			cattab.attach_defaults(@cat_check[n], n%2, n%2+1, n/2, n/2+1)
			@cat_check[n].active = @extended_defaults[n]
		}
		frames[1].add cattab
		# frame for action
		frames[2] = Gtk::Frame.new(@tl.get_translation("virus_action"))
		avbox = Gtk::VBox.new(false, 6)
		@act_radio[0] = Gtk::RadioButton.new(@tl.get_translation("protocol-only"))
		@act_radio[1] = Gtk::RadioButton.new(@act_radio[0], @tl.get_translation("delete"))
		@act_radio[2] = Gtk::RadioButton.new(@act_radio[0], @tl.get_translation("repair"))
		@act_radio[1].sensitive = false
		@act_radio[2].sensitive = false
		@act_radio.each { |m|
			avbox.pack_start(m, false, false, 0)
		}
		detvbox = Gtk::VBox.new(false, 6)
		@det_radio[0] = Gtk::RadioButton.new(@tl.get_translation("tryrename"))
		@det_radio[1] = Gtk::RadioButton.new(@det_radio[0], @tl.get_translation("trydelete"))
		@det_radio[0].sensitive = false
		@det_radio[1].sensitive = false
		@det_radio.each { |m|
			detvbox.pack_start(m, false, false, 0)
		}
		actdet_align = Gtk::Alignment.new(0.1, 0, 0, 0)
		actdet_align.add detvbox
		avbox.pack_start(actdet_align, false, false, 0)
		frames[2].add avbox 
		
		[ frames[0], frames[1] ].each { |f|
			f.width_request = 740
			fvbox.pack_start_defaults(f)
		}
		fx.put(fvbox, 250, 140) 
		
		[ ok ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		ok.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["virus_start"].show_all 
		}
		fx.put(ok, OK_X, OK_Y)
		@fixed.put(fx, 0, 0)
		@layers["virus_settings"] = fx
		
	end
	
	def create_finish_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		# cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		ok = Gtk::Button.new(Gtk::Stock::OK)
		set = Gtk::Button.new(Gtk::Stock::PREFERENCES) 
		set.label = @tl.get_translation("show-logs") 
		fx.put(bgimg, 0, 0)
		# Label
		@finish_label = Gtk::Label.new
		@finish_label.wrap = true
		@finish_label.width_request = 730
		@finish_label.set_markup(@tl.get_translation("virus_done"))
		fx.put(@finish_label, 250, 100)
		
		[ ok, set ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		ok.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
		}
		set.signal_connect("clicked") { 
			if @html_log.nil? 
				system("su surfer -c 'thunar --daemon' &")
				sleep 0.5
				system("su surfer -c 'thunar /var/log/avira' &")
			else
				system("su surfer -c 'firefox file://#{@html_log}' &") 
			end
			# @layers.each { |k,v| v.hide_all }
			# @layers["virus_settings"].show_all 
		}
		fx.put(ok, OK_X, OK_Y)
		fx.put(set, CANCEL_X, CANCEL_Y)
		@fixed.put(fx, 0, 0)
		@layers["virus_finished"] = fx
	end
	
	def reread_drivelist
		drives = Array.new
		@partitions = Array.new
		@internal_drives = Array.new
		@external_drives = Array.new
		@drive_widgets.each { |w|
			@drive_vbox.remove(w) 
		}
		@partition_checkboxes = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/
		}
		drives.each { |d|
			@internal_drives.push d unless d.usb == true
			@external_drives.push d if d.usb == true
			dlabel = "#{d.vendor} #{d.model}"
			if d.usb == true
				dlabel = dlabel + " (USB) "
			else
				dlabel = dlabel + " (SATA/eSATA/IDE) "
			end
			dlabel = dlabel + d.human_size
			dlabel = dlabel + " - " + @tl.get_translation("system_drive") if d.system_drive? 
			l = Gtk::Label.new(dlabel) 
			@drive_vbox.pack_start_defaults(l)
			@drive_widgets.push(l)
			d.partitions.each  { |p|
				label = "#{p.device} #{p.human_size}"
				label = @tl.get_translation("backup_medium") + " " + label if p.label.to_s == "USBDATA"
				pmnt = p.mount_point
				if ( p.fs =~ /vfat/ || p.fs =~ /ntfs/ || p.fs =~ /ext/ || p.fs =~ /btrfs/ ) # && pmnt.nil?
					label = label + " #{p.fs}"
					@partitions.push p
					auxalign = Gtk::Alignment.new(0.02, 0, 0, 0)
					checkbox = Gtk::CheckButton.new(label)
					if pmnt.nil?
						checkbox.active = true if (p.fs =~ /vfat/ || p.fs =~ /ntfs/)
					else
						checkbox.sensitive = false
					end
					auxalign.add checkbox
					@partition_checkboxes.push checkbox 
					@drive_vbox.pack_start_defaults auxalign  
					@drive_widgets.push auxalign
				end
			}
		}
		
	end
	
	def parameter_array
		@params = Array.new
		
		# first frame 
		if @meth_radio[0].active? == 0
			$stderr.puts("scanmethod: allfiles")
			@params.push("--allfiles")
		elsif @meth_radio[1].active? == 1
			$stderr.puts("scanmethod: intelligent")
			@params.push("--smartextensions")
		elsif @meth_radio[2].active? == 2 && @act_radio[2].active?
			$stderr.puts("scanmethod: bootonly")
			@params.push("--fixallboot")
		elsif @meth_radio[2].active?
			$stderr.puts("scanmethod: bootonly")
			@params.push("--allboot")
		end
		
		# second frame "what to do"
		if @act_radio[0].active?
			$stderr.puts("action: protocol only")
			@params.push("--defaultaction=ignore")
		elsif @act_radio[1].active?
			$stderr.puts("action: delete infected")
			@params.push("--defaultaction=delete,delete-archive")
		elsif @act_radio[2].active?
			$stderr.puts("action: repair infected")
			if @det_radio[0].active? 
				$stderr.puts("action: delete if no repair")
				@params.push("--defaultaction=clean,delete,delete-archive")
			else
				$stderr.puts("action: rename if no repair")
				@params.push("--defaultaction=clean,rename")
			end
		end
		extended = Array.new
		0.upto(@cat_check.size - 1) { |i|
			extended.push(@extended_short[i]) if @cat_check[i].active? == true 
		}
		@params.push("--withtype=" + extended.join(',')) if extended.size > 0
		if File.directory? "/var/log/avira"
			@params.push("--log=/var/log/avira/scancl.log")
		else
			@params.push("--log=/dev/null")
		end
		@params.push("--heurlevel=2")
		@params.push("--nolinks")
		@params.push("--showall")
		archmax = get_archive_maxsize
		if archmax > 0 
			@params.push("-z")
			@params.push("--archivemaxsize=" + archmax.to_s + "MB")
		end
		# scan an empty directory if the user chooses to scan only bootsectors
		# this is a weird hack to emulate the behaviour of the old --bootonly
		if @meth_radio[2].active? 
			system("mkdir -p /tmp/.empty")
			@params.push("/tmp/.empty")
		end
		@qparams = @params.collect { |x| "'#{x}'" }  
	end
	
	def count_files
		@file_count = 0
		pgtext = @tl.get_translation("counting_files") # "Analyzing drive DEVICE - NUMBER files found"
		0.upto(@partitions.size - 1) { |n|
			if @cancelled == false && @partition_checkboxes[n].active? == true 
				@action_locked = true
				@partitions[n].mount
				@file_counts[n] =  @partitions[n].count_files(@pgbar, pgtext) 
				@file_count += @file_counts[n]
				@partitions[n].umount 
			else
				@file_counts[n] = 0 
			end
		}
		@pgbar.text = @file_count.to_s + " files found in total" 
		if @cancelled == true 
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all
			@cancel.sensitive = true
		end
		@action_locked = false 
	end
	
	def check_avira(pgbar=nil)
		# return true, 0 unless @avira_version.nil?
		@avira_version = Array.new
		scancl = "ruby generic_wrapper.rb /var/run/scancl.version.ret /AntiVir/scancl --version"
		lastupd = Time.now.to_f
		IO.popen(scancl) { |l|
			while l.gets
				line = $_ 
				unless line.strip == "-TickTock-" 
					@avira_version.push(line)
					puts line
				end
				unless pgbar.nil? || Time.now.to_f - lastupd < 0.1
					lastupd = Time.now.to_f
					pgbar.pulse
					pgbar.text = @tl.get_translation("check-avira") 
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
				end
			end
		}
		retval = File.read("/var/run/scancl.version.ret").strip.to_i
		@avira_version = nil if retval > 1
		return false, retval if @avira_version.nil?
		return true, 0
	end
	
	def update_signatures(interval, parameters=[], pgbar=nil)
		return false, @tl.get_translation("key-missing") unless File.exist?("/AntiVir/hbedv.key")
		return true, nil if File.stat("/AntiVir/hbedv.key").mtime.to_f + interval.to_f > Time.now.to_f 
		lastupd = Time.now.to_f
		now = Time.new.strftime("%Y%m%d-%H%M%S") 
		log = File.new(@logdir + "/" + now + "-avupdate.txt", "w") unless @logdir.nil?
		log = File.new(@logdir + "/" + now + "-avupdate.txt", "w") if @logdir.nil? && @debug == true
		command = "ruby generic_wrapper.rb /var/run/avupdate.ret /AntiVirUpdate/avupdate"
		parameters.each { |p| command = command + " '#{p}'" } 
		IO.popen(command) { |l|
			while l.gets
				line = $_
				unless pgbar.nil? || Time.now.to_f - lastupd < 0.1
					lastupd = Time.now.to_f
					pgbar.pulse
					pgbar.text = @tl.get_translation("sigupdate") 
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
				end
				unless line.strip == "-TickTock-" 
					puts line
					log.write(line) unless @logdir.nil?
				end
			end
		}
		log.close unless @logdir.nil?
		retval = -1
		begin
			retval = File.read("/var/run/avupdate.ret").strip.to_i
		rescue
		end
		puts "avupdate returned: " + retval.to_s
		unless pgbar.nil?
			pgbar.text = @tl.get_translation("update-done") 
			pgbar.fraction = 1.0
		end
		if retval == 0
			# touch the key file
			system("touch /AntiVir/hbedv.key")
			return true, nil
		elsif retval == 1
			# no update available - do nothing
			return true, nil
		else
			# Update failed
			return false, @tl.get_translation("update-failed") 
		end
	end
	
	def run_scan 
		
		@tstamp = Time.now.to_i 
		@hrtime = Time.new.strftime("%Y%m%d-%H%M%S") 
		system("touch /var/run/lesslinux/scan_running") 
		failures = Array.new
		pgtext = "Scanning for malware on drive DEVICE"
		virii = 0
		0.upto(@partitions.size - 1) { |n|
			if @cancelled == false && @partition_checkboxes[n].active? == true 
				#if @act_radio[0].active?
				#	@partitions[n].mount
				#else
				#	@partitions[n].mount("rw") 
				#end
				scan_partition(@partitions[n], n+1, @pgbar)
				virii += @infections[@partitions[n]].size 
				# @partitions[n].umount
			end
		}
		if failures.size > 0
			# FIXME: Show error message indicating failed scan!
		end
		if @cancelled == false
			dump_html_log
			if virii > 0
				@finish_label.set_markup(@tl.get_translation("virus_found"))
			else
				@finish_label.set_markup(@tl.get_translation("virus_done"))
			end
			@layers.each { |k,v| v.hide_all }
			@layers["virus_finished"].show_all
		end
	end
	
	def scan_partition(p, pc=0, pgbar=nil, label=nil)
		filect = 0 
		system("touch /var/run/lesslinux/scan_running") 
		if @cancelled == true
			pgbar.text = @tl.get_translation("scan-cancelled") unless pgbar.nil?
			system("rm /var/run/lesslinux/scan_running") 
			return false
		end
		mode = "rw"
		mode = "ro" if @act_radio[0].active?
		if p.class.to_s == "MfsSinglePartition"
			begin
				p.umount
				p.mount(mode)
			rescue
				# FIXME: Mount failed...
				info_dialog(@tl.get_translation("mount-failed"), "Error!")
				return false
			end
		end
		lastfname = nil
		infected = Array.new
		last_pulse = Time.now.to_f
		unless pgbar.nil?
			pgbar.text =  @tl.get_translation("scan-start").gsub("NUM", pc.to_s).gsub("TOTAL",  @partcount.to_s)
			pgbar.fraction = 0.0 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		unless @params[-1] =~/^\// 
			if p.mount_point.nil?
				info_dialog(@tl.get_translation("mount-failed"), "Error!")
				return false
			end
		end
		scancl = "/usr/bin/ruby scancl_wrapper.rb /var/run/scancl.#{p.uuid}.ret /AntiVir/scancl " + @qparams.join(" ") + " "
		scancl = scancl + "'#{p.mount_point[0]}'" unless @params[-1] =~/^\// 
		puts "Running command: " + scancl
		now = Time.new.strftime("%Y%m%d-%H%M%S") 
		log = File.new(@logdir + "/scancl-" + p.device.gsub("/", "_") + "-" + now + ".txt", "w") unless @logdir.nil?
		prefix = Array.new
		prefix_finished = false
		suffix = Array.new
		suffix_started = false
		# file_lines = Array.new
		# alert = false
		last_count_change = Time.now.to_f
		last_count = 0
		last_file = 0
		line_count = 0
		filecmd = ` which file `
		last_six_lines = Array.new
		IO.popen(scancl) { |l|
			while l.gets
				now = Time.now.to_f
				line = nil
				raw = $_
				# Throw away all those lines "TickTock" - generated from the wrapper script
				unless raw.strip == "-TickTock-"
					begin
						puts raw.strip if raw =~ /ä/
						line = raw
					rescue
						line =  raw.encode("UTF-8", "binary", :undef => :replace, :invalid => :replace, :replace => '_') 
						line = line.encode("binary", "UTF-8", :undef => :replace, :invalid => :replace, :replace => '_') 
						puts line.strip
					end
					line_count += 1
				end
				# Increase filecount and log last filename count if line starts with "/"
				# this might be imprecise because archives sometimes appear with more than one line
				# therefore those two variables should just be used for rough statistics
				if !line.nil? && line.strip =~ /^\//
					filect += 1
					lastfname = line.strip
				end
				# Treat all files as prefix until the first line starting with "/" appears
				if !line.nil? && prefix_finished == false
					if line.strip =~ /^\//
						prefix_finished = true
						unless @logdir.nil?
							prefix.each { |l| log.write(l) }
							0.upto(1) { |n| log.write("\n") }
						end
					else
						prefix.push(line)
					end
				end
				
				# Start pushing to suffix as soon as a line starting with Statistics appears
				if !line.nil? && ( line.strip =~ /^Statistics/ || suffix_started == true )
					suffix.push(line)
					suffix_started = true
				end
				
				# Somehow Aviras documentation of scancl is imprecise: The documentation says that
				# every file appears with three lines in the log. However our tests have shown that
				# sometimes it's four lines (nested archives). To properly recognize, we keep a ring
				# buffer of six lines. As soon as the first line in the buffer starts with "/" and
				# the second with "Date" we are sure to have a new file. From the last two or three
				# lines in the buffer we can then judge if the proceeding file has three or four
				# lines.
				#
				# FIXME! Tell Avira to either fix the documentation or the behaviour of the scanner.
				#
				# FIXME! When Avira is run in desinfection mode on a ro mounted filesystem, output
				# will be garbled (missing line break, name of next file in brackets. This is very
				# bad to parse. We currently try to avoid this situation by telling users to unmount 
				# themselves. But this does not work in pure CLI mode.
				
				if !line.nil?
					last_six_lines.push(line)
					last_six_lines.shift if last_six_lines.size > 6
					# Do not do anything if the buffer is not yet ready
					if last_six_lines.size > 5
						# let's check if three lines indicate an infection:
						if last_six_lines[0] =~ /^\// && last_six_lines[1].strip =~ /^date:/i && last_six_lines[2].strip =~ /^ALERT/
							fileout = nil
							fileout = ` file -b '#{last_six_lines[0].strip}' `.strip unless filecmd == ""
							puts "ALERT:  " + last_six_lines[0]
							0.upto(2) { |n| 
								unless @logdir.nil?
									log.write(last_six_lines[n]) 
									log.flush 
								end
							}
							# find out whether something has been done with the file
							act = nil
							slc = nil
							if last_six_lines[5].strip =~ /^date:/i 
								log.write(last_six_lines[3]) unless @logdir.nil?
								act = last_six_lines[3].split[-1].gsub("[", "").gsub("]", "")
								slc = last_six_lines[0..3]
							else
								act = last_six_lines[2].split[-1].gsub("[", "").gsub("]", "")
								slc = last_six_lines[0..2]
							end
							puts "Action taken on file: " + act unless act.nil?
							newinf = AviraInfectedFile.new(last_six_lines[0], p.mount_point[0], p.uuid, last_six_lines[2], @qparams, fileout, @logdb, @tstamp, act, slc)
							infected.push newinf
						end
					end					
				end
				
				# This is just GUI stuff, used to move the progress bar. If Avira keeps scanning one 
				# file for more than two seconds, the progress bar will show the file name and it will
				# pulse.
				
				unless pgbar.nil? || now - last_pulse < 0.1 
					last_pulse = now
					unless p.filecount(pgbar).nil?
						if filect.to_i > 0
							if filect.to_i > last_count
								last_count = filect.to_i
								last_count_change = now
								pgbar.fraction = filect.to_f / p.filecount(pgbar).to_f
								pgtext = @tl.get_translation("scan-progress").gsub("NUM", pc.to_s).gsub("TOTAL",  @partcount.to_s).gsub("FILES", filect.to_s).gsub("PERCENT", (pgbar.fraction * 100.0).to_i.to_s)
								pgtext = pgtext.gsub("PERCENT", (pgbar.fraction * 100.0).to_i.to_s) + " - " + @tl.get_translation("scan-malware-multiple").gsub("NUM", infected.size.to_s) if infected.size > 1
								pgtext = pgtext.gsub("PERCENT", (pgbar.fraction * 100.0).to_i.to_s) + " - " + @tl.get_translation("scan-malware-single") if infected.size == 1
								pgbar.text = pgtext
							elsif now - last_count_change > 2.0
								pgbar.pulse
								chopped_fname = lastfname.to_s.split("/")[-1] 
								pgbar.text = @tl.get_translation("check-file").gsub("FNAME", chopped_fname.to_s)
							end
						else 
							pgbar.pulse
						end
					end
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
				end
			end
		}
		# Flush the saved lines from the suffix:
		log.write("\n\n") unless @logdir.nil?
		@statistics[p] = Array.new
		suffix.each{ |l| 
			log.write(l) unless @logdir.nil?
			@statistics[p].push(l) unless l.strip == ""
		}
		log.close unless @logdir.nil?
		unless pgbar.nil?
			pgbar.text = @tl.get_translation("scan-done").gsub("NUM", pc.to_s).gsub("TOTAL",  @partcount.to_s) 
			pgbar.fraction = 1.0 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		p.umount if p.class.to_s == "MfsSinglePartition"
		@infections[p] = infected
		@return_codes[p] = File.read("/var/run/scancl.#{p.uuid}.ret").strip.to_i 
		puts "Scanning partition: #{p.device} #{p.uuid} terminated with code #{@return_codes[p]} "
		return false if @cancelled == true
	end
	
	def dump_html_log
		return true if @logdb.nil?
		csslines = Array.new
		jslines = Array.new
		File.open("scanlog.css").each { |line| csslines.push(line.strip) unless line.strip == "" }
		File.open("scanlog.js").each { |line| jslines.push(line.strip) unless line.strip == "" } 
		# Read some rquired information
		dmiinfo = Array.new
		IO.popen("dmidecode --type system") { |l|
			while l.gets
				dmiinfo.push($_)
			end
		}
		# Build XML document 
		doc = REXML::Document.new(nil, { :respect_whitespace => %w{ script style } } )
		root = REXML::Element.new "html"
		body = REXML::Element.new "body"
		body.add_attribute("onload", "jsinit();") 
		head = REXML::Element.new "head"
		m1 = REXML::Element.new "meta"
		m1.add_attribute("http-equiv", "Content-Type")
		m1.add_attribute("content", "text/html; charset=UTF-8")
		css = REXML::Element.new "style"
		css.add_attribute("type", "text/css")
		css.add(REXML::Text.new("\n" + csslines.join(" \n ") + "\n", true, nil, true ))
		cs2 = REXML::Element.new "link"
		cs2.add_attribute("rel", "stylesheet")
		cs2.add_attribute("type", "text/css")
		cs2.add_attribute("href", "override.css")
		js = REXML::Element.new "script"
		js.add_attribute("type", "text/javascript")
		js.add(REXML::Text.new("\n" + jslines.join(" \n ") + "\n", true, nil, true ))
		head.add m1
		head.add cs2
		head.add css
		head.add js 
		t = REXML::Element.new "title"
		t.add_text @tl.get_translation("html-title")
		head.add t
		root.add head
		root.add body
		doc.add root
		# Header section with general information
		allhead = REXML::Element.new "h1"
		allhead.add_text @tl.get_translation("html-title")
		warndiv = REXML::Element.new "div"
		warndiv.add_attribute("class", "warndiv")
		warntxt = @tl.get_translation("html-warn") 
		warndiv.add_text warntxt
		genhead = REXML::Element.new "h2"
		genhead.add_text @tl.get_translation("html-common") 
		body.add allhead
		body.add warndiv
		body.add genhead
		pgen = REXML::Element.new "p"
		pgen.add_attribute("class", "pgen")
		pgen.add_text @tl.get_translation("html-date") + ": " + Time.now.to_s 
		pgen.add REXML::Element.new "br"
		pgen.add_text @tl.get_translation("html-param") + " "  + @params.join(" ")
		body.add pgen
		# div boxes "Computer" and "Avira"
		divgen = REXML::Element.new "div"
		agen = REXML::Element.new "a" 
		agen.add_text @tl.get_translation("html-comp-view") 
		agen.add_attribute("href", "#divgen")
		agen.add_attribute("id", "showcomp")
		age2 = REXML::Element.new "a" 
		age2.add_text @tl.get_translation("html-comp-hide") 
		age2.add_attribute("href", "#divgen")
		age2.add_attribute("id", "hidecomp")
		divgen.add agen
		# divgen.add REXML::Element.new "br"
		divgen.add age2
		dmipre = REXML::Element.new "pre"
		dmipre.add_text dmiinfo.join("")
		dmipre.add_attribute("id", "dmipre")
		divgen.add dmipre
		divavr = REXML::Element.new "div"
		aavr = REXML::Element.new "a" 
		aavr.add_text @tl.get_translation("html-avira-view") 
		aavr.add_attribute("href", "#avrgen")
		aavr.add_attribute("id", "showavira")
		aav2 = REXML::Element.new "a" 
		aav2.add_text @tl.get_translation("html-avira-hide") 
		aav2.add_attribute("href", "#avrgen")
		aav2.add_attribute("id", "hideavira")
		divgen.add aavr
		# divgen.add REXML::Element.new "br"
		divgen.add aav2
		avrpre = REXML::Element.new "pre"
		avrpre.add_text @avira_version.join("")
		avrpre.add_attribute("id", "avrpre")
		divgen.add avrpre
		body.add divgen
		# div box for scanned drives
		divdrv = REXML::Element.new "div"
		divdrv.add_attribute("id", "divdrives")
		divext = REXML::Element.new "div"
		divext.add_attribute("id", "extdrives")
		divext.add_attribute("class", "intextdrives")
		divint = REXML::Element.new "div"
		divint.add_attribute("id", "intdrives")
		divint.add_attribute("class", "intextdrives")
		divspec = REXML::Element.new "div"
		divspec.add_attribute("id", "specialdrives")
		divspec.add_attribute("class", "intextdrives")
		hint = REXML::Element.new "h3"
		hint.add_text @tl.get_translation("html-drives-internal") 
		hext = REXML::Element.new "h3"
		hext.add_text @tl.get_translation("html-drives-external") 
		hspec = REXML::Element.new "h3"
		hspec.add_text @tl.get_translation("html-drives-external") 
		divint.add hint
		divext.add hext
		divspec.add hspec
		divdrv.add divint
		divdrv.add divext
		body.add divdrv
		# General Info for each drive
		int_divs = Hash.new
		ext_divs = Hash.new
		spec_divs = Hash.new
		@internal_drives.each { |d|
			int_divs[d.device] =  REXML::Element.new "div"
			int_divs[d.device].add_attribute("id", "drive-#{d.device}")
			int_divs[d.device].add_attribute("class", "drivebox")
			divint.add int_divs[d.device]
		}
		@external_drives.each { |d|
			ext_divs[d.device] =  REXML::Element.new "div"
			ext_divs[d.device].add_attribute("id", "drive-#{d.device}")
			ext_divs[d.device].add_attribute("class", "drivebox")
			divext.add ext_divs[d.device]
		}	
		( @internal_drives + @external_drives ).each { |d|
			h = REXML::Element.new "h4"
			h.add_text d.vendor + " " + d.model + " - " + d.human_size 
			# Link to fold SMART info
			a = REXML::Element.new "a"
			a.add_text @tl.get_translation("html-smart-view")  
			a.add_attribute("href", "#" + d.device + "-unfold")
			a.add_attribute("id", "showsmart-" + d.device)
			a.add_attribute("class", "showsmart")
			a.add_attribute("onclick", 'showsmart("' + d.device + '");')
			b = REXML::Element.new "a"
			b.add_text @tl.get_translation("html-smart-hide")   
			b.add_attribute("href", "#" + d.device + "-unfold")
			b.add_attribute("id", "hidesmart-" + d.device)
			b.add_attribute("class", "hidesmart")
			b.add_attribute("onclick", 'hidesmart("' + d.device + '");')
			# Smart information
			smart_adiv = REXML::Element.new "div"
			smart_adiv.add_attribute("class", "smartouter")
			smart_adiv.add_attribute("id", "smart-" + d.device)
			smart_idiv = REXML::Element.new "div"
			smart_idiv.add_attribute("class", "smartinfo")
			smart_ediv = REXML::Element.new "div"
			smart_ediv.add_attribute("class", "smarterror")
			smart_ipre = REXML::Element.new "pre"
			smart_epre = REXML::Element.new "pre"
			smart_summ = REXML::Element.new "div"
			smart_summ.add_attribute("class", "smartsummary")
			s, i, e = d.error_log
			smart_ipre.add_text i.join("")
			smart_epre.add_text e.join("")
			smart_idiv.add smart_ipre
			smart_ediv.add smart_epre
			smart_adiv.add a
			# smart_adiv.add REXML::Element.new "br"
			smart_adiv.add b
			smart_link = REXML::Element.new "a"
			smart_link.add_attribute("target", "_blank")
			smart_link.add_attribute("href", @tl.get_translation("html-smart-href"))
			smart_link.add_attribute("title", @tl.get_translation("html-smart-title"))
			smart_link.add_text " S.M.A.R.T. "
			if s == true
				if e.size < 1
					smart_summ.add_text @tl.get_translation("html-smartlog-pre").gsub("DEVICE", d.device)
					smart_summ.add smart_link
					smart_summ.add_text @tl.get_translation("html-smartlog-post").gsub("DEVICE", d.device)
				else
					smart_summ.add_text @tl.get_translation("html-smarterr-pre").gsub("DEVICE", d.device)
					smart_summ.add smart_link
					smart_summ.add_text @tl.get_translation("html-smarterr-post").gsub("DEVICE", d.device)
				end
			else
				smart_summ.add_text @tl.get_translation("html-smartno-pre").gsub("DEVICE", d.device)
				smart_summ.add smart_link
				smart_summ.add_text @tl.get_translation("html-smartno-post").gsub("DEVICE", d.device)
			end
			smart_adiv.add smart_summ
			smart_adiv.add smart_idiv
			smart_adiv.add smart_ediv if e.size > 0
			# Now Partition by partition
			pboxes = Array.new
			d.partitions.each { |p|
				pouterbox = REXML::Element.new "div"
				pinnerbox = REXML::Element.new "div"
				pinnerbox.add_attribute("class", "pinnerbox")
				pshort = REXML::Element.new "div"
				pshort.add_attribute("class", "psummary")
				phead = REXML::Element.new "h5"
				windows, winvers = p.is_windows
				pht = p.device.to_s + ", " + p.fs.to_s + " " + p.label.to_s + " " + p.human_size
				pht = pht + " - " + winvers if windows == true
				pht = pht + " (UUID: #{p.uuid})"
				pht = pht + " - " + @tl.get_translation("html-drive-rescue") if p.system_partition? == true
				err_msg = hr_error_code(p)
				pht += " - " + err_msg unless err_msg.nil? 
				phead.add_text pht
				pouterbox.add phead
				pouterbox.add pshort
				if !@statistics[p].nil? && @statistics[p].size > 0
					divstat = REXML::Element.new "div"
					divstat.add_attribute("class", "statistics")
					pouterbox.add divstat
					prestat = REXML::Element.new "pre"
					prestat.add_text @statistics[p].join("")
					divstat.add prestat
				end
				if @infections[p].nil?
					pshort.add_text @tl.get_translation("html-drive-ignored")
					pouterbox.add_attribute("class", "pouterbox")
				elsif @infections[p].size > 0
					pshort.add_text @tl.get_translation("html-drive-infected")
					# retrieve table with infected files
					pinnerbox.add infected_table(p)
					pouterbox.add pinnerbox
					pouterbox.add_attribute("class", "pouterbox-red")
				else
					pshort.add_text @tl.get_translation("html-drive-ok")
					pouterbox.add_attribute("class", "pouterbox-green")
					pouterbox.add_attribute("class", "pouterbox-red") unless err_msg.nil? 
				end
				
				pboxes.push pouterbox if p.fs =~ /ext/ || p.fs =~ /fat/ || p.fs =~ /ntfs/ || p.fs =~ /btrfs/ 
			}
			if ext_divs.has_key? d.device
				ext_divs[d.device].add h
				ext_divs[d.device].add smart_adiv
				pboxes.each { |pb| ext_divs[d.device].add pb }
			else
				int_divs[d.device].add h
				int_divs[d.device].add smart_adiv
				pboxes.each { |pb| int_divs[d.device].add pb }
			end
		}
		# @logdir @tstamp
		unless @logdir.nil?
			@html_log = @logdir + "/scanlog-" + @hrtime.to_s + ".html"
			outfile = File.new(@html_log, File::CREAT|File::TRUNC|File::RDWR) 
		else
			@html_log = @tl.get_translation("html-proto-dir") + "/" + @tl.get_translation("html-proto-prefix")  + @hrtime.to_s + ".html"
			system("mkdir -p " + @tl.get_translation("html-proto-dir"))
			outfile = File.new( @html_log, File::CREAT|File::TRUNC|File::RDWR)
		end
		doc.write(outfile) # , 4)
		outfile.close
	end
	
	def infected_table(p)
		inftab = REXML::Element.new "table"
		inffirst = REXML::Element.new "tr"
		[ @tl.get_translation("inftable-fpath"), 
			@tl.get_translation("inftable-malware"), 
			@tl.get_translation("inftable-action"), "loglines" ].each { |i|
			td = REXML::Element.new "td"
			td.add_text i
			td.add_attribute("class", "fulllog") if i == "loglines"
			inffirst.add td
		}
		thead = REXML::Element.new "thead"
		thead.add inffirst
		inftab.add thead
		tbody = REXML::Element.new "tbody"
		lct = 0
		@infections[p].each { |i|
			tr = REXML::Element.new "tr"
			fn = REXML::Element.new "td"
			ic = REXML::Element.new "td"
			ac = REXML::Element.new "td"
			fl = REXML::Element.new "td"
			fp = REXML::Element.new "pre"
			il = REXML::Element.new "a"
			il.add_attribute("href", @tl.get_translation("inftable-href") + i.short_infection)
			il.add_attribute("target", "_blank")
			il.add_attribute("title", @tl.get_translation("inftable-link").gsub("VIRUS", i.short_infection))
			fl.add_attribute("class", "fulllog") 
			fn.add_text i.relpath
			ic.add il
			il.add_text i.short_infection
			if i.action_taken == "desinfect" 
				ac.add_text @tl.get_translation("inftable-act-desinf") 
			elsif i.action_taken == "delete" 
				ac.add_text @tl.get_translation("inftable-act-delete") 
			elsif i.action_taken == "truncate" 
				ac.add_text  @tl.get_translation("inftable-act-truncate") 
			elsif i.action_taken == "rename" 
				ac.add_text @tl.get_translation("inftable-act-rename") 
			else
				ac.add_text @tl.get_translation("inftable-act-none") 
			end
			tr.add fn
			tr.add ic
			tr.add ac
			tr.add fl
			fl.add fp
			fp.add_text i.fulllog.join
			tr.add_attribute("class", "oddline") if lct % 2 == 1
			tr.add_attribute("class", "evenline") if lct % 2 == 0
			tbody.add tr			
			lct += 1
		}
		inftab.add tbody
		return inftab 
	end
	
	def hr_error_code(partition)
		code = @return_codes[partition] 
		case code
			when 99999
				return @tl.get_translation("error-99999") # "Virenscan abgebrochen oder gestoppt"
			when 203
				return @tl.get_translation("error-203") #"Abbruch: Ungültiger Programmaufruf"
			when 204
				return @tl.get_translation("error-204") #"Abbruch: Ungültiges Verzeichnis"
			when 205
				return @tl.get_translation("error-205") #"Abbruch: Protokoll konnte nicht erstellt werden"
			when 210
				return @tl.get_translation("error-210") #"Abbruch: Beschädigte Avira-Installation"
			when 211
				return @tl.get_translation("error-211") #"Abbruch: Selbstcheck fehlgeschlagen"
			when 212
				return @tl.get_translation("error-212") #"Abbruch: Virensignaturen konnten nicht gelesen werden"
			when 213
				return @tl.get_translation("error-213") #"Abbruch: Scan-Engine und Signaturen inkompatibel"
			when 214
				return @tl.get_translation("error-214") #"Abbruch: Lizenzdatei ungültig"
			when 215
				return @tl.get_translation("error-215") #"Abbruch: Selbstcheck fehlgeschlagen"
			when 216 
				return @tl.get_translation("error-216") #"Fehler: Datei-Zugriff verweigert"
			when 217
				return @tl.get_translation("error-217") #"Fehler: Ordner-Zugriff verweigert"
			when 219
				return @tl.get_translation("error-219") #"Fehler: Ordner-Zugriff verweigert"
			else
				return nil
		end
	end
	
end


