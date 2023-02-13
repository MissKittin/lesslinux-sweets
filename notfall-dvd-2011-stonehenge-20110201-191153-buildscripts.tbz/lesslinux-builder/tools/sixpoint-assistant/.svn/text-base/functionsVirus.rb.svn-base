#!/usr/bin/ruby
# encoding: utf-8

def get_virus_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 5)
	header = Gtk::Label.new(extract_lang_string("virus_check_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("virus_nonet"))
	desc.wrap = true
	desc.width_request = 570
	goon = Gtk::Label.new(extract_lang_string("virus_net_continue"))
	goon.wrap = true
	netcombo = Gtk::ComboBoxEntry.new
	netkey = Gtk::Entry.new
	netkey.visibility = false
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	ssid_box = Gtk::HBox.new(true, 0)
	ssid_box.pack_start(Gtk::Label.new(extract_lang_string("virus_essid")), true, true, 0)
	ssid_box.pack_start(netcombo, true, true, 0)
	outer_box.pack_start(ssid_box, true, true, 0)
	key_box = Gtk::HBox.new(true, 0)
	key_box.pack_start(Gtk::Label.new(extract_lang_string("virus_key")), true, true, 0)
	key_box.pack_start(netkey, true, true, 0)
	outer_box.pack_start(key_box, true, true, 0)
	skip_wlan = Gtk::CheckButton.new(extract_lang_string("virus_nosigupdate"))
	outer_box.pack_start(skip_wlan, true, true, 0)
	return outer_box, netcombo, netkey, skip_wlan
end

def get_virus_sig_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("virus_sigupdate"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	## desc = Gtk::Label.new("Heruntergeladene Dateien: 23")
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 570
	scan_vte = Vte::Terminal.new
	scan_vte.set_size(80, 14)
	scan_vte.set_colors(Gdk::Color.new(0,0,0), Gdk::Color.new(65535, 65535, 65535), [])
	scan_exp = Gtk::Expander.new(extract_lang_string("details"))
	stop_button = Gtk::Button.new(extract_lang_string("cancel"))
	stop_button.signal_connect("clicked") {
		stop_button.sensitive = false
		system("killall -9 freshclam")
		system("killall -9 kav4ws-keepup2date")
		stop_button.sensitive = true
	}
	outer_box.pack_start(header, true, false, 0)
	## outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(pgbar, true, true, 0)
	scan_exp.add(scan_vte)
	outer_box.pack_start(scan_exp, true, true, 0)
	outer_box.pack_start(stop_button, true, true, 0)
	return outer_box, scan_vte, pgbar
end

def get_virus_scan_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("virus_search_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	### desc = Gtk::Label.new("Gefundene verdächtige Dateien: 42")
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 570
	scan_vte = Vte::Terminal.new
	scan_vte.set_size(80, 14)
	scan_vte.set_colors(Gdk::Color.new(0,0,0), Gdk::Color.new(65535, 65535, 65535), [])
	scan_exp = Gtk::Expander.new(extract_lang_string("details"))
	stop_button = Gtk::Button.new(extract_lang_string("cancel"))
	stop_button.signal_connect("clicked") {
		system("killall -9 clamscan")
		system("killall -9 kav4ws-kavscanner")
	}
	outer_box.pack_start(header, true, false, 0)
	### outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(pgbar, true, true, 0)
	scan_exp.add(scan_vte)
	outer_box.pack_start(scan_exp, true, true, 0)
	outer_box.pack_start(stop_button, true, true, 0)
	return outer_box, scan_vte, pgbar
end

def get_virus_options_screen(scanner)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("virus_opts_head"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	sdesc = Gtk::Label.new(extract_lang_string("virus_opts_arch"))
	sdesc.wrap = true
	sdesc.width_request = 570
	schck = Gtk::RadioButton.new(extract_lang_string("virus_opts_arch_yes"))
	schno = Gtk::RadioButton.new(schck, extract_lang_string("virus_opts_arch_no"))
	schno.active = true
	ddesc = Gtk::Label.new(extract_lang_string("virus_opts_found"))
	ddesc.wrap = true
	ddesc.width_request = 570
	dchno = Gtk::RadioButton.new(extract_lang_string("virus_opts_found_show"))
	dchc2 = Gtk::RadioButton.new(dchno, extract_lang_string("virus_opts_found_del"))
	dchck = Gtk::RadioButton.new(dchno, extract_lang_string("virus_opts_found_lax"))
	dchc2.active = true
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(sdesc, true, true, 0)
	outer_box.pack_start(schck, true, true, 0)
	outer_box.pack_start(schno, true, true, 0)
	outer_box.pack_start(ddesc, true, true, 0)
	outer_box.pack_start(dchc2, true, true, 0)
	if scanner == "kaspersky"
		outer_box.pack_start(dchck, true, true, 0)
	end
	# outer_box.pack_start(dchc2, true, true, 0)
	outer_box.pack_start(dchno, true, true, 0)
	return outer_box, schck, dchck, dchc2 
end

def get_virus_results_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new( extract_lang_string("virus_scan_cancel") )
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	act = Gtk::Label.new(extract_lang_string("virus_cancel_desc") )
	act.wrap = true
	act.width_request = 570
	outer_box.pack_start(header, true, false, 0)
	# outer_box.pack_start(desc1, true, true, 0)
	outer_box.pack_start(act, true, true, 0)
	return outer_box
end

def get_virus_repair_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 0)
	header = Gtk::Label.new("Reparatur infizierter Dateien")
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new("Reparierte Dateien: 42")
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 500
	scan_vte = Vte::Terminal.new
	scan_exp = Gtk::Expander.new("Details anzeigen")
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(pgbar, true, true, 0)
	scan_exp.add(scan_vte)
	outer_box.pack_start(scan_exp, true, true, 0)
	return outer_box, scan_vte
end

def get_virus_finish_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 0)
	header = Gtk::Label.new("Reparatur abgeschlossen")
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new("Die Reparatur infizierter Dateien ist abgeschlossen. Klicken Sie auf \"Weiter\", um Ihren Computer neu zu starten.")
	desc.wrap = true
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	return outer_box
end

def run_virus_signature_update(vte, progbar, buttons, scanner, parent)
	buttons.each { |b| b.sensitive = false }
	progbar.text = extract_lang_string("virus_sigup_running") 
	update_in_progress = true
	vte.signal_connect("child-exited") { update_in_progress = false }
	if scanner == "kaspersky"
		# vte.fork_command("/opt/kaspersky/kav4ws/bin/kav4ws-keepup2date", [ "/opt/kaspersky/kav4ws/bin/kav4ws-keepup2date" ]) 
		vte.fork_command("/bin/bash", [ "/bin/bash", "/opt/computerbild/rescuetool/keepup2date-wrapper.sh" ] )
	else
		# vte.fork_command("/opt/bin/freshclam", [ "/opt/bin/freshclam" ] )
		vte.fork_command("/bin/bash", [ "/bin/bash", "/opt/computerbild/rescuetool/freshclam-wrapper.sh" ] )
	end
	vte.signal_connect("child-exited") { update_in_progress = false }
	while update_in_progress == true
		sleep 0.1
		progbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end 
	retval = 99
	progbar.fraction = 1.0
	progbar.text =     extract_lang_string("virus_sigup_done") 
	retval = ` cat /var/run/lesslinux/last_clamav_update `.to_i if scanner == "clamav"
	retval = ` cat /var/run/lesslinux/last_kaspersky_update `.to_i if scanner == "kaspersky"
	if retval == 0 && scanner == "kaspersky"
		generic_dialog(parent, extract_lang_string("virus_sigup_noneed") )
	elsif retval == 1 && scanner == "kaspersky"
		puts "Alles super!"
	elsif retval == 0
		puts "Alles super!"
	else
		generic_dialog(parent, extract_lang_string("virus_sigup_failed") )
	end
	buttons.each { |b| b.sensitive = true }
end

def run_virusscan(vte, progbar, buttons, scanner, archives, disinfect, kill) 
	buttons.each { |b| b.sensitive = false }
	# Mount all drives!
	drives = AllDrives.new(false, false, false)
	scan_parts = Array.new
	progbar.text =  extract_lang_string("virus_scan_running") 
	drives.drive_list.each { |k,v|
		v.partitions.each { |n,p|
			if (p.fs =~ /^ntfs/ || p.fs =~ /^fat/) && p.mounted == false 
				mountpoint = p.device.gsub("/dev/", "/virusscan/")
				system("mkdir -p " + mountpoint)
				if disinfect.active? == true || kill.active? == true
					system("mount -t ntfs-3g -o rw,noatime " + p.device + " " + mountpoint) if p.fs =~ /^ntfs/
					system("mount -t vfat -o rw,noatime " + p.device + " " + mountpoint) if p.fs =~ /^fat/
				else
					system("mount -t ntfs-3g -o ro " + p.device + " " + mountpoint) if p.fs =~ /^ntfs/
					system("mount -t vfat -o ro " + p.device + " " + mountpoint) if p.fs =~ /^fat/
				end
				scan_parts.push(p.device)
			end	
		}
	}
	scan_in_progress = true
	vte.signal_connect("child-exited") { scan_in_progress = false }
	if scanner == "kaspersky"
		if disinfect.active? == true
			delaction = "-i1" 
			# conffile = "-c/opt/computerbild/rescuetool/kav4ws.conf"
			# conffile = "-c/etc/opt/kaspersky/kav4ws.conf"
		elsif kill.active? == true	
			delaction = "-i2" 
		else
			delaction = "-i0"
			# conffile = "-c/etc/opt/kaspersky/kav4ws.conf"
		end
		system("rm /tmp/kaspersky.log /tmp/kaspersky_infected.log /tmp/kaspersky_suspicious.log /tmp/kaspersky_warning.log")
		params = [ "/opt/kaspersky/kav4ws/bin/kav4ws-kavscanner", "-R", "-s", "-j3", "-ea", "-es", 
			delaction, "-o/tmp/kaspersky.log", "-pi/tmp/kaspersky_infected.log", "-pw/tmp/kaspersky_warning.log",
			"-ps/tmp/kaspersky_suspicious.log", "/virusscan" ]
		params = [ "/opt/kaspersky/kav4ws/bin/kav4ws-kavscanner", "-R", "-s", "-j3", "-eA", "-eS",
			delaction, "-o/tmp/kaspersky.log", "-pi/tmp/kaspersky_infected.log",  "-pw/tmp/kaspersky_warning.log",
			"-ps/tmp/kaspersky_suspicious.log", "/virusscan" ] if archives.active? == true
		vte.fork_command("/opt/kaspersky/kav4ws/bin/kav4ws-kavscanner", params )
	else
		if archives.active? == true
			scan_archive = "--scan-archive=yes"
		else
			scan_archive = "--scan-archive=no"
		end
		if kill.active? == true
			delaction = "--remove=yes"
		else
			delaction = "--remove=no"
		end
		system("rm /tmp/clamscan.log")
		params = [ "/opt/bin/clamscan", delaction , scan_archive, 
			"--scan-html=no", "--scan-mail=no", "--phishing-sigs=no", "--phishing-scan-urls=no", "--log=/tmp/clamscan.log", "-r", "/virusscan" ]
		vte.fork_command("/opt/bin/clamscan", params )
		# system(params.join(" "))
		puts  params.join(" ")
	end	
	while scan_in_progress == true
		sleep 0.1
		progbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end 
	scan_parts.each { |p| system("umount " + p) }
	progbar.text = extract_lang_string("virus_scan_done") 
	progbar.fraction = 1.0
	buttons.each { |b| b.sensitive = true }
end

def get_virus_summary_screen
	outer_box = Gtk::VBox.new(false, 10)
	header = Gtk::Label.new(extract_lang_string("virus_summ_head") )
	desc = Gtk::Label.new(extract_lang_string("virus_summ_desc"))
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
	# outer_box.pack_start(scroll_pane, true, false, 0)
	return outer_box, drivebox, desc
end

def get_virus_list_screen
	outer_box = Gtk::VBox.new(false, 10)
	header = Gtk::Label.new(extract_lang_string("virus_summ_head"))
	desc = Gtk::Label.new(extract_lang_string("virus_summ_infect"))
	desc.wrap = true
	desc.width_request = 570
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	textview = Gtk::TextView.new
	textview.buffer.text =      extract_lang_string("virus_summ_empty")
	textview.set_wrap_mode(Gtk::TextTag::WRAP_NONE)
	scrolled_win = Gtk::ScrolledWindow.new
	scrolled_win.border_width = 5
	scrolled_win.add(textview)
	scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
	# scrolled_win.add(textview)
	scrolled_win.set_size_request(570, 200)
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(scrolled_win, true, false, 0)
	return outer_box, textview
end

def virus_human_stats(scanner)
	checked = 0
	infected = 0
	repaired = 0
	curefailed = 0
	if scanner == "kaspersky"
		summary =  ` tail -n1 /tmp/kaspersky.log `
		ltoks = summary.strip.split
		ltoks.each { |t|
			ttoks = t.strip.split("=")
			if ttoks[0] == "Files"
				checked = ttoks[1].to_i
			elsif ttoks[0] == "Infected"
				infected = ttoks[1].to_i
			elsif ttoks[0] == "Cured"
				repaired = ttoks[1].to_i
			elsif ttoks[0] == "CureFailed"
				curefailed = ttoks[1].to_i
			end
		}
		
	else	
		repaired=` grep ': Removed.' /tmp/clamscan.log | wc -l `.strip.to_i
		infected=` grep '^Infected files: ' /tmp/clamscan.log | awk '{print $3}' `.strip.to_i
		checked=` grep '^Scanned files: ' /tmp/clamscan.log | awk '{print $3}' `.strip.to_i
	end
	return extract_lang_string("virus_summ_desc").gsub("%M%",  checked.to_s).
		gsub("%N%", infected.to_s).gsub("%O%",   repaired.to_s).gsub("%P%", curefailed.to_s)
end

def read_scan_summary(scanner)
	if scanner == "kaspersky"
		summary = ` tail -n1 /tmp/kaspersky.log `
		return false unless summary =~ /Scan summary/
	else
		return false unless system("grep -q -E '^-+ SCAN SUMMARY -+' /tmp/clamscan.log")
	end
	return true
end