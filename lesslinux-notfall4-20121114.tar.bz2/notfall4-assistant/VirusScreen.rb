#!/usr/bin/ruby
# encoding: utf-8

class VirusScreen	
	def initialize(extlayers, button)
		@layers = Array.new
		fixed = Gtk::Fixed.new
		
		TileHelpers.place_back(fixed, extlayers)
		extlayers["virusstart"] = fixed
		@layers[0] = fixed
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["virusstart"].show_all
			end
		}
		
		
		
	end
	attr_reader :layers
	
end