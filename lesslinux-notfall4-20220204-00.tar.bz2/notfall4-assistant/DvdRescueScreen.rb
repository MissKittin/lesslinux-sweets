#!/usr/bin/ruby
# encoding: utf-8

require 'MfsTranslator.rb'

class DvdRescueScreen	
	def initialize(extlayers, button, rescuescreen)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "DvdRescueScreen.xml")
		@layers = Array.new
		@extlayers = extlayers 
		@killrescue = false
		@killburn = false
		@imageonly = true
		@isopath = "/tmp/"
		@isoname = "NONAME.iso"
		@imagesize = 0 
		@rescuescreen = rescuescreen
		@lang = ENV['LANGUAGE'][0..1]
		@lang = ENV['LANG'][0..1] if @lang.nil?
		@lang = "en" if @lang.nil?
		# @tlfile = "usbinstall.xml"
		# tlfile = "/usr/share/lesslinux/drivetools/usbinstall.xml" if File.exists?("/usr/share/lesslinux/drivetools/usbinstall.xml")
		# @tl = MfsTranslator.new(@lang, @tlfile)
		### ComboBox for target drives
		@resccombo = Gtk::ComboBox.new
		@rescdrives = Array.new
		@targetcombo = Gtk::ComboBox.new
		@targetparts = Array.new
		@burnercombo = Gtk::ComboBox.new
		@burnerdrives = Array.new
		### ProgressBar for running dd
		@rescueprogress = Gtk::ProgressBar.new
		@killdd = Gtk::Button.new("2. Lauf abbrechen") 
		@killdd.signal_connect("clicked") { 
			system("killall -9 ddrescue")
		} 
		@analyzeprogress = Gtk::ProgressBar.new
		@burnprogress = Gtk::ProgressBar.new
		# attach target screen
		drives = create_drive_screen(extlayers)
		extlayers["dvdrescue"] = drives
		@layers.push drives
		# attach analyze screen
		analyzing = create_analyze_screen(extlayers)
		extlayers["dvdanalyze"] = analyzing
		@layers.push analyzing
		# attach choice screen
		choices = create_choice_screen(extlayers)
		extlayers["dvdchoice"] = choices
		@layers.push choices
		# Attach target screen
		target = create_target_screen(extlayers)
		extlayers["dvdtarget"] = target
		@layers.push target
		# Attach progress screen
		pgscreen = create_progress_screen(extlayers)
		extlayers["dvdprogress"] = pgscreen
		@layers.push pgscreen
		# Attach burners screen
		burningscreen = create_burning_screen(extlayers)
		extlayers["dvdburning"] = burningscreen
		@layers.push burningscreen
		# Attach burners screen
		burnersscreen = create_burner_screen(extlayers)
		extlayers["dvdburners"] = burnersscreen
		@layers.push burnersscreen
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				reread_drivelist
				if @rescdrives.size == 1
					extlayers.each { |k,v|v.hide_all }
					extlayers["dvdanalyze"].show_all
					check_source_media(@rescdrives[0])
					extlayers.each { |k,v|v.hide_all }
					if media_is_missing?(@rescdrives[0]) == true 
						TileHelpers.error_dialog(@tl.get_translation("nodvdbody"),@tl.get_translation("nodvdhead"))
						extlayers.each { |k,v|v.hide_all }
						TileHelpers.back_to_group
					else
						if media_is_damaged?(@rescdrives[0]) == true 
							@imageonly = true
							@imagesize = sizes(@rescdrives[@resccombo.active])[1]
							puts @imagesize.to_s 
							reread_targets
							TileHelpers.error_dialog(@tl.get_translation("badtocbody"),@tl.get_translation("badtochead"))
							puts "Create image"
							extlayers.each { |k,v|v.hide_all }
							extlayers["dvdtarget"].show_all
						else
							extlayers.each { |k,v|v.hide_all }
							extlayers["dvdchoice"].show_all
						end
					end
				else
					extlayers.each { |k,v|v.hide_all }
					extlayers["dvdrescue"].show_all
				end
			end
		}
	end
	attr_reader :layers
	
	def prepare_dvdrescue(extlayers)
		reread_drivelist
		if @rescdrives.size == 1
			extlayers.each { |k,v|v.hide_all }
			extlayers["dvdanalyze"].show_all
			check_source_media(@rescdrives[0])
			extlayers.each { |k,v|v.hide_all }
			if media_is_missing?(@rescdrives[0]) == true 
				TileHelpers.error_dialog(@tl.get_translation("nodvdbody"),@tl.get_translation("nodvdhead"))
				extlayers.each { |k,v|v.hide_all }
				return "start"
			else
				if media_is_damaged?(@rescdrives[0]) == true 
					@imageonly = true
					@imagesize = sizes(@rescdrives[@resccombo.active])[1]
					puts @imagesize.to_s 
					reread_targets
					TileHelpers.error_dialog(@tl.get_translation("badtocbody"),@tl.get_translation("badtochead"))
					puts "Create image"
					return "dvdtarget"
				else
					return "dvdchoice"
				end
			end
		else
			return "dvdrescue"
		end
	end
	
	def create_target_screen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gocopy") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("dvdrescuegreen.png")
		@targetcombo.height_request = 32
		@targetcombo.width_request = 380
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("temphead") + "</b>\n\n" + @tl.get_translation("tempbody"), 510)
		reread = Gtk::Button.new(@tl.get_translation("reread") )
		reread.width_request = 120
		reread.height_request = 32
		reread.signal_connect('clicked') { reread_targets }
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @targetparts.size < 1
					TileHelpers.error_dialog(@tl.get_translation("notempbody"),@tl.get_translation("notempbody"))
				else
					@targetparts[@targetcombo.active].mount("rw")
					if @targetparts[@targetcombo.active].mount_point.nil?
						TileHelpers.error_dialog(@tl.get_translation("badtempbody"),@tl.get_translation("badtempbody"))
					else
						@isopath = @targetparts[@targetcombo.active].mount_point[0] 
						extlayers.each { |k,v|v.hide_all }
						extlayers["dvdprogress"].show_all
						update_isoname(@rescdrives[@resccombo.active])
						read_dvd(@rescdrives[@resccombo.active])
						if @imageonly == true
							system("sync") 
							if File.exists?("#{@isopath}/#{@isoname}") && TileHelpers.yes_no_dialog(@tl.get_translation("isosuccbody").gsub("ISONAME", @isoname), @tl.get_translation("isosucchead") )
								extlayers.each { |k,v|v.hide_all }
								extlayers["pleasewait"].show_all
								while (Gtk.events_pending?)
									Gtk.main_iteration
								end
								losetup = "losetup /dev/loop23 #{@isopath}/#{@isoname}"
								puts losetup
								system(losetup)
								@rescuescreen.sourcedrives = @rescuescreen.reread_drivelist(@rescuescreen.sourcecombo, false, "loop23" )
								extlayers.each { |k,v| v.hide_all }
								extlayers["photorectypes"].show_all
							else
								@targetparts[@targetcombo.active].umount 
								extlayers.each { |k,v| v.hide_all }
								TileHelpers.back_to_group
							end
						else
							extlayers.each { |k,v|v.hide_all }
							extlayers["pleasewait"].show_all
							while (Gtk.events_pending?)
								Gtk.main_iteration
							end
							reread_burners
							extlayers.each { |k,v|v.hide_all }
							extlayers["dvdburners"].show_all
						end
					end
				end
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(@targetcombo, 0, 128)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 128)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_drive_screen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("goanalyze") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("dvdrescuegreen.png")
		@resccombo.height_request = 32
		@resccombo.width_request = 380
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("sourcehead") + "</b>\n\n" + @tl.get_translation("sourcebody") , 510)
		reread = Gtk::Button.new(@tl.get_translation("reread") )
		reread.width_request = 120
		reread.height_request = 32
		reread.signal_connect('clicked') { 
			reread.sensitive = false
			reread_drivelist
			reread.sensitive = true
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @rescdrives.size < 1
					TileHelpers.error_dialog(@tl.get_translation("nodrivebody"),@tl.get_translation("nodrivehead") )
				else
					extlayers.each { |k,v| v.hide_all }
					extlayers["dvdanalyze"].show_all
					check_source_media(@rescdrives[@resccombo.active])
					if media_is_missing?(@rescdrives[@resccombo.active]) == true
						TileHelpers.error_dialog(@tl.get_translation("nodvdbody"),@tl.get_translation("nodvdhead"))
						extlayers.each { |k,v| v.hide_all }
						extlayers["dvdrescue"].show_all
					else
						if media_is_damaged?(@rescdrives[@resccombo.active]) == true 
							@imageonly = true
							@imagesize = sizes(@rescdrives[@resccombo.active])[1]
							puts @imagesize.to_s 
							reread_targets
							TileHelpers.error_dialog(@tl.get_translation("badtocbody"),@tl.get_translation("badtochead"))
							puts "Create image"
							extlayers.each { |k,v|v.hide_all }
							extlayers["dvdtarget"].show_all
						else
							extlayers.each { |k,v| v.hide_all }
							extlayers["dvdchoice"].show_all
						end
					end
				end
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(@resccombo, 0, 160)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 160)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_burner_screen(extlayers)
		fixed = Gtk::Fixed.new
		back = TileHelpers.place_back(fixed, extlayers, true)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("goburn") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("dvdrescuegreen.png")
		@burnercombo.height_request = 32
		@burnercombo.width_request = 380
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("burnerhead") + "</b>\n\n" + @tl.get_translation("burnerbody") , 510)
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		reread.signal_connect('clicked') {
			reread.sensitive = false
			reread_burners
			reread.sensitive = true
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @burnerdrives.size < 1
					TileHelpers.error_dialog(@tl.get_translation("noburnerbody"), @tl.get_translation("noburnerhead") )
				else
					extlayers.each { |k,v| v.hide_all }
					extlayers["dvdburning"].show_all
					burn_iso(@burnerdrives[@burnercombo.active]) 
				end
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(@burnercombo, 0, 128)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 128)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def reread_drivelist
		TileHelpers.set_lock 
		@killburn = false
		@killrescue = false
		mounted = Array.new
		nicedrives = Array.new
		@rescdrives = Array.new
		100.downto(0) { |i| 
			begin
				@resccombo.remove_text(i) 
			rescue
			end
		}
		IO.popen("cat /proc/mounts") { |l|
			while l.gets
				mounted.push $_.strip.split[0]
			end
		}
		0.upto(9) { |n|
			if File.exists?("/dev/sr#{n.to_s}") &&  File.stat("/dev/sr#{n.to_s}").blockdev?
				@rescdrives.push "sr#{n.to_s}" unless mounted.include?("/dev/sr#{n.to_s}")
			end
		}
		@rescdrives.each { |r|
			model = File.open("/sys/block/#{r}/device/model", "r").read.strip
			vendor = File.open("/sys/block/#{r}/device/vendor", "r").read.strip
			nicedrives.push("#{vendor} #{model} (#{r})") 
		}	
		nicedrives.each { |n| @resccombo.append_text(n) }
		@resccombo.append_text(@tl.get_translation("nodrivecombo")) if @rescdrives.size < 1 
		@resccombo.active = 0 
		@resccombo.sensitive = false
		@resccombo.sensitive = true if @rescdrives.size > 0
		TileHelpers.remove_lock
	end
	
	def reread_burners
		mounted = Array.new
		nicedrives = Array.new
		@burnerdrives = Array.new
		100.downto(0) { |i| 
			begin
				@burnercombo.remove_text(i) 
			rescue
			end
		}
		IO.popen("cat /proc/mounts") { |l|
			while l.gets
				mounted.push $_.strip.split[0]
			end
		}
		0.upto(9) { |n|
			if File.exists?("/dev/sr#{n.to_s}") &&  File.stat("/dev/sr#{n.to_s}").blockdev?
				@burnerdrives.push "sr#{n.to_s}" unless mounted.include?("/dev/sr#{n.to_s}") || is_burner?("sr#{n.to_s}") == false
			end
		}
		@burnerdrives.each { |r|
			model = File.open("/sys/block/#{r}/device/model", "r").read.strip
			vendor = File.open("/sys/block/#{r}/device/vendor", "r").read.strip
			nicedrives.push("#{vendor} #{model} (#{r})") 
		}
		nicedrives.each { |n| @burnercombo.append_text(n) }
		@burnercombo.append_text(@tl.get_translation("nodrivecombo")) if @burnerdrives.size < 1 
		@burnercombo.active = 0 
		@burnercombo.sensitive = false
		@burnercombo.sensitive = true if @burnerdrives.size > 0
	end
	
	def reread_targets
		TileHelpers.set_lock 
		combobox = @targetcombo
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
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		drives.each { |d|
			d.partitions.each  { |p|
				label = label = "#{d.vendor} #{d.model}"
				if d.usb == true
					label = label + " (USB) "
				else
					label = label + " (SATA/eSATA/IDE/NVME) "
				end
				label = label + "#{p.device} #{p.human_size}"
				if ( p.fs =~ /vfat/ || p.fs =~ /ntfs/ || p.fs =~ /ext/ || p.fs =~ /btrfs/ ) && p.mount_point.nil? && p.size > ( @imagesize * 110 / 100 )
					if p.fs =~ /vfat/ && @imagesize > 4_294_967_200
						puts "File to large for FAT, skipping"
					elsif  ( @imagesize * 110 / 100 ) > p.free_space 
						puts "File to large for remaining free space, skipping"
					else
						label = label + " #{p.fs}"
						label = @tl.get_translation("backup_medium") + " " + label if p.label.to_s == "USBDATA" 
						partitions.push p
						combobox.append_text(label)
					end
				end
			}
		}
		combobox.active = 0
		@targetparts = partitions
		TileHelpers.remove_lock 
	end
	
	def create_analyze_screen(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("dvdrescuegreen.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("analyzinghead") + "</b>\n\n" + @tl.get_translation("analyzebody"), 510)
		@analyzeprogress.width_request = 510
		@analyzeprogress.height_request = 32
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@analyzeprogress, 0, 108)
		return fixed
	end
	
	def create_choice_screen(extlayers)
		fixed = Gtk::Fixed.new
		# First tile, rescue on block level
		button1 = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		text1 = Gtk::Label.new
		text1.width_request = 510
		text1.wrap = true
		text1.set_markup("<span foreground='white'><b>" +@tl.get_translation("choiceimagehead") + "</b>\n" +@tl.get_translation("choiceimagebody") + "</span>") 
	
		# Second tile, rescue to cloud
		button2 = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		text2 = Gtk::Label.new
		text2.width_request = 510
		text2.wrap = true
		text2.set_markup("<span foreground='white'><b>" +@tl.get_translation("choiceburnhead") + "</b>\n" +@tl.get_translation("choiceburnbody") + "</span>")
		
		fixed.put(button2, 510, 33)
		fixed.put(button1, 510, 173)
		fixed.put(text2, 0, 0)
		fixed.put(text1, 0, 140)
		TileHelpers.place_back(fixed, extlayers)
		
		button1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				puts "Create image"
				@imageonly = true
				@imagesize = sizes(@rescdrives[@resccombo.active])[1]
				puts @imagesize.to_s 
				reread_targets
				extlayers.each { |k,v|v.hide_all }
				extlayers["dvdtarget"].show_all
			end
		}
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				puts "Create copy"
				@imageonly = false
				@imagesize = sizes(@rescdrives[@resccombo.active])[0]
				puts @imagesize.to_s 
				extlayers.each { |k,v|v.hide_all }
				if write_to_temp?(@rescdrives[@resccombo.active]) == true
					@isopath = "/tmp/"
					@isoname = "NONAME.iso"
					extlayers["dvdprogress"].show_all
					read_dvd(@rescdrives[@resccombo.active])
					extlayers.each { |k,v|v.hide_all }
					reread_burners
					extlayers["dvdburners"].show_all
				else
					reread_targets
					extlayers["dvdtarget"].show_all
				end
			end
		}
		return fixed
	end
	
	def create_progress_screen(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("dvdrescuegreen.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("readproghead") + "</b>\n\n" + @tl.get_translation("readprogbody"), 510)
		@rescueprogress.width_request = 380
		@rescueprogress.height_request = 32
		@killdd.width_request = 120
		@killdd.height_request = 32
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@rescueprogress, 0, 128)
		fixed.put(@killdd, 385, 128)
		# TileHelpers.place_back(fixed, extlayers)
		
		text = Gtk::Label.new
		text.width_request = 250
		text.wrap = true
		text.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		fixed.put(back, 650, 402)
		fixed.put(text, 402, 408)
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@killrescue = true
				system("killall -9 ddrescue")
				system "rm #{@isopath}/#{@isoname}"
				system("eject /dev/" + @rescdrives[@resccombo.active]) 
				TileHelpers.umount_all 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
				@killrescue = false
			end
		}
		return fixed
	end
	
	def create_burning_screen(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("dvdrescuegreen.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("burnproghead") + "</b>\n\n" + @tl.get_translation("burnprogbody"), 510)
		@burnprogress.width_request = 510
		@burnprogress.height_request = 32
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@burnprogress, 0, 108)
		back = TileHelpers.place_back(fixed, extlayers, false)
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				puts "Trying to kill the burn process!"
				@killburn = true
				system("killall xorrecord")
				sleep 0.5
				system("eject /dev/" + @burnerdrives[@burnercombo.active]) 
			end
		}
		return fixed
	end
	
	def burn_iso(device, isofile=nil)
		TileHelpers.set_lock 
		pgbar = @burnprogress
		command =  ["xorrecord", "--verbose", "dev=/dev/" + device.gsub("/dev/", ""), "blank=as_needed", "-eject", "#{@isopath}/#{@isoname}"  ]
		# TileHelpers.progress(@burnprogress, ["xorrecord", "--verbose", "dev=/dev/" + device.gsub("/dev/", ""), "blank=as_needed", "/tmp/COBIRESCUE.iso"  ], "Brenne neue CD/DVD" )
		# def TileHelpers.progress(pgbar, command, text)
		puts "Running " + command[0] + " : " + command.join(" ")  
		pgbar.text = @tl.get_translation("burnpgprep")
		vte = Vte::Terminal.new
		running = true
		vte.signal_connect("child_exited") { running = false }
		vte.fork_command(command[0], command)
		cycle = 0
		pgbar.fraction = 0.0
		while running == true
			if cycle % 10 == 0
				t = vte.get_text(false)
				lines = t.split("\n")
				puts lines[-2] 
				lines.each { |l|
					if l =~ /\s(\d+)\s+of\s+(\d+).*?written/
						puts $1.to_s + " - " + $2.to_s 
						pgbar.fraction = $1.to_f / $2.to_f
						pgbar.text = @tl.get_translation("burnpgprep")
					end
				}
			end
			# pgbar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
			cycle += 1 
		end
		pgbar.fraction = 1.0
		lines = vte.get_text(false).split("\n")
		success = false
		lines.each { |l|
			success = true if l =~ /writing to(.*?)completed successfully/i
		}
		if success == true
			TileHelpers.success_dialog(@tl.get_translation("burndonebody"), @tl.get_translation("burndonehead"))
			if @isopath =~ /^\/tmp/
				system "rm #{@isopath}/#{@isoname}"
			else
				if TileHelpers.yes_no_dialog(@tl.get_translation("burndeletebody").gsub("ISONAME", @isoname), @tl.get_translation("burndeletehead"))
					system "rm #{@isopath}/#{@isoname}"
				end
				@targetparts[@targetcombo.active].umount 
			end
			@extlayers.each { |k,v| v.hide_all }
			TileHelpers.back_to_group
		else	
			TileHelpers.error_dialog(@tl.get_translation("burndonebody"), @tl.get_translation("burnfailhead"))
			@killburn = false
			@extlayers.each { |k,v| v.hide_all }
			@extlayers["dvdburners"].show_all
		end
		TileHelpers.remove_lock 
	end
	
	def check_source_media(device)
		TileHelpers.set_lock
		TileHelpers.progress(@analyzeprogress, ["bash", "xocheckdrive.sh", device.gsub("/dev/", "") ], @tl.get_translation("analyzepgbar") )
		TileHelpers.progress(@analyzeprogress, ["bash", "xotoc.sh", device.gsub("/dev/", "") ], @tl.get_translation("analyzepgbar") )
		TileHelpers.remove_lock 
	end
	
	def is_burner?(device)
		TileHelpers.progress(@analyzeprogress, ["bash", "xocheckdrive.sh", device.gsub("/dev/", "") ], @tl.get_translation("analyzepgbar") )
		return nil unless File.exists?("/var/log/lesslinux/xocheckdrive-#{device}.log")
		File.open("/var/log/lesslinux/xocheckdrive-#{device}.log").each { |line|
			return true if line =~ /supported modes/i
		}
		return false
	end
	
	def sizes(device)
		return nil unless File.exists?("/var/log/lesslinux/xotoc-#{device}.log")
		File.open("/var/log/lesslinux/xotoc-#{device}.log").each { |line|
			if line =~ /media blocks/i 
				puts line 
				data = line.split(":")[1].strip.split 
				min = data[0].to_i * 2048 
				max = data[6].to_i * 2048 
				# puts min.to_s
				# puts max.to_s 
				return [ min, max ] 
			end
		}
		File.open("/var/log/lesslinux/xotoc-#{device}.log").each { |line|
			if line =~ /media summary/i 
				puts line 
				data = line.split(":")[1].strip.split(",")
				datamb = 0
				freemb = 0 
				data.each { |d|
					dtoks = d.strip.split
					datamb = ( dtoks[0].to_i + 1)  * 1024 * 1024 if dtoks[0][-1] == "m" && dtoks[-1] == "data"
					freemb = ( dtoks[0].to_i + 1) * 1024 * 1024 if dtoks[0][-1] == "m" && dtoks[-1] == "free"
					datamb = ( dtoks[0].to_i + 1 ) * 1024 * 1024 * 1024 if dtoks[0][-1] == "g" && dtoks[-1] == "data"
					freemb = ( dtoks[0].to_i + 1 ) * 1024 * 1024 * 1024 if dtoks[0][-1] == "g" && dtoks[-1] == "free"
				}
				if datamb > 0
					return [ datamb, freemb + datamb ] 
				end
			end
		}
		return nil
	end
	
	def media_is_missing?(device)
		return nil unless File.exists?("/var/log/lesslinux/xocheckdrive-#{device}.log")
		File.open("/var/log/lesslinux/xocheckdrive-#{device}.log").each { |line|
			if line =~ /media status/i
				return true if line =~ /not present/i 
			end
		}
		return false
	end
	
	def media_is_damaged?(device)
		return nil unless File.exists?("/var/log/lesslinux/xotoc-#{device}.log")
		File.open("/var/log/lesslinux/xotoc-#{device}.log").each { |line|
			return true if line =~ /read error/i 
		}
		return false
	end
	
	def write_to_temp?(device)
		s = sizes(device)
		return nil if s.nil?
		File.open("/proc/meminfo").each { |line|
			if line =~ /memfree/i
				freemem = line.split[1].to_i * 1024 
				puts line
				puts freemem.to_s 
				if freemem - s[0] >= 268435456
					return true
				else
					return false
				end
			end
		}
		return false 
	end
	
	def update_isoname(device)
		IO.popen("blkid -o udev /dev/#{device}") { |l|
			while l.gets
				ltoks = $_.strip.split("=")
				@isoname = ltoks[1] + ".iso" if ltoks[0] == "ID_FS_LABEL"
			end
		}
	end
	
	def read_dvd(device, target=nil, full=false)
		TileHelpers.set_lock 
		# FIXME: ask before overwriting!
		now = Time.new.to_i.to_s
		if File.exists?("#{@isopath}/#{@isoname}")
			@isoname = @isoname.gsub(".iso", "-#{now}.iso")
		end
		# system "rm #{@isopath}/#{@isoname}"
		system "rm /var/log/lesslinux/dvdrescue.dd.log"
		@killdd.sensitive = false
		s = sizes(device)
		rescsize = s[0]
		rescsize = s[1] if @imageonly == true 
		@rescueprogress.text = @tl.get_translation("isopgbarfirst")
		vte = Vte::Terminal.new
		running = true
		vte.signal_connect("child_exited") { running = false }
		vte.fork_command("ddrescue", [ "ddrescue", "-s", rescsize.to_s, "-n", "/dev/#{device}", "#{@isopath}/#{@isoname}", "/var/log/lesslinux/dvdrescue.dd.log" ] )
		cycles = 0 
		@rescueprogress.fraction = 0.0
		while running == true
			if File.exists?("#{@isopath}/#{@isoname}") && cycles % 10  == 0
				fsize = File.size "#{@isopath}/#{@isoname}"
				puts ( ( fsize.to_f / rescsize.to_f ) * 100 ).to_s 
				@rescueprogress.fraction = fsize.to_f / rescsize.to_f
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
			cycles += 1 
		end
		return false if @killrescue == true 
		@killdd.sensitive = true
		# start second run
		running = true
		@rescueprogress.text = @tl.get_translation("isopgbarsecond")
		vte.fork_command("ddrescue", [ "ddrescue", "-s", rescsize.to_s, "-r", "3", "/dev/#{device}", "#{@isopath}/#{@isoname}", "/var/log/lesslinux/dvdrescue.dd.log" ] )
		while running == true
			@rescueprogress.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
		end
		@rescueprogress.text = @tl.get_translation("isopgbardone")
		@rescueprogress.fraction = 1.0
		@killdd.sensitive = false
		system("rm /var/log/lesslinux/dvdrescue.dd.log") 
		system("eject /dev/#{device}")
		TileHelpers.remove_lock 
	end
	
end





