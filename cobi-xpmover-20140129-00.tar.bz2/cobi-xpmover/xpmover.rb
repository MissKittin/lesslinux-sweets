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

def reread_targets(combobox, windrive)
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
	tgtlist = Array.new
	potential_targets = search_targets(drives, windrive, e)
	100.downto(0) { |n| 
		begin
			combobox.remove_text(n)
		rescue
		end
	}
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
	resultset = Array.new
	drives.each { |d|
		winparts = Array.new 
		d.partitions.each { |p|
			iswin, winvers = p.is_windows
			if iswin == true && winvers =~ /XP$/
				winparts.push( p )
			end
		}
		if winparts.size > 0
			resultset.push( [ d, winparts ] )  
		end
	}
	return resultset 
end

# Ask which drive to use if more than one is found
def select_drive(windrives)
	return windrives[0] 
end

# Check if system partition on drive can be mounted
def mount_check(drive)
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
	occupied = drive[0].size - free 
	estimated = occupied * 105 / 100 + 104857600 + 1073741824
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
		p.zero_free(pgbar)
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
		system("dd if=/dev/zero bs=8M count=1 seek=#{n} of='#{mntpnt}/XP-gerettet/swap.bin'" )
	}
	pgbar.text = "Erstelle Auslagerungsdatei - fertig"
	system("mkswap '#{mntpnt}/XP-gerettet/swap.bin'" )
	system("swapon '#{mntpnt}/XP-gerettet/swap.bin'" )
	install_icons
end

# Copy to VDI
def copy_to_vdi(windrive, target, pgbar)
	# windrive[0] contains the drive
	# windrive[1] contains array of partitions
	o, e = calculate_size(windrive)
	# target.mount("rw")
	mntpnt = target.mount_point[0]
	return false if mntpnt.nil?
	vdi_running = true
	pgbar.text = "Erstelle Image der XP-Installation"
	vte = Vte::Terminal.new
	vte.signal_connect("child_exited") { vdi_running = false }
	vte.fork_command("/bin/bash", [ "/bin/bash", "device2vdi.sh", "/dev/" + windrive[0].device, mntpnt + "/XP-gerettet/xp.vdi", windrive[0].size.to_s ] )
	while vdi_running == true
		percentage = 0
		begin
			x = o.to_f * 1.2
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
	pgbar.text = "Erstelle Image der XP-Installation - fertig"
	pgbar.fraction = 1.0
	return mntpnt + '/XP-gerettet/xp.vdi'
end

# Connect VDI
def connect_vdi(vdipath)
	system("modprobe -v nbd")
	system("qemu-nbd -c /dev/nbd0 '#{vdipath}'")
	system("kpartx -a -v -s /dev/nbd0") 
end

# Get CurrentControlSet
def get_currentcontrolset(basepath)
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

# Extract drivers
def extract_drivers(basepath, pgbar)
	pgbar.text = "Extrahiere generische Treiber"
	windir = nil
	sysdir = nil
	drvdir = nil
	cchdir = nil
	arcdir = nil
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
		puts "Found cab: #{basepath}/#{arcdir}/#{z}"
		if File.exists?(basepath + "/" + arcdir + "/" + z)
			[ "Pciidex.sys", "Atapi.sys", "Intelide.sys", "Pciide.sys" ].each { |f|
				pgbar.pulse
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				system("cabextract -F #{f} -d '#{basepath}/#{drvdir}' '#{basepath}/#{arcdir}/#{z}'")
			}
		end
	}
end

# Clean up
def cleanup(targetdev)
	1.upto(32) { |n| system("dmsetup remove /dev/mapper/nbd0p#{n.to_s}") if File.exists?("/dev/mapper/nbd0p" + n.to_s) }
	system("qemu-nbd -d /dev/nbd0")
	system("swapoff -a")
	File.new("/proc/swaps").each { |s|
		ltoks = s.strip.split
		if ltoks[1] =~ /XP-gerettet\/swap\.bin/
			system("swapoff #{ltoks[0]}")
			File.unlink ltoks[0]
		end
	}
	system("umount #{targetdev}")
end

# Write configuration
def write_config
	
end

def install_icons
	[ "010_firefox", "gnomine", "mahjongg", "glchess" ].each { |f|
		system("install -m 0755 /usr/share/applications/#{f}.desktop /home/surfer/Desktop/")
	}
end

# Create a drivelist
drives = Array.new
windrives = Array.new
Dir.entries("/sys/block").each { |l|
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/ 
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /md[0-9]$/ 
}

# Now find windows installations
windrives = find_xp_drives(drives)
windrives.each { |d|
	puts "Found Windows on: #{d[0].device}"
}
# Take first drive found...

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
pbox = Gtk::HBox.new(false, 5)
pgbar = Gtk::ProgressBar.new
pgbar.width_request = 460
pgbar.text = "Warte..."
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
reread.signal_connect("clicked") { tgtlist = reread_targets(drop, windrives[0]) }
tgtlist = reread_targets(drop, windrives[0])
if tgtlist.size < 1
	info_dialog("Kein geeignetes Ziellaufwerk", "Es wurde kein geeignetes Ziellaufwerk gefunden. Bitte schließen Sie eine NTFS formatierte USB-Festplatte an und klicken Sie anschließend auf \"Neu einlesen\"")
end
if mount_check(windrives[0]) == true
	info_dialog("Dateisystem beschädigt", "Das Dateisystem Ihres Windows XP ist beschädigt, führen Sie chkdisk duch. Der Computer wird jetzt heruntergefahren.")
else
	puts "Drive is clean, continuing."
end
dbox.pack_start_defaults(reread)
fixed.put(dbox, 10, 310)
leave = Gtk::Button.new # ("minimieren")
leave.image = Gtk::Image.new("/usr/share/icons/Faenza/actions/16/system-shutdown.png")
leave.relief = Gtk::RELIEF_NONE
leave.has_tooltip = true
leave.tooltip_text = "Abbrechen und herunterfahren"
fixed.put(leave, 565, 4)

window.add fixed
go.signal_connect("clicked") {
	go.sensitive = false
	reread.sensitive = false
	drop.sensitive = false
	create_swap(tgtlist[drop.active], pgbar)
	write_zeroes(windrives[0], pgbar)
	vdipath = copy_to_vdi(windrives[0], tgtlist[drop.active], pgbar)
	connect_vdi(vdipath)
	windrives[0][1].each{ |p|
		pnum = p.device.delete(windrives[0][0].device)
		puts "Partition to try /dev/mapper/nbd0p#{pnum}" 
		system("mkdir -p /tmp/wintarget")
		if p.fs =~ /ntfs/i 
			system("mount -t ntfs-3g -o rw /dev/mapper/nbd0p#{pnum} /tmp/wintarget")
		elsif p.fs =~ /fat/i
			system("mount -t vfat -o rw /dev/mapper/nbd0p#{pnum} /tmp/wintarget")
		end
		ccs, winf = get_currentcontrolset("/tmp/wintarget")
		system("sed s/THISNUM/#{ccs}/g < mergeide.reg > /tmp/mergeide.reg") 
		system("yes y | reged -I /tmp/wintarget/#{winf} HKEY_LOCAL_MACHINE\\\\SYSTEM /tmp/mergeide.reg")
		extract_drivers("/tmp/wintarget", pgbar)
		system("umount /dev/mapper/nbd0p#{pnum}") 
	}
	cleanup("/dev/" + tgtlist[drop.active].device)
	info_dialog("Fertig!", "Windows XP wurde erfolgreich in eine virtuelle Maschine von VirtualBox umgewandelt.")
	system("shutdown-wrapper.sh") 
}
window.show_all
Gtk.main

