#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'vte'
require 'MfsDiskDrive.rb'
require 'MfsSinglePartition.rb'

def confirm_dialog
	dialog = Gtk::Dialog.new(
		"Installation bestätigen",
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES ],
		[ Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_NO
	dialog.window_position = Gtk::Window::POS_CENTER_ALWAYS
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup("<b>Die Installation von ChromiumOS löscht alle anderen Betriebssysteme auf diesem Computer! Wollen Sie das wirklich tun?</b>")
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		case resp
		when Gtk::Dialog::RESPONSE_YES
			dialog.destroy
			return true
		else
			dialog.destroy
			return false
		end
	}
end

def find_windows
	winpart = nil
	windrive = nil
	drives = Array.new
	devinfo = Hash.new
	Dir.entries("/sys/block").each { |l|
		if l =~ /[a-z]$/
			d = MfsDiskDrive.new(l, true) 
			drives.push(d) unless d.usb == true
		end
	}
	drives[0].partitions.each { |p|
		iswin, winvers = p.is_windows
		if iswin == true
			winpart = p
			windrive = drives[0]
		end
	}
	puts "Windows found on #{winpart} on #{windrive}" unless winpart.nil?
	return winpart, windrive, drives
end

def get_meta(winpart, windrive)
	parttable = Hash.new
	linecount = 0
	partnum = winpart.sub(windrive, "") 
	pstart = nil
	pend = nil 
	IO.popen("parted -sm /dev/#{windrive} unit B print") { |l|
		while l.gets 
			if linecount > 1 
				ptoks = $_.strip.split(":") 
				if ptoks[0] == partnum
					pstart = ptoks[1].sub("B", "")
					pend = ptoks[2].sub("B", "")
				end
			end
			linecount += 1
		end
	}
	puts pstart
	puts pend 
	return pstart, pend
end

def force_ntfs_resize(winpart, size, pgbar)
	pgbar.pulse
	pgbar.text = "Lösche Windows"
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	resrun = true
	vte = Vte::Terminal.new
	vte.signal_connect("child_exited") { resrun = false }
	vte.fork_command("/bin/bash", [ "/bin/bash", "run_ntfs_resize.sh", size.to_s, winpart ] )
	while resrun == true
		pgbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 1.0
	end
	# system("yes y | ntfsresize --no-progress-bar --force --size #{size.to_s} /dev/#{winpart}"
	pgbar.text = "Lösche Windows - abgeschlossen"
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
end

def backup_some_stuff(winpart, windrive)
	system("mkdir -p /tmp/winbackx") 
	winpart.mount("rw", "/tmp/winbackx", nil, nil, ["recover", "remove_hiberfile"] )
	system("parted -sm /dev/#{windrive.device} unit B print > /tmp/winbackx/cobicros.ptb") 
	system("dd if=/dev/#{windrive.device} of=/tmp/winbackx/cobicros.bin bs=1M count=1") 
	File.open("/tmp/winbackx/cobicros.txt", 'w') {|f| 
		f.write("Kontaktieren Sie Mattias Schlenker - ms@mattiasschlenker.de - +49 341 39290767 - bzgl. Datenwiederherstellung")
	}
	system("ls -lah /tmp/winbackx/cobicros.*") 
	system("cp -v /tmp/winbackx/cobicros.* /tmp/")
	winpart.umount 
end


def get_image
	imgpath = nil
	imgpath = "/tmp/cros.xz" if File.exists? "/tmp/cros.xz"
	imgpath = "cros.xz" if File.exists? "cros.xz"
	imgpath = "/lesslinux/isoloop/cros.xz" if File.exists? "/lesslinux/isoloop/cros.xz"
	imgpath = "/lesslinux/cdrom/cros.xz" if File.exists? "/lesslinux/cdrom/cros.xz"
	return imgpath 
end

def install_cros_image(offset, target, pgbar)
	imgpath = get_image 
	offsetblocks = offset / 512
	resrun = true
	pgbar.pulse
	pgbar.text = "Installiere ChromiumOS-Image - ca. 15 Minuten"
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	vte = Vte::Terminal.new
	vte.signal_connect("child_exited") { resrun = false }
	vte.fork_command("/bin/bash", [ "/bin/bash", "dd_chromium.sh", imgpath, target.device, offsetblocks.to_s ] )
	while resrun == true
		pgbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 1.0
	end
	# system("yes y | ntfsresize --no-progress-bar --force --size #{size.to_s} /dev/#{winpart}"
	system("dd if=/etc/syslinux/gptmbr.bin of=/dev/#{target.device}") 
	pgbar.text = "Installiere ChromiumOS-Image - abgeschlossen"
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
end

def write_partition_table(offset, target, winstart, winend)
	# first read the specified table:
	parttab = Array.new 
	linecount = 0
	lastend = 0 
	ptbfile = get_image.gsub(/\.xz$/, ".ptb")
	File.open(ptbfile).each { |line|
		if linecount > 1
			ltoks = line.strip.split(":")
			parttab[ltoks[0].to_i] = Array.new
			parttab[ltoks[0].to_i][0] = ltoks[1].sub("B", "").to_i
			parttab[ltoks[0].to_i][1] = ltoks[2].sub("B", "").to_i
			parttab[ltoks[0].to_i][2] = ltoks[5]
			parttab[ltoks[0].to_i][3] = ltoks[6]
		end
		linecount += 1
	}
	# remove the old partition table
	system("dd if=/dev/zero bs=1024 count=16 of=/dev/#{target.device}")
	# initialize the boot 
	system("parted -sm /dev/#{target.device} mktable gpt")
	
	parttab.each { |p|
		unless p.nil?
			pstart = offset + p[0]
			pend = offset + p[1]
			puts "Create partition - Start #{pstart.to_s} - End #{pend.to_s} - Name #{p[2]}"
			system("parted -sm /dev/#{target.device} unit B mkpart \"#{p[2]}\" ext2 #{pstart.to_s} #{pend.to_s}")
			lastend = pend if pend > lastend 
			# Flags
			# Names
		end
	}
	# Create partitions for LessLinux and bootloader
	llponeend = lastend + 1342177280
	llptwoend = lastend + 1342177280 + 1342177280
	llbootend = llptwoend + 268435456
	system("parted -sm /dev/#{target.device} unit B mkpart LLSYS-A ext2 #{(lastend + 1).to_s} #{llponeend.to_s}")
	system("parted -sm /dev/#{target.device} unit B mkpart LLSYS-B ext2 #{(llponeend + 1).to_s} #{llptwoend.to_s}")
	system("parted -sm /dev/#{target.device} unit B mkpart LLBOOT ext2 #{(llptwoend + 1).to_s} #{llbootend.to_s}")
	system("parted -sm /dev/#{target.device} unit B toggle 12 boot ")
	system("parted -sm /dev/#{target.device} unit B toggle 15 legacy_boot ")
	# Create windows partition:
	unless winend.nil?
		system("parted -sm /dev/#{target.device} unit B mkpart WINOLD ext2 #{winstart.to_s} #{winend.to_s}")
		system("parted -sm /dev/#{target.device} unit B toggle 16 hidden")
	end
	
end

def write_boot(target)
	system("mkfs.ext2 /dev/#{target.device}15")
	system("mkdir /tmp/crosboot")
	system("mount -t ext4 /dev/#{target.device}15 /tmp/crosboot")
	system("mkdir /tmp/crosboot/boot")
	if File.directory?("/lesslinux/isoloop/boot") 
		system("tar -C /lesslinux/isoloop/boot -cf - isolinux kernel | tar -C /tmp/crosboot/boot -xf -")
	else
		system("tar -C /lesslinux/cdrom/boot -cf - isolinux kernel | tar -C /tmp/crosboot/boot -xf -")
	end
	system("extlinux --install /tmp/crosboot/boot/isolinux") 
	# Copy kernel
	system("mkdir /tmp/croskern")
	system("mount -o ro /dev/#{target.device}12 /tmp/croskern")
	system("cp -v extlinux.conf /tmp/crosboot/boot/isolinux") 
	system("cp -v /tmp/croskern/syslinux/vmlinuz.A /tmp/crosboot/boot/kernel/cros.bzi") 
	system("cp -v /tmp/croskern/syslinux/vmlinuz.Z /tmp/crosboot/boot/kernel/crossafe.bzi") 
	system("cp -v /tmp/cobicros.* /tmp/crosboot/")
	system("umount /tmp/crosboot")
	system("umount /tmp/croskern")
end

def write_lesslinux(target, pgbar)
	sourcedev = nil
	if system("mountpoint -q /lesslinux/isoloop") 
		sourcedev = ` cat /proc/mounts | grep ' /lesslinux/isoloop ' `.strip.split[0] 
 	else
		sourcedev = ` cat /proc/mounts | grep ' /lesslinux/cdrom ' `.strip.split[0] 
	end
	resrun = true
	pgbar.pulse
	pgbar.text = "Installiere Aktualisierer - ca. 5 Minuten"
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	vte = Vte::Terminal.new
	vte.signal_connect("child_exited") { resrun = false }
	vte.fork_command("/bin/dd", [ "/bin/dd", "if=" + sourcedev,  "of=/dev/" + target.device + "14" ] )
	while resrun == true
		pgbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 1.0
	end
	pgbar.text = "Installiere Aktualisierer - abgeschlossen"
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	# system("dd if=#{sourcedev} of=/dev/#{target.device}14") 
end

def info_dialog(title, text) 
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.window_position = Gtk::Window::POS_CENTER_ALWAYS
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
end

# Error dialog
def error_dialog(title, text) 
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.window_position = Gtk::Window::POS_CENTER_ALWAYS
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
end

def fix_offset(oldoffset)
	return oldoffset if (oldoffset % 1048576  == 0)
	megblocks = oldoffset / 1048576 + 1
	return megblocks * 1048576
end

def check_image
	matches = false
	imgfile = get_image
	md5file = imgfile.gsub(/\.xz$/, ".md5")
	md5sum = ` md5sum #{imgfile} `.strip.split[0]
	File.open(md5file).each { |line|
		matches = true if line.strip.split[0] == md5sum
	}
	return matches
end

drives = nil 
winstart = nil
winend = nil
offset = 8388608
winpart, windrive, drives = find_windows 

######## The GUI

window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}
window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

window.border_width = 0
window.set_title("ChromiumOS-Installer")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.deletable = false
window.decorated = false
window.width_request = 600
window.height_request = 360

# box for progressbar
fixed = Gtk::Fixed.new
backs = Array.new
2.downto(0) { |n|
	backs[n] = Gtk::Image.new("step#{n.to_s}.png")
	fixed.put(backs[n], 0, 0) 
}
# box for progress bar:
pbox = Gtk::HBox.new(false, 5)
pgbar = Gtk::ProgressBar.new
pgbar.width_request = 430
pgbar.text = "Klicken Sie hier, um ChromiumOS jetzt zu installieren →"
pbox.pack_start(pgbar, false, true, 0)
go = Gtk::Button.new("ChromiumOS installieren")
go.width_request = 150
go.height_request = 32
pbox.pack_start(go, false, false, 0)
fixed.put(pbox, 10, 310)

if get_image.nil? 
	info_dialog("Image nicht gefunden", "Das ChromiumOS Image wurde nicht gefunden. Abbruch.")
	system("poweroff")
elsif drives.size < 1
	info_dialog("Keine internen Festplatten", "Es wurden keine internen IDE- oder SATA-Festplatten gefunden. Eine Installation auf USB- oder SCSI-Festplatten ist nicht vorgesehen.")
	system("poweroff")
elsif drives.size > 1
	info_dialog("Mehrere interne Festplatten", "Das Ziellaufwerk kann nicht bestimmt werden. Bitte trennen Sie die internen Festplatten und eSATA-Platten, auf denen ChromiumOS nicht installiert werden soll.")
	system("poweroff")
elsif drives[0].mounted
	info_dialog("Laufwerk im Zugriff", "Das Ziellaufwerk befindet sich im Zugriff. Installationsdateien müssen auf USB-Stick oder DVD abgelegt werden, nicht auf der internen Festplatte!")
	system("poweroff")
elsif system("parted -sm /dev/#{drives[0].device} print | head -n2 | grep gpt")
	info_dialog("GPT-Partitionstabelle", "Ihre Festplatte weist eine GPT-Partitionstabelle auf. Das bedeutet: ChromiumOS ist bereits installiert oder Sie versuchen, dieses Tool auf einem UEFI-System zu benutzen.")
	system("poweroff")
elsif check_image == false
	info_dialog("Image beschädigt", "Das ChromiumOS Image ist beschädigt. Eine Installation ist nicht möglich. Abbruch.")
	system("poweroff")
else
	go.sensitive = true
end

leave = Gtk::Button.new # ("minimieren")
leave.image = Gtk::Image.new("/usr/share/icons/Faenza/actions/16/system-shutdown.png")
leave.relief = Gtk::RELIEF_NONE
leave.has_tooltip = true
leave.tooltip_text = "Abbrechen und herunterfahren"
fixed.put(leave, 565, 4)
$stop_clone = false
$running = false
window.add fixed
go.signal_connect("clicked") {
	if confirm_dialog == true 
		offset = fix_offset(offset) 
		backs[0].hide_all
	$running = true
	go.sensitive = false
	unless winpart.nil? 
		winstart, winend = get_meta(winpart.device, windrive.device)
		# Calculate the new size:
		ntfsnewsize = winend.to_i - winstart.to_i - 8_589_934_592 
		force_ntfs_resize(winpart.device, ntfsnewsize, pgbar) unless $stop_clone == true
		# Put out info on offset:
		puts "calculating offset for ChromiumOS image (add one byte for start)"
		newwinend = winend.to_i - 7_516_192_768
		puts newwinend.to_s 
		offset = newwinend + 1  
		# backup some stuff before deleting anything
		backup_some_stuff(winpart, windrive) unless $stop_clone == true
	end
	pgbar.text = "Schreibe Partitionstabelle"
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	write_partition_table(offset, drives[0], winstart, newwinend) unless $stop_clone == true
	install_cros_image(offset, drives[0], pgbar) unless $stop_clone == true
	pgbar.text = "Schreibe Startdateien"
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	write_boot(drives[0]) unless $stop_clone == true
	write_lesslinux(drives[0], pgbar) unless $stop_clone == true
	unless $stop_clone == true
		backs[1].hide_all
		pgbar.text = "Die ChromiumOS-Installation ist abgeschlossen"
		pgbar.fraction = 1.0 
		info_dialog("Fertig!", "ChromiumOS wurde erfolgreich installiert!")
		system("reboot") 
	else
		backs[2].hide_all
		pgbar.fraction = 1.0 
		pgbar.text = "Die ChromiumOS-Installation wurde abgebrochen"
		info_dialog("Abbruch", "Die ChromiumOS-Installation wurde abgebrochen. Windows wird vermutlich nicht mehr starten (je nach Zeitpunkt des Abbruchs), Daten können aber in der Regel mit Werkzeugen wie PhotoRec gerettet werden.")
		system("shutdown-wrapper.sh")
	end
	exit 0
	end 
}
leave.signal_connect("clicked") {
	unless $running == true 
		system("shutdown-wrapper.sh")
	else
		system("killall -9 dd") 
		$stop_clone = true
	end
}
window.show_all
Gtk.main

########
