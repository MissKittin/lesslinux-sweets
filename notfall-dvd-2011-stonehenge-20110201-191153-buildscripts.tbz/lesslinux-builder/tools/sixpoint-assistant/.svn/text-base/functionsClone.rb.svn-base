#!/usr/bin/ruby
# encoding: utf-8

def get_restore_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	radio = Array.new
	header = Gtk::Label.new(extract_lang_string("clone_header"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	header.wrap = true
	desc = Gtk::Label.new(extract_lang_string("clone_desc"))
	des2 = Gtk::Label.new(extract_lang_string("clone_desc2")) 
	desc.wrap = true
	desc.width_request = 570
	des2.wrap = true
	des2.width_request = 570
	drive_combo = Gtk::ComboBox.new
	reread = Gtk::Button.new(extract_lang_string("reread"))
	inner_box = Gtk::HBox.new(false, 2)
	inner_box.pack_start(drive_combo, true, true, 0)
	inner_box.pack_start(reread, false, true, 0)
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(des2, true, true, 0)
	outer_box.pack_start(inner_box, true, true, 0)
	return outer_box, drive_combo, reread
end

def get_restore_target_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	radio = Array.new
	header = Gtk::Label.new(extract_lang_string("clone_tgt_head"))
	desc = Gtk::Label.new(extract_lang_string("clone_tgt_desc"))
	des2 = Gtk::Label.new(extract_lang_string("clone_tgt_warn"))
	desc.wrap = true
	desc.width_request = 570
	des2.wrap = true
	des2.width_request = 570
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	drive_combo = Gtk::ComboBox.new
	reread = Gtk::Button.new(extract_lang_string("reread"))
	inner_box = Gtk::HBox.new(false, 2)
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(des2, true, true, 0)
	inner_box.pack_start(drive_combo, true, true, 0)
	inner_box.pack_start(reread, false, true, 0)
	outer_box.pack_start(inner_box, true, true, 0)
	return outer_box, drive_combo, reread
end

def get_restore_progress_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 5)
	header = Gtk::Label.new(extract_lang_string("clone_progress_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	### desc = Gtk::Label.new("Fortschritt: 42%")
	desc = Gtk::Label.new(extract_lang_string("clone_progress_warn"))
	desc.wrap = true
	desc.width_request = 570
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 570
	scan_vte = Vte::Terminal.new
	scan_vte.set_size(80, 15)
	scan_vte.set_colors(Gdk::Color.new(0,0,0), Gdk::Color.new(65535, 65535, 65535), [])
	stop_button = Gtk::Button.new(extract_lang_string("cancel"))
	stop_button.sensitive = false
	### scan_exp = Gtk::Expander.new("Details anzeigen")
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(pgbar, true, true, 0)
	### scan_exp.add(scan_vte)
	outer_box.pack_start(scan_vte, true, true, 0)
	outer_box.pack_start(stop_button, true, true, 0)
	return outer_box, scan_vte, pgbar, stop_button
end

def get_restore_finish_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 5)
	header = Gtk::Label.new(extract_lang_string("clone_finished"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("clone_fin_desc"))
	desc.wrap = true
	desc.width_request = 570 
	reboot = Gtk::Button.new(extract_lang_string("reboot"))
	reboot.signal_connect("clicked") {
		system("rm /var/run/lesslinux/assistant_running")
		Gtk.main_quit
	}
	sec = Gtk::Label.new
	sec.set_markup(extract_lang_string("clone_further"))
	sec.wrap = true
	sec.width_request = 570 
	pdfbutt = Gtk::Button.new(extract_lang_string("clone_show_manual"))
	pdfbutt.signal_connect("clicked") { system("evince -p " + extract_lang_number("clone_manual_page").to_s + " " + extract_lang_string("clone_manual_path")  + " &") }
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(reboot, true, true, 0)
	outer_box.pack_start(sec, true, true, 0)
	outer_box.pack_start(pdfbutt, true, true, 0)
	return outer_box
end

def dialog_clone_compare(parent, clone_target, clone_source)
	msg = ""
	moveon = false
	if clone_target.nil?
		msg = extract_lang_string("clone_error_read")
		moveon = false
	elsif clone_source.last_partend < 0 && clone_target.size < clone_source.size
		msg =  extract_lang_string("clone_warn_noparts")
	elsif clone_source.last_partend > clone_target.size
		msg = extract_lang_string("clone_warn_bigger")
	end	
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
	# image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
	# hbox = Gtk::HBox.new(false, 5)
	# hbox.border_width = 10
	# hbox.pack_start_defaults(image)
	# hbox.pack_start_defaults(label)
	dialog.vbox.add(label)
	warn = Gtk::Label.new(extract_lang_string("clone_warn_destroy"))
	warn.wrap = true
	dialog.vbox.add(warn) unless   clone_target.nil?
	dialog.show_all
	dialog.run { |resp|
		if resp == Gtk::Dialog::RESPONSE_OK &&  !clone_target.nil?
			moveon = true
		end
		dialog.destroy
	}
	return moveon
end

def reread_full_drives(combo, drives_to_ignore)
	drive_meta = Hash.new
	retdrives = Array.new
	99.downto(0) { |i|
		begin
			combo.remove_text(i)
		rescue
		end
	}
	alldrives = AllDrives.new(false, false, false)
	alldrives.dump 
	alldrives.drive_list.each { |k,d|
		unless drives_to_ignore.include?(k) || d.has_mounted_partitions 
			retdrives.push(k)
			combo.append_text(d.device + " " + d.vendor.to_s + " " + d.model.to_s + " " + human_readable_bytes(d.blocks * d.bs) )
			drive_meta[k] = d
		end
	}
	combo.active = 0
	return retdrives, drive_meta
end