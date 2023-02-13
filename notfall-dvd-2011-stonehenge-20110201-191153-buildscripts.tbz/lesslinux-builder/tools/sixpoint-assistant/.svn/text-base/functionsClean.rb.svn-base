#!/usr/bin/ruby
# encoding: utf-8

def get_clean_screen(fwdbutton, simulate)
	icon_theme = Gtk::IconTheme.default
	outer_box = Gtk::VBox.new(false, 10)
	outer_box.set_size_request(570, 170)
	bbox = Array.new
	blab = Array.new
	img = Array.new
	
	radio = Array.new
	header = Gtk::Label.new(extract_lang_string("select_five"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	radio[0] = Gtk::RadioButton.new(extract_lang_string("clean_fast"))
	radio[1] = Gtk::RadioButton.new(radio[0], extract_lang_string("clean_good"))
	outer_box.pack_start(header, true, false, 5)
	# 0.upto(2) { |i| outer_box.pack_start(radio[i], true, false, 0) }
	
	button = Array.new
	0.upto(1) { |i| 
		button[i] = Gtk::Button.new
		button[i].xalign = 0.0 
	}
	
	# button[0].label = Gtk::Label.new "Schnellreinigung: Wählen Sie diese Option, wenn Sie Windows auf der bereinigten Festplatte neu installieren möchten."
	# button[0].label.width_request = 500
	# button[0].label.wrap = true
	#button[0].image = Gtk::Image.new(icon_theme.load_icon("media-seek-forward", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	#button[1].label = Gtk::Label.new "Tiefenreinigung: Falls Sie den Computer verkaufen oder die Ihre Festplatte entsorgen möchten, wählen Sie diese Option."
	#button[1].image = Gtk::Image.new(icon_theme.load_icon("edit-clear", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	#button[1].label.width_request = 500
	#button[1].label.wrap = true
	
	bbox[0] = Gtk::HBox.new(false, 5)
	blab[0] = Gtk::Label.new(  extract_lang_string("clean_fast"))
	img[0] =  Gtk::Image.new(icon_theme.load_icon("media-seek-forward", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	bbox[1] = Gtk::HBox.new(false, 5)
	blab[1] = Gtk::Label.new( extract_lang_string("clean_good") )
	img[1] = Gtk::Image.new(icon_theme.load_icon("edit-clear", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
	
	 0.upto(1) { |i| 
		blab[i].width_request = 500
		blab[i].wrap = true
		bbox[i].pack_start(img[i], false, true, 0)
		bbox[i].pack_start(blab[i], false, true, 0)
		button[i].add(bbox[i])
		outer_box.pack_start(button[i], true, true, 0) 
	}
	return outer_box, radio, button
end

def get_clean_drives(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 10)
	header = Gtk::Label.new(extract_lang_string("clean_select_part"))
	desc = Gtk::Label.new(extract_lang_string("clean_part_desc"))
	desc.wrap = true
	desc.width_request = 570
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	drivebox = Gtk::VBox.new(false, 5)
	scroll_pane = Gtk::ScrolledWindow.new
	scroll_pane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
	scroll_pane.add_with_viewport(drivebox)
	scroll_pane.set_size_request(570, 195)
	
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(scroll_pane, true, false, 0)
	return outer_box, drivebox, desc
end


def get_clean_progress_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 10)
	header = Gtk::Label.new(extract_lang_string("clean_progress_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	drivebox = Gtk::VBox.new(false, 5)
	scroll_pane = Gtk::ScrolledWindow.new
	scroll_pane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
	scroll_pane.add_with_viewport(drivebox)
	scroll_pane.set_size_request(570, 270)
	
	outer_box.pack_start(header, true, false, 0)
	# outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(scroll_pane, true, false, 0)
	return outer_box, drivebox
	# return outer_box, scan_vte, pgbar
end

def get_clean_finish_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("clean_done_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("clean_done_desc"))
	desc.wrap = true
	desc.width_request = 570
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	return outer_box
end

def fill_clean_list(box, type)
	box.each { |c| box.remove(c) }
	alldrives = AllDrives.new(true, true, false)
	drivelist = alldrives.drive_list
	all_checkboxes = Hash.new
	radio = Array.new
	fat_font = Pango::FontDescription.new("Sans Bold")
	drivelist.keys.sort.each { |k|
		v = drivelist[k]
		parts = Hash.new
		devices = Array.new
		0.upto(99) { |i|
			unless v.partitions[i].nil? || v.partitions[i].extended == true # || v.partitions[i].fs.to_s == ""
				p_desc = "Partition " + i.to_s + " " + human_readable_bytes(v.partitions[i].size) + v.partitions[i].fs.to_s 
				p_desc = p_desc + " Label: " + v.partitions[i].fslabel unless v.partitions[i].fslabel.to_s == "" 
				p_click = Gtk::CheckButton.new(p_desc)
				p_click.sensitive = false if v.partitions[i].mounted
				parts[v.partitions[i].id] = p_click
				
				# devices.push(v.partitions[i].id)
				# drivebox.pack_start(p_click, false, true, 5 )
			end
		}
		if parts.size > 0 && type == "fast"
			slab = v.vendor + " " + v.model + " " + human_readable_bytes(v.blocks * v.bs) + v.device
			if v.attached == "internal"
				slab += " (SATA/eSATA/IDE)"
			else
				slab += " (USB)"
			end
			l = Gtk::Label.new(slab  )
			l.modify_font(fat_font)
			box.pack_start(l, false, true, 5)
			parts.keys.sort.each { |p| 
				box.pack_start(parts[p], false, true, 5 ) 
				all_checkboxes[p] = parts[p] 
			}
		elsif type == "full"
			slab = v.vendor + " " + v.model + " " + human_readable_bytes(v.blocks * v.bs) + v.device
			if v.attached == "internal"
				slab += " (SATA/eSATA/IDE)"
			else
				slab += " (USB)"
			end
			p_click = Gtk::CheckButton.new(slab)
			p_click.sensitive = false if v.has_mounted_partitions
			box.pack_start(p_click, false, true, 5 ) 
			all_checkboxes[v.device] = p_click
			
		end
	}
	return all_checkboxes, alldrives
end

def fill_clean_pgbars(box, type, drivelist, checkboxes)
	box.each { |c| box.remove(c) }
	fat_font = Pango::FontDescription.new("Sans Bold")
	progress_bars = Hash.new
	parts = Hash.new
	devices = Array.new
	vtes = Hash.new
	drivelist.drive_list.keys.sort.each { |k|
		# puts k + " " + checkboxes[k].active?.to_s
		v = drivelist.drive_list[k]
		if type == "full" && checkboxes[k].active?
			slab = v.vendor + " " + v.model + " " + (v.blocks * v.bs / 1024 / 1024 ).to_s + "MB " + v.device
			if v.attached == "internal"
				slab += " (SATA/eSATA/IDE)"
			else
				slab += " (USB)"
			end
			l = Gtk::Label.new(slab  )
			l.modify_font(fat_font)
			box.pack_start(l, false, true, 5)
			pgbox = Gtk::HBox.new(false, 5)
			progress_bars[k] = Gtk::ProgressBar.new
			# progress_bars[k].width_request = 300
			pgbox.pack_start(progress_bars[k], true, true, 0)
			pgbutt = Gtk::Button.new(extract_lang_string("cancel"))
			pgbutt.signal_connect("clicked") { 
				pgbutt.sensitive = false
				f = File.new("/tmp/" + k.gsub("/", "_") + ".stop", "w")
				f.close
			}
			pgbox.pack_start(pgbutt, false, true, 0)
			# box.pack_start(progress_bars[k], false, true, 5)
			box.pack_start(pgbox, false, true, 5)
			vtes[k] = Vte::Terminal.new
		elsif type == "fast"
			0.upto(99) { |i|
				unless v.partitions[i].nil? || v.partitions[i].extended == true ||
					!checkboxes[v.partitions[i].device].active?  # || v.partitions[i].fs.to_s == ""	
					p_desc = v.vendor + " " + v.model + " Partition " + i.to_s + " " + 
						(v.partitions[i].size/1024/1024).to_s + "MB " + v.partitions[i].fs.to_s
					p_desc = p_desc + " Label: " + v.partitions[i].fslabel unless v.partitions[i].fslabel.to_s == ""
					l = Gtk::Label.new(p_desc)
					l.modify_font fat_font
					box.pack_start(l, false, true, 5)
					progress_bars[v.device.to_s + i.to_s] = Gtk::ProgressBar.new
					progress_bars[v.device.to_s + i.to_s].width_request = 400
					box.pack_start(progress_bars[v.device.to_s + i.to_s], false, true, 5)
					vtes[v.device.to_s + i.to_s] = Vte::Terminal.new
				end
			}
		end
	}
	return progress_bars, vtes
end

def dialog_empty_clean(parent)
	dialog = Gtk::Dialog.new(
		"Information",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(extract_lang_string("clean_no_selection"))
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

def dialog_clean_warn(parent, type)
	msg = ""
	moveon = false
	if type == "fast"
		msg = extract_lang_string("clean_fast_message")
	elsif type == "full"
		msg =  extract_lang_string("clean_good_message")
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

def run_clean(method, progress_bars, invisible_vtes, current_drivelist, checkboxes, forw_button, back_button)
	# run_clean(method, clean_pgbars, clean_vtes)
	delete_in_progress = Hash.new
	chunk_size = 64 * 1024 * 1024
	chunk_counts = Hash.new
	sleep_count = 0
	invisible_vtes.each { |k,v|
		if checkboxes[k].active? && method == "full"
			device_size = current_drivelist.drive_list[k].blocks * current_drivelist.drive_list[k].bs
			chunk_counts[k] = ((device_size / chunk_size) + 1).to_i
			delete_in_progress[k] = true
			invisible_vtes[k].fork_command("ruby", [ "ruby", "run_dd.rb", k, device_size.to_s, "/tmp/" + k.gsub("/", "_") + ".log"] )
			invisible_vtes[k].signal_connect("child-exited") { puts k + " exited!"; delete_in_progress[k] = false }
		elsif checkboxes[k].active? && method == "fast"
			device_size = 268435456
			chunk_counts[k] = 4
			delete_in_progress[k] = true
			invisible_vtes[k].fork_command("ruby", [ "ruby", "run_dd.rb", k, device_size.to_s, "/tmp/" + k.gsub("/", "_") + ".log"] )
			invisible_vtes[k].signal_connect("child-exited") { puts k + " exited!"; delete_in_progress[k] = false }
		else
			progress_bars[k].text = extract_lang_string("clean_no_clean")
		end
	}
	while delete_in_progress.has_value?(true) 
		if sleep_count % 300 == 0
			unless system("ps waux | grep run_dd.rb")
				delete_in_progress.each { |k,v| delete_in_progress[k] = false }
			end
		end
		forw_button.sensitive = false
		back_button.sensitive = false
		progress_bars.each { |k,v|
			if delete_in_progress[k] == true && sleep_count % 10 == 0
				# v.pulse
				chunk_num = ` tail -n1 /tmp/#{k.gsub("/", "_")}.log `.split[0].to_i
				v.fraction = chunk_num.to_f / chunk_counts[k].to_f 
				v.text = sprintf("%4.2f%", chunk_num.to_f / chunk_counts[k].to_f * 100)
				v.fraction = 1.0 if chunk_num == chunk_counts[k]
			elsif delete_in_progress[k] == false				
				v.fraction = 1.0
				v.text =  extract_lang_string("clean_done")
			end
		}
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		# puts delete_in_progress.to_s
		sleep_count += 1
		sleep 0.1
	end
	progress_bars.each { |k,v|
		if checkboxes[k].active?
			v.fraction = 1.0
			v.text = extract_lang_string("clean_done")
			system("rm /tmp/" + k.gsub("/", "_") + ".log")
		end
	}
	forw_button.sensitive = true
	back_button.sensitive = true
	return true
end