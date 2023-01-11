#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'MfsTranslator.rb'

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "welcome_desktop.xml"
tlfile = "/usr/share/lesslinux/antibot3/welcome_desktop.xml" if File.exists?("/usr/share/lesslinux/antibot3/welcome_desktop.xml")
tl = MfsTranslator.new(lang, tlfile)
 
icon_theme = Gtk::IconTheme.default
table = Gtk::Table.new(5, 2, false)
warnlab = Gtk::Label.new
warnlab.set_markup("<span weight='bold' size='large'>" + tl.get_translation("header") + "</span>")
warnlab.width_request = 785
table.attach(warnlab, 0, 2, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)

# Label IMSM

imsmlab = Gtk::Label.new
imsmlab.set_markup(tl.get_translation("biglabel"))
imsmlab.wrap = true
imsmlab.width_request = 730
imsmbuf = icon_theme.load_icon("user-desktop", 96, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
imsmimg = Gtk::Image.new(imsmbuf)
imsmimg.set_alignment(0,0.5)
table.attach(imsmlab, 1, 2, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
table.attach(imsmimg, 0, 1, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)

# Buttons

buttonbox = Gtk::HBox.new(true, 5)
continue = Gtk::Button.new(tl.get_translation("button-www"))
shutdown = Gtk::Button.new(tl.get_translation("button-skip"))
continue.signal_connect('clicked') {
	system("firefox " + tl.get_translation("urls").gsub(",", " ") + " &") 
	Gtk.main_quit
}
shutdown.signal_connect('clicked') {
	Gtk.main_quit
}

buttonbox.pack_end_defaults(shutdown)
buttonbox.pack_end_defaults(continue)
table.attach(buttonbox, 0, 2, 4, 5, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)

# Show everything

window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

window.border_width = 10
window.set_title(tl.get_translation("wintitle"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.deletable = false
window.decorated = false
# window.width_request = 600
# window.height_request = 400
window.add table
window.show_all
# shutdown.grab_default
shutdown.grab_focus

Gtk.main
