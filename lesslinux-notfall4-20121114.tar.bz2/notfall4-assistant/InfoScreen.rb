#!/usr/bin/ruby
# encoding: utf-8

class InfoScreen
	def initialize(extlayers, button)
		@layers = Array.new
		infopane = Gtk::Label.new
		infopane.wrap = true
		infopane.set_markup('<span foreground="white">Die <b>COMPUTER BILD Notfall-CD 4.0</b> wurde erstellt von: ...</span>')
		fixed = Gtk::Fixed.new
		fixed.put(infopane, 0, 0)
		
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>Klicken Sie hier, um abzubrechen und zum Startbildschirm zurückzukehren.</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		
		fixed.put(back, 852, 332)
		fixed.put(text4, 630, 338)
		
		extlayers["infobox"] = fixed
		@layers[0] = fixed
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["infobox"].show_all
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["start"].show_all
			end
		}
	
	end
	
	attr_reader :layers

end