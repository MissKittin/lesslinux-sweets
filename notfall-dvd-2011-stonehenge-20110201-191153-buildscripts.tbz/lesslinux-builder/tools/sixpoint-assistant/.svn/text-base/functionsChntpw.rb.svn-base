#!/usr/bin/ruby
# encoding: utf-8

def get_chntpw_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	radio = Array.new
	header = Gtk::Label.new(extract_lang_string("select_three"))
	desc = Gtk::Label.new(extract_lang_string("chntpw_win_select"))
	desc.wrap = true
	desc.width_request = 570
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	drive_combo = Gtk::ComboBox.new
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(drive_combo, true, true, 0)
	return outer_box, drive_combo
end

def get_chntpw_user_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("chntpw_user_head"))
	desc = Gtk::Label.new(extract_lang_string("chntpw_user_select"))
	desc.wrap = true
	desc.width_request = 570
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	user_combo = Gtk::ComboBox.new
	user_combo.append_text("Administrator")	
	user_combo.active = 0
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	outer_box.pack_start(user_combo, true, true, 0)
	return outer_box, user_combo
end

def find_win_sysparts(drives)
	sysparts = Hash.new
	drives.drive_list.keys.sort.each { |k|
		v = drives.drive_list[k]
		drives.drive_list[k].partitions.each { |l,p|
			if p.fs == "ntfs" || p.fs.downcase =~ /^fat/
				puts p.id
				system("umount " + p.id)
				system("mkdir -p /var/run/lesslinux/" + $$.to_s + "/testmount") unless 
					File.exist?("/var/run/lesslinux/" + $$.to_s + "/testmount")
				if p.fs == "ntfs"
					system("mount -t ntfs-3g -o ro " +  p.id + " /var/run/lesslinux/" + $$.to_s + "/testmount")
				else
					system("mount -t vfat -o ro " +  p.id + " /var/run/lesslinux/" + $$.to_s + "/testmount")
				end
				system("df -h /var/run/lesslinux/" + $$.to_s + "/testmount")
				if File.exist?("/var/run/lesslinux/" + $$.to_s + "/testmount/Windows/System32/config/SAM") ||
					File.exist?("/var/run/lesslinux/" + $$.to_s + "/testmount/WINDOWS/system32/config/SAM")
					sysparts[p.id] = v.vendor + " " + v.model + " Partition " + l.to_s + ", " + human_readable_bytes(p.size)
					unless p.fslabel.to_s == ""
						sysparts[p.id] = sysparts[p.id] + " Label: " + p.fslabel
					end
					puts sysparts[p.id]
				end
				system("umount /var/run/lesslinux/" + $$.to_s + "/testmount")
			end
		}
	}
	return sysparts
end

def fill_chntpw_combo(chntpw_combo, sysparts) 
	devices = Array.new
	100.downto(0) { |i| 
		begin
			chntpw_combo.remove_text(i) 
		rescue
		end
	}
	sysparts.each { |k,v|
		chntpw_combo.append_text(v)
		devices.push(k)
	}
	if sysparts.size < 1
		chntpw_combo.append_text(extract_lang_string("chntpw_not_found"))
		chntpw_combo.sensitive = false
	end
	chntpw_combo.active = 0
	return devices
	
end

def get_nt_users(partition, drives)
	drives.drive_list.each { |k,d|
		d.partitions.each { |l,p|
			if p.id == partition
				if p.fs == "ntfs"
					system("mount -t ntfs-3g -o ro " +  partition + " /var/run/lesslinux/" + $$.to_s + "/testmount")	
				else
					system("mount -t vfat -o ro " +  partition + " /var/run/lesslinux/" + $$.to_s + "/testmount")
				end
			end
		}
	}
	samusers = Array.new
	samfile = ""
	[ "/var/run/lesslinux/" + $$.to_s + "/testmount/Windows/System32/config/SAM", 
	  "/var/run/lesslinux/" + $$.to_s + "/testmount/WINDOWS/system32/config/SAM" ].each { |s|
		samfile = s if File.exist?(s)
	}
	IO.popen("chntpw -l " + samfile + " | iconv -c -f ISO-8859-15 -t UTF-8 ") { |io|
		accstart = false
		while io.gets
			toks = $_.split("|")
			if accstart == true
				$stderr.puts "Hex ID:" + toks[1].to_s.strip
				$stderr.puts "Username: " + toks[2].to_s.strip.gsub(/[^[:print:]]/, '_')
				# samusers.push( [ toks[1].to_s.strip, toks[2].to_s.strip.gsub(/[^[:print:]]/, '_') ] )
				samusers.push( [ toks[1].to_s.strip, toks[2].to_s.strip ] )
			end
			accstart = true if $_ =~ / ^|\sRID/
		end
	}
	system("umount /var/run/lesslinux/" + $$.to_s + "/testmount")
	return samusers
end

def fill_ntuser_combo(user_combo, ntusers)
	100.downto(0) { |i| 
		begin
			user_combo.remove_text(i) 
		rescue
		end
	}
	ntusers.each { |i|
		user_combo.append_text(i[1]) 
	}
	user_combo.active = 0
end

def get_chntpw_finish_screen(fwdbutton, simulate)
	outer_box = Gtk::VBox.new(false, 15)
	header = Gtk::Label.new(extract_lang_string("chntpw_success_title"))
	fat_font = Pango::FontDescription.new("Sans Bold")
	header.modify_font(fat_font)
	desc = Gtk::Label.new(extract_lang_string("chntpw_success_long"))
	desc.wrap = true
	desc.width_request = 570 
	outer_box.pack_start(header, true, false, 0)
	outer_box.pack_start(desc, true, true, 0)
	return outer_box
end

def run_chntpw(partition, user, drives)
	puts partition
	puts user.join(", ")
	drives.drive_list.each { |k,d|
		d.partitions.each { |l,p|
			if p.id == partition
				if p.fs == "ntfs"
					system("mount -t ntfs-3g -o rw,noatime " +  partition + " /var/run/lesslinux/" + $$.to_s + "/testmount")	
				else
					system("mount -t vfat -o rw,noatime " +  partition + " /var/run/lesslinux/" + $$.to_s + "/testmount")
				end
			end
		}
	}
	samfile = ""
	[ "/var/run/lesslinux/" + $$.to_s + "/testmount/Windows/System32/config/SAM", 
	  "/var/run/lesslinux/" + $$.to_s + "/testmount/WINDOWS/system32/config/SAM" ].each { |s|
		samfile = s if File.exist?(s)
	}
	exstring = "printf \"1\\ny\\n\" | chntpw -u 0x" + user[0] + " " + samfile
	puts exstring
	retval = system(exstring)
	system("umount /var/run/lesslinux/" + $$.to_s + "/testmount")
	puts retval.to_s
	return retval
end