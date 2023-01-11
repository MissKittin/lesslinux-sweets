#!/usr/bin/ruby
# encoding: utf-8

class MozillaRecoverScreen	
	def initialize(extlayers)
		# Create the start panel
		@keytext = "Hallo Welt!"
		@textview = Gtk::TextView.new
		@headerlines = []
		@detaillines = [] 
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "MozillaRecoverScreen.xml")
		@layers = Array.new
		# First panel with warning
		infopane = Gtk::Label.new
		infopane.width_request = 510
		infopane.wrap = true
		infopane.set_markup("<span foreground='white'><b>" + @tl.get_translation("recoverhead") + "</b>\n\n" + @tl.get_translation("recoverbody") + "</span>")
		fixed = Gtk::Fixed.new
		
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		forwtext = TileHelpers.create_label(@tl.get_translation("gotokeys"), 220)
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		cancelbutton = TileHelpers.place_back(fixed, extlayers)
		# fixed.put(text4, 402, 408)
		fixed.put(infopane, 0, 20)
		fixed.put(forw, 650, 352)
		fixed.put(forwtext, 402, 358)
		
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				TileHelpers.set_lock
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				@headerlines = []
				@detaillines = [] 
				retrievekeys
				@textview.buffer.text = @headerlines.join("\n") + "\n" + @detaillines.join("\n") 
				extlayers.each { |k,v|v.hide_all }
				extlayers["mozillashow"].show_all
				TileHelpers.remove_lock
			end
		}
		
		extlayers["mozillaquest"] = fixed
		@layers[0] = fixed
		prepare_resultscreen(extlayers)
	end
	attr_reader :layers 
	
	def prepare_resultscreen(extlayers)
		infopane = Gtk::Label.new
		infopane.width_request = 510
		infopane.wrap = true
		infopane.set_markup("<span foreground='white'><b>" + @tl.get_translation("recoverdonehead") + "</b>\n\n" + @tl.get_translation("recoverdonebody") + "</span>")
		fixed = Gtk::Fixed.new
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		cancelbutton = TileHelpers.place_back(fixed, extlayers)
		# fixed.put(text4, 402, 408)
		fixed.put(infopane, 0, 20)
		
		@textview.buffer.text = @keytext
		@textview.set_wrap_mode(Gtk::TextTag::WRAP_WORD)
		scrolled_win = Gtk::ScrolledWindow.new
		scrolled_win.border_width = 5
		scrolled_win.add(@textview)
		scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
		@textview.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		forwtext = TileHelpers.create_label(@tl.get_translation("openeditor"), 220)

		# scrolled_win.add(textview)
		scrolled_win.set_size_request(510, 190)
		fixed.put(scrolled_win, 0, 200)
		#fixed.put(forw, 650, 352)
		#fixed.put(forwtext, 402, 350)
		extlayers["mozillashow"] = fixed
		@layers[1] = fixed
		
		#forw.signal_connect('button-release-event') { |x, y|
		#	if y.button == 1 
		#		outfile = File.new("/tmp/winkeys.txt", "w")
		#		outfile.write("# encoding: utf-8\n")
		#		outfile.write(@keytext)
		#		outfile.close
		#		system("scite /tmp/winkeys.txt &")
		#	end
		#}
	end
	
	def retrievekeys
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ || l =~ /mmcblk[0-9]$/
		}
		drives.each { |d|
			d.partitions.each { |p|
				if p.fs =~ /ntfs/i 
					system("mkdir -p /media/disk/#{p.device}")
					p.mount("ro", "/media/disk/#{p.device}", 1000, 1000)
					IO.popen("find /media/disk/#{p.device}/Users -type f -name profiles.ini") { |l|
						while l.gets 
							line = $_.strip.gsub("/profiles.ini", "")
							puts "FOUND PROFILE FOLDER: #{line}"
							list_mozilla_profiles(line)
						end	
					}
					p.umount
				end
			}
		}
	end
	
	def list_mozilla_profiles(path)
		profs = []
		IO.popen("python2 /usr/share/lesslinux/firefox_decrypt-0.7.0/firefox_decrypt.py -l \"#{path}\"")  { |l|
			while l.gets 
				ltoks = $_.strip.split("->") 
				puts ltoks[0].strip + " === " + ltoks[1].strip.gsub("Profiles/", "")
				profs.push(ltoks[1].strip.gsub("Profiles/", "")) unless ltoks[0].nil? 
			end
		}
		idx = 1
		profs.each { |p|
			savep = check_profiles(path, p, idx)
			idx += 1
			if savep.nil? 
				@headerlines.push(path + ", " + p + " <- NSS ERROR, siehe Details")
			elsif savep == true
				@headerlines.push(path + ", " + p + " <- sicheres Profil")
			else
				@headerlines.push(path + ", " + p + " <- unsicheres Profil")
			end
		}
	end
	
	def check_profiles(path, p, idx) 
		save_prof = false
		IO.popen("bash wrap_decode_err.sh \"#{path}\" \"#{idx}\"") { |l|
			while l.gets 
				save_prof = true if $_.strip.split =~ /ERROR(.*?)master(.*?)password/i 
				save_prof = nil if $_.strip.split =~ /ERROR(.*?)NSS/i 
			end
		}
		if save_prof == false
			@detaillines.push("\n" + path + ", " + p + ", DETAILS:")
			IO.popen("bash wrap_decode.sh \"#{path}\" \"#{idx}\"") { |l|
				while l.gets
					line = $_.strip
					@detaillines.push(line)
					puts "GOT LINE: #{line}"
				end
			}
		elsif save_prof.nil?
			@detaillines.push("\n" + path + ", " + p + ", DETAILS:\n")
			@detaillines.push("Das Sicherheitsniveau konnte nicht ermittelt werden, Ursache hierfür ist meist eine inkompatible Version der NSS-Bibliothek. Die untersuchte Installation des Mozilla-Programmes ist deutlich neuer als die Notfall-DVD. Bitte prüfen Sie auf Updates und informieren Sie ggf. den Entwickler: ms@mattiasschlenker.de.")
		end
		return save_prof
	end
end
