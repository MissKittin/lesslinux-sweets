#!/usr/bin/ruby

require "rexml/document"
require 'gtk2'

$password = nil
$dialog_success = false
$dummy = false

def read_devs
	xml_obj = nil
	if ARGV.size > 0 
		file = File.new( ARGV[0] )
		doc = REXML::Document.new(file)
		$dummy = true
	else	
		system("sudo /sbin/mdev -s")
		xmlstr = ""
		IO.popen("sudo /usr/sbin/lshw-static -xml") { |x|
			while x.gets
				xmlstr = xmlstr +$_
			end
		}
		doc = REXML::Document.new(xmlstr)
	end
	return doc
end

def get_mount_point(dev)
	return "/media/" + dev.gsub("/dev/", "").gsub("/", "_")
end

def error_dialog(message)
	dialog = Gtk::MessageDialog.new($main_application_window, 
			Gtk::Dialog::MODAL,
			Gtk::MessageDialog::ERROR,
			Gtk::MessageDialog::BUTTONS_CLOSE,
			message)
	dialog.run
	dialog.destroy
end

def pwdialog
	dialog = Gtk::Dialog.new(
		"Passwort",
		nil,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ],
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	question  = Gtk::Label.new("Diese Aktion erfordert ein Passwort!")
	question.height_request = 32
	entry_label = Gtk::Label.new("Passwort:")

	pass = Gtk::Entry.new
	pass.visibility = false
	pass.signal_connect('activate') {
		#puts pass.text
		dialog.response(Gtk::Dialog::RESPONSE_OK)
		# dialog.destroy
	}
	hbox = Gtk::HBox.new(false, 5)
	hbox.pack_start_defaults(entry_label)
	hbox.pack_start_defaults(pass)
	dialog.vbox.add(question)
	dialog.vbox.add(hbox)
	dialog.show_all
	success = false
	dialog.run do |response|
		 if response == Gtk::Dialog::RESPONSE_OK
			$password = pass.text
			$dialog_success = true
		end
		# return success, pass.text
		dialog.destroy
	end
end

def mount(partinfo, rw)
	pwdialog
	password = $password if $dialog_success == true
	$password = nil
	return false if $dialog_success == false
	$dialog_success = false
	puts "---"
	puts partinfo
	puts rw
	mount_opts = "-o noexec,nodev,nosuid,gid=1000,uid=1000"
	fstype = ""
	if partinfo[1] == "fat"
		fstype = "-t vfat"
		mount_opts = "-o noexec,nodev,nosuid,gid=1000,uid=1000"
	elsif partinfo[1] == "iso9660"	
		fstype = "-t iso9660"
		mount_opts = "-o noexec,nodev,nosuid,gid=1000,uid=1000"
	elsif partinfo[1] == "ntfs"
		fstype = "-t ntfs"
		mount_opts = "-o noexec,nodev,nosuid,gid=1000,uid=1000"
	else
		mount_opts = "-o noexec,nodev,nosuid"
	end
	unless rw == true
		mount_opts = mount_opts + ",ro"
	end
	mountdir = get_mount_point(partinfo[0])
	mountdir = partinfo[3] unless partinfo[3].nil?
	mkdir = "echo '" + password + "' | sudo -S /bin/mkdir -p " + mountdir
	mount = "echo '" + password + "' | sudo -S /bin/mount "  + fstype + " " + mount_opts + " " + partinfo[0] + " " + mountdir
	if $dummy == true
		puts mkdir
		puts mount
		puts "---"
		return true
	else
		puts "---"
		system(mkdir)
		if system(mount) 
			return true
		else
			return false
		end
	end
	return true
end

def umount(partinfo)
	puts "---"
	puts partinfo
	umount = "sudo /bin/umount " + partinfo[0]
	# eject = "sudo eject " + partinfo[0]  if partinfo[0] =~ /^\/dev\/sr/ 
	if $dummy == true
		puts umount
		puts "---"
		return true
	else	
		umount_success = system(umount)
		# system("sudo /sbin/eject " + partinfo[0]) if partinfo[0] =~ /^\/dev\/sr/
		puts "---"
		return true if umount_success == true
	end
	return false
end

def scan_parts (doc)
	alldisks = []
	doc.elements.each("//node[@class='storage']") { |x|
		businfo = x.elements["businfo"].text.to_s
		x.elements.each("node[@class='disk']") { |element|
			parts = []
			product = ""
			size = 0
			unit = ""
			cdrom = false
			begin
				product = element.elements["product"].text.to_s
			rescue
				product = element.elements["description"].text.to_s
			end
			begin
				size = element.elements["size"].text.to_i
				unit = element.elements["size"].attributes["units"]
			rescue
			end
			# puts element.attributes["handle"]  + " " + product + " " + businfo + " " + size.to_s + " " + unit
			if element.attributes["id"] =~ /^cdrom/ 
				#	puts "  " + element.elements["logicalname"].text
				cdrom = true
				mount_point = nil
				log_name = []
				element.elements.each("logicalname") { |l| log_name.push(l.text) }
				state = "clear"
				if log_name.size > 1
					mount_point = log_name[1] 
					state = "mounted"
				end
				parts.push( [ element.elements["logicalname"].text, "iso9660", state, mount_point, false ] )
			end
			element.elements.each("node[@class='volume']") { |n|
				state = ""
				mount_options = []
				rw = false
				begin
					state = n.elements["configuration/setting[@id='state']"].attributes["value"].to_s
					mount_options = n.elements["configuration/setting[@id='mount.options']"].
						attributes["value"].to_s.split(",")
					mount_options.each { |m| rw = true if m == "rw" }
				rescue
				end
				fstype = nil
				begin
					fstype = n.elements["configuration/setting[@id='filesystem']"].attributes["value"].strip
				rescue
					fstype = "???"
				end
				is_extended = false
				begin
					is_extended = true if n.elements["capabilities/capability[@id='partitioned:extended']"].text.strip == "Extended partition"
				rescue
				end
				unless fstype == "swap" || is_extended == true
					# puts "  " + n.attributes["id"] + " " + n.elements["logicalname"].text + " " + 
					#	n.elements["configuration/setting[@id='filesystem']"].attributes["value"] + " " + state
					mount_point = nil
					log_name = []
					n.elements.each("logicalname") { |l| log_name.push(l.text) }
					mount_point = log_name[1] if log_name.size > 1
					parts.push( [ n.elements["logicalname"].text,
					fstype.to_s,
					state, mount_point, rw ] )
				end
				if is_extended == true
					n.elements.each("node[@class='volume']") { |m|
						begin
							istate = ""
							imount_options = []
							irw = false
							begin
								istate = m.elements["configuration/setting[@id='state']"].attributes["value"].to_s
								imount_options = m.elements["configuration/setting[@id='mount.options']"].
									attributes["value"].to_s.split(",")
								imount_options.each { |o| irw = true if o == "rw" }
							rescue
							end
							ifstype = nil
							begin
								ifstype = m.elements["configuration/setting[@id='filesystem']"].attributes["value"].strip
							rescue
								ifstype = "???"
							end
							unless fstype == "swap"
								mount_point = nil
								log_name = []
								m.elements.each("logicalname") { |l| log_name.push(l.text) }
								mount_point = log_name[1] if log_name.size > 1
								parts.push( [ m.elements["logicalname"].text,
								ifstype.to_s,
								istate, mount_point, rw ] )
							end
						rescue
						end
					}
				end
				
			}
			alldisks.push( [  businfo, product, size, unit, cdrom, parts ] )
		}
		x.elements.each("node[@class='volume']") { |element|
			if element.elements["logicalname"].text =~ /^\/dev\/sd/ && businfo =~ /^usb/
				parts = []
				product = ""
				size = 0
				unit = ""
				cdrom = false
				istate = ""
				imount_options = []
				irw = false
				begin
					istate = element.elements["configuration/setting[@id='state']"].attributes["value"].to_s
					imount_options = element.elements["configuration/setting[@id='mount.options']"].
					attributes["value"].to_s.split(",")
					imount_options.each { |o| irw = true if o == "rw" }
				rescue
				end
				ifstype = nil
				begin
					ifstype = element.elements["configuration/setting[@id='filesystem']"].attributes["value"].strip
				rescue
					ifstype = "???"
				end
				# udrive = UsbDrive.new(element.elements["logicalname"].text)
				begin
					product = x.elements["vendor"].text + " " + x.elements["product"].text
				#	udrive.product = x.elements["product"].text
				rescue
				end
				mount_point = nil
				log_name = []
				size = element.elements["size"].text.to_i
				element.elements.each("logicalname") { |l| log_name.push(l.text) }
				mount_point = log_name[1] if log_name.size > 1
				parts.push( [ element.elements["logicalname"].text, ifstype.to_s, istate, mount_point, irw ] )
			end
			alldisks.push( [  businfo, product, size, unit, cdrom, parts ] )
			#all_drives[element.elements["logicalname"].text] = udrive unless 
			#all_drives.has_key?( element.elements["logicalname"].text )
		}
	}
	return alldisks
end

def build_panel(alldisks)
	outer_vbox = Gtk::VBox.new(false, 1)
	fat_font = Pango::FontDescription.new("Sans Bold")
	alldisks.each { |d|
		text = d[1]
		if d[0] =~ /^usb/ 
			text = "USB-Laufwerk"
		end
		if d[2] > 0
			if d[2] > 6000000000
				text = text  + " (" + ( d[2] / 1024 / 1024 / 1024).to_i.to_s + " Gigabyte)"
			elsif d[2] > 6000000
				text = text  + " (" + ( d[2] / 1024 / 1024).to_i.to_s + " Megabyte)"
			else
				text = text + " (" + d[2].to_s + " Byte)"
			end
		end
		l = Gtk::Label.new(text)
		l.modify_font(fat_font)
		icon_theme = Gtk::IconTheme.default
		if d[4] == true
			pixbuf = icon_theme.load_icon("gnome-dev-dvd", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
		elsif d[0] =~ /^usb/
			pixbuf = icon_theme.load_icon("gnome-dev-media-sdmmc", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
		else
			pixbuf = icon_theme.load_icon("gnome-dev-harddisk", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
		end
		inner_hbox = Gtk::HBox.new(false, 1)
		inner_vbox = Gtk::VBox.new(false, 1)
		img = Gtk::Image.new(pixbuf)
		img.set_alignment(0,0.5)
		l.set_alignment(0,0.5)
		inner_hbox.pack_start(img, false, false, 0)
		inner_vbox.pack_start(l, false, false, 0)
		d[5].each { |p|
			dev_desc = p[0]
			if p[0] =~ /^\/dev\/sd[a-z]$/
				dev_desc = "USB-Stick"
			elsif p[0] =~ /^\/dev\/sd[a-z][0-9]$/
				part_num = p[0].split(/\/dev\/sd[a-z]/)
				dev_desc = "Partition " + part_num[1].to_s
			elsif p[0] =~ /^\/dev\/sr[0-9]$/
				dev_desc = "CD/DVD"
			end
			writeable = Gtk::CheckButton.new("schreibbar?")
			mount_button = Gtk::Button.new(dev_desc + " (" + p[1] + ") einbinden" )
			mount_button.width_request = 200
			mount_button.height_request = 32
			show_button = Gtk::Button.new("Inhalt anzeigen")
			show_button.width_request = 120
			show_button.height_request = 32
			writeable.active = p[4]
			if d[4] == true
				writeable.sensitive = false
			end
			unless p[2] == "mounted"
				show_button.sensitive = false
			else
				writeable.sensitive = false
				mount_button.label = dev_desc + " (" + p[1] + ") freigeben"
			end
			show_button.signal_connect( "clicked" ) { |w|
				if p[3].nil?
					system("Thunar " + get_mount_point(p[0]))
				else
					system("Thunar " + p[3])
				end
			}
			mount_button.signal_connect( "clicked" ) {|w|
				unless p[2] == "mounted"
					mount_res = mount(p, writeable.active?)
					if mount_res == true
						writeable.sensitive = false
						show_button.sensitive = true
						mount_button.label = dev_desc + " (" + p[1] + ") freigeben"
						p[2] = "mounted"
						if p[3].nil?
							system("Thunar " + get_mount_point(p[0]))
						else
							system("Thunar " + p[3])
						end
					else
						error_dialog("Zugriff fehlgeschlagen oder abgebrochen.")
					end
				else
					umount_res = umount(p)
					if umount_res == true
						writeable.sensitive = true unless d[4] == true
						show_button.sensitive = false
						mount_button.label = dev_desc + " (" + p[1] + ") einbinden"
						p[2] = "clean"
					else
						error_dialog("Freigeben fehlgeschlagen. Stellen Sie sicher, dass kein Prozess mehr auf das Laufwerk zugreift.")
					end
				end
			}
			button_box = Gtk::HBox.new(false, 1)
			button_box.pack_start(writeable, false, false, 2)
			button_box.pack_start(mount_button, false, false, 2)
			button_box.pack_start(show_button, false, false, 2)
			inner_vbox.pack_start(button_box, false, false, 2)
		}
		inner_hbox.pack_start(inner_vbox, false, false, 5)
		outer_vbox.pack_start(inner_hbox, false, false, 5)
		sep = Gtk::HSeparator.new
		outer_vbox.pack_start(sep)
	}
	return outer_vbox
end

doc = read_devs
alldisks = scan_parts(doc)
outer_vbox = build_panel(alldisks)

window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
window.set_title  "Laufwerke"
window.border_width = 10
window.set_size_request(540, 400)
# window.set_size_request(240, 240)
window.signal_connect('delete_event') { 
	# cleanup
	Gtk.main_quit 
}

scroll_pane = Gtk::ScrolledWindow.new
scroll_pane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

reread = Gtk::Button.new("Neu einlesen")
reread.height_request = 32
layout_box = Gtk::VBox.new(false, 0)
scroll_pane.add_with_viewport(outer_vbox)
layout_box.pack_start(scroll_pane, true, true, 0)
# layout_box.pack_start(reread, false, false, 0)
window.add(layout_box)
window.show_all
Gtk.main



