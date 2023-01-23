#!/usr/bin/ruby

require 'gtk2'

window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
window.set_title  "Password?"
window.border_width = 10
window.signal_connect('delete_event') { Gtk.main_quit }

question  = Gtk::Label.new("Diese Aktion erfordert ein Passwort!")
entry_label = Gtk::Label.new("Password:")

pass = Gtk::Entry.new
pass.visibility = false
pass.signal_connect('activate') {
	puts pass.text
	Gtk.main_quit
}

# The following property takes integer value not string character
# pass.invisible_char = 42           ### for instance 42=asterisk

hbox = Gtk::HBox.new(false, 5)
hbox.pack_start_defaults(entry_label)
hbox.pack_start_defaults(pass)
vbox = Gtk::VBox.new(false, 5)
vbox.pack_start_defaults(question)
vbox.pack_start_defaults(hbox)

window.add(vbox)
window.show_all
Gtk.main
