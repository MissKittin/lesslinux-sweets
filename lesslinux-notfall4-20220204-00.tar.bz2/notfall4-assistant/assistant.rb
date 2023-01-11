#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'vte'
require "rexml/document"
require 'optparse'
require 'InfoScreen'
require 'SambaScreen'
require 'WindowsScreen'
require 'PhotorecScreen'
# require 'MobilerecScreen'
require 'RescueScreen'
require 'VirusScreen'
require 'ChntpwScreen'
require 'DeleteScreen'
require 'CloneScreen'
require 'TileHelpers'
require 'NetworkScreen' 
require 'CheckScreen'
require 'UsbInstallScreen'
require 'DvdRescueScreen' 
require 'ImageScreen'
require 'PcInspectorScreen'
require 'MailRescueScreen' 
require 'FfRescueScreen' 
require 'ChrRescueScreen' 
require 'WordRescueScreen'
require 'UsbRescueScreen'
require 'SingleFileRescue' 
# require 'BlueInputTool' 

require 'MfsSinglePartition.rb'
require 'MfsDiskDrive.rb'
require 'MfsTranslator.rb'
require 'mahoro'

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

@simulate = Array.new
@deco = false
@start = nil
@forcescreen = false
@showhint = false 
@expertmode = false 

opts = OptionParser.new 
opts.on('-s', '--simulate', :REQUIRED ) { |i| i.split(",").each { |j| @simulate.push(j) } }
opts.on('--no-deco') { @deco = false } 
opts.on('--start', :REQUIRED ) { |i| 
	@start = i.strip 
	@forcescreen = true
} 
opts.parse!

# Check the dimensions of our screen 
system("scrot /var/run/lesslinux/screen.png")
dims = ` file /var/run/lesslinux/screen.png ` 
if dims =~ /([0-9]+)\sx\s([0-9]+)/ 
	puts $1
	puts $2 
	if $1.to_i < 1024 || $2.to_i < 600
		@deco = true
		@showhint = true 
	end
end

def check_battery(battboxes) 
	#~ "batt0.png", # Unknown state
	#~ "batt1.png", # empty not charging
	#~ "batt2.png", # 1/3 not charging
	#~ "batt3.png", # 2/3 not charging
	#~ "batt4.png", # 3/3 not charging
	#~ "batt5.png", # empty charging
	#~ "batt6.png", # 1/3 charging
	#~ "batt7.png", # 2/3 charging
	#~ "batt8.png", # full charging 
	battboxes.each { |b| b.hide_all }
	return true unless File.directory?("/sys/class/power_supply/BAT0")
	percentage = 0
	percentage = File.read("/sys/class/power_supply/BAT0/capacity").to_i if File.exists?("/sys/class/power_supply/BAT0/capacity")
	status = nil
	status = File.read("/sys/class/power_supply/BAT0/status") if File.exists?("/sys/class/power_supply/BAT0/status")
	if status =~ /Unknown/ 
		battboxes[0].show_all
	elsif status =~ /Charging/
		if percentage < 15 
			battboxes[5].show_all
		elsif percentage >= 15 && percentage < 50
			battboxes[6].show_all
		elsif percentage >= 50 && percentage < 84
			battboxes[7].show_all
		else
			battboxes[8].show_all
		end
	else
		if percentage < 15 
			battboxes[1].show_all
		elsif percentage >= 15 && percentage < 50
			battboxes[2].show_all
		elsif percentage >= 50 && percentage < 84
			battboxes[3].show_all
		else
			battboxes[4].show_all
		end
	end
end

# TileHelpers.umount_all
# bluetool = BlueInputTool.new 

window = Gtk::Window.new
window.border_width = 10
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.icon = "iconassi.png"

window.deletable = false
window.allow_grow = false
window.allow_shrink = false
window.decorated = false if @deco == false

window.title = "Notfall-DVD"
window.signal_connect('delete_event') { false }
window.signal_connect('destroy') { 
	system("rm /var/run/lesslinux/assistant_running")
	Gtk.main_quit
}

# Layout table

table = Gtk::Table.new(4,    7,    false)
table.row_spacings = 10
table.column_spacings = 10

button = Array.new
imagefiles = [  "reparieren", "viren", "deletelightgreen", "password120", "recover", "viewdoc", "samba", "rescue", "shutdown", "desktop", "info", "usbinstall", "dvdrescue", "pcinspector", "filerepair", "drivebackup" ]
0.upto(imagefiles.size - 1) { |n|
	if File.exists?("#{imagefiles[n]}.#{$lang}.png")
		button[n] = Gtk::EventBox.new.add Gtk::Image.new("#{imagefiles[n]}.#{$lang}.png")
	else
		button[n] = Gtk::EventBox.new.add Gtk::Image.new("#{imagefiles[n]}.png")
	end
}

desctexts = [ 
	@tl.get_translation("maincrash"),
	@tl.get_translation("mainvirus"),
	@tl.get_translation("mainshred"),
	@tl.get_translation("mainchntpw"), 
	@tl.get_translation("mainresc"), 
	@tl.get_translation("docblahblah"), 
	@tl.get_translation("mainsave"), 
	@tl.get_translation("maincloud"), 
	@tl.get_translation("mainshutdown"),
	@tl.get_translation("maindesk"), 
	@tl.get_translation("mainmore"), 
	@tl.get_translation("mainusb"), 
	@tl.get_translation("maindvd"),
	@tl.get_translation("pcinspector"),
	@tl.get_translation("filerepair"),
	@tl.get_translation("drivebackup"),
]
descriptions = Hash.new
infolabel = Gtk::Label.new
infolabel.set_markup("<span color='white'>" + @tl.get_translation("mainmouse") + "</span>")
infolabel.wrap = true
infolabel.width_request = 500

button.each { |b| b.set_size_request(120, 120) }
[ 0, 1].each { |n|
	button[n].set_size_request(250, 120)
}
# [ 2, 3, 6, 7, 8, 9, 10, 11, 12 ].each { |n|
#	button[n].set_size_request(120, 120)
# }


0.upto(15) { |n|
	descriptions[button[n]] = desctexts[n]
	button[n].signal_connect('enter-notify-event') { |x, y|
		# puts "Entered: " + descriptions[x]
		infolabel.set_markup("<span color='white'>" + descriptions[x] + "</span>")
	}
	#button[n].signal_connect('button-release-event') { |x, y|
	#	if y.button == 1 
	#		# puts "Clicked: " + descriptions[x]
	#	elsif y.button == 3 && x == button[10]
	#		system("wicd-gtk -n &") 
	#	end
	#}
}

options = Gtk::FILL|Gtk::EXPAND|Gtk::SHRINK
# erste Reihe zweispaltig 1. und 2.
table.attach(button[0],  0,  2,  0,  1, options, options, 0,    0)
# erste Reihe zweispaltig 3. und 4.
table.attach(button[4],  2,  4,  0,  1, options, options, 0,    0)
# erste Reihe zweispaltig 5. und 6. (alt)
# erste Reihe einspaltig 5. (neu) <- neues Icon
table.attach(button[14],  4,  5,  0,  1, options, options, 0,    0)
# erste Reihe einspaltig 7. (alt)
# erste Reihe einspaltig 6. (neu)
table.attach(button[7],  5,  6,  0,  1, options, options, 0,    0)
# erste Reihe einspaltig 7. (neu) <- neues Icon, neuer Button
table.attach(button[15],  6,  7,  0,  1, options, options, 0,    0)

# zweite Reihe einspaltig 1. 
table.attach(button[5],  0,  1,  1,  2, options, options, 0,    0)
# zweite Reihe einspaltig 2. 
table.attach(button[12],  1,  2,  1,  2, options, options, 0,    0)
# zweite Reihe einspaltig 3. 
table.attach(button[3],  2,  3,  1,  2, options, options, 0,    0)
# zweite Reihe einspaltig 4. 
table.attach(button[2],  3,  4,  1,  2, options, options, 0,    0)
# zweite Reihe einspaltig 5. 
table.attach(button[6],  4,  5,  1,  2, options, options, 0,    0)
# zweite Reihe zweispaltig 6 und 7.
table.attach(button[1],  5,  7,  1,  2, options, options, 0,    0)

# table.attach(button[11],  3,  4,  1,  2, options, options, 0,    0)
# table.attach(button[2],  4,  5,  1,  2, options, options, 0,    0)

# dritte Reihe Textfeld vierspaltig.
table.attach(infolabel,  0,  4,  2,  3, options, options, 0,    0)
# dritte Reihe zweispaltig 5 und 6.
table.attach(button[13],  4,  6,  2,  3, options, options, 0,    0)
# dritte Reihe einspaltig 7. 
table.attach(button[9],  6,  7,  2,  3, options, options, 0,    0)

# table.attach(button[14],  4,  5,  2,  3, options, options, 0,    0)
# table.attach(button[10], 3,  4,  2,  3, options, options, 0,    0)
# table.attach(button[8],  4,  5,  2,  3, options, options, 0,    0)

0.upto(6) { |n|
	x = Gtk::Image.new("placeholder.png")
	x.set_size_request(120, 1)
	table.attach(x,  n,  n+1,  3,  4, options, options, 0,    0)
}



table.width_request = 900 

window.set_size_request(972, 548)
window.border_width = 0

imgfile = "bg_notfall-80.png"
imgfile = "bg_notfall-80.#{$lang}.png" if File.exists? "bg_notfall-80.#{$lang}.png"
imgfile = "/etc/lesslinux/branding/bg_notfall-80.#{$lang}.png" if File.exists? "/etc/lesslinux/branding/bg_notfall-80.#{$lang}.png"
bgimg = Gtk::Image.new(imgfile)


# buttons for shutdown and info and smaller tasks
wifibutton = Gtk::EventBox.new.add Gtk::Image.new("wifibutton.png")
infobutton = Gtk::EventBox.new.add Gtk::Image.new("infobutton.png")
exitbutton = Gtk::EventBox.new.add Gtk::Image.new("exitbutton.png")
kbdbutton = Gtk::EventBox.new.add Gtk::Image.new("keyboard.png")
tvbutton = Gtk::EventBox.new.add Gtk::Image.new("teamviewer.png")
usbbutton = Gtk::EventBox.new.add Gtk::Image.new("usbsmall.png")
vcryptbutton = Gtk::EventBox.new.add Gtk::Image.new("vcbutton.png")
vcryptopenbutton = Gtk::EventBox.new.add Gtk::Image.new("vcbuttonopen.png")

infobutton.signal_connect('enter-notify-event') { |x, y|
	infolabel.set_markup("<span color='white'>" + @tl.get_translation("mainmore") + "</span>")
}
infobutton.signal_connect('button-release-event') { |x, y|
	if y.button == 3
		system("lxqt-config-monitor &") 
	elsif y.button == 2
		system("xfce4-terminal &")
	end
}
exitbutton.signal_connect('button-release-event') { |x, y|
	if y.button == 3
		system("gnome-screenshot -i &") 
	elsif y.button == 2
		system("/usr/bin/teamviewer.sh &")
	end
}
wifibutton.signal_connect('button-release-event') { |x, y|
	system("connman-gtk &") 
}
wifibutton.signal_connect('enter-notify-event') { |x, y|
	infolabel.set_markup("<span color='white'>" + @tl.get_translation("wifidetails") + "</span>")
}
exitbutton.signal_connect('enter-notify-event') { |x, y|
	infolabel.set_markup("<span color='white'>" + @tl.get_translation("mainshutdown") + "</span>")
}
kbdbutton.signal_connect('enter-notify-event') { |x, y|
	infolabel.set_markup("<span color='white'>" + @tl.get_translation("mainkeyboard") + "</span>")
}
tvbutton.signal_connect('enter-notify-event') { |x, y|
	infolabel.set_markup("<span color='white'>" + @tl.get_translation("mainteamviewer") + "</span>")
}
usbbutton.signal_connect('enter-notify-event') { |x, y|
	infolabel.set_markup("<span color='white'>" + @tl.get_translation("mainusb") + "</span>")
}
vcryptbutton.signal_connect('enter-notify-event') { |x, y|
	infolabel.set_markup("<span color='white'>" + @tl.get_translation("vcryptcontainerinfo") + "</span>")
}
vcryptbutton.signal_connect('button-release-event') { |x, y|
	TileHelpers.vcrypt_wrapper(vcryptbutton, vcryptopenbutton)
}
vcryptopenbutton.signal_connect('enter-notify-event') { |x, y|
	infolabel.set_markup("<span color='white'>" + @tl.get_translation("vcryptcontainerinfo") + "</span>")
}
vcryptopenbutton.signal_connect('button-release-event') { |x, y|
	TileHelpers.vcrypt_wrapper(vcryptbutton, vcryptopenbutton)
}

# inner fixed 
ifixed = Gtk::Fixed.new
ifixed.put(table, 0, 48)
ifixed.put(vcryptopenbutton, 689, 4)
ifixed.put(vcryptbutton, 689, 4)
# ifixed.put(vcryptbutton, 689, 4)
ifixed.put(wifibutton, 717, 0)
ifixed.put(usbbutton, 744, 0)
ifixed.put(tvbutton, 780, 0)
ifixed.put(kbdbutton, 811, 0)
ifixed.put(infobutton, 850, 0)
ifixed.put(exitbutton, 877, 0)

# Battery symbols 

battery = [
	"batt0.png", # Unknown state
	"batt1.png", # empty not charging
	"batt2.png", # 1/3 not charging
	"batt3.png", # 2/3 not charging
	"batt4.png", # 3/3 not charging
	"batt5.png", # empty charging
	"batt6.png", # 1/3 charging
	"batt7.png", # 2/3 charging
	"batt8.png", # full charging 
]

battboxes = []

battery.each { |b|
	bb = Gtk::EventBox.new.add Gtk::Image.new(b) 
	battboxes.push bb
	ifixed.put(bb, 662, 2)
	bb.hide_all
	bb.signal_connect('button-release-event') {
		system("su surfer -c \"conky -c /usr/share/lesslinux/notfallcd4/conkyrc.window\" &")
	}
}
# battboxes[0].show_all 


fixed = Gtk::Fixed.new
fixed.put(bgimg, 0, 0)
fixed.put(ifixed, 35, 88)

#
# Now create some objects for each task - return windows as "named layers"
# 

layers = Hash.new
layers["start"] = ifixed
ifixed.signal_connect("show") {
	system("wmctrl -r Notfall-DVD -b add,below") 
	check_battery(battboxes) 
#	bluetool.connect_everything if $startup_finished == false  
	if system("mountpoint /media/tresor")
		vcryptopenbutton.show_all
		vcryptbutton.hide_all
	else
		vcryptbutton.show_all
		vcryptopenbutton.hide_all
	end
}

# Network screen
networkscreen = NetworkScreen.new(layers)
networkscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now the Samba share
sambascreen = SambaScreen.new(layers, button[6], networkscreen)
sambascreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now fix windows
winfixscreen = WindowsScreen.new(layers, button[0], networkscreen)
winfixscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Word rescue screen
wordrescscreen = WordRescueScreen.new(layers)
wordrescscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Single file rescue
singlefilerescscreen = SingleFileRescue.new(layers) 
singlefilerescscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now Photorec
# photorecscreen = PhotorecScreen.new(layers, [ button[4], button[5], button[14], winfixscreen.gpartbutton, wordrescscreen.button, singlefilerescscreen.button ] )
photorecscreen = PhotorecScreen.new(layers, [ button[4], Gtk::EventBox.new.add(Gtk::Image.new("wifibutton.png")), button[14], winfixscreen.gpartbutton, wordrescscreen.button, singlefilerescscreen.button ] )
photorecscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now Photorec
# mobilerecscreen = MobilerecScreen.new(layers, button[5])
# mobilerecscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now Rescue
rescuescreen = RescueScreen.new(layers, button[7], button[15], networkscreen)
rescuescreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now virus screen
virusscreen = VirusScreen.new(layers, button[1], networkscreen)
virusscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Check screen (bad memory, hibernation, Intel IMSM)
checkscreen = CheckScreen.new(layers, @simulate)
checkscreen.layers.each { |k| fixed.put(k, 35, 136) }

# The simple info screen
infoscreen = InfoScreen.new(layers, infobutton, networkscreen, virusscreen.scanner, checkscreen.show)
infoscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now chntpw screen
chntpwscreen = ChntpwScreen.new(layers, button[3], networkscreen )
chntpwscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Delete screen
deletescreen = DeleteScreen.new(layers, button[2] )
deletescreen.layers.each { |k| fixed.put(k, 35, 136) }

# Clone screen
clonescreen = CloneScreen.new(layers, networkscreen)
clonescreen.layers.each { |k| fixed.put(k, 35, 136) }

# Image screen
imagescreen = ImageScreen.new(layers)
imagescreen.layers.each { |k| fixed.put(k, 35, 136) }

# USB installation
usbscreen = UsbInstallScreen.new(layers, usbbutton)
usbscreen.layers.each { |k| fixed.put(k, 35, 136) }

# DVD rescue screen
dvdscreen = DvdRescueScreen.new(layers, button[12], photorecscreen)
dvdscreen.layers.each { |k| fixed.put(k, 35, 136) }

# USB rescue screen
usbrescuescreen = UsbRescueScreen.new(layers)
usbrescuescreen.layers.each { |k| fixed.put(k, 35, 136) }

# PC Inspector 
inspectorscreen = PcInspectorScreen.new(layers, button[13], networkscreen, usbrescuescreen.button, @simulate)
inspectorscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Mail Rescue Tool
mailrescuescreen = MailRescueScreen.new(layers, photorecscreen.mailbutton, networkscreen)
mailrescuescreen.layers.each { |k| fixed.put(k, 35, 136) }

# Firefox Rescue Tool
ffrescuescreen = FfRescueScreen.new(layers, photorecscreen.firefoxbutton, networkscreen)
ffrescuescreen.layers.each { |k| fixed.put(k, 35, 136) }

# Chrome Rescue Tool
chrrescuescreen = ChrRescueScreen.new(layers, photorecscreen.chromebutton, networkscreen)
chrrescuescreen.layers.each { |k| fixed.put(k, 35, 136) }

# No separate layer for desktop mode
button[9].signal_connect('button-release-event') {
	TileHelpers.umount_all
	TileHelpers.mount_usbdata
	# system("touch /home/surfer/.ll_requested_desktop")
	# system("chown 1000:1000 /home/surfer/.ll_requested_desktop")
	# Gtk.main_quit 
	if (@expertmode == false)
		winwidth = 0
		system("scrot /var/run/lesslinux/screen.png")
		dims = ` file /var/run/lesslinux/screen.png ` 
		if dims =~ /([0-9]+)\sx\s([0-9]+)/ 
			winwidth = $1.to_i
		end
		system("esetroot -scale /usr/share/lesslinux/notfallcd4/bg0000pxdark.png")
		system("compton &") 
		system("su surfer -c 'PATH=/usr/bin:/bin:/usr/sbin:/sbin:/static/bin:/static/sbin cairo-dock' &") 
		# system("su surfer -c xfce4-panel &")
		#if winwidth > 1439
		#	system('su surfer -c "conky -c /usr/share/lesslinux/notfallcd4/conkyrc.desktop -d" &')
		#else
		#	system('su surfer -c "conky -c /usr/share/lesslinux/notfallcd4/conkyrc.window -d" &')
		#end
		@expertmode = true 
		# window.decorated = true
	else 
		system("killall -9 cairo-dock")
		system("killall -9 conky") 
		system("esetroot -scale /usr/share/lesslinux/notfallcd4/bg0000px.png")
		@expertmode = false 
		# window.decorated = false 
	end
}

# No separate layer for shutdown
exitbutton.signal_connect('button-release-event') {
	# system("touch /var/run/lesslinux/requested_shutdown")
	system("/usr/bin/shutdown-wrapper.sh") 
}
button[8].signal_connect('button-release-event') {
	# system("touch /var/run/lesslinux/requested_shutdown")
	system("/usr/bin/shutdown-wrapper.sh") 
}

kbdbutton.signal_connect('button-release-event') {
	system('nohup xvkbd &') 
}

tvbutton.signal_connect('button-release-event') {
	system("wmctrl -r Notfall-DVD -b add,below") 
	if networkscreen.test_connection == false
		#networkscreen.nextscreen = "start"
		#networkscreen.fill_wlan_combo 
		#layers.each { |k,v|v.hide_all }
		#layers["networks"].show_all
		system("su surfer -c /usr/bin/connman-gtk &") 
	end
	# system('/usr/bin/teamviewer.sh &') 
	system("su surfer -c /opt/teamviewer/teamviewer/tv_bin/TeamViewer &")
	0.upto(100) { |n|
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 0.1
	}
	if TileHelpers.yes_no_dialog(@tl.get_translation("wannarestartgui"))
		system("killall -15 teamviewerd")
		sleep 3.0
		system("/opt/teamviewer/teamviewer/tv_bin/teamviewerd -d")
		system("touch /home/surfer/.start_teamviewer")
		system("chown surfer:surfer /home/surfer/.start_teamviewer")
		system("killall -15 lxdm-binary")
	end
	
}

button[5].signal_connect('button-release-event') {
	unless $lang == "pl" # || system("grep S.A.D /etc/lesslinux/branding/branding.en.sh")
		layers.each { |k,v|v.hide_all }
		layers["pcinspdoc"].show_all
	else
		manualdir = "/usr/share/lesslinux/notfallcd4/Anleitungen"
		manualdir = "/lesslinux/isoloop/Poradniki" if File.directory?("/lesslinux/isoloop/Poradniki") 
		manualdir = "/lesslinux/cdrom/Poradniki" if File.directory?("/lesslinux/cdrom/Poradniki") 
		system("su surfer -c 'thunar #{manualdir}' &")
	end
}

layers.keys.sort.each { |n|
	puts "Layer: " + n 
}

#
# Show everything
#

window.add fixed
window.show_all 
layers.each { |k,v| v.hide_all }

@start = "start" if @start.nil?

if File.exist?("/var/run/lesslinux/license_accepted") &&  checkscreen.show == true && @forcescreen == false 
	layers["checkscreen"].show_all 
elsif File.exist?("/var/run/lesslinux/license_accepted") || @forcescreen == true
	layers[@start].show_all 
else
	layers["legal"].show_all 
end
if system("mountpoint /media/tresor")
	vcryptopenbutton.hide_all
else
	vcryptopenbutton.hide_all
end
sleep 0.2
system("wmctrl -r Notfall-DVD -b add,below") 
system("esetroot -scale /usr/share/lesslinux/notfallcd4/bg0000px.png") 
TileHelpers.error_dialog( @tl.get_translation("lowresbody"), @tl.get_translation("lowreshead") ) if @showhint == true 

$startup_finished = true 

# networkscreen.network_dialog

Gtk.main

# bluetool.connect_everything # if $startup_finished == true 
