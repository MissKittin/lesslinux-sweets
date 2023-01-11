#!/usr/bin/ruby
# encoding: utf-8

class DeleteScreen
	
	def initialize(extlayers, button)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@lang = lang 
		@tl = MfsTranslator.new(lang, "DeleteScreen.xml")
		@layers = Array.new
		fixed = Gtk::Fixed.new
		#### Was the deletion cancelled?
		@deletecancelled = false
		#### Table for deletion of single partitions
		@parttable = nil
		# list of drives
		@partdrives = Array.new
		# shown partitions
		@partparts = Array.new
		@fullparts = Array.new
		# headers
		@partheaders = Array.new
		# checkboxes
		@partchecks = Array.new
		# labels
		@partlabels = Array.new
		#### Table for deletion of complete drives
		@drivetable = nil
		@drivedrives = Array.new
		@drivechecks = Array.new
		@drivelabels = Array.new
		#### Progress bar for deletion
		@deleteprogress = Gtk::ProgressBar.new
		@rubbprogress = Gtk::ProgressBar.new 
		#### Shred only free space
		@shredfreeonly = false 
		
		greentile = Gtk::EventBox.new.add Gtk::Image.new("deletelightgreennotext.png")
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("deleteorange.png")
		othertile = Gtk::EventBox.new.add Gtk::Image.new("deleteorange.png")
		reinsttext = TileHelpers.create_label("<b>" + @tl.get_translation("fasthead") + "</b>\n\n" + @tl.get_translation("fastbody"), 320)
		secdeltext = TileHelpers.create_label("<b>" + @tl.get_translation("fullhead") + "</b>\n\n" + @tl.get_translation("fullbody"), 320)
		rubbishtext = TileHelpers.create_label("<b>" + @tl.get_translation("rubbishhead") + "</b>\n\n" + @tl.get_translation("rubbishbody"), 320)
		clearfreetext = TileHelpers.create_label("<b>" + @tl.get_translation("clearfreehead") + "</b>\n\n" + @tl.get_translation("clearfreebody"), 320)
		anothertile = Gtk::EventBox.new.add Gtk::Image.new("deletelightgreennotext.png")

		fixed.put(orangetile, 0, 0)
		fixed.put(greentile, 0, 130)
		fixed.put(othertile, 460, 130)
		fixed.put(anothertile, 460, 0)
		
		fixed.put(secdeltext, 130, 0)
		fixed.put(reinsttext, 130, 130) 
		fixed.put(rubbishtext, 590, 130) 
		fixed.put(clearfreetext, 590, 0) 
		
		TileHelpers.place_back(fixed, extlayers)
		
		### Layer for deletion of single partitions
		
		green2tile = Gtk::EventBox.new.add Gtk::Image.new("deletegreen.png")
		fixeddelete = Gtk::Fixed.new
		TileHelpers.place_back(fixeddelete, extlayers)
		delscroll = Gtk::ScrolledWindow.new
		delscroll.height_request = 220
		delscroll.width_request = 700
		delscroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC ) 
		# fixeddelete.put(green2tile, 0, 0)
		fixeddelete.put(delscroll, 0, 110)
		@drivetext = TileHelpers.create_label("<b>" + @tl.get_translation("parthead") + "</b>\n\n" + @tl.get_translation("partbody"), 510)
		# fixeddelete.put(@drivetext, 0, 0)
		@cleantext = TileHelpers.create_label("<b>" + @tl.get_translation("cleanhead") + "</b>\n\n" + @tl.get_translation("cleanbody"), 510)
		fixeddelete.put(@cleantext, 0, 0)
		# Table for drives
		@parttable = Gtk::Table.new(2, 11, false)
		align = Gtk::Alignment.new(0, 0, 0.1, 0.1)
		align.add @parttable
		delscroll.add_with_viewport align
		# delscroll.add drivetab
		anc = @parttable.get_ancestor(Gtk::Viewport)
		anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#052f4c') )
		anc.modify_fg(Gtk::STATE_NORMAL, Gdk::Color.parse('#052f4c') )
		anc.modify_text(Gtk::STATE_NORMAL, Gdk::Color.parse('#ffffff') )
		# puts anc.to_s
		# Forward button:
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("deletenow") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		fixeddelete.put(forw, 650, 352)
		fixeddelete.put(text5, 402, 358)
		# End forward button
		forw.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				msg = @tl.get_translation("confirmbody")
				msg = @tl.get_translation("confirmshredder") if @shredfreeonly == true 
				if TileHelpers.yes_no_dialog( msg, @tl.get_translation("confirmhead"))
					extlayers.each { |k,v|v.hide_all }
					extlayers["deleteprogress"].show_all
					# run dd to delete
					if @shredfreeonly == true
						run_shredder(@deleteprogress)
					else
						run_deletion(@deleteprogress, false)
					end
					unless @deletecancelled == true
						TileHelpers.success_dialog(@tl.get_translation("successbody"), @tl.get_translation("successhead"))
					else
						TileHelpers.success_dialog(@tl.get_translation("partialbody"), @tl.get_translation("partialhead"))
					end
					extlayers.each { |k,v|v.hide_all }
					TileHelpers.back_to_group
				end
			end
		}
		
		
		### Layer for progress of deletion
		
		fixedprogress = Gtk::Fixed.new
		winetile = Gtk::EventBox.new.add Gtk::Image.new("deletegreen.png")
		# fixedprogress.put(winetile, 0, 0)
		cancelbutton = TileHelpers.place_back(fixedprogress, extlayers, false)
		@deleteprogress.width_request = 510
		@deleteprogress.height_request = 32
		fixedprogress.put(@deleteprogress, 0, 120)
		progresstext = TileHelpers.create_label("<b>" + @tl.get_translation("runninghead") + "</b>\n\n" + @tl.get_translation("runningbody"), 510)
		fixedprogress.put(progresstext, 0, 0)
		
		cancelbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@deletecancelled = true
			end
		}
		
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["DEAD_deletestart"].show_all
			end
		}
		greentile.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				TileHelpers.umount_all
				@partdrives, @partparts, @partheaders, @partchecks, @partlabels, @fullparts  = fill_part_tab(@parttable, @partheaders, @partchecks, @partlabels)
				extlayers.each { |k,v|v.hide_all }
				@shredfreeonly = false
				@drivetext.show_all 
				extlayers["deletepartition"].show_all
				@cleantext.hide_all
			end
		}
		anothertile.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				@partdrives, @partparts, @partheaders, @partchecks, @partlabels, @fullparts = fill_part_tab(@parttable, @partheaders, @partchecks, @partlabels)
				extlayers.each { |k,v|v.hide_all }
				@shredfreeonly = true
				@cleantext.show_all 
				extlayers["deletepartition"].show_all
				@drivetext.hide_all
			end
		}
		orangetile.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				@drivedrives, @drivechecks, @drivelabels = fill_drive_tab(@drivetable, @drivechecks, @drivelabels)
				extlayers.each { |k,v|v.hide_all }
				extlayers["deletedrive"].show_all
			end
		}
		
		### Layer for selecting rubbish
		
		rubbishselect = Gtk::Fixed.new
		rubseltile = Gtk::EventBox.new.add Gtk::Image.new("deletegreen.png")
		# rubbishselect.put(rubseltile, 0, 0)
		rubselcancel = TileHelpers.place_back(rubbishselect, extlayers)
		
		rubseltext = TileHelpers.create_label("<b>" + @tl.get_translation("rubbishselecthead") + "</b>\n\n" + @tl.get_translation("rubbishselectbody"), 510)
		rubbishselect.put(rubseltext, 0, 0)
		
		# 3 checkboxes
		rubbishboxes = Array.new
		rubbishtexts = [ "Hängende Druckaufträge", "Temporäre Dateien", "Inhalt des Mülleimers" ] 
		rubbishtexts = [ "Wiszące zadania drukowania", "Pliki tymczasowe", "Zawartość Kosza" ]  if @lang == "pl" 
		0.upto(2) { |n|
			rubbishboxes.push Gtk::CheckButton.new 
			rubbishselect.put(rubbishboxes[n], 50, 100 + n * 24)
			lab = Gtk::Label.new
			# lab.width_request = 250
			lab.set_markup("<span color='white'>" + rubbishtexts[n] + "</span>")
			rubbishselect.put(lab, 80, 100 + n * 24)
		}
		rubbishboxes[0].active = true 
		
		# Forward button:
		text23 = Gtk::Label.new
		text23.width_request = 250
		text23.wrap = true
		text23.set_markup("<span color='white'>" + @tl.get_translation("deleterubbishnow") + "</span>")
		forw23  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		rubbishselect.put(forw23, 650, 352)
		rubbishselect.put(text23, 402, 358)
		
		
		
		### Layer for killing off rubbish
		
		rubbishprogress = Gtk::Fixed.new
		rubbtile = Gtk::EventBox.new.add Gtk::Image.new("deletegreen.png")
		# rubbishprogress.put(rubbtile, 0, 0)
		rubbishcancel = TileHelpers.place_back(rubbishprogress, extlayers)
		@rubbprogress.width_request = 510
		@rubbprogress.height_request = 32
		rubbishprogress.put(@rubbprogress, 0, 120)
		othertile.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["selectrubbish"].show_all
			end
		}
		rubbprogtext = TileHelpers.create_label("<b>" + @tl.get_translation("rubbishrunninghead") + "</b>\n\n" + @tl.get_translation("rubbishrunningbody"), 510)
		rubbishprogress.put(rubbprogtext, 0, 0)
		
		forw23.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				if rubbishboxes[0].active? || rubbishboxes[1].active? || rubbishboxes[2].active? 
					extlayers.each { |k,v|v.hide_all }
					extlayers["pleasewait"].show_all
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					extlayers.each { |k,v|v.hide_all }
					extlayers["deleterubbish"].show_all
					delete_rubbish(rubbishboxes, @rubbprogress) 
					extlayers.each { |k,v|v.hide_all }
					TileHelpers.back_to_group
				else
					TileHelpers.error_dialog("Bitte treffen Sie eine Auswahl!")
				end
			end
		}
		
		extlayers["DEAD_deletestart"] = fixed
		@layers[0] = fixed
		extlayers["deletepartition"] = fixeddelete
		@layers[1] = fixeddelete
		extlayers["deleteprogress"] = fixedprogress
		@layers[2] = fixedprogress
		
		drivelayer = create_drive_tab(extlayers)
		extlayers["deletedrive"] = drivelayer
		@layers[3] = drivelayer
		
		extlayers["selectrubbish"] = rubbishselect
		@layers[4] = rubbishselect
		
		extlayers["deleterubbish"] = rubbishprogress
		@layers[5] = rubbishprogress
		# @drivetext = drivetext
		# @cleantext = cleantext 
	end
	attr_reader :layers
	
	def prepare_deletepartition(shredfreeonly=false)
		@partdrives, @partparts, @partheaders, @partchecks, @partlabels, @fullparts = fill_part_tab(@parttable, @partheaders, @partchecks, @partlabels)
		@shredfreeonly = shredfreeonly
		if @shredfreeonly == true
			@cleantext.set_markup( "<span color='white'><b>" + @tl.get_translation("cleanhead") + "</b>\n\n" + @tl.get_translation("cleanbody") + "</span>")
			# @drivetext.hide_all
		else
			@cleantext.set_markup( "<span color='white'><b>" + @tl.get_translation("parthead") + "</b>\n\n" + @tl.get_translation("partbody") + "</span>")
			# @cleantext.hide_all 
			# @drivetext.show_all
		end
	end
	
	def prepare_deletedrive
		@drivedrives, @drivechecks, @drivelabels = fill_drive_tab(@drivetable, @drivechecks, @drivelabels)
		# @cleantext.show_all 
		# @drivetext.hide_all
	end
	
	def create_drive_tab(extlayers)
		orangetile = Gtk::EventBox.new.add Gtk::Image.new("deletegreen.png")
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, extlayers)
		delscroll = Gtk::ScrolledWindow.new
		delscroll.height_request = 220
		delscroll.width_request = 700
		delscroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC ) 
		# fixed.put(orangetile, 0, 0)
		fixed.put(delscroll, 0, 110)
		drivetext = TileHelpers.create_label("<b>" + @tl.get_translation("parthead") + "</b>\n\n" + @tl.get_translation("drivebody"), 510)
		fixed.put(drivetext, 0, 0)
		@drivetable = Gtk::Table.new(2, 2, false)
		align = Gtk::Alignment.new(0, 0, 0.1, 0.1)
		align.add @drivetable
		delscroll.add_with_viewport align
		anc = @drivetable.get_ancestor(Gtk::Viewport)
		anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#052f4c') )
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("deletenow") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		forw.signal_connect('button-release-event') { |x,y|
			if y.button == 1
				if TileHelpers.yes_no_dialog(@tl.get_translation("confirmbody"), @tl.get_translation("confirmhead"))
					extlayers.each { |k,v|v.hide_all }
					extlayers["deleteprogress"].show_all
					# run dd to delete
					run_deletion(@deleteprogress, true)
					unless @deletecancelled == true
						TileHelpers.success_dialog(@tl.get_translation("successbody"), @tl.get_translation("successhead"))
					else
						TileHelpers.success_dialog(@tl.get_translation("partialbody"), @tl.get_translation("partialhead"))
					end
					extlayers.each { |k,v|v.hide_all }
					TileHelpers.back_to_group
				end
			end
		}
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		return fixed
	end
	
	
	def fill_part_tab(table, oldheaders, oldchecks, oldlabels)
		TileHelpers.set_lock 
		TileHelpers.umount_all
		table.row_spacings = 4
		parts = Array.new
		fullparts = Array.new
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
				label = label + " (SATA/eSATA/IDE/NVME)</b>\n"
			end
			l = TileHelpers.create_label(label, 670)
			l.height_request = 17
			headers.push l
			table.attach(l, 0, 2, rowcount, rowcount+1)
			rowcount += 1
			partcount = 0
			d.partitions.each { |p|
				unless p.fs.to_s.strip == ""
					if ( @shredfreeonly == true && p.fs =~ /ntfs/i ) || ( @shredfreeonly == false ) 
						pltext = "#{p.device} - #{p.human_size} - #{p.fs}"
						mnt, opts = p.mount_point 
						pltext = @tl.get_translation("inuse").gsub("DRIVENAME", pltext) unless mnt.nil? 
						pl = TileHelpers.create_label(pltext, 650)
						cb = Gtk::CheckButton.new
						cb.sensitive = false unless mnt.nil? 
						labels.push pl
						checks.push cb
						parts.push p.device
						fullparts.push p
						table.attach(pl, 1, 2, rowcount, rowcount+1)
						table.attach(cb, 0, 1, rowcount, rowcount+1)
						rowcount += 1
						partcount += 1
					end
				end
			}
		}
		table.resize(rowcount, 2)
		TileHelpers.remove_lock
		return drives, parts, headers, checks, labels, fullparts 
	end
	
	def fill_drive_tab(table, oldchecks, oldlabels)
		TileHelpers.set_lock 
		TileHelpers.umount_all
		table.row_spacings = 4
		checks = Array.new
		labels = Array.new
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		oldlabels.each{ |l| table.remove l } 
		oldchecks.each{ |c| table.remove c } 
		table.resize(drives.size, 2)
		rowcount = 0
		drives.each { |d|
			label = "<b>#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
			if d.usb == true
				label = label + " (USB)"
			else
				label = label + " (SATA/eSATA/IDE/NVME)"
			end
			mnt = d.mounted 
			label = @tl.get_translation("inuse").gsub("DRIVENAME", label) if mnt == true 
			label = label + "</b>\n"
			l = TileHelpers.create_label(label, 650)
			l.height_request = 17
			labels.push l
			table.attach(l, 1, 2, rowcount, rowcount+1)
			cb = Gtk::CheckButton.new
			cb.sensitive = false if mnt == true
			checks.push cb
			table.attach(cb, 0, 1, rowcount, rowcount+1)
			rowcount += 1
		}
		TileHelpers.remove_lock 
		return drives, checks, labels
	end
	
	# fulldisks == true means to delete whole drives
	# fulldisks == false means to delete selected partitions only
	def run_deletion(progress, fulldisks)
		TileHelpers.set_lock 
		@deletecancelled = false
		delete_devices = Array.new
		# start a new dd process for every 16 chunks of 4 Megabyte = 64MB per process
		chunk_size = 16
		delete_chunks = Hash.new
		if fulldisks == true
			puts "Deletion of complete disks requested"
			0.upto(@drivedrives.size - 1) { |n|
				delete_devices.push(@drivedrives[n].device) if @drivechecks[n].active?
				delete_chunks[@drivedrives[n].device] = ( @drivedrives[n].size / 64 / 1024 ** 2 ) + 1  
			}
		else
			puts "Deletion of partitions requested"
			chunk_size = 2
			0.upto(@partparts.size - 1) { |n|
				delete_devices.push(@partparts[n]) if @partchecks[n].active?
				delete_chunks[@partparts[n]] = 16
			}
		end
		puts delete_devices.join(", ") 
		delete_devices.each { |d|
			starttime = Time.now.to_i 
			0.upto(delete_chunks[d] - 1) { |n|
				if @deletecancelled == false
					seekct = n * chunk_size
					comm = "dd if=/dev/zero of=/dev/#{d} bs=4M count=#{chunk_size.to_s} seek=#{seekct.to_s}" 
					system(comm)
					system("sync")
					current_time = Time.now.to_i 
					t = @tl.get_translation("pgdel").gsub("DRIVENAME", d)
					t = t + " - " + (n * 100 / delete_chunks[d]).to_s + @tl.get_translation("pgpercent").gsub("PERCENT", "")
					progress.fraction = n.to_f / delete_chunks[d].to_f 
					delta_time = current_time - starttime
					if fulldisks == true && delta_time > 20 && n > 2
						time_per_chunk = delta_time.to_f / n.to_f
						time_remaining = ( delete_chunks[d].to_f - n.to_f ) * time_per_chunk
						minutes_remaining = ( time_remaining + 30.0 ) / 60.0 
						nice_minutes = minutes_remaining.to_i % 60
						nice_hours = minutes_remaining.to_i / 60
						if nice_hours < 1 && nice_minutes < 3
							t = t + " - " + @tl.get_translation("pgone")
						elsif nice_hours < 2
							t = t + " - " + @tl.get_translation("pgminutes").gsub("MINUTES",  minutes_remaining.to_i.to_s) 
						else
							t = t + " - " + @tl.get_translation("pgminutes").gsub("MINUTES",  nice_minutes.to_i.to_s).gsub("HOURS", nice_hours.to_i.to_s)  
						end
					end
					progress.text = t 
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
				end
			}
		}
		unless @deletecancelled == true
			progress.text = @tl.get_translation("pgdone")
			progress.fraction = 1.0
		end
		TileHelpers.remove_lock 
	end
	
	def run_shredder(progress)
		TileHelpers.set_lock 
		@deletecancelled = false
		delete_devices = Array.new
		# start a new dd process for every 16 chunks of 4 Megabyte = 64MB per process
		chunk_size = 16
		delete_chunks = Hash.new
		
		0.upto(@partparts.size - 1) { |n|
			delete_devices.push(@partparts[n]) if @partchecks[n].active?
			delete_chunks[@partparts[n]] = ( @fullparts[n].size / 64 / 1024 ** 2 ) + 1  
		}
		
		puts delete_devices.join(", ") 
		delete_devices.each { |d|
			system("mkdir -p /var/run/lesslinux/shredder")
			system("mount -t ntfs-3g -o rw /dev/#{d} /var/run/lesslinux/shredder")
			mount_success = system("mountpoint /var/run/lesslinux/shredder")
			if mount_success == false
				TileHelpers.error_dialog(@tl.get_translation("mount_failed_deletion_incomplete"))
			else
				starttime = Time.now.to_i 
				0.upto(delete_chunks[d] - 1) { |n|
					puts n.to_s 
					if @deletecancelled == false
						seekct = n * chunk_size
						comm = "dd if=/dev/zero of=/var/run/lesslinux/shredder/shredder.nul bs=4M count=#{chunk_size.to_s} seek=#{seekct.to_s}" 
						if mount_success
							system(comm)
							system("sync")
						end
						current_time = Time.now.to_i 
						t = @tl.get_translation("pgdel").gsub("DRIVENAME", d)
						t = t + " - " + (n * 100 / delete_chunks[d]).to_s + @tl.get_translation("pgpercent").gsub("PERCENT", "")
						progress.fraction = n.to_f / delete_chunks[d].to_f 
						delta_time = current_time - starttime
						if delta_time > 20 && n > 2
							time_per_chunk = delta_time.to_f / n.to_f
							time_remaining = ( delete_chunks[d].to_f - n.to_f ) * time_per_chunk
							minutes_remaining = ( time_remaining + 30.0 ) / 60.0 
							nice_minutes = minutes_remaining.to_i % 60
							nice_hours = minutes_remaining.to_i / 60
							if nice_hours < 1 && nice_minutes < 3
								t = t + " - " + @tl.get_translation("pgone")
							elsif nice_hours < 2
								t = t + " - " + @tl.get_translation("pgminutes").gsub("MINUTES",  minutes_remaining.to_i.to_s) 
							else
								t = t + " - " + @tl.get_translation("pgminutes").gsub("MINUTES",  nice_minutes.to_i.to_s).gsub("HOURS", nice_hours.to_i.to_s)  
							end
						end
						progress.text = t 
						while (Gtk.events_pending?)
							Gtk.main_iteration
						end
					end
				}
				system("ls -lah /var/run/lesslinux/shredder/shredder.nul")
				system("rm -f /var/run/lesslinux/shredder/shredder.nul")
				system("umount -f /var/run/lesslinux/shredder") 
			end
		}
		unless @deletecancelled == true
			progress.text = @tl.get_translation("pgdone")
			progress.fraction = 1.0
		end
		TileHelpers.remove_lock 
	end
	
	def delete_rubbish(checkboxes, pgbar)
		TileHelpers.set_lock 
		drives = Array.new
		parts = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		drives.each { |d|
			d.partitions.each { |p|
				if p.fs =~ /ntfs/i 
					parts.push p
				end
			}
		}
		pgbar.text = "Datenmüll wird gelöscht"
		pgbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		parts.each { |p|
			p.mount("rw")
			mnt = p.mount_point
			if (checkboxes[0].active? == true) 
				puts "Delete printerjobs on #{p.device}"
				delete_printjobs(mnt[0], pgbar)
			end
			if (checkboxes[1].active? == true) 
				puts "Delete temp files on #{p.device}"
				delete_temp(mnt[0], pgbar)
			end
			if (checkboxes[2].active? == true) 
				puts "Delete trash on #{p.device}"
				delete_trashcan(mnt[0], pgbar)
			end
			p.umount
		}
		TileHelpers.remove_lock 
		TileHelpers.success_dialog(@tl.get_translation("rubbishdone"))
	end
	
	def delete_printjobs(mountpoint, pgbar)
		TileHelpers.set_lock 
		windir = nil
		sysdir = nil
		spooldir = nil
		printdir = nil 
		[ "Windows", "WINDOWS", "windows"].each { |w| windir = w if File.directory?(mountpoint + "/" + w) }
		$stderr.puts windir
		if windir.nil?
			TileHelpers.remove_lock
			return false
		end
		[ "System32", "SYSTEM32", "system32" ].each { |s| sysdir = windir + "/" + s if File.directory?(mountpoint + "/" + windir + "/" + s) }
		$stderr.puts sysdir
		if sysdir.nil?
			TileHelpers.remove_lock
			return false
		end
		[ "Spool", "SPOOL", "spool" ].each { |s| spooldir = sysdir + "/" + s if File.directory?(mountpoint + "/" + sysdir + "/" + s) }
		$stderr.puts spooldir
		if spooldir.nil?
			TileHelpers.set_lock 
			return false
		end
		[ "Printers", "PRINTERS", "printers" ].each { |s| printdir = mountpoint + "/" + spooldir + "/" + s if File.directory?(mountpoint + "/" + spooldir + "/" + s) }
		$stderr.puts printdir
		if printdir.nil?
			TileHelpers.set_lock 
			return false
		end
		Dir.entries(printdir).each { |f|
			pgbar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			if f =~ /\.SHD$/i || f =~ /\.SPL$/i
				$stderr.puts(printdir + "/" + f)
				FileUtils.rm(printdir + "/" + f, :force => true) 
			end
		}
		TileHelpers.remove_lock 
	end
	
	def delete_trashcan(mountpoint, pgbar)
		TileHelpers.set_lock 
		if File.directory?(mountpoint + '/$Recycle.Bin')
			$stderr.puts("Found trashcan!")
			Dir.entries(mountpoint + '/$Recycle.Bin').each { |f|
				unless [ ".", ".." ].include?(f)
					pgbar.pulse
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					$stderr.puts( mountpoint + '/$Recycle.Bin/' + f)
					FileUtils.rm_rf(mountpoint + '/$Recycle.Bin/' + f) 
				end
			}
		end
		TileHelpers.remove_lock 
	end
	
	def delete_temp(mountpoint, pgbar)
		TileHelpers.set_lock 
		windir = nil
		tempdir = nil
		userdir = nil
		usernames = [] 
		[ "Windows", "WINDOWS", "windows"].each { |w| windir = w if File.directory?(mountpoint + "/" + w) }
		# return false if windir.nil?
		unless windir.nil?
			[ "Temp", "TEMP", "temp" ].each { |s| tempdir = mountpoint + "/" + windir + "/" + s if File.directory?(mountpoint + "/" + windir + "/" + s) } 
		end
		# return false if tempdir.nil?
		unless tempdir.nil?
			Dir.entries(tempdir).each { |f|
				unless [ ".", ".." ].include?(f)
					pgbar.pulse
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
					$stderr.puts( tempdir + '/' + f)
					FileUtils.rm_rf(tempdir + '/' + f) 
				end
			}
		end
		[ "Users", "USERS", "users"].each { |u| userdir = mountpoint + "/" + u if File.directory?(mountpoint + "/" + u) }
		if userdir.nil?
			TileHelpers.remove_lock
			return false
		end
		$stderr.puts userdir 
		Dir.entries(userdir).each { |d|
			unless [ ".", ".." ].include?(d)
				usernames.push(d) if File.directory?(userdir + "/" + d)
			end
		}
		usernames.each { |u|
			$stderr.puts "Delete for #{u}"
			if File.directory?(userdir + "/" + u + "/AppData/Local/Temp") 
				Dir.entries(userdir + "/" + u + "/AppData/Local/Temp").each { |f|
					unless [ ".", ".." ].include?(f)
						pgbar.pulse
						while (Gtk.events_pending?)
							Gtk.main_iteration
						end
						$stderr.puts( userdir + "/" + u + '/AppData/Local/Temp/' + f)
						FileUtils.rm_rf( userdir + "/" + u + '/AppData/Local/Temp/' + f) 
					end
				}
			end
		}
		TileHelpers.remove_lock
	end
end

