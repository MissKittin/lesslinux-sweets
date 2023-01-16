#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'vte'
require 'MfsDiskDrive.rb'
require 'MfsSinglePartition.rb'

# require 'MfsTranslator.rb'

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

def reread_targets(combobox, windrive)
	100.downto(0) { |n| 
		begin
			combobox.remove_text(n)
		rescue
		end
	}
	tgtlist = Array.new
	if windrive.nil?
		combobox.append_text("Kein geeignetes Ziellaufwerk gefunden") if tgtlist.size < 1 
		combobox.active = 0
		return tgtlist
	end
	drives = Array.new
	devinfo = Hash.new
	Dir.entries("/sys/block").each { |l|
		drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/ 
		drives.push(MfsDiskDrive.new(l, true)) if l =~ /md[0-9]$/ 	
	}
	drives.each { |d|
		devinfo[d.device] = "#{d.vendor} - #{d.model}"
		devinfo[d.device] = devinfo[d.device] + " - USB" if d.usb == true 
	}
	o, e = calculate_size(windrive)
	puts "Occupied space: #{o.to_s} bytes"
	puts "Estimated free: #{e.to_s} bytes"
	potential_targets = search_targets(drives, windrive, e)
	potential_targets.each { |t|
		puts "Potential target: #{t.device}"
		tgtlist.push(t)
		combobox.append_text("Ziellaufwerk: #{devinfo[t.parent]} - #{t.device} #{t.human_size} - #{t.fs}")
	}
	combobox.append_text("Kein geeignetes Ziellaufwerk gefunden") if tgtlist.size < 1 
	combobox.active = 0
	return tgtlist
end

# Find all drives containing an XP installation
def find_xp_drives(drives)
	winresultset = Array.new
	xpresultset = Array.new
	drives.each { |d|
		winparts = Array.new 
		xpparts = Array.new
		d.partitions.each { |p|
			iswin, winvers = p.is_windows
			if iswin == true && winvers =~ /XP$/
				xpparts.push( p )
			elsif iswin == true
				winparts.push( p )
			end
		}
		if xpparts.size > 0
			xpresultset.push( [ d, xpparts ] )  
		end
		if winparts.size > 0
			winresultset.push( [ d, winparts ] )  
		end
	}
	return xpresultset, winresultset 
end

# Ask which drive to use if more than one is found
def select_drive(windrives)
	return windrives[0] 
end

# Check if system partition on drive can be mounted
def mount_check(drive)
	return false if drive.nil?
	# drive[0] contains the drive
	# drive[1] contains array of partitions
	hibernated = false
	drive[1].each { |p|
		return true if p.hibernated? 
	}
	return false
end

# Calculate expected size of image
def calculate_size(drive)
	# drive[0] contains the drive
	# drive[1] contains array of partitions
	free = 0
	drive[1].each { |p|
		if p.fs =~ /fat/i || p.fs =~ /ntfs/i
			free += p.free_space
		end
	}
	# estimated size is occupied space + 5% + 100MB + 1024M swap
	puts "Drive size is:     " + drive[0].size.to_s
	puts "Free space is:     " + free.to_s
	occupied = drive[0].size - free 
	estimated = occupied * 105 / 100 + 104857600 + 1073741824
	puts "Estimated minfree: " + estimated.to_s
	return occupied, estimated 
end

# Search target partitions
def search_targets(alldrives, windrive, minfree)
	# windrive[0] contains the drive
	# windrive[1] contains array of partitions
	target_list = Array.new
	alldrives.each { |d|
		unless d.device == windrive[0].device
			d.partitions.each { |p|
				if p.fs =~ /ntfs/i || p.fs =~ /ext/i || p.fs =~ /btrfs/i
					target_list.push(p) if p.free_space > minfree
				end
			}
		end
	}
	return target_list 
end

# Write zeroes to free space on target - each partition
def write_zeroes(windrive, pgbar=nil)
	# windrive[0] contains the drive
	# windrive[1] contains array of partitions
	pgbar.text = "Nulle freie Speicherbereiche" unless pgbar.nil?
	windrive[0].partitions.each { |p|
		begin
			p.zero_free(pgbar)
		rescue
		end
	}
	pgbar.text = "Nulle freie Speicherbereiche - fertig" unless pgbar.nil?
end

def create_swap(target, pgbar)
	target.mount("rw")
	mntpnt = target.mount_point[0]
	return false if mntpnt.nil?
	if File.directory?("#{mntpnt}/XP-gerettet")
		rnd = Random.rand(100_000_000)
		system("mv '#{mntpnt}/XP-gerettet' '#{mntpnt}/XP-gerettet-#{rnd.to_s}'")
	end
	system("mkdir '#{mntpnt}/XP-gerettet'") 
	pgbar.text = "Erstelle Auslagerungsdatei"
	0.upto(127) { |n|
		pgbar.fraction = n.to_f / 127.0  
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		system("dd if=/dev/zero bs=8M count=1 seek=#{n} of='#{mntpnt}/XP-gerettet/swap.bin'" ) unless $stop_clone == true
	}
	pgbar.text = "Erstelle Auslagerungsdatei - fertig"
	unless $stop_clone == true
		system("mkswap '#{mntpnt}/XP-gerettet/swap.bin'" ) 
		unless system("swapon '#{mntpnt}/XP-gerettet/swap.bin'" )
			error_dialog("Fehler beim Erstellen der Auslagerungsdatei", "Es konnte keine Auslagerungsdatei erstellt werden, es wird versucht, ohne fortzufahren.") 
		else
			install_icons
		end
	end
end

# Copy to VDI
def copy_to_vdi(windrive, target, pgbar)
	# windrive[0] contains the drive
	# windrive[1] contains array of partitions
	o, e = calculate_size(windrive)
	# target.mount("rw")
	mntpnt = target.mount_point[0]
	if mntpnt.nil?
		error_dialog("Fehler beim Erstellen der Auslagerungsdatei", "Es konnte keine Auslagerungsdatei erstellt werden, es wird versucht, ohne fortzufahren.") 
		$stop_clone = true
		return false
	end
	vdi_running = true
	pgbar.text = "Erstelle Image der XP-Installation"
	vte = Vte::Terminal.new
	vte.signal_connect("child_exited") { vdi_running = false }
	vte.fork_command("/bin/bash", [ "/bin/bash", "device2vdi.sh", "/dev/" + windrive[0].device, mntpnt + "/XP-gerettet/xp.vdi", windrive[0].size.to_s ] )
	while vdi_running == true
		if $stop_clone == true
			system("killall -9 VBoxManage")
		end
		percentage = 0
		begin
			x = o.to_f * 1.05
			fsize = File.size(mntpnt + "/XP-gerettet/xp.vdi")
			percentage = ( fsize.to_f / x * 100.0).to_i 
			pgbar.fraction = fsize.to_f / x.to_f 
			pgbar.text = "Erstelle Image der XP-Installation - #{percentage}% abgeschlossen"
		rescue
			pgbar.pulse
		end
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 1.0
	end
	unless $stop_clone == true
		pgbar.text = "Erstelle Image der XP-Installation - fertig"
		pgbar.fraction = 1.0
	end
	unless File.exists?(mntpnt + '/XP-gerettet/xp.vdi')
		error_dialog("Fehler beim Erstellen des Images", "Das Image xp.vdi konnte nicht erstellt werden. Bitte prüfen Sie das Dateisystem des Ziellaufwerkes.") 
		$stop_clone = true
	end
	return mntpnt + '/XP-gerettet/xp.vdi'
end

def install_config(vdipath)
	uuid = nil
	IO.popen("/usr/local/VirtualBox/VBoxManage showhdinfo '#{vdipath}'") { |l|
		while l.gets
			ltoks = $_.strip.split
			uuid = ltoks[1] if ltoks[0] == "UUID:"
		end
	}
	cfgfile = vdipath.gsub("xp.vdi", "xp.vbox")
	system("cp -v xp.vbox '#{cfgfile}'") 
	system("sed -i 's/UUIDOFVDI/#{uuid}/g' '#{cfgfile}'")
	vmuuid = ` uuidgen `.strip
	system("sed -i 's/UUIDOFVM/#{vmuuid}/g' '#{cfgfile}'")
end

# Connect VDI
def connect_vdi(vdipath)
	system("modprobe -v nbd")
	system("qemu-nbd -c /dev/nbd0 '#{vdipath}'")
	system("kpartx -a -v -s /dev/nbd0") 
end

# Get CurrentControlSet
def get_currentcontrolset(basepath)
	unless system("mountpoint #{basepath}")
		error_dialog("Fehler beim Mount des Images", "Partitionstabelle oder Dateisystem des Images sind möglicherweise beschädigt.") 
		$stop_clone = true
		return nil
	end
	windir = nil
	sysdir = nil
	cfgdir = nil
	winfile = nil
	[ "Windows", "WINDOWS", "windows"].each { |w| windir = w if File.directory?(basepath + "/" + w) }
	return nil if windir.nil? 
	[ "System32", "SYSTEM32", "system32" ].each { |s| sysdir = windir + "/" + s if File.directory?(basepath + "/" + windir + "/" + s) }
	return nil if sysdir.nil?
	[ "Config", "CONFIG", "config" ].each { |c| cfgdir = sysdir + "/" + c if File.directory?(basepath + "/" + sysdir + "/" + c) }
	return nil if cfgdir.nil?
	[ "System", "SYSTEM", "system" ].each { |f| winfile = cfgdir + "/" + f if File.exists?(basepath + "/" + cfgdir + "/" + f) }
	return nil if winfile.nil?
	puts winfile
	ccset = nil 
	a = ` echo -e 'cat Select\\Current\nq\n' | reged -e "#{basepath}/#{winfile}" ` 
	b = a.split("\n")
	b.each { |t| ccset = t.strip[-1] if t =~ /^0x0/ }
	puts ccset 
	return ccset, winfile
end

def get_mergeide(basepath)
	unless system("mountpoint #{basepath}")
		error_dialog("Fehler beim Mount des Images", "Partitionstabelle oder Dateisystem des Images sind möglicherweise beschädigt.") 
		$stop_clone = true
		return nil
	end
	windir = nil
	sysdir = nil
	cfgdir = nil
	winfile = nil
	[ "Windows", "WINDOWS", "windows"].each { |w| windir = w if File.directory?(basepath + "/" + w) }
	return nil if windir.nil? 
	[ "System32", "SYSTEM32", "system32" ].each { |s| sysdir = windir + "/" + s if File.directory?(basepath + "/" + windir + "/" + s) }
	return nil if sysdir.nil?
	[ "Config", "CONFIG", "config" ].each { |c| cfgdir = sysdir + "/" + c if File.directory?(basepath + "/" + sysdir + "/" + c) }
	return nil if cfgdir.nil?
	[ "Software", "SOFTWARE", "software" ].each { |f| winfile = cfgdir + "/" + f if File.exists?(basepath + "/" + cfgdir + "/" + f) }
	return nil if winfile.nil?
	puts winfile
	midevers = nil 
	a = ` echo -e 'cat Microsoft\\Windows\\CurrentVersion\\Uninstall\\CobiRelaxIDE\\BuildID\nq\n' | reged -e "#{basepath}/#{winfile}" ` 
	b = a.split("\n")
	b.each { |t| midevers = t.strip if t.strip =~ /^2014\d{4}-\d{6}$/ }
	puts midevers.to_s
	puts "Key not found!" if midevers.nil? 
	return midevers, winfile
end

# Extract drivers
def extract_drivers(basepath, pgbar)
	pgbar.text = "Extrahiere generische Treiber"
	windir = nil
	sysdir = nil
	drvdir = nil
	cchdir = nil
	arcdir = nil
	cabfiles = 0
	[ "Windows", "WINDOWS", "windows"].each { |w| windir = w if File.directory?(basepath + "/" + w) }
	return nil if windir.nil? 
	puts "windir: #{windir}"
	[ "System32", "SYSTEM32", "system32" ].each { |s| sysdir = windir + "/" + s if File.directory?(basepath + "/" + windir + "/" + s) }
	return nil if sysdir.nil?
	puts "sysdir: #{sysdir}"
	[ "Drivers", "DRIVERS", "drivers" ].each { |c| drvdir = sysdir + "/" + c if File.directory?(basepath + "/" + sysdir + "/" + c) }
	return nil if drvdir.nil?
	puts "drvdir: #{drvdir}"
	[ "Driver Cache", "DRIVER CACHE", "driver cache" ].each { |f| cchdir = windir + "/" + f if File.directory?(basepath + "/" + windir + "/" + f) }
	return nil if cchdir.nil?
	puts "cchdir: #{cchdir}"
	[ "i386", "I386" ].each { |a| arcdir = cchdir + "/" + a if File.directory?(basepath + "/" + cchdir + "/" + a) }
	return nil if arcdir.nil?
	puts "arcdir: #{arcdir}"
	[ "driver.cab", "DRIVER.CAB", "sp2.cab", "SP2.CAB", "sp3.cab", "SP3.CAB" ].each { |z|
		if File.exists?(basepath + "/" + arcdir + "/" + z)
			puts "Found cab: #{basepath}/#{arcdir}/#{z}"
			cabfiles += 1
			[ "Pciidex.sys", "Atapi.sys", "Intelide.sys", "Pciide.sys" ].each { |f|
				# system("cabextract -F #{f} -d '#{basepath}/#{drvdir}' '#{basepath}/#{arcdir}/#{z}'")
				ext_running = true
				vte = Vte::Terminal.new
				vte.signal_connect("child_exited") { ext_running = false }
				vte.fork_command("cabextract", [ "cabextract", "-F", f, "-d", basepath + "/" + drvdir, basepath + "/" + arcdir ] )
				while ext_running == true
					pgbar.pulse
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					sleep 0.3
				end
			}
		end
	}
	if cabfiles < 1
		error_dialog("Fehler beim Extrahieren der Treiber", "Keine der CAB-Dateien driver.cab, sp2.cab oder sp3.cab wurde gefunden. In der Regel stellt dies kein Problem dar, im Einzelfall kann es jedoch eine Reparaturinstallation erforderlich machen.") 
	end
end

# Copy guest additions to every desktop we find:
def copy_additions(path, file="VBoxWindowsAdditions-x86.exe") 
	IO.popen("find '#{path}' -type d -name Desktop -print") { |l|
		while l.gets
			d = $_.strip
			unless d =~ /all\susers/i || d =~ /default\suser/i || d =~ /windows\/system32\/config/i 
				system("cp -v '#{file}' '#{d}'") 
				system("sync")
			end
		end
	}
end

# Clean up
def cleanup(targetdev)
	1.upto(32) { |n| system("dmsetup remove /dev/mapper/nbd0p#{n.to_s}") if File.exists?("/dev/mapper/nbd0p" + n.to_s) }
	system("qemu-nbd -d /dev/nbd0")
	# system("swapoff -a")
	File.new("/proc/swaps").each { |s|
		ltoks = s.strip.split
		if ltoks[0] =~ /swap\.bin/ && ltoks[1] =~ /file/i 
			system("sync")
			system("swapoff #{ltoks[0]}")
			File.unlink ltoks[0]
			system("sync")
		end
	}
	mntpnt = targetdev.mount_point[0]
	if $stop_clone == true
		system("rm -rf '#{mntpnt}/XP-gerettet'") 
		File.unlink("/var/run/lesslinux/stop.zeroing")
	end
	targetdev.umount
end


def install_icons
	[ "010_firefox", "gnomine", "mahjongg", "glchess" ].each { |f|
		system("install -m 0755 /usr/share/applications/#{f}.desktop /home/surfer/Desktop/")
	}
end

# Create a drivelist
drives = Array.new
windrives = Array.new
allwindrives = Array.new 
xpfound = false 
Dir.entries("/sys/block").each { |l|
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/ 
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /md[0-9]$/ 
}

# Now find windows installations
windrives, allwindrives = find_xp_drives(drives)
if windrives.size > 0
	xpfound = true
elsif allwindrives.size > 0
	windrives = allwindrives 
end
windrives.each { |d|
	puts "Found XP on: #{d[0].device}"
}
allwindrives.each { |d|
	puts "Found Windows on: #{d[0].device}"
}

### Create a window here - enter main loop ### 

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
window.set_title("XP-Retter")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.deletable = false
window.decorated = false
window.width_request = 600
window.height_request = 400

# box for progressbar
fixed = Gtk::Fixed.new
backs = Array.new
3.downto(0) { |n|
	backs[n] = Gtk::Image.new("step#{n.to_s}.png")
	fixed.put(backs[n], 0, 0) 
}
# box for progress bar:
pbox = Gtk::HBox.new(false, 5)
pgbar = Gtk::ProgressBar.new
pgbar.width_request = 460
pgbar.text = "Klicken Sie hier, um Ihr Windows XP jetzt zu retten →"
pbox.pack_start(pgbar, false, true, 0)
go = Gtk::Button.new("XP retten")
go.width_request = 120
go.height_request = 32
pbox.pack_start(go, false, false, 0)
fixed.put(pbox, 10, 350)
# Box for target selection 
dbox = Gtk::HBox.new(false, 5)
drop = Gtk::ComboBox.new
drop.width_request = 460
drop.height_request = 32
dbox.pack_start_defaults(drop)
reread = Gtk::Button.new("Neu einlesen")
reread.width_request = 120
tgtlist = Array.new 
go.sensitive = false
reread.sensitive = true
drop.sensitive = false
reread.signal_connect("clicked") { 
	tgtlist = reread_targets(drop, windrives[0])
	if tgtlist.size > 0
		go.sensitive = true
		drop.sensitive = true
	end
}
tgtlist = reread_targets(drop, windrives[0])
if tgtlist.size > 0
	go.sensitive = true
	drop.sensitive = true
end
# Take first drive found...
if windrives.size < 1
	info_dialog("Kein geeignetes Quelllaufwerk", "Es wurde keine Festplatte mit installiertem Windows gefunden. Möglicherweise ist das System beschädigt oder auf einem nicht unterstützten RAID installiert. Wenden Sie sich ggf. per Email an den Entwickler dieses Tools, Mattias Schlenker, ms@mattiasschlenker.de")
	system("shutdown-wrapper.sh &")
elsif xpfound == false
	info_dialog("XP nicht erkannt", "Es wurde zwar Windows gefunden, dieses aber nicht als Windows XP erkannt. In der Regel stellt dies kein Problem dar, führen Sie die XP-Rettung wie im Artikel beschrieben durch. Wenden Sie sich bei Nachfragen ggf. per Email an den Entwickler dieses Tools, Mattias Schlenker, ms@mattiasschlenker.de")
end
if windrives.size > 1 && xpfound == true
	info_dialog("Mehrere Festplatten mit XP gefunden", "Es wurden mehrere Festplatten mit Windows XP gefunden, gerettet wird die erste: #{windrives[0][0].vendor} #{windrives[0][0].model} - /dev/#{windrives[0][0].device} - #{windrives[0][0].human_size}. Wenn das nicht ist, was Sie wollen, schalten Sie den Computer aus und trennen Sie alle bis auf die zu rettende Festplatte.")
elsif windrives.size > 1
	info_dialog("Mehrere Festplatten mit Windows gefunden", "Es wurden mehrere Festplatten mit Windows gefunden, gerettet wird die erste: #{windrives[0][0].vendor} #{windrives[0][0].model} - /dev/#{windrives[0][0].device} - #{windrives[0][0].human_size}. Wenn das nicht ist, was Sie wollen, schalten Sie den Computer aus und trennen Sie alle bis auf die zu rettende Festplatte.")
end
if tgtlist.size < 1
	info_dialog("Kein geeignetes Ziellaufwerk", "Es wurde kein geeignetes Ziellaufwerk gefunden. Bitte schließen Sie eine NTFS formatierte USB-Festplatte an und klicken Sie anschließend auf \"Neu einlesen\"")
end
if mount_check(windrives[0]) == true
	info_dialog("Dateisystem beschädigt", "Das Dateisystem Ihres Windows XP ist beschädigt, wir empfehlen, den Computer herunterzufahren und CHKDSK durchzuführen.")
	# system("shutdown-wrapper.sh &")
else
	puts "Drive is clean, continuing."
end
# Check for preparation: Has mergeide already been executed?
mergeide_missing = 0
windrives[0][1].each{ |p|
	p.mount("rw")
	mntpnt = p.mount_point[0]
	v, f = get_mergeide(mntpnt)
	if v.nil?
		mergeide_missing += 1 
		copy_additions(mntpnt, "COMPUTERBILD-XP-Rettungsvorbereitung.exe") 
	end
	system("sync")
	sleep 2.0
	p.umount 
}
if mergeide_missing > 0 
	info_dialog("Fehlende Vorbereitung", "Das Programm \"XP-Rettungsvorbereitung\" wurde noch nicht ausgeführt. Starten Sie jetzt Windows XP, und installieren Sie die XP-Rettungsvorbereitung. Danach starten Sie den XP-Retter erneut. Das Programm \"XP-Rettungsvorbereitung\" wurde automatisch auf Ihren Windows Desktop kopiert. Sollten Sie sicher sein, dass Sie die Rettungsvorbereitung bereits erfolgreich ausgeführt haben, fahren Sie einfach fort.")
	# system("sudo poweroff")
end

dbox.pack_start_defaults(reread)
fixed.put(dbox, 10, 310)
leave = Gtk::Button.new # ("minimieren")
leave.image = Gtk::Image.new("/usr/share/icons/Faenza/actions/16/system-shutdown.png")
leave.relief = Gtk::RELIEF_NONE
leave.has_tooltip = true
leave.tooltip_text = "Abbrechen und herunterfahren"
fixed.put(leave, 565, 4)
$stop_clone = false
$running = false
File.unlink("/var/run/lesslinux/stop.zeroing") if File.exists?("/var/run/lesslinux/stop.zeroing")
window.add fixed
go.signal_connect("clicked") {
	backs[0].hide_all
	$running = true
	go.sensitive = false
	reread.sensitive = false
	drop.sensitive = false
	create_swap(tgtlist[drop.active], pgbar) unless $stop_clone == true
	unless $stop_clone == true
		windrives[0][1].each{ |p|
			p.mount("rw")
			mntpnt = p.mount_point[0]
			copy_additions(mntpnt) 
			system("sync")
			sleep 2.0
			p.umount 
		}
	end
	write_zeroes(windrives[0], pgbar) unless $stop_clone == true
	vdipath = copy_to_vdi(windrives[0], tgtlist[drop.active], pgbar) unless $stop_clone == true
	install_config(vdipath) unless $stop_clone == true 
	# connect_vdi(vdipath) unless $stop_clone == true 
	unless $stop_clone == true
		windrives[0][1].each{ |p|
			pnum = p.device.delete(windrives[0][0].device) unless $stop_clone == true
			puts "Partition to try /dev/mapper/nbd0p#{pnum}" 
			system("mkdir -p /tmp/wintarget") unless $stop_clone == true
			# if p.fs =~ /ntfs/i 
			#	system("mount -t ntfs-3g -o rw /dev/mapper/nbd0p#{pnum} /tmp/wintarget") unless $stop_clone == true
			# elsif p.fs =~ /fat/i
			#	system("mount -t vfat -o rw /dev/mapper/nbd0p#{pnum} /tmp/wintarget") unless $stop_clone == true
			# end
			# ccs, winf = get_currentcontrolset("/tmp/wintarget") unless $stop_clone == true
			# puts "CCS: #{ccs}, REGFILE: #{winf}" unless $stop_clone == true
			# system("sed s/THISNUM/#{ccs}/g < mergeide.reg > /tmp/mergeide.reg") unless $stop_clone == true
			# system("yes y | reged -I /tmp/wintarget/#{winf} HKEY_LOCAL_MACHINE\\\\SYSTEM /tmp/mergeide.reg") unless $stop_clone == true
			# extract_drivers("/tmp/wintarget", pgbar) unless $stop_clone == true
			# copy_additions("/tmp/wintarget") unless $stop_clone == true
			# system("umount /dev/mapper/nbd0p#{pnum}")
		}
	end
	cleanup(tgtlist[drop.active])
	backs[1].hide_all
	unless $stop_clone == true
		pgbar.text = "Die XP-Rettung ist abgeschlossen"
		pgbar.fraction = 1.0 
		info_dialog("Fertig!", "Windows XP wurde erfolgreich in eine virtuelle Maschine von VirtualBox umgewandelt.")
	else
		backs[2].hide_all
		pgbar.text = "Die XP-Rettung wurde abgebrochen"
		info_dialog("Abbruch", "Die XP-Rettung wurde abgebrochen, temporäre Dateien wurden entfernt.")
		pgbar.fraction = 1.0 
	end
	system("shutdown-wrapper.sh")
	system("sync") 
	system("install -m 0755 /usr/share/applications/shutdown.desktop /home/surfer/Desktop")
	exit 0
}
leave.signal_connect("clicked") {
	unless $running == true 
		system("shutdown-wrapper.sh")
	else
		$stop_clone = true
		system("touch /var/run/lesslinux/stop.zeroing")
	end
}
window.show_all
Gtk.main

