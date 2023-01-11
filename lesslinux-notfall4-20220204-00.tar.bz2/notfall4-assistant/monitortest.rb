#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
# require 'vte'
require "rexml/document"
# require 'MfsTranslator.rb'
require "TileHelpers"

$lang = ENV['LANGUAGE'][0..1]
$lang = ENV['LANG'][0..1] if $lang.nil?
$lang = "en" if $lang.nil?

layers = Array.new
button = Array.new
fixed = Gtk::Fixed.new

n = 0
[  "testbild.png", "black1920.png", "white1920.png", "blue1920.png", "green1920.png" , "red1920.png" ].each { |b|
	img = b
	img = b if File.exists?("/usr/share/lesslinux/notfallcd4/#{b}")
	button[n] = Gtk::EventBox.new.add Gtk::Image.new(b)
	fixed.put(button[n], 0, 0)
	n += 1
}
button[0].signal_connect('button-release-event') { |x, y|
	if y.button == 1 
		button.each { |m| m.hide_all }
		button[ 1 ].show_all 
	end
}
button[1].signal_connect('button-release-event') { |x, y|
	if y.button == 1 
		button.each { |m| m.hide_all }
		button[ 2 ].show_all 
	else
		button.each { |m| m.hide_all }
		button[ 0 ].show_all 
	end
}
button[2].signal_connect('button-release-event') { |x, y|
	if y.button == 1 
		button.each { |m| m.hide_all }
		button[ 3 ].show_all
	else
		button.each { |m| m.hide_all }
		button[ 1 ].show_all
	end
}
button[3].signal_connect('button-release-event') { |x, y|
	if y.button == 1 
		button.each { |m| m.hide_all }
		button[ 4 ].show_all
	else
		button.each { |m| m.hide_all }
		button[ 2 ].show_all
	end
}
button[4].signal_connect('button-release-event') { |x, y|
	if y.button == 1 
		button.each { |m| m.hide_all }
		button[ 5 ].show_all
	else
		button.each { |m| m.hide_all }
		button[ 3 ].show_all
	end
}
button[5].signal_connect('button-release-event') { |x, y|
	if y.button == 1 
		exit 0 
	else
		button.each { |m| m.hide_all }
		button[ 4 ].show_all
	end
}

window = Gtk::Window.new
window.set_size_request(1920, 1200)
window.border_width = 0
# window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.deletable = false
window.decorated = false
window.allow_grow = false
window.allow_shrink = false
window.move(0,0)
window.title = "Monitortest"
window.signal_connect('delete_event') { false }
window.signal_connect('destroy') { Gtk.main_quit }
window.add(fixed) 
window.show_all 
button.each { |n| n.hide_all }
button[0].show_all

message = "The first image is intended to check whether monitor and graphics card cooperate smoothly. All other images are intended to check backlight and find dead pixels. Click anywere to jump to next image. This programs automatically quits after the last image." 
message = "Das erste Testbild dient zur Überprüfung der korrekten Zusammenarbeit von Grafikkarte und Monitor. Die weiteren Testbilder dienen der Überprüfung von Ausleuchtung und dem Aufspüren von Pixelfehlern. Klicken Sie mit der Maus an einer beliebigen Stelle ins Testbild um zum nächsten Testbild zu gelangen - per Rechtsklick gelangen Sie ein Bild zurück. Nach dem letzten Testbild wird das Programm automatisch beendet." if $lang == "de"
message = "Pierwszy obraz kontrolny ma na celu sprawdzenie, czy monitor i karta graficzna współpracują bezproblemowo. Wszystkie inne plansze mają za zadanie sprawdzić podświetlenie i znaleźć martwe piksele. Kliknij w dowolnym miejscu, aby przejść do następnego obrazu. Ten program wyłączy się automatycznie po ostatnim obrazie." if $lang == "pl" 
TileHelpers.success_dialog(message, "Monitortest")
Gtk.main


