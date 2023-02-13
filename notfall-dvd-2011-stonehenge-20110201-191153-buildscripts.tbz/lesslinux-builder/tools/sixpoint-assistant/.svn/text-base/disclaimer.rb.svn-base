#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'vte'
require "rexml/document"

# $background = "/usr/share/lesslinux/cbavgui/bck_rescuecd_final.png"
# $background = "/tmp/avira-skel/bck_decleaner.png" unless system("test -f " + $background)

$background = "NotfallCD30.png"

window = Gtk::Window.new
window.border_width = 10

unless ARGV[0] == "debug"
	window.deletable = false
	window.decorated = false
end

disctext = File.new("haftung.txt").read
disctext = File.new("/lesslinux/cdrom/haftung.txt").read if File.exist?("/lesslinux/cdrom/haftung.txt")
wintitle =  "Nutzungs- und Haftungsbedingungen"
accept = "Akzeptieren"
decline = "Ablehnen"

begin
	if ENV["LANGUAGE"][0..1] == "es"
		wintitle = "Uso y responsabilidad"
		accept  = "Aceptar"
		decline = "Rechazar"
		$background = "NotfallCD30_es.png"
		disctext = File.new("disclaimer_es.txt").read
		disctext = File.new("/lesslinux/cdrom/aviso_legal.txt").read if File.exist?("/lesslinux/cdrom/aviso_legal.txt")
		disctext = File.new("/lesslinux/toram/aviso_legal.txt").read if File.exist?("/lesslinux/toram/aviso_legal.txt")
	end
rescue
end

window.title = wintitle
fixed = Gtk::Fixed.new
fixed.put(Gtk::Image.new($background), 0, 0)

#File.new("/tmp/haftung.txt").each { |line| 
#	disctext = disctext + line
#}

disclabel = Gtk::Label.new(wintitle)
fat_font = Pango::FontDescription.new("Sans Bold 18")
disclabel.modify_font(fat_font)

textview = Gtk::TextView.new
textview.buffer.text = disctext
textview.set_wrap_mode(Gtk::TextTag::WRAP_WORD)

scrolled_win = Gtk::ScrolledWindow.new
scrolled_win.border_width = 5
scrolled_win.add(textview)
scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
# scrolled_win.add(textview)
scrolled_win.set_size_request(595, 260)
fixed.put(scrolled_win, 4, 140)
fixed.put(disclabel, 4, 110)

icon_theme = Gtk::IconTheme.default
button_box = Gtk::HBox.new
accept_button = Gtk::Button.new(Gtk::Stock::APPLY)
accept_button.label = accept

decline_button = Gtk::Button.new(Gtk::Stock::DISCARD)
decline_button.label = decline
button_box.pack_start(accept_button, true, true, 0)
button_box.pack_start(decline_button, true, true, 0)
button_box.set_size_request(595, 32)
fixed.put(button_box, 4, 404)

window.signal_connect('delete_event') { Gtk.main_quit }

accept_button.signal_connect("clicked") { Gtk.main_quit }
decline_button.signal_connect("clicked") {
	$stderr.puts("Ooops, not accepted, shut down!")
	system("sudo chvt 1")
	system("sudo shutdown -h now")
}

window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.set_size_request(600, 440)
window.border_width = 0
window.add(fixed)
window.show_all

Gtk.main