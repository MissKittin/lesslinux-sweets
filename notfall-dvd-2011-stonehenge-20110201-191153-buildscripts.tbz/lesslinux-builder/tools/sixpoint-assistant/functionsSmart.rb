#!/usr/bin/ruby
# encoding: utf-8

def get_failure_screen(fwdbutton, simulate)
	icon_theme = Gtk::IconTheme.default
	outer_box = Gtk::VBox.new(true, 5)
	outer_box.set_size_request(570, 270)
	radio = Array.new
	header = Gtk::Label.new(extract_lang_string("select_one") )
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	radio[0] = Gtk::RadioButton.new(extract_lang_string("smart_fail_start"))
	radio[1] = Gtk::RadioButton.new(radio[0], extract_lang_string("smart_fail_ntldr"))
	radio[2] = Gtk::RadioButton.new(radio[0], extract_lang_string("smart_fail_noos"))
	outer_box.pack_start(header, true, true, 0)
	# 0.upto(2) { |i| outer_box.pack_start(radio[i], true, false, 0) }
	
	button = Array.new
	0.upto(2) { |i| 
		button[i] = Gtk::Button.new
		button[i].xalign = 0.0 
	}
	button[0].label = extract_lang_string("smart_fail_start")
	button[0].image = Gtk::Image.new(icon_theme.load_icon("gnome-monitor", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button[1].label = extract_lang_string("smart_fail_ntldr")
	button[1].image = Gtk::Image.new("winlogo.png") #icon_theme.load_icon("help-browser", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	b2l = Gtk::Label.new extract_lang_string("smart_fail_noos")
	b2l.wrap = true
	b2l.width_request = 490
	lbx = Gtk::Alignment.new(0.0, 0.0, 1.0, 1.0)
	lbx.add b2l
	# button[2].add b2l
	aux_hb =  Gtk::HBox.new(false, 4)
	aux_hb.pack_start( Gtk::Image.new(icon_theme.load_icon("gtk-floppy", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)), false, true, 0)
	aux_hb.pack_start( lbx, false, true, 0)
	# button[2].image = Gtk::Image.new(icon_theme.load_icon("system-users", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	button[2].add aux_hb
	0.upto(2) { |i| outer_box.pack_start(button[i], true, true, 0) }
	return outer_box, radio, button
end

def get_smart_overview_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 5)
	header = Gtk::Label.new(extract_lang_string("smart_read_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	drivebox = Gtk::VBox.new(false, 5)
	scroll_pane = Gtk::ScrolledWindow.new
	scroll_pane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
	scroll_pane.add_with_viewport(drivebox)
	scroll_pane.set_size_request(570, 200)
	all_devices = Array.new
	all_checkboxes = Array.new
	drv_count = 0
	desc = Gtk::Label.new(extract_lang_string("smart_read_desc"))
	desc.width_request = 560
	desc.wrap = true
	lbx = Gtk::Alignment.new(0.0, 0.0, 1.0, 1.0)
	lbx.add desc
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(scroll_pane, true, true, 0)
	outer_box.pack_start(lbx, true, true, 0)
	return outer_box, drivebox
end

def get_smart_progress_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("smart_prog_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("smart_prog_desc"))
	desc.wrap = true
	desc.width_request = 570
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 570
	scan_vte = Vte::Terminal.new
	scan_exp = Gtk::Expander.new(extract_lang_string("details"))
	stop_smart_test = Gtk::Button.new(extract_lang_string("cancel"))
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(pgbar, true, true, 0)
	outer_box.pack_start(stop_smart_test, true, true, 0)
	scan_exp.add(scan_vte)
	### outer_box.pack_start(scan_exp, true, true, 0)
	return outer_box, scan_vte, pgbar, stop_smart_test
end

def get_smart_fail_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 5)
	header = Gtk::Label.new(extract_lang_string("smart_error_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("smart_error_desc"))
	desc.wrap = true
	desc.width_request = 570
	drive_combo = Gtk::ComboBox.new
	reread = Gtk::Button.new(extract_lang_string("reread"))
	drivebox = Gtk::VBox.new(false, 5)
	scroll_pane = Gtk::ScrolledWindow.new
	scroll_pane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
	scroll_pane.add_with_viewport(drivebox)
	scroll_pane.set_size_request(570, 140)
	## inner_box = Gtk::HBox.new(false, 0)
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	## inner_box.pack_start(drive_combo, true, true, 0)
	## inner_box.pack_start(reread, true, true, 0)
	## outer_box.pack_start(inner_box, true, true, 0)
	outer_box.pack_start(scroll_pane, true, true, 0)
	outer_box.pack_start(reread, true, true, 0)
	return outer_box, drivebox, reread
end

def get_smart_clone_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("smart_save_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	## desc = Gtk::Label.new("Fortschritt: 42%")
	desc = Gtk::Label.new(extract_lang_string("smart_save_desc"))
	desc.wrap = true
	desc.width_request = 570
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 570
	scan_vte = Vte::Terminal.new
	scan_vte.set_colors(Gdk::Color.new(0,0,0), Gdk::Color.new(65535, 65535, 65535), [])
	scan_vte.set_size(80, 12)
	stop_button = Gtk::Button.new(extract_lang_string("cancel"))
	stop_button.sensitive = false
	### scan_exp = Gtk::Expander.new("Details anzeigen / ausblenden")
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(pgbar, true, true, 0)
	outer_box.pack_start(scan_vte, true, true, 0)
	outer_box.pack_start(stop_button, true, true, 0)
	
	## scan_exp.add(scan_vte)
	## outer_box.pack_start(scan_exp, true, true, 0)
	return outer_box, scan_vte, pgbar, stop_button
end

def get_smart_finish_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("smart_fini_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("smart_fini_desc"))
	desc.wrap = true
	desc.width_request = 570
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	return outer_box
end

def get_smart_ok_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("smart_ok_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc1 = Gtk::Label.new(extract_lang_string("smart_ok_desc"))
	desc2 = Gtk::Label.new(extract_lang_string("smart_ok_desc2"))
	check_button = Gtk::Button.new(extract_lang_string("smart_fsck"))
	desc1.wrap = true
	desc1.width_request = 570
	desc2.wrap = true
	desc2.width_request = 570
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc1, true, true, 0)
	outer_box.pack_start(desc2, true, true, 0)
	return outer_box, check_button
end

def smart_short_summary(drives)
	# if a drive is 
	results = Hash.new
	test_types = Hash.new
	bad_sectors = Hash.new
	reallocated_sectors = Hash.new
	seek_errors = Hash.new
	has_smart = Hash.new
	drives.drive_list.each { |k,v|
		numtests = 0
		test_types[k] = nil
		has_smart[k] = false
		system("smartctl -s on " + k)
		IO.popen("smartctl -c " + k) { |l|
			while l.gets
				line = $_.strip
				has_smart[k] = true if line =~ /START OF READ SMART DATA SECTION/
			end
		}	
		inside = false
		IO.popen("smartctl -l selftest " + k) { |l|
			while l.gets
				line = $_.strip
				if inside == true && line =~/^\#/
					if line =~ /Short offline/ && test_types[k].nil?
						test_types[k] = "short"
					end
					if (line =~ /Extended offline/ || line =~ /Extended captive/) \
							&& (test_types[k].nil? || test_types[k] == "short") 
						test_types[k] = "long"
					end
					if line =~ /Completed\: read failure/
						results[k] = "error"
					end
				end
				inside = true if line =~ /START OF READ SMART DATA SECTION/
			end
		}
		inside = false
		IO.popen("smartctl --attributes " + k) { |l|
			while l.gets
				line = $_.strip
				ltoks = line.split
				if inside == true && ltoks[0].to_i == 5 && ltoks[-1].to_i > 0
					reallocated_sectors[k] = ltoks[-1].to_i
				elsif inside == true && ltoks[0].to_i == 7 && ltoks[-1].to_i > 100
					seek_errors[k] = ltoks[-1].to_i
				elsif inside == true && ltoks[0].to_i == 197 && ltoks[-1].to_i > 0
					bad_sectors[k] = ltoks[-1].to_i
				end
				inside = true if line =~ /^ID\# ATTRIBUTE/
			end
		}
		
	}
	return results, has_smart, test_types, bad_sectors, reallocated_sectors, seek_errors
end

def fill_smart_info(drives, res, available, types, bad, reallocated, seek, panel)
	fat_font = Pango::FontDescription.new("Sans Bold")
	icon_theme = Gtk::IconTheme.default
	panel.each { |c| panel.remove(c) }
	drives.drive_list.keys.sort.each { |k|
		v = drives.drive_list[k]
		if v.blocks * v.bs > 12_000_000_000
			size = (v.blocks * v.bs / 1024 / 1024 / 1024 ).to_s + "GB "
		else
			size = (v.blocks * v.bs / 1024 / 1024 ).to_s + "MB "
		end
		desc = v.vendor.to_s + " " + v.model.to_s + " " + size + v.device.to_s
		if v.attached == "usb"
			desc += " (USB)" 
		else
			desc += " (SATA/eSATA/IDE)"
		end
		puts desc
		l = Gtk::Label.new(desc )
		# l = Gtk::Label.new "Hulla"
		l.modify_font(fat_font)
		ltext = Array.new
		face = "face-uncertain"
		if available[k] == false
			ltext.push extract_lang_string("smart_info_nosmart")
		else
			if types[k].nil?
				ltext.push     extract_lang_string("smart_info_notest")
			elsif types[k] == "short"
				ltext.push     extract_lang_string("smart_info_shorttest")
				face = "face-plain"
			elsif types[k] == "long"
				ltext.push     extract_lang_string("smart_info_longtest")
				face = "face-smile"
			end
			if bad[k].to_i > 0 || reallocated[k].to_i > 0 || seek[k].to_i > 0
				ltext.push   extract_lang_string("smart_info_bad")
				face = "face-sad"
			end
			if res[k] == "error"
				ltext.push   extract_lang_string("smart_info_verybad")
				face = "face-sad"
			end
		end
		hbox = Gtk::HBox.new(false, 5)
		hbox.width_request = 550
		img = Gtk::Image.new(icon_theme.load_icon(face, 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
		hbox.pack_start(img, false, true, 0)
		slab = Gtk::Label.new(ltext.join(" "))
		slab.width_request = 480
		slab.wrap = true
		if available[k] == true
			panel.pack_start(l, false, true, 5)
			hbox.pack_start(slab, false, true, 0)
			panel.pack_start(hbox, false, true, 5)
		end
	}
end

def run_smart_check(drives, progbar, buttons)
	buttons.each { |b| b.sensitive = false }
	max_duration = -1
	durations = Hash.new
	remaining = Hash.new
	finished = Hash.new
	bad_drives = Hash.new
	drives.drive_list.keys.sort.each { |k|
		v = drives.drive_list[k]
		system("smartctl -s on " + k)
		system("smartctl -X " + k)	
		inside = false
		IO.popen("smartctl -c " + k) { |l|
			while l.gets
				line = $_.strip
				if line =~ /recommended polling time.*\((.*?)\)/ && inside == true
					# puts v.device + " time: " + $1.to_i.to_s
					durations[k] = $1.to_i
					max_duration = $1.to_i if $1.to_i > max_duration
					break
				end
				inside = true if line =~ /Extended self-test routine/
			end
		}
		finished[k] = false
		system("smartctl -t long " + k)
	}	
	sleepcount = 0
	while finished.has_value?(false)
		remtime = -1
		progbar.pulse
		sleep 0.1
		progbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		if sleepcount % 100 == 0
			drives.drive_list.keys.sort.each { |k|
				lcount = 0
				test_line = -1
				IO.popen("smartctl -c " + k) { |l|
					while l.gets
						line = $_.strip
						if line =~ /Self-test routine in progress/ 
							test_line = lcount
						end
						if lcount == test_line + 1 && line =~ /(\d*)% of test remaining/
							remaining[k] = $1.to_i
						end
						lcount += 1
					end
				}
				finished[k] = true if test_line < 0
				this_remaining = remaining[k].to_i * durations[k].to_i / 100 
				remtime = this_remaining if this_remaining > remtime
			}
			progbar.text = extract_lang_string("smart_test_remain").gsub("%COUNT%",  remtime.to_s)
		end
		sleepcount += 1
	end
	results, has_smart, test_types, bad_sectors, reallocated_sectors, seek_errors = smart_short_summary(drives)
	results.each { |k,v| bad_drives[k] = drives.drive_list[k] if v == "error" }
	bad_sectors.each { |k,v| bad_drives[k] = drives.drive_list[k] if v > 0 }
	reallocated_sectors.each { |k,v| bad_drives[k] = drives.drive_list[k] if v > 0 }
	seek_errors.each { |k,v| bad_drives[k] = drives.drive_list[k] if v > 0 }
	progbar.fraction = 1.0
	progbar.text =      extract_lang_string("smart_test_finished")
	buttons.each { |b| b.sensitive = true }
	return bad_drives
end

def fill_smart_clone_panel(panel, drives, bad_drives)
	# panel.each { |c| panel.remove(c) }
	fat_font = Pango::FontDescription.new("Sans Bold")
	tgt_drives = Hash.new
	tgt_combos = Hash.new
	src_checks = Hash.new
	bad_drives.each { |k,v|
		puts "bad drive: " + k
		desc = v.vendor.to_s + " " + v.model.to_s + " " + human_readable_bytes(v.blocks * v.bs) + v.device
		if v.attached == "usb"
			desc += " (USB)" 
		else
			desc += " (SATA/eSATA/IDE)"
		end
		lab = Gtk::Label.new(desc)
		lab.modify_font(fat_font)
		panel.pack_start(lab, false, true, 5)
		cb = Gtk::CheckButton.new(extract_lang_string("smart_clone_desc"))
		src_checks[k] = cb
		hbox = Gtk::HBox.new(false, 0)
		panel.pack_start(cb, false, true, 5)
		tgt_combo = Gtk::ComboBox.new
		tgt_drives[k] = Array.new
		drives.drive_list.each { |d,e|
			unless bad_drives.has_key?(d) || v.blocks * v.bs > e.blocks * e.bs 
				puts "target: " + d
				desc = e.vendor.to_s + " " + e.model.to_s + " " + human_readable_bytes(e.blocks * e.bs) + e.device
				if e.attached == "usb"
					desc += " (USB)" 
				else
					desc += " (SATA/eSATA/IDE)"
				end
				tgt_combo.append_text(desc)
				tgt_drives[k].push(e.device)
			end
		}
		tgt_combo.active = 0
		tgt_combos[k] = tgt_combo
		panel.pack_start(tgt_combo, false, true, 5)
	}
	return src_checks, tgt_drives, tgt_combos 
	
end

def update_smart_clone_panel(tgt_combos, drives, bad_drives)
	tgt_drives = Hash.new
	# tgt_combos = Hash.new
	bad_drives.each { |k,v|
		puts "bad drive: " + k
		tgt_drives[k] = Array.new
		99.downto(0) { |i|
			begin
				tgt_combos[k].remove_text(i)
			rescue
			end
		}
		drives.drive_list.each { |d,e|
			unless bad_drives.has_key?(d) || v.blocks * v.bs > e.blocks * e.bs || e.has_mounted_partitions == true
				puts "target: " + d
				desc = e.vendor.to_s + " " + e.model.to_s + " " + human_readable_bytes(e.blocks * e.bs) + e.device
				if e.attached == "usb"
					desc += " (USB)" 
				else
					desc += " (SATA/eSATA/IDE)"
				end
				tgt_combos[k].append_text(desc)
				tgt_drives[k].push(e.device)
			end
		}
		tgt_combos[k].active = 0
	}
	return tgt_drives
end

def smart_no_src_dialog(parent)
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(extract_lang_string("smart_warn_nosrc"))
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

def smart_no_tgt_dialog(parent)
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(extract_lang_string("smart_warn_notgt"))
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

def smart_mult_tgt_dialog(parent)
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(extract_lang_string("smart_warn_multtgt"))
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

def smart_run_ddrescue(vte, progbar, srctgt, buttons)
	buttons.each { |b| b.sensitive = false } 
	args = Array.new
	args.push("ruby")
	args.push("run_ddrescue.rb")
	srctgt.each { |k,v|
		args.push(k)
		args.push(v)
		# args.push("/dev/null") 
	}
	ddrunning = true
	vte.signal_connect("child-exited") { ddrunning = false }
	vte.fork_command("ruby", args)
	progbar.text = extract_lang_string("smart_clone_progress")
	puts args.join(" ")
	while ddrunning == true
		sleep 0.1
		progbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end
	progbar.text = extract_lang_string("smart_clone_finished")
	progbar.fraction = 1.0
	buttons.each { |b| b.sensitive = true } 
end

def smart_run_ntfsfix(drives)
	drives.drive_list.each { |k,v|
		v.partitions.each { |n,p|
			if p.fs =~ /ntfs/
				puts "Fount ntfs partition: " + p.device
				system("ntfsfix " + p.device)
			end
		}
	}
end

def smart_tgt_not_empty(target, drives)
	puts "not empty? target " + target 
	drives.drive_list.each { |k,v|
		puts "not empty? target " + k
		if target == k
			puts "not empty? occupied " + v.occupied_space.to_s
			if v.occupied_space > 0
				return true
			else
				return false
			end
		end
	}
	return false
end

def smart_tgt_not_empty_dialog(parent, tgt)
	moveon = false
	msg = extract_lang_string("smart_clone_nonempty").gsub("%TARGET%", tgt) 
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ],
		[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ]	
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_CANCEL
	dialog.has_separator = false
	label = Gtk::Label.new(msg)
	label.wrap = true
	dialog.vbox.add(label)
	dialog.show_all
	dialog.run { |resp|
		if resp == Gtk::Dialog::RESPONSE_OK
			moveon = true
		end
		dialog.destroy
	}
	return moveon	
end

def get_ntldr_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 5)
	header = Gtk::Label.new(extract_lang_string("smart_ntldr_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("smart_ntldr_desc"))
	desc.wrap = true
	desc.width_request = 570
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	xphead = Gtk::Label.new(extract_lang_string("smart_ntldr_xp"))
	xpbutton = Gtk::Button.new(extract_lang_string("smart_ntldr_xpbutt"))
	xpbutton.signal_connect("clicked") { system("evince -p " + extract_lang_number("smart_ntldr_xppage").to_s + 
		" \"" + extract_lang_string("smart_ntldr_xpfile") + "\" &") }
	xphead.modify_font(fat_font)
	visthead = Gtk::Label.new(extract_lang_string("smart_ntldr_vista7"))
	visthead.modify_font(fat_font)
	vistbutton = Gtk::Button.new(extract_lang_string("smart_ntldr_vista7butt"))
	vistbutton.signal_connect("clicked") { system("evince -p " + extract_lang_number("smart_ntldr_vista7page").to_s + 
		" \"" + extract_lang_string("smart_ntldr_vista7file") + "\" &") }
	fintext = Gtk::Label.new(extract_lang_string("smart_ntldr_cont"))
	fintext.width_request = 570
	fintext.wrap = true
	help = Gtk::Label.new(extract_lang_string("smart_ntldr_folder"))
	help.wrap = true
	help.width_request = 570
	reboot_button = Gtk::Button.new(extract_lang_string("reboot"))
	reboot_button.signal_connect("clicked") { 
		system("rm /var/run/lesslinux/assistant_running")
		Gtk.main_quit
	}
	[ xphead, xpbutton, visthead, vistbutton, fintext, reboot_button ].each { |i|
		outer_box.pack_start(i, true, false, 0)
	}
	return outer_box
end

def get_noos_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("smart_noos_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("smart_noos_desc"))
	desc.wrap = true
	desc.width_request = 570
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	return outer_box
end

def get_noos_repaired_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 5)
	header = Gtk::Label.new(extract_lang_string("smart_mbr_done"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("smart_mbr_desc")) 
	des2 = Gtk::Label.new(extract_lang_string("smart_mbr_desc2"))
	desc.wrap = true
	desc.width_request = 570
	des2.wrap = true
	des2.width_request = 570
	xp1butt = Gtk::Button.new(extract_lang_string("smart_inst_xpbutt"))
	xp1butt.signal_connect("clicked") { system("evince -p " + extract_lang_number("smart_inst_xppage").to_s + 
		" \"" + extract_lang_string("smart_inst_xpfile") + "\" &") }
	visbutt = Gtk::Button.new(extract_lang_string("smart_inst_7butt"))
	visbutt.signal_connect("clicked") { system("evince -p " + extract_lang_number("smart_inst_7page").to_s + 
		" \"" + extract_lang_string("smart_inst_7file") + "\" &") }
	warn = Gtk::Label.new(extract_lang_string("smart_inst_backup"))
	warn.width_request = 570
	warn.wrap = true
	safebutt = Gtk::Button.new(extract_lang_string("smart_inst_bubutt"))
	safebutt.signal_connect("clicked") { system("evince -p " + extract_lang_number("smart_inst_bupage").to_s + 
		" \"" + extract_lang_string("smart_inst_bufile") + "\" &") }
	# help = Gtk::Label.new("Diese Anleitungen finden Sie auch im Ordner \"Anleitungen\" auf der CD.")
	# help.wrap = true
	# help.width_request = 570
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(des2, true, true, 0)
	outer_box.pack_start(xp1butt, true, true, 0)
	# outer_box.pack_start(xp2butt, true, true, 0)
	outer_box.pack_start(visbutt, true, true, 0)
	outer_box.pack_start(warn, true, true, 0)
	outer_box.pack_start(safebutt, true, true, 0) unless LANGUAGE == "es"
	# outer_box.pack_start(help, true, true, 0)
	return outer_box
end

def get_noos_failure_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 5)
	header = Gtk::Label.new(extract_lang_string("smart_mbr_fail"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("smart_mbr_fail_desc"))
	desc.wrap = true
	desc.width_request = 570
	xp1butt = Gtk::Button.new(extract_lang_string("smart_inst_xpbutt"))
	xp1butt.signal_connect("clicked") { system("evince -p " + extract_lang_number("smart_inst_xppage").to_s + 
		" \"" + extract_lang_string("smart_inst_xpfile") + "\" &") }
	visbutt = Gtk::Button.new(extract_lang_string("smart_inst_7butt"))
	visbutt.signal_connect("clicked") { system("evince -p " + extract_lang_number("smart_inst_7page").to_s + 
		" \"" + extract_lang_string("smart_inst_7file") + "\" &") }
	warn = Gtk::Label.new(extract_lang_string("smart_inst_backup"))
	warn.width_request = 570
	warn.wrap = true
	safebutt = Gtk::Button.new(extract_lang_string("smart_inst_bubutt"))
	safebutt.signal_connect("clicked") { system("evince -p " + extract_lang_number("smart_inst_bupage").to_s + 
		" \"" + extract_lang_string("smart_inst_bufile") + "\" &") }
	# help = Gtk::Label.new("Diese Anleitungen finden Sie auch im Ordner \"Anleitungen\" auf der CD.")
	# help.wrap = true
	# help.width_request = 570
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(xp1butt, true, true, 0)
	# outer_box.pack_start(xp2butt, true, true, 0)
	outer_box.pack_start(visbutt, true, true, 0)
	outer_box.pack_start(warn, true, true, 0)
	outer_box.pack_start(safebutt, true, true, 0) unless LANGUAGE == "es"
	# outer_box.pack_start(help, true, true, 0)
	return outer_box
end

def dialog_ntfsfix_done(parent)
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(extract_lang_string("smart_ntfsfix"))
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

def human_readable_bytes(num_size)
	size = ""
	if num_size > 12_000_000_000
		size = (num_size / 1024 / 1024 / 1024 ).to_s + "GB "
	elsif num_size > 12_000_000
		size = (num_size / 1024 / 1024 ).to_s + "MB "
	else
		size = (num_size / 1024 ).to_s + "kB "
	end
	return size
end

def dialog_bootsect_warn(parent)
	moveon = false
	msg =   extract_lang_string("smart_mbrwarn")
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ],
		[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ]	
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new(msg)
	label.wrap = true
	dialog.vbox.add(label)
	dialog.show_all
	dialog.run { |resp|
		if resp == Gtk::Dialog::RESPONSE_OK
			moveon = true
		end
		dialog.destroy
	}
	return moveon	
end

def run_bootsect_restore(drives) 
	success = false
	drives.drive_list.each { |k,v|
		if v.attached == "internal"
			ospart, ostype = v.identify_windows
			bootparts = v.boot_partitions
			unless ospart.nil?
				unless bootparts.size == 1
					bootparts.each { |i|
						puts "remove boot flag from: " + i
						# partnum = i[8..-1]
						system("parted -sm " + v.device + " set " + i[8..-1] + " boot off") 
					}
					puts "set boot flag on: " + ospart 
					system("parted -sm " + v.device + " set " + ospart[8..-1] + " boot on") 
				end
				puts "write MBR for " + ostype + " on device: " + v.device
				system("dd if=/usr/share/syslinux/mbr.bin of=" + v.device)
				success = true
			end
		end	
	}
	return success
end

