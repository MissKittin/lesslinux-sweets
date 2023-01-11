#!/usr/bin/ruby
# encoding: utf-8

def get_chooser_screen(fwdbutton, simulate)
	icon_theme = Gtk::IconTheme.default
	outer_box = Gtk::VBox.new(false, 10)
	outer_box.set_size_request(570, 300)
	radio = Array.new
	header = Gtk::Label.new(extract_lang_string("select_title"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	radio[0] = Gtk::RadioButton.new(extract_lang_string("select_one"))
	radio[1] = Gtk::RadioButton.new(radio[0], extract_lang_string("select_two"))
	radio[2] = Gtk::RadioButton.new(radio[0], extract_lang_string("select_three"))
	radio[3] = Gtk::RadioButton.new(radio[0], extract_lang_string("select_four"))
	radio[4] = Gtk::RadioButton.new(radio[0], extract_lang_string("select_five"))
	radio[5] = Gtk::RadioButton.new(radio[0], extract_lang_string("select_six"))
	outer_box.pack_start(header, true, true, 0)
	# 0.upto(5) { |i| outer_box.pack_start(radio[i], true, false, 0) }

	button = Array.new
	0.upto(5) { |i| 
		button[i] = Gtk::Button.new
		button[i].xalign = 0.0 
	}
	button[0].label = extract_lang_string("select_one")
	button[0].image = Gtk::Image.new(icon_theme.load_icon("gtk-stop", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	
	# button[1].label = "Wichtige Dateien wurden versehentlich gelöscht"
	# button[1].image = Gtk::Image.new(icon_theme.load_icon("gnome-searchtool", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	b1l = Gtk::Label.new extract_lang_string("select_two")
	b1l.wrap = true
	b1l.width_request = 230
	b1i = Gtk::Image.new(icon_theme.load_icon("gnome-searchtool", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	b1a = Gtk::Alignment.new(0.0, 0.0, 1.0, 1.0)
	b1a.add b1l
	b1b = Gtk::HBox.new(false, 4)
	b1b.pack_start(b1i, false, true, 0)
	b1b.pack_start(b1a, false, true, 0)
	button[1].add b1b
	
	# button[2].label = "Ich habe mein Windows-Passwort vergessen"
	# button[2].image = Gtk::Image.new(icon_theme.load_icon("system-users", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	b2l = Gtk::Label.new extract_lang_string("select_three")
	b2l.wrap = true
	b2l.width_request = 230
	b2i = Gtk::Image.new(icon_theme.load_icon("system-users", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	b2a = Gtk::Alignment.new(0.0, 0.0, 1.0, 1.0)
	b2a.add b2l
	b2b = Gtk::HBox.new(false, 4)
	b2b.pack_start(b2i, false, true, 0)
	b2b.pack_start(b2a, false, true, 0)
	button[2].add b2b
	
	# button[3].label = "Ich habe den Verdacht, dass ich einen Virus habe"
	# button[3].image = Gtk::Image.new(icon_theme.load_icon("help-browser", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	b3l = Gtk::Label.new extract_lang_string("select_four")
	b3l.wrap = true
	b3l.width_request = 230
	# b3i = Gtk::Image.new(icon_theme.load_icon("help-browser", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	b3i = Gtk::Image.new("virus.png")
	b3a = Gtk::Alignment.new(0.0, 0.0, 1.0, 1.0)
	b3a.add b3l
	b3b = Gtk::HBox.new(false, 4)
	b3b.pack_start(b3i, false, true, 0)
	b3b.pack_start(b3a, false, true, 0)
	button[3].add b3b
	
	#button[4].label = "Ich möchte Windows neu installieren oder meinen Computer verkaufen"
	#button[4].image = Gtk::Image.new(icon_theme.load_icon("editclear", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	
	b4l = Gtk::Label.new  extract_lang_string("select_five")
	b4l.wrap = true
	b4l.width_request = 230
	b4i = Gtk::Image.new(icon_theme.load_icon("edit-clear", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	b4a = Gtk::Alignment.new(0.0, 0.0, 1.0, 1.0)
	b4a.add b4l
	b4b = Gtk::HBox.new(false, 4)
	b4b.pack_start(b4i, false, true, 0)
	b4b.pack_start(b4a, false, true, 0)
	button[4].add b4b
	
	# button[5].label = "Ich möchte eine zuvor erstellte Sicherung zurückspielen" 
	# button[5].image = Gtk::Image.new(icon_theme.load_icon("gtk-redo-ltr", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	b5l = Gtk::Label.new    extract_lang_string("select_six")
	# "Ich möchte eine zuvor erstellte Sicherung zurückspielen" 
	b5l.wrap = true
	b5l.width_request = 230
	b5i = Gtk::Image.new(icon_theme.load_icon("gtk-redo-ltr", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	b5a = Gtk::Alignment.new(0.0, 0.0, 1.0, 1.0)
	b5a.add b5l
	b5b = Gtk::HBox.new(false, 4)
	b5b.pack_start(b5i, false, true, 0)
	b5b.pack_start(b5a, false, true, 0)
	button[5].add b5b
	
	stab = Gtk::Table.new(3, 2, true)
	stab.height_request = 250
	stab.set_row_spacings 4
	0.upto(2) { |i|           
		button[i].height_request = 60
		stab.attach(button[i], 0, 1, i, i + 1, Gtk::FILL|Gtk::EXPAND, 2, 2)
	}
	3.upto(5) { |i|
		button[i].height_request = 60
		stab.attach(button[i], 1, 2, i - 3, i - 2, Gtk::FILL|Gtk::EXPAND, 2, 2)
	}
	# 0.upto(5) { |i| 
	#	# button[i].height_request = 60
	#	outer_box.pack_start(button[i], true, true, 00)
	# }
	outer_box.pack_start(stab, true, true, 0)
	return outer_box, radio, button
end

def check_network
	# Check the network by "digging" for www.computerbild.de
	# if this works, routing and name resolution should work
	return true if system("nslookup www.computerbild.de") # || system("nslookup www.computerbild.de 8.8.8.8")
	return false
end

def get_networks 
	# First find interfaces:
	interfaces = Array.new
	networks = Hash.new
	IO.popen("iwconfig 2>&1") { |l|
		while l.gets
			line = $_.strip
			if line =~ /ESSID/
				interfaces.push(line.split[0])
			end
		end
	}
	interfaces.each { |i|
		networks[i] = Array.new
		system("ifconfig " + i + " up")
		IO.popen("iwlist " + i + " scan") { |l|
			while l.gets
				line = $_.strip
				if line =~ /^ESSID\:\"(.*?)\"/
					networks[i].push($1)
				end
			end
		}
	}
	# return { "wlan0" => [ "mattiasanja108", "bueromattias" ] }
	return networks
end

def fill_wlan_combo(combo, networks)
	99.downto(0) { |i|
		begin
			combo.remove_text(i)
		rescue
		end
	}
	best_interface = nil
	networks_found = Hash.new
	max_nets = -1
	cleaned_nets = Array.new
	networks.each { |k,v|
		networks_found[k] = 0
		v.each { |n|
			cleaned_nets.push(n)
			networks_found[k] += 1
		}
		best_interface = k if networks_found[k] > max_nets
	}
	cleaned_nets.sort.uniq.each { |n| combo.append_text(n) }
	combo.active = 0
	return best_interface
end

def dialog_nonet(parent)
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(extract_lang_string("wlan_not_found"))
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);

	# Add the message in a label, and show everything we've added to the dialog.
	# dialog.vbox.pack_start_defaults(hbox) # Also works, however dialog.vbox
                                          # limits a single item (element).
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run
	dialog.destroy
end

def window_net_connect(parent, essid, key, buttons)
	buttons.each { |b| b.sensitive = false }
	dwin = Gtk::Window.new
	dwin.set_default_size(400, 40)
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 300
	dwin.add(pgbar)
	dwin.deletable = false
	dwin.show_all
	ccount = 0
	netnum = -1
	system("wicd-cli --wireless -S")
	IO.popen("wicd-cli --wireless -l") { |l|
		while l.gets 
			ltoks = $_.strip.split
			netnum = ltoks[0].to_i if ltoks[3] == essid
		end
	}
	if key == ""
		system("wicd-cli --wireless -n " + netnum.to_s + " -p encryption -s False")
	else
		system("wicd-cli --wireless -n " + netnum.to_s + " -p encryption -s True")
		system("wicd-cli --wireless -n " + netnum.to_s + " -p enctype -s wpa")
		system("wicd-cli --wireless -n " + netnum.to_s + " -p encryption_method -s wpa")
		system("wicd-cli --wireless -n " + netnum.to_s + " -p key -s " + key)
	end
	connecting_active = true
	connect_vte = Vte::Terminal.new
	connect_vte.signal_connect("child-exited") { connecting_active = false }
	connect_vte.fork_command("wicd-cli", [ "wicd-cli", "--wireless", "-n", netnum.to_s, "-c" ])
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	while ( connecting_active == true && ccount < 1200 ) || ccount < 200
		pgbar.pulse
		pgbar.text = extract_lang_string("wlan_connecting")
		sleep 0.1
		ccount += 1
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end
	dwin.destroy
	buttons.each { |b| b.sensitive = true }
end





def run_kexec_memtest
	# FIXME: Unmount first!!!
	system("chvt 2")
	system("kexec --force --reset-vga /usr/share/memtest/memtest")
end

def reread_swap_drives(drives, combo)
	available_sticks = Array.new
	99.downto(0) {
		begin
			combo.remove_text(0)
		rescue
		end
	}
	drives.drive_list.each { |k,v|
		if v.attached == "usb"
			v.partitions.each { |n,p|
				if p.mounted == false && p.fs =~ /^fat/ && p.free_space > 805_306_368
					available_sticks.push(p.device)
					combo.append_text( v.vendor + " " + v.model + " " + (v.blocks * v.bs / 1024 / 1024 ).to_s + "MB " + p.device )
				end
			}
		end
	}
	combo.active = 0
	combo.sensitive = true
	return available_sticks
end

def create_swap(swapdev)
	puts "Creating swap on: " + swapdev
	system("mkdir /var/run/lesslinux/" + $$.to_s + "/tmp_swap")
	system("mount " + swapdev + " /var/run/lesslinux/" + $$.to_s + "/tmp_swap")
	system("dd if=/dev/zero bs=1M count=768 of=/var/run/lesslinux/" + $$.to_s + "/tmp_swap/swapfile.cry")
	system("umount /var/run/lesslinux/" + $$.to_s + "/tmp_swap")
	system("/etc/rc.d/0171-swap.sh start " + swapdev)
end

def generic_dialog(parent, text)
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);

	# Add the message in a label, and show everything we've added to the dialog.
	# dialog.vbox.pack_start_defaults(hbox) # Also works, however dialog.vbox
                                          # limits a single item (element).
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run
	dialog.destroy
end
