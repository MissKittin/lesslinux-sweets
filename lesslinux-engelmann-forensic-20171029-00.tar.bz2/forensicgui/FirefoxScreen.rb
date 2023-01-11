#!/usr/bin/ruby
# encoding: utf-8

class FirefoxScreen 

	def initialize(layers, fixed)
		
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "FirefoxScreen.xml")
		@layers = layers
		@fixed = fixed 
		
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
		@pstpartlist = nil 
		@flatproflist = nil
		@profcombo = nil
		@selradio1 = nil
		@ffbutton = nil
		
		#### Table to show mailboxes 
	
		##@mbtable = nil
		# List of mailboxes
		##@mblist = Hash.new
		# Checkboxes for mailboxes
		##@mbchecks = Hash.new
		@start_label = @tl.get_translation("start_label") 
		create_first_layer 
		create_prof_layer 
	end
	attr_reader :start_label
	
	def create_first_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		ok = Gtk::Button.new(Gtk::Stock::APPLY)
		# ok.sensitive = false 
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("firefox_start")) 
		fx.put(infolabel, 250, 100)
		
		delscroll = Gtk::ScrolledWindow.new
		delscroll.height_request = 250
		delscroll.width_request = 730
		delscroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC ) 
		@parttable = Gtk::Table.new(2, 11, false)
		align = Gtk::Alignment.new(0, 0, 0.1, 0.1)
		align.add @parttable
		delscroll.add_with_viewport align
		anc = @parttable.get_ancestor(Gtk::Viewport)
		# anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		# anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		
		cancel.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
		}
		
		# Event for forward button
		ok.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				checks = 0
				@partchecks.each { |p|
					checks += 1 if p.active? 
				}
				if checks < 1
					TileHelpers.error_dialog(@tl.get_translation("please_select_partition"))
				else
					@pstpartlist = find_profile_dirs(@partparts, @partchecks)
					@flatproflist = fill_prof_combo(@pstpartlist, @profcombo) 
					@layers.each { |k,v|v.hide_all }
					@ffbutton.sensitive = true if @flatproflist.size > 0
					@ffbutton.sensitive = false unless @flatproflist.size > 0
					@layers["firefox_list"].show_all
				end
			end
		}
		
		fx.put(delscroll, 250, 220)
		[ ok, cancel, ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		fx.put(ok, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		# fx.put(set, SETTINGS_X, SETTINGS_Y)
		@fixed.put(fx, 0, 0)
		@layers["firefox_start"] = fx	
		
		return true 
	end
	
	def create_prof_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		@ffbutton = Gtk::Button.new(Gtk::Stock::APPLY)
		# @ffbutton.sensitive = false 
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("firefox_profiles")) 
		fx.put(infolabel, 250, 100)
		
		@profcombo = Gtk::ComboBox.new
		@profcombo.width_request = 730
		@selradio1 = Gtk::RadioButton.new(@tl.get_translation("onlypasswords"), 400)
		selradio2 = Gtk::RadioButton.new(@selradio1, @tl.get_translation("wholeprofile"))
		
		fx.put(@profcombo, 250, 250)
		fx.put(@selradio1, 280, 290)
		fx.put(selradio2, 280, 320)
		
		cancel.signal_connect("clicked") { 
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
		}
		
		fullhtml = @tl.get_translation("fullhtml")
		passhtml = @tl.get_translation("passhtml")
		
		@ffbutton.signal_connect("clicked") {
			if @flatproflist.size < 1 
				TileHelpers.error_dialog(@tl.get_translation("please_select_profile"))
			else				
				puts @flatproflist[@profcombo.active][0].device + " " + @flatproflist[@profcombo.active][1]
				sync_firefox_pass(@flatproflist[@profcombo.active], @selradio1)
				# @layers.each { |k,v|v.hide_all }
				TileHelpers.mount_usbdata
				if @selradio1.active?
					system("nohup su surfer -c 'firefox file://#{fullhtml}' &")
				else
					system("nohup su surfer -c 'firefox file://#{passhtml}' &")
				end
				# @layers["firefoxfinish"].show_all
			end
			@ffbutton.sensitive = false 
		}
		
		[ @ffbutton, cancel, ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		fx.put(@ffbutton, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		# fx.put(set, SETTINGS_X, SETTINGS_Y)
		@fixed.put(fx, 0, 0)
		@layers["firefox_list"] = fx	

	end
	
	def reread_drivelist 
		@partdrives, @partparts, @partheaders, @partchecks, @partlabels = fill_part_tab(@parttable, @partheaders, @partchecks, @partlabels)
	end
	
	def fill_part_tab(table, oldheaders, oldchecks, oldlabels)
		check_count = 0 
		# TileHelpers.umount_all
		table.row_spacings = 4
		parts = Array.new
		headers = Array.new
		drives = Array.new
		checks = Array.new
		labels = Array.new
		Dir.entries("/sys/block").each { |l|
			drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ 
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
			# l = TileHelpers.create_label(label, 670)
			l = Gtk::Label.new
			l.set_markup label 
			l.wrap = false
			l.width_request = 670 
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
					# pl = TileHelpers.create_label(pt, 650)
					pl = Gtk::Label.new(pt)
					pl.width_request = 650
					pl.wrap = true 
					cb = Gtk::CheckButton.new
					if p.fs =~ /ntfs/ || p.fs =~ /vfat/  
						cb.active = true 
						check_count += 1
					end
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
		return drives, parts, headers, checks, labels
	end
	
	def find_profile_dirs(parts, checks)
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
		return pstpartlist 
	end
	
	def traverse_for_profiles(startdir, basedir, pgbar) 
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
			elsif File.file?("#{startdir}/#{e}") && (e =~ /^signons.*\.txt$/i ||  e == "signons.sqlite" || e == "key.db" ||   e == "key3.db" ||  e == "logins.json" )
				proflist.push(startdir.gsub(basedir, "") )
			end
		}
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
		device_path[0].mount
		mntpnt = device_path[0].mount_point[0] 
		if radio.active?
			[ "signons1.txt", "signons2.txt", "signons3.txt", "signons.sqlite", "key.db", "key3.db", "logins.json" ].each { |f|
				system("rsync -avHP \"#{mntpnt}/#{device_path[1]}/#{f}\" /home/surfer/.mozilla/firefox/c3o3frus.default/")
			}
		else
			system("rsync -avHP \"#{mntpnt}/#{device_path[1]}/\" /home/surfer/.mozilla/firefox/c3o3frus.default/")
		end
		system("chown -R surfer:surfer /home/surfer/.mozilla/firefox/c3o3frus.default") 
		device_path[0].umount
	end
	
end