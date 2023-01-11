#!/usr/bin/ruby
# encoding: utf-8

class InfoScreen
	def initialize(extlayers, button, nwscreen, scanner=nil, checkscreen=false)
		@extlayers = extlayers 
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@lang = lang
		tlfile = "InfoScreen.xml"
		tlfile = "/etc/lesslinux/branding/InfoScreen.xml" if File.exist?("/etc/lesslinux/branding/InfoScreen.xml")
		
		@tl = MfsTranslator.new(lang, tlfile)
		@nwscreen = nwscreen
		@layers = Array.new
		@checkscreen = checkscreen
		fixed = Gtk::Fixed.new
		
		# Kachel Nutzungsbedingungen
		icon_legal = Gtk::EventBox.new.add  Gtk::Image.new("legal.png")
		text_legal = TileHelpers.create_label("<b>" + @tl.get_translation("lichead") + "</b>\n\n" +@tl.get_translation("licbody") , 250)
		icon_legal.signal_connect("button-release-event") { |x,y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["legal2"].show_all
			end
		}
		
		# Kachel Datenschutzhinweise
		icon_data = Gtk::EventBox.new.add  Gtk::Image.new("legal.png")
		text_data = TileHelpers.create_label("<b>" + @tl.get_translation("datahead") + "</b>\n\n" +@tl.get_translation("databody") , 250)
		icon_data.signal_connect("button-release-event") { |x,y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["legal3"].show_all
			end
		}
		
		# Kachel Updates
		icon_update = Gtk::EventBox.new.add  Gtk::Image.new("updater.png")
		text_update = TileHelpers.create_label("<b>" + @tl.get_translation("updhead") + "</b>\n\n" +@tl.get_translation("updbody") , 250)
		icon_update.signal_connect("button-release-event") { |x,y|
			if nwscreen.test_connection == false
				nwscreen.nextscreen = "infobox"
				nwscreen.fill_wlan_combo 
				extlayers.each { |k,v|v.hide_all }
				extlayers["networks"].show_all
			end
			system("/etc/lesslinux/updater/update_wrapper.sh &")
		}
		# Kachel Mattias Schlenker
		icon_mattias = Gtk::EventBox.new.add  Gtk::Image.new("lesslinux.png")
		text_mattias = TileHelpers.create_label("<b>" + @tl.get_translation("techhead") + "</b>\n\n" +@tl.get_translation("techbody") , 510)
		icon_mattias.signal_connect("button-release-event") { |x,y|
			if y.button == 1 
				TileHelpers.open_browser("http://www.mattiasschlenker.de/") 
			end
		}
		
		# Kachel Jan Sass
		icon_jansass = Gtk::EventBox.new.add  Gtk::Image.new("jansass.png")
		text_jansass = TileHelpers.create_label("<b>" + @tl.get_translation("graphhead") + "</b>\n\n" +@tl.get_translation("graphbody") , 510)
		icon_jansass.signal_connect("button-release-event") { |x,y|
			if y.button == 1 
				TileHelpers.open_browser("http://www.jansass.com/") 
			end
		}

		# Kachel André Hesel
		icon_ahesel = Gtk::EventBox.new.add  Gtk::Image.new("janmattias.png")
		text_ahesel = TileHelpers.create_label("<b>Redaktion: André Hesel</b>\n\nFür die Konzeption und Texte der Notfall-DVD zeichnet Redakteur André Hesel verantwortlich. Sie erreichen André Hesel per Email an ahesel@computerbild.de." , 510)
		icon_ahesel.signal_connect("button-release-event") { |x,y|
			if y.button == 1 
				TileHelpers.open_browser("https://www.computerbild.de/autoren/Andre_Hesel-8830627.html") 
			end
		}

		# Kachel Avira
		
		if scanner == "scancl"
			scantext = "<b>" + @tl.get_translation("avirahead") + "</b>\n\n" + @tl.get_translation("avirabody")
			scanicon = "avira.png"
		elsif scanner == "eset"
			scantext = "<b>" + @tl.get_translation("esethead") + "</b>\n\n" + @tl.get_translation("esetbody")
			scanicon = "eset.png"
		else
			scantext = "<b>" + @tl.get_translation("clamavhead") + "</b>\n\n" + @tl.get_translation("clamavbody") 
			scanicon = "clamav.png"
		end
			
		icon_avira = Gtk::EventBox.new.add  Gtk::Image.new(scanicon)
		text_avira = TileHelpers.create_label(scantext,  250) 
		icon_avira.signal_connect("button-release-event") { |x,y|
			# if y.button == 3
			#	TileHelpers.open_browser("http://www.avira.com/") 
			# end
		}
		
		# Kachel Jan Mattias
		icon_jsms = Gtk::EventBox.new.add  Gtk::Image.new("janmattias.png")
		text_jsms = TileHelpers.create_label("<b>" + @tl.get_translation("exthead") + "</b>\n\n" + @tl.get_translation("extbody"),  250) 
		icon_jsms.signal_connect("button-release-event") { |x,y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["infojanmattias"].show_all
			end
		}
		
		
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" +@tl.get_translation("cancel") + "</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		
		fixed.put(back, 852, 332)
		fixed.put(text4, 605, 338)
		fixed.put(icon_legal, 0, 0)
		fixed.put(text_legal, 130, 0)
		fixed.put(icon_update, 380, 0)
		fixed.put(text_update, 510, 0)
		# fixed.put(icon_mattias, 380, 0)
		# fixed.put(text_mattias, 510, 0)
		# fixed.put(icon_jansass, 0, 0)
		# fixed.put(text_jansass, 130, 0)
		fixed.put(icon_avira, 0, 130)
		fixed.put(text_avira, 130, 130)
		fixed.put(icon_jsms, 380, 130)
		fixed.put(text_jsms, 510, 130)
		unless @lang == "pl" || system("grep S.A.D /etc/lesslinux/branding/branding.en.sh") 
			fixed.put(icon_data, 0, 260)
			fixed.put(text_data, 130, 260)
		end
		
		extlayers["infobox"] = fixed
		@layers[0] = fixed
		
		legallayer = create_legal_screen(extlayers)
		extlayers["legal"] = legallayer
		@layers[1] = legallayer
		
		otherlegallayer = create_other_legal_screen(extlayers)
		extlayers["legal2"] = otherlegallayer
		@layers[2] = otherlegallayer
		
		dsgvolayer = create_dsgvo_screen(extlayers)
		extlayers["legal3"] = dsgvolayer
		@layers[3] = dsgvolayer
		
		jsmslayer = create_jsms_screen(extlayers)
		extlayers["infojanmattias"] = jsmslayer
		@layers[4] = jsmslayer
		
		waitlayer = create_wait_screen
		extlayers["pleasewait"] = waitlayer
		@layers[5] = waitlayer
		
		doclayer = create_docfolderscreen
		extlayers["docfolder"] = doclayer
		@layers[6] = doclayer
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["infobox"].show_all
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
	
	end
	
	def create_jsms_screen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		# Kachel Mattias Schlenker
		icon_mattias = Gtk::EventBox.new.add  Gtk::Image.new("lesslinux.png")
		text_mattias = TileHelpers.create_label("<b>" + @tl.get_translation("techhead") + "</b>\n\n" +@tl.get_translation("techlong") , 510)
		icon_mattias.signal_connect("button-release-event") { |x,y|
			if y.button > 0 
				TileHelpers.open_browser("http://www.mattiasschlenker.de/") 
				sleep 2
				TileHelpers.open_browser("http://blog.lesslinux.org/")
			end
		}
		
		# Kachel Jan Sass
		icon_jansass = Gtk::EventBox.new.add  Gtk::Image.new("jansass.png")
		text_jansass = TileHelpers.create_label("<b>" + @tl.get_translation("graphhead") + "</b>\n\n" +@tl.get_translation("graphlong") , 510)
		icon_jansass.signal_connect("button-release-event") { |x,y|
			if y.button > 0
				TileHelpers.open_browser("http://www.jansass.com/") 
			end
		}
		
		# Kachel André Hesel
		icon_ahesel = Gtk::EventBox.new.add  Gtk::Image.new("janmattias.png")
		text_ahesel = TileHelpers.create_label("<b>" + @tl.get_translation("redhead") + "</b>\n\n" +@tl.get_translation("redlong") , 510)
		icon_ahesel.signal_connect("button-release-event") { |x,y|
			if y.button == 1 
				TileHelpers.open_browser(@tl.get_translation("redlink")) 
			end
		}
		
		fixed.put(icon_mattias, 0, 0)
		fixed.put(text_mattias, 130, 0)
		fixed.put(icon_jansass, 0, 130)
		fixed.put(text_jansass, 130, 130)
		fixed.put(icon_ahesel, 0, 260)
		fixed.put(text_ahesel, 130, 260)
		
		
		return fixed
	end
		
		
	
	def create_legal_screen(extlayers)
		fixed = Gtk::Fixed.new
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("licdecline") + "</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("licaccept") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		
		disctext = "Ooops nicht gefunden!"
		if File.exist?("/etc/lesslinux/branding/legal.#{@lang}.txt")
			disctext = File.new("/etc/lesslinux/branding/legal.#{@lang}.txt").read
		elsif File.exist?("legal.#{@lang}.txt")
			disctext = File.new("legal.#{@lang}.txt").read
		elsif File.exist?("haftung.txt")
			disctext = File.new("haftung.txt").read
		end
		disclabel = Gtk::Label.new
		disclabel.set_markup("<span color='white'>" + @tl.get_translation("licheader") + "</span>")
		fat_font = Pango::FontDescription.new("Sans Bold 14")
		disclabel.modify_font(fat_font)
		textview = Gtk::TextView.new
		textview.buffer.text = disctext
		textview.set_wrap_mode(Gtk::TextTag::WRAP_WORD)
		scrolled_win = Gtk::ScrolledWindow.new
		scrolled_win.border_width = 5
		scrolled_win.add(textview)
		scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
		textview.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		
		# scrolled_win.add(textview)
		scrolled_win.set_size_request(700, 330)
		
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("touch /var/run/lesslinux/license_accepted") 
				extlayers.each { |k,v|v.hide_all }
				if @checkscreen == false
					TileHelpers.back_to_group
				else
					extlayers["checkscreen"].show_all 
				end
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("/usr/bin/shutdown-wrapper.sh") 
			end
		}
		fixed.put(disclabel, 0, 3)
		fixed.put(scrolled_win, 0, 40)
		TileHelpers.place_back(fixed, extlayers)
		#fixed.put(forw, 853, 282)
		#fixed.put(text5, 605, 288)
		#fixed.put(back, 852, 332)
		#fixed.put(text4, 605, 338)
		return fixed 
	end
	
	def create_other_legal_screen(extlayers)
		fixed = Gtk::Fixed.new
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("licdecline") + "</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("licaccept") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		
		disctext = "Ooops nicht gefunden!"
		if File.exist?("/etc/lesslinux/branding/legal.#{@lang}.txt")
			disctext = File.new("/etc/lesslinux/branding/legal.#{@lang}.txt").read
		elsif File.exist?("legal.#{@lang}.txt")
			disctext = File.new("legal.#{@lang}.txt").read
		elsif File.exist?("haftung.txt")
			disctext = File.new("haftung.txt").read
		end
		
		disclabel = Gtk::Label.new
		disclabel.set_markup("<span color='white'>" + @tl.get_translation("licheader") + "</span>")
		fat_font = Pango::FontDescription.new("Sans Bold 14")
		disclabel.modify_font(fat_font)
		textview = Gtk::TextView.new
		textview.buffer.text = disctext
		textview.set_wrap_mode(Gtk::TextTag::WRAP_WORD)
		scrolled_win = Gtk::ScrolledWindow.new
		scrolled_win.border_width = 5
		scrolled_win.add(textview)
		scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
		textview.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		
		# scrolled_win.add(textview)
		scrolled_win.set_size_request(700, 330)
		
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("touch /var/run/lesslinux/license_accepted") 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("/usr/bin/shutdown-wrapper.sh") 
			end
		}
		fixed.put(disclabel, 0, 3)
		fixed.put(scrolled_win, 0, 40)
		#fixed.put(forw, 853, 282)
		#fixed.put(text5, 605, 288)
		#fixed.put(back, 852, 332)
		#fixed.put(text4, 605, 338)
		TileHelpers.place_back(fixed, extlayers)
		return fixed 
	end	
	
	def create_dsgvo_screen(extlayers)
		fixed = Gtk::Fixed.new
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("licdecline") + "</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("licaccept") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		
		disctext = "Ooops nicht gefunden!"
		if File.exist?("/etc/lesslinux/branding/dataprotection.#{@lang}.txt")
			disctext = File.new("/etc/lesslinux/branding/dataprotection.#{@lang}.txt").read
		elsif File.exist?("dataprotection.#{@lang}.txt")
			disctext = File.new("dataprotection.#{@lang}.txt").read
		elsif File.exist?("datenschutz.txt")
			disctext = File.new("datenschutz.txt").read
		end
		
		disclabel = Gtk::Label.new
		disclabel.set_markup("<span color='white'>" + @tl.get_translation("dataheader") + "</span>")
		fat_font = Pango::FontDescription.new("Sans Bold 14")
		disclabel.modify_font(fat_font)
		textview = Gtk::TextView.new
		textview.buffer.text = disctext
		textview.set_wrap_mode(Gtk::TextTag::WRAP_WORD)
		scrolled_win = Gtk::ScrolledWindow.new
		scrolled_win.border_width = 5
		scrolled_win.add(textview)
		scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
		textview.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		
		# scrolled_win.add(textview)
		scrolled_win.set_size_request(700, 330)
		
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("touch /var/run/lesslinux/license_accepted") 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("/usr/bin/shutdown-wrapper.sh") 
			end
		}
		fixed.put(disclabel, 0, 3)
		fixed.put(scrolled_win, 0, 40)
		#fixed.put(forw, 853, 282)
		#fixed.put(text5, 605, 288)
		#fixed.put(back, 852, 332)
		#fixed.put(text4, 605, 338)
		TileHelpers.place_back(fixed, extlayers)
		return fixed 
	end	
	
	def create_wait_screen
		fixed = Gtk::Fixed.new
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("pleasewait") + "</span>")
		fixed.put(text4, 260, 65)
		icon_wait = Gtk::EventBox.new.add  Gtk::Image.new("pleasewait.png")
		fixed.put(icon_wait, 130, 65)
		return fixed 
	end
	
	def create_docfolderscreen 
		fixed = Gtk::Fixed.new
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("systestneutral.png")
		# deltext = TileHelpers.create_label("<b>" + @tl.get_translation("sysprofiledonehead") + "</b>\n\n" + @tl.get_translation("sysprofiledonebody"), 510)
		#text4 = Gtk::Label.new
		#text4.width_request = 250
		#text4.wrap = true
		#text4.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		#fixed.put(back, 650, 402)
		#fixed.put(text4, 402, 408)
		TileHelpers.place_back(fixed, @extlayers)
		infolabel = TileHelpers.create_label("<b>" + @tl.get_translation("docqrhead") + "</b>\n\n" +@tl.get_translation("docqrbody") , 510)
		fixed.put(infolabel, 0, 0)
		qrimage  = Gtk::EventBox.new.add Gtk::Image.new("qralle.png")
		fixed.put(qrimage, 0, 100)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotofilemanager") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		forw.signal_connect("button-release-event") { |x, y|
			if y.button == 1 
				system('su surfer -c "Thunar /home/surfer/Desktop/Anleitungen" &')
			end
		}
		qrimage.signal_connect("button-release-event") { |x, y|
			if y.button == 1 
				system('su surfer -c "Thunar /home/surfer/Desktop/Anleitungen" &')
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		return fixed
	end
	
	attr_reader :layers

end