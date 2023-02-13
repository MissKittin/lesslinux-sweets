#!/usr/bin/ruby
# encoding: utf-8

require "resolv"

class AntibotPrereqScreen
	
	def initialize(assi)
		@wdgt = Gtk::Alignment.new(0.5, 0.5, 0.8, 0.0)
		@assistant = assi
		@install_in_progress = false
		@complete = false
		# @icon_theme = Gtk::IconTheme.default
		# Proxy
		@proxy_settings = [ "", "", "", "" ]
		# Icons
		@icon = Array.new
		0.upto(2) { |i| 
			# @icon.push Gtk::Image.new(Gtk::Stock::CANCEL, Gtk::IconSize::BUTTON)
			# @icon.push Gtk::Image.new(@icon_theme.load_icon("gtk-quit", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
			# @icon.push Gtk::Image.new(Gdk::Pixbuf.new("icons/error32.png"))
			@icon.push Gtk::Image.new("icons/error48.png")
		}
		# Short labels
		@slab = [ Gtk::Label.new("<b>Netzwerk</b>"),
			Gtk::Label.new("<b>Energie</b>"),
			Gtk::Label.new("<b>Speicher</b>") ]
		@slab.each { |s|
			s.use_markup = true
		}
		# Long descriptions
		@desc = Array.new
		@longdesc = Array.new
		0.upto(2) { |i| 
			@desc[i] = Gtk::Label.new("Hier steht ein etwas längerer Text, der möglicherweise über mehrere Zeilen geht. Dies ist Blindtext.")
			@desc[i].width_request = 375
			@desc[i].wrap = true 
			@longdesc[i] = Gtk::Label.new("Hier steht ein etwas längerer Text, der möglicherweise über mehrere Zeilen geht. Dies ist Blindtext.")
			@longdesc[i].width_request = 540
			@longdesc[i].wrap = true 
		}
		# Buttons
		@buttons = Array.new
		@buttons[0] = Gtk::Button.new("Internet-Optionen")
		@buttons[1] = Gtk::Button.new("Erneut prüfen")
		@buttons[2] = Gtk::Button.new("USB-Stick einrichten")
		@buttboxes = Array.new
		0.upto(2) { |i|  
			@buttboxes[i] = Gtk::Alignment.new(0.5, 0.5, 1.0, 0.0) 
			@buttboxes[i].add @buttons[i]
		}
		
		# Table
		#stab = Gtk::Table.new(4, 3, false)
		#stab.set_row_spacings 7
		#stab.set_column_spacings 5
		#0.upto(@slab.size - 1) { |i|
		#	stab.attach_defaults(@icon[i], 0, 1, i, i + 1)
		#	stab.attach_defaults(@slab[i], 1, 2, i, i + 1)
		#	stab.attach_defaults(@buttboxes[i], 3, 4, i, i + 1)
		#	stab.attach_defaults(@desc[i], 2, 3, i, i + 1)
		#}
		@taligns = Array.new
		indtabs = Array.new
		0.upto(2) { |i| 
			indtabs[i] = Gtk::Table.new(3, 2, false)
			indtabs[i].set_row_spacings 7
			indtabs[i].set_column_spacings 5
			indtabs[i].attach_defaults(@icon[i], 0, 1, 1, 2)
			# indtabs[i].attach_defaults(@slab[i], 1, 2, 1, 2)
			indtabs[i].attach_defaults(@buttboxes[i], 2, 3, 1, 2)
			indtabs[i].attach_defaults(@desc[i], 1, 2, 1, 2)
			indtabs[i].attach_defaults(@longdesc[i], 0, 3, 0, 1)
			@taligns[i] = Gtk::Alignment.new(0.5, 0.5, 0.8, 0.0)
			@taligns[i].add indtabs[i]
		}
		@buttons[1].signal_connect('clicked') { 
			check_power
			# @assistant.current_page = @assistant.current_page + 1 if check_power
			# update_page_flow
		}
		@buttons[0].signal_connect('clicked') { 
			net_dialog
			check_net
		}
		check_net
		@buttons[2].signal_connect('clicked') { 
			usb_dialog
			# update_page_flow
		}
		# check_memory
		# @wdgt.add stab
	end
	attr_reader :wdgt, :complete, :proxy_settings, :taligns
	
	def check_power
		skippable = false
		@longdesc[1].text = "Da die Überprüfung je nach Festplattengröße sehr lange dauern kann, darf sich der Computer nicht im Akku-Betrieb befinden. Stellen Sie daher bei einem Notebook sicher, dass das Gerät mit dem Netzteil verbunden ist."
		unless File.exist?("/proc/acpi/battery/BAT0/state") 
			@icon[1].set("icons/ok48.png")
			@desc[1].text = "Der Computer befindet sich im Netz-Betrieb, Klicken Sie auf „Vor“."
			# @assistant.current_page = 2 if @assistant.current_page == 1
			return true
		end
		File.open("/proc/acpi/battery/BAT0/state").each { |line|
			ltoks = line.strip.split(':')
			if ltoks[0].strip =~ /charging/ && ltoks[1].strip =~ /discharging/ 
				# @icon[1].set(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::BUTTON)
				# @icon[1].set(Gtk::Image.new(@icon_theme.load_icon("gtk-quit", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))) # Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
				@icon[1].set("icons/error48.png")
				@desc[1].text = "Der Computer befindet sich im Akku-Betrieb. Schließen Sie ihn an das Stromnetz an, und klicken Sie anschließend auf „Erneut prüfen“."
				return false
			elsif ltoks[0].strip =~ /charging/ && ltoks[1].strip =~ /^charg/ 
				# @icon[1].set(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
				# @icon[1].set(Gtk::Image.new(@icon_theme.load_icon("gtk-ok", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)))
				@icon[1].set("icons/ok48.png")
				@desc[1].text = "Der Computer befindet sich im Netz-Betrieb, Klicken Sie auf „Vor“."
				# @assistant.current_page = 2 if @assistant.current_page == 1
				return true
			end
		}
		return false
	end
	
	def update_page_flow
		power = check_power
		memory = check_memory
	end
	
	def net_dialog
		frame_width = 640
		# Create the dialog
		dialog = Gtk::Dialog.new("Netzwerk",
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ])
		ovbox = Gtk::VBox.new(false, 6)
		frames = Array.new
		[ "WLAN und IP-Adressen", "Proxy-Server" ].each { |s| frames.push(Gtk::Frame.new(s)) }
		netlabel = Gtk::Label.new("Sie können den <i>WiCD Network Manager</i> verwenden, um mit einem WLAN zu verbinden oder statische IP-Adressen zu vergeben")
		netlabel.use_markup = true
		netlabel.wrap = true
		netlabel.width_request = 450
		wicd_button = Gtk::Button.new("WiCD Network Manager starten")
		wicd_button.signal_connect('clicked') { system("wicd-gtk --no-tray &") } 
		netbox = Gtk::VBox.new(false, 6)
		netbox.pack_start(netlabel, true, false, 3)
		netbox.pack_start(wicd_button, true, false, 3)
		frames[0].add netbox
		proxylabel = Gtk::Label.new("Tragen Sie hier die Proxy-Zugangsdaten ein, falls ein Proxy zur Aktualisierung der Virensignaturen benötigt wird")
		proxylabel.use_markup = true
		proxylabel.wrap = true
		proxylabel.width_request = 450
		proxytab = Gtk::Table.new( 2, 4, false)
		proxydesc = [ "IP oder Hostname:", "Port:", "Nutzername:", "Passwort:" ]
		proxyfields = Array.new
		0.upto(3) { |n|
			proxytab.attach(Gtk::Label.new(proxydesc[n]), 0, 1, n, n+1)
			proxyfields[n] = Gtk::Entry.new
			proxyfields[n].text = @proxy_settings[n].strip
			proxytab.attach(proxyfields[n], 1, 2, n, n+1) 
		}
		proxybox = Gtk::VBox.new(false, 6)
		proxybox.pack_start(proxylabel, true, false, 3)
		proxybox.pack_start(proxytab, true, false, 3)
		frames[1].add proxybox
		frames.each { |f|
			ovbox.pack_start(f, true, true, 3)
		}
		dialog.vbox.add(ovbox)
		dialog.signal_connect('response') { 
			0.upto(3) { |n| @proxy_settings[n] = proxyfields[n].text.strip }
			check_net
			dialog.destroy
		}
		dialog.show_all
	end
	
	# FIXME: For now just try name resolution! - Must be extended to check if download via proxy works
	def check_net
		@longdesc[0].text = "Damit die Antibot-CD auch mit Informationen über die neuesten Schädlinge versorgt ist, benötigen Sie jetzt eine Internetverbindung."
		if @proxy_settings[0].strip.size > 0
			# @icon[0].set(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
			@icon[0].set("icons/ok48.png")
			@desc[0].text = "Die Antibot-CD 3.0 hat eine bestehende Internetverbindung erkannt. Klicken Sie auf „Vor“."
			return true
		end
		dns = Resolv::DNS.new
		addr = nil
		begin
			addr = dns.getaddress("www.avira.com")
		rescue
		end
		if addr.nil?
			# @icon[0].set(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::BUTTON)
			@icon[0].set("icons/error48.png")
			@desc[0].text = "Die Antibot-CD 3.0 konnte keine Internetverbindung finden. Bitte klicken Sie auf „Internet-Optionen“, um Ihr WLAN Netzwerk auszuwählen."
		else
			# @icon[0].set(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
			@icon[0].set("icons/ok48.png")
			@desc[0].text = "Die Antibot-CD 3.0 hat eine bestehende Internetverbindung erkannt. Klicken Sie auf „Vor“."
		end
	end
	
	def check_memory
		@longdesc[2].text = "Wenn Sie Ihren Computer von der Antibot-CD gestartet haben und damit überprüfen möchten, wird für einen reibungslosen Ablauf mindestens ein Gigabyte Arbeitsspeicher benötigt."
		puts "INFO: (re-)checking memory"
		mem = -1
		File.open("/proc/meminfo").each { |line|
			ltoks = line.strip.split
			mem = ltoks[1].to_i if ltoks[0] =~ /MemTotal/  
		}
		if system("mountpoint /lesslinux/antibot") || system("mountpoint /tmp/lesslinux/antibot")
			@icon[2].set("icons/ok48.png")
			@desc[2].text = "Sie verwenden einen USB-Speicherstift für Virensignaturen, Protokolle und die Auslagerungsdatei. Bitte klicken Sie auf „Vor“."
			@buttons[2].sensitive = false
			#set_complete(true)
			@assistant.set_page_complete(@taligns[2], true)
			# puts "Currently on page: " + @assistant.current_page.to_s 
			# @assistant.current_page = 4 if @assistant.current_page == 2
			# @assistant.current_page = 2 if @assistant.current_page == 4
			return true
		elsif File.directory?("/lesslinux/toram/antibot3")
			@icon[2].set("icons/ok48.png")
			@desc[2].text = "Sie haben die Antibot-CD 3.0 komplett in den Arbeitsspeicher kopiert. Bitte klicken Sie auf „Vor“."
			@buttons[2].sensitive = false
			@assistant.set_page_complete(@taligns[2], true)
		elsif mem >= 901_120 # 1_572_863
			@icon[2].set("icons/ok48.png")
			@desc[2].text = "Ihr Computer verfügt über genügend Arbeitsspeicher. Klicken Sie auf „Vor“, um die Prüfung gleich zu starten. Sie können die Antibot-CD auch auf einen USB-Speicherstift übertragen, um später Netbooks ohne Laufwerk zu überprüfen und Protokolle dauerhaft zu speichern."
			#set_complete(true)
			@assistant.set_page_complete(@taligns[2], true)
			# @assistant.current_page = 4
			return false
		else
			@icon[2].set("icons/error48.png")
			@desc[2].text = "Ihr Computer hat nicht genügend Arbeitsspeicher. Daher muss das Antibot-System auf einen USB-Stick übertragen werden. Stöpseln Sie einen Stick mit mindestens 2 Gigabyte Speicherplatz ein, und klicken Sie auf „USB-Stick einrichten“."
			#set_complete(false)
			@assistant.set_page_complete(@taligns[2], false)
			return false
		end
		return false
	end
	
	#def set_complete(comp)
	#	@assistant.set_page_complete(@wdgt, comp)
	#	@complete = comp
	#end
	
	def usb_dialog
		frame_width = 640
		# Create the dialog
		dialog = Gtk::Dialog.new("USB-Einrichtung",
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::CLOSE, Gtk::Dialog::RESPONSE_NONE ])
		ovbox = Gtk::VBox.new(false, 6)
		frames = Array.new
		[ "Ziel", "Methode", "Installation" ].each { |s| frames.push(Gtk::Frame.new(s)) }
		tgtvbox = Gtk::VBox.new(false, 6)
		tgtlabel = Gtk::Label.new("Wählen Sie einen USB-Stick, auf den Sie das Antibot-System übertragen wollen. Achtung: Bei Auswahl von „Startfähig“ gehen alle Dateien auf dem Laufwerk verloren! Wird Ihr Stick nicht angezeigt, klicken Sie auf „Neu einlesen“.")
		tgtlabel.width_request = 450
		tgtlabel.wrap = true
		tgthbox = Gtk::HBox.new(false, 3)
		tgtsel = Gtk::ComboBox.new
		instbutton = Gtk::Button.new("Starten")
		targets = fill_drivelist(tgtsel, instbutton)
		tgthbox.pack_start(tgtsel, true, true, 3)
		tgtreread = Gtk::Button.new("Neu einlesen") 
		tgtreread.signal_connect("clicked") {
			targets = fill_drivelist(tgtsel, instbutton)
		}
		tgthbox.pack_start(tgtreread, false, false, 3)
		tgtvbox.pack_start(tgtlabel, true, false, 3)
		tgtvbox.pack_start(tgthbox, true, false, 3)
		frames[0].add tgtvbox
		methvbox = Gtk::VBox.new(false, 6)
		methpartradio = Gtk::RadioButton.new( "Nur Signaturen und Protokolle: Vorhandene Daten bleiben bestehen")
		methfullradio = Gtk::RadioButton.new(methpartradio, "Startfähig: Vorhandene Daten werden gelöscht, Stick wird bootfähig")
		methfullradio.active = true
		methvbox.pack_start(methpartradio, true, false, 1)
		methvbox.pack_start(methfullradio, true, false, 1)
		frames[1].add methvbox
		insthbox = Gtk::HBox.new(false, 3)
		instprog = Gtk::ProgressBar.new
		instprog.text = "Bitte klicken Sie auf \"Starten\""
		insthbox.pack_start(instprog, true, true, 3)
		insthbox.pack_start(instbutton, false, false, 3)
		frames[2].add insthbox
		[ 0, 1, 2 ].each { |n|
			ovbox.pack_start(frames[n], true, true, 3)
		}
		dialog.vbox.add(ovbox)
		dialog.signal_connect('response') { 
			if @install_in_progress == false
				@assistant.current_page = @assistant.current_page + 1 
				# update_page_flow
				dialog.destroy 
			else 
				AntibotMisc.info_dialog("Die laufende Installation kann nicht abgebrochen werden!", "Installation läuft")
			end
		}
		instbutton.signal_connect('clicked') {
			@install_in_progress = true
			[ instbutton, tgtsel, methfullradio, methpartradio, tgtreread ].each { |i| i.sensitive = false }
			dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, false)
			dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_CLOSE, false)
			inst_success = run_installation(targets[tgtsel.active], methfullradio.active?, instprog)
			dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, true)
			dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_CLOSE, true)
			[ instbutton, tgtsel, methfullradio, methpartradio, tgtreread ].each { |i| i.sensitive = true } if inst_success == false
			@install_in_progress = false
		}
		dialog.show_all
	end
	
	def fill_drivelist(combo, button)
		drives = Array.new
		usable_drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/ 
		}
		999.downto(0) { |n|
			begin
				combo.remove_text(n)
			rescue
			end
		}
		drives.each { |v|
			if v.size > 1_500_000_000 && (v.removable == true || AntibotMisc.boot_options["internal"] == true) 
				text =  v.vendor + " " + v.model + " " + v.human_size + " (" + v.device + ")"
				combo.append_text(text) 
				usable_drives.push(v)
			end
		}
		if usable_drives.size < 1
			combo.append_text "Kein geeignetes Laufwerk gefunden"
			combo.sensitive = false
			button.sensitive = false
		else
			combo.sensitive = true
			button.sensitive = true
		end
		combo.active = 0
		return usable_drives
	end
	
	def run_installation(tgt, boot, pgbar)
		puts "Target: " + tgt.vendor + " " + tgt.model + " " + tgt.human_size + " (" + tgt.device + ")"
		puts "Bootable: " + boot.to_s
		if boot == false
			return false unless copy_signatures(tgt, pgbar)
			make_swap(tgt, pgbar)
		else
			run_partitioning(tgt, pgbar)
			newtgt = MfsDiskDrive.new(tgt.device)
			write_boot(newtgt, pgbar)
			write_sys(newtgt, pgbar)
			copy_signatures(newtgt, pgbar)
			make_swap(newtgt, pgbar)
		end
		pgbar.text = "Die Installation ist abgeschlossen - Bitte klicken Sie auf „Schließen“"
		pgbar.fraction = 1.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		return true
	end
	
	def run_partitioning(tgt, pgbar=nil)
		sysmount = nil
		# Find out where the system is mounted
		if system("mountpoint -q /lesslinux/isoloop")
			sysmount = "/lesslinux/isoloop"
		elsif system("mountpoint -q /lesslinux/toram")
			sysmount = "/lesslinux/toram"
		elsif system("mountpoint -q /lesslinux/cdrom")
			sysmount = "/lesslinux/cdrom"
		end
		# FIXME! Usable error message!
		return false if sysmount.nil?
		# Get size of boot folder
		bootsize = -1
		szline = ` du -k #{sysmount}/boot | tail -n1 ` 
		# FIXME! Usable error message!
		return false if szline.strip.size < 1
		bootsize = szline.strip.split[0].to_i * 1024 
		# Get size of ISO image
		isosize = -1
		isoline = ` df -k #{sysmount} | tail -n1 `
		isosize = isoline.strip.split[2].to_i * 1024 
		# Calculate partition sizes:
		p3blocks = ( isosize.to_f * 1.16 / 1048576 ).to_i + 1
		p2blocks = ( bootsize.to_f * 1.51 / 1048576 ).to_i + 1
		p1blocks = ( tgt.size / 1048576 ).to_i - p3blocks - p2blocks - 1 
		# Write the first partition (DOS)
		p2start = ( p1blocks + 1 ) * 1048576 
		# Write the second partition (boot)
		p3start = ( p1blocks + p2blocks + 1 ) * 1048576 
		p3end = ( p1blocks + p2blocks + p3blocks + 1 ) * 1048576 
		
		commands = [
			"dd if=/dev/zero bs=1024 count=128 of=/dev/" + tgt.device,
			"sync",
			"parted -s /dev/#{tgt.device} unit B mklabel msdos",
			"parted -s /dev/#{tgt.device} unit B mkpart primary fat32 1048576 #{ (p2start - 1).to_s } ",
			"parted -s /dev/#{tgt.device} unit B set 1 lba  on ",
			"sync",
			"parted -s /dev/#{tgt.device} unit B mkpart primary ext2 #{p2start.to_s} #{ (p3start - 1).to_s } ",
			"parted -s /dev/#{tgt.device} unit B set 2 boot  on ",
			"parted -s /dev/#{tgt.device} unit B mkpart primary ext2 #{p3start.to_s} #{ (p3end - 1).to_s } ",
			"sync",
			"partprobe /dev/#{tgt.device}",
			"mkfs.msdos -F32 /dev/#{tgt.device}1",
			"mkfs.ext3 /dev/#{tgt.device}2",
			"sync"
		]
		ccount = 0
		commands.each { |c|
			pgbar.text = "Bereite Ziellaufwerk vor..."
			pgbar.fraction = ccount.to_f / commands.size 
			system(c)
			ccount += 1
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		}
	end
	
	def write_boot(tgt, pgbar)
		sysmount = nil
		# Find out where the system is mounted
		[ "cdrom", "toram", "isoloop" ].each { |d|
			mnt = "/lesslinux/" + d
			sysmount = mnt if system("mountpoint -q #{mnt} ")
		}
		# FIXME! Usable error message!
		return false if sysmount.nil?
		weird_pulse(pgbar, "Schreibe MBR")
		# Write MBR
		system("dd if=/usr/share/syslinux/mbr.bin of=/dev/#{tgt.device}")
		# Copy content of boot partition
		tgt.partitions[1].mount("rw")
		weird_pulse(pgbar, "Kopiere Bootdateien")
		system("rsync -avHP #{sysmount}/boot/ #{tgt.partitions[1].mount_point[0]}/boot/ ")
		# Write bootloader
		weird_pulse(pgbar, "Schreibe Extlinux")
		system("extlinux -i #{tgt.partitions[1].mount_point[0]}/boot/isolinux/ ")
		# Write UUID to config files
		system("sed -i 's/uuid=all/uuid=#{tgt.partitions[1].uuid}/g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/extlinux.conf")
		Dir.foreach("#{tgt.partitions[1].mount_point[0]}/boot/isolinux") { |n|
			if n =~ /cfg$/ 
				weird_pulse(pgbar, "Schreibe UUID")
				system("sed -i 's/uuid=all/uuid=#{tgt.partitions[1].uuid}/g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/#{n}")
				system("sed -i 's%^INCLUDE /boot/isolinux/boot0x80.cfg%# INCLUDE /boot/isolinux/boot0x80.cfg%g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/#{n}")
				system("sed -i 's%^# INCLUDE /boot/isolinux/usbonly%INCLUDE /boot/isolinux/usbonly%g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/#{n}")
			end
		}
		# Copy extlinux.conf if necessary
		unless File.exists?(tgt.partitions[1].mount_point[0] + "/boot/isolinux/extlinux.conf")
			system("cp #{tgt.partitions[1].mount_point[0]}/boot/isolinux/isolinux.cfg #{tgt.partitions[1].mount_point[0]}/boot/isolinux/extlinux.conf")
		end
		# Umount
		tgt.partitions[1].umount
		system("mkdir /lesslinux/boot")
		tgt.partitions[1].mount("ro", "/lesslinux/boot")
		pgbar.text = "Bootdateien geschrieben"
		pgbar.fraction = 1.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end
	
	def write_sys(tgt, pgbar)
		sysmount = nil
		# Find out where the system is mounted
		[ "cdrom", "toram", "isoloop" ].each { |d|
			mnt = "/lesslinux/" + d
			sysmount = mnt if system("mountpoint -q #{mnt} ")
		}
		# FIXME! Usable error message!
		return false if sysmount.nil?
		mntline = ` df -k #{sysmount} | tail -n1 ` 
		puts mntline
		sysdev = mntline.strip.split[0]
		kblocks = mntline.strip.split[1].to_i
		m4blocks = kblocks / 4096
		0.upto(m4blocks) { |n|
			ddstr = "dd if=#{sysdev} of=/dev/#{tgt.device}3 bs=4194304 seek=#{n.to_s} skip=#{n.to_s} count=1 "
			puts ddstr
			system(ddstr)
			pgbar.text = "Kopiere System"
			pgbar.fraction = n.to_f / m4blocks.to_f
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			system("sync") if n % 4 == 0 
		}
	end
	
	def make_swap(tgt, pgbar)
		# tgt.partitions[0].mount("rw")
		system("mkdir -p '#{tgt.partitions[0].mount_point[0]}/antibot3/antivir' ")
		free = tgt.partitions[0].retrieve_occupation 
		swapblocks = 0
		if free < 402_653_184
			swapblocks = 256
		elsif free > 1_610_612_736
			swapblocks = 1024
		else
			swapblocks = free / 1_572_864
		end
		return false if swapblocks < 1
		0.upto(swapblocks - 1) { |n|
			pgbar.text = "Erstelle Auslagerungsspeicher"
			pgbar.fraction = n.to_f / swapblocks.to_f
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			system("dd if=/dev/zero bs=1048576 count=1 of='#{tgt.partitions[0].mount_point[0]}/antibot3/swap.sys' seek=#{n.to_s}")
			system("sync") if n % 32 == 0 
		}
		system("mkswap '#{tgt.partitions[0].mount_point[0]}/antibot3/swap.sys'")
		system("swapon '#{tgt.partitions[0].mount_point[0]}/antibot3/swap.sys'")
		pgbar.text = "Auslagerungsspeicher erstellt"
		pgbar.fraction = 1.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		return true
	end
	
	# FIXME! Show errors also in GUI
	# FIXME! Remove hardcoded size!
	# FIXME! Source might be /lesslinux/cdrom/Antibot3 instead of /lesslinux/cdrom
	def copy_signatures(tgt, pgbar)
		# Are there partitions?
		if tgt.partitions.size < 1
			puts "ERROR: No partitions found!"
			AntibotMisc.info_dialog("Auf dem ausgewählten Ziellaufwerk wurde kein geeignetes Dateisystem gefunden. Formatieren Sie den USB-Stick oder wählen Sie die startfähige Installation. Abbruch.", "Kein geeignetes Dateisystem")
			return false
		end
		# Is the partition mountable - free space should answer that?
		free = tgt.partitions[0].free_space 
		if free.nil? ||  free < 120_000_000
			puts "ERROR: Not enough free space!"
			AntibotMisc.info_dialog("Auf dem ausgewählten Ziellaufwerk ist zuwenig Platz frei. Löschen Sie Dateien oder wählen Sie die startfähige Installation. Abbruch.", "Zuwenig freier Platz")
			return false
		end
		# Can we unmount?
		unless tgt.partitions[0].mount_point.nil?
			unless tgt.partitions[0].umount
				puts "ERROR: Could not umount!"
				AntibotMisc.info_dialog("Das ausgewählte Laufwerk befindet sich im Zugriff. Abbruch.", "Laufwerk im Zugriff")
				return false
			end
		end
		source = nil
		[ "cdrom", "isoloop", "toram" ].each { |d|
			[  "/", "/antibot3/"  ].each { |s|
				src = "/lesslinux/" + d + s 
				source = src if File.exist?(src + "avupdate")
			}
		}
		return false if source.nil?
		copy_files = Dir.entries("/AntiVir")
		copy_count = copy_files.size - 2
		copy_n = 0
		pgbar.text = "Kopiere Programmdateien..."
		tgt.partitions[0].mount("rw")
		system("mkdir -p '#{tgt.partitions[0].mount_point[0]}/antibot3/antivir' ")
		system("tar -C '#{source}' -cvf - avupdate avupdate.bat | tar -C '#{tgt.partitions[0].mount_point[0]}/antibot3' -xf - ")
		
		copy_files.each { |f|
			unless f.strip == ".." || f.strip == "."
				system("tar -C '/AntiVir/' -cvf - '#{f}' | tar -C '#{tgt.partitions[0].mount_point[0]}/antibot3/antivir' -xf - ")
				copy_n += 1
				pgbar.fraction = copy_n.to_f / copy_count.to_f
				pgbar.text = "Kopiere Signaturdatei #{copy_n.to_s} von #{copy_count.to_s}"
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				system("sync")
			end
		}
		pgbar.text = "Kopieren der Signaturdateien abgeschlossen"
		pgbar.fraction = 1.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		tgt.partitions[0].umount
		system("umount /AntiVir")
		system("mkdir -p /lesslinux/antibot")
		tgt.partitions[0].mount("rw", "/lesslinux/antibot")
		system("mkdir -p /lesslinux/antibot/antibot3/Protokolle")
		system("mount --bind /lesslinux/antibot/antibot3/antivir /AntiVir")
		system("sed -i 's%file:///tmp/Protokolle%file:///lesslinux/antibot/antibot3/Protokolle%g' /home/surfer/.gtk-bookmarks")
	end
	
	def weird_pulse(pgbar, text=nil)
		pgbar.text = text unless text.nil?
		pgbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end
	
	def proxy_parameters
		params = Array.new
		if @proxy_settings[0].strip.size > 0
			params.push("--proxy-host=" + @proxy_settings[0].strip)
			if @proxy_settings[1].strip.size > 0
				params.push("--proxy-port=" + @proxy_settings[1].strip)
			else
				params.push("--proxy-port=3128")
			end
			params.push("--proxy-username=" + @proxy_settings[2].strip) if @proxy_settings[2].strip.size > 0
			params.push("--proxy-password=" + @proxy_settings[3].strip) if @proxy_settings[3].strip.size > 0
		end
		return params
	end
	
end