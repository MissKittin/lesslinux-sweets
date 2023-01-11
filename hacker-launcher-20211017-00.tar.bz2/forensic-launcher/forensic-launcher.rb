#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'vte'
require "rexml/document"
require 'optparse'

Gtk.init

window = Gtk::Window.new
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.set_size_request(1020, 630)
window.border_width = 0
window.deletable = false
window.decorated = false
window.allow_grow = false
window.allow_shrink = false
window.title = "Hacker Tools 2020"
window.signal_connect('delete_event') { false }
window.signal_connect('destroy') { 
	# system("rm /var/run/lesslinux/assistant_running")
	Gtk.main_quit
}

bgimg = Gtk::Image.new("images/winbg.png")
fixed = Gtk::Fixed.new
fixed.put(bgimg, 0, 0)
minimize = Gtk::EventBox.new.add(Gtk::Image.new("images/minimize.png"))
# fixed.put(minimize, 0, 0)
minimize.signal_connect('button_release_event') {
	puts "Minimize"
	window.iconify
}

# Add buttons top
topbuttons = [
	Gtk::EventBox.new.add(Gtk::Image.new("images/button_off.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/button_network.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/button_usb.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/button_teamviewer.png")),
]
topboffsets = [ 873, 909, 947, 970 ]
topbcommandstrings = [ 
	"shutdown-wrapper.sh",
	"connman-gtk",
	"exo-open /usr/share/applications/060_usbinstall.desktop",
	"exo-open /usr/share/applications/teamviewer.desktop"
]

# Add buttons left
leftbuttons = [
	Gtk::EventBox.new.add(Gtk::Image.new("images/menu1.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/menu2.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/menu3.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/menu4.png")),
	#Gtk::EventBox.new.add(Gtk::Image.new("images/menu5.png")),
	#Gtk::EventBox.new.add(Gtk::Image.new("images/menu6.png"))
]
rightimages = [
	[
		"images/HACK-GUI-main-1-0.png",
		"images/HACK-GUI-main-1-1.png",
		"images/HACK-GUI-main-1-2.png",
		"images/HACK-GUI-main-1-3.png" ],
	[
		"images/HACK-GUI-main-2-0.png",
		"images/HACK-GUI-main-2-1.png",
		"images/HACK-GUI-main-2-2.png",
		"images/HACK-GUI-main-2-3.png" ],
	[
		"images/HACK-GUI-main-3-0.png",
		"images/HACK-GUI-main-3-1.png",
		"images/HACK-GUI-main-3-2.png",
		"images/HACK-GUI-main-3-3.png",
		"images/HACK-GUI-main-3-4.png" ],
	[
		"images/HACK-GUI-main-4-0.png",
		"images/HACK-GUI-main-4-1.png",
		"images/HACK-GUI-main-4-2.png",
		"images/HACK-GUI-main-4-3.png" ],
	#[
	#	"images/HACK-GUI-main-5-0.png",
	#	"images/HACK-GUI-main-5-1.png" ],
	#[
	#	"images/HACK-GUI-main-6-0.png",
	#	"images/HACK-GUI-main-6-1.png",
	#	"images/HACK-GUI-main-6-2.png", 
	#	"images/HACK-GUI-main-6-3.png" ]
]
rightcommands = [
	[
		"exo-open /usr/share/applications/080_photorec.desktop",
		"search-caches.sh",
		"photorec-sorter.sh" ],
	[
		"history-extractor.sh",
		"pst-importer.sh",
		"jumplist-extractor.sh" ],
	[
		"xfce4-terminal --hide-menubar -e 'sudo openvas-wrapper' ",
		"ruby -I . nmapper.rb", 
		# "exo-open /usr/share/applications/snort.desktop",
		"exo-open /usr/share/applications/wireshark.desktop",
		"exo-open /usr/share/applications/wpa-cracker.desktop" ],
	[
		"exo-open /usr/share/applications/vdiskimage.desktop",
		"sudo /usr/bin/qemustarter.sh",
		"sudo /usr/share/lesslinux/toolbox-launcher/basecheck.sh" ],
	#[
	#	"exo-open /usr/share/applications/060_usbinstall.desktop" ],	
	#[
	#	"exo-open /usr/share/applications/teamviewer.desktop",
	#	"exo-open /usr/share/applications/runx11vnc.desktop",
	#	"exo-open /usr/share/applications/remmina.desktop" ]
]
rightpixbufs = Array.new
rightimages.each { |i|
	rightpixbufs.push(Gtk::Image.new(i[0]))
}
rightboxes = Array.new
rightpixbufs.each { |b|
	rightboxes.push(Gtk::EventBox.new.add(b))
}
rightboxes.each { |b|
	fixed.put(b, 320, 160)
}
0.upto(rightimages.size - 1) { |n|
	rightboxes[n].signal_connect("button_press_event") { |obj, event|
		puts "Y position: #{event.y}"
		if event.x > 50 && event.x < 600 
			el = (event.y - 84.0) / 80.0
			unless rightimages[n][el.to_i + 1].nil?
				rightpixbufs[n].file = rightimages[n][el.to_i + 1]
			end
		end
	}
	rightboxes[n].signal_connect("button_release_event") { |obj, event|
		rightpixbufs[n].file = "images/HACK-GUI-main-" + (n+1).to_s + "-0.png"
		if event.x > 50 && event.x < 600 
			el = (event.y - 84.0) / 80.0
			unless rightcommands[n][el.to_i].nil?
				system(rightcommands[n][el.to_i] + " &")
			end
		end
	}
}

leftbuttons.each{ |b| 
	fixed.put(b, 0, 160)
	b.signal_connect("button_release_event") { |obj, event|
		puts event.class
		puts event.x
		puts event.y
		el = (event.y - 16.0) / 64
		unless el < 0.0 || el.to_i  >= leftbuttons.size 
			puts "Clicked #{el.to_s}"
			leftbuttons.each{ |b| b.hide_all } 
			leftbuttons[el.to_i].show_all
			rightboxes.each{ |b| b.hide_all } 
			rightboxes[el.to_i].show_all
		end
	}
} 

bc = 0
topbcommands = Hash.new
topbuttons.each { |b|
	fixed.put(b, topboffsets[bc], 103)
	topbcommands[b] = topbcommandstrings[bc]
	b.signal_connect("button_release_event") { |obj, event|
		system(topbcommands[obj] + " &")
	}
	bc += 1
}

window.add fixed
window.show_all 
leftbuttons.each{ |b| b.hide_all } 
leftbuttons[0].show_all
rightboxes.each{ |b| b.hide_all } 
rightboxes[0].show_all
Gtk.main
