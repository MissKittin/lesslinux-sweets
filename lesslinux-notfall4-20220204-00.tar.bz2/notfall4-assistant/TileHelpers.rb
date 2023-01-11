#!/usr/bin/ruby
# encoding: utf-8

class TileHelpers
	def TileHelpers.place_back(panel, layers, connect=true)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "TileHelpers.xml")
		text = Gtk::Label.new
		text.width_request = 250
		text.wrap = true
		text.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		#panel.put(back, 852, 332)
		#panel.put(text, 605, 338)
		panel.put(back, 650, 402)
		panel.put(text, 402, 408)
		if connect == true
			back.signal_connect('button-release-event') { |x, y|
				if y.button == 1 
					layers.each { |k,v|v.hide_all }
					layers["pleasewait"].show_all unless layers['pleasewait'].nil? 
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					TileHelpers.umount_all
					layers.each { |k,v|v.hide_all }
					TileHelpers.back_to_group 
					TileHelpers.remove_lock 
				end
			}
		end
		return back
	end
	
	def TileHelpers.back_to_group
		$rightboxes.each { |b| 
			b.each { |w| w.hide_all } 
		}
		$rightboxes[$rightactivebox].each { |b| b.show_all }
		$groupnames[$rightactivebox].show_all 
		TileHelpers.remove_lock 
	end
	
	
	def TileHelpers.create_label(text, width)
		label = Gtk::Label.new
		label.width_request = width
		label.wrap = true
		label.set_markup("<span color='white'>" + text + "</span>")
		return label
	end
	
	def TileHelpers.set_lock
		lock = File.new("/var/run/lesslinux/leftlocked.txt", "w+")
		lock.write("locked!\n")
		lock.close
	end
	
	def TileHelpers.get_lock
		return File.exists?("/var/run/lesslinux/leftlocked.txt")
	end
	
	def TileHelpers.remove_lock
		begin 
			File.unlink("/var/run/lesslinux/leftlocked.txt")
		rescue 
			$stderr.puts("No lock to remove!")
		end
	end
	
	def TileHelpers.error_dialog(message, title="none")
		title = @tl.get_translation("error") if title == "none" 
		dialog = Gtk::Dialog.new(title,
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ] )
		dialog.has_separator = false
		label = Gtk::Label.new(message)
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image);
		hbox.pack_start_defaults(label);
			     
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run do |response|
			# finito
		end
		dialog.destroy
	end
	
	def TileHelpers.success_dialog(message, title="none")
		title = @tl.get_translation("success") if title == "none" 
		dialog = Gtk::Dialog.new(title,
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ] )
		dialog.has_separator = false
		label = Gtk::Label.new(message)
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image);
		hbox.pack_start_defaults(label);
			     
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run do |response|
			# finito
		end
		dialog.destroy
	end
	
	def TileHelpers.password_dialog(pwtext, link=nil)
		dialog = Gtk::Dialog.new(
			@tl.get_translation("pwtitle"),
			nil,
			Gtk::Dialog::MODAL,
			[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ],
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.default_response = Gtk::Dialog::RESPONSE_OK
		question  = Gtk::Label.new(pwtext)
		question.wrap = true 
		
		# question.height_request = 32
		entry_label = Gtk::Label.new(@tl.get_translation("pwpassword"))

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
		infobutton = Gtk::Button.new(@tl.get_translation("read"))
		unless link.nil? 
			hbox.pack_start_defaults(infobutton)
		end
		infobutton.signal_connect("clicked") {
			system("su surfer -c \"firefox http://go.microsoft.com/fwlink/p/?LinkId=237614\" &")
		}
		dialog.vbox.add(question)
		dialog.vbox.add(hbox)
		dialog.show_all
		success = false
		password = ""
		
		# dialog.action_area.add_child(Gtk::Builder.new, infobutton) unless link.nil?
		dialog.run do |response|
			if response == Gtk::Dialog::RESPONSE_OK
				success = true
				password = pass.text
			end
			dialog.destroy
		end
		return success, password
	end
	
	def TileHelpers.open_pdf(pdfname)
		system("evince '" + pdfname + "' & ")
	end
	
	def TileHelpers.mount_usbdata
		c = caller
		$stderr.puts "TileHelpers.mount_usbdata called from: "
		c.each { |l| $stderr.puts l }
		mnt = nil
		freespace = -1 
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		drives.each { |d|
			if d.usb == true
				d.partitions.each { |p|
					mnt = p.mount_point
					if p.label == "USBDATA"
						p.mount("rw", nil, 1000, 1000) if mnt.nil?
						mnt = p.mount_point
						unless mnt.nil?
							system("mkdir -p #{mnt[0]}/Downloads")
							system("mkdir -p /home/surfer/Downloads")
							system("mkdir -p #{mnt[0]}/Anleitungen")
							# FIXME translate
							system("rsync -avHP /usr/share/lesslinux/notfallcd4/Anleitungen/ #{mnt[0]}/Anleitungen/")
							system("rsync -avHP /lesslinux/cdrom/shutdown.bat #{mnt[0]}/")
							system("rsync -avHP /lesslinux/isoloop/shutdown.bat #{mnt[0]}/")
							system("chown surfer:surfer /home/surfer/Downloads")
							system("mount --bind #{mnt[0]}/Downloads /home/surfer/Downloads") unless system("mountpoint /home/surfer/Downloads")
							freespace = p.free_space
							return mnt, freespace
						end
					end
				}
			end
		}
		return mnt, freespace 
	end
	
	
	def TileHelpers.umount_all
		c = caller
		$stderr.puts "TileHelpers.umount_all called from: "
		c.each { |l| $stderr.puts l }
		$stderr.puts "Unmount everything first!"
		system("umount /home/surfer/Downloads")
		system("umount /tmp/Outlook-Import")
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		IO.popen("losetup -a") { |l|
			while l.gets
				ltoks = $_.strip.split
				system("losetup -d " + ltoks[0].gsub(":", "")) unless ltoks[2] =~ /^\(\/lesslinux\// || ltoks[2] =~ /^\(\/opt\/teamviewer\// || ltoks[2] =~ /^\(\/AntiVir\//
			end
		}
		drives.each { |d|
			d.partitions.each { |p|
				mnt = p.mount_point
				unless mnt.nil?
					p.umount if mnt[0].to_s =~ /^\/media\/disk/ || mnt[0].to_s =~ /^\/cobi\//
					begin
						p.vss_umount_all 
					rescue
					end
				end
			}
		}
		drives.each { |d|
			d.partitions.each { |p|
				mnt = p.mount_point
				unless mnt.nil?
					p.force_umount if mnt[0].to_s =~ /^\/media\/disk/ || mnt[0].to_s =~ /^\/cobi\// 
				end
			}
		}
		[ "/cobi", "/media/disk" ].each { |d|
			if File.directory?(d)
				Dir.entries(d).each { |f|
					if File.directory?(d + "/" + f) && !f.eql?(".") && !f.eql?("..")
						begin
							Dir.unlink(d + "/" + f)
						rescue
						end
					end
				}
			end
		}
	end
	
	def TileHelpers.cloud_count
		c = 0
		File.new("/proc/mounts").read.split("\n").each { |line|
			ltoks = line.strip.split
			if ltoks[1] =~ /^\/media\/webdav\// || ltoks[1] =~ /^\/media\/cifs\// || ltoks[1] =~ /^\/media\/cloud\//
				c += 1
			end
		}
		return c 
	end
	
	def TileHelpers.umount_cloud
		File.new("/proc/mounts").read.split("\n").each { |line|
			ltoks = line.strip.split
			if ltoks[1] =~ /^\/media\/webdav\// || ltoks[1] =~ /^\/media\/cifs\// || ltoks[1] =~ /^\/media\/cloud\//
				system("umount #{ltoks[1]}")
			end
		}
	end
	
	def TileHelpers.open_browser(url)
		system("su surfer -c 'firefox #{url}' &") 
	end
	
	def TileHelpers.yes_no_dialog(message, title="none")
		title = @tl.get_translation("question") if title == "none" 
		moveon = false
		dialog = Gtk::Dialog.new(
			title,
			$main_application_window,
			Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ],
			[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ]	
		)
		dialog.default_response = Gtk::Dialog::RESPONSE_CANCEL
		dialog.has_separator = false
		label = Gtk::Label.new
		label.wrap = true
		label.set_markup(message)
		image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image);
		hbox.pack_start_defaults(label);
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run { |resp|
			if resp == Gtk::Dialog::RESPONSE_OK
				moveon = true
			end
			dialog.destroy
		}
		return moveon	
	end
	
	def TileHelpers.progress(pgbar, command, text)
		puts "Running " + command[0] + " : " + command.join(" ")  
		pgbar.text = text 
		vte = Vte::Terminal.new
		running = true
		vte.signal_connect("child_exited") { running = false }
		vte.fork_command(command[0], command)
		cycle = 0
		while running == true
			pgbar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			if cycle % 10 == 0
				t = vte.get_text(false)
				puts t 
			end
			sleep 0.2 
			cycle += 1 
		end
	end	
	
	def TileHelpers.vcrypt_wrapper(cicon, oicon)
		usbdata, freespace = TileHelpers.mount_usbdata
		blocknum = freespace / 2048
		blocknum = 4000000 if blocknum > 4000000
		puts usbdata.to_s 
		if usbdata.nil?
			TileHelpers.error_dialog(@tl.get_translation("vcstickonly")) 
			return false 
		end
		# Check whether there is a vera crypt container available
		if File.exists?("#{usbdata[0]}/tresor.hc")
			# A container is available but mounted, start Thunar
			if system("mountpoint -q /media/tresor")
				# Unmount or show filemanager?
				if TileHelpers.yes_no_dialog(@tl.get_translation("vcmounted"))
					TileHelpers.mount_all
					system("su surfer -c \"Thunar /media/tresor\" &")
				else
					# A container is available, unmount requested
					system("veracrypt -t -d /media/tresor")
					system("umount -f /media/tresor")
					system("veracrypt -t -d /media/tresor")
					system("dmsetup remove /dev/mapper/veracrypt1")
				end
			else
				# A container is available, but not mounted, ask for password
				succ, pass = TileHelpers.password_dialog(@tl.get_translation("vcpassword"), link=nil)
				if succ == true
					system("touch /var/run/createvccontainer")
					system("ruby -I . pgbar.rb &")
					system("mkdir /media/tresor")
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					system("veracrypt -t -k \"\" --pim=0 --filesystem=none --password=\"#{pass}\" --protect-hidden=no \"#{usbdata[0]}/tresor.hc\" /media/tresor")
					system("mount -t vfat -o uid=1000,gid=1000 /dev/mapper/veracrypt1 /media/tresor")
					system("rm -f /var/run/createvccontainer")
					# system("su surfer -c 'Thunar /media/tresor' &")
					if system("mountpoint -q /media/tresor")
						TileHelpers.mount_all
						system("su surfer -c \"Thunar /media/tresor\" &")
					else
						TileHelpers.error_dialog(@tl.get_translation("vcbroken"))
					end
				end
			end
		else
			# A container is  not available, ask for password
			succ, pass = TileHelpers.password_dialog(@tl.get_translation("vcnewpassword"), link=nil)
			if succ == true
				system("touch /var/run/createvccontainer")
				system("ruby -I . pgbar.rb &")
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				system("veracrypt -t --create \"#{usbdata[0]}/tresor.hc\" --password \"#{pass}\" --hash sha512 --encryption AES --filesystem fat --volume-type normal -k \"\" --pim=0 --size=#{blocknum}k --random-source=/dev/urandom") 
				system("mkdir /media/tresor")
				system("veracrypt -t -k \"\" --pim=0 --filesystem=none --password=\"#{pass}\" --protect-hidden=no \"#{usbdata[0]}/tresor.hc\" /media/tresor")
				system("mount -t vfat -o uid=1000,gid=1000 /dev/mapper/veracrypt1 /media/tresor")
				TileHelpers.mount_all
				system("rm -f /var/run/createvccontainer")
				# system("su surfer -c 'Thunar /media/tresor' &")
				system("su surfer -c \"Thunar /media/tresor\" &")
			else 
				TileHelpers.error_dialog(@tl.get_translation("vcfailed"))
			end
		end
		cicon.hide_all
		oicon.hide_all
		if system("mountpoint /media/tresor")
			oicon.show_all
		else
			cicon.show_all
		end
	end
	
	def TileHelpers.mount_all(writeable_part=nil, vssmount=false, normalmount=true)
		begin
			bookmarks = File.new("/home/surfer/.gtk-bookmarks", "w")
		rescue
			bookmarks = File.new("/tmp/.gtk-bookmarks", "w")
		end
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		TileHelpers.umount_all
		drives.each { |d|
			d.partitions.each { |p|
				pmnt = p.mount_point
				if pmnt.nil?
					$stderr.puts "#{p.device} vs. #{writeable_part}" 
					# p.umount 
					if p.device.strip == writeable_part.to_s.strip
						$stderr.puts "Match!"
						system("mkdir -p /cobi/" + @tl.get_translation("backupdir")) 
						p.mount("rw", "/cobi/" + @tl.get_translation("backupdir"), 1000, 1000)
						bookmarks.write("file:///cobi/" + @tl.get_translation("backupdir") + "\n")
					else
						if normalmount == true
							if p.fs =~ /bitlocker/
								$stderr.puts("Ignore Bitlocker here")
							else
								system("mkdir -p /media/disk/#{p.device}")
								p.mount("ro", "/media/disk/#{p.device}", 1000, 1000)
								bookmarks.write("file:///media/disk/#{p.device}\n")
							end
						end
						if vssmount == true && p.vss? == true
							p.vss_mount_all 
						end
					end
				end
			}
		}
		bookmarks.close
		system("chown 1000:1000 /home/surfer/.gtk-bookmarks")
	end
	
end







