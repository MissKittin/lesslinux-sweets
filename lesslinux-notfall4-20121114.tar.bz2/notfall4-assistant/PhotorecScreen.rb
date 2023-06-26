#!/usr/bin/ruby
# encoding: utf-8

class PhotorecScreen	
	def initialize(extlayers, button)
		@layers = Array.new
		
		fixed = Gtk::Fixed.new
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>Klicken Sie hier, um mit Ihren Einstellungen fortzufahren.</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		fixed.put(forw, 853, 282)
		fixed.put(text5, 630, 288)
		TileHelpers.place_back(fixed, extlayers)
		extlayers["photorecstart"] = fixed
		@layers[0] = fixed
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["photorecstart"].show_all
			end
		}
		
		
		
	end
	
	attr_reader :layers
end