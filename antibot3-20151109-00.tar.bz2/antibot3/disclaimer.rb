#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'vte'
require "rexml/document"
require "MfsTranslator"

$background = "background_disclaimer.png"

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "disclaimer.xml"
tlfile = "/usr/share/lesslinux/antibot3/disclaimer.xml" if File.exists?("/usr/share/lesslinux/antibot3/disclaimer.xml")
tl = MfsTranslator.new(lang, tlfile)

window = Gtk::Window.new
window.border_width = 10

unless ARGV[0] == "debug"
	window.deletable = false
	window.decorated = false
	window.title = tl.get_translation("wintitle")
else
	window.title = tl.get_translation("wintitle")
end

fixed = Gtk::Fixed.new
fixed.put(Gtk::Image.new($background), 0, 0)

discfile = tl.get_translation("legalfile")
discfile = "/lesslinux/cdrom/antibot3/#{discfile}" if File.exist?("/lesslinux/cdrom/antibot3/#{discfile}")
disctext = File.new(discfile).read

disclabel = Gtk::Label.new(tl.get_translation("wintitle"))
fat_font = Pango::FontDescription.new("Sans Bold 18")
disclabel.modify_font(fat_font)

textview = Gtk::TextView.new
textview.buffer.text = disctext
textview.editable = false
textview.set_wrap_mode(Gtk::TextTag::WRAP_WORD)

scrolled_win = Gtk::ScrolledWindow.new
scrolled_win.border_width = 5
scrolled_win.add(textview)
scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
# scrolled_win.add(textview)
scrolled_win.set_size_request(640, 350)
fixed.put(scrolled_win, 145, 150)
fixed.put(disclabel, 147, 116)

icon_theme = Gtk::IconTheme.default
button_box = Gtk::HBox.new
accept_button = Gtk::Button.new(Gtk::Stock::APPLY)
accept_button.label = tl.get_translation("button-accept")

decline_button = Gtk::Button.new(Gtk::Stock::DISCARD)
decline_button.label = tl.get_translation("button-decline")
button_box.pack_start(accept_button, true, true, 0)
button_box.pack_start(decline_button, true, true, 0)
button_box.set_size_request(636, 32)
fixed.put(button_box, 147, 510)

window.signal_connect('delete_event') { Gtk.main_quit }

accept_button.signal_connect("clicked") { Gtk.main_quit }
decline_button.signal_connect("clicked") {
	$stderr.puts("Ooops, not accepted, shut down!")
	system("sudo chvt 1")
	system("sudo poweroff")
}

window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.set_size_request(800, 600)
window.border_width = 0
window.add(fixed)
system("esetroot -s " + tl.get_translation("background"))
window.show_all

Gtk.main
