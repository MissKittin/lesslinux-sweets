#!/usr/bin/ruby
# encoding: utf-8

class TileHelpers
	def TileHelpers.place_back(panel, layers)
		text = Gtk::Label.new
		text.width_request = 250
		text.wrap = true
		text.set_markup("<span color='white'>Klicken Sie hier, um abzubrechen und zum Startbildschirm zurückzukehren.</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		panel.put(back, 852, 332)
		panel.put(text, 630, 338)
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				layers.each { |k,v|v.hide_all }
				layers["start"].show_all
			end
		}
	end
end
