#!/usr/bin/ruby
# encoding: utf-8

require 'hivex'

class LicenseRecoverScreen	
	def initialize(extlayers)
		# Create the start panel
		@winkeys = []
		@keytext = "Hallo Welt!"
		@textview = Gtk::TextView.new
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "LicenseRecoverScreen.xml")
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
		fixed.put(text4, 402, 408)
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
				retrievekeys
				extlayers.each { |k,v|v.hide_all }
				extlayers["licenseshow"].show_all
				TileHelpers.remove_lock
			end
		}
		
		extlayers["licensequest"] = fixed
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
		fixed.put(text4, 402, 408)
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
		scrolled_win.set_size_request(510, 170)
		fixed.put(scrolled_win, 0, 170)
		fixed.put(forw, 650, 352)
		fixed.put(forwtext, 402, 350)
		extlayers["licenseshow"] = fixed
		@layers[1] = fixed
		
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				outfile = File.new("/tmp/winkeys.txt", "w")
				outfile.write("# encoding: utf-8\n")
				outfile.write(@keytext)
				outfile.close
				system("scite /tmp/winkeys.txt &")
			end
		}
		
	end
	
	def retrievekeys 
		@winkeys = []
		@keytext = ""
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ || l =~ /mmcblk[0-9]$/
		}
		drives.each { |d|
			d.partitions.each { |p|
				system("mkdir -p /media/disk/#{p.device}")
				p.mount("ro", "/media/disk/#{p.device}", 1000, 1000)
				r = p.regfile
				unless r.nil?
					puts "Mountpoint: " + r.partition.mount_point[0]
					puts "RegistryHive: " + r.regfile
					nextkey = decode_winkey(r.partition.mount_point[0] + "/" + r.regfile)
					if $lang == "pl" 
						@keytext = @keytext + "Klucz produktu Windows: " + nextkey + "\n" if $lang == "pl"
					elsif $lang == "de" 
						@keytext = @keytext + "Windows-Schlüssel: " + nextkey + "\n"
					else
						@keytext = @keytext + "Windows key: " + nextkey + "\n"
					end
				end
				p.umount
			}
		}
		if @keytext.strip == ""
			if $lang == "de" 
				keytext = "Keine Schlüssel gefunden" 
			else
				keytext = "No keys found"
			end
		end
		@textview.buffer.text = @keytext
	end
	
	def decode_winkey(regfile)
		key = ""
		h = Hivex::open(regfile, { :write => 0}) 
		root = h.root()
		node = h.node_get_child(root, "Microsoft")
		node = h.node_get_child(node, "Windows NT")
		node = h.node_get_child(node, "CurrentVersion")
		keyobj = h.node_get_value(node, "DigitalProductId")
		hsh = h.value_value(keyobj)[:value]
		h.close
		digProdId = hsh.bytes.to_a
		key = ""
		keyoffset = 52
		iswin8 = (digProdId[66] / 6) & 1
		# puts iswin8
		digProdId[66] = (digProdId[66] & 0xf7) | (iswin8 & 2) * 4
		# puts digProdId[66]
		digits = "BCDFGHJKMPQRTVWXY2346789";
		last = 0
		24.downto(0) { |i|
			current = 0
			14.downto(0) { |j|
				current = current * 256
				current = digProdId[j + keyoffset] + current
				digProdId[j + keyoffset] = (current / 24) % 255
				current = current % 24
				last = current
				# puts digProdId[j + keyoffset]
				# puts current
			}
			key = digits[current] + key
			puts key 
		}
		puts last
		keypart1 = key[1,last]
		keypart2 = key[last + 1, key.length - (last + 1)];
		key = keypart1 + "N" + keypart2
		outk = ""
		0.upto(key.length - 1) { |n|
			outk += "-" if (n%5 == 0 && n>0)
			outk += key[n]
		}
		return outk
	end
end
	