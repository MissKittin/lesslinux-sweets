#!/usr/bin/ruby
# encoding: utf-8

class FfRescueScreen	
	def initialize(extlayers, button, nwscreen)
		
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "FfRescueScreen.xml")
		@layers = Array.new
		
		@lastpulse = Time.now.to_f 
		
		#### Table for single partitions
		@parttable = nil
		# list of drives
		@partdrives = Array.new
		# shown partitions
		@partparts = Array.new
		# headers
		@partheaders = Array.new
		# checkboxes
		@partchecks = Array.new
		# labels
		@partlabels = Array.new
		
		@nwscreen = nwscreen 
		
		passhtml = "/usr/share/lesslinux/notfallcd4/password.html"
		fullhtml = "/usr/share/lesslinux/notfallcd4/password-full.html"
		passhtml = "/usr/share/lesslinux/notfallcd4/password.#{lang}.html" if File.exists? "/usr/share/lesslinux/notfallcd4/password.#{lang}.html"
		fullhtml = "/usr/share/lesslinux/notfallcd4/password-full.#{lang}.html" if File.exists? "/usr/share/lesslinux/notfallcd4/password-full.#{lang}.html"
		
		#### Table to show mailboxes 
		pstpartlist = nil
		@flatproflist = nil
		
		#### Panel for selection of partitions
		
		fixed = Gtk::Fixed.new
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		logotile = Gtk::Image.new("firefoxneutral.png")
		bodytext = TileHelpers.create_label("<b>" + @tl.get_translation("ffhead") + "</b>\n\n" + @tl.get_translation("ffbody") , 700)
		
		delscroll = Gtk::ScrolledWindow.new
		delscroll.height_request = 220
		delscroll.width_request = 700
		delscroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC ) 
		@parttable = Gtk::Table.new(2, 11, false)
		align = Gtk::Alignment.new(0, 0, 0.1, 0.1)
		align.add @parttable
		delscroll.add_with_viewport align
		anc = @parttable.get_ancestor(Gtk::Viewport)
		# anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#052f4c') )
		
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		# fixed.put(logotile, 0, 0)
		fixed.put(bodytext, 0, 0)
		fixed.put(delscroll, 0, 110)
		TileHelpers.place_back(fixed, extlayers)
		
		#### Panel for selection of found profiles
		
		selfixed = Gtk::Fixed.new
		selnext = Gtk::Label.new
		selnext.width_request = 230
		selnext.wrap = true
		selnext.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		selforw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		sellogotile = Gtk::Image.new("firefoxneutral.png")
		selbodytext = TileHelpers.create_label("<b>" + @tl.get_translation("ffselhead") + "</b>\n\n" + @tl.get_translation("ffselbody") , 700)
		
		selcombo = Gtk::ComboBox.new
		selcombo.width_request = 700
		selradio1 = Gtk::RadioButton.new
		selradio2 = Gtk::RadioButton.new(selradio1)
		selonlypass = TileHelpers.create_label(@tl.get_translation("onlypasswords"), 400)
		selwholeprof = TileHelpers.create_label(@tl.get_translation("wholeprofile"), 400)
		
		selfixed.put(selforw, 650, 352)
		selfixed.put(selnext, 402, 358)
		# selfixed.put(sellogotile, 0, 0)
		selfixed.put(selbodytext, 0, 0)
		selfixed.put(selradio1, 0, 120)
		selfixed.put(selradio2, 0, 150)
		selfixed.put(selonlypass, 30, 120)
		selfixed.put(selwholeprof, 30, 150)
		selfixed.put(selcombo, 0, 200)
		TileHelpers.place_back(selfixed, extlayers)
		
		# Finishing screen 
		
		finfixed =  Gtk::Fixed.new
		finbodytext = TileHelpers.create_label("<b>" + @tl.get_translation("ffprofdonehead") + "</b>\n\n" + @tl.get_translation("ffprofdonebody") , 510)
		fintile = Gtk::Image.new("firefoxneutral.png")
		# finfixed.put(fintile, 0, 0)
		finfixed.put(finbodytext, 0, 0)
		TileHelpers.place_back(finfixed, extlayers)
		ffbutton =Gtk::Button.new(@tl.get_translation("openfirefox"))
		ffbutton.width_request = 150
		ffbutton.height_request = 32
		finfixed.put(ffbutton, 365, 160)
		
		extlayers["firefoxpartlist"] = fixed
		@layers[0] = extlayers["firefoxpartlist"] 
		extlayers["firefoxproflist"] = selfixed
		@layers[1] = extlayers["firefoxproflist"] 
		extlayers["firefoxfinish"] = finfixed
		@layers[2] = extlayers["firefoxfinish"] 
		
		# Event for tile
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				# Read drivelist
				@partdrives, @partparts, @partheaders, @partchecks, @partlabels = fill_part_tab(@parttable, @partheaders, @partchecks, @partlabels)
				extlayers.each { |k,v|v.hide_all }
				extlayers["firefoxpartlist"].show_all
			end
		}
		
		# Event for forward button
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				checks = 0
				@partchecks.each { |p|
					checks += 1 if p.active? 
				}
				if checks < 1
					TileHelpers.error_dialog(@tl.get_translation("please_select_partition"))
				else
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					pstpartlist = find_profile_dirs(@partparts, @partchecks)
					@flatproflist = fill_prof_combo(pstpartlist, selcombo) 
					extlayers.each { |k,v|v.hide_all }
					extlayers["firefoxproflist"].show_all
				end
			end
		}
		
		# Even for last forward button
		selforw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @flatproflist.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("please_select_profile"))
				else				
					puts @flatproflist[selcombo.active][0].device + " " + @flatproflist[selcombo.active][1]
					sync_firefox_pass(@flatproflist[selcombo.active], selradio1)
					if @nwscreen.test_connection == false
						extlayers.each { |k,v|v.hide_all }
						@nwscreen.nextscreen = "firefoxfinish"
						@nwscreen.fill_wlan_combo 
						# Check for networks first...
						extlayers["networks"].show_all
						# FIXME: Properly start FF
						TileHelpers.mount_usbdata
					else
						extlayers.each { |k,v|v.hide_all }
						extlayers["pleasewait"].show_all
						while (Gtk.events_pending?)
							Gtk.main_iteration
						end
						TileHelpers.mount_usbdata
						extlayers.each { |k,v|v.hide_all }
						if selradio1.active?
							system("nohup su surfer -c 'firefox file://#{fullhtml}' &")
						else
							system("nohup su surfer -c 'firefox file://#{passhtml}' &")
						end
						extlayers["firefoxfinish"].show_all
					end
				end
			end
		}
		
		ffbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 && selradio1.active?
				system("su surfer -c 'firefox file://#{passhtml}' &") 
			elsif y.button == 1
				system("su surfer -c 'firefox file://#{fullhtml}' &") 
			end
		}
		
	end
	
	attr_reader :layers
	
	def prepare_firefoxpartlist
		# Read drivelist
		@partdrives, @partparts, @partheaders, @partchecks, @partlabels = fill_part_tab(@parttable, @partheaders, @partchecks, @partlabels)
	end
	
	def fill_part_tab(table, oldheaders, oldchecks, oldlabels)
		TileHelpers.set_lock 
		TileHelpers.umount_all
		table.row_spacings = 4
		parts = Array.new
		headers = Array.new
		drives = Array.new
		checks = Array.new
		labels = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		oldheaders.each { |h| table.remove h }
		oldlabels.each{ |l| table.remove l } 
		oldchecks.each{ |c| table.remove c } 
		
		table.resize(drives.size * 100, 2)
		rowcount = 0
		drives.each { |d|
			label = "<b>#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
			if d.usb == true
				label = label + " (USB)</b>\n"
			else
				label = label + " (SATA/eSATA/IDE)</b>\n"
			end
			l = TileHelpers.create_label(label, 670)
			l.height_request = 17
			headers.push l
			table.attach(l, 0, 2, rowcount, rowcount+1)
			rowcount += 1
			d.partitions.each { |p|
				unless p.fs.to_s.strip == ""
					pt = "#{p.device} - #{p.human_size} - #{p.fs}"
					mnt, opt = p.mount_point
					iswin, winvers = p.is_windows
					pt = pt + " - " + winvers if iswin
					if p.system_partition? == true
						pt = @tl.get_translation("notesystem").gsub("PARTITIONNAME", pt) 
					elsif mnt.nil? == false
						pt = @tl.get_translation("noteinuse").gsub("PARTITIONNAME", pt) 
					end
					pl = TileHelpers.create_label(pt, 650)
					cb = Gtk::CheckButton.new
					cb.active = true if p.fs =~ /ntfs/ || p.fs =~ /vfat/  
					cb.active = false unless mnt.nil?
					cb.sensitive = false unless mnt.nil? 
					labels.push pl
					checks.push cb
					parts.push p
					table.attach(pl, 1, 2, rowcount, rowcount+1)
					table.attach(cb, 0, 1, rowcount, rowcount+1)
					rowcount += 1
					table.resize(rowcount, 2)
				end
			}
			
		}
		TileHelpers.remove_lock 
		return drives, parts, headers, checks, labels
	end
	
	def find_profile_dirs(parts, checks)
		TileHelpers.set_lock 
		pstpartlist = Hash.new
		dwin = Gtk::Window.new
		dwin.set_default_size(400, 40)
		pgbar = Gtk::ProgressBar.new
		pgbar.width_request = 300
		dwin.add(pgbar)
		dwin.deletable = false
		dwin.title = @tl.get_translation("be_patient")
		dwin.show_all
		0.upto(parts.size - 1) { |n|
			if checks[n].active? 
				parts[n].mount
				puts parts[n].mount_point[0]
				pstlist = traverse_for_profiles(parts[n].mount_point[0], parts[n].mount_point[0], pgbar) 
				pstpartlist[parts[n]] = pstlist if pstlist.size > 0 
				parts[n].umount
			end
		}
		dwin.destroy 
		TileHelpers.remove_lock
		return pstpartlist 
	end
	
	def traverse_for_profiles(startdir, basedir, pgbar) 
		TileHelpers.set_lock 
		proflist = Array.new
		Dir.entries(startdir).each { |e|
			now = Time.now.to_f
			if now - @lastpulse > 0.2 
				pgbar.text =  @tl.get_translation("traversing") +" " + e  
				pgbar.pulse
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				@lastpulse = now
			end
			# puts "Parsing #{startdir}/#{e}"
			if e == "." || e == ".."
				# puts "Ignore directory #{e}"
			elsif File.symlink? "#{startdir}/#{e}"
				puts "Ignore symlink #{e}"
			elsif File.directory? "#{startdir}/#{e}" 
				proflist = proflist + traverse_for_profiles("#{startdir}/#{e}", basedir, pgbar) 
			elsif File.file?("#{startdir}/#{e}") && (e =~ /^signons.*\.txt$/i ||  e == "signons.sqlite" || e == "key.db" ||   e == "key3.db" ||  e == "logins.json"  || e == "key4.db" || e == "cert9.db"  )
				proflist.push(startdir.gsub(basedir, "") )
			end
		}
		TileHelpers.remove_lock
		return proflist.uniq 
	end
	
	def fill_prof_combo(profpartlist, selcombo) 
		flatlist = Array.new
		1000.downto(0) { |n|
			begin
				selcombo.remove_text(n)
			rescue
			end
		}
		profpartlist.each { |k,v|
			v.each { |p|
				flatlist.push( [ k, p ] ) 
				selcombo.append_text(k.device + " " + p )
			}
		}
		if flatlist.size < 1
			selcombo.append_text(@tl.get_translation("no_profile_found"))
			selcombo.sensitive = false
		else
			selcombo.sensitive = true
		end
		selcombo.active = 0 
		return flatlist 
	end
	
	def sync_firefox_pass(device_path, radio)
		TileHelpers.set_lock 
		device_path[0].mount
		mntpnt = device_path[0].mount_point[0] 
		usbmnt, freespace = TileHelpers.mount_usbdata
		if radio.active?
			[ "signons1.txt", "signons2.txt", "signons3.txt", "signons.sqlite", "key.db", "key3.db", "key4.db", "logins.json", "cert9.db" ].each { |f|
				system("rsync -avHP \"#{mntpnt}/#{device_path[1]}/#{f}\" /home/surfer/.mozilla/firefox/u94f9t7o.default/")
			}
		else
			system("rsync -avHP \"#{mntpnt}/#{device_path[1]}/\" /home/surfer/.mozilla/firefox/u94f9t7o.default/")
		end
		unless usbmnt.nil?
			if TileHelpers.yes_no_dialog(@tl.get_translation("savetostick") )
				# FIXME translate
				[ "signons1.txt", "signons2.txt", "signons3.txt", "signons.sqlite", "key.db", "key3.db", "key4.db", "logins.json", "cert9.db" ].each { |f|
					system("rsync -avHP --inplace \"#{mntpnt}/#{device_path[1]}/#{f}\" \"/#{usbmnt[0]}/Firefox-Retter/\" ")
				}
			end
		end
		system("chown -R surfer:surfer /home/surfer/.mozilla/firefox/u94f9t7o.default") 
		device_path[0].umount
		TileHelpers.remove_lock 
	end
end