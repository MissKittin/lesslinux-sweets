#!/usr/bin/ruby
# encoding: utf-8

class AntibotScanFrame
	
	def initialize(assi, drvscreen, optscreen, prereqscreen, starttime=nil)
		@killed = false
		# @wdgt = Gtk::Frame.new("Virenscan durchführen")
		@wdgt = Gtk::Alignment.new(0.5, 0.5, 0.8, 0.0)
		@assistent = assi
		@drivescreen = drvscreen
		@optionscreen = optscreen
		@prereqscreen = prereqscreen
		@starttime = starttime
		@starttime = Time.now if @starttime.nil?
		@scanner = nil
		scanlabel = Gtk::Label.new("Um den Computer mit den empfohlenen Einstellungen zu überprüfen, klicken Sie auf „Starten“. Nur wenn Sie die Suchoptionen noch verändern wollen, müssen Sie zuvor auf „Einstellungen“ klicken.")
		# Der Virenscan kann je nach Geschwindigkeit des Computers und Festplattenbelegung zwischen wenigen Minuten und vielen Stunden dauern. Ein Abbruch ist jederzeit möglich.")
		scanlabel.wrap = true
		scanlabel.width_request = 540
		scanvbox = Gtk::VBox.new(false, 3)
		scanvbox.pack_start(scanlabel, false, false, 5)
		# FIXME: Fine tuning necessary here...
		# :mlabel, :elabel, :alabel,
		# scanvbox.pack_start(@optionscreen.stab, false, false, 5)
		# scanvbox.pack_start(@optionscreen.optbutton, false, false, 5)
		@progress = Gtk::ProgressBar.new
		# @progress.width_request = 500
		#scanvbox.pack_start(@progress, false, false, 5)
		#buttonbox = Gtk::HBox.new(true, 3)
		@confirm = Gtk::Button.new("Starten")
		@cancel = Gtk::Button.new("Abbrechen")
		[ @confirm, @cancel ].each { |b| b.width_request = 90 }
		confirm_mode = true
		@confirm.signal_connect("clicked") {
			if confirm_mode == true
				@killed = false
				@optionscreen.optbutton.sensitive = false
				confirm_mode = false
				@confirm.label = "Abbrechen"
				@assistent.set_page_type(@wdgt, Gtk::Assistant::PAGE_PROGRESS)
				@assistent.set_page_complete(@wdgt, false)
				# @cancel.sensitive = true
				# @confirm.sensitive = false
				@progress.activity_mode = true
				run_scan
				@progress.activity_mode = false
				# @cancel.sensitive = false
				# @confirm.sensitive = true
				confirm_mode = true
				@confirm.label = "Starten"
				@confirm.sensitive = true
				@optionscreen.optbutton.sensitive = true
				# @assistent.set_page_type(@wdgt, Gtk::Assistant::PAGE_PROGRESS)
				@assistent.set_page_complete(@wdgt, true)
			else
				@confirm.sensitive = false
				@assistent.set_page_type(@wdgt, Gtk::Assistant::PAGE_PROGRESS)
				@assistent.set_page_complete(@wdgt, true)
				# @cancel.sensitive = false
				kill_scan
				# @confirm.sensitive = true
			end
		}
		@cancel.signal_connect("clicked") {
			# @assistent.set_page_type(@wdgt, Gtk::Assistant::PAGE_PROGRESS)
			# @assistent.set_page_complete(@wdgt, true)
			@cancel.sensitive = false
			kill_scan
			# @confirm.sensitive = true
		}
		@cancel.sensitive = false
		#buttonbox.pack_start(@cancel, true, true, 2)
		#buttonbox.pack_start(@confirm, true, true, 2)
		#scanvbox.pack_start(buttonbox, false, false, 5)
		
		proghbox = Gtk::HBox.new(false, 3)
		proghbox.width_request = 540 
		proghbox.pack_start(@progress, true, true, 3)
		proghbox.pack_start(@optionscreen.optbutton, false, false, 0)
		proghbox.pack_start(@confirm, false, false, 0)
		scanvbox.pack_start(proghbox, false, false, 5)
		
		@wdgt.add scanvbox
		
	end
	attr_accessor :wdgt, :scanner
	attr_reader :killed
	
	def kill_scan
		@killed = true
		@scanner.kill_scan
		@progress.fraction = 1.0
		@progress.text = "Der Virenscan wurde abgebrochen"
	end
	
	def run_scan
		msg = "Something strange happened..."
		logdir = nil
		if system("mountpoint -q /lesslinux/antibot")
			logdir = "/lesslinux/antibot/antibot3/Protokolle/" + @starttime.strftime("%Y%m%d-%H%M%S") 
			system("mkdir -p '#{logdir}'")
		end
		system("dmidecode -t system > '/var/log/antibot3/computer-identifikation.txt'")
		@scanner = AntibotAviraScanner.new(@drivescreen, @optionscreen.parameter_array, logdir)
		success, msg = @scanner.update_signatures(14400, @prereqscreen.proxy_parameters, @progress)
		# return 1
		if success == false
			d = dialog_general_info("Update fehlgeschlagen", msg.to_s)
			puts d.to_s
			return false if d == false
		end
		funct, code = @scanner.check_avira(@progress)
		if funct == false && code == 214
			d = dialog_general_error("Lizenzdatei zu alt", "Die Informationen über Schädlinge sind zu alt, daher ist eine Aktualisierung zwingend erforderlich.")
			system("touch -d '1970-01-02 00:00:00' /AntiVir/rescue_cd.key")
			@killed = true
			@assistent.set_page_complete(@wdgt, true)
			return false
		elsif funct == false
			puts "killed? " + @killed.to_s
			d = dialog_general_error("scancl defekt", "Die Überprüfung konnte nicht gestartet werden oder wurde abgebrochen. Möglicherweise ist die Installation beschädigt.") unless @scanner.killed == true
			@killed = true
			@assistent.set_page_complete(@wdgt, true)
			return false
		end
		@scanner.prepare_scan(@progress)
		@scanner.run_scan(@progress) unless @scanner.killed == true
		@scanner.dump_html_log
		@assistent.set_page_complete(@wdgt, true)
		@assistent.current_page = @assistent.current_page + 1 if @scanner.return_codes.size > 0
	end
	
	def dialog_general_info(head, message)
		dialog = Gtk::Dialog.new(
			head,
			$main_application_window,
			Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ],
			[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ]
		)
		dialog.has_separator = false
		label = Gtk::Label.new(message)
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image);
		hbox.pack_start_defaults(label);
		dialog.vbox.add(hbox)
		dialog.default_response = Gtk::Dialog::RESPONSE_CANCEL
		dialog.show_all
		retval = false
		dialog.run { |response|
			case response
			when Gtk::Dialog::RESPONSE_OK
				puts "OK clicked!"
				retval = true
			else
				puts "Cancel clicked!"
				retval = false
			end
		}
		dialog.destroy
		return retval
	end
	
	def dialog_general_error(head, message)
		dialog = Gtk::Dialog.new(
			head,
			$main_application_window,
			Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.has_separator = false
		label = Gtk::Label.new(message)
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image);
		hbox.pack_start_defaults(label);
		dialog.vbox.add(hbox)
		dialog.default_response = Gtk::Dialog::RESPONSE_NONE
		dialog.show_all
		retval = false
		dialog.run { |response|
			# 
		}
		dialog.destroy
		return retval
	end
	
end