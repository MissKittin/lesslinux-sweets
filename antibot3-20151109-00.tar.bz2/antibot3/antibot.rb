#!/usr/bin/ruby
# encoding: utf-8

# require 'iconv'
require 'gtk2'
require 'vte'
require "rexml/document"
require 'optparse'
require 'sqlite3'

require "MfsDiskDrive.rb"
require "MfsSinglePartition.rb"
require "MfsTranslator.rb"
require "AntibotDriveScreen.rb"
require "AntibotOptionScreen.rb"
require "AntibotScanFrame.rb"
require "AntibotPrereqScreen.rb"
require "AntibotFinishFrame.rb"
require "AntibotAviraScanner.rb" 
require "AntibotResultFrame.rb"
require "AntibotInfectedFile.rb"
require "AntibotMisc.rb"

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "antibot.xml"
tlfile = "/usr/share/lesslinux/antibot3/antibot.xml" if File.exists?("/usr/share/lesslinux/antibot3/antibot.xml")
@tl = MfsTranslator.new(lang, tlfile)

pageflow = Array.new

# Robby and friends
sbimages = [ "DE-Cleaner-Rettungssystem-2012-0.png",
	"DE-Cleaner-Rettungssystem-2012-1.png",
	"DE-Cleaner-Rettungssystem-2012-2.png",
	"DE-Cleaner-Rettungssystem-2012-3.png",
	"DE-Cleaner-Rettungssystem-2012-4.png",
	"DE-Cleaner-Rettungssystem-2012-5.png",
	"DE-Cleaner-Rettungssystem-2012-6a.png" ]
sbpixbuf = sbimages.collect { |i| Gdk::Pixbuf.new(i) }

# Create a new assistant widget with no pages. */
assistant = Gtk::Assistant.new
assistant.set_size_request(750, 400)   # 450, 300
assistant.signal_connect('destroy') { Gtk.main_quit }

# Intro page
intro_label = Gtk::Label.new @tl.get_translation("welcome") 
help_button = Gtk::Button.new
help_button.use_underline = true
help_button.label = @tl.get_translation("help")
help_button.image = Gtk::Image.new(Gtk::IconTheme.default.load_icon("gtk-help", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
help_button.signal_connect('clicked') { system("bash viewhelp.sh &") } 
intro_label.wrap = true
intro_label.width_request = 500 
assistant.append_page(intro_label)
assistant.set_page_title(intro_label, @tl.get_translation("label-intro"))
assistant.set_page_type(intro_label, Gtk::Assistant::PAGE_INTRO)
assistant.set_page_complete(intro_label, true)
assistant.set_page_side_image(intro_label, sbpixbuf[0]) 
assistant.add_action_widget help_button

# Append the page for checking prerequisites
# Now this are three pages!

prescr = AntibotPrereqScreen.new(assistant)
assistant.append_page(prescr.taligns[1])
assistant.set_page_title(prescr.taligns[1], @tl.get_translation("label-power"))
assistant.set_page_complete(prescr.taligns[1], true)
assistant.set_page_side_image(prescr.taligns[1], sbpixbuf[1]) 

assistant.append_page(prescr.taligns[0])
assistant.set_page_title(prescr.taligns[0], @tl.get_translation("label-internet"))
assistant.set_page_complete(prescr.taligns[0], true)
assistant.set_page_side_image(prescr.taligns[0], sbpixbuf[2]) 

assistant.append_page(prescr.taligns[2])
assistant.set_page_title(prescr.taligns[2], @tl.get_translation("label-memory"))
assistant.set_page_complete(prescr.taligns[2], prescr.complete)
assistant.set_page_side_image(prescr.taligns[2], sbpixbuf[3]) 

# Append the page for drive selection
dscrn = AntibotDriveScreen.new(assistant)
assistant.append_page(dscrn.wdgt) 
assistant.set_page_title(dscrn.wdgt, @tl.get_translation("label-drives"))
assistant.set_page_complete(dscrn.wdgt, true)
assistant.set_page_side_image(dscrn.wdgt, sbpixbuf[4]) 

# Append the page for scan options
oscrn = AntibotOptionScreen.new
# Append the page for scan start
scnfr = AntibotScanFrame.new(assistant, dscrn, oscrn, prescr, Time.now)
assistant.append_page(scnfr.wdgt)
assistant.set_page_title(scnfr.wdgt, @tl.get_translation("label-start"))
# assistant.set_page_type(scnfr.wdgt, Gtk::Assistant::PAGE_PROGRESS)
assistant.set_page_complete(scnfr.wdgt, false)
assistant.set_page_side_image(scnfr.wdgt, sbpixbuf[5]) 

# Append the results page
resfr = AntibotResultFrame.new(assistant)
assistant.append_page(resfr.wdgt)
assistant.set_page_title(resfr.wdgt, @tl.get_translation("label-done"))
assistant.set_page_type(resfr.wdgt, Gtk::Assistant::PAGE_SUMMARY)
assistant.set_page_complete(resfr.wdgt, false)
assistant.set_page_side_image(resfr.wdgt, sbpixbuf[6]) 

# Append the finish page - shown after desinfection
finfr = AntibotFinishFrame.new(assistant)

# We need some friendly names for debugging the page flow
pagenames = {
	intro_label => "0 intro",
	prescr.taligns[1] => "1 energie",
	prescr.taligns[0] => "2 netzwerk",
	prescr.taligns[2] => "3 speicher",
	dscrn.wdgt => "4 laufwerke",
	scnfr.wdgt => "5 scan",
	resfr.wdgt => "6 result"
}
# Current page for re-reading drivelist

assistant.signal_connect("prepare") { |s, p|
	puts "Current page is " + assistant.current_page.to_s 
	puts "Prepare to go to page: " + pagenames[p]
	puts "Previous pages: " + pageflow.join(", ")
	$stdout.flush 
	resfr.again_button.hide_all
	resfr.log_button.hide_all
	
	if p == intro_label
		help_button.show_all
	else
		help_button.hide_all
	end
	
	if p == prescr.taligns[1]
		puts "Checking power supply"
		prescr.check_power
	elsif p == prescr.taligns[0]
		puts "Checking network connection"
		prescr.check_net
	elsif p == prescr.taligns[2]
		puts "Checking memory"
		prescr.check_memory
	elsif p == dscrn.wdgt
		puts "Moving to drivelist, rereading"
		dscrn.reread_drivelist
		dscrn.reread_drivelist if dscrn.check_drives == true
		dscrn.reread_drivelist if dscrn.check_uuids == true
	elsif p == resfr.wdgt
		puts "Jumping to results page"
		resfr.show_results(dscrn.int_drives, dscrn.ext_drives, dscrn.special_drives, scnfr.scanner)
	end
	
	unless pageflow[-1] == pagenames[p]
		pageflow.push(pagenames[p]) 
	else
		puts "ERROR: duplicate in flow " + pagenames[p]
	end
	# dscrn.dump_marked
	# lastpage = assistant.current_page 
	$stdout.flush 
}

assistant.set_forward_page_func { |curr|
	puts "Currently on: " + curr.to_s
	puts "Alternative method: " + assistant.current_page.to_s 
	if curr == 2 && prescr.check_memory 
		4
	elsif curr == 0 && prescr.check_power
		2
	else
		curr + 1 
	end
}

assistant.signal_connect("close") {
	puts "Closing. Goodbye."
	( dscrn.ext_drives + dscrn.int_drives ).each { |d| d.umount } 
	system("touch /var/run/lesslinux/reboot_requested")
	AntibotMisc.cancel_dialog(assistant)
}

assistant.signal_connect("cancel") {
	puts "Cancelled! Goodby."
	( dscrn.ext_drives + dscrn.int_drives ).each { |d| d.umount } 
	system("touch /var/run/lesslinux/restart_requested")
	AntibotMisc.cancel_dialog(assistant)
}

assistant.deletable = false
assistant.decorated = false
assistant.window_position = Gtk::Window::POS_CENTER_ALWAYS
assistant.title = @tl.get_translation("wintitle")
# system("su surfer -c /usr/bin/xfce4-panel &")
assistant.show_all
Gtk.main
