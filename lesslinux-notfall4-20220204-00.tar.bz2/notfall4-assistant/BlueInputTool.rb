#!/usr/bin/ruby
# encoding: utf-8

class BlueInputTool

	def initialize 
		@busydevices = Array.new 
		@lastline = 0
		@lastcol = 0 
		@pairdevice = nil
		@running = false 
		
		@vte = Vte::Terminal.new
		@vte.set_size(80, 25)  
		@vte.set_scrollback_lines 65536
		@vte.fork_command("bluetoothctl", [ "bluetoothctl"] ) 
		
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "BlueInputTool.xml")
	end
	
	def connect_everything
		return true if @running == true 
		@running = true 
		@vte.feed_child("power on\n")
		@vte.feed_child("agent on\n")
		@vte.feed_child("default-agent\n")
		@vte.feed_child("pairable on\n")
		@vte.feed_child("scan on\n")
		# Run for max 30 minutes
		i = 1
		while i < 3600 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			c,r = @vte.cursor_position
			puts c.to_s + " " + r.to_s 
			if r > @lastline 
				numrows = r - @lastline
				txt = @vte.get_text_range( r - numrows - 1, 0, r - 1, 79, false) 
				inline = @vte.get_text_range( r, 0, r , 79, false) 
				analyze_buffer(txt, inline)
				@lastline = r 
			end	
			if i % 120 == 0
				@vte.feed_child("scan on\n")
			end
			sleep 0.5
			i += 1
		end
	end

	def analyze_buffer(txt, inline)
		# @pairdevice 
		puts "Text:\n" + txt
		puts "Input line:\n" + inline
		lines = txt.split("\n") 
		if inline =~ /Confirm passkey/ 
			@vte.feed_child("no\n")
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		if inline =~ /Enter PIN code/
			@vte.feed_child("000000\n")
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		lines.each{ |l|
			if l =~ /Passkey\:\s([0-9]+)/ 
				pin_dialog($1)
			end	
			if l =~ /Pairing successful/
				@vte.feed_child("trust #{@pairdevice}\n")
				sleep 1.0
				@vte.feed_child("connect #{@pairdevice}\n")
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
			end
			if l =~ /Icon\:\sinput-mouse/
				label.text = "Found mouse, trying to connect #{@pairdevice}"
				@vte.feed_child("pair #{@pairdevice}\n")
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
			end
			if l =~ /Icon\:\sinput-keyboard/
				label.text = "Found keyboard, trying to connect #{@pairdevice}"
				@vte.feed_child("pair #{@pairdevice}\n")
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
			end
			if l =~ /^\[NEW\]/ 
				@pairdevice = l.split[2]
				@vte.feed_child("info #{@pairdevice}\n")
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
			end
			if l =~ /Enter PIN code/
				@vte.feed_child("000000\n")
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
			end
		}
	end
	
	def pin_dialog(pin)
		dialog = Gtk::Dialog.new(@tl.get_translation("pinhead"),
                             $main_application_window,
                             Gtk::Dialog::DESTROY_WITH_PARENT,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ])
		dialog.signal_connect('response') { dialog.destroy }
		label = Gtk::Label.new
		label.wrap = true
		label.set_markup( @tl.get_translation("please_enter") ) 
		pinlabel = Gtk::Label.new
		pinlabel.set_markup("<big><big><big><b>" + pin + "</b></big></big></big>")
		entry = Gtk::Entry.new
		[ label, pinlabel, entry ].each { |w|
			w.width_request = 300
			dialog.vbox.add(w)
		}
		dialog.show_all
	end
	
end
