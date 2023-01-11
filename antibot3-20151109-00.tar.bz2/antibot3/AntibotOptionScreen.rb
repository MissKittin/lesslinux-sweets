#!/usr/bin/ruby
# encoding: utf-8

class AntibotOptionScreen
	
	def initialize
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		tlfile = "AntibotOptionScreen.xml"
		tlfile = "/usr/share/lesslinux/antibot3/AntibotOptionScreen.xml" if File.exists?("/usr/share/lesslinux/antibot3/AntibotOptionScreen.xml")
		@tl = MfsTranslator.new(lang, tlfile)
		# Defaults for settings
		@methods = [ @tl.get_translation("method0") , @tl.get_translation("method1") , @tl.get_translation("method2") ]
		#@methods = [ "Alle Dateien werden untersucht",
		#	"Avira entscheidet selbst, welche Dateien untersucht werden",
		#	"Bootsektoren werden nach Schädlingen durchsucht" ]
		@methods_short = [ "all", "auto", "boot" ]
		@method_sel = 0
		@extended = [ @tl.get_translation("extended0") , @tl.get_translation("extended1") , 
			@tl.get_translation("extended2"), @tl.get_translation("extended3") , 
			@tl.get_translation("extended4") , @tl.get_translation("extended5"), 
			@tl.get_translation("extended6") , @tl.get_translation("extended7") ]
		#@extended = [ "Einwahlprogramme (Dialer)",
		#	"Dateien mit verschleierten Endungen",
		#	"Programme, die Ihre Privatsphäre verletzen",
		#	"Ungewöhnliches Packprogramm",
		#	"Phishing",
		#	"Backdoor-Clients", 
		#	"Scherzprogramme",
		#	"Computerspiele" ]			
		# @method_short = "all" # Others: "auto", "boot"
		@extended_short = [ "dial", "heur-dblext", "adspy", "pck", "phish", "bcd", "joke", "game" ] 
		@actions = [ @tl.get_translation("action0") , @tl.get_translation("action1") , @tl.get_translation("action2") ]
		# @actions = [ "Schädlingsfund protokollieren, spätere Entscheidung im Einzelfall",
		#	"Infizierte Dateien löschen",
		#	"Infizierte Dateien reparieren" ]
		@actions_short = [ "protocol", "delete", "repair" ]
		@action_sel = 2
		@details = [ @tl.get_translation("detail0"), @tl.get_translation("detail1") ]
		# @details = [ "Datei umbenennen wenn Reparatur nicht möglich",
		#	"Datei löschen, wenn Reparatur nicht möglich" ]
		@details_short = [ "rename", "delete" ]
		@detail_sel = 0
		@extended_defaults =  [ true, true, true, true, false, false, false, false ]
		@extended_checks =    [ true, true, true, true, false, false, false, false ]
		@action_radio = 0
		@detail_radio = 0
		# Widget to be shown in the assistent
		# @wdgt = Gtk::Frame.new("Einstellungen für den Virenscan")
		@wdgt = Gtk::Alignment.new(0.5, 0.5, 0.8, 0.0)
		@mlabel = Gtk::Label.new(@methods[0])
		@elabel = Gtk::Label.new(@tl.get_translation("extended-title"))
		@alabel = Gtk::Label.new(@actions[0])
		@stab = Gtk::Table.new(1, 2, false)
		n = 0
		[ @mlabel, @elabel, @alabel ].each { |l|
			a = Gtk::Alignment.new(0.0, 0.0, 0.0, 0.0)
			a.add l
			@stab.attach(Gtk::Image.new("icons/ok48.png"), 0, 1, n, n+1, nil, Gtk::SHRINK, 5, 5)
			# @stab.attach(Gtk::Image.new(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON), 0, 1, n, n+1, nil, Gtk::SHRINK, 5, 5)
			@stab.attach(a, 1, 2, n, n+1, nil, Gtk::SHRINK, 5, 5)
			n += 1
		}
		@optbutton = Gtk::Button.new(@tl.get_translation("button-title"))
		@optbutton.width_request = 90
		@optbutton.signal_connect('clicked') { show_options }
		# stab.attach(optbutton, 0, 2, 3, 4, nil, Gtk::SHRINK, 5, 5)
		# @wdgt.add stab
		@wdgt.add Gtk::Label.new("Placeholder, should not be shown...")
	end
	attr_reader :stab, :wdgt, :extended_checks, :extended_short, :methods_short, :methods_sel, :actions_short, :action_sel, :details_short, :detail_sel
	attr_accessor :optbutton
	
	def show_options
		frame_width = 560
		# Create the dialog
		dialog = Gtk::Dialog.new("Einstellungen der Virensuche",
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ])
		ovbox = Gtk::VBox.new(false, 6)
		frames = Array.new
		[ @tl.get_translation("frame0"), @tl.get_translation("frame1"), @tl.get_translation("frame2") ].each { |s| frames.push(Gtk::Frame.new(s)) }
		# Frame for scan method
		mct = 0
		method_radio = Array.new
		mvbox = Gtk::VBox.new(false, 6)
		@methods.each { |m|
			if mct == 0
				method_radio[mct] = Gtk::RadioButton.new(m)
			else
				method_radio[mct] = Gtk::RadioButton.new(method_radio[0], m)
			end
			method_radio[mct].active = true if mct == @method_sel
			mvbox.pack_start(method_radio[mct], false, false, 0)
			mct += 1 
		}
		0.upto(method_radio.size - 1) { |n|
			method_radio[n].signal_connect('clicked') {  
				@mlabel.text = @methods[n]
				@method_sel = n
			}
		}
		frames[0].add mvbox
		# Frame for extended categories
		exttab = Gtk::Table.new( 2, (@extended.size + 1) / 2, false)
		ext_checks = Array.new
		ect = 0
		@extended.each { |e|
			ext_checks[ect] = Gtk::CheckButton.new(e)
			ext_checks[ect].active = @extended_checks[ect]
			exttab.attach(ext_checks[ect], ect%2, ect%2 + 1, ect/2, ect/2 + 1, nil, nil, 4, 4)
			ect += 1
		}
		0.upto(ext_checks.size - 1) { |n|
			ext_checks[n].signal_connect('clicked') { 
				@extended_checks[n] = ext_checks[n].active?
				@elabel.text = @tl.get_translation("extended-title") if @extended_checks == @extended_defaults
				@elabel.text = @tl.get_translation("extended-custom") unless @extended_checks == @extended_defaults
			}
		}
		frames[1].add exttab
		# Detailed actions for failed cleaning
		actdet_align = Gtk::Alignment.new(0.1, 0, 0, 0)
		actdet_vbox = Gtk::VBox.new(false, 5)
		actdet_radio = Array.new
		actdet_radio[0] = Gtk::RadioButton.new(@details[0])
		actdet_radio[1] = Gtk::RadioButton.new(actdet_radio[0], @details[1])
		actdet_radio[@detail_sel].active = true
		actdet_radio.each { |i| actdet_vbox.pack_start(i, false, false, 0) }
		actdet_align.add actdet_vbox
		
		# Frame for decision what to do with infected files
		act = 0
		action_radio = Array.new
		avbox = Gtk::VBox.new(false, 6)
		@actions.each { |a|
			if act == 0
				action_radio[act] = Gtk::RadioButton.new(a)
			else
				action_radio[act] = Gtk::RadioButton.new(action_radio[0], a)
			end
			action_radio[act].active = true if act == @action_sel
			if act == 2 && act == @action_sel
				actdet_radio.each { |r| r.sensitive = true }
			else
				actdet_radio.each { |r| r.sensitive = false }
			end
			avbox.pack_start(action_radio[act], false, false, 0)
			act += 1 
		}
		avbox.pack_start(actdet_align, false, false, 0) 
		frames[2].add avbox
		0.upto(action_radio.size - 1) { |n|
			action_radio[n].signal_connect('clicked') {  
				@alabel.text = @actions[n]
				@action_sel = n
				if n == 2
					actdet_radio.each { |r| r.sensitive = true }
				else
					actdet_radio.each { |r| r.sensitive = false }
				end
			}
		}
		0.upto(actdet_radio.size - 1) { |n|
			actdet_radio[n].signal_connect('clicked') {  
				@detail_sel = n
			}
		}
		
		frames.each { |f| 
			f.width_request = frame_width
			ovbox.pack_start(f, false, false, 0)
		} 
		oscrl = Gtk::ScrolledWindow.new
		oscrl.width_request = 570
		oscrl.height_request = 370
		oscrl.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		oscrl.add_with_viewport ovbox
		dialog.vbox.add(oscrl)
		dialog.signal_connect('response') { dialog.destroy }
		dialog.show_all
	end
	
	def parameter_array
		params = Array.new
		
		# first frame 
		if @method_sel == 0
			$stderr.puts("scanmethod: allfiles")
			params.push("--allfiles")
		elsif @method_sel == 1
			$stderr.puts("scanmethod: intelligent")
			params.push("--smartextensions")
		elsif @method_sel == 2 && @action_sel > 0
			$stderr.puts("scanmethod: bootonly")
			params.push("--fixallboot")
		elsif @method_sel == 2
			$stderr.puts("scanmethod: bootonly")
			params.push("--allboot")
		end
		
		# second frame "what to do"
		if @action_sel == 0
			$stderr.puts("action: protocol only")
			params.push("--defaultaction=ignore")
		elsif @action_sel == 1 
			$stderr.puts("action: delete infected")
			params.push("--defaultaction=delete,delete-archive")
		elsif @action_sel == 2
			$stderr.puts("action: repair infected")
			if @detail_sel > 0
				$stderr.puts("action: delete if no repair")
				params.push("--defaultaction=clean,delete,delete-archive")
			else
				$stderr.puts("action: rename if no repair")
				params.push("--defaultaction=clean,rename")
			end
		end
		extended = Array.new
		0.upto(@extended_checks.size - 1) { |i|
			extended.push(@extended_short[i]) if @extended_checks[i] == true 
		}
		params.push("--withtype=" + extended.join(',')) if extended.size > 0
		if File.directory? "/var/log/antibot3"
			params.push("--log=/var/log/antibot3/scancl.log")
		else
			params.push("--log=/dev/null")
		end
		params.push("--heurlevel=2")
		params.push("--nolinks")
		params.push("--showall")
		archmax = get_archive_maxsize
		if archmax > 0 
			params.push("-z")
			params.push("--archivemaxsize=" + archmax.to_s + "MB")
		end
		# scan an empty directory if the user chooses to scan only bootsectors
		# this is a weird hack to emulate the behaviour of the old --bootonly
		if @method_sel == 2
			system("mkdir -p /tmp/.empty")
			params.push("/tmp/.empty")
		end
		
		return params
		
	end
	
	def get_archive_maxsize
		tmpstats=` df -k /tmp | tail -n1 `
		free_tmp_megs = tmpstats.split[3].to_i / 1024
		return 4096 if free_tmp_megs - 100 > 4096
		return free_tmp_megs - 100
	end
	
end

