#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'vte'
require "rexml/document"
require 'optparse'
require 'NetworkScreen'
require 'RescueScreen'
require 'SambaScreen'
require 'WindowsScreen'
require 'PhotorecScreen'
require 'DvdRescueScreen'
require 'MailRescueScreen' 
require 'FfRescueScreen' 
require 'WordRescueScreen' 
require 'SingleFileRescue'
require 'DeleteScreen' 
require 'VirusScreen'
require 'ChntpwScreen'
require 'UsbRescueScreen'
require 'PcInspectorScreen'
require 'ImageScreen'
require 'CloneScreen'
require 'InfoScreen'
require 'UsbInstallScreen'
require 'CheckScreen'
require 'LicenseRecoverScreen'
require 'MozillaRecoverScreen'
require 'TileHelpers'
require 'MfsTranslator'

def close_tooltips
	begin 
		@ttwin.destroy
	rescue
		return
		puts "No window to destroy"
	end
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	ttwins = []
	IO.popen("wmctrl -l") { |l|
		while l.gets
			ltoks = $_.strip.split
			ttwins.push(ltoks[0]) if ltoks[-1] == "tooltip"
		end
	}
	if ttwins.size > 1
		ttwins.each{ |w|
			system("wmctrl -i -c #{w}")
		}
	end
end

def close_too_many
	ttwins = []
	IO.popen("wmctrl -l") { |l|
		while l.gets
			ltoks = $_.strip.split
			ttwins.push(ltoks[0]) if ltoks[-1] == "tooltip"
		end
	}
	if ttwins.size > 1
		ttwins.each{ |w|
			system("wmctrl -i -c #{w}")
		}
	end
end

def calculate_batt_symbol
	battsyms = [ 
		"images/button_batt_0.png",
		"images/button_batt_1.png",
		"images/button_batt_2.png",
		"images/button_batt.png",
		"images/button_batt_unknown.png" ]
	#~ "batt0.png", # Unknown state
	#~ "batt1.png", # empty not charging
	#~ "batt2.png", # 1/3 not charging
	#~ "batt3.png", # 2/3 not charging
	#~ "batt4.png", # 3/3 not charging
	#~ "batt5.png", # empty charging
	#~ "batt6.png", # 1/3 charging
	#~ "batt7.png", # 2/3 charging
	#~ "batt8.png", # full charging 
	return battsyms[4] unless File.directory?("/sys/class/power_supply/BAT0")
	percentage = 0
	percentage = File.read("/sys/class/power_supply/BAT0/capacity").to_i if File.exists?("/sys/class/power_supply/BAT0/capacity")
	status = nil
	status = File.read("/sys/class/power_supply/BAT0/status") if File.exists?("/sys/class/power_supply/BAT0/status")
	if status =~ /Unknown/ 
		return battsyms[4]
	elsif percentage > 83
		return battsyms[3]
	elsif percentage > 50
		return battsyms[2]
	elsif percentage > 16
		return battsyms[1]
	end
	return battsyms[0]
end

def change_active_box(num)
	if TileHelpers.get_lock == true
		TileHelpers.error_dialog(@tl.get_translation("guilocked"))
		return
	end
	if (num < 8) 
		@active_boxes_left.each { |b| b.hide_all }
		@inactive_boxes_left.each { |b| b.show_all }
		@inactive_boxes_left[num].hide_all
		@active_boxes_left[num].show_all
	elsif (num > 16)
		@active_boxes_left.each { |b| b.hide_all }
		@inactive_boxes_left.each { |b| b.show_all }
	end
	@rightboxes.each { |n|
		n.each { |o|
			o.hide_all
		}
	}
	@rightboxes[num].each { |o| o.show_all }
	@groupnames.each { |n| n.hide_all }
	@groupnames[num].show_all 
	@modlayers.each { |k, v| 
		v.hide_all 
	}
	$rightactivebox = num 
end

def change_active_screen(scr)
	if TileHelpers.get_lock == true
		TileHelpers.error_dialog(@tl.get_translation("guilocked"))
		return
	end
	@rightboxes.each { |n|
		n.each { |o|
			o.hide_all
		}
	}
	@groupnames.each { |n| n.hide_all }
	@modlayers.each { |k, v| 
		v.hide_all 
	}
	@modlayers[scr].show_all 
end

def change_active_screen_special(scr, id)
	if TileHelpers.get_lock == true
		TileHelpers.error_dialog(@tl.get_translation("guilocked"))
		return
	end
	puts "Button pressed: #{id.to_s}"
	nextscreen = scr
	change_active_screen("pleasewait") 
	# Show wait screen!
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	# Special moves for each screen
	if scr == "photorecstart"
		@photorecscreen.prepare_photorecstart
	elsif scr == "winfindpartitions"
		@windowsscreen.prepare_winfindpartitions 
	elsif scr == "dvdrescue"
		nextscreen = @dvdrescuescreen.prepare_dvdrescue(@modlayers)
	elsif scr == "mailpartlist"
		@mailrescuescreen.prepare_mailpartlist 
	elsif scr == "firefoxpartlist"
		@ffrescuescreen.prepare_firefoxpartlist 
	elsif scr == "wordrescuestart"
		@wordrescuescreen.prepare_wordrescuestart
	elsif scr == "filerescuestart"
		@filerescuescreen.prepare_filerescuestart
	elsif scr == "rescueprofile"
		@rescuescreen.prepare_rescueprofile
	elsif scr == "sevensavesourcelayer"
		@rescuescreen.prepare_sevensavesourcelayer
	elsif scr == "deletepartition"
		@deletescreen.prepare_deletepartition(id == 2)
	elsif scr == "deletedrive"
		@deletescreen.prepare_deletedrive() # id == 2)
	elsif scr == "virusstart"
		nextscreen = @virusscreen.prepare_virusstart(@networkscreen)
	elsif scr == "chntpwstart"
		@chntpwscreen.prepare_chntpwstart 
	elsif scr == "pcsysprofile"
		nextscreen = @pcinspectorscreen.prepare_pcsysprofile(@networkscreen)
	elsif scr == "dvdstartpanel"
		burnmode = (1 + id) % 2
		nextscreen = @windowsscreen.prepare_dvdstartpanel(burnmode)
	elsif scr == "imagetargetscreen"	
		@photorecscreen.prepare_imagetargetscreen
	elsif scr == "rescuelocal"
		@rescuescreen.prepare_rescuelocal
	elsif scr == "rescuecloud"
		nextscreen = @rescuescreen.prepare_rescuecloud(@networkscreen)
	elsif scr == "sambaquest"
		nextscreen = @sambascreen.prepare_sambaquest(@networkscreen)
	elsif scr == "imagesrcdrives"
		@imagescreen.prepare_imgsrcdrives
	elsif scr == "imagesrcfiles"
		@imagescreen.prepare_imagesrcfiles
	elsif scr == "clonesource"
		@clonescreen.prepare_clonesource
	elsif scr == "selectclonesrctgt"
		nextscreen = @clonescreen.prepare_selectclonesrctgt(@networkscreen)
	elsif scr == "installtarget"
		@usbinstallscreen.prepare_installtarget
		# TileHelpers.set_lock 
	elsif scr == "efiinstall"
		nextscreen = @usbinstallscreen.prepare_efiinstall
		if nextscreen.nil?
			TileHelpers.error_dialog(@tl.get_translation("uefionly"))
			@modlayers["pleasewait"].hide_all 
			TileHelpers.back_to_group
			return 
		end
	elsif scr == "updatesearch"
		system("/etc/lesslinux/updater/update_wrapper.sh &")
		@modlayers["pleasewait"].hide_all 
		TileHelpers.back_to_group
		return 
	elsif scr == "wpatargetselect"
		netcount = @virusscreen.prepare_wpatargetselect
		if netcount < 1
			@modlayers["pleasewait"].hide_all 
			TileHelpers.back_to_group
			return 
		end
	elsif scr == "installdvd"
		loopfile = @usbinstallscreen.get_loop_file
		unless loopfile.nil?
			system("xfburn \"#{loopfile}\" &")  unless loopfile.nil?
		else
			puts "FIXME: No loopfile!"
			TileHelpers.error_dialog(@tl.get_translation("no_loopfile"))
		end
		@modlayers["pleasewait"].hide_all 
		TileHelpers.back_to_group
		return 
	elsif scr == "winfixcpuburn"
		change_active_screen(nextscreen)
		TileHelpers.set_lock
		@windowsscreen.prepare_winfixcpuburn(@modlayers)
		return
	elsif scr == "pcloadtest"	
		change_active_screen(nextscreen)
		TileHelpers.set_lock
		@pcinspectorscreen.prepare_pcloadtest
		return
	elsif scr == "monitorpixeltest"
		system("ruby -I /usr/share/lesslinux/notfallcd4 /usr/share/lesslinux/notfallcd4/monitortest.rb &")
		@modlayers["pleasewait"].hide_all 
		TileHelpers.back_to_group
		return 
	elsif scr == "hardwarememtest"
		nextscreen = @pcinspectorscreen.prepare_hardwarememtest
	elsif scr == "tvtargetselect"
		nextscreen = @pcinspectorscreen.prepare_tvtest(@networkscreen)
	elsif scr == "ssdhealthinfo"
		@pcinspectorscreen.prepare_ssdhealthinfo
	elsif scr == "usbteststart"
		@pcinspectorscreen.prepare_usbteststart(id == 1)
	elsif scr == "docfolder" # this is only used in the KS version
		if File.directory?("/lesslinux/cdrom/Poradniki") 
			system("su surfer -c \"Thunar /lesslinux/cdrom/Poradniki\" &")
		elsif File.directory?("/lesslinux/isoloop/Poradniki")
			system("su surfer -c \"Thunar /lesslinux/isoloop/Poradniki\" &")
		elsif File.directory?("/lesslinux/cdrom/Anleitungen") 
			system("su surfer -c \"Thunar /lesslinux/cdrom/Anleitungen\" &")
		elsif File.directory?("/lesslinux/isoloop/Anleitungen")
			system("su surfer -c \"Thunar /lesslinux/isoloop/Anleitungen\" &")
		end
		@modlayers["pleasewait"].hide_all 
		TileHelpers.back_to_group
		return
	end
	# Now open the screen
	change_active_screen(nextscreen)
end

def show_left_tooltip(n)
	close_too_many
	return unless $tooltipson
	# sleep 0.5
	return if $currenttt[0] == -n && $currenttt[1] == -1
	$currenttt[0] = -n
	$currenttt[1] = -1
	# 0, 175 + 55 * n
	xwin = 0
	ywin = 0
	IO.popen("wmctrl -lG") { |l|
		while l.gets
			ltoks = $_.strip.split
			if ltoks[-1] == "Notfall-DVD"
				xwin = ltoks[2].to_i
				ywin = ltoks[3].to_i
			end
		end
	}
	# close_tooltips
	txt = @tl.get_translation("ttleft_#{n.to_s}")
	lcount = (txt.length + 70) / 66
	bgimg = Gtk::Image.new("images/ttbg.png")
	fixed = Gtk::Fixed.new
	fixed.put(bgimg, 0, 0)
	fixed.put(TileHelpers.create_label(txt.strip, 394), 3, 3)
	@ttwin = Gtk::Window.new
	@ttwin.decorated = false
	# Calculate size
	@ttwin.set_size_request(400, lcount * 20 + 5) 
	@ttwin.add fixed
	@ttwin.set_title("tooltip")
	@ttwin.show_all
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	system("wmctrl -r tooltip -e 0," + (237 + xwin).to_s + "," + (ywin + 201 + 55 * n).to_s + ",-1,-1") 
	close_too_many
end

def show_right_tooltip(group, position)
	close_too_many
	return unless $tooltipson
	return if $currenttt[0] == group && $currenttt[1] == position
	$currenttt[0] = group
	$currenttt[1] = position
	# 0, 175 + 55 * n
	xwin = 0
	ywin = 0
	IO.popen("wmctrl -lG") { |l|
		while l.gets
			ltoks = $_.strip.split
			if ltoks[-1] == "Notfall-DVD"
				xwin = ltoks[2].to_i
				ywin = ltoks[3].to_i
			end
		end
	}
	close_tooltips
	txt = @tl.get_translation("ttright_#{group.to_s}_#{position.to_s}")
	return if txt.length < 16
	lcount = (txt.length + 70) / 66
	bgimg = Gtk::Image.new("images/ttbg.png")
	fixed = Gtk::Fixed.new
	fixed.put(bgimg, 0, 0)
	fixed.put(TileHelpers.create_label(txt.strip, 394), 3, 3)
	# $ttdestructionlocked == true
	@ttwin = Gtk::Window.new
	@ttwin.decorated = false
	# Calculate size
	@ttwin.set_size_request(400, lcount * 20 + 5) 
	@ttwin.add fixed
	@ttwin.set_title("tooltip")
	@ttwin.show_all
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	# 231 + 71
	system("wmctrl -r tooltip -e 0," + (680 + xwin).to_s + "," + (ywin + 280 + 71 * position).to_s + ",-1,-1") 
	# sleep 0.2
	# $ttdestructionlocked == false
	close_too_many
end

def show_top_tooltip(n, pos, event)
	return unless $tooltipson
	$currenttt[0] = -1
	$currenttt[1] = -1
	puts n
	puts event.x
	puts event.y
	# 0, 175 + 55 * n
	xwin = 0
	ywin = 0
	IO.popen("wmctrl -lG") { |l|
		while l.gets
			ltoks = $_.strip.split
			if ltoks[-1] == "Notfall-DVD"
				xwin = ltoks[2].to_i
				ywin = ltoks[3].to_i
			end
		end
	}
	close_tooltips
	txt = @tl.get_translation("tttop_#{n.to_s}")
	lcount = (txt.length + 70) / 66
	bgimg = Gtk::Image.new("images/ttbg.png")
	fixed = Gtk::Fixed.new
	fixed.put(bgimg, 0, 0)
	fixed.put(TileHelpers.create_label(txt.strip, 394), 3, 3)
	@ttwin = Gtk::Window.new
	@ttwin.decorated = false
	# Calculate size
	@ttwin.set_size_request(400, lcount * 20 + 5) 
	@ttwin.add fixed
	@ttwin.set_title("tooltip")
	# @ttwin.window_position = Gtk::Window::POS_MOUSE
	@ttwin.show_all
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	system("wmctrl -r tooltip -e 0," + (xwin + pos - 400).to_s + "," + (ywin + 130).to_s + ",-1,-1") 
	close_too_many 
end

$lastpulse = 0.0 
$lang = ENV['LANGUAGE'][0..1]
$lang = ENV['LANG'][0..1] if $lang.nil?
$lang = "en" if $lang.nil?
$startup_finished = false
if File.exists?("/etc/lesslinux/branding/assistant.xml")
	@tl = MfsTranslator.new($lang, "/etc/lesslinux/branding/assistant.xml")
else
	@tl = MfsTranslator.new($lang, "assistant.xml") 
end

@active_boxes_left = []
@inactive_boxes_left = []
@rightboxes = [] 

@simulate = Array.new
@start = nil
@forcescreen = false 
@ttwin = nil 

# Activebuttons
$rightactivebox = 0
$rightboxes = []
$groupnames = []
TileHelpers.remove_lock 
$currenttt = [ -1, -1 ] 
$tooltipson = true 
$startup_finished = false

Gtk.init

opts = OptionParser.new 
opts.on('-s', '--simulate', :REQUIRED ) { |i| i.split(",").each { |j| @simulate.push(j) } }
opts.on('--start', :REQUIRED ) { |i| 
	@start = i.strip 
	@forcescreen = true
} 
opts.parse!

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
	Gtk::EventBox.new.add(Gtk::Image.new("images/button_info.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/button_kbd.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/button_tv.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/button_usb.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/button_network.png")),
	Gtk::EventBox.new.add(Gtk::Image.new("images/button_lock.png")),
	Gtk::EventBox.new.add(Gtk::Image.new(calculate_batt_symbol))
]
topboffsets = [ 973, 942, 902, 869, 844, 808, 784, 759  ]
@topboffsets = topboffsets
topbcommandscreens = [
	nil,
	18,
	nil,
	nil,
	17,
	nil, 
	nil,
	nil
]
topbcommandstrings = [ 
	"shutdown-wrapper.sh",
	nil,
	"xvkbd",
	"exo-open /usr/share/applications/teamviewer.desktop",
	nil,
	"connman-gtk",
	nil,
	"su surfer -c \"conky -c /usr/share/lesslinux/notfallcd4/conkyrc.window\""
]

# buttons left

0.upto(7) { |n|
	inactbox = Gtk::EventBox.new.add(Gtk::Image.new("images/left/#{n+1}_inactive.png"))
	actbox = Gtk::EventBox.new.add(Gtk::Image.new("images/left/#{n+1}_active.png"))
	# 120 , 55
	fixed.put(inactbox, 0, 175 + 55 * n) 
	inactbox.signal_connect("button_release_event") {
		puts n.to_s 
		change_active_box(n)
		close_tooltips
	}
	inactbox.signal_connect("enter_notify_event") {
		puts n.to_s
		show_left_tooltip(n)
	}
	inactbox.signal_connect("leave_notify_event") {
		close_tooltips
	}
	fixed.put(actbox, 0, 175 + 55 * n) 
	actbox.signal_connect("button_release_event") {
		puts n.to_s 
		change_active_box(n)
	}
	actbox.signal_connect("enter_notify_event") {
		puts n.to_s
		show_left_tooltip(n)
	}
	actbox.signal_connect("leave_notify_event") {
		close_tooltips
	}
	@active_boxes_left.push actbox
	@inactive_boxes_left.push inactbox
}

# 1 Windows reparieren
# 2 Daten wiederherstellen
# 3 Dateien reparieren
# 4 Daten sichern
# 5 Daten vernichten
# 6 PC-Sicherheit
# 7 Hardware reparieren
# 8 Tips und Tricks

# 9 Windows reparieren -> DVD # 2 
# 10 Daten wiederherstellen -> Backup zurück # 2 
# 11 Daten sichern -> Daten manuell sichern # 3 
# 12 Daten sichern -> Festplatte sichern und wiederh... # 2 
# 13 Daten sichern -> Festplatte klonen # 2 
# 14 PC Sicherheit -> Sicherheitscheck # 3 
# 15 PC Sicherheit -> Sicher surfen # 2
# 16 Hardware reparieren -> Hardware testen # 5 
# 17 Hardware reparieren -> Hardware testen -> USB-Laufwerk prüfen  # 2 
# 18 USB Installation # 3 
# 19 Info # 5
# 20 Info -> Umsetzung # 4

# Buttons right
@buttoncounts = [
	4, 4, 3, 4, 3, 4, 4, 3, 
	1, 1, 2, 1, 1, 2, 1, 4, 1, 2, 4, 3
] 
@subscreens = [
	[ "+winfixcpuburn", "_winfixntldr", "_winfixmssys", "_winfixshell", 8 ], # 1 Windows reparieren
	[ "+photorecstart", "_licensequest", "+winfindpartitions", "+dvdrescue", 9 ], # 2 Daten wiederherstellen
	[ "+mailpartlist", "+firefoxpartlist", "+wordrescuestart", "+filerescuestart" ], # 3 Dateien reparieren
	[ "+rescueprofile", 10, 11, 12, "+sevensavesourcelayer" ], # 4 Daten sichern
	[ "+deletepartition", "+deletedrive", "+deletepartition", "_selectrubbish" ], # 5 Daten vernichten
	[ "+virusstart", 13, 14, "+chntpwstart", "su surfer -c \"firefox http://go.microsoft.com/fwlink/p/?LinkId=237614\" &" ], # 6 PC-Sicherheit
	[ "_usbrescuestart", "_networkrepair", "+tvtargetselect", "+pcsysprofile", 15 ], # 7 Hardware reparieren
	[ # 8 Tips und Tricks
		"su surfer -c 'firefox file:///usr/share/doc/notfall-dvd/BIOS-Kompendium/index.htm' &",
		"su surfer -c 'firefox file:///usr/share/doc/notfall-dvd/WinFAQ/winfaq/Content/winfaq.htm' &",
		"su surfer -c 'firefox https://avm.de/service/' &",
		"_docfolder"
	], 
	[ "+dvdstartpanel", "+dvdstartpanel" ], # 9 Windows reparieren -> DVD erstellen
	[ "_rescuefilemanagervss" , "+imagetargetscreen" ], # 10 Daten wiederherstellen -> Backup zurück
	[ "+rescuelocal", "+rescuecloud", "+sambaquest" ], # 11 Daten sichern -> Daten manuell sichern
	[ "+imagesrcdrives", "+imagesrcfiles" ], # 12 Daten sichern -> Festplatte sichern und wiederh...
	[ "+clonesource", "+selectclonesrctgt" ], # 13 Daten sichern -> Festplatte klonen
	[ "_nmapstartlayer", "+wpatargetselect", "_mozillaquest" ], # 14 PC Sicherheit -> Sicherheitscheck 
	[ "su surfer -c 'firefox -P safefox --no-remote' &",
	"su surfer -c 'firefox -P vpnfox --no-remote' &"  ], # 15 PC Sicherheit -> Sicher surfen
	[ "+pcloadtest", "+monitorpixeltest", "+hardwarememtest", "+ssdhealthinfo", 16 ], # 16 Hardware reparieren -> Hardware testen
	[ "+usbteststart", "+usbteststart" ], # 17 Hardware reparieren -> Hardware testen -> USB-Laufwerk prüfen
	[ "+installtarget",  "+efiinstall" ,"+installdvd" ], # 18 USB Installation # 3 
	[ "_legal", "_legal3", "su surfer -c 'firefox https://www.eset.com/" + $lang +  "/' &", "+updatesearch", 19 ], # 19 Info # 5
	[  # 20 Info -> Umsetzung # 4
		"su surfer -c 'firefox http://www.mattiasschlenker.de/' &", 
		"su surfer -c 'firefox https://www.computerbild.de/autoren/Andre_Hesel-8830627.html' &", 
		"su surfer -c 'https://www.xing.com/profile/Timo_Knorst' &", 
		nil ]
]

@assumecobi = true
File.open("/etc/lesslinux/branding/branding.en.sh").each { |line|
	ltoks = line.strip.split("=")
	@assumecobi = false if ltoks[1] =~ /sadrescue/i
}
if @assumecobi == false 
	@subscreens[18] = [ # 19 Info -> Info
		"_legal", "_legal3", "su surfer -c 'firefox https://www.clamav.net/' &", "+updatesearch"
	]
	@buttoncounts = [
		4, 4, 3, 4, 3, 4, 4, 3, 
		1, 1, 2, 1, 1, 2, 1, 4, 1, 2, 3, 3
	] 
end
if $lang == "pl"
	@subscreens[7] = [
		"+docfolder"
	]
end

@rightboxes = []
@groupnames = [] 

# Buttons right either lead to other button panels or to screens with functionality
0.upto(19) { |n|
	groupname = Gtk::EventBox.new.add(Gtk::Image.new("images/right/#{n+1}_groupname.png"))
	fixed.put(groupname, 298, 152) 
	@groupnames.push groupname 
	@rightboxes[n] = []
	0.upto(@buttoncounts[n]) { |o|
		inactbox = Gtk::EventBox.new.add(Gtk::Image.new("images/right/#{n+1}_#{o}_inactive.png"))
		fixed.put(inactbox, 298, 231 + 71 * o) 
		inactbox.signal_connect("enter-notify-event") { |s, ev|
			puts "Group: #{n}, button: #{o}"
			show_right_tooltip(n, o)
		}
		unless @subscreens[n][o].nil?
			if (@subscreens[n][o].class.to_s == "String" && @subscreens[n][o] =~ /^_/ )
				# Move on to the named subscreen 
				inactbox.signal_connect("button_release_event") {
					close_tooltips
					puts "Moving to: #{@subscreens[n][o]}"
					change_active_screen(@subscreens[n][o].gsub(/^_/, ""))
					# puts n.to_s 
				}
			elsif (@subscreens[n][o].class.to_s == "String" && @subscreens[n][o] =~ /^\+/ )
				inactbox.signal_connect("button_release_event") {
					close_tooltips
					puts "Moving to: #{@subscreens[n][o]}"
					change_active_screen_special(@subscreens[n][o].gsub(/^\+/, ""), o)
					# puts n.to_s 
				}
			elsif @subscreens[n][o].class.to_s == "String"
				# Assume it is a command to run
				inactbox.signal_connect("button_release_event") {
					close_tooltips
					puts "Running: #{@subscreens[n][o]}"
					system(@subscreens[n][o])
					# puts n.to_s 
				}
			else
				# Assume its an integer
				# Move on to another selection subscreen
				inactbox.signal_connect("button_release_event") {
					close_tooltips
					change_active_box(@subscreens[n][o])
					# puts n.to_s 
				}
			end
		else
			# Manually specify commands or 
			
		end
		@rightboxes[n].push(inactbox) 
	}
}
$rightboxes = @rightboxes 
$groupnames = @groupnames 

# Top buttons for network, info and stuff:
bc = 0
topbcommands = Hash.new
topbscreens = Hash.new
# vcryptopenbutton
vcryptopenbutton = Gtk::EventBox.new.add(Gtk::Image.new("images/button_lock_open.png"))
vcryptopenbutton.signal_connect("enter-notify-event") { |obj, event|
	show_top_tooltip(6, topboffsets[6], event)
}
vcryptopenbutton.signal_connect("leave-notify-event") { |obj, event|
	close_tooltips
}

fixed.put(vcryptopenbutton, topboffsets[6], 100)
topbuttons.each { |b|
	pos = topboffsets[bc]
	n = bc
	fixed.put(b, topboffsets[bc], 100)
	# Those lead to shell commands
	unless topbcommandstrings[bc].nil?
		topbcommands[b] = topbcommandstrings[bc]
		b.signal_connect("button_release_event") { |obj, event|
			system(topbcommands[obj] + " &")
		}
	end
	# Those lead to further screens
	unless topbcommandscreens[bc].nil?
		topbscreens[b] = topbcommandscreens[bc]
		b.signal_connect("button_release_event") { |obj, event|
			if event.button == 3 && n == 1 
				$tooltipson = !$tooltipson
				if $tooltipson 
					TileHelpers.success_dialog(@tl.get_translation('tooltipson'))
				else
					TileHelpers.success_dialog(@tl.get_translation('tooltipsoff'))
				end
			else
				if TileHelpers.get_lock == true
					TileHelpers.error_dialog(@tl.get_translation("guilocked"))
					return
				end
				change_active_box(topbscreens[obj])
			end
		}
	end
	b.signal_connect("enter-notify-event") { |obj, event|
		show_top_tooltip(n, pos, event)
	}
	b.signal_connect("leave-notify-event") { |obj, event|
		close_tooltips
	}
	if bc == 6 
		b.signal_connect("button_release_event") { |obj, event|
			TileHelpers.vcrypt_wrapper(b, vcryptopenbutton)
		}
		vcryptopenbutton.signal_connect("button_release_event") { |obj, event|
			TileHelpers.vcrypt_wrapper(b, vcryptopenbutton)
		}
	end
	bc += 1
}

fixed.signal_connect("leave_notify_event") {
	close_tooltips
}

# Now initialize all screens:
@modlayers = Hash.new # Hash to contain all named screens

# Network screen
@networkscreen = NetworkScreen.new(@modlayers)
@networkscreen.layers.each { |k| fixed.put(k, 308, 162) }

# Now Rescue
@rescuescreen = RescueScreen.new(@modlayers, Gtk::EventBox.new, Gtk::EventBox.new, @networkscreen)
@rescuescreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now Samba/iSCSI
@sambascreen = SambaScreen.new(@modlayers, Gtk::EventBox.new, @networkscreen)
@sambascreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now WindowsScreen
@windowsscreen = WindowsScreen.new(@modlayers, Gtk::EventBox.new, @networkscreen)
@windowsscreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now WindowsScreen
@photorecscreen = PhotorecScreen.new(@modlayers, [ Gtk::EventBox.new, Gtk::EventBox.new, Gtk::EventBox.new] )
@photorecscreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now DvdRescueScreen
@dvdrescuescreen = DvdRescueScreen.new(@modlayers, Gtk::EventBox.new, @rescuescreen)
@dvdrescuescreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now MailRescueScreen
@mailrescuescreen = MailRescueScreen.new(@modlayers, Gtk::EventBox.new, @networkscreen)
@mailrescuescreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now FfRescueScreen
@ffrescuescreen = FfRescueScreen.new(@modlayers, Gtk::EventBox.new, @networkscreen)
@ffrescuescreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now WordRescueScreen
@wordrescuescreen = WordRescueScreen.new(@modlayers)
@wordrescuescreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now SingleFileRescue
@filerescuescreen = SingleFileRescue.new(@modlayers)
@filerescuescreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now DeleteScreen
@deletescreen = DeleteScreen.new(@modlayers, Gtk::EventBox.new)
@deletescreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now VirusScreen
@virusscreen = VirusScreen.new(@modlayers, Gtk::EventBox.new, @networkscreen)
@virusscreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now ChntpwScreen
@chntpwscreen = ChntpwScreen.new(@modlayers, Gtk::EventBox.new, @networkscreen)
@chntpwscreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now UsbRescueScreen
@usbrescuescreen = UsbRescueScreen.new(@modlayers)
@usbrescuescreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now PcInspectorScreen
@pcinspectorscreen = PcInspectorScreen.new(@modlayers, Gtk::EventBox.new, @networkscreen, Gtk::EventBox.new, @simulate)
@pcinspectorscreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now UsbRescueScreen
@imagescreen = ImageScreen.new(@modlayers)
@imagescreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now CloneScreen
@clonescreen = CloneScreen.new(@modlayers, @networkscreen)
@clonescreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now CloneScreen
@infoscreen = InfoScreen.new(@modlayers, Gtk::EventBox.new, @networkscreen)
@infoscreen.layers.each { |k| fixed.put(k, 308, 162) }
# USB install screen
@usbinstallscreen = UsbInstallScreen.new(@modlayers, Gtk::EventBox.new)
@usbinstallscreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now CheckScreen
@checkscreen = CheckScreen.new(@modlayers, @simulate)
@checkscreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now LicenseRecoverScreen
@licrecoverscreen = LicenseRecoverScreen.new(@modlayers)
@licrecoverscreen.layers.each { |k| fixed.put(k, 308, 162) }
# Now MozillaRecoverScreen
@mozrecoverscreen = MozillaRecoverScreen.new(@modlayers)
@mozrecoverscreen.layers.each { |k| fixed.put(k, 308, 162) }

# We need one layer as dummy, fallback
dummy = Gtk::Fixed.new
dummy.put(TileHelpers.create_label(@tl.get_translation("error_pageflow"), 380), 0, 130)
TileHelpers.place_back(dummy, @modlayers)
fixed.put(dummy, 308, 162)
@modlayers["start"] = dummy


# Start and show everything



window.add fixed
window.show_all 
@active_boxes_left.each{ |b| b.hide_all }
@inactive_boxes_left.each{ |b| b.show_all }
@inactive_boxes_left[0].hide_all 
@active_boxes_left[0].show_all 
@rightboxes.each { |n|
	n.each { |o|
		o.hide_all
	}
}
@modlayers.each { |k, v| 
	puts "Layer: #{k}"
	v.hide_all 
}
@rightboxes[0].each { |o| o.show_all }
@groupnames.each { |n| n.hide_all }
@groupnames[0].show_all 
if @checkscreen.show == true
	change_active_screen("checkscreen") 
elsif @forcescreen == true
	change_active_screen(@start) 
end
$startup_finished = true
Gtk.main
