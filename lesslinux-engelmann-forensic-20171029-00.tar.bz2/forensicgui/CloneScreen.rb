#!/usr/bin/ruby
# encoding: utf-8

class CloneScreen

	def initialize(layers, fixed)
		@layers = layers
		@fixed = fixed
		@target_combo = nil
		@source_combo = nil
		@pgbar = nil 
		@source_devices = Array.new
		@target_devices = Array.new
		@vte = nil
		@ok = nil 
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "CloneScreen.xml") 
		@start_label = @tl.get_translation("start_label") 
		create_first_layer 
		create_vte_layer
		create_progress_layer
	end
	attr_reader :start_label 


	def create_first_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		@ok = Gtk::Button.new(Gtk::Stock::APPLY)
		set = Gtk::Button.new(Gtk::Stock::PREFERENCES) 
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("clone_start")) 
		fx.put(infolabel, 250, 100)
		
		@source_combo = Gtk::ComboBox.new
		@source_combo.active = 0
		@source_combo.width_request = 350
		@source_combo.height_request = 32
		fx.put(@source_combo, 250, 250)
 
		fwicon = Gtk::Image.new("/usr/share/icons/Faenza/actions/32/forward.png")
		fx.put(fwicon, 610, 250)
 
		@target_combo = Gtk::ComboBox.new
		@target_combo.active = 0
		@target_combo.sensitive = false
		@target_combo.width_request = 330
		@target_combo.height_request = 32
		fx.put(@target_combo, 652, 250)
		
		[ @ok, cancel, set ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		cancel.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
		}
		@ok.signal_connect("clicked") { 
			doit = true
			if @source_devices[@source_combo.active-1].device == @target_devices[@target_combo.active-1].device 
				TileHelpers.error_dialog( @tl.get_translation("source_target_identical"), "Error")
				doit = false
			elsif @source_devices[@source_combo.active-1].size > @target_devices[@target_combo.active-1].size
				doit = TileHelpers.yes_no_dialog( @tl.get_translation("target_smaller_than_source"), "Question")
			end
			if doit == true
				doit = TileHelpers.yes_no_dialog( @tl.get_translation("really_overwrite"), "Question" )
			end
			if doit == true
				@layers.each { |k,v| v.hide_all }
				@vte.reset(true, true) 
				clone_running = true
				start_time = Time.now.to_i.to_f 
				@vte.signal_connect("child_exited") { 
					clone_running = false
				}
				@vte.fork_command("ddrescue", ["ddrescue", "-f", "/dev/" + @source_devices[@source_combo.active-1].device, "/dev/" + @target_devices[@target_combo.active-1].device] )
				@layers["clone_vte"].show_all 
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				@layers.each { |k,v| v.hide_all }
				@layers["clone_running"].show_all 
				while clone_running == true
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					# line with rate
					# puts @vte.get_text_range(2,0,2,79, false)
					# line with general info
					# puts @vte.get_text_range(6,0,6,79, false)
					update_pgbar(Time.now.to_i.to_f - start_time)
					sleep 0.25
				end	
			end
		}
		@source_combo.signal_connect("changed") {
			if @source_combo.active == 0
				@target_combo.sensitive = false
				@ok.sensitive = false
			else
				@target_combo.sensitive = true
				@ok.sensitive = true if @target_combo.active > 0
			end
		}
		@target_combo.signal_connect("changed") {
			if @target_combo.active > 0
				@ok.sensitive = true
			else
				@ok.sensitive = false
			end
		}
		fx.put(@ok, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		# fx.put(set, SETTINGS_X, SETTINGS_Y)
		@fixed.put(fx, 0, 0)
		@layers["clone_start"] = fx
	end
	
	def create_progress_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		ok = Gtk::Button.new(Gtk::Stock::OK)
		details = Gtk::Button.new(@tl.get_translation("details") )
		ok.sensitive = false
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("clone_running"))
		fx.put(infolabel, 250, 100)
		# Progress Bar
		@pgbar = Gtk::ProgressBar.new
		@pgbar.fraction = 0.3 
		@pgbar.width_request = 594
		@pgbar.height_request = 32
		fx.put(@pgbar, 250, 240)
		fx.put(details, 852, 240)
		cancel.signal_connect("clicked") { 
			system("killall -9 ddrescue") 
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
		}
		details.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["clone_vte"].show_all 
		}
		[ ok, cancel, details ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		fx.put(ok, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		@fixed.put(fx, 0, 0)
		@layers["clone_running"] = fx
	end
	
	def update_pgbar(running_time)
		# puts @vte.get_text_range(2,0,2,79, false)
		# line with general info
		# puts @vte.get_text_range(6,0,6,79, false)
		total_size = @source_devices[@source_combo.active-1].size.to_f # bytes
		rate_line = @vte.get_text_range(3,0,3,79, false)
		rate_line =~ /average\srate\:\s*([0-9]*?)\s/ 
		bytes_done = $1.to_f * 1024.0 * running_time  
		# puts bytes_done 
		# puts rate_line 
		fraction = bytes_done / total_size
		if fraction < 0.02
			@pgbar.pulse
		else
			@pgbar.fraction = fraction 
		end
		@pgbar.text = @tl.get_translation("clone_progress_percentage").gsub("%PERCENTAGE%", (fraction*100).to_i.to_s) 
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
		infolabel.set_markup(@tl.get_translation("clone_vte"))
		fx.put(infolabel, 250, 100)
		# terminal
		@vte = Vte::Terminal.new
		@vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
		@vte.width_request = 730
		@vte.height_request = 250
		fx.put(@vte, 250, 250)
		[ ok ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		ok.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["clone_running"].show_all 
		}
		fx.put(ok, OK_X, OK_Y)
		@fixed.put(fx, 0, 0)
		@layers["clone_vte"] = fx
	end
	
	def reread_drivelist 
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
		@target_combo.append_text(@tl.get_translation("please_select_target"))
		@source_combo.append_text(@tl.get_translation("please_select_source"))
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/
		}
		drives.reverse.each { |d|
			label = "#{d.vendor} #{d.model} - #{d.human_size}"
			if d.usb == true
				label = label + " (USB) "
			else
				label = label + " (SATA/eSATA/IDE) "
			end
			unless d.system_drive?
				@target_combo.append_text(label)
				@target_devices.push(d)
			end
		}
		drives.each  { |d|
			label = "#{d.vendor} #{d.model} - #{d.human_size}"
			if d.usb == true
				label = label + " (USB) "
			else
				label = label + " (SATA/eSATA/IDE) "
			end
			@source_combo.append_text(label)
			@source_devices.push(d)
		}
		@target_combo.active = 0
		@source_combo.active = 0
	end
	
	
end
