#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'vte'
require "rexml/document"
require 'optparse'
require "RescueScreen" 
require "VssScreen" 
require "VirusScreen"
require "OvasScreen" 
require "CloneScreen" 
require "ImageScreen"
require "OutlookRescueScreen" 
require 'FirefoxScreen' 
require 'LicenseScreen'

require "TileHelpers"
require 'mahoro'

# require "BackupScreen"
# require "CloneScreen" 
# require "VirusScreen"
# require "ShredderScreen"
# require "SambaScreen"
# require "LicenseScreen"
require "TileHelpers"
require "MfsTranslator"
require "MfsDiskDrive"
require "MfsSinglePartition"
# require "FileUtils"

# Constants for positions:

OK_X = 864
OK_Y = 536
CANCEL_X = 728
CANCEL_Y = 536
SETTINGS_X = 592
SETTINGS_Y = 536

$lastpulse = Time.now.to_f 

def create_hdd_layer(layers, fixed)
	hddfixed = Gtk::Fixed.new
	bgimg = Gtk::Image.new("background.png")
	layers["hddforensics"] = hddfixed 
	fixed.put(hddfixed,0,0)
	hddfixed.put(bgimg, 0, 0)
	 
	undel_button = Gtk::Button.new()
	undel_hbox = Gtk::HBox.new
	undel_hbox.pack_start_defaults Gtk::Image.new("icons/undelete.png")
	undel_label = Gtk::Label.new # (rescuescreen.start_label) 
	undel_label.set_markup @tl.get_translation("tile_photorec")
	undel_label.wrap = true 
	undel_label.width_request = 243
	undel_label.height_request = 194
	undel_hbox.pack_start_defaults undel_label 
	undel_button.add(undel_hbox) 
	hddfixed.put(undel_button, 200, 94)
	
	undel_button.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		@rescuescreen.reread_drivelist 
		layers["rescue_start"].show_all 
	}
	
	vss_button = Gtk::Button.new()
	vss_hbox = Gtk::HBox.new
	vss_hbox.pack_start_defaults Gtk::Image.new("icons/schattenkopie.png")
	vss_label = Gtk::Label.new # (rescuescreen.start_label) 
	vss_label.set_markup @tl.get_translation("tile_vss")
	vss_label.wrap = true 
	vss_label.width_request = 243
	vss_label.height_request = 194
	vss_hbox.pack_start_defaults vss_label 
	vss_button.add(vss_hbox) 
	hddfixed.put(vss_button, 596, 94)
	
	vss_button.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		@vssscreen.reread_drivelist 
		layers["vss_start"].show_all 
	}
	
	virus_button = Gtk::Button.new()
	virus_hbox = Gtk::HBox.new
	virus_hbox.pack_start_defaults Gtk::Image.new("icons/virusscan-green.png")
	virus_label = Gtk::Label.new # (rescuescreen.start_label) 
	virus_label.set_markup @tl.get_translation("tile_avira")
	virus_label.wrap = true 
	virus_label.width_request = 243
	virus_label.height_request = 194
	virus_hbox.pack_start_defaults virus_label 
	virus_button.add(virus_hbox) 
	hddfixed.put(virus_button, 200, 312)
	
	virus_button.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		@virusscreen.reread_drivelist 
		layers["virus_start"].show_all 
	}
	
	cache_button = Gtk::Button.new()
	cache_hbox = Gtk::HBox.new
	cache_hbox.pack_start_defaults Gtk::Image.new("icons/datenrettung_green.png")
	cache_label = Gtk::Label.new # (rescuescreen.start_label) 
	cache_label.set_markup @tl.get_translation("tile_sort")
	cache_label.wrap = true 
	cache_label.width_request = 243
	cache_label.height_request = 194
	cache_hbox.pack_start_defaults cache_label 
	cache_button.add(cache_hbox) 
	hddfixed.put(cache_button, 596, 312)
	
	cache_button.signal_connect("clicked") { 
		system("photorec-sorter.sh &") 
		# layers.each { |k,v| v.hide_all }
		# @virusscreen.reread_drivelist 
		# layers["virus_start"].show_all 
	}
	
	
	cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
	cancel.width_request = 128
	cancel.height_request = 32 
	cancel.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		layers["start"].show_all 
	}
	hddfixed.put(cancel, OK_X, OK_Y)
end

def create_block_layer(layers, fixed) 
	blockfixed = Gtk::Fixed.new
	bgimg = Gtk::Image.new("background.png")
	layers["blocktools"] = blockfixed 
	fixed.put(blockfixed,0,0)
	blockfixed.put(bgimg, 0, 0)
	 
	image_button = Gtk::Button.new()
	image_hbox = Gtk::HBox.new
	image_hbox.pack_start_defaults Gtk::Image.new("icons/laufwerkklonen_green.png")
	image_label = Gtk::Label.new # (rescuescreen.start_label) 
	image_label.set_markup @tl.get_translation("tile_image")
	image_label.wrap = true 
	image_label.width_request = 243
	image_label.height_request = 194
	image_hbox.pack_start_defaults image_label 
	image_button.add(image_hbox) 
	blockfixed.put(image_button, 200, 94)
	
	image_button.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		@imagescreen.fill_target_combo
		layers["image_start"].show_all 
	}
	
	clone_button = Gtk::Button.new()
	clone_hbox = Gtk::HBox.new
	clone_hbox.pack_start_defaults Gtk::Image.new("icons/backup_green.png")
	clone_label = Gtk::Label.new # (rescuescreen.start_label) 
	clone_label.set_markup @tl.get_translation("tile_clone")
	clone_label.wrap = true 
	clone_label.width_request = 243
	clone_label.height_request = 194
	clone_hbox.pack_start_defaults clone_label 
	clone_button.add(clone_hbox) 
	blockfixed.put(clone_button, 596, 94)
	
	clone_button.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		@clonescreen.reread_drivelist 
		layers["clone_start"].show_all 
	}
	
	vm_button = Gtk::Button.new()
	vm_hbox = Gtk::HBox.new
	vm_hbox.pack_start_defaults Gtk::Image.new("icons/run_image.png")
	vm_label = Gtk::Label.new # (rescuescreen.start_label) 
	vm_label.set_markup @tl.get_translation("tile_qemu")
	vm_label.wrap = true 
	vm_label.width_request = 243
	vm_label.height_request = 194
	vm_hbox.pack_start_defaults vm_label 
	vm_button.add(vm_hbox) 
	blockfixed.put(vm_button, 200, 312)
	
	vm_button.signal_connect("clicked") { 
		#layers.each { |k,v| v.hide_all }
		#@vmscreen.reread_drivelist 
		#layers["vm_start"].show_all 
		system("/usr/bin/qemustarter.sh &") 
	}
	
	zap_button = Gtk::Button.new()
	zap_hbox = Gtk::HBox.new
	zap_hbox.pack_start_defaults Gtk::Image.new("icons/erase_green.png")
	zap_label = Gtk::Label.new # (rescuescreen.start_label) 
	zap_label.set_markup @tl.get_translation("tile_wipe")
	zap_label.wrap = true 
	zap_label.width_request = 243
	zap_label.height_request = 194
	zap_hbox.pack_start_defaults zap_label 
	zap_button.add(zap_hbox) 
	blockfixed.put(zap_button, 596, 312)
	
	zap_button.signal_connect("clicked") { 
		# layers.each { |k,v| v.hide_all }
		# @virusscreen.reread_drivelist 
		# layers["virus_start"].show_all 
		system("/usr/bin/deletedisk.sh &") 
	}
	
	
	cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
	cancel.width_request = 128
	cancel.height_request = 32 
	cancel.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		layers["start"].show_all 
	}
	blockfixed.put(cancel, OK_X, OK_Y)
end


def create_net_layer(layers, fixed)
	netfixed = Gtk::Fixed.new
	bgimg = Gtk::Image.new("background.png")
	layers["netforensics"] = netfixed 
	fixed.put(netfixed,0,0)
	netfixed.put(bgimg, 0, 0)
	 
	ovas_button = Gtk::Button.new()
	ovas_hbox = Gtk::HBox.new
	ovas_hbox.pack_start_defaults Gtk::Image.new("icons/netzwerk_forensic.png")
	ovas_label = Gtk::Label.new # (rescuescreen.start_label) 
	ovas_label.set_markup @tl.get_translation("tile_ovas")
	ovas_label.wrap = true 
	ovas_label.width_request = 243
	ovas_label.height_request = 194
	ovas_hbox.pack_start_defaults ovas_label 
	ovas_button.add(ovas_hbox) 
	netfixed.put(ovas_button, 200, 94)
	
	ovas_button.signal_connect("clicked") { 
		if @ovasscreen.check_environment
			layers.each { |k,v| v.hide_all }
			# @rescuescreen.reread_drivelist 
			layers["ovas_start"].show_all 
		end
	}
	
	ws_button = Gtk::Button.new()
	ws_hbox = Gtk::HBox.new
	ws_hbox.pack_start_defaults Gtk::Image.new("icons/wireshark2.png")
	ws_label = Gtk::Label.new # (rescuescreen.start_label) 
	ws_label.set_markup @tl.get_translation("tile_wireshark")
	ws_label.wrap = true 
	ws_label.width_request = 243
	ws_label.height_request = 194
	ws_hbox.pack_start_defaults ws_label 
	ws_button.add(ws_hbox) 
	netfixed.put(ws_button, 596, 94)
	
	ws_button.signal_connect("clicked") { 
		system("su surfer -c wireshark-gtk &") 
		#layers.each { |k,v| v.hide_all }
		# @vssscreen.reread_drivelist 
		# layers["vss_start"].show_all 
	}
	
	zenm_button = Gtk::Button.new()
	zenm_hbox = Gtk::HBox.new
	zenm_hbox.pack_start_defaults Gtk::Image.new("icons/nmap.png")
	zenm_label = Gtk::Label.new # (rescuescreen.start_label) 
	zenm_label.set_markup @tl.get_translation("tile_nmap")
	zenm_label.wrap = true 
	zenm_label.width_request = 243
	zenm_label.height_request = 194
	zenm_hbox.pack_start_defaults zenm_label 
	zenm_button.add(zenm_hbox) 
	netfixed.put(zenm_button, 200, 312)
	
	zenm_button.signal_connect("clicked") { 
		system("/usr/bin/zenmap &") 
		# layers.each { |k,v| v.hide_all }
		# @virusscreen.reread_drivelist 
		# layers["virus_start"].show_all 
	}

	ap_button = Gtk::Button.new()
	ap_hbox = Gtk::HBox.new
	ap_hbox.pack_start_defaults Gtk::Image.new("icons/WIFI.png")
	ap_label = Gtk::Label.new # (rescuescreen.start_label) 
	ap_label.set_markup @tl.get_translation("tile_ap")
	ap_label.wrap = true 
	ap_label.width_request = 243
	ap_label.height_request = 194
	ap_hbox.pack_start_defaults ap_label 
	ap_button.add(ap_hbox) 
	netfixed.put(ap_button, 596, 312)
	
	ap_button.signal_connect("clicked") { 
		 system("/usr/bin/accesspoint.sh &") 
	}
	
	cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
	cancel.width_request = 128
	cancel.height_request = 32 
	cancel.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		layers["start"].show_all 
	}
	netfixed.put(cancel, OK_X, OK_Y)
end

def create_history_layer(layers, fixed)
	historyfixed = Gtk::Fixed.new
	bgimg = Gtk::Image.new("background.png")
	layers["history_start"] = historyfixed 
	fixed.put(historyfixed,0,0)
	historyfixed.put(bgimg, 0, 0)
	 
	ff_button = Gtk::Button.new()
	ff_hbox = Gtk::HBox.new
	ff_hbox.pack_start_defaults Gtk::Image.new("icons/Browser_emial_chat.png")
	ff_label = Gtk::Label.new # (rescuescreen.start_label) 
	ff_label.set_markup @tl.get_translation("tile_firefox")
	ff_label.wrap = true 
	ff_label.width_request = 243
	ff_label.height_request = 194
	ff_hbox.pack_start_defaults ff_label 
	ff_button.add(ff_hbox) 
	historyfixed.put(ff_button, 200, 94)
	
	ff_button.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		@firefoxscreen.reread_drivelist 
		layers["firefox_start"].show_all 
	}
	
	outlook_button = Gtk::Button.new()
	outlook_hbox = Gtk::HBox.new
	outlook_hbox.pack_start_defaults Gtk::Image.new("icons/backup_green.png")
	outlook_label = Gtk::Label.new # (rescuescreen.start_label) 
	outlook_label.set_markup @tl.get_translation("tile_outlook")
	outlook_label.wrap = true 
	outlook_label.width_request = 243
	outlook_label.height_request = 194
	outlook_hbox.pack_start_defaults outlook_label 
	outlook_button.add(outlook_hbox) 
	# historyfixed.put(outlook_button, 596, 94)
	historyfixed.put(outlook_button, 200, 312)
	
	outlook_button.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		@outlookscreen.reread_drivelist 
		layers["outlook_start"].show_all 
	}
	
	tb_button = Gtk::Button.new()
	tb_hbox = Gtk::HBox.new
	tb_hbox.pack_start_defaults Gtk::Image.new("icons/skype and others.png")
	tb_label = Gtk::Label.new # (rescuescreen.start_label) 
	tb_label.set_markup @tl.get_translation("tile_history2") 
	tb_label.wrap = true 
	tb_label.width_request = 243
	tb_label.height_request = 194
	tb_hbox.pack_start_defaults tb_label 
	tb_button.add(tb_hbox) 
	# historyfixed.put(tb_button, 200, 312)
	 historyfixed.put(tb_button, 596, 312)
	
	tb_button.signal_connect("clicked") { 
		system("/usr/bin/history-extractor.sh &") 
		# layers.each { |k,v| v.hide_all }
		# @virusscreen.reread_drivelist 
		# layers["virus_start"].show_all 
	}

	jumplist_button = Gtk::Button.new()
	jumplist_hbox = Gtk::HBox.new
	jumplist_hbox.pack_start_defaults Gtk::Image.new("icons/datenrettung_green.png")
	jumplist_label = Gtk::Label.new # (rescuescreen.start_label) 
	jumplist_label.set_markup @tl.get_translation("tile_jump")
	jumplist_label.wrap = true 
	jumplist_label.width_request = 243
	jumplist_label.height_request = 194
	jumplist_hbox.pack_start_defaults jumplist_label 
	jumplist_button.add(jumplist_hbox) 
	# historyfixed.put(jumplist_button, 596, 312)
	historyfixed.put(jumplist_button, 596, 94)
	
	jumplist_button.signal_connect("clicked") { 
		system("/usr/bin/jumplist-extractor.sh &") 
	}
	
	cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
	cancel.width_request = 128
	cancel.height_request = 32 
	cancel.signal_connect("clicked") { 
		layers.each { |k,v| v.hide_all }
		layers["start"].show_all 
	}
	historyfixed.put(cancel, OK_X, OK_Y)
end



lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
@tl = MfsTranslator.new(lang, "forensicgui.xml") 

# Identify the correct manual
manualpath = "/lesslinux/cdrom/Manual"
manualpath = "/lesslinux/isoloop/Manual" if File.directory?("/lesslinux/isoloop/Manual")
manualpath = "/lesslinux/cdrom/Manual" if File.directory?("/lesslinux/cdrom/Manual")
@manual = manualpath + "/SecuPerts_Forensic_System_en.pdf" 
@manual = manualpath + "/SecuPerts_Forensic_System_de.pdf" if lang == "de"

top_buttons = Array.new

window = Gtk::Window.new
window.set_size_request(1000, 576)
window.border_width = 0
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

window.deletable = false
window.decorated = false
window.allow_grow = false
window.allow_shrink = false
window.title = "ForensicGUI"

fixed = Gtk::Fixed.new

# Layers are stored in a Hash:

layers = Hash.new

# First layer for starting page

bgimg = Gtk::Image.new("background.png")
startfixed = Gtk::Fixed.new
layers["start"] = startfixed 
startfixed.put(bgimg, 0, 0)

# Layers provided by component "HddForensics"

# rescuescreen = RescueScreen.new(layers, fixed) 
hddfor_button = Gtk::Button.new()
hddfor_hbox = Gtk::HBox.new
hddfor_hbox.pack_start_defaults Gtk::Image.new("icons/datenrettung_green.png")
hddfor_label = Gtk::Label.new # (rescuescreen.start_label) 
hddfor_label.set_markup @tl.get_translation('tile_hdd')  
hddfor_label.wrap = true 
hddfor_label.width_request = 243
hddfor_label.height_request = 214
hddfor_hbox.pack_start_defaults hddfor_label 
hddfor_button.add(hddfor_hbox) 

hddfor_button.signal_connect("clicked") { 
	layers.each { |k,v| v.hide_all }
	layers["hddforensics"].show_all 
}
startfixed.put(hddfor_button, 200, 94)

# Layers provided by component "BrowserEmailChat"

# rescuescreen = RescueScreen.new(layers, fixed) 
browser_button = Gtk::Button.new()
browser_hbox = Gtk::HBox.new
browser_hbox.pack_start_defaults Gtk::Image.new("icons/Browser_emial_chat.png")
browser_label = Gtk::Label.new # (rescuescreen.start_label) 
browser_label.set_markup  @tl.get_translation('tile_history')  
browser_label.wrap = true 
browser_label.width_request = 243
browser_label.height_request = 214
browser_hbox.pack_start_defaults browser_label 
browser_button.add(browser_hbox) 

# rescue_button.image = Gtk::Image.new("icons/datenrettung_green.png")
browser_button.signal_connect("clicked") { 
	layers.each { |k,v| v.hide_all }
#	rescuescreen.reread_drivelist 
	layers["history_start"].show_all 
}
startfixed.put(browser_button, 596, 94)

# Layers provided by component "NetworksForensic"

# rescuescreen = RescueScreen.new(layers, fixed) 
nwfor_button = Gtk::Button.new()
nwfor_hbox = Gtk::HBox.new
nwfor_hbox.pack_start_defaults Gtk::Image.new("icons/netzwerk_forensic.png")
nwfor_label = Gtk::Label.new # (rescuescreen.start_label) 
nwfor_label.set_markup @tl.get_translation('tile_net')  
nwfor_label.wrap = true 
nwfor_label.width_request = 243
nwfor_label.height_request = 214
nwfor_hbox.pack_start_defaults nwfor_label 
nwfor_button.add(nwfor_hbox) 

nwfor_button.signal_connect("clicked") { 
	layers.each { |k,v| v.hide_all }
	layers["netforensics"].show_all 
}

startfixed.put(nwfor_button, 200, 334)

# Layers provided by component "CloneImageDelete"

# rescuescreen = RescueScreen.new(layers, fixed) 
image_button = Gtk::Button.new()
image_hbox = Gtk::HBox.new
image_hbox.pack_start_defaults Gtk::Image.new("icons/kategorie_icon_imaging_clone_delete_run_image.png")
image_label = Gtk::Label.new # (rescuescreen.start_label) 
image_label.set_markup @tl.get_translation('tile_block')  
image_label.wrap = true 
image_label.width_request = 243
image_label.height_request = 214
image_hbox.pack_start_defaults image_label 
image_button.add(image_hbox) 

# rescue_button.image = Gtk::Image.new("icons/datenrettung_green.png")
image_button.signal_connect("clicked") { 
	layers.each { |k,v| v.hide_all }
#	rescuescreen.reread_drivelist 
	layers["blocktools"].show_all 
}
startfixed.put(image_button, 596, 334)


# licensescreen = LicenseScreen.new(layers, fixed, top_buttons) 

@rescuescreen = RescueScreen.new(layers, fixed) 
@vssscreen = VssScreen.new(layers, fixed) 
@virusscreen = VirusScreen.new(layers, fixed) 
@ovasscreen = OvasScreen.new(layers, fixed) 
@clonescreen = CloneScreen.new(layers, fixed) 
@imagescreen = ImageScreen.new(layers, fixed) 
@outlookscreen = OutlookRescueScreen.new(layers, fixed) 
@firefoxscreen = FirefoxScreen.new(layers, fixed) 
@licensescreen = LicenseScreen.new(layers, fixed, top_buttons) 
create_hdd_layer(layers, fixed)
create_net_layer(layers, fixed)
create_block_layer(layers, fixed)
create_history_layer(layers, fixed)
fixed.put(startfixed,0,0)

# Icons shown in any mode - must be added latest!

button_count = 0
[ 
	"icons/help.png",
	"icons/browser.png", 
	"icons/network.png",
	"icons/usb.png", 
	"/usr/share/icons/Faenza/actions/32/down.png"
].each { |i| 
	puts "Using icon: #{i}"
	ico = Gtk::Button.new # Gtk::EventBox.new
	ico.image = Gtk::Image.new(i)
	fixed.put(ico, 753 + button_count*48, 9 )
	top_buttons.push(ico)
	button_count += 1
}
top_commands = [ 
	"evince #{@manual} &", 
	"su surfer -c firefox &",
	"connman-gtk &",
	"usbinstall.sh &",
	nil
]
0.upto(top_buttons.size - 1) { |n|
	top_buttons[n].signal_connect('button-release-event') { |x, y|
		if y.button == 1 
			unless top_commands[n].nil?
				tc = top_commands[n]
				system(tc)
			else
				window.iconify
			end
		elsif y.button == 3
			layers.each { |k,v| v.hide_all }
			top_buttons.each { |v| v.hide_all }
			layers["license"].show_all 
		end
	}
}

window.add fixed
window.signal_connect('destroy') { Gtk.main_quit }
window.show_all 
# unshow all layers
layers.each { |k,v| v.hide_all }
top_buttons.each { |v| v.hide_all }
if File.exist?("/var/run/lesslinux/license_accepted") 
	top_buttons.each { |v| v.show_all }
	layers["start"].show_all 
else
	layers["license"].show_all 
end		

Gtk.main