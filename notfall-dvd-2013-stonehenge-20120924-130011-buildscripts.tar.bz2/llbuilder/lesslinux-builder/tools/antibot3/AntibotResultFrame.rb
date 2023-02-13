#!/usr/bin/ruby
# encoding: utf-8

class AntibotResultFrame	
	def initialize(assi)
		icon_theme = Gtk::IconTheme.default
		@killed = false
		@infected = nil
		@scanner = nil
		@int_drives = nil
		@ext_drives = nil
		@delete_on_failed_desinfect = false
		@truncate_instead_delete = true
		@backup_before_action = true
		@localbackup = true
		@assistant = assi
		@wdgt = Gtk::Alignment.new(0.5, 0.5, 0.8, 0.0)
		@vbox = Gtk::VBox.new(false, 5)
		@children = Array.new
		image = Gtk::Image.new("icons/warning32.png")
		@ctext = Gtk::Label.new("Die Überprüfung wurde unerwartet beendet. Die angezeigten Ergebnisse sind daher unvollständig!")
		@ctext.wrap = true
		calign = Gtk::Alignment.new(0.0, 0.0, 0.0, 0.0)
		calign.add @ctext
		@ctext.width_request = 495
		@children.push Gtk::HBox.new(false, 5)
		@children[0].pack_start(image, false, false, 1)
		@children[0].pack_start(calign, true, true, 1)
		@children[0].width_request = 550
		@children.push(Gtk::Label.new("Es wurde keine Schadsoftware gefunden. Führen Sie den Scan im monatlichen Abstand erneut aus. Wählen Sie \"Schließen\", um den Computer neu zu starten.\n\n<b>Mit Schadsoftware infizierte Dateien: keine</b>"))
		@children[1].wrap = true
		@children[1].use_markup = true
		@children[1].width_request = 550
		@children.push(Gtk::Label.new("Es wurden %FILECOUNT% Datei(en) gefunden, die mit Schadsoftware infiziert sind. Sie können nun festlegen, was mit diesen Dateien geschehen soll und anschließend eine Reinigung durchführen lassen. Für den Fall, dass sehr viele infizierte Dateien gefunden wurden, klicken Sie auf „Neue Prüfung“ und starten die Überprüfung erneut. Wählen Sie dabei die Option „sofortige Desinfektion“ in den „Einstellungen“.\n\n<b>Mit Schadsoftware infizierte Dateien: %FILECOUNT%</b>\n\nKlicken Sie auf „Starten“, um die Reinigung zu beginnen."))
		@children[2].wrap = true
		@children[2].use_markup = true
		@children[2].width_request = 550
		@children.push Gtk::HBox.new(false, 3)
		@progress = Gtk::ProgressBar.new
		# @progress.width_request = 330
		@children[3].width_request = 550 
		@children[3].pack_start(@progress, true, true, 3)
		@confbutton = Gtk::Button.new("Auswahl")
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
		@again_button.label = "_Neue Prüfung"
		@again_button.image = Gtk::Image.new(icon_theme.load_icon("go-first", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
		@again_button.signal_connect("clicked") { @assistant.current_page = 0 }
		@log_button = Gtk::Button.new
		@log_button.use_underline = true
		@log_button.label = "_Protokolle"
		@log_button.image = Gtk::Image.new(icon_theme.load_icon("applications-system", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
		@log_button.signal_connect("clicked") { 
			unless @scanner.logdir.nil?
				system("su surfer -c 'Thunar #{@scanner.logdir}' &")
			else
				system("su surfer -c 'Thunar /tmp/Protokolle' &")
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
	
	def show_results(int_drives, ext_drives, scanner)
		@killed = false
		@desinf_runmode = true
		@desinfbutton.label = "Start"
		@progress.fraction = 0.0
		@progress.text = ""
		@scanner = scanner
		@int_drives = int_drives
		@ext_drives = ext_drives
		@again_button.sensitive = true
		@confbutton.sensitive = true
		@desinfbutton.sensitive = true
		@again_button.show_all
		@log_button.show_all
		puts "Infections total: " + @scanner.inf_count.to_s
		@children.each { |w| w.hide_all }
		failed_parts = Array.new
		@scanner.return_codes.each { |k, r| failed_parts.push(k.device) if r > 101 }
		@ctext.text = "Die Überprüfung wurde unerwartet beendet. Bei der Untersuchung des Laufwerks #{failed_parts.join(', ')} gab es einen Fehler. Die angezeigten Ergebnisse sind daher unvollständig!"  if failed_parts.size > 0
		@ctext.text = "Die Überprüfung wurde vom Benutzer abgebrochen! Das angezeigte Ergebnis ist daher wahrscheinlich unvollständig."  if @scanner.killed == true
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
			@assistant.set_page_title(@wdgt, "Virensuche abgeschlossen")
			@assistant.set_page_complete(@wdgt, true)
		elsif @scanner.params.include?("--defaultaction=ignore")
			@assistant.set_page_side_image(@wdgt, Gdk::Pixbuf.new("DE-Cleaner-Rettungssystem-2012-6b.png"))
			@children[3].show_all
			# @children[2].text = "Es wurden %FILECOUNT% Datei(en) gefunden, die mit Schadsoftware infiziert sind. Sie können nun festlegen, was mit diesen Dateien geschehen soll und anschließend eine Reinigung durchführen lassen. Für den Fall, dass sehr viele infizierte Dateien gefunden wurden, klicken Sie auf „Neue Prüfung“ und starten die Überprüfung erneut. Wählen Sie dabei die Option „sofortige Desinfektion“ in den „Einstellungen“.\n\n<b>Mit Schadsoftware infizierte Dateien: %FILECOUNT%</b>%SUFFVIR%\n\nKlicken Sie auf „Starten“, um die Reinigung zu beginnen.".gsub("%FILECOUNT%", @scanner.inf_count.to_s).gsub("%SUFFVIR%", get_vir_suffix)
			# {fettdruck}Achtung: Auf Ihrem Computer wurden %FILECOUNT% Datei(en) entdeckt, die mit Schadsoftware infiziert sind. 
			#{if %VIRFILECOUNT%>0}Davon haben %VIRFILECOUNT% die Dateiendung .vir, was auf eine vorherige Umbenennung mit der Antibot-CD hinweist.
			#
			#Über "Auswahl" können Sie nun für jede infizierte Datei festlegen, was damit geschehen soll.  Klicken Sie auf "Starten" um mit dem Reinigungsprozess zu beginnen.
			#
			# Noch ein Hinweis:
			# Falls auf Ihrem Computer mehrere Dutzend Schädlinge entdeckt wurden, müssen Sie bei dieser Methode sehr viele Eingaben machen.
			# Wenn Sie das nicht möchten, sollten Sie lieber zur automatischen Desinfektion wechseln.
			# Dabei werden infizierte Dateien nach Möglichkeit automatisch desinfiziert oder - falls dies nicht möglich ist - mit der zusätzlichen Dateiendung ".vir" gespeichert.
			# Ist diese Methode für Ihren Fall besser? Dann klicken Sie jetzt auf "Neue Prüfung" und wählen dann nach einem Klick auf die Schaltfläche "Einstellungen" die Option "sofortige Desinfektion" aus.
			@children[2].text = "<b>Achtung: Auf Ihrem Computer wurden %FILECOUNT% Datei(en) entdeckt, die mit Schadsoftware infiziert sind</b>%SUFFVIR%.\n\nÜber \"Auswahl\" können Sie nun für jede infizierte Datei festlegen, was damit geschehen soll.  Klicken Sie auf \"Starten\", um mit dem Reinigungsprozess zu beginnen.\n\nNoch ein Hinweis: Falls auf Ihrem Computer mehrere Dutzend Schädlinge entdeckt wurden, müssen Sie bei dieser Methode sehr viele Eingaben machen. Wenn Sie das nicht möchten, sollten Sie lieber zur automatischen Desinfektion wechseln. Dabei werden infizierte Dateien nach Möglichkeit automatisch desinfiziert oder - falls dies nicht möglich ist - mit der zusätzlichen Dateiendung \".vir\" gespeichert. Ist diese Methode für Ihren Fall besser? Dann klicken Sie jetzt auf \"Neue Prüfung\" und wählen dann nach einem Klick auf die Schaltfläche \"Einstellungen\" die Option \"sofortige Desinfektion\" aus.".gsub("%FILECOUNT%", @scanner.inf_count.to_s).gsub("%SUFFVIR%", get_vir_suffix)
			@children[2].use_markup = true
			@children[2].show_all
			@assistant.set_page_title(@wdgt, "Virensuche abgeschlossen - Desinfektion")
		else
			@assistant.set_page_side_image(@wdgt, Gdk::Pixbuf.new("DE-Cleaner-Rettungssystem-2012-6a.png"))
			@children[2].text = "Es wurden %FILECOUNT% Datei(en) gefunden, die mit Schädlingen infiziert sind. Die entdeckten Schädlinge wurden bereits während der Überprüfung unschädlich gemacht. Zur Sicherheit sollten Sie die Überprüfung im monatlichen Abstand wiederholen.\n\n<b>Mit Schadsoftware infizierte Dateien: %FILECOUNT%</b>%SUFFVIR%".gsub("%FILECOUNT%", @scanner.inf_count.to_s).gsub("%SUFFVIR%", get_vir_suffix)
			@children[2].use_markup = true
			@children[2].show_all
			@assistant.set_page_title(@wdgt, "Virensuche abgeschlossen")
			@assistant.set_page_complete(@wdgt, true)
		end
	end
	
	def get_vir_suffix 
		if @scanner.vir_count == @scanner.inf_count
			return " (davon tragen alle bereits die Endung .vir, was auf eine erfolgreiche Umbenennung in einer vorherigen Prüfung hinweist)"
		elsif @scanner.vir_count > 1
			return " (davon tragen #{@scanner.vir_count} die Endung .vir, was auf eine erfolgreiche Umbenennung in einer vorherigen Prüfung hinweist)"
		elsif @scanner.vir_count == 1
			return " (davon trägt eine die Endung .vir, was auf eine erfolgreiche Umbenennung in einer vorherigen Prüfung hinweist)"
		end
		return ""
	end
	
	# FIXME! External drives still missing!
	def show_configuration
		inf_count = 0 
		# puts @scanner.to_s
		# Create the dialog
		dialog = Gtk::Dialog.new("Einstellungen für Desinfektion",
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
						note = " - " + tlines.size.to_s + " Fund(e)"
						ls = [ "", "N", "D", "L", "Infizierte Datei", "Schadsoftware" ]
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
						note = " - kein Fund"
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
		oscrl = Gtk::ScrolledWindow.new
		oscrl.width_request = 730
		oscrl.height_request = 350
		oscrl.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		oscrl.add_with_viewport vbox
		
		leg = Gtk::Label.new("Mögliche Optionen für die Desinfektion: <b>N</b> - nichts tun, <b>D</b> - desinfizieren, <b>L</b> - löschen")
		leg.use_markup = true
		legalign =Gtk::Alignment.new(0.0, 0.0, 0.0, 0.0)
		legalign.add leg
		
		outbox = Gtk::VBox.new(false, 0)
		outbox.pack_start(oscrl, true, true, 0)
		delquest = Gtk::CheckButton.new("Löschen, wenn Desinfektion nicht möglich")
		delbox = Gtk::VBox.new(false, 0)
		trcquest = Gtk::CheckButton.new("Datei auf Größe Null schrumpfen statt entfernen")
		trcquest.sensitive = @delete_on_failed_desinfect
		bakquest = Gtk::CheckButton.new("Vor Löschen Sicherung erstellen")
		bakquest.sensitive = @delete_on_failed_desinfect
		delbox.pack_start(trcquest, false, false, 0)
		delbox.pack_start(bakquest, false, false, 0)
		delalign = Gtk::Alignment.new(0.11, 0.0, 0.11, 0.0)
		delalign.add delbox
		locradio = Gtk::RadioButton.new("Sicherung neben infizierter Datei erstellen")
		usbradio = Gtk::RadioButton.new(locradio, "Sicherung auf USB-Laufwerk erstellen")
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
		@desinfbutton.label = "Abbrechen"
		@again_button.sensitive = false
		@confbutton.sensitive = false
		checked_uuids = Array.new
		@scanner.infections.each { |k,v| 
			checked_uuids.push(k.uuid) unless v.nil? 
			#puts v.to_s 
		}
		( @int_drives + @ext_drives).each { |d|
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
		@progress.fraction = 1.0
		@progress.text = "Desinfektion abgeschlossen"
		@progress.text = "Desinfektion abgebrochen" if @killed == true
		AntibotMisc.info_dialog("Die Desinfektion wurde mit den gewünschten Einstellungen abgeschlossen. Ein Protokoll wurde gespeichert. Zur Sicherheit wiederholen Sie die Überprüfung im monatlichen Abstand.") if @killed == false
		AntibotMisc.info_dialog("Die Desinfektion wurde abgebrochen! Die gespeicherten Protokolle zeigen alle Dateien an, die vor dem Abbruch desinfiziert wurden.") if @killed == true
		@again_button.sensitive = true
		@assistant.set_page_side_image(@wdgt, Gdk::Pixbuf.new("DE-Cleaner-Rettungssystem-2012-6a.png")) unless @killed == true
		@assistant.set_page_complete(@wdgt, true)
	end
	
	def backup_failed_dialog(fname)
		dialog = Gtk::Dialog.new("Sicherung fehlgeschlagen",
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NO ]
			     )
		info = Gtk::Label.new("Die Sicherung der Datei #{fname} ist leider fehlgeschlagen. Mögliche Ursachen sind zu wenig Speicherplatz oder die Datei existiert bereits. Was möchten Sie jetzt tun?")
		info.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		vbox = Gtk::VBox.new(false, 5)
		oct = 0
		hbox.pack_start_defaults image
		hbox.pack_start_defaults info
		vbox.pack_start_defaults hbox
		radios = Array.new
		[ 	"Diese Datei weder sichern, löschen, noch desinfizieren",
			"Diese Datei nicht sichern aber möglichst desinfizieren.\nWenn eine Desinfektion nicht möglich ist, die Datei löschen ",
			"Diese und alle weiteren Dateien ohne Sicherung möglichst desinfizieren.\nWenn eine Desinfizierung nicht möglich ist, die Datei löschen.",
			"Die Desinfektion abbrechen" ].each { |opt|
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
