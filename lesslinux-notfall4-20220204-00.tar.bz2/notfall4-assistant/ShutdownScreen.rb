#!/usr/bin/ruby
# encoding: utf-8

class InfoScreen
	def initialize(extlayers, button)
		@layers = Array.new
		infopane = Gtk::Label.new
		infopane.wrap = true
		infopane.set_markup('<span foreground="white">Die <b>COMPUTER BILD Notfall-DVD 5.0</b> wurde erstellt von: ...</span>')
		back = Gtk::Button.new("Zurück")
		fixed = Gtk::Fixed.new
		fixed.put(infopane, 0, 0)
		fixed.put(back, 700, 300)
		extlayers["infobox"] = fixed
		@layers[0] = fixed
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|
					if v == extlayers["infobox"] 
						v.show_all
					else
						v.hide_all
					end
				}
			end
		}
		back.signal_connect('clicked') {
			extlayers.each { |k,v|
				if v == extlayers["start"] 
					v.show_all
				else
					v.hide_all
				end
			}
		}
	end
	
	attr_reader :layers

end