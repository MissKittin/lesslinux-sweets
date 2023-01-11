#!/usr/bin/ruby
# encoding: utf-8

class UsbRescueScreen	
	def initialize(extlayers)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@lang = lang
		@tl = MfsTranslator.new(lang, "UsbRescueScreen.xml")
		@extlayers = extlayers
		@layers = Array.new
		# exported button:
		@button = Gtk::EventBox.new.add Gtk::Image.new("systest3.png")
		@suitabledrives = Array.new
		@progress = nil
		@targetcombo = nil
		@vte = nil
		@killed = false
		
		firstlayer = create_first_layer(extlayers)
		extlayers["usbrescuestart"] = firstlayer
		@layers.push firstlayer
		proglayer = create_progress_layer(extlayers)
		extlayers["usbrescueprogress"] = proglayer
		@layers.push proglayer
		
		@button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				fill_target_combo
				@progress.fraction = 0.0 
				extlayers["usbrescuestart"].show_all
			end
		}
		
	end
	attr_reader :layers, :button 
	
	def create_first_layer(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("systestneutral.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("usbreschead") + "</b>\n\n" + @tl.get_translation("usbrescbody"), 510)
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		back = TileHelpers.place_back(fixed, extlayers) #, false)
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		forwtext = Gtk::Label.new
		forwtext.width_request = 250
		forwtext.wrap = true
		targettext = TileHelpers.create_label(@tl.get_translation("selecttarget"), 250)
		forwtext.set_markup("<span color='white'>" + @tl.get_translation("gotonext") + "</span>")
		fixed.put(forw, 650, 352)
		fixed.put(forwtext, 402, 358)
		@targetcombo = Gtk::ComboBox.new
		@targetcombo.width_request = 510
		@targetcombo.height_request = 32
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		fixed.put(targettext, 0, 150)
		fixed.put(@targetcombo, 0, 170)
		fixed.put(reread, 520, 170)
		reread.signal_connect("clicked") {
			fill_target_combo
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@killed = false
				if @suitabledrives.size > 0
					if TileHelpers.yes_no_dialog(@tl.get_translation("reallydoit"))
						# Check for HDD/SSD
						extlayers.each { |k,v|v.hide_all }
						extlayers["usbrescueprogress"].show_all
						delete_drive
						TileHelpers.success_dialog(@tl.get_translation("successfullyformatted")) unless @killed == true 
						extlayers.each { |k,v|v.hide_all }
						TileHelpers.back_to_group
					end
				else
					TileHelpers.error_dialog(@tl.get_translation("nosuitabletargetfound"))
				end
			end
		}
		return fixed
	end
	
	def create_progress_layer(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("systestneutral.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("usbrescproghead") + "</b>\n\n" + @tl.get_translation("usbrescprogbody"), 510)
		back = TileHelpers.place_back(fixed, extlayers, false)
		@progress = Gtk::ProgressBar.new
		@progress.width_request = 510
		@progress.height_request = 32
		@vte = Vte::Terminal.new
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@progress, 0, 150)
		back.signal_connect('button-release-event') {
			if y.button == 1 
				system("killall -9 parted")
				system("killall -9 mkfs.msdos")
				system("killall -9 mkfs.ntfs")
				@killed = true
			end
		}
		return fixed
	end
	
	def fill_target_combo
		@suitabledrives = Array.new
		199.downto(0) { |n|
			begin
				@targetcombo.remove_text(n)
			rescue
			end
		}
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/
				begin
					d =  MfsDiskDrive.new(l, true)
					if d.usb == true && d.mounted == false
						@suitabledrives.push(d) 
						desc = "#{d.device} - #{d.vendor} #{d.model}, #{d.device}, #{d.human_size}"
						@targetcombo.append_text(desc)
					end
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		if @suitabledrives.size > 0 
			# gobutton.sensitive = true 
			@targetcombo.sensitive = true
			# switch_shelllabel(shelllabel, 0, gobutton)
		else
			@targetcombo.append_text(@tl.get_translation("no_suitable_drive_found"))
			@targetcombo.sensitive = false
		end
		@targetcombo.active = 0
	end
	
	def delete_drive
		TileHelpers.set_lock 
		running = false 
		@vte.signal_connect("child_exited") { running = false }
		tgt = @suitabledrives[@targetcombo.active] 
		system("dd if=/dev/zero bs=1M count=3 of=/dev/#{tgt.device}") unless @killed == true 
		system("parted -s /dev/#{tgt.device} mklabel msdos") unless @killed == true 
		system("parted -s /dev/#{tgt.device} mkpart primary fat32 1M 100%") unless @killed == true 
		cmd = [ "mkfs.msdos", "-n", "USBSTICK", "-F", "32", "/dev/#{tgt.device}1" ]
		cmd = [ "mkfs.ntfs", "--fast", "-L", "USBSTICK", "/dev/#{tgt.device}1" ] if tgt.size > 15_000_000_000
		unless @killed == true 
			running = true 
			@vte.fork_command(cmd[0], cmd ) 
		end
		while running == true
			sleep 0.2
			@progress.text = @tl.get_translation("formatting")
			@progress.pulse 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		@progress.text = @tl.get_translation("done")
		@progress.fraction = 1.0
		TileHelpers.remove_lock 
	end
	
end
