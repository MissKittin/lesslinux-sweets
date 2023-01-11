#!/usr/bin/ruby
# encoding: utf-8

def get_photorec_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	radio = Array.new
	header = Gtk::Label.new(extract_lang_string("select_two"))
	desc = Gtk::Label.new(extract_lang_string("restore_select_source"))
	desc.wrap = true
	desc.width_request = 570
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	drive_combo = Gtk::ComboBox.new
	reread = Gtk::Button.new(extract_lang_string("reread"))
	inner_box = Gtk::HBox.new(false, 2)
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	inner_box.pack_start(drive_combo, true, true, 0)
	inner_box.pack_start(reread, false, true, 0)
	outer_box.pack_start(inner_box, true, true, 0)
	return outer_box, drive_combo, reread
end

def get_photorec_types_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 0)
	header = Gtk::Label.new(extract_lang_string("restore_types_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	# scroll_pane = Gtk::ScrolledWindow.new
	# scroll_pane.set_size_request(400, 250)
	desc = Gtk::Label.new(extract_lang_string("restore_types_desc"))
	desc.width_request = 570
	filetypes = Array.new
	filetypes[0] = Gtk::CheckButton.new(extract_lang_string("restore_types_office"))
	# filetypes[1] = Gtk::CheckButton.new("Formatierte Textdateien (findet alte RTF- und moderne XML-Formate)")
	filetypes[1] = Gtk::CheckButton.new(extract_lang_string("restore_types_image"))
	filetypes[2] = Gtk::CheckButton.new(extract_lang_string("restore_types_video"))
	filetypes[3] = Gtk::CheckButton.new(extract_lang_string("restore_types_music"))
	filetypes[4] = Gtk::CheckButton.new(extract_lang_string("restore_types_mbox"))
	# filetypes[5] = Gtk::CheckButton.new("Zip-Archive (findet auch Office 2007-2011 und OpenOffice.org-Dateien)")
	filetypes[5] = Gtk::CheckButton.new(extract_lang_string("restore_types_arch"))
	filetypes[6] = Gtk::CheckButton.new(extract_lang_string("restore_types_every"))
	filetypes.each { |f| f.active = true } 
	filetypes[6].active = false
	filetypes[6].signal_connect("clicked") {
		if  filetypes[6].active?
			0.upto(5) { |i| 
				filetypes[i].active = true
				filetypes[i].sensitive = false
			}
		else
			0.upto(5) { |i|  filetypes[i].sensitive = true }
		end
	}
	
	fmachine = [ "office", "image", "video", "audio", "mail", "archive", "everything" ]
	outer_box.pack_start(header, true, false, 10)
	outer_box.pack_start(desc, true, true, 10)
	0.upto(8) { |i| outer_box.pack_start(filetypes[i], true, false, 3) }
	return outer_box, filetypes, fmachine
end


def get_photorec_target_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 5)
	radio = Array.new
	header = Gtk::Label.new(extract_lang_string("restore_tgt_head"))
	desc = Gtk::Label.new(extract_lang_string("restore_tgt_desc"))
	des2 = Gtk::Label.new(extract_lang_string("restore_tgt_desc2"))
	des3 = Gtk::Label.new(extract_lang_string("restore_tgt_desc3"))
	desc.wrap = true
	desc.width_request = 570
	des2.wrap = true
	des2.width_request = 570
	des3.wrap = true
	des3.width_request = 570
	
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	drive_combo = Gtk::ComboBox.new
	reread = Gtk::Button.new(extract_lang_string("reread"))
	inner_box = Gtk::HBox.new(false, 2)
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(des2, true, true, 0)
	outer_box.pack_start(des3, true, true, 0)
	inner_box.pack_start(drive_combo, true, true, 0)
	inner_box.pack_start(reread, false, true, 0)
	outer_box.pack_start(inner_box, true, true, 0)
	return outer_box, drive_combo, reread
end

def get_photorec_prog_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 5)
	header = Gtk::Label.new(extract_lang_string("restore_prog_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	### desc = Gtk::Label.new("Gefundene Dateien: 23")
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 570
	scan_vte = Vte::Terminal.new
	tfont = Pango::FontDescription.new("Sans Mono")
	tfont.absolute_size = 4
	puts tfont.size.to_s
	scan_vte.modify_font(tfont)
	scan_vte.set_size(80, 24)
	scan_vte.set_colors(Gdk::Color.new(0,0,0), Gdk::Color.new(65535, 65535, 65535), [])
	scan_exp = Gtk::Expander.new(extract_lang_string("details"))
	stop_button = Gtk::Button.new(extract_lang_string("cancel"))
	stop_button.signal_connect("clicked") {
		stop_button.sensitive = false
		system("killall -9 photorec")
		system("sync")
		stop_button.sensitive = true
	}
	outer_box.pack_start(header, true, false, 0)
	### outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(pgbar, true, true, 0)
	scan_exp.add(scan_vte)
	outer_box.pack_start(scan_exp, true, true, 0)
	outer_box.pack_start(stop_button, true, true, 0)
	return outer_box, scan_vte, pgbar
end

def fill_photorec_combo(combo, drives)
	device_list = Array.new
	100.downto(0) { |i| 
		begin
			combo.remove_text(i) 
		rescue
		end
	}
	drives.drive_list.keys.sort.each { |k|
		v = drives.drive_list[k]
		if v.attached == "usb"
			att = "(USB) "
		else
			att = "(SATA/eSATA/IDE) "
		end
		label = v.vendor + " " + v.model + " " + human_readable_bytes(v.blocks * v.bs) + att + " " + v.device
		unless v.has_mounted_partitions
			combo.append_text(label)
			device_list.push(v.device)
		end
	}
	combo.active = 0
	return device_list
end

def dialog_photorec_notypes(parent)
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(extract_lang_string("restore_no_types"))
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

def dialog_photorec_notarget(parent)
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(extract_lang_string("restore_no_target"))
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

def fill_photorec_targets(combo, drives, source, minfree=100_000_000)
	device_list = Array.new
	100.downto(0) { |i| 
		begin
			combo.remove_text(i) 
		rescue
		end
	}
	drives.dump
	drives.drive_list.keys.sort.each { |k|
		v = drives.drive_list[k]
		unless v.device == source  
			if v.attached == "usb"
				att = "(USB) "
			else
				att = "(SATA/eSATA/IDE) "
			end
			v.partitions.each { |n,m|
				# puts n.to_s + " " + m.to_s
				if (m.fs == "ntfs" || m.fs =~ /^fat/ || m.fs =~ /^ext/ || m.fs =~ /^btrfs/) && 
					m.mounted == false && m.free_space > minfree
					fslab = "" 
					unless m.fslabel.to_s == ""
						fslab = " (Label: "  + m.fslabel + ") "
					end
					#label = v.vendor + " " + v.model + " " + v.device + " " + att + 
					#	" Partition: " + n.to_s + fslab +" Frei: " + human_readable_bytes(m.free_space)
					# "%VENDOR% %MODEL% %DEVICE% %ATTACHED% partición: %PART%%LABEL% Libre %FREESPACE%",
					label = extract_lang_string("restore_tgt_combo").gsub("%VENDOR%", v.vendor).gsub("%MODEL%", v.model).gsub("%DEVICE%", v.device).
						gsub("%ATTACHED%", att).gsub("%PART%", n.to_s).gsub("%LABEL%", fslab).gsub("%FREESPACE%", human_readable_bytes(m.free_space))
					combo.append_text(label)
					device_list.push(m.id)
				end
			}
		end
	}
	combo.active = 0
	return device_list
end	

def run_photorec(source, categories, target, drives, vte, forw_button, progbar, parent)
	drives.drive_list.keys.sort.each { |k|
		v = drives.drive_list[k]
		v.partitions.each { |n,m|
			if m.id == target
				puts "Mounting target " + target + " FS: " + m.fs
				system("mkdir -p /var/run/lesslinux/" + $$.to_s + "/photorec_target")
				if m.fs == "ntfs"
					system("mount -t ntfs-3g -o rw,noatime " + target + " /var/run/lesslinux/" + $$.to_s + "/photorec_target")
				elsif m.fs =~ /^fat/
					system("mount -t vfat -o rw,noatime " + target + " /var/run/lesslinux/" + $$.to_s + "/photorec_target")
				else	
					system("mount -o rw,noatime " + target + " /var/run/lesslinux/" + $$.to_s + "/photorec_target")
				end
			end
		}
	}
	return false unless system("mountpoint -q /var/run/lesslinux/" + $$.to_s + "/photorec_target")
	forw_button.sensitive = false
	rescue_running = true
	# vte.fork_command("bash", [ "bash", "./run_chntpw.sh"])
	# "photorec /d \"" + target + "\" /cmd " + device + " " + partstring + ",fileopt,everything," + fileopt + "search"
	sleep_counter = 0
	recupdir = Time.now.strftime("Recovery-%Y%m%d-%H%M%S")
	params = [ "photorec", "/d", 
		"/var/run/lesslinux/" + $$.to_s + "/photorec_target/"+ recupdir , "/cmd", source,
		"partition_none,fileopt," + get_photorec_fileopts(categories) + ",search" ]
	puts params.join(" ")
	vte.fork_command("photorec", params )
	vte.signal_connect("child_exited") { rescue_running = false }
	auxiliary_drive = nil
	progbar.text = extract_lang_string("restore_running")
	while rescue_running == true
		progbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		if sleep_counter % 50 == 0
			# Check for free space!
			df_out = ` df -k #{target} | tail -n1 `
			freespace = df_out.split[3].to_i
			# FIXME: Move this out?
			# auxiliary_drive = nil
			if freespace < 100_000 && auxiliary_drive.nil?
				puts "Space is getting narrow, please STOP, clean up and CONT!"
				system("killall -STOP photorec")
				# dialog for copying
				copy_and_goon = dialog_photorec_space(parent)
				# dialog_move_recovered("/var/run/lesslinux/" + $$.to_s + "/photorec_target/", recupdir)
				if copy_and_goon == true
					cancel, auxiliary_drive = dialog_photorec_newtarget(parent, source)
					if cancel == false
						move_success = photorec_move_found(recupdir, auxiliary_drive)
						system("killall -CONT photorec")
					else
						system("killall -9 photorec")
					end
				else
					system("killall -9 photorec")
				end
			elsif freespace < 100_000
				system("killall -STOP photorec")
				unless photorec_move_found(recupdir, auxiliary_drive)
					auxiliary_drive = nil
				else
					system("killall -CONT photorec")
				end
			end
		end
		if sleep_counter == 100 || sleep_counter % 500 == 0
			fcount = ` ls /var/run/lesslinux/#{$$.to_s}/photorec_target/#{recupdir}* | grep -v ':$' | grep -v '^$' | wc -l `
			progbar.text = extract_lang_string("restore_count").gsub("%COUNT%",  fcount.strip)
		end
		sleep 0.1
		sleep_counter += 1
	end
	system("umount /var/run/lesslinux/" + $$.to_s + "/photorec_target")
	forw_button.sensitive = true
	return recupdir 
end

def get_photorec_finish_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 015)
	header = Gtk::Label.new(extract_lang_string("restore_finished_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("restore_finished_desc"))
	img = Gtk::Image.new("recovery.png")
	desc.wrap = true
	desc.width_request = 570
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	 outer_box.pack_start(img, true, true, 0)
	return outer_box
end

def dialog_photorec_space(parent)
	moveon = false
	msg = extract_lang_string("restore_space_warn")
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

def dialog_photorec_newtarget(parent, source)
	target = nil
	cancel = true
	msg = extract_lang_string("restore_new_target")
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
	drive_combo = Gtk::ComboBox.new
	reread = Gtk::Button.new(extract_lang_string("reread"))
	target_devs = fill_photorec_targets(drive_combo, AllDrives.new(false, false, false), source, 1_000_000_000)
	hb = Gtk::HBox.new
	hb.pack_start_defaults(drive_combo)
	hb.pack_start_defaults(reread)
	dialog.vbox.add(hb)
	dialog.show_all
	dialog.run { |resp|
		if resp == Gtk::Dialog::RESPONSE_OK
			target = target_devs[drive_combo.active] 
			cancel = false
		end
		dialog.destroy
	}
	return cancel, target
end

def photorec_move_found(recupdir, auxiliary_drive)
	blocked_raw = ` lsof | grep photorec_target/#{recupdir} `
	blocked_file = blocked_raw.split[-1]
	blocked_dir = blocked_file.split("/")[-2]
	puts "Blocked Dir: " + blocked_dir
	system("mkdir  /var/run/lesslinux/" + $$.to_s + "/photorec_auxiliary")
	system("mount " + auxiliary_drive + " /var/run/lesslinux/" + $$.to_s + "/photorec_auxiliary")
	# FIXME: Fail gracefully if only one directory exists and this does not
	# provide enough space
	copycount = 0
	0.upto(10_000) { |i|
		aux_free = ` df -k #{auxiliary_drive} | tail -n1 `.split[-3].to_i
		if File.exist?("/var/run/lesslinux/" + $$.to_s + "/photorec_target/" + recupdir + "." + i.to_s) &&
			recupdir + "." + i.to_s != blocked_dir &&
			Dir.entries("/var/run/lesslinux/" + $$.to_s + "/photorec_target/" + recupdir + "." + i.to_s).size > 2 &&
			` du -k /var/run/lesslinux/#{$$}/photorec_target/#{recupdir}.#{i.to_s} `.split[0].to_i < aux_free
			system("rsync -avHP /var/run/lesslinux/" + $$.to_s + "/photorec_target/" + recupdir + "." + i.to_s + " " +
				" /var/run/lesslinux/" + $$.to_s + "/photorec_auxiliary/")
			Dir.entries("/var/run/lesslinux/" + $$.to_s + "/photorec_target/" + recupdir + "." + i.to_s).each { |d|
				unless d == "." || d == ".."
					system("rm -rf /var/run/lesslinux/" + $$.to_s + "/photorec_target/" + recupdir + "." + i.to_s + "/" + d)
				end
			}
			system("rm -rf /var/run/lesslinux/" + $$.to_s + "/photorec_target/" + recupdir + "." + i.to_s + "/*")
			copycount += 1
		elsif File.exist?("/var/run/lesslinux/" + $$.to_s + "/photorec_target/" + recupdir + "." + i.to_s) && Dir.entries("/var/run/lesslinux/" + $$.to_s + "/photorec_target/" + recupdir + "." + i.to_s).size < 3
			puts "Empty Dir: " + " /var/run/lesslinux/" + $$.to_s + "/photorec_target/" + recupdir + "." + i.to_s
		end
	}
	system("umount /var/run/lesslinux/" + $$.to_s + "/photorec_auxiliary")
	if copycount > 0
		return true
	else
		return false
	end
end

def get_photorec_categories(photorec_ftypes, m_ftypes)
	retval = Array.new
	0.upto(photorec_ftypes.size - 1) { |i|
		retval.push(m_ftypes[i]) if photorec_ftypes[i].active? 
	}
	return retval
end

def dialog_photorec_allornothing(parent)
	moveon = false
	msg = extract_lang_string("restore_all_warn")
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

def get_photorec_fileopts(categories)
	return "everything,enable" if categories.include?("everything")
	fpath = "photorec_suffixes.txt"
	types = Array.new
	retstring = "everything,disable"
	File.open(fpath).each { |l|
		toks = l.strip.split
		if !toks[1].nil? && categories.include?(toks[1]) && !types.include?(toks[0])
			types.push toks[0]
			retstring = retstring + "," + toks[0] + ",enable"
		end
	}
	return "everything,enable" if types.size < 1
	return retstring
end
