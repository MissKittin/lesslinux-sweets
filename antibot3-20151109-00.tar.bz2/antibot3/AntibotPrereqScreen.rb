#!/usr/bin/ruby
# encoding: utf-8

require "resolv"

class AntibotPrereqScreen
	
	def initialize(assi)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		tlfile = "AntibotPrereqScreen.xml"
		tlfile = "/usr/share/lesslinux/antibot3/AntibotPrereqScreen.xml" if File.exists?("/usr/share/lesslinux/antibot3/AntibotPrereqScreen.xml")
		@tl = MfsTranslator.new(lang, tlfile)
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
		@slab = [ Gtk::Label.new("<b>" + @tl.get_translation("short-net") + "</b>"),
			Gtk::Label.new("<b>" + @tl.get_translation("short-batt") + "</b>"),
			Gtk::Label.new("<b>" + @tl.get_translation("short-mem") + "</b>") ]
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
		@buttons[0] = Gtk::Button.new(@tl.get_translation("button-net"))
		@buttons[1] = Gtk::Button.new(@tl.get_translation("button-again"))
		@buttons[2] = Gtk::Button.new(@tl.get_translation("button-usb"))
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
		@longdesc[1].text = @tl.get_translation("power-long")
		unless File.exist?("/proc/acpi/battery/BAT0/state") 
			@icon[1].set("icons/ok48.png")
			@desc[1].text = @tl.get_translation("power-conn") 
			# @assistant.current_page = 2 if @assistant.current_page == 1
			return true
		end
		File.open("/proc/acpi/battery/BAT0/state").each { |line|
			ltoks = line.strip.split(':')
			if ltoks[0].strip =~ /charging/ && ltoks[1].strip =~ /discharging/ 
				# @icon[1].set(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::BUTTON)
				# @icon[1].set(Gtk::Image.new(@icon_theme.load_icon("gtk-quit", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))) # Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
				@icon[1].set("icons/error48.png")
				@desc[1].text = @tl.get_translation("power-batt") 
				return false
			elsif ltoks[0].strip =~ /charging/ && ltoks[1].strip =~ /^charg/ 
				# @icon[1].set(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
				# @icon[1].set(Gtk::Image.new(@icon_theme.load_icon("gtk-ok", 32, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)))
				@icon[1].set("icons/ok48.png")
				@desc[1].text = @tl.get_translation("power-conn") 
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
		dialog = Gtk::Dialog.new(@tl.get_translation("short-net"),
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ])
		ovbox = Gtk::VBox.new(false, 6)
		frames = Array.new
		[ @tl.get_translation("net-wifi"), @tl.get_translation("net-proxy") ].each { |s| frames.push(Gtk::Frame.new(s)) }
		netlabel = Gtk::Label.new(@tl.get_translation("net-wicd"))
		netlabel.use_markup = true
		netlabel.wrap = true
		netlabel.width_request = 450
		wicd_button = Gtk::Button.new(@tl.get_translation("button-wicd"))
		wicd_button.signal_connect('clicked') { system("wicd-gtk --no-tray &") } 
		netbox = Gtk::VBox.new(false, 6)
		netbox.pack_start(netlabel, true, false, 3)
		netbox.pack_start(wicd_button, true, false, 3)
		frames[0].add netbox
		proxylabel = Gtk::Label.new(@tl.get_translation("proxy-label"))
		proxylabel.use_markup = true
		proxylabel.wrap = true
		proxylabel.width_request = 450
		proxytab = Gtk::Table.new( 2, 4, false)
		proxydesc = [ @tl.get_translation("proxy-host"), @tl.get_translation("proxy-port"), 
			@tl.get_translation("proxy-user"), @tl.get_translation("proxy-pass") ]
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
		@longdesc[0].text = @tl.get_translation("net-desc")
		if @proxy_settings[0].strip.size > 0
			# @icon[0].set(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
			@icon[0].set("icons/ok48.png")
			@desc[0].text = @tl.get_translation("net-found") 
			return true
		end
		dns = Resolv::DNS.new
		dns.timeouts = 3 
		addr = nil
		begin
			addr = dns.getaddress("www.avira.com")
		rescue
		end
		if addr.nil?
			# @icon[0].set(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::BUTTON)
			@icon[0].set("icons/error48.png")
			@desc[0].text = @tl.get_translation("net-none") 
		else
			# @icon[0].set(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
			@icon[0].set("icons/ok48.png")
			@desc[0].text = @tl.get_translation("net-found") 
		end
	end
	
	def check_memory
		@longdesc[2].text = @tl.get_translation("mem-desc") 
		mem = -1
		File.open("/proc/meminfo").each { |line|
			ltoks = line.strip.split
			mem = ltoks[1].to_i if ltoks[0] =~ /MemTotal/  
		}
		if system("mountpoint /lesslinux/antibot") || system("mountpoint /tmp/lesslinux/antibot")
			@icon[2].set("icons/ok48.png")
			@desc[2].text = @tl.get_translation("mem-usb") 
			@buttons[2].sensitive = false
			#set_complete(true)
			@assistant.set_page_complete(@taligns[2], true)
			# puts "Currently on page: " + @assistant.current_page.to_s 
			# @assistant.current_page = 4 if @assistant.current_page == 2
			# @assistant.current_page = 2 if @assistant.current_page == 4
			return true
		elsif File.directory?("/lesslinux/toram/antibot3")
			@icon[2].set("icons/ok48.png")
			@desc[2].text = @tl.get_translation("mem-mem") 
			@buttons[2].sensitive = false
			@assistant.set_page_complete(@taligns[2], true)
		elsif mem >= 901_120 # 1_572_863
			@icon[2].set("icons/ok48.png")
			@desc[2].text = @tl.get_translation("mem-ok") 
			#set_complete(true)
			@assistant.set_page_complete(@taligns[2], true)
			# @assistant.current_page = 4
			return false
		else
			@icon[2].set("icons/error48.png")
			@desc[2].text = @tl.get_translation("mem-low") 
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
		dialog = Gtk::Dialog.new(@tl.get_translation("usb-title"),
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::CLOSE, Gtk::Dialog::RESPONSE_NONE ])
		ovbox = Gtk::VBox.new(false, 6)
		frames = Array.new
		[ @tl.get_translation("usb-frame0"), @tl.get_translation("usb-frame1"),  @tl.get_translation("usb-frame2") ].each { |s| frames.push(Gtk::Frame.new(s)) }
		tgtvbox = Gtk::VBox.new(false, 6)
		tgtlabel = Gtk::Label.new(@tl.get_translation("usb-desc"))
		tgtlabel.width_request = 450
		tgtlabel.wrap = true
		tgthbox = Gtk::HBox.new(false, 3)
		tgtsel = Gtk::ComboBox.new
		instbutton = Gtk::Button.new(@tl.get_translation("usb-go"))
		targets = fill_drivelist(tgtsel, instbutton)
		tgthbox.pack_start(tgtsel, true, true, 3)
		tgtreread = Gtk::Button.new(@tl.get_translation("reread")) 
		tgtreread.signal_connect("clicked") {
			targets = fill_drivelist(tgtsel, instbutton)
		}
		tgthbox.pack_start(tgtreread, false, false, 3)
		tgtvbox.pack_start(tgtlabel, true, false, 3)
		tgtvbox.pack_start(tgthbox, true, false, 3)
		frames[0].add tgtvbox
		methvbox = Gtk::VBox.new(false, 6)
		methpartradio = Gtk::RadioButton.new( @tl.get_translation("usb-sigs")  )
		methfullradio = Gtk::RadioButton.new(methpartradio, @tl.get_translation("usb-boot") )
		methfullradio.active = true
		methvbox.pack_start(methpartradio, true, false, 1)
		methvbox.pack_start(methfullradio, true, false, 1)
		frames[1].add methvbox
		insthbox = Gtk::HBox.new(false, 3)
		instprog = Gtk::ProgressBar.new
		instprog.text = @tl.get_translation("usb-pgbar") 
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
				AntibotMisc.info_dialog(@tl.get_translation("usb-nocancel"),@tl.get_translation("usb-progress"))
			end
		}
		instbutton.signal_connect('clicked') {
			if methfullradio.active? && targets[tgtsel.active].size < 5_900_000_000
				AntibotMisc.info_dialog(@tl.get_translation("usb-toosmall"),@tl.get_translation("usb-toosmall-title"))
			else
				@install_in_progress = true
				[ instbutton, tgtsel, methfullradio, methpartradio, tgtreread ].each { |i| i.sensitive = false }
				dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, false)
				dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_CLOSE, false)
				inst_success = run_installation(targets[tgtsel.active], methfullradio.active?, instprog)
				dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, true)
				dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_CLOSE, true)
				[ instbutton, tgtsel, methfullradio, methpartradio, tgtreread ].each { |i| i.sensitive = true } if inst_success == false
				@install_in_progress = false
			end
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
			if v.size > 1_900_000_000 && (v.removable == true || AntibotMisc.boot_options["internal"] == true) 
				text =  v.vendor + " " + v.model + " " + v.human_size + " (" + v.device + ")"
				combo.append_text(text) 
				usable_drives.push(v)
			end
		}
		if usable_drives.size < 1
			combo.append_text @tl.get_translation("no-suitable-drive") 
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
			copy_doc(tgt)
			return false unless copy_signatures(tgt, pgbar)
			make_swap(tgt, pgbar)
		else
			run_partitioning(tgt, pgbar)
			newtgt = MfsDiskDrive.new(tgt.device)
			write_sys(newtgt, pgbar)
			write_efi(newtgt, pgbar)
			write_boot(newtgt, pgbar)
			copy_doc(newtgt)
			copy_signatures(newtgt, pgbar, 3)
			system("/bin/bash /etc/rc.d/0141-swap.sh start")
			# make_swap(newtgt, pgbar)
			system("/bin/bash /etc/rc.d/0610-antibot.sh stop")
			system("/bin/bash /etc/rc.d/0610-antibot.sh stop")
			system("/bin/bash /etc/rc.d/0142-blobpart.sh start")
			system("/bin/bash /etc/rc.d/0610-antibot.sh start")
		end
		pgbar.text = @tl.get_translation("usb-done") 
		pgbar.fraction = 1.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		return true
	end
	
	def cmdline_partsizes
		swap = 1024
		home = 8
		blob = 512
		ltoks = Array.new
		File.open("/proc/cmdline").each { |line|
			ltoks = ltoks + line.split
		}
		ltoks.each { |t|
			if t =~ /^homecont/ 
				home = t.split(/[\-=]/)[-1].to_i
				home = 8 if home < 8
			elsif t =~ /^swapsize/
				swap = t.split(/[\-=]/)[-1].to_i
				swap = 8 if swap < 8
			elsif t =~ /^blobsize/
				blob = t.split(/[\-=]/)[-1].to_i
				blob = 8 if swap < 8
			end
		}
		return swap, home, blob 
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
		# Get size of the EFI boot partition
		efisize = File.size("#{sysmount}/boot/efi/efi.img") 
		# Calculate partition sizes
		p8blocks = ( isosize.to_f * 1.25 / 1048576 ).to_i + 1
		# p6blocks = 1024 # swap
		# p5blocks = 8	# home 
		# p4blocks = 512	# blob
		p3blocks = ( efisize.to_f * 1.51 / 1048576 ).to_i + 1
		p2blocks = ( ( bootsize - efisize ).to_f * 1.51 / 1048576 ).to_i + 1
		# p1blocks = ( tgt.size / 1048576 ).to_i - (2 * p8blocks) - p6blocks - p5blocks - p4blocks - p3blocks - p2blocks - 1 
		### For pros: read the partition sizes from the boot command line
		p6blocks, p5blocks, p4blocks = cmdline_partsizes
		p1blocks = ( tgt.size / 1048576 ).to_i - (2 * p8blocks) - p6blocks - p5blocks - p4blocks - p3blocks - p2blocks - 1 
		# if (tgt.size < 6_000_000_000)
		#	p8blocks = ( isosize.to_f * 1.21 / 1048576 ).to_i + 1
		#	p6blocks = 512 # swap
		#	p5blocks = 8	# home 
		#	p4blocks = 256	# blob
		#	p3blocks = ( efisize.to_f * 1.26 / 1048576 ).to_i + 1
		#	p2blocks = ( ( bootsize - efisize ).to_f * 1.26 / 1048576 ).to_i + 1
		#	p1blocks = ( tgt.size / 1048576 ).to_i - (2 * p8blocks) - p6blocks - p5blocks - p4blocks - p3blocks - p2blocks - 1 	
		# end
		# Write the first partition (DOS)... and all others
		p2start = ( p1blocks + 1 ) * 1048576 
		p3start = ( p1blocks + p2blocks + 1 ) * 1048576 
		p4start = ( p1blocks + p2blocks + p3blocks + 1 ) * 1048576 
		p5start = ( p1blocks + p2blocks + p3blocks + p4blocks + 1 ) * 1048576 
		p6start = ( p1blocks + p2blocks + p3blocks + p4blocks + p5blocks + 1 ) * 1048576 
		p7start = ( p1blocks + p2blocks + p3blocks + p4blocks + p5blocks + p6blocks + 1 ) * 1048576 
		p8start = ( p1blocks + p2blocks + p3blocks + p4blocks + p5blocks + p6blocks + p8blocks + 1 ) * 1048576 
		p8end = ( p1blocks + p2blocks + p3blocks + p4blocks + p5blocks + p6blocks + p8blocks + p8blocks ) * 1048576 
		
		commands = [
			"dd conv=fsync if=/dev/zero bs=1024 count=128 of=/dev/" + tgt.device,
			"sync",
			"dd conv=fsync if=/dev/zero bs=1M seek=" + (( tgt.size / 1048576 ) - 3 ).to_s   + " of=/dev/" + tgt.device,
			"sync",
			"parted -s /dev/#{tgt.device} unit B mklabel gpt",
			"sync",
			"parted -s /dev/#{tgt.device} unit B mkpart datawin fat32 1048576 #{ (p2start - 1).to_s } ",
			"sync",
			"parted -s /dev/#{tgt.device} unit B mkpart biosboot ext2 #{p2start.to_s} #{ (p3start - 1).to_s } ",
			"sync",
			"parted -s /dev/#{tgt.device} unit B set 2 legacy_boot on ",
			"sync", 
			"parted -s /dev/#{tgt.device} unit B mkpart efiboot fat32 #{p3start.to_s} #{ (p4start - 1).to_s } ",
			"sync",
			"parted -s /dev/#{tgt.device} unit B set 3 boot on",
			"sync",
			"parted -s /dev/#{tgt.device} unit B mkpart blob ext2 #{p4start.to_s} #{ (p5start - 1).to_s } ",
			"sync", 
			"parted -s /dev/#{tgt.device} unit B mkpart crypthome ext2 #{p5start.to_s} #{ (p6start - 1).to_s } ",
			"sync", 
			"parted -s /dev/#{tgt.device} unit B mkpart cryptswap ext2 #{p6start.to_s} #{ (p7start - 1).to_s } ",
			"sync", 
			"parted -s /dev/#{tgt.device} unit B mkpart system2 ext2 #{p7start.to_s} #{ (p8start - 1).to_s } ",
			"sync", 
			"parted -s /dev/#{tgt.device} unit B mkpart system1 ext2 #{p8start.to_s} #{ p8end.to_s } ",
			"sync"
		]
		5.times { commands.push("sleep 1") } 
		commands.push("partprobe /dev/#{tgt.device}")
		5.times { commands.push("sleep 1") } 
		1.upto(8) { |n|
			commands.push("dd conv=fsync if=/dev/zero bs=1M count=2 of=/dev/#{tgt.device}#{n.to_s}")
			commands.push("sync") 
		}
		commands = commands + [
			"mkfs.ntfs -Q -L USBDATA /dev/#{tgt.device}1",
			"sync",
			"mkfs.ext2 -L LessLinuxBoot /dev/#{tgt.device}2",
			"sync",
			"mkfs.btrfs -L LessLinuxBlob /dev/#{tgt.device}4",
			"sync",
			"mkfs.ext2 -L LessLinuxSwap /dev/#{tgt.device}6",
			"sync"
		]
		if p5blocks > 8
			commands.push("mkfs.ext2 -L LessLinuxCrypt /dev/#{tgt.device}5")
			commands.push("sync") 
		end
		5.times { commands.push("sleep 1") } 
		ccount = 0
		commands.each { |c|
			pgbar.text = @tl.get_translation("usb-tgt-prep") 
			puts "RUNNING: #{c}"
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
		weird_pulse(pgbar, @tl.get_translation("usb-do-mbr"))
		# Write MBR
		system("dd if=/usr/share/syslinux/gptmbr.bin of=/dev/#{tgt.device}")
		system("sync") 
		# Copy content of boot partition
		tgt.partitions[1].mount("rw")
		# FIXME!
		sleep 0.5
		tgt.partitions[2].mount("rw")
		weird_pulse(pgbar, @tl.get_translation("usb-do-boot"))
		# FIXME!
		sleep 0.5
		# system("rsync -avHP #{sysmount}/boot/ #{tgt.partitions[1].mount_point[0]}/boot/ ")
		system("mkdir -p #{tgt.partitions[1].mount_point[0]}/boot/")
		system("tar -C #{sysmount}/boot/ -cf - isolinux grub kernel | tar -C #{tgt.partitions[1].mount_point[0]}/boot/ -xvf -")
		# Write bootloader
		weird_pulse(pgbar, @tl.get_translation("usb-do-extl"))
		system("/usr/sbin/extlinux --install #{tgt.partitions[1].mount_point[0]}/boot/isolinux/")
		# Copy extlinux.conf if necessary
		unless File.exists?(tgt.partitions[1].mount_point[0] + "/boot/isolinux/extlinux.conf")
			system("cp #{tgt.partitions[1].mount_point[0]}/boot/isolinux/isolinux.cfg #{tgt.partitions[1].mount_point[0]}/boot/isolinux/extlinux.conf")
		end
		# Write UUID to config files
		system("sed -i 's/uuid=all/uuid=#{tgt.partitions[1].uuid}/g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/extlinux.conf")
		system("sed -i 's/swap=none/swap=#{tgt.partitions[5].uuid}/g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/extlinux.conf")
		## [ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  "${cfgfile}"
		## [ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' "${cfgfile}"
		unless tgt.partitions[4].uuid.nil?   || tgt.partitions[4].uuid =~ /^nil/ 
			system("sed -i 's/crypt=all/crypt=#{tgt.partitions[4].uuid}/g'  #{tgt.partitions[1].mount_point[0]}/boot/isolinux/extlinux.conf")
			system("sed -i 's/crypt=none/crypt=#{tgt.partitions[4].uuid}/g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/extlinux.conf")
		end
		Dir.foreach("#{tgt.partitions[1].mount_point[0]}/boot/isolinux/antibot") { |n|
			if n =~ /cfg$/ 
				weird_pulse(pgbar, @tl.get_translation("usb-do-uuid"))
				system("sed -i 's/uuid=all/uuid=#{tgt.partitions[1].uuid}/g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/antibot/#{n}")
				system("sed -i 's/swap=none/swap=#{tgt.partitions[5].uuid}/g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/antibot/#{n}")
				system("sed -i 's%^INCLUDE /boot/isolinux/boot0x80.cfg%# INCLUDE /boot/isolinux/boot0x80.cfg%g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/antibot/#{n}")
				system("sed -i 's%^# INCLUDE /boot/isolinux/usbonly%INCLUDE /boot/isolinux/usbonly%g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/antibot/#{n}")
				unless tgt.partitions[4].uuid.nil? || tgt.partitions[4].uuid =~ /^nil/ 
					system("sed -i 's/crypt=all/crypt=#{tgt.partitions[4].uuid}/g'  #{tgt.partitions[1].mount_point[0]}/boot/isolinux/antibot/#{n}")
					system("sed -i 's/crypt=none/crypt=#{tgt.partitions[4].uuid}/g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/antibot/#{n}")
				end
			end
		}
		b = File.new("#{tgt.partitions[1].mount_point[0]}/boot.uuid", "w")
		b.write(tgt.partitions[1].uuid)
		b.close
		s = File.new("#{tgt.partitions[1].mount_point[0]}/swap.uuid", "w")
		s.write(tgt.partitions[5].uuid)
		s.close
		unless tgt.partitions[4].uuid.nil? || tgt.partitions[4].uuid =~ /^nil/ 
			c = File.new("#{tgt.partitions[1].mount_point[0]}/crypt.uuid", "w")
			c.write(tgt.partitions[4].uuid) 
			c.close 
		end

		system("sed -i 's/uuid=all/uuid=#{tgt.partitions[1].uuid}/g' #{tgt.partitions[1].mount_point[0]}/boot/isolinux/usbonly.cfg")
		Dir.foreach("#{tgt.partitions[2].mount_point[0]}/loader/entries") { |n|
			if n =~ /conf$/
				weird_pulse(pgbar, @tl.get_translation("usb-do-uuid"))
				system("sed -i 's/uuid=all/uuid=#{tgt.partitions[1].uuid}/g' #{tgt.partitions[2].mount_point[0]}/loader/entries/#{n}")
				unless tgt.partitions[4].uuid.nil?  || tgt.partitions[4].uuid =~ /^nil/ 
					system("sed -i 's/crypt=all/crypt=#{tgt.partitions[4].uuid}/g'  #{tgt.partitions[2].mount_point[0]}/loader/entries/#{n}")
					system("sed -i 's/crypt=none/crypt=#{tgt.partitions[4].uuid}/g' #{tgt.partitions[2].mount_point[0]}/loader/entries/#{n}")
				end
			end
		}
		system("sync")
		# Umount
		tgt.partitions[1].umount
		tgt.partitions[2].umount
		system("mkdir /lesslinux/boot")
		tgt.partitions[1].mount("ro", "/lesslinux/boot")
		pgbar.text = @tl.get_translation("usb-boot-done")
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
			ddstr = "dd if=#{sysdev} of=/dev/#{tgt.device}8 bs=4194304 seek=#{n.to_s} skip=#{n.to_s} count=1 "
			chksum = ` dd if=#{sysdev} bs=4194304 skip=#{n.to_s} count=1 | sha1sum `.strip.split[0] 
			comp = "nix"
			tries = 0
			while (comp != chksum && tries < 4)
				puts ddstr
				system(ddstr)
				comp = ` dd if=/dev/#{tgt.device}8 bs=4194304 skip=#{n.to_s} count=1 | sha1sum `.strip.split[0] 
				tries += 1
			end
			pgbar.text = @tl.get_translation("usb-do-system") 
			pgbar.fraction = n.to_f / m4blocks.to_f
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			system("sync") if n % 4 == 0 
		}
	end
	
	def write_efi(tgt, pgbar) 
		sysmount = nil
		# Find out where the system is mounted
		[ "cdrom", "toram", "isoloop" ].each { |d|
			mnt = "/lesslinux/" + d
			sysmount = mnt if system("mountpoint -q #{mnt} ")
		}
		# FIXME! Usable error message!
		return false if sysmount.nil?
		# Get size of the EFI boot partition
		efisize = File.size("#{sysmount}/boot/efi/efi.img") 
		m4blocks = efisize / 4194304
		0.upto(m4blocks) { |n|
			ddstr = "dd if=#{sysmount}/boot/efi/efi.img of=/dev/#{tgt.device}3 bs=4194304 seek=#{n.to_s} skip=#{n.to_s} count=1 "
			puts ddstr
			system(ddstr)
			pgbar.text = @tl.get_translation("usb-do-efi") 
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
			pgbar.text = @tl.get_translation("usb-do-swap") 
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
	
	def copy_doc(tgt)
		# Are there partitions?
		if tgt.partitions.size < 1
			puts "ERROR: No partitions found!"
			AntibotMisc.info_dialog(@tl.get_translation("error-nofs"), @tl.get_translation("error-nofs-title"))
			return false
		end
		# Can we unmount?
		unless tgt.partitions[0].mount_point.nil?
			unless tgt.partitions[partition].umount
				puts "ERROR: Could not umount!"
				AntibotMisc.info_dialog(@tl.get_translation("error-inuse"), @tl.get_translation("error-inuse-title"))
				return false
			end
		end
		cdroot = ""
		[ "cdrom", "isoloop", "toram" ].each { |d|
			src = "/lesslinux/" + d
			cdroot = src if File.exist?(src + "/autorun.inf")
		}
		tgt.partitions[0].mount("rw")
		system("tar -C '#{cdroot}' -cvf - shutdown.bat autorun.inf autorun.ico liesmich.html Antibot.3.0.pdf Antibot.3.5.pdf Antibot.3.7.pdf  | tar -C '#{tgt.partitions[0].mount_point[0]}' -xf - ")
		system("sync")
		tgt.partitions[0].umount
		return true 
	end
	
	# FIXME! Show errors also in GUI
	# FIXME! Remove hardcoded size!
	# FIXME! Source might be /lesslinux/cdrom/Antibot3 instead of /lesslinux/cdrom
	def copy_signatures(tgt, pgbar, partition=0)
		# Are there partitions?
		if tgt.partitions.size < 1
			puts "ERROR: No partitions found!"
			AntibotMisc.info_dialog(@tl.get_translation("error-nofs"), @tl.get_translation("error-nofs-title"))
			return false
		end
		# Is the partition mountable - free space should answer that?
		free = tgt.partitions[partition].free_space 
		if free.nil? ||  free < 180_000_000
			puts "ERROR: Not enough free space!"
			AntibotMisc.info_dialog(@tl.get_translation("error-space"), @tl.get_translation("error-space-title"))
			return false
		end
		# Can we unmount?
		unless tgt.partitions[partition].mount_point.nil?
			unless tgt.partitions[partition].umount
				puts "ERROR: Could not umount!"
				AntibotMisc.info_dialog(@tl.get_translation("error-inuse"), @tl.get_translation("error-inuse-title"))
				return false
			end
		end
		source = nil
		cdroot = nil
		[ "cdrom", "isoloop", "toram" ].each { |d|
			[  "/", "/antibot3/"  ].each { |s|
				src = "/lesslinux/" + d + s 
				source = src if File.exist?(src + "avupdate")
			}
		}
		[ "cdrom", "isoloop", "toram" ].each { |d|
			src = "/lesslinux/" + d
			cdroot = src if File.exist?(src + "autorun.inf")
		}
		return false if source.nil?
		copy_files = Dir.entries("/AntiVir")
		copy_count = copy_files.size - 2
		copy_n = 0
		pgbar.text = @tl.get_translation("usb-do-sigs")
		tgt.partitions[partition].mount("rw")
		system("mkdir -p '#{tgt.partitions[partition].mount_point[0]}/antibot3/antivir' ")
		system("tar -C '#{source}' -cvf - avupdate avupdate.bat | tar -C '#{tgt.partitions[partition].mount_point[0]}/antibot3' -xf - ")
		system("tar -C '#{cdroot}' -cvf - shutdown.bat autorun.inf autorun.ico liesmich.html Antibot.3.0.pdf Antibot.3.5.pdf Antibot.3.7.pdf  | tar -C '#{tgt.partitions[partition].mount_point[0]}' -xf - ") unless cdroot.nil?
		copy_files.each { |f|
			unless f.strip == ".." || f.strip == "."
				system("tar -C '/AntiVir/' -cvf - '#{f}' | tar -C '#{tgt.partitions[partition].mount_point[0]}/antibot3/antivir' -xf - ")
				copy_n += 1
				pgbar.fraction = copy_n.to_f / copy_count.to_f
				pgbar.text = @tl.get_translation("usb-sig-detail").gsub("NUM", copy_n.to_s).gsub("TOTAL", copy_count.to_s) 
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				system("sync")
			end
		}
		pgbar.text = @tl.get_translation("usb-sig-done") 
		pgbar.fraction = 1.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		tgt.partitions[partition].umount
		system("/etc/rc.d/0610-antibot.sh stop")
		system("sync")
		system("mkdir -p /lesslinux/antibot/antibot3/" + @tl.get_translation("html-proto-dir"))
		system("sed -i 's%file:///tmp/Protokolle%file:///lesslinux/antibot/antibot3/" + @tl.get_translation("html-proto-dir")  +  "%g' /home/surfer/.gtk-bookmarks")
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