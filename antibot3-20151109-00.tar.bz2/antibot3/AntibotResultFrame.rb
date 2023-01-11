#!/usr/bin/ruby
# encoding: utf-8

class AntibotResultFrame	
	def initialize(assi)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		tlfile = "AntibotResultFrame.xml"
		tlfile = "/usr/share/lesslinux/antibot3/AntibotResultFrame.xml" if File.exists?("/usr/share/lesslinux/antibot3/AntibotResultFrame.xml")
		@tl = MfsTranslator.new(lang, tlfile)
		icon_theme = Gtk::IconTheme.default
		@killed = false
		@infected = nil
		@scanner = nil
		@int_drives = nil
		@ext_drives = nil
		@spec_drives = nil
		@delete_on_failed_desinfect = false
		@truncate_instead_delete = true
		@backup_before_action = true
		@localbackup = true
		@assistant = assi
		@wdgt = Gtk::Alignment.new(0.5, 0.5, 0.8, 0.0)
		@vbox = Gtk::VBox.new(false, 5)
		@children = Array.new
		image = Gtk::Image.new("icons/warning32.png")
		@ctext = Gtk::Label.new(@tl.get_translation("incomplete"))
		@ctext.wrap = true
		calign = Gtk::Alignment.new(0.0, 0.0, 0.0, 0.0)
		calign.add @ctext
		@ctext.width_request = 495
		@children.push Gtk::HBox.new(false, 5)
		@children[0].pack_start(image, false, false, 1)
		@children[0].pack_start(calign, true, true, 1)
		@children[0].width_request = 550
		@children.push(Gtk::Label.new(@tl.get_translation("novirus")))
		@children[1].wrap = true
		@children[1].use_markup = true
		@children[1].width_request = 550
		@children.push(Gtk::Label.new(@tl.get_translation("virusfound")))
		@children[2].wrap = true
		@children[2].use_markup = true
		@children[2].width_request = 550
		@children.push Gtk::HBox.new(false, 3)
		@progress = Gtk::ProgressBar.new
		# @progress.width_request = 330
		@children[3].width_request = 550 
		@children[3].pack_start(@progress, true, true, 3)
		@confbutton = Gtk::Button.new(@tl.get_translation("selection"))
		@confbutton.width_request = 90
		@children[3].pack_start(@confbutton, false, false, 0)
		@confbutton.signal_connect("clicked") { show_configuration }
		@desinfbutton = Gtk::Button.new("Start")
		@desinfbutton.width_request = 90
		@desinf_runmode = true
		@desinfbutton.signal_connect("clicked") { 
			run_desinfection if @desinf_runmode == true
			kill_desinfection if @desinf_runmode == false
		}
		@children[3].pack_start(@desinfbutton, false, false, 0)
		# @children.push Gtk::HBox.new(false, 3)
		# again_box = Gtk::Alignment.new(1.0, 0.0, 0.0, 0.0)
		# @again_button = Gtk::Button.new("Weiteren Virenscan starten")
		@again_button = Gtk::Button.new(Gtk::Stock::GOTO_FIRST)
		@again_button.use_underline = true
		@again_button.label = @tl.get_translation("button-again")
		@again_button.image = Gtk::Image.new(icon_theme.load_icon("go-first", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
		@again_button.signal_connect("clicked") { @assistant.current_page = 0 }
		@log_button = Gtk::Button.new
		@log_button.use_underline = true
		@log_button.label = @tl.get_translation("button-log")
		@log_button.image = Gtk::Image.new(icon_theme.load_icon("applications-system", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
		@log_button.signal_connect("clicked") { 
			unless @scanner.logdir.nil?
				system("su surfer -c 'Thunar #{@scanner.logdir}' &")
			else
				system("su surfer -c 'Thunar /tmp/" + @tl.get_translation("html-proto-dir") + "' &")
			end
		}
		# again_box.add @again_button
		# @children[4].pack_start(again_box, true, true, 0)
		0.upto(@children.size - 1) { |n| @children[n].width_request = 540 } 
		@children.each { |w|
			al = Gtk::Alignment.new(0.0, 0.0, 0.0, 0.0)
			al.add w
			@vbox.pack_start(al, true, false, 0)
		}
		@assistant.add_action_widget @again_button
		@assistant.add_action_widget @log_button
		@again_button.show_all
		@log_button.show_all
		@wdgt.add @vbox
	end
	attr_reader :wdgt, :scanner
	attr_accessor :again_button, :log_button
	
	def show_results(int_drives, ext_drives, spec_drives, scanner)
		@killed = false
		@desinf_runmode = true
		@desinfbutton.label = @tl.get_translation("button-go") 
		@progress.fraction = 0.0
		@progress.text = ""
		@scanner = scanner
		@int_drives = int_drives
		@ext_drives = ext_drives
		@spec_drives = spec_drives
		@again_button.sensitive = true
		@confbutton.sensitive = true
		@desinfbutton.sensitive = true
		@again_button.show_all
		@log_button.show_all
		puts "Infections total: " + @scanner.inf_count.to_s
		@children.each { |w| w.hide_all }
		failed_parts = Array.new
		@scanner.return_codes.each { |k, r| failed_parts.push(k.device) if r > 101 }
		@ctext.text = @tl.get_translation("incomplete2").gsub("FAILEDPARTS", failed_parts.join(', ')) if failed_parts.size > 0
		@ctext.text = @tl.get_translation("killed")  if @scanner.killed == true
		@ctext.use_markup = true
		@children[0].show_all if failed_parts.size > 0
		@children[0].show_all if @scanner.killed == true
		
		# Here we show three different states of infection
		#
		# 1. not infected
		# 2. infected, separate cleaning requested
		# 3. infected, but infections were desinfected/deleted during scan
		
		if @scanner.inf_count < 1
			@assistant.set_page_side_image(@wdgt, Gdk::Pixbuf.new("DE-Cleaner-Rettungssystem-2012-6a.png"))
			@children[1].show_all
			@assistant.set_page_title(@wdgt, @tl.get_translation("scan-done"))
			@assistant.set_page_complete(@wdgt, true)
		elsif @scanner.params.include?("--defaultaction=ignore")
			@assistant.set_page_side_image(@wdgt, Gdk::Pixbuf.new("DE-Cleaner-Rettungssystem-2012-6b.png"))
			@children[3].show_all
			@children[2].text = @tl.get_translation("virusfound").gsub("%FILECOUNT%", @scanner.inf_count.to_s).gsub("%SUFFVIR%", get_vir_suffix)
			@children[2].use_markup = true
			@children[2].show_all
			@assistant.set_page_title(@wdgt, @tl.get_translation("desinfect") )
		else
			@assistant.set_page_side_image(@wdgt, Gdk::Pixbuf.new("DE-Cleaner-Rettungssystem-2012-6a.png"))
			@children[2].text = @tl.get_translation("virus-removed").gsub("%FILECOUNT%", @scanner.inf_count.to_s).gsub("%SUFFVIR%", get_vir_suffix)
			@children[2].use_markup = true
			@children[2].show_all
			@assistant.set_page_title(@wdgt, @tl.get_translation("scan-done") )
			@assistant.set_page_complete(@wdgt, true)
		end
	end
	
	def get_vir_suffix 
		if @scanner.vir_count == @scanner.inf_count
			return " (" + @tl.get_translation("vir-all") + ")"
		elsif @scanner.vir_count > 1
			return " (" + @tl.get_translation("vir-some").gsub("VIRUSCOUNT", @scanner.vir_count.to_s) + ")"
		elsif @scanner.vir_count == 1
			return " (" + @tl.get_translation("vir-one") + ")"
		end
		return ""
	end
	
	def show_configuration
		inf_count = 0 
		# puts @scanner.to_s
		# Create the dialog
		dialog = Gtk::Dialog.new(@tl.get_translation("wintitle"),
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ])
		drive_expanders = Hash.new
		vbox = Gtk::VBox.new(false, 5)
		checked_uuids = Array.new
		@scanner.infections.each { |k,v| 
			checked_uuids.push(k.uuid) unless v.nil? 
			#puts v.to_s 
		}
		( @int_drives + @ext_drives ).each { |d|
			d.partitions.each { |p|
				if checked_uuids.include?(p.uuid)
					puts d.device.to_s + " " + p.device.to_s + " " + p.uuid.to_s
					tlines = Array.new
					inf = @scanner.infections[p]
					unless inf.nil?
						inf.each { |i|
							tlines.push i.create_list_entry
						}
					end
					table = Gtk::Table.new(tlines.size + 1, 6, false)
					if tlines.size > 0 
						note = " " + @tl.get_translation("clean-note").gsub("COUNT",  tlines.size.to_s)
						ls = [ "", @tl.get_translation("thead0"), @tl.get_translation("thead1"), 
							@tl.get_translation("thead2"), @tl.get_translation("thead3"),
							@tl.get_translation("thead4") ] 
						0.upto(ls.size - 1) { |n|
							lab = Gtk::Label.new("<b>" + ls[n] + "</b>")
							lab.use_markup = true
							table.attach(lab, n, n+1, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 0, 2)
						}
						lct = 1
						tlines.each { |tentry|
							spacer = Gtk::Label.new("")
							spacer.width_request = 20
							table.attach(spacer, 0, 1, lct, lct+1, Gtk::SHRINK, Gtk::SHRINK, 0, 2)
							table.attach(tentry[2], 1, 2, lct, lct+1, Gtk::SHRINK, Gtk::SHRINK, 0, 2)
							table.attach(tentry[3], 2, 3, lct, lct+1, Gtk::SHRINK, Gtk::SHRINK, 0, 2)
							table.attach(tentry[4], 3, 4, lct, lct+1, Gtk::SHRINK, Gtk::SHRINK, 0, 2)
							table.attach(tentry[0], 4, 5, lct, lct+1, Gtk::FILL, Gtk::SHRINK, 5, 2)
							table.attach(tentry[1], 5, 6, lct, lct+1, Gtk::FILL, Gtk::SHRINK, 5, 2)
							lct += 1
						}
					else
						note = " " + @tl.get_translation("clean-note0")
					end
					err_msg = @scanner.hr_error_code(p)
					note += " - " + err_msg unless err_msg.nil? 
					drive_expanders[p.device] = Gtk::Expander.new("<b>" + d.device + ", Partition " + p.device.to_s + ", " + p.fs.to_s + " " + p.label.to_s + " " + p.human_size + note + "</b>", true)
					drive_expanders[p.device].use_markup = true
					if tlines.size > 0
						drive_expanders[p.device].expanded = true
					else
						drive_expanders[p.device].sensitive = false
					end
					drive_expanders[p.device].add(table)
					vbox.pack_start(drive_expanders[p.device], false, false, 0)
				end
			}
		}
		@spec_drives.each { |p|
			if checked_uuids.include?(p.uuid)
				tlines = Array.new
				inf = @scanner.infections[p]
				unless inf.nil?
					inf.each { |i|
						tlines.push i.create_list_entry
					}
				end
				table = Gtk::Table.new(tlines.size + 1, 6, false)
				if tlines.size > 0 
					note = " " + @tl.get_translation("clean-note")
					ls = [ "", @tl.get_translation("thead0"), @tl.get_translation("thead1"), 
							@tl.get_translation("thead2"), @tl.get_translation("thead3"),
							@tl.get_translation("thead4") ]
					0.upto(ls.size - 1) { |n|
						lab = Gtk::Label.new("<b>" + ls[n] + "</b>")
						lab.use_markup = true
						table.attach(lab, n, n+1, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 0, 2)
					}
					lct = 1
					tlines.each { |tentry|
						spacer = Gtk::Label.new("")
						spacer.width_request = 20
						table.attach(spacer, 0, 1, lct, lct+1, Gtk::SHRINK, Gtk::SHRINK, 0, 2)
						table.attach(tentry[2], 1, 2, lct, lct+1, Gtk::SHRINK, Gtk::SHRINK, 0, 2)
						table.attach(tentry[3], 2, 3, lct, lct+1, Gtk::SHRINK, Gtk::SHRINK, 0, 2)
						table.attach(tentry[4], 3, 4, lct, lct+1, Gtk::SHRINK, Gtk::SHRINK, 0, 2)
						table.attach(tentry[0], 4, 5, lct, lct+1, Gtk::FILL, Gtk::SHRINK, 5, 2)
						table.attach(tentry[1], 5, 6, lct, lct+1, Gtk::FILL, Gtk::SHRINK, 5, 2)
						lct += 1
					}
				else
					note = " " + @tl.get_translation("clean-note0")
				end
				err_msg = @scanner.hr_error_code(p)
				note += " - " + err_msg unless err_msg.nil? 
				prefix = @tl.get_translation("address") + ": "
				prefix = @tl.get_translation("device") + ": " if p.dev =~ /^\/dev\//
				button_text = prefix + @tl.get_translation("drive-desc").gsub("DEVICE", p.dev).gsub("FILESYS", p.fs).gsub("MOUNTPOINT", p.mntpoint) 
				button_text = button_text + " " +  @tl.get_translation("drive-ro") unless p.rw? 
				drive_expanders[p.device] = Gtk::Expander.new("<b>" + button_text + note + "</b>", true)
				drive_expanders[p.device].use_markup = true
				if tlines.size > 0
					drive_expanders[p.device].expanded = true
				else
					drive_expanders[p.device].sensitive = false
				end
				drive_expanders[p.device].add(table)
				vbox.pack_start(drive_expanders[p.device], false, false, 0)
			end
		}
		oscrl = Gtk::ScrolledWindow.new
		oscrl.width_request = 730
		oscrl.height_request = 350
		oscrl.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		oscrl.add_with_viewport vbox
		
		leg = Gtk::Label.new(@tl.get_translation("clean-opts"))
		leg.use_markup = true
		legalign =Gtk::Alignment.new(0.0, 0.0, 0.0, 0.0)
		legalign.add leg
		
		outbox = Gtk::VBox.new(false, 0)
		outbox.pack_start(oscrl, true, true, 0)
		delquest = Gtk::CheckButton.new(@tl.get_translation("action0"))
		delbox = Gtk::VBox.new(false, 0)
		trcquest = Gtk::CheckButton.new(@tl.get_translation("action1"))
		trcquest.sensitive = @delete_on_failed_desinfect
		bakquest = Gtk::CheckButton.new(@tl.get_translation("action2"))
		bakquest.sensitive = @delete_on_failed_desinfect
		delbox.pack_start(trcquest, false, false, 0)
		delbox.pack_start(bakquest, false, false, 0)
		delalign = Gtk::Alignment.new(0.11, 0.0, 0.11, 0.0)
		delalign.add delbox
		locradio = Gtk::RadioButton.new(@tl.get_translation("action3"))
		usbradio = Gtk::RadioButton.new(locradio, @tl.get_translation("action4"))
		locradio.sensitive = @delete_on_failed_desinfect && @backup_before_action
		usbradio.sensitive = false 
		bakbox = Gtk::VBox.new(false, 0)
		bakbox.pack_start(locradio, false, false, 0)
		bakbox.pack_start(usbradio, false, false, 0)
		bakalign = Gtk::Alignment.new(0.20, 0.0, 0.20, 0.0)
		bakalign.add bakbox
		delquest.active = @delete_on_failed_desinfect
		delquest.signal_connect("clicked") { 
			@delete_on_failed_desinfect = delquest.active? 
			if delquest.active? 
				trcquest.sensitive = true
				bakquest.sensitive = true
				locradio.sensitive = @delete_on_failed_desinfect && @backup_before_action
			else
				trcquest.sensitive = false
				bakquest.sensitive = false
				locradio.sensitive = @delete_on_failed_desinfect && @backup_before_action
			end
		}
		trcquest.active = @truncate_instead_delete
		trcquest.signal_connect("clicked") { @truncate_instead_delete = trcquest.active? }
		bakquest.active = @backup_before_action
		bakquest.signal_connect("clicked") { 
			@backup_before_action = bakquest.active? 
			if bakquest.active?
				locradio.sensitive = true
			else
				locradio.sensitive = false
			end
		}
		usbradio.active = true if @localbackup == false
		locradio.signal_connect("clicked") { @localbackup = true if locradio.active? }
		usbradio.signal_connect("clicked") { @localbackup = false if usbradio.active? }
		[ legalign, delquest, delalign ].each { |b| outbox.pack_start(b, false, false, 2) } 
		dialog.vbox.add(outbox)
		dialog.signal_connect('response') { dialog.destroy }
		dialog.show_all
		
	end
	
	def kill_desinfection
		@killed = true
		# @progress.text = "Desinfektion wird abgebrochen"
		@desinfbutton.sensitive = false
		@desinfbutton.label = "Start"
	end
	
	# FIXME! External drives still missing!
	def run_desinfection
		@desinf_runmode = false
		@desinfbutton.label = @tl.get_translation("killbutton") 
		@again_button.sensitive = false
		@confbutton.sensitive = false
		checked_uuids = Array.new
		@scanner.infections.each { |k,v| 
			checked_uuids.push(k.uuid) unless v.nil? 
			#puts v.to_s 
		}
		( @int_drives + @ext_drives ).each { |d|
			d.partitions.each { |p|
				if checked_uuids.include?(p.uuid)
					p.mount("rw")
					puts d.device.to_s + " " + p.device.to_s + " " + p.uuid.to_s + " - " + p.mount_point[0].to_s 
					inf = @scanner.infections[p]
					unless inf.nil?
						inf.each { |i|
							choice = -1
							unless @killed == true
								skip_this = false
								puts i.uuid + " - " + i.relpath + " - "  + i.raw_infection 
								backup_success = i.create_backup(p.mount_point[0], @delete_on_failed_desinfect, @truncate_instead_delete, @backup_before_action, @localbackup, @progress)
								if backup_success == false
									choice = backup_failed_dialog(i.relpath.split("/")[-1])
									puts "Auswahl: #{choice.to_s}"
									if choice < 1
										skip_this = true
									elsif choice == 2
										@backup_before_action = false
									elsif choice == 3
										skip_this = true
										kill_desinfection
									end
								end
								i.desinfect(p.mount_point[0], @delete_on_failed_desinfect, @truncate_instead_delete, @backup_before_action, @localbackup, @progress) if skip_this == false
							end
						}
					end
					p.umount
				end
			}
		}
		@scanner.dump_html_log
		@spec_drives.each { |p|
			if checked_uuids.include?(p.uuid)
				# p.mount("rw")
				puts p.device.to_s + " " + p.uuid.to_s + " - " + p.mount_point[0].to_s 
				inf = @scanner.infections[p]
				unless inf.nil?
					inf.each { |i|
						choice = -1
						unless @killed == true
							skip_this = false
							puts i.uuid + " - " + i.relpath + " - "  + i.raw_infection 
							backup_success = i.create_backup(p.mount_point[0], @delete_on_failed_desinfect, @truncate_instead_delete, @backup_before_action, @localbackup, @progress)
							if backup_success == false
								choice = backup_failed_dialog(i.relpath.split("/")[-1])
								puts "Auswahl: #{choice.to_s}"
								if choice < 1
									skip_this = true
								elsif choice == 2
									@backup_before_action = false
								elsif choice == 3
									skip_this = true
									kill_desinfection
								end
							end
							i.desinfect(p.mount_point[0], @delete_on_failed_desinfect, @truncate_instead_delete, @backup_before_action, @localbackup, @progress) if skip_this == false
						end
					}
				end
			end
		}
		@progress.fraction = 1.0
		@progress.text = @tl.get_translation("pgclean-done") 
		@progress.text = @tl.get_translation("pgclean-cancelled") if @killed == true
		AntibotMisc.info_dialog(@tl.get_translation("pgclean-ok")) if @killed == false
		AntibotMisc.info_dialog(@tl.get_translation("pgclean-cancelled2") ) if @killed == true
		@again_button.sensitive = true
		@assistant.set_page_side_image(@wdgt, Gdk::Pixbuf.new("DE-Cleaner-Rettungssystem-2012-6a.png")) unless @killed == true
		@assistant.set_page_complete(@wdgt, true)
	end
	
	def backup_failed_dialog(fname)
		dialog = Gtk::Dialog.new(@tl.get_translation("backup-title"),
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NO ]
			     )
		info = Gtk::Label.new(@tl.get_translation("backup-title").gsub("FILENAME", fname) )
		info.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		vbox = Gtk::VBox.new(false, 5)
		oct = 0
		hbox.pack_start_defaults image
		hbox.pack_start_defaults info
		vbox.pack_start_defaults hbox
		radios = Array.new
		[ 	@tl.get_translation("backup-radio0"), @tl.get_translation("backup-radio1"),
			@tl.get_translation("backup-radio2"), @tl.get_translation("backup-radio3") ].each { |opt|
			if oct < 1
				radios.push Gtk::RadioButton.new(opt)
				vbox.pack_start_defaults radios[oct]
			else
				radios.push Gtk::RadioButton.new(radios[0], opt)
				vbox.pack_start_defaults radios[oct] 
			end
			oct += 1
		}
		dialog.vbox.add(vbox)
		dialog.show_all
		dialog.run { |resp|
			active = -1
			0.upto(radios.size - 1) { |n|
				if radios[n].active?
					puts "Button #{n.to_s} is active!"
					active = n
				end
			}
			dialog.destroy
			return active
		}
	end
	
end
