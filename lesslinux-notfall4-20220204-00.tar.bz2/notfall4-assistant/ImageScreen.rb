#!/usr/bin/ruby
# encoding: utf-8

class ImageScreen	
	def initialize(extlayers)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "ImageScreen.xml")
		@layers = Array.new
		@extlayers = extlayers
		### Kill cloning
		@killimaging = Gtk::Button.new
		@ddkilled = false
		### Create image disk -> file
		### ComboBox for source drives
		@srcdrivecombo = Gtk::ComboBox.new
		@srcdrives = Array.new
		@imagenames = Array.new
		### ComboBox for target partitions
		@tgtpartcombo = Gtk::ComboBox.new
		@tgtparts = Array.new
		@tgtname = Gtk::Entry.new
		### Copy it back disk -> file
		### Combobox for source files
		@srcfilecombo = Gtk::ComboBox.new
		@srcfiles = Array.new
		### Combobox for target drives
		@tgtdrivecombo = Gtk::ComboBox.new
		@tgtdrives = Array.new
		### Checkbutton for type of image
		@tgtimagetype = Gtk::CheckButton.new("")
		
		### ProgressBar for running ddrescue disk -> file
		@imageprogress = Gtk::ProgressBar.new
		### ProgressBar for running dd file -> disk
		@writeprogress = Gtk::ProgressBar.new
		
		@rescuepath = "/tmp"
		@imagename = "test.ddimage"
		@ddkilled = false
		
		choice = create_choice_screen
		@extlayers["DEAD_imagechoice"] = choice
		@layers.push choice
		
		srcdrv = create_srcdrives_screen
		@extlayers["imagesrcdrives"] = srcdrv
		@layers.push srcdrv
		
		tgtprts = create_tgtparts_screen
		@extlayers["imagetgtparts"] = tgtprts
		@layers.push tgtprts
		
		imgprog = create_imageprogress_screen
		@extlayers["imageprogress"] = imgprog
		@layers.push imgprog
		
		imgsrcs = create_srcfiles_screen
		@extlayers["imagesrcfiles"] = imgsrcs
		@layers.push imgsrcs
		
		tgtdrvs = create_tgtdrives_screen
		@extlayers["imagetgtdrives"] = tgtdrvs
		@layers.push tgtdrvs
		
		wrtprog = create_writeprogress_screen
		@extlayers["writeprogress"] = wrtprog
		@layers.push wrtprog
		
	end
	attr_reader :layers
	
	def create_choice_screen
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, @extlayers)
		button1 = Gtk::EventBox.new.add Gtk::Image.new("rescuewine.png")
		text1 = Gtk::Label.new
		text1.width_request = 510
		text1.wrap = true
		text1.set_markup("<span foreground='white'><b>" + @tl.get_translation("choiceimagehead") + "</b>\n" + @tl.get_translation("choiceimagebody") + "</span>")
	
		# Second tile, rescue to cloud
		button2 = Gtk::EventBox.new.add Gtk::Image.new("rescueturq.png")
		text2 = Gtk::Label.new
		text2.width_request = 510
		text2.wrap = true
		text2.set_markup("<span foreground='white'><b>" + @tl.get_translation("choicebackhead") + "</b>\n" + @tl.get_translation("choicebackbody") + "</span>")
		button1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				@extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				reread_srcdrives
				@extlayers.each { |k,v|v.hide_all }
				@extlayers["imagesrcdrives"].show_all
			end
		}
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				@extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				reread_srcfiles
				@extlayers.each { |k,v|v.hide_all }
				@extlayers["imagesrcfiles"].show_all
			end
		}
		fixed.put(button1, 0, 0)
		fixed.put(button2, 0, 130)
		fixed.put(text1, 130, 0)
		fixed.put(text2, 130, 130)
		return fixed
	end
	
	def prepare_imgsrcdrives
		reread_srcdrives
	end
	
	def prepare_imagesrcfiles
		reread_srcfiles
	end
	
	def create_srcdrives_screen
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, @extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gototarget") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		@srcdrivecombo.height_request = 32
		@srcdrivecombo.width_request = 380
		deltext = TileHelpers.create_label("<b>"+ @tl.get_translation("sourcedrivehead") + "</b>\n\n" + @tl.get_translation("sourcedrivebody"), 510)
		# reread_srcdrives
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @srcdrives.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("nosourcebody"), @tl.get_translation("nosourcehead"))
				else
					hib = @srcdrives[@srcdrivecombo.active].hibernated?
					if hib == true && TileHelpers.yes_no_dialog(@tl.get_translation("warnhiberboot"),@tl.get_translation("warnhiberboothead") ) == true
						@extlayers.each { |k,v|v.hide_all }
						@extlayers["pleasewait"].show_all
						while (Gtk.events_pending?)
							Gtk.main_iteration
						end
						reread_tgtparts
						update_tgtfile
						@extlayers.each { |k,v|v.hide_all }
						@extlayers["imagetgtparts"].show_all
					elsif hib == false
						@extlayers.each { |k,v|v.hide_all }
						@extlayers["pleasewait"].show_all
						while (Gtk.events_pending?)
							Gtk.main_iteration
						end
						reread_tgtparts
						update_tgtfile
						@extlayers.each { |k,v|v.hide_all }
						@extlayers["imagetgtparts"].show_all
					end
					
				#	if @tgtparts.size < 1
				#		TileHelpers.error_dialog("Es wurde nur ein Laufwerk gefunden, das Imaging von Festplatten erfordert aber ein Quell- und ein Zielllaufwerk. Bitte ggf. USB-Laufwerke anschließen und auf \"Neu einlesen\" klicken.", "Keine Laufwerke gefunden")
				#	end
				end
			end
		}
		reread.signal_connect('clicked') { reread_srcdrives }
		# fixed.put(tile, 0, 0)
		fixed.put(@srcdrivecombo, 0, 108)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 108)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_tgtparts_screen
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, @extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotoimaging") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		@tgtpartcombo.height_request = 32
		@tgtpartcombo.width_request = 380
		@tgtname.height_request = 32
		@tgtname.width_request = 380
		deltext = TileHelpers.create_label("<b>" +@tl.get_translation("targetparthead") +"</b>\n\n" +@tl.get_translation("targetpartbody") , 510)
		typelabel = TileHelpers.create_label(@tl.get_translation("bitwise"), 300)
		# reread_tgtparts
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @tgtparts.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("nosourcebody"), @tl.get_translation("nosourcehead"))
				else
					@imagename = @tgtname.text
					if  !( @imagename =~ /\.ddimage$/ ) || @imagename =~ /\// || @imagename =~ /\\/  
						TileHelpers.error_dialog(@tl.get_translation("filenamebody"), @tl.get_translation("filenamehead"))
					else
						# start imaging
						@tgtparts[@tgtpartcombo.active].mount("rw")
						if @tgtparts[@tgtpartcombo.active].mount_point.nil?
							TileHelpers.error_dialog(@tl.get_translation("badtempbody"), @tl.get_translation("badtemphead"))
						else
							@rescuepath = @tgtparts[@tgtpartcombo.active].mount_point[0] 
							if File.exists?(@rescuepath + "/" + @imagename) 
								if TileHelpers.yes_no_dialog(@tl.get_translation("askdeletebody"), @tl.get_translation("askdeletehead"))
									File.unlink(@rescuepath + "/" + @imagename) 
									runwrap
								else
									TileHelpers.umount_all
								end
							else
								runwrap 
							end
						end
					end
				end
			end
		}
		reread.signal_connect('clicked') { reread_tgtparts }
		@tgtimagetype.signal_connect('clicked') { reread_tgtparts }
		# fixed.put(tile, 0, 0)
		fixed.put(@tgtpartcombo, 0, 158)
		fixed.put(@tgtname, 0, 200)
		# fixed.put(@tgtimagetype, 130, 158)
		# fixed.put(typelabel, 150, 163)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 158)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end

	def create_imageprogress_screen
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		back = TileHelpers.place_back(fixed, @extlayers, false)
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("readproghead") + "</b>\n\n" +@tl.get_translation("readprogbody") , 510)
		@imageprogress.width_request = 510
		@imageprogress.height_request = 32
		@killimaging.width_request = 120
		@killimaging.height_request = 32
		@killimaging.label = @tl.get_translation("stopsecond") # "2. Lauf abbrechen"
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@imageprogress, 0, 128)
		# fixed.put(@killimaging, 515, 108)
		# TileHelpers.place_back(fixed, extlayers)
		
		text = Gtk::Label.new
		text.width_request = 250
		text.wrap = true
		text.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		# fixed.put(text, 605, 338)
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@ddkilled = true
				@extlayers.each { |k,v|v.hide_all }
				system("killall -9 ddrescue")
				system("killall -9 dd")
				system("killall -9 ntfsclone")
				system("killall -9 vboxmanage")
				sleep 5.0 
				system "rm #{@rescuepath}/#{@imagename}"
				TileHelpers.umount_all 
				TileHelpers.back_to_group
				@ddkilled = false
			end
		}
		return fixed
	end
	
	def create_srcfiles_screen
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, @extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gototargetchoice") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		@srcfilecombo.height_request = 32
		@srcfilecombo.width_request = 380
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("sourcefilehead") + "</b>\n\n" +@tl.get_translation("sourcefilebody") , 510)
		# reread_srcdrives
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @srcfiles.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("noimagebody"),@tl.get_translation("noimagehead"))
				else
					@extlayers.each { |k,v|v.hide_all }
					@extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					reread_tgtdrives 
					@extlayers.each { |k,v|v.hide_all }
					@extlayers["imagetgtdrives"].show_all
				end
			end
		}
		reread.signal_connect('clicked') { reread_srcdrives }
		# fixed.put(tile, 0, 0)
		fixed.put(@srcfilecombo, 0, 128)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 128)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_tgtdrives_screen
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, @extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotocopyback") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		@tgtdrivecombo.height_request = 32
		@tgtdrivecombo.width_request = 380
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("ddbackhead") + "</b>\n\n" +@tl.get_translation("ddbackbody") , 510)
		# reread_tgtparts
		reread = Gtk::Button.new(@tl.get_translation("reread") ) # ("Neu einlesen")
		reread.width_request = 120
		reread.height_request = 32
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				minsize = @srcfiles[@srcfilecombo.active][3] 
				disksize = @tgtdrives[@tgtdrivecombo.active].size
				doit = true
				if minsize > disksize
					doit = TileHelpers.yes_no_dialog(@tl.get_translation("toosmallbody"), @tl.get_translation("toosmallhead"))
				end
				if doit == true
					doit = TileHelpers.yes_no_dialog(@tl.get_translation("confirmbody"), @tl.get_translation("confirmhead"))
				end
				if doit == true
					@ddkilled = false
					@extlayers.each { |k,v|v.hide_all }
					@extlayers["writeprogress"].show_all
					run_dd
					# run_vdimage 
					if @ddkilled == true
						TileHelpers.error_dialog(@tl.get_translation("ddcancelbody"), @tl.get_translation("ddcancelhead"))
					else
						TileHelpers.success_dialog(@tl.get_translation("ddsuccessbody"), @tl.get_translation("ddsuccesshead"))
					end
					@extlayers.each { |k,v|v.hide_all }
					TileHelpers.back_to_group
				end
			end
		}
		reread.signal_connect('clicked') { reread_tgtparts }
		# fixed.put(tile, 0, 0)
		fixed.put(@tgtdrivecombo, 0, 108)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 108)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_writeprogress_screen
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		back = TileHelpers.place_back(fixed, @extlayers, false)
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("ddproghead") + "</b>\n\n" + @tl.get_translation("ddprogbody"), 510)
		@writeprogress.width_request = 510
		@writeprogress.height_request = 32
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@writeprogress, 0, 128)
		# TileHelpers.place_back(fixed, extlayers)
		
		text = Gtk::Label.new
		text.width_request = 250
		text.wrap = true
		text.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		# fixed.put(text, 605, 338)
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@ddkilled = true
				system("killall -9 dd")
				TileHelpers.umount_all 
			end
		}
		return fixed
	end
	
	def reread_srcdrives
		TileHelpers.set_lock 
		TileHelpers.umount_all
		100.downto(0) { |i| 
			begin
				@srcdrivecombo.remove_text(i) 
			rescue
			end
		}
		drives = Array.new
		drivenames = Array.new
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				d = MfsDiskDrive.new(l, false)
				drives.push d unless d.mounted
			end
		}
		drives.each { |d|
			label =  "#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
			drivenames.push "#{d.vendor} #{d.model} - #{d.human_size}"
			if d.usb == true
				label = label + " (USB)"
			else
				label = label + " (SATA/eSATA/IDE/NVME)"
			end
			@srcdrivecombo.append_text(label)
		}
		@srcdrivecombo.active = 0
		@srcdrives = drives
		@imagenames = drivenames
		TileHelpers.remove_lock
	end
	
	def reread_tgtparts
		TileHelpers.set_lock 
		TileHelpers.umount_all
		100.downto(0) { |i| 
			begin
				@tgtpartcombo.remove_text(i) 
			rescue
			end
		}
		drives = Array.new
		drivenames = Array.new
		partitions = Array.new
		if @srcdrives[@srcdrivecombo.active].nil?
			@extlayers.each { |k,v|v.hide_all }
			@extlayers["imagesrcfiles"].show_all
			TileHelpers.remove_lock 
			return false
		end
		srcdisk = @srcdrives[@srcdrivecombo.active].device
		minsize = @srcdrives[@srcdrivecombo.active].size
		minsize = calculate_logical_size(@srcdrives[@srcdrivecombo.active]) if @tgtimagetype.active? == false
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
							@tgtpartcombo.append_text(label) 
						end
					end
				else
					puts "Ignore #{label} #{p.fs}"
				end
			}
		}
		@tgtpartcombo.append_text(@tl.get_translation("nosuitabletarget")) if partitions.size <  1
		@tgtpartcombo.sensitive = true
		@tgtpartcombo.sensitive = false if partitions.size <  1
		@tgtparts = partitions 
		@tgtpartcombo.active = 0
		TileHelpers.remove_lock 
	end
	
	def update_tgtfile
		@tgtname.text = @imagenames[@srcdrivecombo.active] + ".ddimage" 
	end
	
	def reread_srcfiles
		TileHelpers.set_lock 
		TileHelpers.umount_all
		100.downto(0) { |i| 
			begin
				@srcfilecombo.remove_text(i) 
			rescue
			end
		}
		srcfiles = Array.new
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				d = MfsDiskDrive.new(l, false)
				drives.push d # unless d.mounted
			end
		}
		drives.reverse.each { |d|
			d.partitions.each { |p|
				mnt = p.mount_point
				if  ( p.fs =~ /vfat/ || p.fs =~ /ntfs/ || p.fs =~ /ext/ || p.fs =~ /btrfs/ || p.fs =~ /vfat/ ) && mnt.nil? 
					label = "#{d.vendor} #{d.model}"
					if d.usb == true
						label = label + " USB"
						label = @tl.get_translation("backup_medium") + " " + label if p.label.to_s == "USBDATA"  
					else
						label = label + " SATA/eSATA/IDE/NVME"
					end
					puts label
					p.mount
					mnt = p.mount_point
					imgs = get_images(mnt[0]) unless mnt.nil?
					imgs = Array.new if mnt.nil?
					p.umount 
					imgs.each { |i|
						f = i[0] # .gsub('.ddimage', '')
						@srcfilecombo.append_text "#{f} ( #{label})" 
						srcfiles.push [ d.device, p, i[0], i[1] ] 
					}
				end
			}
		}
		@srcfilecombo.active = 0
		@srcfiles = srcfiles
		TileHelpers.remove_lock 
	end
	
	def get_images(mountpoint)
		TileHelpers.set_lock 
		imgs = Array.new
		Dir.foreach(mountpoint) { |f|
			begin
				if File.stat(mountpoint + "/" + f).file? &&  ( f =~ /\.ddimage$/ || f =~ /\.qcow/ || f =~ /\.vdi$/ || f =~ /\.vhd/ || f =~ /\.vmdk$/ || f =~ /\.vpc$/ ) 
					unless f =~ /-s[0-9][0-9][0-9]\.ddimage$/ 
						virtsize = nil
						virttype = nil
						IO.popen("qemu-img info \"#{mountpoint}/#{f}\"") { |l|
							while l.gets
								if $_ =~ /^file format\: raw/i
									virttype = nil
								elsif $_ =~  /^file format\: (.*)$/i
									# Format is handled by qemu-nbd!
									virttype = $1.strip 
								elsif $_ =~ /^virtual size.*?\(([0-9]*)/i
									virtsize = $1.to_i 
								end
							end
						}
						imgsize =  File.stat(mountpoint + "/" + f).size
						imgsize = virtsize unless virttype.nil? 
						imgs.push [ f, imgsize ] 
					end
				end
			rescue
				puts "Reading file: #{f} failed"
			end
		}
		TileHelpers.remove_lock
		return imgs 
	end
	
	def reread_tgtdrives
		TileHelpers.set_lock 
		TileHelpers.umount_all
		100.downto(0) { |i| 
			begin
				@tgtdrivecombo.remove_text(i) 
			rescue
			end
		}
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				d = MfsDiskDrive.new(l, false)
				drives.push d unless d.mounted || @srcfiles[@srcfilecombo.active][0] == d.device 
			end
		}
		drives.each { |d|
			label =  "#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
			if d.usb == true
				label = label + " (USB)"
			else
				label = label + " (SATA/eSATA/IDE/NVME)"
			end
			@tgtdrivecombo.append_text(label)
		}
		@tgtdrivecombo.active = 0
		@tgtdrives = drives
		TileHelpers.remove_lock 
	end
	
	def runwrap
		TileHelpers.set_lock 
		@extlayers.each { |k,v|v.hide_all }
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		@extlayers["imageprogress"].show_all
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		logsucc = true
		if @tgtimagetype.active? 
			run_ddrescue 
			# run_vdimage 
		else	
			if @tgtparts[ @tgtpartcombo.active ].fs =~ /vfat/i
				logsucc = run_vdimage 
			else
				logsucc = run_logical_image
			end
		end
		if logsucc == false
			TileHelpers.error_dialog(@tl.get_translation("erroraccess"))
			system("sync")
			system("rm \"#{@rescuepath}/#{@imagename}\"")
			system("sync") 
		elsif File.exists?("#{@rescuepath}/#{@imagename}") && ( @srcdrives[@srcdrivecombo.active].size <= File.size("#{@rescuepath}/#{@imagename}") || @tgtparts[ @tgtpartcombo.active ].fs =~ /vfat/i ) 
			TileHelpers.success_dialog(@tl.get_translation("imagesuccessbody").gsub("IMAGENAME", @imagename), @tl.get_translation("imagesuccesshead")) 
		elsif File.exists?("#{@rescuepath}/#{@imagename}")
			TileHelpers.success_dialog(@tl.get_translation("imagetoosmallbody").gsub("IMAGENAME", @imagename), @tl.get_translation("imagetoosmallhead")) 
		else
			TileHelpers.success_dialog(@tl.get_translation("imagemissingbody").gsub("IMAGENAME", @imagename), @tl.get_translation("imagemissinghead")) 
		end
		@extlayers.each { |k,v|v.hide_all }
		@extlayers["pleasewait"].show_all
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		TileHelpers.umount_all 
		TileHelpers.remove_lock 
		@extlayers.each { |k,v|v.hide_all }
		TileHelpers.back_to_group
	end
	
	def calculate_size(filename)
		truncfile = filename.gsub(/\.ddimage$/, "")
		filesize = 0 
		1.upto(999) { |n|
			fname = truncfile + "-s" + sprintf("%03d", n) + ".ddimage"
			filesize += File.size(fname) if File.exists?(fname) 
		}
		return filesize 
	end
	
	# VERR_INVALID_PARAMETER
	# vboxmanage convertfromraw /dev/sdc /mnt/archiv/tmp/test.vmdk --format vmdk --variant Split2G
	
	def run_vdimage
		TileHelpers.set_lock 
		@killimaging.sensitive = false
		minsize = @srcdrives[@srcdrivecombo.active].size
		device = @srcdrives[@srcdrivecombo.active].device
		@imageprogress.text = @tl.get_translation("vdiprogfirst")
		vte = Vte::Terminal.new
		vte.set_size(80, 25)  
		running = true
		vte.signal_connect("child_exited") { running = false }
		args = [ "/usr/local/VirtualBox/VBoxManage", "convertfromraw", "/dev/#{device}", "#{@rescuepath}/#{@imagename}", "--format", "vmdk", "--variant", "Split2G" ]
		puts args.join(" + ")
		vte.fork_command( :argv => args )
		cycles = 0 
		@imageprogress.fraction = 0.0
		fraction = 0.0
		starttime = Time.now.to_i
		timeremaining = -1
		while running == true
			if cycles % 250 == 0
				system("sync")
			end
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
				@imageprogress.pulse
			else
				@imageprogress.fraction = fraction
				#@imageprogress.text = "Erstelle Image - 1. Lauf - ca. #{timeremaining.to_s} Minuten verbleibend" 
				@imageprogress.text = @tl.get_translation("vdiprogminutes").gsub("MINUTES", timeremaining.to_s) 
				# @imageprogress.text = "Erstelle Image - 1. Lauf - ca. eine Minute verbleibend" if timeremaining == 1 
				@imageprogress.text = @tl.get_translation("vdiprogone") if timeremaining == 1 
				# @imageprogress.text = "Erstelle Image - 1. Lauf - weniger als eine Minute verbleibend" if timeremaining < 1 
				@imageprogress.text = @tl.get_translation("vdiprogzero") if timeremaining < 1 
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
			cycles += 1 
		end
		TileHelpers.remove_lock 
		return false if @ddkilled == true 
		@killimaging.sensitive = true	
		@imageprogress.text = @tl.get_translation("vdiprogdone")
		system("sync")
		# TileHelpers.umount_all
		@imageprogress.fraction = 1.0
		@killimaging.sensitive = false
		command_out = vte.get_text_range( 0, 0, 25 , 79, false)
		return false if command_out =~ /VERR_/ 
		return true 
	end
	
	
	def run_ddrescue
		TileHelpers.set_lock 
		system "rm /var/log/lesslinux/dvdrescue.dd.log"
		system "mkdir -p /var/log/lesslinux"
		@killimaging.sensitive = false
		minsize = @srcdrives[@srcdrivecombo.active].size
		device = @srcdrives[@srcdrivecombo.active].device
		@imageprogress.text = @tl.get_translation("ddprogfirst")
		vte = Vte::Terminal.new
		running = true
		vte.signal_connect("child_exited") { running = false }
		args = [ "ddrescue", "-n", "/dev/#{device}", "#{@rescuepath}/#{@imagename}", "/var/log/lesslinux/dvdrescue.dd.log" ]
		args = [ "ddrescue", "--sparse", "-n", "/dev/#{device}", "#{@rescuepath}/#{@imagename}", "/var/log/lesslinux/dvdrescue.dd.log" ] if @srcdrives[@srcdrivecombo.active].size >= 4_294_967_296
		puts args.join(" + ")
		vte.fork_command( :argv => args )
		cycles = 0 
		@imageprogress.fraction = 0.0
		fraction = 0.0
		starttime = Time.now.to_i
		timeremaining = -1
		while running == true
			if cycles % 250 == 0
				system("sync")
			end
			if File.exists?("#{@rescuepath}/#{@imagename}") && cycles % 10  == 0
				fsize = File.size "#{@rescuepath}/#{@imagename}"
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
				@imageprogress.pulse
			else
				@imageprogress.fraction = fraction
				#@imageprogress.text = "Erstelle Image - 1. Lauf - ca. #{timeremaining.to_s} Minuten verbleibend" 
				@imageprogress.text = @tl.get_translation("ddprogminutes").gsub("MINUTES", timeremaining.to_s) 
				# @imageprogress.text = "Erstelle Image - 1. Lauf - ca. eine Minute verbleibend" if timeremaining == 1 
				@imageprogress.text = @tl.get_translation("ddprogone") if timeremaining == 1 
				# @imageprogress.text = "Erstelle Image - 1. Lauf - weniger als eine Minute verbleibend" if timeremaining < 1 
				@imageprogress.text = @tl.get_translation("ddprogzero") if timeremaining < 1 
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
			cycles += 1 
		end
		if @ddkilled == true 
			TileHelpers.remove_lock
			return false
		end
		@killimaging.sensitive = true
		# start second run
		running = true
		@imageprogress.text = @tl.get_translation("ddprogsecond")
		args =  [ "ddrescue", "-r", "3", "/dev/#{device}", "#{@rescuepath}/#{@imagename}", "/var/log/lesslinux/dvdrescue.dd.log" ] 
		args =  [ "ddrescue", "--sparse", "-r", "3", "/dev/#{device}", "#{@rescuepath}/#{@imagename}", "/var/log/lesslinux/dvdrescue.dd.log" ] if @srcdrives[@srcdrivecombo.active].size >= 4_294_967_296
		puts args.join(" + ")
		vte.fork_command( :argv => args )
		while running == true
			@imageprogress.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
		end
		@imageprogress.text = @tl.get_translation("ddprogdone")
		system("sync")
		TileHelpers.umount_all
		@imageprogress.fraction = 1.0
		@killimaging.sensitive = false
		TileHelpers.set_lock 
		system("rm /var/log/lesslinux/dvdrescue.dd.log") 
	end
	
	def run_dd
		TileHelpers.set_lock 
		tgt = @tgtdrives[@tgtdrivecombo.active].device
		@writeprogress.text = @tl.get_translation("ddprogrunning")
		src = @srcfiles[@srcfilecombo.active] 
		src[1].mount
		infile = src[1].mount_point[0] + "/" + src[2] 
		insize = src[3] 
		# Test whether file is format known by Qemu
		virtsize = nil
		virttype = nil
		IO.popen("qemu-img info \"#{src[1].mount_point[0]}/#{src[2]}\"") { |l|
			while l.gets
				if $_ =~ /^file format\: raw/i
					virttype = nil
				elsif $_ =~  /^file format\: (.*)$/i
					# Format is handled by qemu-nbd!
					virttype = $1.strip 
				elsif $_ =~ /^virtual size.*?\(([0-9]*)/i
					virtsize = $1.to_i 
				end
			end
		}
		args = Array.new
		unless virttype.nil?
			system("modprobe nbd")
			system("qemu-nbd -d /dev/nbd0")
			sleep 1.0
			system("qemu-nbd -r -c /dev/nbd0 \"#{infile}\"")
			system("sync")
			sleep 1.0
			args = [ "dd", "of=/dev/#{tgt}", "if=/dev/nbd0", "conv=fdatasync,sparse" ]
		else
			args = [ "dd", "of=/dev/#{tgt}", "if=#{infile}", "conv=fdatasync,sparse" ]
		end
		vte = Vte::Terminal.new
		running = true
		vte.signal_connect("child_exited") { running = false }
		puts args.join(" + ")
		vte.fork_command( :argv => args )
		cycles = 0 
		@writeprogress.fraction = 0.0
		fraction = 0.0
		starttime = Time.now.to_i
		timeremaining = -1
		timerunning = 0
		while running == true
			if cycles % 10 == 0
				# system("sync") 
				system("killall -USR1 dd")
				t = vte.get_text(false)
				lines = t.split("\n")
				lines.each { |l|
					if l =~ /(\d+)\sbyte/i || l =~ /(\d+)\sbajt/i
						written = $1.to_i
						fraction = written.to_f / insize.to_f
					end
				}
				puts fraction.to_s
				timerunning = Time.now.to_i - starttime 
				begin
					ttotal = 1.0 / fraction * timerunning.to_f
					ttemp = ( ttotal.to_i - timerunning ) / 60 
					puts fraction.to_f.to_s
					puts ttemp 
					timeremaining = ttemp if  ( ttemp < timeremaining || timeremaining < 0 ) && fraction > 0.015 && timerunning > 30
					puts ttemp.to_s 
				rescue
				end
				puts "Remaining: " + timeremaining.to_s 
				# timerunning = Time.now.to_i - starttime 
			end
			if fraction > 0.02 && timerunning > 30
				@writeprogress.fraction = fraction
				# @writeprogress.text = "Schreibe Image-Datei zurück - ca. #{timeremaining.to_s} Minuten verbleibend" 
				@writeprogress.text = @tl.get_translation("backprogminutes").gsub("MINUTES", timeremaining.to_s)
				# @writeprogress.text = "Schreibe Image-Datei zurück - 1. Lauf - ca. eine Minute verbleibend" if timeremaining == 1 
				@writeprogress.text = @tl.get_translation("backprogone")  if timeremaining == 1 
				# @writeprogress.text = "Schreibe Image-Datei zurück - 1. Lauf - weniger als eine Minute verbleibend" if timeremaining < 1 
				@writeprogress.text = @tl.get_translation("backprogzero")  if timeremaining < 1
			else
				@writeprogress.pulse
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
			cycles += 1 
		end
		puts "Last process exit: " + $?.to_i.to_s
		system("sync")
		sleep 0.5
		system("partprobe /dev/#{tgt}")
		system("qemu-nbd -d /dev/nbd0")
		t = vte.get_text(false)
		puts t 
		src[1].umount 
		@writeprogress.fraction = 1.0
		@writeprogress.text = @tl.get_translation("backprogdone")
		TileHelpers.remove_lock
	end
	
	# Only copy occupied space to image
	def run_logical_image
		TileHelpers.set_lock 
		srcdev = @srcdrives[@srcdrivecombo.active]
		@imageprogress.text = @tl.get_translation("log_prog_prepare")
		# return false if srcdev.gpt == true
		vte = Vte::Terminal.new
		running = true
		vte.signal_connect("child_exited") { running = false }
		# create an empty container 
		numblocks = srcdev.size / 512 
		system("dd conv=fdatasync if=/dev/#{srcdev.device} of=\"#{@rescuepath}/#{@imagename}\" seek=#{numblocks - 1} count=1 bs=512")
		system("sync")
		loopdev = ` losetup -f `.strip 
		system("losetup #{loopdev} \"#{@rescuepath}/#{@imagename}\" ")
		@imageprogress.text = @tl.get_translation("wait_for_loopdevice")
		0.upto(50) {
			@imageprogress.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
		}
		# clone the partition table
		blockcount = 1
		blockcount = 128 if srcdev.gpt == true
		# copy partition table
		command = "dd conv=fdatasync bs=512 count=#{blockcount} if=/dev/#{srcdev.device} of=#{loopdev}"
		$stderr.puts "RUNNING (to copy MBR): #{command}" 
		system(command) 
		ebrblocks = Array.new
		if srcdev.gpt == false
			IO.popen("parted -s /dev/#{srcdev.device} unit b print") { |l|
				while l.gets
					ltoks = $_.strip.split 
					if ltoks[4] == "extended"
						ebrblocks.push(ltoks[1].gsub("B", "").to_i / 512) 
					elsif  ltoks[4] == "logical"
						ebrblocks.push((ltoks[2].gsub("B", "").to_i + 1) / 512) 
					end
				end
			}
		end
		# Clone all EBRs 
		ebrblocks.each { |e|
			command = "dd conv=fdatasync if=/dev/#{srcdev.device} of=#{loopdev} seek=#{e} skip=#{e} bs=512 count=2"
			$stderr.puts "RUNNING (to copy EBR): #{command}" 
			system(command)
		}
		# Now associate partition mappings to the loop device
		$stderr.puts "RUNNING kpartx to create partition mappings"
		system("kpartx -s -a -v #{loopdev}") 
		@imageprogress.text = @tl.get_translation("wait_for_devicemapper")
		0.upto(50) {
			@imageprogress.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
		}
		system("sync")
		system("ls -lah /dev/mapper")
		system("sync") 
		# Clone each partition 
		n = 0 
		srcdev.partitions.each { |p|
			#while n < 5
				system("sync")
				sleep 2.0 
				system("sync")
				tgt = loopdev.gsub("/dev/", "/dev/mapper/") + "p" + p.device.gsub(srcdev.device, "") 
				ddcmd = "dd conv=fdatasync if=/dev/zero of=#{tgt} bs=1024 count=1024"
				puts "RUNNING: #{ddcmd}"
				system "ls -lah #{tgt}"
				system(ddcmd) 
				args = Array.new
				if p.fs =~ /ntfs/i 
					args = [ "/usr/sbin/ntfsclone", "--force", "--overwrite", tgt, "/dev/#{p.device}" ]
					@imageprogress.text = @tl.get_translation("log_prog_ntfs").gsub("PARTITION", p.device) 
				else
					args = [ "dd", "conv=fdatasync,sparse", "if=/dev/#{p.device}", "of=#{tgt}" ]
					@imageprogress.text = @tl.get_translation("log_prog_dd").gsub("PARTITION", p.device) 
				end
				system("sync")
				$stderr.puts args.join(" + ")
				if @ddkilled == true
					running = false
				else
					vte.fork_command( :argv => args )
					running = true 
				end
				while running == true
					@imageprogress.pulse
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					sleep 0.2 
				end
				n += 1
			#end
		}
		# Check for success 
		system("mkdir -p /var/run/lesslinux/clonesrc")
		system("mkdir -p /var/run/lesslinux/clonetgt")
		failed_parts = Array.new
		srcdev.partitions.each { |p|
			tgt = loopdev.gsub("/dev/", "/dev/mapper/") + "p" + p.device.gsub(srcdev.device, "") 
			if p.fs =~ /ntfs/i 
				system("mount -t ntfs-3g -o ro #{tgt} /var/run/lesslinux/clonetgt")
				failed_parts.push(p.device) unless system("mountpoint -q /var/run/lesslinux/clonetgt")
				system("umount /var/run/lesslinux/clonetgt")
			elsif p.fs =~ /fat/i 
				system("mount -t vfat -o ro #{tgt} /var/run/lesslinux/clonetgt")
				failed_parts.push(p.device) unless system("mountpoint -q /var/run/lesslinux/clonetgt")
				system("umount /var/run/lesslinux/clonetgt")
			end
		}
		# Remove partition mappings
		99.downto(1) { |n| 
			dmdev = loopdev.gsub("/dev/", "/dev/mapper/") + "p" + n.to_s
			system("dmsetup remove " +  dmdev) if File.exists?(dmdev)
		}
		# Remove loop device
		system("losetup -d #{loopdev}") 
		@imageprogress.fraction = 1.0
		@imageprogress.text = @tl.get_translation("log_prog_done")
		TileHelpers.remove_lock
		if failed_parts.size > 0
			@imageprogress.text = @tl.get_translation("errorprogress")
			return false
		end
		return true
	end
	
	def calculate_logical_size(disk)
		minsize = 16777216
		disk.partitions.each { |p|
			if p.fs =~ /ntfs/i 
				p.free_space
				minsize = minsize + p.filesyssize - p.free 
			else 
				minsize += p.size 
			end
		}
		return minsize 
	end
end







