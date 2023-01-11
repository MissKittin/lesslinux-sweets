#!/usr/bin/ruby
# encoding: utf-8

class SingleFileRescue 
	def initialize(extlayers)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "SingleFileRescue.xml")
		@layers = Array.new
		@extlayers = extlayers
		# exported button:
		@button = Gtk::EventBox.new.add Gtk::Image.new("fileresc_turq.png")
		# Drives to put the image on
		@suitableparts = Array.new
		# File to rescue
		@targetfile = ""
		# Progress bar
		@progress = nil
		# Combobox for selecting target for temporary file
		@drivecombo = nil
		# Button for choosing which file to rescue
		@filebutton = nil 
		# Checkbox to decide whether to keep the temporary file 
		@keepcheck = nil
		@vte = nil
		# Flag for killing
		@killed = false 
	
		firstlayer = create_first_layer(extlayers)
		extlayers["filerescuestart"] = firstlayer
		@layers.push firstlayer
		proglayer = create_progress_layer(extlayers)
		extlayers["filerescueprogress"] = proglayer
		@layers.push proglayer
		
		@button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				fill_target_combo
				@progress.fraction = 0.0 
				extlayers["filerescuestart"].show_all
			end
		}
	end
	attr_accessor :layers, :button

	def prepare_filerescuestart
		fill_target_combo
		@progress.fraction = 0.0 
	end

	def  create_first_layer(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("systestneutral.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("filereschead") + "</b>\n\n" + @tl.get_translation("filerescbody"), 510)
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		back = TileHelpers.place_back(fixed, extlayers) #, false)
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		forwtext = Gtk::Label.new
		forwtext.width_request = 250
		forwtext.wrap = true
		# Put icon and text on fixed
		targettext = TileHelpers.create_label(@tl.get_translation("selecttarget"), 250)
		forwtext.set_markup("<span color='white'>" + @tl.get_translation("gotonext") + "</span>")
		fixed.put(forw, 650, 352)
		fixed.put(forwtext, 402, 358)
		# Create file chooser and place on fixed
		@filebutton = Gtk::Button.new(@tl.get_translation("selectfile"))
		@filebutton.width_request = 510
		@filebutton.height_request = 32
		
		# Create combobox
		@drivecombo = Gtk::ComboBox.new
		@drivecombo.width_request = 510
		@drivecombo.height_request = 32
		targettext = TileHelpers.create_label(@tl.get_translation("selecttemporarydevice"), 510)
		
		# Create checkbox 
		@keepcheck = Gtk::CheckButton.new
		checktext = TileHelpers.create_label(@tl.get_translation("keepimageafterrescue"), 510)
		
		# Whiche file to rescue?
		@selectedfile = nil 
		
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		
		fixed.put(@filebutton, 0, 150)
		fixed.put(targettext, 0, 190)
		fixed.put(@drivecombo, 0, 210)
		fixed.put(checktext, 30, 255)
		fixed.put(@keepcheck, 0, 250)
		fixed.put(reread, 520, 210)
		
		reread.signal_connect("clicked") {
			fill_target_combo
		}
		
		@filebutton.signal_connect("clicked") {
			dialog = Gtk::FileChooserDialog.new(@tl.get_translation("selectfile"),
			$mainwindow,
			Gtk::FileChooser::ACTION_OPEN,
			nil,
			[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
			[Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
			# dialog.select_multiple = true 
			if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
				# @startdir = dialog.filename
				@filebutton.label = dialog.filenames.to_s  
				@selectedfile = dialog.filenames[0] 
				puts "filename = #{dialog.filenames.to_s}"
			end
			dialog.destroy
		}
		
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @suitableparts.size > 0
					part, file = get_partition(@selectedfile)
					continue = false
					if part.nil?
						TileHelpers.error_dialog(@tl.get_translation("filenotfoundonpart"))
					elsif @suitableparts[@drivecombo.active].device == part.device 
						TileHelpers.error_dialog(@tl.get_translation("filefoundontargetpart"))
					elsif check_freespace(@suitableparts[@drivecombo.active], part, @selectedfile) 
						TileHelpers.error_dialog(@tl.get_translation("insufficientfreespace"))
					else
						continue = true
					end
					if continue == true
						extlayers.each { |k,v|v.hide_all }
						extlayers["filerescueprogress"].show_all
						# Run recovery...
						run_recovery(@suitableparts[@drivecombo.active], part, file, @keepcheck.active? ) 
						TileHelpers.success_dialog(@tl.get_translation("rescuedone")) unless @killed == true 
						extlayers.each { |k,v|v.hide_all }
						TileHelpers.back_to_group
					end
				end
			end
		}
		return fixed
	
	end
	
	def get_partition(fname)
		TileHelpers.set_lock 
		drives = Array.new
		partition = nil
		filepath = nil
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				begin
					d =  MfsDiskDrive.new(l, true)
					drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		drives.each { |d|
			d.partitions.each { |p|
				mnt = p.mount_point
				unless mnt.nil?
					z = Regexp.new("^#{mnt[0]}")
					unless fname[z].nil?
						partition = p
						filepath = fname.gsub(z, "") 
					end
				end
			}
		}
		TileHelpers.remove_lock
		return partition, filepath 
	end
	
	def check_freespace(targetpart, sourcepart, fname) 
		needed_space = sourcepart.fssize + File.size(fname)
		return true unless targetpart.free_space > needed_space
		return false
	end
	
	
	def fill_target_combo
		TileHelpers.set_lock 
		drives = Array.new
		bookmarks = File.new("/root/.gtk-bookmarks", "w") 
		@suitableparts = Array.new
		# @winparts = Array.new
		# shellentry = Array.new
		# isdefault = Array.new
		# @regfiles = Hash.new
		# activeitem = 0
		199.downto(0) { |n|
			begin
				@drivecombo.remove_text(n)
			rescue
			end
		}
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				begin
					d =  MfsDiskDrive.new(l, true)
					drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		# Now fill each combo box with the respective 
		drives.each { |d|
			d.partitions.each { |p|
				# iswin, winvers = p.is_windows
				if p.fs =~ /FAT/i 
					p.umount
					if p.label =~ /^usbdata/i
						system("mkdir -p /cobi/sicherung")
						p.mount("rw", "/cobi/sicherung") 
					else
						p.mount("ro")
					end
				end
				if p.fs =~ /NTFS/i || p.fs =~ /EXT/i || p.fs =~ /btrfs/i 
					p.umount
					if p.label =~ /^usbdata/i
						system("mkdir -p /cobi/sicherung")
						p.mount("rw", "/cobi/sicherung") 
					else
						p.mount("ro")
					end
					@suitableparts.push(p)
					desc = "#{p.device}, #{p.human_size} - #{p.fs}"
					desc = desc + " (Backup-Medium)" if p.label =~ /^usbdata/i
					@drivecombo.append_text(desc)
				end
				mnt = p.mount_point
				unless mnt.nil?
					bookmarks.write("file://#{mnt[0]}\n")
				end
			}
		}
		if @suitableparts.size > 0 
			@drivecombo.sensitive = true
		else
			@drivecombo.append_text(@tl.get_translation("no_suitable_partition_found"))
			@drivecombo.sensitive = false
		end
		@drivecombo.active = 0
		bookmarks.close 
		TileHelpers.remove_lock
	end

	def create_progress_layer(extlayers)
		@vte = Vte::Terminal.new
		@vte.height_request = 130
		@vte.width_request = 580
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("systestneutral.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("filerescproghead") + "</b>\n\n" + @tl.get_translation("filerescprogbody"), 510)
		back = TileHelpers.place_back(fixed, extlayers, false)
		@progress = Gtk::ProgressBar.new
		@progress.width_request = 510
		@progress.height_request = 32
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@progress, 0, 150)
		back.signal_connect('button-release-event') { |x, y| 
			if y.button == 1 
				@killed = true
				system("killall -9 ddrescue") 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		return fixed
	end
	
	def run_recovery(targetpart, sourcepart, fname, morefiles) 
		TileHelpers.set_lock 
		running = true
		killed = false
		targetpart.remount_rw
		sourcepart.umount
		tgtdir = targetpart.mount_point[0] + "/Datei-Rettung"
		real_target = tgtdir
		ct = 0
		while File.directory?(real_target) 
			real_target = tgtdir + "_" + ct.to_s
			ct += 1
		end
		FileUtils.mkdir_p real_target 
		cmd = [ "ddrescue", "-S", "-r", "0", "/dev/#{sourcepart.device}", "#{real_target}/filesystem.img", "#{real_target}/ddrescue.log" ]
		$stderr.puts "ddrescue first run..."
		@vte.signal_connect("child_exited") { running = false }
		unless @killed == true
			running = true
			@vte.fork_command(cmd[0], cmd)
		end
		while running == true
			running = false if @killed == true 
			sleep 0.2
			fraction = File.size("#{real_target}/filesystem.img").to_f / sourcepart.fssize.to_f 
			fraction = 1.0 if fraction > 1.0
			@progress.fraction = fraction 
			percentage = ( fraction * 100.0).to_i 
			@progress.text = @tl.get_translation("ddrescuefirstrun") + " - #{percentage}%"
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		$stderr.puts "ddrescue first run... done"
		@progress.text = @tl.get_translation("ddrescuefirstrun") + " - 100%"
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		cmd = [ "ddrescue", "-S", "-r", "5", "/dev/#{sourcepart.device}", "#{real_target}/filesystem.img", "#{real_target}/ddrescue.log" ]
		unless @killed == true
			running = true 
			sleep 0.5
			$stderr.puts "ddrescue second run..."
			@vte.fork_command(cmd[0], cmd)
			sleep 0.5
		end
		while running == true
			running = false if @killed == true 
			sleep 0.2
			@progress.text = @tl.get_translation("ddrescuesecondrun")
			@progress.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		@progress.text = @tl.get_translation("copyfile")
		@progress.fraction = 0.5
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		$stderr.puts "mount target..."
		FileUtils.mkdir_p("/tmp/filerescue") unless @killed == true
		if sourcepart.fs =~ /NTFS/i 
			system("mount -t ntfs-3g -o ro,loop  #{real_target}/filesystem.img /tmp/filerescue") unless @killed == true
		else
			system("mount -o ro,loop  #{real_target}/filesystem.img /tmp/filerescue") unless @killed == true
		end
		$stderr.puts "copy file..."
		FileUtils.cp("/tmp/filerescue/#{fname}", real_target) unless @killed == true
		@progress.text = @tl.get_translation("rescuedone")
		@progress.fraction = 1.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		if morefiles == true && TileHelpers.yes_no_dialog(@tl.get_translation("jumptoimagemount")) && @killed == false
			system("thunar /tmp/filerescue &")
			sleep 2.0
			system("thunar '#{real_target}' &")
			while @killed == false
				sleep 0.2
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
			end
		end
		system("umount /tmp/filerescue")
		FileUtils.rm("#{real_target}/filesystem.img") unless @keepcheck.active? 
		TileHelpers.umount_all
		TileHelpers.remove_lock
	end
	

end
