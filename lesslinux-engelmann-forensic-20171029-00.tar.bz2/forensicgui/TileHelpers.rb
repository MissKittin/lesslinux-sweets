#!/usr/bin/ruby
# encoding: utf-8

class TileHelpers
	 
	def TileHelpers.create_label(text, width)
		label = Gtk::Label.new
		label.width_request = width
		label.wrap = true
		label.set_markup(text) 
		return label
	end
	
	def TileHelpers.error_dialog(message, title="none")
		title = @tl.get_translation("error") if title == "none" 
		TileHelpers.success_dialog(message, title)
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
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ 
		}
		drives.each { |d|
			if d.usb == true
				d.partitions.each { |p|
					mnt = p.mount_point
					if p.label == "USBDATA" && mnt.nil?
						p.mount("rw", nil, 1000, 1000)
						mnt = p.mount_point
						unless mnt.nil?
							system("mkdir -p #{mnt[0]}/Downloads")
							system("mkdir -p /home/surfer/Downloads")
							system("mkdir -p #{mnt[0]}/Anleitungen")
							system("rsync -avHP /lesslinux/cdrom/shutdown.bat #{mnt[0]}/")
							system("rsync -avHP /lesslinux/isoloop/shutdown.bat #{mnt[0]}/")
							system("chown surfer:surfer /home/surfer/Downloads")
							system("mount --bind #{mnt[0]}/Downloads /home/surfer/Downloads")
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
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ 
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
end







