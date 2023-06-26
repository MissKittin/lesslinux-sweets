#!/usr/bin/ruby
# encoding: utf-8

class RescueScreen	
	def initialize(extlayers, button)
		
		### First panel, selection of tasks
		# First tile, rescue on file system level
		button1 = Gtk::EventBox.new.add Gtk::Image.new("neutralwine.png")
		text1 = Gtk::Label.new
		text1.width_request = 380
		text1.wrap = true
		text1.set_markup("<span foreground='white'><b>Daten lokal sichern:</b> Sie erhalten Zugriff auf alle Laufwerke und können mit zwei Dateimanager-Fenstern Daten zwischen den Laufwerken kopieren. Schließen Sie USB- und eSATA-Platten an, bevor Sie diese Option auswählen.</span>")
	
		# Second tile, rescue to cloud
		button2 = Gtk::EventBox.new.add Gtk::Image.new("neutralturq.png")
		text2 = Gtk::Label.new
		text2.width_request = 380
		text2.wrap = true
		text2.set_markup("<span foreground='white'><b>Daten in die COMPUTER BILD Cloud sichern:</b> Sie erhalten Zugriff auf alle Laufwerke und können in einem Firefox-Fenster Daten auf Ihr COMPUTER BILD Cloud Konto hochladen.</span>")
		
		# Third tile, image 1:1
		button3 = Gtk::EventBox.new.add Gtk::Image.new("neutralorange.png")
		text3 = Gtk::Label.new
		text3.width_request = 380
		text3.wrap = true
		text3.set_markup("<span foreground='white'><b>1:1 Kopie einer Festplatte:</b> Wählen Sie diese Option im Falle drohender Hardwaredefekte. Die ausgewählte Festplatte wird dabei bitgetreu auf das Ziellaufwerk kopiert. Alle auf dem Ziellaufwerk gespeicherten gespeicherten Daten werden überschrieben!</span>.")
		
		@layers = Array.new
		fixed = Gtk::Fixed.new
		fixed.put(button1, 0, 0)
		fixed.put(button2, 0, 130)
		fixed.put(button3, 0, 260)
		fixed.put(text1, 130, 28)
		fixed.put(text2, 130, 170)
		fixed.put(text3, 130, 280)
		
		TileHelpers.place_back(fixed, extlayers)
		extlayers["rescuestart"] = fixed
		@layers[0] = fixed
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["rescuestart"].show_all
			end
		}

	end
	attr_reader :layers
	
end