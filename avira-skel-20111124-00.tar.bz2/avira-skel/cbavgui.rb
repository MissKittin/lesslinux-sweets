#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'vte'
require "rexml/document"

#=============================================================================
#
# (c) Mattias Schlenker 2010 für Redaktion Computerbild
# 
# Alle Verwertungsrechte liegen bei Redaktion Computerbild
#
# Bei Fragen wenden Sie sich bitte an:
#
# Mattias Schlenker - Redaktion + EDV-Beratung + Linux-CD/DVD-Konzepte
# Kochstrasse 21 - 04275 LEIPZIG - GERMANY
#
# Telefon (VoIP "ueberall"), geschaeftlich: +49 341 39290767 
# Mobil, geschaeftlich:                     +49 163  6953657
#
# Bitte fuer geschaeftliche Telefonate vorzugsweise die VoIP-Telefonnummer
# +49 341 39290767 verwenden, da ich diese aufs Mobiltelefon routen kann!
#
# http://blog.rootserverexperiment.de/ http://news.mattiasschlenker.de/
#
#=============================================================================

#=============================================================================
#
# FIXME: This is weird copy and paste from the old installer
# This code is used to detect suitable USB target drives
#
#=============================================================================

class UsbDrive
	@device
	@vendor
	@product
	@size
	@partitions
	def initialize(dev)
		@device = dev
		@partitions = Hash.new
		@size = 0
		@vendor = "?"
		@product = "?"
	end
	attr_accessor :device, :vendor, :product, :partitions, :size
end

class UsbDrivePartition
	@device
	@size
	@version
	@mounted
	@mountpoint
	def initialize(dev)
		@size = 0
		@device = dev
		@mounted = false
		# now find mounted partitions
		IO.popen("mount") { |i|
			while i.gets
				tokens = $_.split
				if tokens[0] == dev
					@mounted = true
					@mountpoint = tokens[2]
				end
			end
		}
	end
	attr_accessor :device, :size, :version, :mounted, :mountpoint
end

def get_usbdrives_lshw
	all_drives = Hash.new
	xstring = ""
	begin
		IO.popen("lshw-static -xml") { |ioin|
			while ioin.gets
				xstring = xstring + $_
			end
		}
		xdoc = REXML::Document.new(xstring)
	rescue
		xdoc = REXML::Document.new("<empty><nix></nix></empty>")
	end
	# xdoc = REXML::Document.new(File.new("/tmp/lshw_sf2.xml"))
	xdoc.root.elements.each("//node[@class='storage']") { |x|
		begin
			businfo = "unknown"
			begin
				businfo = x.elements["businfo"].text.to_s
			rescue
			end
			x.elements.each("node[@class='disk']") { |element|
					if element.elements["logicalname"].text =~ /^\/dev\/sd/ && businfo =~ /^usb/
						# puts element.elements["logicalname"].text
						udrive = UsbDrive.new(element.elements["logicalname"].text)
						begin
							udrive.vendor = x.elements["vendor"].text
							udrive.product = x.elements["product"].text
						rescue
						end
						udrive.size = element.elements["size"].text.to_i
						all_parts = Hash.new
						element.elements.each("node[@class='volume']") { |vol|
							if vol.attributes["id"] =~ /^volume/  && vol.elements["description"].text =~ /fat/i
								begin
									npart = UsbDrivePartition.new(vol.elements["logicalname"].text)
									# puts vol.elements["logicalname"].text
									npart.size = vol.elements["capacity"].text.to_i
									puts vol.elements["capacity"].text.to_i
									npart.version = ""
									all_parts[vol.elements["logicalname"].text] = npart
								rescue
								end
							end
						}
						udrive.partitions = all_parts
						all_drives[element.elements["logicalname"].text] = udrive
					end
			}
			x.elements.each("node[@class='volume']") { |element|
				if element.elements["logicalname"].text =~ /^\/dev\/sd/ && businfo =~ /^usb/
					udrive = UsbDrive.new(element.elements["logicalname"].text)
					begin
						udrive.vendor = x.elements["vendor"].text
						udrive.product = x.elements["product"].text
					rescue
					end
				end
				udrive.size = element.elements["size"].text.to_i
				all_drives[element.elements["logicalname"].text] = udrive unless 
					all_drives.has_key?( element.elements["logicalname"].text )
			}
		rescue
		end
	}
	return all_drives
end

def create_drivelist(combobox, rows, usbdrives)
	(1023).downto(0) { |i| 
		# puts "removing " + i.to_s
		begin
			combobox.remove_text(i)
		rescue
		end
	}
	comborows = 0
	usable_drives = []
	usbdrives.each { |key, val| 
		if val.size > get_minsize
			puts "create drivelist entry " + key
			# Use Gigabytes if the drive is 8GB or larger 
			if val.size > 7_900_000_000
				sizestr = ((val.size.to_f / 1073741824 ) + 0.5).to_i.to_s + "GB"
			else
				sizestr = (val.size.to_f / 1048576 ).to_i.to_s + "MB"
			end
			combobox.append_text( val.vendor + " " + val.product + " " + sizestr )
			usable_drives.push(val)
		end
	}
	combobox.active = 0
	return usable_drives
end

def get_minsize 
	900_000_000
end

#=============================================================================
#
# END OF FIXME: This is weird copy and paste from the old installer
#
#=============================================================================

# Check the age of the signatures
#
# returns false if signatures need no update
# 
# false: file rescue_cd.key exists and is newer than 14 days
# true:  file vbase000.vdf is missing
# true:  file vbase000.vdf exists and is older than 14 days
# false: file vbase000.vdf exists and is younger than 14 days

def check_signature_age
	now = Time.new
	if system("test -f " + $check_key) 
		mtime = File.mtime($check_key)
		if now.to_i - mtime.to_i < 7 * 24 * 3600
			$stderr.puts "Signatures are newer than 7 days"
			return false
		end
	end
	return true
	#return true unless system("test -f " + $check_date)
	#mtime = File.mtime($check_date)
	#if now.to_i - mtime.to_i > 7 * 24 * 3600
	#	$stderr.puts "Signatures are older than 7 days"
	#	return true
	#else
	#	$stderr.puts "Signatures are newer than 7 days"
	#	return false
	#end
end

def check_network(tot)
	if system("timeout -t " + tot.to_s + " nslookup " + $host_to_check)
		return true
	end
	return false
end

# Return maximum archive size depending on available memory

def get_archive_maxsize
	tmpstats=` df -k /tmp | tail -n1 `
	free_tmp_megs = tmpstats.split[3].to_i / 1024
	return 4096 if free_tmp_megs - 100 > 4096
	return free_tmp_megs - 100
end

# Build the content of the first notebook tab 
#
# Start scanner and VTE for scanner output

def create_scantab 
	scan_vbox = Gtk::VBox.new
	scan_vte = Vte::Terminal.new
	scan_vte.set_colors(Gdk::Color.new(0,0,0), Gdk::Color.new(65535, 65535, 65535), [])
	scan_vte.cursor_blinks = false
	frame_vte = Gtk::Frame.new("Ausgabe des Virusscanners")
	frame_state = Gtk::Frame.new("Status")
	label_state = Gtk::Label.new
	label_state.set_markup("\n<b>Noch kein Suchlauf gestartet</b>\n")
	frame_state.add(label_state)
	frame_stats = Gtk::Frame.new("Auswertung")
	log_save = Gtk::Button.new("Protokoll ansehen/speichern") 
	log_save.sensitive = false
	log_hbox = Gtk::HBox.new(false, 0)
	prog_hbox = Gtk::HBox.new(false, 0)
	prog_bar = Gtk::ProgressBar.new
	
	scan_inner_vbox = Gtk::VBox.new(true, 0)
	# Drei/vier Buttons erste Seite
	buttons_first_tab = Gtk::HBox.new(true, 2)
	butt_start = Gtk::Button.new("Scanner starten") 
	butt_stop = Gtk::Button.new("Scanner beenden") 
	butt_stop.sensitive = false
	butt_shop = Gtk::Button.new("Onlineshop")
	butt_down = Gtk::Button.new("Herunterfahren")
	buttons_first_tab.pack_start(butt_start, false, true, 5)
	buttons_first_tab.pack_start(butt_stop, false, true, 5)
	# buttons_first_tab.pack_start(butt_shop, false, true, 5)
	# buttons_first_tab.pack_start(butt_down, false, true, 5)
	# frame_vte.add(scan_vte)
	scan_inner_vbox.pack_start(scan_vte, true, true, 2)
	log_hbox.pack_start(log_save, true, true, 2)
	prog_hbox.pack_start(prog_bar, true, true, 2)
	# scan_inner_vbox.pack_start(log_hbox, false, true, 2)
	frame_vte.add(scan_inner_vbox)
	# Tabelle Auswertung / noch nicht angezeigt
	stats_table = Gtk::Table.new(3,    4,    true)
	st_options = Gtk::EXPAND|Gtk::FILL
	# child, x1, x2, y1, y2, x-opt,   y-opt,   xpad, ypad
	stat_label = []
	stat_label[0] = Gtk::Label.new("Untersuchte Dateien:")
	stat_label[1] = Gtk::Label.new("Untersuchte Verzeichnisse:")
	stat_label[2] = Gtk::Label.new("Benötigte Zeit:")
	stat_label[3] = Gtk::Label.new("Funde:")
	stat_label[4] = Gtk::Label.new("Verdächtige Dateien:")
	stat_label[5] = Gtk::Label.new("Warnungen:")
	stat_align = []
	stat_val = []
	0.upto(5) { |i| stat_val[i] = Gtk::Label.new(0.to_s) }
	stat_val[2] = Gtk::Label.new("00:00:00")
	val_align = []
	0.upto(stat_label.count - 1) { |i|
		stat_align[i] = Gtk::Alignment.new(0, 0, 0, 0)
		stat_align[i].add(stat_label[i])
		val_align[i] = Gtk::Alignment.new(1, 0, 0, 0)
		val_align[i].add(stat_val[i])
	}
	stats_table.attach(stat_align[0],  0,  1,  0,  1, st_options, st_options, 10,    0)
	stats_table.attach(stat_align[1],  0,  1,  1,  2, st_options, st_options, 10,    0)
	stats_table.attach(stat_align[2],  0,  1,  2,  3, st_options, st_options, 10,    0)
	stats_table.attach(stat_align[3],  2,  3,  0,  1, st_options, st_options, 30,    0)
	stats_table.attach(stat_align[4],  2,  3,  1,  2, st_options, st_options, 30,    0)
	stats_table.attach(stat_align[5],  2,  3,  2,  3, st_options, st_options, 30,    0)
	stats_table.attach(val_align[0],  1,  2,  0,  1, st_options, st_options, 10,    0)
	stats_table.attach(val_align[1],  1,  2,  1,  2, st_options, st_options, 10,    0)
	stats_table.attach(val_align[2],  1,  2,  2,  3, st_options, st_options, 10,    0)
	stats_table.attach(val_align[3],  3,  4,  0,  1, st_options, st_options, 30,    0)
	stats_table.attach(val_align[4],  3,  4,  1,  2, st_options, st_options, 30,    0)
	stats_table.attach(val_align[5],  3,  4,  2,  3, st_options, st_options, 30,    0)
	frame_stats.add(stats_table)
	scan_vbox.pack_start(frame_state, false, true, 5)
	scan_vbox.pack_start(frame_vte, true, true, 5)
	scan_vbox.pack_start(prog_hbox, false, true, 5)
	scan_vbox.pack_start(log_hbox, false, true, 5)
	scan_vbox.pack_start(frame_stats, false, true, 5)
	scan_vbox.pack_start(buttons_first_tab, false, true, 5)
	return scan_vbox, [ log_save, butt_start, butt_stop, butt_shop, butt_down ], scan_vte, label_state, stat_val, prog_bar
end

def create_conftab 
	# Radiobutton Scanmethode
	radio_butts = []
	check_boxes = []
	radio_butts[0] = Gtk::RadioButton.new("Alle Dateien scannen")
	radio_butts[1] = Gtk::RadioButton.new(radio_butts[0], "Avira entscheidet selbst, welche Dateien gescannt werden")
	# radio_butts[1].sensitive = false
	radio_butts[2] = Gtk::RadioButton.new(radio_butts[0], "Nur Bootsektoren nach Schädlingen durchsuchen")
	box_sm = Gtk::VBox.new(false, 0)
	box_sm.pack_start_defaults(radio_butts[0])
	box_sm.pack_start_defaults(radio_butts[1])
	box_sm.pack_start_defaults(radio_butts[2])
	# Radiobutton Malware-Fund
	radio_butts[3] = Gtk::RadioButton.new("Schädlings-Fund nur protokollieren")
	radio_butts[4] = Gtk::RadioButton.new(radio_butts[3], "Infizierte Dateien löschen")
	radio_butts[5] = Gtk::RadioButton.new(radio_butts[3], "Infizierte Dateien reparieren")
	radio_butts[5].active = true
	box_fo = Gtk::VBox.new(false, 0)
	box_fo.pack_start_defaults(radio_butts[3])
	box_fo.pack_start_defaults(radio_butts[4])
	box_fo.pack_start_defaults(radio_butts[5])
	check_boxes[0] = Gtk::RadioButton.new("Datei umbenennen, wenn Reparatur nicht möglich")
	check_boxes[1] = Gtk::RadioButton.new(check_boxes[0], "Datei löschen, wenn Reparatur nicht möglich")
	aux_inf_box = Gtk::VBox.new(false, 0)
	aux_inf_box.pack_start_defaults(check_boxes[0])
	aux_inf_box.pack_start_defaults(check_boxes[1])
	inf_rendel_align = Gtk::Alignment.new(0.1, 0, 0, 0)
	inf_rendel_align.add(aux_inf_box)
	box_fo.pack_start(inf_rendel_align, false, false, 0)
	# Checkboxes erweitert
	check_boxes[2] = Gtk::CheckButton.new("Einwahlprogramme für kostenpflichtige Dienste")
	check_boxes[2].active = true
	check_boxes[3] = Gtk::CheckButton.new("Scherzprogramme")
	check_boxes[4] = Gtk::CheckButton.new("Computerspiele")
	check_boxes[5] = Gtk::CheckButton.new("Programme, die ihre Privatsphäre verletzen")
	check_boxes[5].active = true
	check_boxes[6] = Gtk::CheckButton.new("Werbe- und Spionageprogramme")
	check_boxes[6].active = true
	check_boxes[7] = Gtk::CheckButton.new("Hintertür-Programme")
	check_boxes[7].active = true
	check_boxes[8] = Gtk::CheckButton.new("Dateien mit verschleierten Dateiendungen")
	check_boxes[8].active = true
	check_boxes[9] = Gtk::CheckButton.new("Ungewöhnliches Packprogramm")
	check_boxes[9].active = true
	check_boxes[10] = Gtk::CheckButton.new("Phishing")
	# check_boxes[10].active = true
	
	
	# Callbacks to enable/disable
	radio_butts[3].signal_connect("clicked") {
		check_boxes[0].sensitive = false
		check_boxes[1].sensitive = false
	}
	radio_butts[4].signal_connect("clicked") {
		check_boxes[0].sensitive = false
		check_boxes[1].sensitive = false
	}
	radio_butts[5].signal_connect("clicked") {
		check_boxes[0].sensitive = true
		check_boxes[1].sensitive = true
	}
	box_er = Gtk::VBox.new(false, 0)
	box_er.pack_start(check_boxes[2], false, false, 0)
	box_er.pack_start(check_boxes[8], false, false, 0)
	box_er.pack_start(check_boxes[5], false, false, 0)
	box_er2 = Gtk::VBox.new(false, 0)
	box_er2.pack_start(check_boxes[9], false, false, 0)
	box_er2.pack_start(check_boxes[6], false, false, 0)
	box_er2.pack_start(check_boxes[7], false, false, 0)
	box_er3 = Gtk::VBox.new(false, 0)
	box_er3.pack_start(check_boxes[10], false, false, 0)
	box_er3.pack_start(check_boxes[3], false, false, 0)
	box_er3.pack_start(check_boxes[4], false, false, 0)
	box_er_hbox = Gtk::HBox.new(false, 0)
	box_er_hbox.pack_start(box_er, false, true, 2)
	box_er_hbox.pack_start(box_er2, false, true, 2)
	box_er_hbox.pack_start(box_er3, false, true, 2)
	# Verzeichnis
	searchchooser  = Gtk::FileChooserButton.new("Suchpfad", Gtk::FileChooser::ACTION_OPEN)
	searchchooser.current_folder = "/media"
	chooser_label = Gtk::Label.new("Suchpfad:")
	searchchooser.action = Gtk::FileChooser::ACTION_SELECT_FOLDER
	chooser_hbox = Gtk::HBox.new(false, 0)
	chooser_hbox.pack_start(chooser_label, false, true, 2)
	chooser_hbox.pack_start(searchchooser, true, true, 2)
	# Box für die Konfiguration
	confbox =  Gtk::VBox.new(false, 0)
	frame_sm = Gtk::Frame.new("Scanmethode")
	frame_fo = Gtk::Frame.new("Aktion beim Fund von Schädlingen")
	frame_er = Gtk::Frame.new("Erweiterte Gefahrenkategorien")
	frame_vz = Gtk::Frame.new("Wo soll nach Schädlingen gesucht werden?")
	frame_sm.add(box_sm)
	frame_fo.add(box_fo)
	# frame_er.add(box_er_hbox)
	frame_vz.add(chooser_hbox)
	
	
	# Expander
	expander = Gtk::Expander.new("Erweiterte Gefahrenkategorien")
	exp_align = Gtk::Alignment.new(0.6, 0, 0, 0)
	exp_align.add(box_er_hbox)
	expander.add(exp_align)
	box_sm.pack_start_defaults(expander)
	
	confbox.pack_start(frame_sm, true, true, 5)
	confbox.pack_start(frame_fo, true, true, 5)
	# confbox.pack_start(frame_er, true, true, 5)
	confbox.pack_start(frame_vz, true, false, 5)
	return confbox, radio_butts, check_boxes, searchchooser
end

def create_updtab
	update_box = Gtk::VBox.new
	upd_status = Gtk::Label.new
	upd_status.set_markup("\n<b>Noch keine Aktualisierung durchgeführt</b>\n")
	upd_frame = Gtk::Frame.new("Status")
	upd_frame.add(upd_status)
	update_box.pack_start(upd_frame, false, true, 2)
	upd_vte = Vte::Terminal.new
	upd_vte.set_colors(Gdk::Color.new(0,0,0), Gdk::Color.new(65535, 65535, 65535), [])
	upd_vte.cursor_blinks = false
	upd_frame = Gtk::Frame.new("Informationen zur Aktualisierung")
	upd_frame.add(upd_vte)
	update_box.pack_start(upd_frame, true, true, 2)
	proxy_frame = Gtk::Frame.new("Proxy")
	proxy_tab = Gtk::Table.new(2,    6,    true)
	st_options = Gtk::FILL|Gtk::EXPAND
	
	proxy_entries = []
	0.upto(3) { |i|
		proxy_entries[i] = Gtk::Entry.new
		proxy_entries[i].width_chars = 25
	}
	proxy_entries[3].visibility = false
	proxy_tab.attach(Gtk::Label.new("Host"),  0,  1,  0,  1, st_options, st_options, 1,    1)
	proxy_tab.attach(Gtk::Label.new("Port"),  0,  1,  1,  2, st_options, st_options, 1,    1)
	proxy_tab.attach(Gtk::Label.new("Nutzer"),  3,  4,  0,  1, st_options, st_options, 1,    1)
	proxy_tab.attach(Gtk::Label.new("Passwort"),  3,  4,  1,  2, st_options, st_options, 1,    1)
	proxy_tab.attach(proxy_entries[0],  1,  3,  0,  1, st_options, st_options, 1,    1)
	proxy_tab.attach(proxy_entries[1],  1,  3,  1,  2, st_options, st_options, 1,    1)
	proxy_tab.attach(proxy_entries[2],  4,  6,  0,  1, st_options, st_options, 1,    1)
	proxy_tab.attach(proxy_entries[3],  4,  6,  1,  2, st_options, st_options, 1,    1)
	proxy_frame.add(proxy_tab)
	upd_butt_box = Gtk::HBox.new(true, 2)
	upd_start = Gtk::Button.new("Aktualisierung starten")
	upd_log = Gtk::Button.new("Protokoll ansehen/speichern")
	upd_log.sensitive = false
	upd_butt_box.pack_start(upd_start, false, true, 2)
	upd_butt_box.pack_start(upd_log, false, true, 2)
	update_box.pack_start(proxy_frame, false, true, 2)
	update_box.pack_start(upd_butt_box, false, true, 2)
	return update_box, upd_start, upd_log, upd_vte, upd_status, proxy_entries 
end

def create_iconbox_tab
	icon_theme = Gtk::IconTheme.default
	iconvbox = Gtk::VBox.new
	frame_tools = Gtk::Frame.new("Werkzeuge")
	frame_about = Gtk::Frame.new("Eine Initiative von")
	icon_table = Gtk::Table.new(3,    3,    true)
	st_options = Gtk::EXPAND|Gtk::FILL
	button_list = []
	button_list[0] = Gtk::Button.new("Terminal")
	button_list[0].image = Gtk::Image.new(icon_theme.load_icon("terminal", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[1] = Gtk::Button.new("Dateimanager")
	button_list[1].image = Gtk::Image.new(icon_theme.load_icon("file-manager", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[2] = Gtk::Button.new("Laufwerke")
	button_list[2].image = Gtk::Image.new(icon_theme.load_icon("drive-harddisk", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[3] = Gtk::Button.new("Netzwerk und WLAN")
	button_list[3].image = Gtk::Image.new(icon_theme.load_icon("gnome-dev-wavelan", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[4] = Gtk::Button.new("Proxy")
	button_list[4].image = Gtk::Image.new(icon_theme.load_icon("proxy", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[5] = Gtk::Button.new("Webbrowser")
	button_list[5].image = Gtk::Image.new(icon_theme.load_icon("browser", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[6] = Gtk::Button.new("Anleitung")
	button_list[6].image = Gtk::Image.new(icon_theme.load_icon("info", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[7] = Gtk::Button.new("Onlineshop")
	button_list[7].image = Gtk::Image.new($shoplarge)
	# button_list[7].image = Gtk::Image.new(icon_theme.load_icon("applications-science", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[8] = Gtk::Button.new("Herunterfahren")
	# button_list[8].image = Gtk::Image.new(icon_theme.load_icon("system-shutdown", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[8].image = Gtk::Image.new($shutdownlarge)
	button_list[9] = Gtk::Button.new("Systemaktualisierung")
	button_list[9].image = Gtk::Image.new(icon_theme.load_icon("software-update-available", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[10] = Gtk::Button.new("Fernzugriff einrichten")
	button_list[10].image = Gtk::Image.new(icon_theme.load_icon("network-workgroup", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[11] = Gtk::Button.new("USB-Installation")
	button_list[11].image = Gtk::Image.new(icon_theme.load_icon("drive-removable-media", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list[12] = Gtk::Button.new("Nutzungsbedingungen")
	button_list[12].image = Gtk::Image.new(icon_theme.load_icon("important", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button_list.each { |i| 
		i.image_position = Gtk::POS_TOP
		i.relief = Gtk::RELIEF_NONE
		i.focus_on_click = false
	}
	# icon_table.attach(button_list[0],  0,  1,  0,  1, st_options, st_options, 1,    1)
	icon_table.attach(button_list[1],  0,  1,  0,  1, st_options, st_options, 1,    1)
	icon_table.attach(button_list[2],  1,  2,  0,  1, st_options, st_options, 1,    1)
	icon_table.attach(button_list[3],  0,  1,  1,  2, st_options, st_options, 1,    1)
	# icon_table.attach(button_list[4],  1,  2,  1,  2, st_options, st_options, 1,    1)
	icon_table.attach(button_list[5],  1,  2,  1,  2, st_options, st_options, 1,    1)
	icon_table.attach(button_list[6],  2,  3,  0,  1, st_options, st_options, 1,    1)
	# 7 Onlineshop
	# 12 Haftungsausschluss
	# icon_table.attach(button_list[7],  2,  3,  1,  2, st_options, st_options, 1,    1)
	icon_table.attach(button_list[12],  2,  3,  1,  2, st_options, st_options, 1,    1)
	# button_list[8] is shutdown button_list[0] is terminal
	# icon_table.attach(button_list[0],  2,  3,  2,  3, st_options, st_options, 1,    1)
	icon_table.attach(button_list[8],  2,  3,  2,  3, st_options, st_options, 1,    1)
	icon_table.attach(button_list[9],  1,  2,  2,  3, st_options, st_options, 1,    1)
	# icon_table.attach(button_list[10],  3,  4,  0,  1, st_options, st_options, 1,    1)
	icon_table.attach(button_list[11],  0,  1,  2,  3, st_options, st_options, 1,    1)
	frame_tools.add(icon_table)
	
	
	involved_img = Gtk::Image.new($involved)
	
	avira_vbox = Gtk::VBox.new
	lab_about_fat = Gtk::Label.new("Avira GmbH")
	fat_font = Pango::FontDescription.new("Sans Bold 18")
	lab_about_fat.modify_font(fat_font)
	avira_vbox.pack_start(lab_about_fat, false, false, 1)
	avira_vbox.pack_start(Gtk::Label.new("Lindauer Str. 21"), false, false, 1)
	avira_vbox.pack_start(Gtk::Label.new("88069 Tettnang"), false, false, 1)
	avira_vbox.pack_start(Gtk::Label.new("Deutschland\n"), false, false, 1)
	avira_link_label = Gtk::Label.new
	avira_link_label.set_markup("<span foreground=\"blue\" underline=\"single\">http://www.avira.de/</span>")
	avira_link_button = Gtk::Button.new
	avira_link_button.relief = Gtk::RELIEF_NONE
	avira_link_button.focus_on_click = false
	avira_link_button.image = avira_link_label
	avira_vbox.pack_start(avira_link_button, false, false, 1)
	avira_vbox.pack_start(Gtk::Label.new("Copyright 2010\n"), false, false, 1)
	# frame_about.add(avira_vbox)
	frame_about.add(involved_img)
	
	iconvbox.pack_start(frame_tools, true, true, 2)
	iconvbox.pack_start(frame_about, true, true, 2)
	return iconvbox, button_list, avira_link_button
end

def show_summary(label_state, summary_labels)
	retval = ""
	File.open("/tmp/retval").each { |line|
		retval = line.strip if line.strip != ''
	}
	if $return_codes.has_key?(retval)
		$stderr.puts $return_codes[retval]
		label_state.set_markup("\n<b>" + $return_codes[retval] + "</b>\n")
		dirs = 0
		fils = 0
		time = "00:00:00"
		infc = 0
		susp = 0
		warn = 0
		IO.popen("tail -n 13 \"" + $logfile + "\"") { |io|
			while io.gets
				$stderr.puts "Analyzing... " + $_.strip
				fils = $_.strip.split[2].to_i if $_.strip =~ /^Files.../
				dirs = $_.strip.split[2].to_i if $_.strip =~ /^Directories.../
				time = $_.strip.split[2].to_s if $_.strip =~ /^Time.../
				infc = $_.strip.split[2].to_i if $_.strip =~ /^Infected.../
				susp = $_.strip.split[2].to_i if $_.strip =~ /^Suspicious.../
				warn = $_.strip.split[2].to_i if $_.strip =~ /^Warnings.../
			end
		}
		summary_labels[0].text = fils.to_s
		summary_labels[1].text = dirs.to_s
		summary_labels[2].text = time
		summary_labels[3].text = infc.to_s
		summary_labels[4].text = susp.to_s
		summary_labels[5].text = warn.to_s
	end
end

def create_buttonbar
	bar_buttons = []
	tool_tips = []
	icon_theme = Gtk::IconTheme.default
	0.upto(2) { |i| 
		bar_buttons[i] = Gtk::Button.new
	}
	bar_buttons[0].image = Gtk::Image.new($shopsmall)
	bar_buttons[0].set_tooltip_text "Onlineshop"
	bar_buttons[1].image = Gtk::Image.new(icon_theme.load_icon("info", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	bar_buttons[2].set_tooltip_text "Hilfe"
	# bar_buttons[2].image = Gtk::Image.new(icon_theme.load_icon("system-shutdown", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	bar_buttons[2].image = Gtk::Image.new($shutdownsmall)
	bar_buttons[2].set_tooltip_text "Computer ausschalten"
	button_bar = Gtk::HBox.new
	1.upto(2) { |i| 
		button_bar.pack_start(bar_buttons[i], false, false, 1)
	}
	return button_bar, bar_buttons
end

def reset_summary(summary_labels)
	summary_labels.each { |l| l.text = "0" }
	summary_labels[2].text = "00:00:00"
end

# Assemble the command line for the scanner

def assemble_scan_cli(scan_cl, conf_radio, conf_check, directory_chooser)
	cli_array = [ $scan_wrapper, scan_cl ]
	# first frame "scan method"
	if conf_radio[0].active?
		$stderr.puts("scanmethod: allfiles")
		cli_array.push("--allfiles")
	elsif conf_radio[1].active?
		$stderr.puts("scanmethod: intelligent")
		cli_array.push("--smartextensions")
	elsif conf_radio[2].active? && conf_radio[5].active?
		$stderr.puts("scanmethod: bootonly")
		cli_array.push("--fixallboot")
	elsif conf_radio[2].active?
		$stderr.puts("scanmethod: bootonly")
		cli_array.push("--allboot")
	end
	
	# second frame "what to do"
	if conf_radio[3].active?
		$stderr.puts("action: protocol only")
		cli_array.push("--defaultaction=ignore")
	elsif conf_radio[4].active?
		$stderr.puts("action: delete infected")
		cli_array.push("--defaultaction=delete,delete-archive")
	elsif conf_radio[5].active?
		$stderr.puts("action: repair infected")
		if conf_check[0].active? 
			$stderr.puts("FIXME: rename if no repair")
			cli_array.push("--defaultaction=clean,rename")
		elsif conf_check[1].active? 
			$stderr.puts("FIXME: delete if no repair")
			cli_array.push("--defaultaction=clean,delete,delete-archive")
		end
	end
	# extended dangers  dial,joke,game,bdc,heur-dblext,pck,spr,adspy,all
	extended_opts = []
	extended_opts.push("dial") 		if conf_check[2].active?
	extended_opts.push("joke") 		if conf_check[3].active?
	extended_opts.push("game") 		if conf_check[4].active?
	extended_opts.push("spr")  		if conf_check[5].active?
	extended_opts.push("adspy")  	        if conf_check[6].active?
	extended_opts.push("bdc")  		if conf_check[7].active?
	extended_opts.push("heur-dblext")  	if conf_check[8].active?
	extended_opts.push("pck") 		if conf_check[9].active?
	extended_opts.push("PHISH")  		if conf_check[10].active?
	need_extended_opts = false
	2.upto(10) { |i| need_extended_opts = true if conf_check[i].active? }
	cli_array.push("--withtype=" + extended_opts.join(",")) if need_extended_opts == true
	# timestamp for logfile
	tstamp = Time.new.strftime("%Y%m%d-%H%M")
	$logfile = $logdir + "/rescue-system_scan_" + tstamp + ".log"
	cli_array.push("--log=" + $logfile)
	cli_array.push("--logformat=singleline")
	cli_array.push("--quarantine=" + $quarantine)
	cli_array.push("--heurlevel=2")
	cli_array.push("--nolinks")
	archmax = get_archive_maxsize
	if archmax > 0 
		cli_array.push("-z")
		cli_array.push("--archivemaxsize=" + archmax.to_s + "MB")
	end
	# scan an empty directory if the user chooses to scan only bootsectors
	# this is a weird hack to emulate the behaviour of the old --bootonly
	if conf_radio[2].active?
		cli_array.push("/tmp/.empty")
	else
		cli_array.push(directory_chooser.filename)
	end
	return cli_array
end

def run_signature_update(update_label, update_button, scan_button, update_vte, proxy_entries)
	update_vte.reset(true, true)
	update_label.set_markup("\n<b>Aktualisierung läuft - bitte Geduld</b>\n")
	system("echo -n > " + $update_logfile) 
	update_button.sensitive = false
	scan_button.sensitive = false
	wrapper_params = [ $update_wrapper ]
	if proxy_entries[0].text.strip.size > 0
		wrapper_params.push("--proxy-host=" + proxy_entries[0].text.strip)
		if proxy_entries[1].text.strip.size > 0
			wrapper_params.push("--proxy-port=" + proxy_entries[1].text.strip)
		else
			wrapper_params.push("--proxy-port=3128")
		end
		wrapper_params.push("--proxy-username=" + proxy_entries[2].text.strip) if proxy_entries[2].text.strip.size > 0
		wrapper_params.push("--proxy-password=" + proxy_entries[3].text.strip) if proxy_entries[3].text.strip.size > 0
	end
	$stderr.puts "Using params for updater " + wrapper_params.join(", ")
	update_vte.fork_command($update_wrapper, wrapper_params, nil, $update_directory )
end

def get_update_count
	updct = 0
	File.open($update_logfile).each { |line|
		updct += 1 if line =~ /Downloading http/
	}
	return updct - 4
end

def get_signature_version
	vdfversion = nil
	IO.popen($scancl + " --version") { |io|
		while io.gets
			if $_ =~ /^VDF Version/ 
				vdfversion = $_.split[2].strip
			end
		end
	}
	return vdfversion
end

#=============================================================================
#
# Functions used to open dialogs
#
#=============================================================================

def update_nag_dialog(parent, update_label, update_button, scan_button, update_vte, notebook, proxy_entries)
	IO.popen("ps waux") { |io|
		while io.gets
			return 0 if $_ =~ /avupdate.bin/
		end
	}
	return 0 if $update_running == true
	dialog = Gtk::Dialog.new(
		"Signaturupdate erforderlich",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ],
		[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT]
	)
	dialog.has_separator = false
	label = Gtk::Label.new("Ihre Virensignaturen sind älter als 7 Tage, wollen Sie sie jetzt aktualisieren?")
	image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |response|
		case response
			when Gtk::Dialog::RESPONSE_OK
				$stderr.puts "Signature update requested"
				$update_running = true
				run_signature_update(update_label, update_button, scan_button, update_vte, proxy_entries)
				notebook.page = 2
		end
	}
	dialog.destroy
end

def dialog_shutdown(parent)
	dialog = Gtk::Dialog.new(
		"System herunterfahren",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ],
		[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT]
	)
	dialog.deletable = false
	dialog.has_separator = false
	label = Gtk::Label.new("Wollen Sie den Computer jetzt abschalten?")
	image = Gtk::Image.new(Gtk::Stock::DIALOG_QUESTION, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |response|
		case response
			when Gtk::Dialog::RESPONSE_OK
				system("chvt 1")
				system("poweroff")
		end
	}
	dialog.destroy
end

def dialog_not_wired(parent)
	dialog = Gtk::Dialog.new(
		"Sorry",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new("Sorry, dieser Button ist noch nicht verdrahtet.")
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run
	dialog.destroy
end

def dialog_installer(parent)
	dialog = Gtk::Dialog.new(
		"USB-Installation",
		parent,
		Gtk::Dialog::MODAL # ,
		# [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ],
		# [Gtk::Stock::QUIT, Gtk::Dialog::RESPONSE_REJECT]
	)
	all_drives = get_usbdrives_lshw
	usable_drives = []
	ok_button = dialog.add_button(Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK)
	ok_button.sensitive = false
	quit_button = dialog.add_button(Gtk::Stock::QUIT, Gtk::Dialog::RESPONSE_REJECT)
	dialog.has_separator = false
	lab_about_fat = Gtk::Label.new("Installation auf USB-Speicherstift")
	fat_font = Pango::FontDescription.new("Sans Bold 18")
	lab_about_fat.modify_font(fat_font)
	description = "Sie können den Inhalt dieser CD auf einen USB-Speicherstift installieren. Dieser ist anschließend startfähig und hat den Vorteil, dass Signaturupdates erhalten bleiben. Beachten Sie: Bei der Installation wird der gesamte Inhalt des Speicherstiftes gelöscht."
	desc_label = Gtk::Label.new(description)
	desc_label.wrap = true 
	desc_label.width_request = 585
	layout_vbox = Gtk::VBox.new(false, 5)
	target_hbox = Gtk::HBox.new(false, 0)
	target_button = Gtk::Button.new("Neu einlesen")
	# target_button.sensitive = false
	target_button.sensitive = true
	frame_inst = Gtk::Frame.new("Installationsziel")
	target_combo = Gtk::ComboBox.new
	target_combo.append_text("Kein geeignetes Laufwerk gefunden")
	target_combo.active = 0
	target_combo.sensitive = false
	
	usable_drives = create_drivelist(target_combo, 1, all_drives)
	
	if usable_drives.size > 0
		target_combo.sensitive = true
	else
		target_combo.append_text("Kein geeignetes Laufwerk gefunden")
		target_combo.active = 0
		target_combo.sensitive = false
	end
	
	target_hbox.pack_start(target_combo, true, true, 2)
	target_hbox.pack_start(target_button, false, true, 2)
	frame_inst.add(target_hbox)
	layout_vbox.pack_start(lab_about_fat, true, false, 2)
	layout_vbox.pack_start(desc_label, true, false, 2)
	layout_vbox.pack_start(frame_inst, true, false, 2)
	vte_aux_box = Gtk::VBox.new(true, 0)
	inst_vte = Vte::Terminal.new
	inst_vte.set_colors(Gdk::Color.new(0,0,0), Gdk::Color.new(65535, 65535, 65535), [])
	inst_vte.cursor_blinks = false
	inst_vte.set_size(40, 8)
	frame_vte = Gtk::Frame.new("Ausgabe der Installationsroutine")
	vte_aux_box.pack_start(inst_vte, true, true, 0)
	vte_aux_box.height_request = 150
	frame_vte.add(vte_aux_box)
	layout_vbox.pack_start(frame_vte, true, false, 2)
	# layout_vbox.pack_start(vte_aux_box, false, false, 2)
	frame_disclaimer = Gtk::Frame.new("Haftungsausschluß")
	disclaimer_hbox = Gtk::HBox.new(false, 0)
	disclaimer_label = Gtk::Label.new("Ja, ich bin mir bewußt, dass bei der Installation alle Daten auf dem ausgewählten Laufwerk unwiederbringlich gelöscht werden und ich möchte die Installation durchführen.")
	disclaimer_label.wrap= true
	disclaimer_label.width_request = 560
	disclaimer_check = Gtk::CheckButton.new("")
	disclaimer_hbox.pack_start(disclaimer_check, false, true)
	disclaimer_hbox.pack_start(disclaimer_label, true, true)
	
	frame_disclaimer.add(disclaimer_hbox)
	layout_vbox.pack_start(frame_disclaimer, true, false, 2)
	
	dialog.vbox.add(layout_vbox)
	dialog.set_size_request(600, -1)
	
	target_button.signal_connect("clicked") {
		target_button.sensitive = false
		disclaimer_check.active = false
		all_drives = get_usbdrives_lshw
		usable_drives = create_drivelist(target_combo, 1, all_drives)
		if usable_drives.size > 0
			target_combo.sensitive = true
		else
			target_combo.append_text("Kein geeignetes Laufwerk gefunden")
			target_combo.active = 0
			target_combo.sensitive = false
		end
		target_button.sensitive = true
	}
	
	ok_button.signal_connect("clicked") {
		quit_button.sensitive = false
		ok_button.sensitive = false
		target_combo.sensitive = false
		disclaimer_check.sensitive = false
		$stderr.puts target_combo.active.to_s
		$stderr.puts usable_drives[target_combo.active].device
		# inst_vte.fork_command("/bin/bash", [ "/bin/bash", "/tmp/cbavcdinstaller.sh",  usable_drives[target_combo.active].device], nil, "/tmp" )
		inst_vte.fork_command("/bin/bash", [ "/bin/bash", "/usr/bin/cbavcdinstaller.sh",  usable_drives[target_combo.active].device], nil, "/tmp" )
		# quit_button.sensitive = true
	}
	
	inst_vte.signal_connect("child_exited") {
		quit_button.sensitive = true
	}
	
	disclaimer_check.signal_connect("clicked") { |i|
		ok_button.sensitive = true if i.active? && all_drives.size > 0
		ok_button.sensitive = false unless i.active? 
	}
	
	quit_button.signal_connect("clicked") {
		dialog.destroy
	}
	dialog.show_all
	dialog.run { |response|
		case response
			when Gtk::Dialog::RESPONSE_REJECT
				# dialog.destroy
				$stderr.puts "Exit requested"
		end
	}
	# dialog.destroy
end

def dialog_scan_runs(parent, vte)
	dialog = Gtk::Window.new(
		"Scan läuft")
	# dialog.deletable = false
	# dialog.has_separator = false
	
	label = Gtk::Label.new("Der Virenscan läuft...")
	image = Gtk::Image.new(Gtk::Stock::DIALOG_QUESTION, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	pbar = Gtk::ProgressBar.new
	pbar.pulse
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);
	hbox.pack_start_defaults(pbar)
	dialog.add(hbox)
	
	pbar = Gtk::ProgressBar.new
	pbar.pulse
	
	
	# dialog.show_all
	
	t = Thread.new {
		IO.popen("tail -f " + $logfile) { |io|
			#while (Gtk.events_pending?)
			#	Gtk.main_iteration
			#end
			while io.gets
				$stderr.puts "got..." + $_
				## $files_scanned += 1 if $_ =~ /^\//
				$files_infected += 1 if $_ =~ /^ ALERT/
				# pbar.pulse
			end
		}
	}
	
	#dialog.run { |response|
	#	case response
	#		when Gtk::Dialog::RESPONSE_OK
	#			# system("chvt 1")
	#			# system("poweroff")
	#			$stderr.puts "OK clicked"
	#	end
	#}
	# dialog.destroy
	return t
end

def dialog_update_info(parent, message)
	dialog = Gtk::Dialog.new(
		"Aktualisierung der Signaturen abgeschlossen",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	updated_files = get_update_count
	msg = message
	if updated_files < 1
		msg =  message + " - Es wurden keine Dateien heruntergeladen."
	elsif updated_files == 1
		msg = message + " - Es wurde eine Datei heruntergeladen."
	else	
		msg = message + " - Es wurden " + get_update_count.to_s + " Dateien heruntergeladen."
	end
	label = Gtk::Label.new(msg)
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run
	dialog.destroy
end

def dialog_general_info(parent, head, message)
	dialog = Gtk::Dialog.new(
		head,
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(message)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run
	dialog.destroy
end

def dialog_network_down(parent)
	dialog = Gtk::Dialog.new(
		"Netzwerk nicht erreichbar",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new("Ihre Virensignaturen sind älter als 7 Tage. Möglicherweise verhindern Netzwerkprobleme jedoch eine Aktualisierung. Bitte überprüfen Sie Ihre Netzwerkeinstellungen im Reiter \"Sonstiges\" oder tragen Sie im Reiter \"Aktualisierung\" Proxy-Zugangsdaten ein, damit die Aktualisierung der Signaturdateien erfolgen kann.")
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run
	dialog.destroy
end

#=============================================================================
#
# Functions used for Window management:
#
#=============================================================================

# Get a list of all windows creted by a given command
#
# return value is a list of hexadecimal IDs - the list itself is not very
# useful, since xlsclients uses different IDs

def retrieve_windows(command)
	current_id = nil
	id_list = []
	IO.popen("xlsclients -l") { |io|
			while io.gets
				if $_ =~ /^Window/
					current_id = $_.strip.split[1].gsub(":", "")
				end
				if $_.strip =~ /^Command:/
					if $_.strip.split[1] == command
						id_list.push(current_id)
					end
				end
			end
	}
	return id_list
end

# Find and raise a window by its invoking command
#
# Remember to check if the process was started by some wrapper script! Does
# not work with all programs, may cause trouble with some window managers

def raise_by_name(window_name)
	termid=` xdotool search --onlyvisible #{window_name} | head -n1 `
	# system("xdotool windowunmap " + termid)
	# system("xdotool windowmap " + termid)
	system("xdotool windowactivate " + termid)
end

# Find and raise a firefox process
#
# Process is running: Connect to it and open the given URL in a new tab
# Process is not running: Start a new firefox process

def firefox_open(url)
	term_windows = retrieve_windows("firefox-bin")
	url_to_open = url
	if term_windows.size > 0
		# raise_by_name("firefox")
		system("su surfer -c \"cbavffwrapper.sh --remote \'openurl(#{url_to_open})\'\" &")
	else
		system("su surfer -c \"cbavffwrapper.sh #{url_to_open}\" &")
	end
end

def open_in_editor(fname)
	if system("which gedit")
		system("gedit " + fname + " & ")
	else
		system("su surfer -c \"cbavlogviewer.sh " + fname + "\" & ")
	end
end

#=============================================================================
#
# Initialize GUI here
#
#=============================================================================

window = Gtk::Window.new
window.border_width = 10

unless ARGV[0] == "debug"
	window.deletable = false
	window.decorated = false
	window.title = "Virenscan"
else
	window.title = "Virenscan - Debug"
end

window.window_position = Gtk::Window::POS_CENTER_ALWAYS

# FIXME: try to use global variables more sparingly.

$scan_pid = nil
$upd_pid = nil
$scan_ret = nil
$upd_ret = nil
$scan_cl = "/AntiVir/scancl"
$check_date = "/AntiVir/vbase031.vdf"
$check_key = "/AntiVir/rescue_cd.key"
$update_wrapper = "/AntiVirUpdate/avupdate"
$update_directory = "/AntiVirUpdate"
$scan_wrapper = "/AntiVir/run_and_save_exit"
$logdir = "/tmp"
$logdir = "/lesslinux/signatures/Protokolle" if system("test -d  /lesslinux/signatures/Protokolle")
$logdir = "/lesslinux/cdrom/Protokolle" if system("test -d  /lesslinux/cdrom/Protokolle") 
$logfile = nil
$update_logfile = "/tmp/avupdate.log"
$quarantine = "/tmp/quarantine"
# $background = "/usr/share/lesslinux/cbavgui/header.png"
$background = "/usr/share/lesslinux/cbavgui/bck_rescuecd_final.png"
$background = "/tmp/bck_rescuecd_final.png" unless system("test -f " + $background)
$involved = "/usr/share/lesslinux/cbavgui/eine_initiative_von.png"
$shoplarge = "/usr/share/lesslinux/cbavgui/avirashop.png"
$shopsmall = "/usr/share/lesslinux/cbavgui/avirashop24.png"
$shutdownlarge = "/usr/share/lesslinux/cbavgui/shutdown48.png"
$shutdownsmall = "/usr/share/lesslinux/cbavgui/shutdown24.png"
$shoplink = "http://www.avira.de/de/losungen/privatanwender_home-office.html"
$host_to_check = "dl.antivir.de"
$files_scanned = 0
$files_infected = 0
$files_warned = 0
$scanstart = 0
$last_progbar_update = 0
$network_failed = 0
$update_running = false
$scan_running = false

$return_codes = { 
	"0" => "Suchlauf beendet - Normales Programmende, kein Fund, kein Fehler",
	"1" => "Suchlauf beendet - Verdächtige Dateien oder Bootsektoren gefunden",
	"2" => "Suchlauf beendet - Signaturen im Arbeitsspeicher gefunden",
	"3" => "Suchlauf beendet - Verdächtige Dateien gefunden",
	"100" => "Info: Es wurde nur der Hilfetext angezeigt",
	"101" => "Suchlauf beendet - Ein Macro wurde gefunden",
	"203" => "Fehler: Ungültiger Kommandozeilenparameter",
	"204" => "Fehler: Ungültiges oder fehlendes Verzeichnis",
	"205" => "Fehler: Die Protokolldatei konnte nicht erstellt werden",
	"210" => "Fehler: Avira konnte Bibliotheken nicht finden",
	"211" => "Fehler: Selbsttest des Programmes fehlgeschlagen",
	"212" => "Fehler: Virusdefinitionen konnten nicht gelesen werden",
	"213" => "Fehler: Scannerengine und VDF-Versionen inkompatibel",
	"214" => "Fehler: Keine gültige Lizenz gefunden",
	"215" => "Fehler: Scancl Selbsttest fehlgeschlagen",
	"216" => "Fehler: Dateizugriff fehlgeschlagen, fehlende Berechtigungen",
	"217" => "Fehler: Dateizugriff fehlgeschlagen, fehlende Berechtigungen"
}

scan_vbox, scantab_buttons, scan_vte, label_state, summary_labels, prog_bar = create_scantab
conf_vbox, conf_radio, conf_check, directory_chooser = create_conftab
updt_vbox, update_button, update_log_button, update_vte, update_label, proxy_entries = create_updtab
icon_vbox, button_list, avira_link_button = create_iconbox_tab
button_bar, top_buttons = create_buttonbar

# Assemble the Notebook

nb = Gtk::Notebook.new
label1 = Gtk::Label.new("Virusscanner")
label2 = Gtk::Label.new("Einstellungen")
label3 = Gtk::Label.new("Aktualisierung")
label4 = Gtk::Label.new("Sonstiges")
#note2  = Gtk::Label.new("-2- page.\nSwitch to ...")
#button = Gtk::Button.new("Gumbek")
nb.append_page(scan_vbox, label1)
nb.append_page(conf_vbox, label2)
nb.append_page(updt_vbox,  label3)
nb.append_page(icon_vbox,  label4)
nb.set_size_request(790, 490)

fixed = Gtk::Fixed.new
fixed.put(Gtk::Image.new($background), 0, 0)
fixed.put(nb, 5, 100)
fixed.put(button_bar, 721, 85)

# Connect some callbacks

window.signal_connect('delete_event') { false }
window.signal_connect('destroy') { Gtk.main_quit }

scantab_buttons[1].signal_connect("clicked") {
	unless system("cat /proc/mounts | grep -q /media/")
		dialog_general_info(window, "Keine Laufwerke eingebunden", "Es sind momentan keine Laufwerke eingebunden. Möglicherweise wurden Laufwerke nicht identifiziert, weil keine Treiber vorhanden sind oder die Anmeldung einzelner Laufwerke am System dauerte zu lange. Bitte verwenden Sie das Werkzeug \"Laufwerke\" im Reiter \"Sonstiges\" um zu durchsuchende Laufwerke manuell einzubinden.")
	else
		scan_vte.reset(true, true)
		prog_bar.fraction = 0.0
		sleepcount = 0
		$files_scanned = 0
		$files_infected = 0
		reset_summary(summary_labels)
		$scanstart = Time.now
		scantab_buttons[1].sensitive = false
		scantab_buttons[2].sensitive = true	
		update_button.sensitive = false
		scan_params = assemble_scan_cli($scan_cl, conf_radio, conf_check, directory_chooser)
		reset_summary(summary_labels)
		label_state.set_markup("\n<b>Suchlauf gestartet</b>\n")
		$stderr.puts scan_params.join(", ")
		system("touch " + $logfile)
		$scan_pid = scan_vte.fork_command($scan_wrapper, scan_params, nil)
		$scan_running = true
		dialog_scan_runs(window, scan_vte)
		while $scan_running == true
			prog_bar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			if sleepcount % 10 == 0
				summary_labels[0].text = " - " # $files_scanned.to_s
				summary_labels[1].text = " - "
				summary_labels[3].text = $files_infected.to_s
				tdelta = Time.now - $scanstart
				hrs = tdelta.to_i / 3600
				min = (tdelta.to_i % 3600) / 60
				sec = tdelta.to_i % 60
				fmtstring = sprintf("%02d:%02d:%02d", hrs, min, sec)
				summary_labels[2].text = fmtstring unless $logfile.nil?
			end
			sleepcount += 1
			sleep 0.1
		end
	end
}

scantab_buttons[2].signal_connect("clicked") {
	scantab_buttons[2].sensitive = false
	system("kill " + $scan_pid.to_s)
	sleep 1
	system("kill -9 " + $scan_pid.to_s)
	sleep 1
	system("killall -9 scancl")
	system("killall -9 tail")
	system("echo -n '' > /tmp/retval")
	label_state.set_markup("\n<b>Suchlauf abgebrochen</b>\n")
	prog_bar.fraction = 1.0
	$scan_running = false
	scantab_buttons[0].sensitive = true
	scantab_buttons[1].sensitive = true
}

scantab_buttons[0].signal_connect("clicked") {
	# system("mousepad \"" + $logfile + "\" & ")
	# system("su surfer -c \"cbavlogviewer.sh " + $logfile + "\" & ")
	open_in_editor($logfile)
}

scan_vte.signal_connect("child_exited") { 
	prog_bar.fraction = 1.0
	system("killall -9 tail")
	scantab_buttons[0].sensitive = true
	scantab_buttons[1].sensitive = true
	scantab_buttons[2].sensitive = false
	update_button.sensitive = true
	$scan_running = false
	show_summary(label_state, summary_labels)
}

#scan_vte.signal_connect("cursor_moved") { 
#	$stderr.puts "Cursor moved!"
#}

#scan_vte.signal_connect("text_inserted") { 
#	$stderr.puts "Text inserted!"
#}

#scan_vte.signal_connect("contents_changed") {
#	# unless $logfile.nil?
#	#	if Time.now.to_f - $last_progbar_update > 0.09
#	#		prog_bar.pulse
#	#		$last_progbar_update = Time.now.to_f
#	#	end
#	# end
#	$stderr.puts "Contents changed!"
#	summary_labels[0].text = $files_scanned.to_s
#	summary_labels[3].text = $files_infected.to_s
#	tdelta = Time.now - $scanstart
#	hrs = tdelta.to_i / 3600
#	min = (tdelta.to_i % 3600) / 60
#	sec = tdelta.to_i % 60
#	fmtstring = sprintf("%02d:%02d:%02d", hrs, min, sec)
#	summary_labels[2].text = fmtstring unless $logfile.nil?
#	# $stderr.puts scan_vte.row_count.to_s
#	# $stderr.puts scan_vte.scrollback_lines.to_s
#	# $stderr.puts scan_vte.get_text_range(14, 0, 14, 20, false)
#}

#scan_vte.signal_connect("text_inserted") { 
#	$stderr.puts "Text inserted!"
#}

update_button.signal_connect("clicked") {
	run_signature_update(update_label, update_button, scantab_buttons[1], update_vte, proxy_entries)
}

update_vte.signal_connect("child_exited") {
	retval= 666
	if system("test -f /tmp/avupdate.ret")
		File.open("/tmp/avupdate.ret").each { |line|
			retval = line.strip.to_i if line.strip != ''
		}
	end
	update_button.sensitive = true
	update_log_button.sensitive = true
	if retval < 1
		message = "Aktualisierung abgeschlossen"
		system("touch " + $check_key)
	elsif retval < 2
		message = "Überprüfung abgeschlossen, keine Aktualisierung nötig"
		system("touch " + $check_key)
	else
		message = "Aktualisierung fehlgeschlagen - Bitte prüfen Sie Ihre Netzwerkeinstellungen"
	end
	update_label.set_markup("\n<b>" + message + "</b>\n")
	dialog_update_info(window, message)
	scantab_buttons[1].sensitive = true
	$update_running = false
}



update_log_button.signal_connect("clicked") {
	# system("mousepad \"" + $update_logfile + "\" & ")
	# system("su surfer -c \"cbavlogviewer.sh " + $update_logfile + "\" & ")
	open_in_editor($update_logfile)
}

# Button for Terminal
# Start Terminal always with root privileges

button_list[0].signal_connect("clicked") {
	xterm = "Terminal"
	xterm = "xfce4-terminal" unless system("which Terminal")
	# system(xterm + " &")
	term_windows = retrieve_windows(xterm)
	if term_windows.size > 0
		raise_by_name(xterm)
	else
		system(xterm + " &")
	end
}

button_list[1].signal_connect("clicked") {
	term_windows = retrieve_windows("Thunar")
	if term_windows.size > 0
		raise_by_name("Thunar")
	else
		system("Thunar /media &")
	end
}

button_list[2].signal_connect("clicked") {
	term_windows = retrieve_windows("mmmm.rb")
	if term_windows.size > 0
		raise_by_name("mmmm.rb")
	else
		system("mmmm.rb &")
	end
}

button_list[3].signal_connect("clicked") {
	term_windows = retrieve_windows("wicd-client.py")
	if term_windows.size > 0
		raise_by_name("wicd-client.py")
	else
		system("wicd-gtk -n &")
	end
}

button_list[5].signal_connect("clicked") {
	firefox_open("http://www.botfrei.de/")
}

button_list[6].signal_connect("clicked") {
	# firefox_open("file:///etc/lesslinux/branding/readme_avira_de.html")
	system("su surfer -c \"cbavevince.sh /tmp/pdf/anleitung.pdf\" &")
}

top_buttons[1].signal_connect("clicked") {
	# firefox_open("file:///etc/lesslinux/branding/readme_avira_de.html")
	system("su surfer -c \"cbavevince.sh /tmp/pdf/anleitung.pdf\" &")
}

scantab_buttons[3].signal_connect("clicked") {
	firefox_open($shoplink)
}

button_list[7].signal_connect("clicked") {
	firefox_open($shoplink)
}

top_buttons[0].signal_connect("clicked") {
	firefox_open($shoplink)
}

button_list[8].signal_connect("clicked") {
	dialog_shutdown(window)
}

top_buttons[2].signal_connect("clicked") {
	dialog_shutdown(window)
}

scantab_buttons[4].signal_connect("clicked") {
	dialog_shutdown(window)
}

avira_link_button.signal_connect("clicked") {
	firefox_open("http://www.avira.com/de/")
}

button_list[9].signal_connect("clicked") {
	# dialog_not_wired(window)
	system("/etc/lesslinux/updater/updater.sh &")
}

button_list[11].signal_connect("clicked") {
	dialog_installer(window)
}

button_list[12].signal_connect("clicked") {
	system("cbavdisclaimer.sh &")
}

nb.signal_connect_after("switch-page") { |a,b,c|
		# $stderr.puts c.to_s
		if check_signature_age && $network_failed < 1 && nb.page == 2
			update_running = false
			update_nag_dialog(window, update_label, update_button, scantab_buttons[1], update_vte, nb, proxy_entries)
		end
}

# When showing the window lets check, if we have to update the signatures first!
# check_signature_age

window.signal_connect("show") { 
	if check_signature_age && check_network(3)
		update_nag_dialog(window, update_label, update_button, scantab_buttons[1], update_vte, nb, proxy_entries)
	elsif check_signature_age
		$network_failed = 1
		dialog_network_down(window)
	end
}

# Everything is created, now show the GUI

#window.signal_connect("frame-event") {
#	$stderr.puts "Ich hab den Fokus"
#}

window.set_size_request(800, 600)
window.border_width = 0
window.add(fixed)
window.show_all

Gtk.main