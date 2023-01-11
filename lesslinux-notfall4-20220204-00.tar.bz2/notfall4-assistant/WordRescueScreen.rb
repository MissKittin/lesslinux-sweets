#!/usr/bin/ruby
# encoding: utf-8

require 'nokogiri'
require 'fileutils'

class WordRescueScreen	
	def initialize(extlayers)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@lang = lang
		@tl = MfsTranslator.new(lang, "WordRescueScreen.xml")
		@extlayers = extlayers
		@layers = Array.new
		# exported button:
		@button = Gtk::EventBox.new.add Gtk::Image.new("fileresc_green.png")
		@selectedfiles = Array.new
		@suitableparts = Array.new
		
		# buttons for selection of target and source
		@fmbutton = nil
		@targetcombo = nil
		@progress = nil
		@killed = false
		
		@button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				fill_target_combo
				@progress.fraction = 0.0 
				@fmbutton.label = @tl.get_translation("selectfile")
				extlayers["wordrescuestart"].show_all
			end
		}
		
		firstlayer = create_first_layer(extlayers)
		extlayers["wordrescuestart"] = firstlayer
		@layers.push firstlayer
		proglayer = create_progress_layer(extlayers)
		extlayers["wordrescueprogress"] = proglayer
		@layers.push proglayer
		
	end
	attr_reader :layers, :button 
	
	def prepare_wordrescuestart
		fill_target_combo
		@progress.fraction = 0.0 
		@fmbutton.label = @tl.get_translation("selectfile")
	end
	
	def create_first_layer(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("wordreschead") + "</b>\n\n" + @tl.get_translation("wordrescbody"), 510)
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		back = TileHelpers.place_back(fixed, extlayers) # , false)
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		forwtext = Gtk::Label.new
		forwtext.width_request = 250
		forwtext.wrap = true
		targettext = TileHelpers.create_label(@tl.get_translation("selecttarget"), 250)
		forwtext.set_markup("<span color='white'>" + @tl.get_translation("gotonext") + "</span>")
		fixed.put(forw, 650, 352)
		fixed.put(forwtext, 402, 358)
		@fmbutton = Gtk::Button.new(@tl.get_translation("selectfile"))
		@fmbutton.width_request = 510
		@fmbutton.height_request = 32
		@targetcombo = Gtk::ComboBox.new
		@targetcombo.width_request = 510
		@targetcombo.height_request = 32
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		fixed.put(@fmbutton, 0, 150)
		fixed.put(targettext, 0, 190)
		fixed.put(@targetcombo, 0, 210)
		fixed.put(reread, 520, 210)
		reread.signal_connect("clicked") {
			fill_target_combo
		}
		@fmbutton.signal_connect("clicked") {
			dialog = Gtk::FileChooserDialog.new(@tl.get_translation("selectfile"),
			$mainwindow,
			Gtk::FileChooser::ACTION_OPEN,
			nil,
			[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
			[Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
			dialog.select_multiple = true 
			if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
				# @startdir = dialog.filename
				@fmbutton.label = dialog.filenames.to_s  
				@selectedfiles = dialog.filenames
				puts "filename = #{dialog.filenames.to_s}"
			end
			dialog.destroy
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@killed = false
				if @selectedfiles.size > 0 && @suitableparts.size > 0
					extlayers.each { |k,v|v.hide_all }
					extlayers["wordrescueprogress"].show_all
					run_extract(extlayers)
				elsif  @selectedfiles.size < 1
					TileHelpers.error_dialog(@tl.get_translation("selectatleastonefile"))
				else
					TileHelpers.error_dialog(@tl.get_translation("nosuitabletargetfound"))
				end
			end
		}
		
		return fixed
	end
	
	def create_progress_layer(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("reparierenneutral.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("wordrescproghead") + "</b>\n\n" + @tl.get_translation("wordrescprogbody"), 510)
		back = TileHelpers.place_back(fixed, extlayers, false)
		@progress = Gtk::ProgressBar.new
		@progress.width_request = 510
		@progress.height_request = 32
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@progress, 0, 150)
		back.signal_connect('button-release-event') {
			if y.button == 1 
				@killed = true
			end
		}
		return fixed
	end
	
	def fill_target_combo
		TileHelpers.set_lock 
		bookmarks = File.new("/root/.gtk-bookmarks", "w") 
		drives = Array.new
		@suitableparts = Array.new
		# @winparts = Array.new
		# shellentry = Array.new
		# isdefault = Array.new
		# @regfiles = Hash.new
		# activeitem = 0
		199.downto(0) { |n|
			begin
				@targetcombo.remove_text(n)
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
				if p.fs =~ /FAT/i || p.fs =~ /NTFS/i
					p.umount
					if p.label =~ /^usbdata/i
						system("mkdir -p /cobi/sicherung")
						p.mount("rw", "/cobi/sicherung") 
					else
						p.mount("ro")
					end
					mnt = p.mount_point
					unless mnt.nil?
						bookmarks.write("file://#{mnt[0]}\n")
						@suitableparts.push(p)
						desc = "#{p.device}, #{p.human_size} - #{p.fs}"
						desc = desc + " (Backup-Medium)" if p.label =~ /^usbdata/i
						@targetcombo.append_text(desc)
					end
				end
			}
		}
		if @suitableparts.size > 0 
			# gobutton.sensitive = true 
			@targetcombo.sensitive = true
			# switch_shelllabel(shelllabel, 0, gobutton)
		else
			@targetcombo.append_text(@tl.get_translation("no_suitable_partition_found"))
			@targetcombo.sensitive = false
			#wincombo.append_text("Windows 8.1 auf sdb1 (SATA/eSATA/IDE)") 
			# wincombo.sensitive = true
		end
		@targetcombo.active = 0
		bookmarks.close
		TileHelpers.remove_lock
	end
	
	def run_extract(extlayers)
		TileHelpers.set_lock 
		filect = 0
		# Mount/Remount target partition
		target_part = @suitableparts[@targetcombo.active]
		return false unless target_part.remount_rw 
		mnt = target_part.mount_point
		return false if mnt.nil?
		@selectedfiles.each { |f|
			$stderr.puts "Extracting: #{f}" 
			@progress.fraction = filect.to_f / @selectedfiles.size.to_f
			@progress.text = @tl.get_translation("rescuing_file") + " " + f
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			rescue_single_file(f, mnt[0]) unless @killed == true 
			filect += 1
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			system("sync") 
		}
		@suitableparts.each { |p| p.umount }
		@progress.fraction = 1.0
		@progress.text = @tl.get_translation("rescuing_done")  
		TileHelpers.success_dialog(@tl.get_translation("everything_done")) unless @killed == true 
		TileHelpers.umount_all 
		TileHelpers.remove_lock
		extlayers.each { |k,v|v.hide_all }
		TileHelpers.back_to_group
	end
	
	def rescue_single_file(filepath, target_dir)
		TileHelpers.set_lock 
		success = false
		if filepath =~ /\.doc$/i ||  filepath =~ /\.rtf$/i 
			success = rescue_doc(filepath, target_dir)
		elsif filepath =~ /\.docx$/i 
			success = rescue_docx(filepath, target_dir)
		elsif filepath =~ /\.odt$/i 
			success = rescue_odt(filepath, target_dir)
		end
		if success == false
			rescue_other(filepath, target_dir)
		end
		TileHelpers.remove_lock
	end
	
	def rescue_doc(filepath, target_dir)
		suffix = "_doc"
		suffix = "_rtf" if filepath =~ /\.rtf$/i 
		target_subdir = target_dir + "/" + File.basename(filepath, ".*") + suffix
		real_target = target_subdir
		ct = 0
		while File.directory?(real_target) 
			real_target = target_subdir + "_" + ct.to_s
			ct += 1
		end
		FileUtils::mkdir_p(real_target)
		#if filepath =~ /\.rtf$/i 
		#	FileUtils::cp( filepath, "/tmp/temp.doc")
		#	success = system("/usr/bin/wvHtml --targetdir='#{real_target}' '/tmp/temp.doc' DOKUMENTINHALT.html")
		#	FileUtils::rm_f("/tmp/temp.doc")
		#else
			success = system("/usr/bin/wvHtml --targetdir='#{real_target}' '#{filepath}' DOKUMENTINHALT.html")
		#end
		return success 
	end
	
	def rescue_docx(filepath, target_dir)
		target_subdir = target_dir + "/" + File.basename(filepath, ".*") + "_docx"
		real_target = target_subdir
		ct = 0
		while File.directory?(real_target) 
			real_target = target_subdir + "_" + ct.to_s
			ct += 1
		end
		FileUtils::mkdir_p(real_target)
		success = system("unzip -d '#{real_target}' '#{filepath}'")
		return false unless success == true
		return false unless File.exists?("#{real_target}/word/document.xml")
		begin
			xmldoc = Nokogiri::XML(File.read("#{real_target}/word/document.xml"))
			outfile = File.new("#{real_target}/DOKUMENTINHALT.txt", "w")
			outfile.write xmldoc.text 
			outfile.close 
			return true
		rescue
			return false
		end
	end
	
	def rescue_odt(filepath, target_dir)
		target_subdir = target_dir + "/" + File.basename(filepath, ".*") + "_odt"
		real_target = target_subdir
		ct = 0
		while File.directory?(real_target) 
			real_target = target_subdir + "_" + ct.to_s
			ct += 1
		end
		FileUtils::mkdir_p(real_target)
		success = system("unzip -d '#{real_target}' '#{filepath}'")
		return false unless success == true
		return false unless File.exists?("#{real_target}/content.xml")
		begin
			xmldoc = Nokogiri::XML(File.read("#{real_target}/content.xml"))
			outfile = File.new("#{real_target}/DOKUMENTINHALT.txt", "w")
			outfile.write xmldoc.text 
			outfile.close 
			return true
		rescue
			return false
		end
	end
	
	def rescue_other(filepath, target_dir)
		target_subdir = target_dir + "/" + File.basename(filepath, ".*") + "_div"
		real_target = target_subdir
		ct = 0
		while File.directory?(real_target) 
			real_target = target_subdir + "_" + ct.to_s
			ct += 1
		end
		FileUtils::mkdir_p(real_target)
		system("iconv -c -f UTF-16 -t UTF-8//IGNORE '#{filepath}' -o '#{real_target}/DOKUMENTINHALT1.txt'")
		system("iconv -c -f ISO-8859-15 -t UTF-8//IGNORE '#{filepath}' -o '#{real_target}/DOKUMENTINHALT2.txt'")
		# system("strings '#{filepath}' > '#{real_target}/DOKUMENTINHALT3.txt'")
		# Always return true - might be glibberish, we do not know
		return true
	end
	# def create_
	
end
