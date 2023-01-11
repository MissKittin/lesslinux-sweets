#!/usr/bin/ruby
# encoding: utf-8

require 'MfsTranslator.rb'

class UsbInstallScreen	
	def initialize(extlayers, button)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		if File.exist?("/etc/lesslinux/branding/UsbInstallScreen.xml")
			@tlx = MfsTranslator.new(lang, "/etc/lesslinux/branding/UsbInstallScreen.xml")
		else
			@tlx = MfsTranslator.new(lang, "UsbInstallScreen.xml")
		end
		@layers = Array.new
		@extlayers = extlayers 
		@killinstall = false
		@lang = ENV['LANGUAGE'][0..1]
		@lang = ENV['LANG'][0..1] if @lang.nil?
		@lang = "en" if @lang.nil?
		@tlfile = "usbinstall.xml"
		# tlfile = "/usr/share/lesslinux/drivetools/usbinstall.xml" if File.exists?("/usr/share/lesslinux/drivetools/usbinstall.xml")
		@tl = MfsTranslator.new(@lang, @tlfile)
		### ComboBox for target drives
		@targetcombo = Gtk::ComboBox.new
		@targetdrives = Array.new
		### ProgressBar for running dd
		@installprogress = Gtk::ProgressBar.new
		
		# attach target screen
		target = create_target_screen(extlayers)
		extlayers["installtarget"] = target
		@layers.push target
		
		# attach progress screen
		installing = create_progress_screen(extlayers)
		extlayers["installprogress"] = installing
		@layers.push installing
		
		# attach select screen USB install or finish EFI install
		select = create_select_screen(extlayers)
		extlayers["DEAD_installselect"] = select
		@layers.push select
		
		# Screen to start EFI installation
		efiinstall = create_efiinstallscreen(extlayers)
		extlayers["efiinstall"] = efiinstall
		@layers.push efiinstall
	
		# Screen to start EFI uninstallation
		efiuninstall = create_efiuninstallscreen(extlayers)
		extlayers["efiuninstall"] = efiuninstall
		@layers.push efiuninstall
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				# @targetdrives = reread_drivelist(@targetcombo)
				extlayers["DEAD_installselect"].show_all
			end
		}
	end
	attr_reader :layers
	
	def prepare_efiinstall
		e = check_efi
		if e > 0
			@extlayers.each { |k,v|v.hide_all }
			TileHelpers.umount_all 
			if e > 1 
				return "efiuninstall"
			else
				return "efiinstall"
			end
		end
		return nil 
	end
	
	def prepare_installtarget
		TileHelpers.umount_all 
		@targetdrives = reread_drivelist(@targetcombo)
	end
	
	def create_select_screen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		### First panel, selection of tasks
		# First tile, rescue on file system level
		button1 = Gtk::EventBox.new.add Gtk::Image.new("rescuewine.png")
		text1 = Gtk::Label.new
		text1.width_request = 320
		text1.wrap = true
		text1.set_markup("<span foreground='white'><b>" + @tlx.get_translation("usbinstallhead") + "</b>\n" + @tlx.get_translation("usbinstallbody") + "</span>")
	
		# Second tile, rescue to cloud
		button2 = Gtk::EventBox.new.add Gtk::Image.new("rescueturq.png")
		text2 = Gtk::Label.new
		text2.width_request = 320
		text2.wrap = true
		text2.set_markup("<span foreground='white'><b>" + @tlx.get_translation("efiinstallhead") + "</b>\n"+ @tlx.get_translation("efiinstallbody") + "</span>")
		
		# Third tile copy DVD
		button3 = Gtk::EventBox.new.add Gtk::Image.new("rescuewine.png")
		text3 = Gtk::Label.new
		text3.width_request = 320
		text3.wrap = true
		text3.set_markup("<span foreground='white'><b>" + @tlx.get_translation("dvdinstallhead") + "</b>\n"+ @tlx.get_translation("dvdinstallbody") + "</span>")
		
		fixed.put(button1, 0, 0)
		fixed.put(button2, 0, 140)
		fixed.put(text1, 130, 0)
		fixed.put(text2, 130, 140)

		loopfile = get_loop_file
		
		unless loopfile.nil?
			fixed.put(button3, 0, 280)
			fixed.put(text3, 130, 280)
		end
	
		button1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.umount_all 
				@targetdrives = reread_drivelist(@targetcombo)
				extlayers["installtarget"].show_all
			end
		}
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				e = check_efi
				if e > 0
					extlayers.each { |k,v|v.hide_all }
					TileHelpers.umount_all 
					if e > 1 
						extlayers["efiuninstall"].show_all
					else
						extlayers["efiinstall"].show_all
					end
				else
					TileHelpers.error_dialog(@tlx.get_translation("no_efi_found"))
				end
			end
		}
		button3.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("xfburn \"#{loopfile}\" &") 
			end
		}
		
		return fixed
	end
	
	def get_esp
		drives = Array.new
		auxdrives = Array.new
		Dir.entries("/sys/block").each { |l|
			auxdrives.push(MfsDiskDrive.new(l, false)) if ( l =~ /[a-z]$/ || l =~ /mmcblk[0-9]$/ ) 
		}
		auxdrives.each { |d|
			drives.push(d) if d.usb == false && d.gpt == true && !d.efiboot.nil? 
		}  
		return drives 
	end
	
	# return partition containing the kernel
	
	def get_kernel(drive)
		kernel = nil
		drive.partitions.each { |p|
			if p.fs =~ /ntfs/ 
				p.mount
				mnt = p.mount_point
				unless mnt.nil?
					if File.exists?(mnt[0] + "/Program Files (x86)/RescueLoader/notfall.lnx")
						kernel = p 
					end
				end
				p.umount
			end
		}
		return kernel 
	end
	
	# run efi installation
	
	def optical?
		optical = false
		File.open("/proc/mounts").each { |line|
			ltoks = line.strip.split
			optical = true if ltoks[0] =~ /\/dev\/sr[0-9]/ && ltoks[1] =~ /\/lesslinux\/cdrom/
			optical = true if ltoks[1] =~ /\/lesslinux\/ramiso/ 
		}
		return optical 
	end
	
	def get_loop_file
		TileHelpers.set_lock 
		loop = nil
		File.open("/proc/mounts").each { |line|
			ltoks = line.strip.split
			loop = ltoks[0] if ltoks[1] =~ /\/lesslinux\/isoloop/
		}
		unless loop.nil?
			IO.popen("losetup -a") { |line|
				while line.gets
					ltoks = $_.strip.split	
					if ltoks[0].gsub(":", "") == loop
						loop = ltoks[-1].gsub("(", "").gsub(")", "") 
					end
				end
			}
		end
		TileHelpers.remove_lock
		return loop 
	end
	
	def is64?
		return true if `uname -m `=~ /64/ 
		return false 
	end
	
	def install_efi(drive, knlpart)
		TileHelpers.set_lock 
		# Save the boot order
		bootorder = ` efibootmgr | grep BootOrder `.strip.split[1]
		# mount partition 
		part = nil
		r = Regexp.new( '[a-z]' + drive.efiboot.to_s + '$')
		efipartnum = 0
		drive.partitions.each { |p| 
			if r.match(p.device) 
				part = p
				part.device =~ /[a-z]([0-9]+)$/
				efipartnum = $1.to_i 
			end
		}
		part.mount("rw")
		mnt = part.mount_point
		# unpack bootloader
		tarball = nil
		config = nil 
		gdir = nil
		efiimg = nil 
		[ "cdrom", "isoloop" ].each { |d|
			t = "/lesslinux/#{d}/boot/grub/grub4efihdd.tgz"
			c = "/lesslinux/#{d}/boot/grub/grub.cfg.hdd"
			g = "/lesslinux/#{d}/boot/grub"
			e = "/lesslinux/#{d}/boot/efi/efi.img"
			tarball = t if File.exists?(t)
			config = c if File.exists?(c)
			gdir = g if File.directory?(g)
			efiimg = e if File.exists?(e)
		}
		[ tarball, config, gdir, efiimg ].each { |f|
			puts "Using: #{f}" 
		}
		# system("tar -C #{mnt[0]} -xvf #{tarball}") 
		if File.directory?("#{mnt[0]}/BOOT")
			system("mv #{mnt[0]}/BOOT #{mnt[0]}/BOOT_")
			system("mv #{mnt[0]}/BOOT_ #{mnt[0]}/boot")
		elsif File.directory?("#{mnt[0]}/Boot")
			system("mv #{mnt[0]}/Boot #{mnt[0]}/BOOT_")
			system("mv #{mnt[0]}/BOOT_ #{mnt[0]}/boot")
		end
		system("mkdir -p #{mnt[0]}/boot/grub")
		system("tar -C #{gdir} -cf - . | tar -C #{mnt[0]}/boot/grub -xf - ")
		system("mkdir -p /tmp/efi")
		system("mkdir -p #{mnt[0]}/EFI/Boot")
		system("mount -t vfat -o loop,ro #{efiimg} /tmp/efi")
		# system("cat /proc/mounts")
		# system("find /tmp/efi -type f")
		system("sync")
		sleep 1.0
		system("cp -v /tmp/efi/EFI/BOOT/GRUBX64.EFI  #{mnt[0]}/EFI/Boot/GRUBX64.EFI")
		system("cp -v /tmp/efi/EFI/BOOT/BOOTX64.EFI  #{mnt[0]}/EFI/Boot/COBIX64.EFI")
		system("sync")
		system("umount /tmp/efi")
		# Get the device number of the partition containing the kernel
		knlpart.device =~ /[a-z]([0-9]*)$/
		pnum = $1.to_i
		# sed config
		system("cat #{config} | sed 's/PARTNUM/#{pnum}/g' | sed 's%KERNELPATH%/Program Files (x86)/RescueLoader/notfall.lnx%g' | sed 's%INITRAMPATH%/Program Files (x86)/RescueLoader/notfall.dsk%g' | sed 's%EFIPART%#{efipartnum}%' > #{mnt[0]}/boot/grub/grub.cfg")
		# unmount
		system("sync") 
		part.umount
		# run efibootmgr
		system("efibootmgr --create --bootnum 9037 --disk /dev/#{drive.device} --part #{drive.efiboot} --label '" + @tlx.get_translation("efibootmgr_label").strip + "' --loader \\\\EFI\\\\Boot\\\\COBIX64.EFI") 
		# fix bootorder
		system("efibootmgr -o #{bootorder},9037")
		# system("efibootmgr --bootnum 9037 -A")
		TileHelpers.remove_lock
	end
	
	def uninstall_efi(drive)
		TileHelpers.set_lock 
		# run efibootmgr
		system("efibootmgr --bootnum 0001 -a") 
		system("efibootmgr --bootnum 9037 -B") 
		# mount partition 
		part = nil
		r = Regexp.new( '[a-z]' + drive.efiboot.to_s + '$')
		drive.partitions.each { |p| part = p if r.match(p.device) }
		return false if part.nil? 
		part.mount("rw")
		mnt = part.mount_point
		# remove bootloader
		system("rm -rf '#{mnt[0]}/boot/grub' ")
		system("rm -f #{mnt[0]}/EFI/Boot/GRUBX64.EFI #{mnt[0]}/EFI/Boot/COBIX64.EFI") 
		system("sync") 
		part.umount
		TileHelpers.remove_lock
	end
	
	def create_efiinstallscreen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tlx.get_translation("goto_efiinstall") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("usbgreen.png")
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# Run install
				espdisk = get_esp 
				puts "Found EFI system partition on #{espdisk[0].device}"
				knl = get_kernel(espdisk[0]) 
				if knl.nil? 
					TileHelpers.error_dialog(@tlx.get_translation("error_run_windows_installer_first"))
				else
					puts "Found kernel on partition #{knl.device}"
					TileHelpers.set_lock 
					install_efi(espdisk[0], knl)
					TileHelpers.success_dialog(@tlx.get_translation("efiinstall_successful"))
				end
				extlayers.each { |k,v| v.hide_all }
				TileHelpers.back_to_group
			end
		}
		instlabel = TileHelpers.create_label("<b>" + @tlx.get_translation("goto_efiinstall_head") + "</b>\n\n" + @tlx.get_translation("goto_efiinstall_body"), 510)
		# fixed.put(tile, 0, 0)
		fixed.put(instlabel, 0, 0)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def create_efiuninstallscreen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tlx.get_translation("goto_efiuninstall") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("usbgreen.png")
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# Run install
				TileHelpers.set_lock
				espdisk = get_esp 
				puts "Found EFI system partition on #{espdisk[0].device}"
				uninstall_efi(espdisk[0])
				TileHelpers.success_dialog(@tlx.get_translation("efiuninstall_successful"))
				extlayers.each { |k,v| v.hide_all }
				TileHelpers.back_to_group
			end
		}
		instlabel = TileHelpers.create_label("<b>" + @tlx.get_translation("goto_efiuninstall_head") + "</b>\n\n" + @tlx.get_translation("goto_efiuninstall_body"), 510)
		# fixed.put(tile, 0, 0)
		fixed.put(instlabel, 0, 0)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def check_efi
		return 0 unless system("mountpoint -q /sys/firmware/efi/efivars") 
		res = 1
		IO.popen("efibootmgr") { |line|
			while line.gets
				res = 2 if $_.strip =~ /^Boot9037/ 
			end
		}
		return res
	end
	
	def create_target_screen(extlayers)
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tlx.get_translation("gotoinstall") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("usbgreen.png")
		@targetcombo.height_request = 32
		@targetcombo.width_request = 380
		deltext = TileHelpers.create_label("<b>" + @tlx.get_translation("targethead") + "</b>\n\n" + @tlx.get_translation("targetbody"), 510)
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		reread.signal_connect('clicked') { 
			@targetdrives = reread_drivelist(@targetcombo)
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# Some checks here!
				if @targetdrives.size < 1
					TileHelpers.error_dialog(@tlx.get_translation("targeterrorbody"), @tlx.get_translation("targeterrorhead"))
				elsif TileHelpers.yes_no_dialog(@tlx.get_translation("confirmbody"), @tlx.get_translation("confirmhead"))
					@killinstall = false
					TileHelpers.set_lock 
					target = @targetdrives[@targetcombo.active] 
					extlayers.each { |k,v|v.hide_all }
					extlayers["installprogress"].show_all
					# run_install(@cloneprogress)
					run_installation(target, "de", [0,0], @installprogress) 
					if @killinstall == false
						if optical? == true
							appendline = File.new("/proc/cmdline").read.strip 
							if TileHelpers.yes_no_dialog(@tlx.get_translation("kexecbody"), @tlx.get_translation("successhead"))
								system("kexec -f --initrd=/tmp/initrd --append \"#{appendline} earlyeject\" -x /tmp/kernel")
								sleep 3.0
								system("reboot")
							else
								system("rm -f /tmp/initrd /tmp/kernel")
							end
						else	
							TileHelpers.success_dialog(@tlx.get_translation("successbody"), @tlx.get_translation("successhead"))
						end
					else
						TileHelpers.success_dialog(@tlx.get_translation("cancelbody"), @tlx.get_translation("cancelhead"))
					end
					extlayers.each { |k,v|v.hide_all }
					TileHelpers.back_to_group
				end
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(@targetcombo, 0, 160)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 160)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	def calculate_min_size 
		sysmount = ""
		[ "/lesslinux/cdrom", "/lesslinux/isoloop" ].each { |m|
			sysmount = m if system("mountpoint -q #{m}")
		}
		if sysmount == ""
			error_dialog( @tl.get_translation("no_system_title"), @tl.get_translation("no_system_found"))
			exit 1 
		end
		sysdev = ` df -k #{sysmount} | tail -n1 `.strip.split[0].to_s
		isosize = ` df -k #{sysmount} | tail -n1 `.strip.split[2].to_i * 1024  
		efisize = ` ls -lak #{sysmount}/boot/efi/efi.img `.strip.split[4].to_i 
		bootsize = ` du -k #{sysmount}/boot | tail -n1 `.strip.split[0].to_i * 1024
		padsize = 1024 ** 2 * 64 
		minsize = isosize + bootsize + efisize + padsize
		puts "#{minsize.to_s}: #{isosize.to_s} #{bootsize.to_s} #{efisize.to_s} #{padsize.to_s}"
		isoblocks = isosize / ( 1024 ** 2 * 8 ) + 1
		bootblocks = bootsize / ( 1024 ** 2 * 8 ) + 4
		efiblocks = efisize / ( 1024 ** 2 * 8 ) + 1
		return minsize, isoblocks, bootblocks, efiblocks, sysdev, sysmount 
	end
	
	def reread_drivelist(combobox, ignoredrive=nil)
		TileHelpers.set_lock 
		TileHelpers.umount_all
		100.downto(0) { |i| 
			begin
				combobox.remove_text(i) 
			rescue
			end
		}
		drives = Array.new
		auxdrives = Array.new
		Dir.entries("/sys/block").each { |l|
			auxdrives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ 
		}
		auxdrives.each { |d|
			if ignoredrive.nil?
				drives.push(d) unless d.mounted || d.usb == false || d.size < 3_500_000_000 
			else
				drives.push(d) unless d.device == ignoredrive.device || d.mounted || d.usb == false || d.size < 3_500_000_000 
			end
		}  
		drives.each { |d|
			label = label = "#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
			if d.usb == true
				label = label + " (USB)"
			else
				label = label + " (SATA/eSATA/IDE)"
			end
			combobox.append_text(label)
		}
		combobox.append_text(@tlx.get_translation("nodrivecombo")) if drives.size < 1 
		combobox.active = 0
		combobox.sensitive = false
		combobox.sensitive = true if drives.size > 0
		TileHelpers.remove_lock
 		return drives
	end
	
	def create_progress_screen(extlayers)
		fixed = Gtk::Fixed.new
		killswitch = TileHelpers.place_back(fixed, extlayers, false)
		tile = Gtk::EventBox.new.add Gtk::Image.new("usbgreen.png")
		deltext = TileHelpers.create_label("<b>" + @tlx.get_translation("progresshead") + "</b>\n\n" + @tlx.get_translation("progressbody"), 510)
		@installprogress.width_request = 510
		@installprogress.height_request = 32
		killswitch.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# Some checks here!
				@killinstall = true 
			end
		}
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@installprogress, 0, 108)
		return fixed
	end
	
	def run_command(pgbar, command, args, text)
		TileHelpers.set_lock 
		puts "Running " + command + " : " + args.join(" ")  
		pgbar.text = text 
		vte = Vte::Terminal.new
		running = true
		vte.signal_connect("child_exited") { running = false }
		vte.fork_command(command, args)
		while running == true
			pgbar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
		end 
		TileHelpers.remove_lock
	end
	
	def run_installation(tgt, language, contsizes, pgbar, check=false) 
		TileHelpers.set_lock 
		sizes = calculate_min_size
		checklist = Array.new
		bootstart = sizes[1] * 8388608 
		efistart = ( sizes[1] + sizes[2] ) * 8388608
		bootend = efistart - 1  
		efiend = ( sizes[1] + sizes[2] + sizes[3]) * 8388608 - 1
		# blank the fist few MB
		# ddstr = "dd if=/dev/zero of=/dev/#{tgt.device} bs=1024 count=1024"
		run_command(pgbar, "dd", [ "dd", "if=/dev/zero", "of=/dev/#{tgt.device}", "bs=1024", "count=1024", "conv=fdatasync" ] , @tl.get_translation("preparing")) 
		system("sync") 
		if @killinstall == true
			TileHelpers.remove_lock 
			return false
		end
		# puts ddstr 
		# system ddstr 
		# blank the last few MB
		tgtblocks = tgt.size / 1024 - 1024 
		puts tgtblocks.to_s 	
		# ddstr = "dd if=/dev/zero of=/dev/#{tgt.device} bs=1024 seek=#{tgtblocks.to_s}"
		# puts ddstr 
		# system ddstr 
		run_command(pgbar, "dd", [ "dd", "if=/dev/zero", "of=/dev/#{tgt.device}", "bs=1024", "seek=#{tgtblocks.to_s}", "conv=fdatasync" ] , @tl.get_translation("preparing")) 
		system("sync") 
		# Copy the ISO image
		0.upto(sizes[1] - 1) { |b|
			if @killinstall == true
				TileHelpers.remove_lock 
				return false
			end
			TileHelpers.set_lock 
			system("rm /var/run/lesslinux/copyblock.bin")
			system("rm /var/run/lesslinux/checkblock.bin")
			system("dd if=#{sizes[4]} of=/var/run/lesslinux/copyblock.bin bs=8388608 count=1 skip=#{b.to_s} conv=fdatasync")
			md5in = ` md5sum /var/run/lesslinux/copyblock.bin `.strip.split[0] 
			md5out = ''
			tries = 0
			matched = false
			while tries < 9 && matched == false 
				system("dd of=/dev/#{tgt.device} if=/var/run/lesslinux/copyblock.bin bs=8388608 count=1 seek=#{b.to_s} conv=fdatasync")
				system("sync")
				system("dd if=/dev/#{tgt.device} of=/var/run/lesslinux/checkblock.bin bs=8388608 count=1 skip=#{b.to_s} conv=fdatasync")
				system("sync")
				md5out = ` md5sum /var/run/lesslinux/checkblock.bin `.strip.split[0]
				if md5in == md5out 
					matched = true
				else
					puts "ERROR WRITING #{b.to_s} - TRY #{tries.to_s}"
				end
				tries += 1 
			end
			
			# ddstr = "dd if=#{sizes[4]} of=/dev/#{tgt.device} bs=8388608 count=1 seek=#{b.to_s} skip=#{b.to_s}" 
			# puts ddstr 
			# system ddstr 
			percentage = b * 100 / ( sizes[1] - 1 ) 
			pgbar.text =  @tl.get_translation("installsys") + " - #{percentage.to_s}%"
			pgbar.fraction = b.to_f / ( sizes[1] - 1 ).to_f 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		}
		system("rm /var/run/lesslinux/copyblock.bin")
		system("rm /var/run/lesslinux/checkblock.bin")
		# Blank the first 32k 
		system("dd if=/dev/zero bs=8192 count=4 of=/dev/#{tgt.device}")
		system("sync")
		0.upto(25) { |n|
			pgbar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
		}
		# Create the boot partition legacy
		run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mklabel", "msdos" ] , @tl.get_translation("partitioning")) 
		system("sync")
		run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mkpart", "primary", "fat32", "#{bootstart}", "#{efiend}" ] , @tl.get_translation("partitioning")) 
		system("sync")
		run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "set", "1", "boot", "on" ] , @tl.get_translation("partitioning")) 
		run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "set", "1", "esp", "on" ] , @tl.get_translation("partitioning")) 
		system("sync")
		#run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mkpart", "primary", "fat32", "#{efistart}", "#{efiend}" ] , @tl.get_translation("partitioning")) 
		#system("sync")
		#run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "set", "2", "boot", "on" ] , @tl.get_translation("partitioning")) 
		#system("sync")
		0.upto(25) { |n|
			pgbar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
		}
		# run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mkpart", "primary", "fat32", "#{efistart}", "#{efiend}" ] , @tl.get_translation("partitioning")) 
		if @killinstall == true
			TileHelpers.remove_lock
			return false
		end
		# tar the content of the legacy boot part 
		# run_command(pgbar, "mkfs.ext2", [ "mkfs.ext2", "/dev/#{tgt.device}1" ] , @tl.get_translation("write_boot")) 
		system("dd if=/dev/zero bs=1M count=8 of=/dev/#{tgt.device}1") 
		system("sync")
		system( "mkfs.msdos -F 32 /dev/#{tgt.device}1") 
		system("sync")
		if @killinstall == true
			TileHelpers.remove_lock
			return false
		end
		# run_command(pgbar, "mkfs.ext2", [ "mkfs.ext2", "-L", "LLDataExtra", "/dev/#{tgt.device}3" ] , @tl.get_translation("write_boot")) 
		system("mkdir -p /var/run/lesslinux/install_boot")
		if @killinstall == true
			TileHelpers.remove_lock
			reutrn false
		end
		# run_command(pgbar, "dd", [ "dd", "if=#{sizes[5]}/boot/efi/efi.img", "of=/dev/#{tgt.device}2", "conv=fdatasync"  ], @tl.get_translation("write_boot")) 
		#system( "dd if=#{sizes[5]}/boot/efi/efi.img of=/dev/#{tgt.device}2 conv=fdatasync" )
		#system("sync")
		if @killinstall == true
			TileHelpers.remove_lock 
			return false
		end
		system("mount -t vfat /dev/#{tgt.device}1 /var/run/lesslinux/install_boot")
		sleep 0.5
		system("sync")
		run_command(pgbar, "rsync", [ "rsync", "-avHP", "--inplace", "#{sizes[5]}/boot", "/var/run/lesslinux/install_boot/" ] , @tl.get_translation("write_boot")) 
		if optical? == true
			if is64? == true
				system("cp -v #{sizes[5]}/boot/kernel/ldefsf /tmp/kernel")
				system("gunzip -c #{sizes[5]}/boot/kernel/idefsf.img #{sizes[5]}/boot/kernel/initram.img | gzip -c > /tmp/initrd")
			else
				system("cp -v #{sizes[5]}/boot/kernel/ldefvn /tmp/kernel")
				system("gunzip -c #{sizes[5]}/boot/kernel/idefvn.img #{sizes[5]}/boot/kernel/initram.img | gzip -c > /tmp/initrd")
			end
		end
		system("rm /var/run/lesslinux/install_boot/boot/efi/efi.img") 
		# system("chmod -R 0644 /var/run/lesslinux/install_boot/")
		system("mkdir -p /var/run/lesslinux/install_efi")
		system("mount -o ro,loop #{sizes[5]}/boot/efi/efi.img /var/run/lesslinux/install_efi")
		run_command(pgbar, "rsync", [ "rsync", "-avHP", "--inplace", "/var/run/lesslinux/install_efi/", "/var/run/lesslinux/install_boot/" ] , @tl.get_translation("write_boot")) 
		sleep 0.5
		system("sync")
		system("umount /var/run/lesslinux/install_efi")
		# system("mount -t vfat /dev/#{tgt.device}2 /var/run/lesslinux/install_efi")
		# Find and move config files 
		cfgfiles = Array.new
		IO.popen("find /var/run/lesslinux/install_boot/boot -name '*.cfg'") { |line|
			while line.gets
				cfgfiles.push $_.strip
			end
		}
		IO.popen("find /var/run/lesslinux/install_boot -name '*.conf'") { |line|
			while line.gets
				cfgfiles.push $_.strip
			end
		}
		cfgfiles.push("/var/run/lesslinux/install_boot/boot/isolinux/syslinux.cfg") if File.exists? ("/var/run/lesslinux/install_boot/boot/isolinux/syslinux.cfg") 
		cfgfiles.each { |fname|
			puts "Editing: " + fname 
			system("cp -v #{fname}.#{language} #{fname}") if File.exists?("#{fname}.#{language}") 
			system("sed -i 's/homecont=0000-00000/homecont=#{contsizes.min.to_s}-#{contsizes.max.to_s}/g' #{fname}") if contsizes.max > 0 
			if tgt.size > 15_000_000_000
				system("sed -i 's/swapsize=0000/swapsize=1024/g' #{fname}")
				system("sed -i 's/blobsize=0000/blobsize=3072/g' #{fname}")
			else
				system("sed -i 's/swapsize=0000/swapsize=512/g' #{fname}")
				system("sed -i 's/blobsize=0000/blobsize=768/g' #{fname}")
			end
			system("rm #{fname}") if fname =~ /boot0x80\.cfg$/ 	
		}
		system("cp -v /var/run/lesslinux/install_boot/boot/isolinux/{isolinux.cfg,syslinux.cfg}") unless File.exists? ("/var/run/lesslinux/install_boot/boot/isolinux/syslinux.cfg") 
		# Write syslinux
		system("extlinux --install /var/run/lesslinux/install_boot/boot/isolinux") 
		system("umount /var/run/lesslinux/install_boot")
		# system("umount /var/run/lesslinux/install_efi")
		# Write the compat MBR
		sysstr = "dd if=/usr/share/syslinux/mbr.bin of=/dev/#{tgt.device}"	
		system("sync") 
		puts sysstr
		system sysstr
		pgbar.fraction = 1.0
		pgbar.text =  @tl.get_translation("install_finished") 
		# info_dialog( @tl.get_translation("finished_title"), @tl.get_translation("finished_text") ) 
		TileHelpers.remove_lock
	end
	
	
	
end








