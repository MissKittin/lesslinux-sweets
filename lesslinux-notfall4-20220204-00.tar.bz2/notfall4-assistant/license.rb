#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'vte'
require "rexml/document"
require 'optparse'
require 'TileHelpers'
require 'MfsTranslator'

exit if File.exists?("/var/run/lesslinux/license_accepted")

$lang = ENV['LANGUAGE'][0..1]
$lang = ENV['LANG'][0..1] if $lang.nil?
$lang = "en" if $lang.nil?
$startup_finished = false
if File.exists?("/etc/lesslinux/branding/InfoScreen.xml")
	@tl = MfsTranslator.new($lang, "/etc/lesslinux/branding/InfoScreen.xml")
else
	@tl = MfsTranslator.new($lang, "InfoScreen.xml") 
end

window = Gtk::Window.new
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.set_size_request(1020, 630)
window.border_width = 0
window.deletable = false
window.decorated = false
window.allow_grow = false
window.allow_shrink = false
window.title = "Notfall-DVD"
window.signal_connect('delete_event') { false }
window.signal_connect('destroy') { 
	# system("rm /var/run/lesslinux/assistant_running")
	Gtk.main_quit
}
bgimg = Gtk::Image.new("images/winbglic.png")
fixed = Gtk::Fixed.new
fixed.put(bgimg, 0, 0)

disclabel = Gtk::Label.new
disclabel.set_markup("<span color='white'>" + @tl.get_translation("licheader") + "</span>")
fat_font = Pango::FontDescription.new("Sans Bold 14")
disclabel.modify_font(fat_font)

disctext = "Ooops nicht gefunden!"
if File.exist?("/etc/lesslinux/branding/legal.#{@lang}.txt")
	disctext = File.new("/etc/lesslinux/branding/legal.#{@lang}.txt").read
elsif File.exist?("legal.#{@lang}.txt")
	disctext = File.new("legal.#{@lang}.txt").read
elsif File.exist?("haftung.txt")
	disctext = File.new("haftung.txt").read
end
textview = Gtk::TextView.new
textview.buffer.text = disctext
textview.set_wrap_mode(Gtk::TextTag::WRAP_WORD)
scrolled_win = Gtk::ScrolledWindow.new
scrolled_win.border_width = 5
scrolled_win.add(textview)
scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
textview.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		
# scrolled_win.add(textview)
scrolled_win.set_size_request(974, 290)
		
text4 = Gtk::Label.new
text4.width_request = 250
text4.wrap = true
text4.set_markup("<span color='white'>" + @tl.get_translation("licdecline") + "</span>")
back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
text5 = Gtk::Label.new
text5.width_request = 250
text5.wrap = true
text5.set_markup("<span color='white'>" + @tl.get_translation("licaccept") + "</span>")
forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		
forw.signal_connect('button-release-event') { |x, y|
	if y.button == 1 
		system("touch /var/run/lesslinux/license_accepted") 
		system("touch /tmp/.license_accepted") 
		Gtk.main_quit
		exit
	end
}
back.signal_connect('button-release-event') { |x, y|
	if y.button == 1 
		system("/usr/bin/shutdown-wrapper.sh") 
	end
}
		
fixed.put(disclabel, 39, 167)
fixed.put(scrolled_win, 36, 200)
fixed.put(forw, 958, 494)
fixed.put(text5, 710, 510)
fixed.put(back, 958, 554)
fixed.put(text4, 710, 560)

window.add fixed
window.show_all 
Gtk.main