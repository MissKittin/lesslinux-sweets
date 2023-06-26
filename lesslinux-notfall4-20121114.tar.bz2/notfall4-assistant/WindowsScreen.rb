#!/usr/bin/ruby
# encoding: utf-8

class WindowsScreen	
	def initialize(extlayers, button)
		@layers = Array.new
		button1 = Gtk::EventBox.new.add Gtk::Image.new("neutralorange.png")
		button2 = Gtk::EventBox.new.add Gtk::Image.new("neutralwine.png")
		button3 = Gtk::EventBox.new.add Gtk::Image.new("neutralpurple.png")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		
		text1 = Gtk::Label.new
		text1.width_request = 380
		text1.wrap = true
		text1.set_markup("<span foreground='white'>Windows startet zwar, stürzt aber nach einer Weile ab oder friert ein.</span>")
		
		text2 = Gtk::Label.new
		text2.width_request = 380
		text2.wrap = true
		text2.set_markup("<span foreground='white'>Windows startet nicht, es erscheint stattdessen <b>\"NTLDR fehlt\"</b></span>")
		
		text3 = Gtk::Label.new
		text3.width_request = 380
		text3.wrap = true
		text3.set_markup("<span foreground='white'>Windows startet nicht, es erscheinen Fehlermeldungen wie <b>\"No operating system found\"</b>, <b>\"Kein System gefunden\"</b> oder <b>\"Please insert a bootable media\"</b></span>.")
		
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>Klicken Sie hier, um abzubrechen und zum Startbildschirm zurückzukehren.</span>")
		
		fixed = Gtk::Fixed.new
		fixed.put(button1, 0, 0)
		fixed.put(button2, 0, 130)
		fixed.put(button3, 0, 260)
		fixed.put(back, 852, 332)
		
		fixed.put(text1, 130, 50)
		fixed.put(text2, 130, 180)
		fixed.put(text3, 130, 290)
		fixed.put(text4, 630, 338)
		
		@layers[0] = fixed
		extlayers["winfixstart"] = fixed 
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["winfixstart"].show_all
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["start"].show_all
			end
		}
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["winfixntldr"].show_all
			end
		}
		
		# Panel for NTLDR ...
		
		ntldrpane = Gtk::Fixed.new
		ntldrtext = Gtk::Label.new
		ntldrtext.width_request = 640
		ntldrtext.wrap = true
		ntldrtext.set_markup("<span foreground='white'>Die Meldung <b>\"NTLDR fehlt\"</b> kann verschiedene Ursachen haben. Meist lässt sich das Problem aber leicht beheben. Da die Notfall-CD dies nicht automatisch erledigen kann, müssen Sie selbst tätig werden. Befolgen Sie dazu einfach die entsprechende Anleitung für Ihre Windows-Version. Diese können Sie sich hier anzeigen lassen oder auf einem anderen Computer ausdrucken. In diesem Fall finden Sie die Hilfetexte im Ordner \"Anleitungen\" auf der CD. Bevor Sie die Anleitung durchführen, starten Sie Ihren Computer neu.</span>")
		textxp = Gtk::Label.new
		textxp.width_request = 120
		textxp.wrap = true
		textxp.set_markup("<span foreground='white'>Anleitung für Windows XP anzeigen</span>")
		text7 = Gtk::Label.new
		text7.width_request = 120
		text7.wrap = true
		text7.set_markup("<span foreground='white'>Anleitung für Windows Vista und höher anzeigen</span>")
		manualxp = Gtk::EventBox.new.add Gtk::Image.new("neutralpurple.png")
		manual7 = Gtk::EventBox.new.add Gtk::Image.new("neutralorange.png")
		checkhd = Gtk::EventBox.new.add Gtk::Image.new("neutralwine.png")
		checktext = Gtk::Label.new
		checktext.width_request = 510
		checktext.wrap = true
		checktext.set_markup("<span foreground='white'>Falls die Anleitung bei Ihnen nicht hilft und die Probleme weiterhin bestehen, kann auch ein Festplattenproblem vorliegen. Klicken Sie hier zum Überprüfen aller Festplatten.</span>")
		back2 = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>Klicken Sie hier, um abzubrechen und zum Startbildschirm zurückzukehren.</span>")
		
		ntldrpane.put(ntldrtext, 0, 0)
		ntldrpane.put(manualxp, 0, 130)
		ntldrpane.put(manual7, 260, 130)
		ntldrpane.put(textxp, 130, 162)
		ntldrpane.put(text7, 390, 162)
		ntldrpane.put(checkhd, 0, 260)
		ntldrpane.put(checktext, 130, 292)
		ntldrpane.put(back2, 852, 332)
		ntldrpane.put(text5, 630, 338)
		
		@layers[1] = ntldrpane
		extlayers["winfixntldr"] = ntldrpane 
		
		back2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["start"].show_all
			end
		}
		
		
	end
	
	attr_reader :layers
	
end