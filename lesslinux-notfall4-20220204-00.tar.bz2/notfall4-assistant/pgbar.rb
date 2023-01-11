#!/usr/bin/ruby

require 'glib2'
require 'gtk2'

$lang = ENV['LANGUAGE'][0..1]
$lang = ENV['LANG'][0..1] if $lang.nil?
$lang = "en" if $lang.nil?

window = Gtk::Window.new
pgbar = Gtk::ProgressBar.new
pgbar.width_request = 400
pgbar.height_request = 32

window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

window.signal_connect("show") {
        while File.exists?("/var/run/createvccontainer")
                pgbar.pulse
		# FIXME translate
		pgbar.text = "Initialisiere Datentresor..."
		pgbar.text = "Inicjowanie sejfu na dane" if $lang == "pl" 
                while (Gtk.events_pending?)
                        Gtk.main_iteration
                end
                sleep 0.5
        end
        exit 0
}

window.add pgbar
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.deletable = false
#window.decorated = false
window.allow_grow = false
window.allow_shrink = false
window.title = "Datentresor"
window.title = "Sejf danych" if $lang == "pl" 

# window.width_request = 400 
# window.height_request = 100

window.show_all
Gtk.main
