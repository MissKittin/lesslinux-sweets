#!/usr/bin/ruby
# encoding: utf-8

class AntibotFinishFrame	
	def initialize(assi)
		@infected = nil
		@scanner = nil
		@int_drives = nil
		@ext_drives = nil
		@assistant = assi
		@wdgt = Gtk::Alignment.new(0.5, 0.5, 0.8, 0.0)
		@vbox = Gtk::VBox.new(false, 5)
		@children = Array.new
		@children.push(Gtk::Label.new("Preparing text for display..."))
		@children[0].wrap = true
		[ 0 ].each { |n| @children[n].width_request = 540 } 
		@children.each { |w|
			@vbox.pack_start(w, true, false, 0)
		}
		@wdgt.add @vbox
	end
	attr_reader :wdgt
	
end