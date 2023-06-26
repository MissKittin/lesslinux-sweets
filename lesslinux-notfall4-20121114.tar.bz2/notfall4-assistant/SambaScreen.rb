#!/usr/bin/ruby
# encoding: utf-8

class SambaScreen	
	def initialize(extlayers, button)
		@layers = Array.new
		# First panel with warning
		infopane = Gtk::Label.new
		infopane.width_request = 500
		infopane.wrap = true
		infopane.set_markup('<span foreground="white">Klicken Sie jetzt hier, um alle angeschlossenen Festplatten lesbar einzubinden und als Windows-Freigabe in Ihrem Heimnetz freizugeben. <b>Der Zugriff ist ohne Passwort möglich!</b> Sie können anschließend die auf diesem Rechner gespeicherten Daten über das Netzwerk kopieren.</span>')
		fixed = Gtk::Fixed.new
		# Second panel with possibility to cancel
		cancelpane = Gtk::Label.new
		cancelpane.width_request = 500
		cancelpane.wrap = true
		cancelpane.set_markup("<span color='white'>Klicken Sie hier, um abzubrechen und zum Startbildschirm zurückzukehren.</span>")
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>Klicken Sie hier, um abzubrechen und zum Startbildschirm zurückzukehren.</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		
		# fixed.put(back, 700, 300)
		# fixed.put(forw, 770, 300)
		
		
		infogreen = Gtk::EventBox.new.add Gtk::Image.new("neutralgreen.png")
		infored = Gtk::EventBox.new.add Gtk::Image.new("neutralred.png")
		
		fixed.put(infogreen, 0, 130)
		# fixed.put(infored, 0, 130)
		fixed.put(infopane, 135, 150)
		# fixed.put(cancelpane, 135, 170)
		fixed.put(text4, 630, 338)
		fixed.put(back, 852, 332)
		
		extlayers["sambaquest"] = fixed
		@layers[0] = fixed
		
		
		
		# Second panel stop server
		stoppane = Gtk::Label.new
		stoppane.width_request = 500
		stoppane.wrap = true
		stoppane.set_markup("<span foreground='white'>Aktuell sind alle Festplatten in diesem Rechner als Windows-Netzlaufwerk <b>ohne Passwort</b> freigegeben, der Servername lautet <b>NOTFALL-CD</b> und befindet sich in der Arbeitsgruppe <b>COMPUTERBILD</b>. Zugriff ist auch über die IP-Adresse <b>12.34.56.78</b> möglich. \n \n Klicken Sie auf \"Zurück\", um die Freigabe zu beenden und zum Hauptmenü zu gelangen.</span>")
		stopbutton = Gtk::EventBox.new.add Gtk::Image.new("neutralturq.png")
		
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>Klicken Sie hier, um abzubrechen und zum Startbildschirm zurückzukehren.</span>")
		back2 = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		
		fixed2 = Gtk::Fixed.new
		fixed2.put(stoppane, 135, 130)
		fixed2.put(stopbutton, 0, 130)
		fixed2.put(text5, 630, 338)
		fixed2.put(back2, 852, 332)
		
		extlayers["sambarunning"] = fixed2
		@layers[1] = fixed2
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["sambaquest"].show_all
			end
		}
		infored.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["start"].show_all
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["start"].show_all
			end
		}
		stopbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				puts "Stopping SAMBA"
				extlayers["start"].show_all
			end
		}
		back2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				puts "Stopping SAMBA"
				extlayers["start"].show_all
			end
		}
		infogreen.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				puts "Starting SAMBA"
				extlayers["sambarunning"].show_all
			end
		}
		
		
		
		
		#forw.signal_connect('clicked') {
		#	extlayers.each { |k,v| v.hide_all }
		#	# Mount drives ... 
		#	# Start Samba here ...
		#	puts "Starting Samba"
		#	extlayers["sambarunning"].show_all
		#}
		
	end
	
	attr_reader :layers
	
end