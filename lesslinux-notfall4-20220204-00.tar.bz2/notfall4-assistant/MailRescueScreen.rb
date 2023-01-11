#!/usr/bin/ruby
# encoding: utf-8

require 'mahoro'

class MailRescueScreen	
	def initialize(extlayers, button, nwscreen)
		
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "MailRescueScreen.xml")
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
		
		#### Table to show mailboxes 
		
		# List for PST files
		pstpartlist = Hash.new
		@mbtable = nil
		# List of mailboxes
		@mblist = Hash.new
		# Checkboxes for mailboxes
		@mbchecks = Hash.new
		
		fixed = Gtk::Fixed.new
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		logotile = Gtk::Image.new("mailgreen.png")
		bodytext = TileHelpers.create_label("<b>" + @tl.get_translation("mailhead") + "</b>\n\n" + @tl.get_translation("mailbody") , 510)
		
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
		
		# List for found mailboxes
		
		mbfixed =  Gtk::Fixed.new
		mbtext = Gtk::Label.new
		mbtext.width_request = 230
		mbtext.wrap = true
		mbtext.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		mbforw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		mbtile = Gtk::Image.new("mailgreen.png")
		mbbodytext = TileHelpers.create_label("<b>" + @tl.get_translation("mailmbhead") + "</b>\n\n" + @tl.get_translation("mailmbbody") , 510)
		
		mbdelscroll = Gtk::ScrolledWindow.new
		mbdelscroll.height_request = 220
		mbdelscroll.width_request = 700
		mbdelscroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC ) 
		@mbtable = Gtk::Table.new(2, 11, false)
		mbalign = Gtk::Alignment.new(0, 0, 0.1, 0.1)
		mbalign.add @mbtable
		mbdelscroll.add_with_viewport mbalign
		mbanc = @mbtable.get_ancestor(Gtk::Viewport)
		# mbanc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		mbanc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#052f4c') )
		mbfixed.put(mbforw, 650, 352)
		mbfixed.put(mbtext, 402, 358)
		# mbfixed.put(mbtile, 0, 0)
		mbfixed.put(mbbodytext, 0, 0)
		mbfixed.put(mbdelscroll, 0, 90)
		TileHelpers.place_back(mbfixed, extlayers)
		
		# List for temporary targets
		# FIXME!
		
		# Finishing screen 
		
		finfixed =  Gtk::Fixed.new
		finbodytext = TileHelpers.create_label("<b>" + @tl.get_translation("mailtbhead") + "</b>\n\n" + @tl.get_translation("mailtbbody") , 510)
		fintile = Gtk::Image.new("mailgreen.png")
		# finfixed.put(fintile, 0, 0)
		finfixed.put(finbodytext, 0, 0)
		TileHelpers.place_back(finfixed, extlayers)
		ffbutton =Gtk::Button.new(@tl.get_translation("openthunderbird"))
		ffbutton.width_request = 150
		ffbutton.height_request = 32
		finfixed.put(ffbutton, 495, 284)
		
		extlayers["mailpartlist"] = fixed
		@layers[0] = extlayers["mailpartlist"] 
		extlayers["mailmboxlist"] = mbfixed
		@layers[1] = extlayers["mailmboxlist"] 
		extlayers["mailthunderbird"] = finfixed
		@layers[2] = extlayers["mailthunderbird"] 
		
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
				extlayers["mailpartlist"].show_all
			end
		}
		
		# Event for forward button
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# check whether something is checked first
				checks = 0
				@partchecks.each { |n|
					checks += 1 if n.active? 
				}
				if checks > 0
					extlayers.each { |k,v|v.hide_all }
					pstpartlist = find_pst_files(@partparts, @partchecks)
					@mblist, @mbchecks = fill_mb_tab(@mbtable, pstpartlist, @mblist, @mbchecks) 
					if @mbchecks.size > 0
						extlayers["mailmboxlist"].show_all
					else
						extlayers["mailpartlist"].show_all
						TileHelpers.error_dialog(@tl.get_translation("no_pst_database_found"))
					end
				else
					TileHelpers.error_dialog(@tl.get_translation("please_select_partition"))
				end
			end
		}
		
		# Even for last forward button
		mbforw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				# Check size first!
				sizeneeded = 0
				checks = 0
				pstpartlist.each { |k,v| 
					puts k.device
					n = 0
					v.each { |b|
						puts b
						if @mbchecks[k][n].active? == true
							sizeneeded += b[1]
							checks += 1 
						end
						n = n+1
					}
				}
				# Enough RAM? 
				puts sizeneeded.to_s
				freeram = ` df -k /tmp | tail -n1 `.strip.split[3].to_i * 700
				puts freeram.to_s 
				mountpoint, freespace = TileHelpers.mount_usbdata
				if checks < 1
					TileHelpers.error_dialog(@tl.get_translation("no_mailbox_checked"))
					TileHelpers.umount_all 
				elsif ( freeram < sizeneeded ) && ( sizeneeded / 768 > freespace / 1024 ) 
					TileHelpers.error_dialog(@tl.get_translation("free_space_not_sufficient"))
					TileHelpers.umount_all 
				else
					if sizeneeded / 768 < freespace / 1024
						system("mkdir -p #{mountpoint[0]}/Outlook-Import")
						system("mount --bind #{mountpoint[0]}/Outlook-Import /tmp/Outlook-Import") 
						TileHelpers.error_dialog(@tl.get_translation("remove_folder_afterwards"))
					end
					extlayers.each { |k,v|v.hide_all }
					#return false
					pstpartlist.each { |k,v| 
						puts k.device
						n = 0
						v.each { |b|
							puts b
							if @mbchecks[k][n].active? == true
								k.mount
								convert_pst(k.mount_point[0] + "/" + b[0], "/tmp")
								k.umount
							end
							n = n+1
						}
					}
					system("chown -R surfer:surfer /tmp/Outlook-Import") 
					if @nwscreen.test_connection == false
						@nwscreen.nextscreen = "mailthunderbird"
						@nwscreen.fill_wlan_combo 
						# Check for networks first...
						extlayers["networks"].show_all
						# FIXME: Properly start Tbird
					else
						extlayers["mailthunderbird"].show_all
						system("nohup su surfer -c thunderbird &")
					end
				end
			end
		}
		
		ffbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("su surfer -c 'thunderbird' &") 
			end
		}
		
	end
	
	attr_reader :layers
	
	def prepare_mailpartlist
		# Read drivelist
		@partdrives, @partparts, @partheaders, @partchecks, @partlabels = fill_part_tab(@parttable, @partheaders, @partchecks, @partlabels)
	end
	
	def find_pst_files(parts, checks)
		TileHelpers.set_lock 
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		pstpartlist = Hash.new
		dwin = Gtk::Window.new
		dwin.set_default_size(400, 40)
		pgbar = Gtk::ProgressBar.new
		pgbar.width_request = 300
		dwin.add(pgbar)
		dwin.deletable = false
		dwin.title = @tl.get_translation("be_patient") 
		dwin.show_all
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		0.upto(parts.size - 1) { |n|
			if checks[n].active? 
				parts[n].mount
				puts parts[n].mount_point[0]
				pstlist = traverse_for_pst(parts[n].mount_point[0], parts[n].mount_point[0], pgbar) 
				pstpartlist[parts[n]] = pstlist if pstlist.size > 0 
				parts[n].umount
			end
		}
		dwin.destroy 
		TileHelpers.remove_lock
		return pstpartlist 
	end
	
	def traverse_for_pst(startdir, basedir, pgbar)
		TileHelpers.set_lock 
		pstlist = Array.new
		Dir.entries(startdir).each { |e|
			now = Time.now.to_f
			if now - @lastpulse > 0.2 
				pgbar.text = @tl.get_translation("traversing") + " "  + e  
				pgbar.pulse
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				@lastpulse = now
			end
			
			if e == "." || e == ".."
				# puts "Ignore directory #{e}"
			elsif File.symlink? "#{startdir}/#{e}"
				puts "Ignore symlink #{e}"
			elsif File.directory? "#{startdir}/#{e}" 
				pstlist = pstlist + traverse_for_pst("#{startdir}/#{e}", basedir, pgbar) 
			elsif File.file?("#{startdir}/#{e}") && ( e =~ /\.pst$/i   || e =~ /\.ost$/i )
				puts "Parsing #{startdir}/#{e}"
				m = Mahoro.new(Mahoro::NONE)
				begin
					if m.buffer(File.read("#{startdir}/#{e}", 2048)) =~ /Microsoft Outlook email/i 
						fsize = File.stat("#{startdir}/#{e}").size 
						pstlist.push( [ "#{startdir}/#{e}".gsub(basedir, ""), fsize ] )
					end
				rescue
				end
			end
		}
		TileHelpers.remove_lock
		return pstlist 
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
					puts "Added: #{pt} #{rowcount.to_s}" 
				end
			}
			
		}
		table.resize(rowcount, 2)
		TileHelpers.remove_lock
		return drives, parts, headers, checks, labels
	end
	
	def fill_mb_tab(table, pstpartlist, oldlabels, oldchecks) 
		TileHelpers.set_lock 
		table.resize(100, 2)
		rowcount = 0
		table.row_spacings = 4
		# Fixme begin rescue end
		oldlabels.each{ |l| 
			begin
				table.remove l 
			rescue
			end
		} 
		oldchecks.each{ |c| 
			begin
				table.remove c
			rescue
			end
		} 
		checks = Hash.new
		labels = Hash.new
		pstpartlist.each { |k,v|
			checks[k] = Array.new
			labels[k] = Array.new 
			v.each { |p|
				pl = TileHelpers.create_label(k.device + " " + p[0] + " (" + (p[1] / 1048576).to_s + "MB)", 650)
				cb = Gtk::CheckButton.new
				cb.active = true
				labels[k].push pl
				checks[k].push cb
				table.attach(pl, 1, 2, rowcount, rowcount+1)
				table.attach(cb, 0, 1, rowcount, rowcount+1)
				rowcount += 1
				table.resize(rowcount, 2)
			}
		}
		TileHelpers.remove_lock
		return labels, checks 
	end
	
	def convert_pst(filepath, tgtdir)
		TileHelpers.set_lock 
		# Create output directory
		outdir = tgtdir + "/Outlook-Import/" + File.basename(filepath, ".pst")
		outsbd = File.basename(filepath, ".pst")
		n = 0
		while File.directory?(outdir) 
			outdir = tgtdir + "/Outlook-Import/" + File.basename(filepath, ".pst") + "." + n.to_s 
			outsbd = File.basename(filepath, ".pst") + "." + n.to_s 
			n += 1
		end
		FileUtils::mkdir_p outdir
		system("sync")
		sleep 1
		# pgbar.text = "Konvertiere " + File.basename(filepath, ".pst")
		puts "Running: readpst -o \"#{outdir}\"  \"#{filepath}\""
		# run_command(pgbar, "readpst", [ "readpst",  "-o" ,   outdir, filepath ], "Konvertiere " + File.basename(filepath, ".pst") ) 
		system("readpst -o \"#{outdir}\"  \"#{filepath}\"") 
		FileUtils::mkdir_p "/home/surfer/.thunderbird/cdi12345.default/Mail/localhost/Inbox.sbd/Outlook-Import.sbd"
		FileUtils::touch "/home/surfer/.thunderbird/cdi12345.default/Mail/localhost/Inbox.sbd/Outlook-Import"
		FileUtils::touch "/home/surfer/.thunderbird/cdi12345.default/Mail/localhost/Inbox.sbd/Outlook-Import.sbd/" + outsbd
		puts "Running: ln -sf \"#{outdir}\" \"/home/surfer/.thunderbird/cdi12345.default/Mail/localhost/Inbox.sbd/Outlook-Import.sbd/#{outsbd}.sbd\""
		system("ln -sf \"#{outdir}\" \"/home/surfer/.thunderbird/cdi12345.default/Mail/localhost/Inbox.sbd/Outlook-Import.sbd/#{outsbd}.sbd\"")
		TileHelpers.remove_lock
	end
	
end