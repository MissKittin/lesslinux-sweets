#!/usr/bin/ruby
# encoding: utf-8

require 'MfsSysProfile'
require 'hivex'

class PcInspectorScreen	
	def initialize(extlayers, button, nwscreen, usbrescbutton, simulate=nil)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@lang = lang
		@tl = MfsTranslator.new(lang, "PcInspectorScreen.xml")
		@extlayers = extlayers
		@layers = Array.new
		@simulate = simulate
		@urllabel = Gtk::Label.new
		## table for first SMART read out
		@smarttab = nil
		@smart_quick_icons = Array.new
		@smart_quick_descriptions = Array.new
		## progressbar for SMART self test routine
		@smart_progress = nil
		@break_smart_test = nil
		## table for second SMART readout
		@smartsumtab = nil
		@smart_detail_icons = Array.new
		@smart_detail_descriptions = Array.new
		## Button and description to jump to save function
		@save_button = nil
		@save_text = nil
		## Button and progress bar for CPU burn
		@cpuburnprogress = Gtk::ProgressBar.new
		@killcpuburn = Gtk::Button.new(@tl.get_translation("killsystest"))
		# @killcpuburn.sensitive = false
		# This flag indicates cooling problems
		@cooling = false
		# Array containing messages to display
		@messages = Array.new 
		# errorlevel, can only be raised
		@errorlevel = 0 
		@trafficlight = nil
		@testcancelled = false
		@infotext = nil
		
		# Table for SSD info
		@ssdtable = nil
		@ssdbars = Array.new 
		
		# Test USB thumb drives for wear
		@usbtestcombo = nil
		@usbtestdrivelist = Array.new 
		@usbtestpgbar = nil
		@usbtestresult = Gtk::Label.new 
		# 
		@usbrescbutton = usbrescbutton
		@usbtestforfake = false 
		
		# TV optimize stuff
		@tvtargetcombo = Gtk::ComboBox.new
		@tvtargetparts = Array.new
		@tvtargetprogress = Gtk::ProgressBar.new
		@tvdlkilled = false
		
		# WTF?
		@cpuburn_next = "winfixsmart"
		
		button1 = Gtk::EventBox.new.add Gtk::Image.new("systest2.png")
		button2 = Gtk::EventBox.new.add Gtk::Image.new("systest2.png")
		button3 = Gtk::EventBox.new.add Gtk::Image.new("systest1.png")
		button5 = Gtk::EventBox.new.add Gtk::Image.new("systest1.png")
		button6 = Gtk::EventBox.new.add Gtk::Image.new("systest3.png")
		button7 = Gtk::EventBox.new.add Gtk::Image.new("systest3.png")
		button8 = Gtk::EventBox.new.add Gtk::Image.new("systest2.png")
		button9 = Gtk::EventBox.new.add Gtk::Image.new("systest3.png")
		button10 = Gtk::EventBox.new.add Gtk::Image.new("systest1.png")
		button11 = Gtk::EventBox.new.add Gtk::Image.new("qralle.png")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		
		text1 = Gtk::Label.new
		text1.width_request = 250
		text1.wrap = true
		text1.set_markup("<span foreground='white'>" + @tl.get_translation("inspect") + "</span>")
		
		text2 = Gtk::Label.new
		text2.width_request = 250
		text2.wrap = true
		text2.set_markup("<span foreground='white'>" + @tl.get_translation("sysprofile") + "</span>")
		
		text3 = Gtk::Label.new
		text3.width_request = 250
		text3.wrap = true
		text3.set_markup("<span foreground='white'>" + @tl.get_translation("monitortest") + "</span>")
		
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span foreground='white'>" + @tl.get_translation("ssdquickcheck") + "</span>")
		
		text6 = Gtk::Label.new
		text6.width_request = 250
		text6.wrap = true
		text6.set_markup("<span foreground='white'>" + @tl.get_translation("stickcheck") + "</span>")
		
		text7 = Gtk::Label.new
		text7.width_request = 250
		text7.wrap = true
		text7.set_markup("<span foreground='white'>" + @tl.get_translation("stickrepair") + "</span>")
		
		hwbutton = Gtk::EventBox.new.add Gtk::Image.new("systest1.png")
		hwtext = Gtk::Label.new
		hwtext.width_request = 250
		hwtext.wrap = true
		hwtext.set_markup("<span foreground='white'>" + @tl.get_translation("submenuhw") + "</span>")
		
		docbutton = Gtk::EventBox.new.add Gtk::Image.new("systest1.png")
		doctext = Gtk::Label.new
		doctext.width_request = 250
		doctext.wrap = true
		doctext.set_markup("<span foreground='white'>" + @tl.get_translation("submenudoc") + "</span>")
		
		text8 = Gtk::Label.new
		text8.width_request = 250
		text8.wrap = true
		text8.set_markup("<span foreground='white'>" + @tl.get_translation("docbioscomp") + "</span>")
		
		text9 = Gtk::Label.new
		text9.width_request = 250
		text9.wrap = true
		text9.set_markup("<span foreground='white'>" + @tl.get_translation("docfritzwiki") + "</span>")
		
		text10 = Gtk::Label.new
		text10.width_request = 250
		text10.wrap = true
		text10.set_markup("<span foreground='white'>" + @tl.get_translation("docwinwiki") + "</span>")
		
		text11 = Gtk::Label.new
		text11.width_request = 250
		text11.wrap = true
		text11.set_markup("<span foreground='white'>" + @tl.get_translation("docpdffolder") + "</span>")
		
		netrepbutton = Gtk::EventBox.new.add Gtk::Image.new("systest1.png")
		text12 = Gtk::Label.new
		text12.width_request = 250
		text12.wrap = true
		text12.set_markup("<span foreground='white'>" + @tl.get_translation("repairnetsettings") + "</span>")
		
		ramtestbutton = Gtk::EventBox.new.add Gtk::Image.new("systest2.png")
		ramtesttxt = Gtk::Label.new
		ramtesttxt.width_request = 250
		ramtesttxt.wrap = true
		ramtesttxt.set_markup("<span foreground='white'>" + @tl.get_translation("ramtestdesc") + "</span>")
		
		# One fixed for most upper level
		fixed = Gtk::Fixed.new
		
		# Sublevel check hardware
		chhwfixed = Gtk::Fixed.new
		TileHelpers.place_back(chhwfixed, extlayers)
		
		# Sublevel documentation
		docfixed = Gtk::Fixed.new 
		TileHelpers.place_back(docfixed, extlayers)
		
		# Move button loadtest to separate layer
		
		#if @lang == "pl" || File.new("/etc/lesslinux/updater/version.txt").read.strip =~ /tunguska-box/ 
		#	chhwfixed.put(button1, 0, 0)
		#	# fixed.put(button2, 0, 130)
		#	chhwfixed.put(button3, 0, 130)
		#	fixed.put(back, 852, 332)
		#	chhwfixed.put(text1, 130, 0)
		#	# fixed.put(text2, 130, 150)
		#	## fixed.put(text3, 130, 130)
		#	fixed.put(text4, 605, 338)
		#else
			chhwfixed.put(button1, 0, 0)
			
			chhwfixed.put(button3, 0, 130)
			fixed.put(back, 852, 332)
			chhwfixed.put(text1, 130, 0)
		
		unless @lang == "pl"
			fixed.put(text2, 130, 130)
			fixed.put(button2, 0, 130)
		end
			
		chhwfixed.put(text3, 130, 130)
		
		
		fixed.put(text4, 605, 338)
		fixed.put(text7, 590, 0)
		fixed.put(@usbrescbutton, 460, 0)
		if @lang == "pl"
			# Move netrepairbutton to first columns second position
			fixed.put(text12, 130, 130)
			fixed.put(netrepbutton, 0, 130)
		else
			fixed.put(text12, 590, 130)
			fixed.put(netrepbutton, 460, 130)
		end
		
		# Buttons for TV check repair
		tvrepbutton = Gtk::EventBox.new.add Gtk::Image.new("systest1.png")
		texttv = Gtk::Label.new
		texttv.width_request = 250
		texttv.wrap = true
		texttv.set_markup("<span foreground='white'>" + @tl.get_translation("repairtvsettings") + "</span>")
		
		if @lang == "pl"
			# Completely omit TV rep button
			#fixed.put(tvrepbutton, 0, 130)
			#fixed.put(texttv, 130, 130)
		else
			fixed.put(tvrepbutton, 0, 260)
			fixed.put(texttv, 130, 260)
		end
		
		chhwfixed.put(text5, 590, 0)
		chhwfixed.put(text6, 590, 130)
		chhwfixed.put(button5, 460, 0)
		chhwfixed.put(button6, 460, 130)
		chhwfixed.put(ramtestbutton, 0, 260)
		chhwfixed.put(ramtesttxt, 130, 260)
		
		docfixed.put(text8, 130, 0)
		docfixed.put(text9, 130, 130)
		docfixed.put(text10, 590, 0)
		docfixed.put(text11, 590, 130)
		docfixed.put(button8, 0, 0)
		docfixed.put(button9, 0, 130)
		docfixed.put(button10, 460, 0)
		docfixed.put(button11, 460, 130)
		
		fixed.put(hwbutton, 0, 0)
		fixed.put(hwtext, 130, 0)
		begin
			if @lang == "pl" || File.new("/etc/lesslinux/updater/version.txt").read.strip =~ /tunguska-box/ 
				$stderr.puts "Do not link documentation"
			else
				#fixed.put(docbutton, 460, 130)
				#fixed.put(doctext, 590, 130)
			end
		rescue
		end
		
		@layers[0] = fixed
		extlayers["DEAD_pcinspector"] = fixed 
		
		hwbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["DEAD_pcinsphw"].show_all
			end
		}
		docbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["DEAD_pcinspdoc"].show_all
			end
		}
		button.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["DEAD_pcinspector"].show_all
			end
		}
		button1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["pcloadtest"].show_all
				run_long_test
			end
		}
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				#if File.exists?("/var/run/lesslinux/sysprofile.url")
				#	url = File.new("/var/run/lesslinux/sysprofile.url").read.strip
				#	@urllabel.set_markup("<span color='white'>" + @tl.get_translation("sysprofiledonebody").gsub("SYSPROFILEURL", url.strip) + "</span>")
				#	system("nohup su surfer -c \"firefox '#{url}'\" &")
				#	extlayers["pcsysprofiledone"].show_all
				#els
				if nwscreen.test_connection == false
					nwscreen.nextscreen = "pcsysprofile"
					nwscreen.fill_wlan_combo 
					# Check for networks first...
					extlayers["networks"].show_all
				else
					extlayers["pcsysprofile"].show_all
				end
			end
		}
		button3.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("ruby -I /usr/share/lesslinux/notfallcd4 /usr/share/lesslinux/notfallcd4/monitortest.rb &") 
			end
		}
		button5.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				fill_ssd_health
				extlayers["ssdhealthinfo"].show_all
			end
		}
		button6.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				#fill_usb_combo
				#extlayers["usbteststart"].show_all
				extlayers["DEAD_usbcheckchoice"].show_all
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		button10.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if nwscreen.test_connection == false
					nwscreen.nextscreen = "DEAD_pcinspdoc"
					nwscreen.fill_wlan_combo 
					# Check for networks first...
					extlayers.each { |k,v|v.hide_all }
					extlayers["networks"].show_all
					0.upto(50) { |n|
						while (Gtk.events_pending?)
							Gtk.main_iteration
						end
						sleep 0.2
					}
				end
				system("su surfer -c 'firefox file:///usr/share/doc/notfall-dvd/WinFAQ/winfaq/Content/winfaq.htm' &")
			end
		}
		button11.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system('su surfer -c "Thunar /home/surfer/Desktop/Anleitungen" &') 
			end
		}
		button9.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if nwscreen.test_connection == false
					nwscreen.nextscreen = "DEAD_pcinspdoc"
					nwscreen.fill_wlan_combo 
					# Check for networks first...
					TileHelpers.success_dialog(@tl.get_translation("fritzwikinet"), @tl.get_translation("fritzwikinetheader"))
					extlayers.each { |k,v|v.hide_all }
					extlayers["networks"].show_all
					0.upto(50) { |n|
						while (Gtk.events_pending?)
							Gtk.main_iteration
						end
						sleep 0.2
					}
				else
					system("/etc/lesslinux/updater/update_wrapper.sh &")
				end
				system("su surfer -c 'firefox file:///usr/share/doc/notfall-dvd/FRITZWIKI/FRITZWIKI.html' &")
			end
		}
		button8.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if nwscreen.test_connection == false
					nwscreen.nextscreen = "DEAD_pcinspdoc"
					nwscreen.fill_wlan_combo 
					# Check for networks first...
					extlayers.each { |k,v|v.hide_all }
					extlayers["networks"].show_all
					0.upto(50) { |n|
						while (Gtk.events_pending?)
							Gtk.main_iteration
						end
						sleep 0.2
					}
				end
				system("su surfer -c 'firefox file:///usr/share/doc/notfall-dvd/BIOS-Kompendium/index.htm' &")
			end
		}
		netrepbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				extlayers["networkrepair"].show_all
			end
		}
		tvrepbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				extlayers.each { |k,v|v.hide_all }
				@tvtargetparts = reread_tvtargetlist(@tvtargetcombo)
				@tvdlkilled = false 
				if nwscreen.test_connection == false
					nwscreen.nextscreen = "tvtargetselect"
					nwscreen.fill_wlan_combo 
					# Check for networks first...
					extlayers["networks"].show_all
				else
					extlayers["tvtargetselect"].show_all
				end
			end
		}
		ramtestbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				#TileHelpers.error_dialog("Verdrahte mich!")
				badmem = false
				IO.popen("dmesg") { |l|
					while l.gets
						badmem = true if $_ =~ / bad mem addr /
					end
				}
				badmem = true if @simulate.include?("badmem")
				extlayers.each { |k,v|v.hide_all }
				if badmem == true
					extlayers["hardwarebadmem"].show_all
				else
					extlayers["hardwaregoodmem"].show_all
				end
			end
		}
		
		create_sysprofile_layer
		create_sysprofile_done
		create_test_layer
		create_result_layer
		create_ssd_smart_layer
		create_sticktest_layer
		create_testrunning_layer
		create_testresult_layer
		create_memory_layers
		create_usbchoice_layer
		
		@layers.push chhwfixed
		extlayers["DEAD_pcinsphw"] = chhwfixed 
		@layers.push docfixed
		extlayers["DEAD_pcinspdoc"] = docfixed 
		
		create_netrepair_layer 
		create_tvtargetlayer
		create_tvtestlayer
		
		return fixed
	end
	attr_reader :layers
	
	def prepare_pcloadtest
		run_long_test
	end
	
	def prepare_pcsysprofile(nwscreen)
		#if nwscreen.test_connection == false
		#	nwscreen.nextscreen = "pcsysprofile"
		#	nwscreen.fill_wlan_combo 
		#	return "networks"
		#end
		return "pcsysprofile"
	end
	
	def prepare_tvtest(nwscreen)
		if nwscreen.test_connection == false
			nwscreen.nextscreen = "tvtargetselect"
			nwscreen.fill_wlan_combo 
			return "networks"
		end
		return "tvtargetselect"
	end
	
	def prepare_hardwarememtest
		badmem = false
		IO.popen("dmesg") { |l|
			while l.gets
				badmem = true if $_ =~ / bad mem addr /
			end
		}
		badmem = true if @simulate.include?("badmem")
		return "hardwarebadmem" if badmem == true
		return "hardwaregoodmem"
	end
	
	def prepare_ssdhealthinfo
		fill_ssd_health
	end
	
	def prepare_usbteststart(forfakes)
		@usbtestforfake = forfakes 
		fill_usb_combo
	end
	
	def create_netrepair_layer
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("systestgreen.png")
		reptext = TileHelpers.create_label("<b>" + @tl.get_translation("netrepairhead") + "</b>\n\n" + @tl.get_translation("netrepairbody"), 510)
		# fixed.put(tile, 0, 0)
		fixed.put(reptext, 0, 0)
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		fixed.put(forw, 650, 352)
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		fixed.put(back, 650, 402)
		fixed.put(text4, 402, 408)
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("gotonetrepair") + "</span>")
		fixed.put(text5, 402, 358)
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				@extlayers["pleasewait"].show_all
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				run_netrepair
				@extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		@layers.push fixed
		@extlayers["networkrepair"] = fixed
	end
	
	def create_usbchoice_layer
		fixed = Gtk::Fixed.new
		button1 = Gtk::EventBox.new.add Gtk::Image.new("systest1.png")
		button2 = Gtk::EventBox.new.add Gtk::Image.new("systest2.png")
		text1 = TileHelpers.create_label(@tl.get_translation("usbcheckonlytext"), 450)
		text2 = TileHelpers.create_label(@tl.get_translation("usbcheckfaketext"), 450)
		TileHelpers.place_back(fixed, @extlayers)
		fixed.put(button1, 0, 0)
		fixed.put(button2, 0, 130)
		fixed.put(text1, 130, 0)
		fixed.put(text2, 130, 130)
		button1.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				@usbtestforfake = false 
				fill_usb_combo
				@extlayers["usbteststart"].show_all
			end
		}
		button2.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				@usbtestforfake = true 
				fill_usb_combo
				@extlayers["usbteststart"].show_all
			end
		}
		@layers.push fixed
		@extlayers["DEAD_usbcheckchoice"] = fixed
	end
	
	def create_sysprofile_layer
		fixed = Gtk::Fixed.new
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("systestneutral.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("sysprofilehead") + "</b>\n\n" + @tl.get_translation("sysprofilebody"), 700)
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		showprivacy = Gtk::Button.new @tl.get_translation("showprivacy")
		showprivacy.width_request = 510
		showprivacy.height_request = 32
		mailentry = Gtk::Entry.new
		mailentry.width_request= 430
		maillabel = TileHelpers.create_label(@tl.get_translation("email"), 80)
		newslabel = TileHelpers.create_label(@tl.get_translation("newsletter"), 240)
		shoplabel = TileHelpers.create_label(@tl.get_translation("shopping"), 240)
		tgtlabel = TileHelpers.create_label(@tl.get_translation("sysproftargetlabel"), 240)
		shopcheck = Gtk::CheckButton.new("")
		newscheck = Gtk::CheckButton.new("")
		targetcombo = Gtk::ComboBox.new
		targetcombo.width_request = 510
		targetcombo.append_text(@tl.get_translation("sysprofstorelocal"))
		targetcombo.append_text(@tl.get_translation("sysprofstoreremote"))
		remotelabel = TileHelpers.create_label(@tl.get_translation("sysprofremoteextra"), 760)
		targetcombo.active = 0
		suitableparts = Array.new 
		drivecombo = Gtk::ComboBox.new
		drivecombo.width_request = 510
		drivecombo.append_text(@tl.get_translation("sysprofreread"))
		drivecombo.active = 0
		drivecombo.sensitive = false
		rereadbutton = Gtk::Button.new(@tl.get_translation("reread"))
		fixed.put(back, 650, 402)
		fixed.put(text4, 402, 408)
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(mailentry, 80, 190)
		fixed.put(maillabel, 0, 190)
		begin
			# if @lang == "pl" || File.new("/etc/lesslinux/updater/version.txt").read.strip =~ /tunguska-box/ 
				fixed.put(drivecombo, 0, 90)
				fixed.put(rereadbutton, 520, 90)
			#else
			#	fixed.put(targetcombo, 0, 80)
			#	fixed.put(tgtlabel, 0, 120)
			#	fixed.put(drivecombo, 0, 150)
			#	fixed.put(rereadbutton, 520, 150)
			#end
		rescue
		end
		fixed.put(remotelabel, 0, 120)
		# fixed.put(newslabel, 150, 100)
		# fixed.put(newscheck, 130, 100)
		# fixed.put(shoplabel, 150, 140)
		# fixed.put(shopcheck, 130, 140)
		fixed.put(showprivacy, 0, 130)
		@layers[1] = fixed
		@extlayers["pcsysprofile"] = fixed
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		showprivacy.signal_connect('button-release-event') { |x, y|
			@extlayers.each { |k,v|v.hide_all }
			@extlayers["legal3"].show_all
		}
		text5 = Gtk::Label.new
		text5.width_request = 230
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("createsysprofile") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		#targetcombo.signal_connect("changed") { 
		#	if targetcombo.active == 0
		#		remotelabel.hide_all
		#		maillabel.hide_all
		#		mailentry.hide_all
		#		showprivacy.hide_all
		#		tgtlabel.show_all
		#		drivecombo.show_all
		#		rereadbutton.show_all
		#	else
		#		remotelabel.show_all
		#		maillabel.show_all
		#		mailentry.show_all
		#		showprivacy.show_all
		#		tgtlabel.hide_all
		#		drivecombo.hide_all
		#		rereadbutton.hide_all
		#	end
		#}
		showprivacy.show_all
		rereadbutton.signal_connect("clicked") {
			suitableparts = fill_profiletarget_combo(drivecombo)
		}
		fixed.signal_connect("show") {
			remotelabel.hide_all
			maillabel.hide_all
			mailentry.hide_all
			# showprivacy.hide_all
			tgtlabel.show_all
			drivecombo.show_all
			rereadbutton.show_all
			targetcombo.active = 0
		}
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				prof = MfsSysProfile.new
				if suitableparts[drivecombo.active].nil? && targetcombo.active == 0
					TileHelpers.error_dialog(@tl.get_translation("selecttarget"))
				elsif targetcombo.active == 0
					@extlayers.each { |k,v|v.hide_all }
					x = prof.get_xml(4)
					# FIXME: check whether suitableparts > 0
					# FIXME: also write HTML
					suitableparts[drivecombo.active].mount("rw")
					mnt = suitableparts[drivecombo.active].mount_point
					pref = "PC-Profil"
					realtgt = pref
					ct = 0
					begin
						FileUtils.mkdir_p("#{mnt[0]}/#{realtgt}") unless File.directory?("#{mnt[0]}/#{realtgt}")
					rescue
					end
					while File.exists?( mnt[0] + "/" + realtgt + "/PC-Profil.html")
						realtgt = pref + "." + ct.to_s
						FileUtils.mkdir_p(mnt[0] + "/" + realtgt)
						ct += 1
					end
					# retrieve all PCI devices 
					pcidevs = Array.new
					xdisks = Array.new
					xcorenum = x.root.elements["general"].attribute("cores").to_s
					xprocessor = x.root.elements["general"].attribute("processor").to_s 
					xmemory = x.root.elements["general"].attribute("memory").to_s
					x.root.elements["pci"].elements.each("dev") { |d|
						pcidevs.push [ d.attribute("id"), d.attribute("nicename"), d.attribute("niceclass") ]
					}
					x.root.elements["disks"].elements.each("disk") { |d|
						xdisks.push [ d.attribute("vendor"), d.attribute("model"), d.attribute("size"), 
							d.attribute("trim"), d.attribute("errors") ] 
					}
					
					# raw lspici short
					# raw lspci long
					# raw USB short 
					# raw usblong
					# raw dmidecode
					template = File.read("PC-Profil.html") 
					template.gsub!("PROCESSOR", xprocessor)
					template.gsub!("CORENUM", (xcorenum.to_i + 1).to_s )
					template.gsub!("MEMORY", xmemory)
					pcistr = ""
					pcidevs.each { |d|
						pcistr += "<li>#{d[0]} <b>#{d[1]}</b> (#{d[2]})</li>\n"
					}
					diskstr = ""
					xdisks.each { |d|
						diskstr += "<li>#{d[0]} <b>#{d[1]}</b> #{d[3]} Bytes Gesamtgröße, "
						diskstr += " unterstützt TRIM, " if d[3].to_s == true
						diskstr += " keine Fehler" if d[4].to_s.to_i < 1 
						diskstr += " <b>#{d[4]} Fehler!</b>" if d[4].to_s.to_i > 0
						diskstr += "</li>\n"
					}
					template.gsub!("PCIDEVICES", pcistr)
					template.gsub!("DRIVES", diskstr)
					dmidec = ` dmidecode ` 
					template.gsub!("DMIDECODE", dmidec.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;") )    
					pcilong = `lspci -vv `
					template.gsub!("PCILONG", pcilong.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;") ) 
					usblong = `lsusb -vv `
					template.gsub!("USBLONG", usblong.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;") ) 
					
					outfile = File.new("#{mnt[0]}/#{realtgt}/PC-Profil.html", "w")
					outfile.write template
					outfile.close
					#system("lspci > #{mnt[0]}/#{realtgt}/PCI-devices.txt")
					#system("lspci -vv > #{mnt[0]}/#{realtgt}/PCI-devices-full.txt")
					#system("lsusb > #{mnt[0]}/#{realtgt}/USB-devices.txt")
					#system("lsusb -vv > #{mnt[0]}/#{realtgt}/USB-devices-full.txt")
					#system("dmidecode > #{mnt[0]}/#{realtgt}/DMI-info-full.txt")
					suitableparts[drivecombo.active].umount
					@urllabel.set_markup("<span color='white'>" + @tl.get_translation("sysprofilelocaldone") + "</span>")
					@extlayers["pcsysprofiledone"].show_all
				else
					if TileHelpers.yes_no_dialog(@tl.get_translation("confirmdsgvo"))
						@extlayers.each { |k,v|v.hide_all }
						n = 0
						n = 1 if newscheck.active? == true
						h = 0
						h = 1 if shopcheck.active? == true
						begin
							url = ""
							if File.exists?("/var/run/lesslinux/sysprofile.url")
								url = File.read("/var/run/lesslinux/sysprofile.url").strip
							else
								url = prof.send('http://sysprofile.lesslinux.com/submit.php', mailentry.text.strip, n, h) 
								u = File.new("/var/run/lesslinux/sysprofile.url", "w")
								u.write url
								u.close 
							end
							$stderr.puts url
							system("nohup su surfer -c \"firefox '#{url}'\" &")
							@urllabel.set_markup("<span color='white'>" + @tl.get_translation("sysprofiledonebody").gsub("SYSPROFILEURL", url.strip) + "</span>")
						rescue
							system("rm /var/run/lesslinux/sysprofile.url")
							@urllabel.set_markup("<span color='white'>" + @tl.get_translation("sysprofilefailedbody") + "</span>")
						end
						@extlayers["pcsysprofiledone"].show_all
					else 
						# Do nothing!
					end
				end
			end
		}
	end
	
	def create_sysprofile_done
		fixed = Gtk::Fixed.new
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("systestneutral.png")
		# deltext = TileHelpers.create_label("<b>" + @tl.get_translation("sysprofiledonehead") + "</b>\n\n" + @tl.get_translation("sysprofiledonebody"), 510)
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		fixed.put(back, 650, 402)
		fixed.put(text4, 402, 408)
		@urllabel.width_request = 510
		@urllabel.wrap = true
		fixed.put(@urllabel, 0, 0)
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		@layers[4] = fixed
		@extlayers["pcsysprofiledone"] = fixed
	end
	
	def create_test_layer
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("systestgreen.png")
		deltext = TileHelpers.create_label("<b>" + @tl.get_translation("systesthead") + "</b>\n\n" + @tl.get_translation("systestbody"), 510)
		@cpuburnprogress.width_request = 380
		@cpuburnprogress.height_request = 32
		@killcpuburn.width_request = 120
		@killcpuburn.height_request = 32
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(@cpuburnprogress, 0, 108)
		fixed.put(@killcpuburn, 385, 108)
		@killcpuburn.signal_connect("clicked") {
			system("killall -9 cpuburn") 
			@testcancelled = true 
			@killcpuburn.sensitive = false
			# @extlayers.each { |k,v|v.hide_all }
			# @extlayers["pcsystestres"].show_all
		}
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("cancel") + "</span>")
		fixed.put(back, 650, 402)
		fixed.put(text4, 402, 408)
		@layers[2] = fixed
		@extlayers["pcloadtest"] = fixed
		# FIXME: 
		@cpuburnprogress.text = @tl.get_translation("systesthead")
		@cpuburnprogress.pulse
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
	end
	
	def create_result_layer
		fixed = Gtk::Fixed.new
		# @trafficlight = Gtk::Image.new("systestneutral.png")
		@trafficlights = [  
			Gtk::Image.new("ampel1gruen.png"),
			Gtk::Image.new("ampel2gelb.png"),
			Gtk::Image.new("ampel3rot.png")
		]
		# tile = Gtk::EventBox.new.add @trafficlight
		@infotext = TileHelpers.create_label("<b>" + @tl.get_translation("sysreshead") + "</b>\n\n" + @tl.get_translation("sysresbody"), 510)
		@detailtext = TileHelpers.create_label("", 450) 
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("normalback") + "</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		fixed.put(back, 650, 402)
		fixed.put(text4, 402, 408)
		@trafficlights.each { |t|  fixed.put(t, 0, 0) }
		# fixed.put(tile, 0, 0)
		fixed.put(@infotext, 130, 0)
		fixed.put(@detailtext, 160, 75)
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				@extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		@layers[3] = fixed
		@extlayers["pcsystestres"] = fixed
		fixed.signal_connect('show') {
			@trafficlights.each { |t| t.hide_all }
			# Now properly format the next screen
			if @messages.size < 1
				@trafficlights[0].show_all
				@infotext.set_markup("<span color='white'>" + @tl.get_translation("result1") + "</span>")
				@detailtext.set_markup("<span color='white'></span>")
			elsif @errorlevel > 0
				@trafficlights[2].show_all
				@infotext.set_markup("<span color='white'>" + @tl.get_translation("result1") + "</span>")
				@detailtext.set_markup("<span color='white'>" + @messages.join("\n\n") + "</span>")
			else
				@trafficlights[1].show_all
				@infotext.set_markup("<span color='white'>" + @tl.get_translation("result1") + "</span>")
				@detailtext.set_markup("<span color='white'>" + @messages.join("\n\n") + "</span>")
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		}
	end
	
	def run_long_test
		TileHelpers.set_lock 
		# Run time is set to the longest runtime found, minimum run time ist five minutes for cpuburn
		# or zero minutes if no sensors are found
		runtime = 0.0 
		cpuburntime = 300
		totaltime = 0
		sensors_found = false
		# this flag indicates cooling problems
		@cooling = false
		@messages = Array.new
		@errorlevel = 0
		@testcancelled = false
		@killcpuburn.sensitive = true
		IO.popen("sensors") { |line|
			while line.gets
				sensors_found = true if $_ =~ /cpu temperature.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 
				sensors_found = true if $_ =~ /temp\d.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 	
				sensors_found = true if $_ =~ /temp\d.*?\+(\d+)\.\d°C.*?high.*?(\d+)\.\d°C/i 
			end
		}
		if sensors_found == false
			TileHelpers.error_dialog(@tl.get_translation("nosensorbody"), @tl.get_translation("nosensorhead"))
			cpuburntime = 30
		end
		totaltime = cpuburntime 
		# Now, identify any hard disk and run a long test on it
		auxdrives = Array.new
		Dir.entries("/sys/block").each { |l|
			auxdrives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ || l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		auxdrives.each { |d|
			disktime = d.smart_long_test.to_i * 63
			totaltime = disktime if disktime > totaltime
		}
		totaltime += cpuburntime 
		totaltime = 300 if File.exists?("/tmp/debug_pcinspection") 
		# Now run with consistent updated progress bar...
		system("cpuburn &") 
		ccount = 0
		while ( runtime < totaltime.to_f && @testcancelled == false )  
			if ccount % 10 == 0
				@cpuburnprogress.fraction = runtime / totaltime.to_f 
				@cpuburnprogress.text = @tl.get_translation("minutesremaining").gsub("MINUTES", (( totaltime.to_f - runtime.to_f) / 60.0 ).to_i.to_s)
				if runtime > cpuburntime.to_f
					system("killall -9 cpuburn") 
				end
				if ccount % 50 == 0
					cputemp, critical = read_temp
					if critical - cputemp < 6
						@cooling = true
						@messages.push(@tl.get_translation("detail1"))
					end
				end
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			ccount += 1
			runtime += 0.2 
			sleep 0.2
		end
		# On cancel, just kill CPU burn and switch to the next screen
		# the running SMART test is usually aborted upon the next SMART command
		# if not, it might still provide some helpful information
		system("killall -9 cpuburn") 
		TileHelpers.remove_lock
		@cpuburnprogress.fraction = 1.0
		@cpuburnprogress.text = @tl.get_translation("testdone")
		# Read the smart values:
		auxdrives.each { |d|
			smart_support, smart_info, smart_error = d.error_log
			smart_test_types, smart_test_results, smart_bad_sectors, smart_reallocated, smart_seek_error = d.smart_details
			if smart_bad_sectors.to_i > 0 || smart_reallocated.to_i > 0 || smart_seek_error.to_i > 0
				@errorlevel = 1
				@messages.push(@tl.get_translation("detail2").gsub("VENDOR", d.vendor).gsub("MODEL", d.model).gsub("SIZE", d.human_size))
			elsif smart_error.size > 0 
				@messages.push(@tl.get_translation("detail3").gsub("VENDOR", d.vendor).gsub("MODEL", d.model).gsub("SIZE", d.human_size))
			end
		}
		@extlayers.each { |k,v|v.hide_all }
		@extlayers["pcsystestres"].show_all
	end
	
	def read_temp(kill=true)
		cputemp = 0
		critical = 80
		lcount = 0
		cpuline = -1
		IO.popen("sensors") { |line|
			while line.gets 
				# CPU Temperature:    +49.0°C  (high = +60.0°C, crit = +95.0°C)
				# temp1: +70.0°C (crit = +92.0°C)
				# 
				# temp1: +44.8°C (high = +70.0°C)
				#                (crit = +100.0°C, hyst = +97.0°C) 
				if $_ =~ /cpu temperature.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 
					puts "Core: " + $1
					puts "Crit: " + $2
					cputemp = $1.to_i 
					critical = $2.to_i 
				elsif $_ =~ /^temp\d.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 	
					puts "Core: " + $1
					puts "Crit: " + $2
					cputemp = $1.to_i 
					critical = $2.to_i
				elsif $_ =~ /^temp\d.*?\+(\d+)\.\d°C.*?high.*?(\d+)\.\d°C/i 
					puts "Core: " + $1
					puts "High: " + $2
					cpuline = lcount
					cputemp = $1.to_i
				elsif $_ =~ /^core.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 
					puts "Core: " + $1
					puts "Crit: " + $2
					cputemp = $1.to_i 
					critical = $2.to_i
				elsif $_ =~ /^core.*?\+(\d+)\.\d°C.*?high.*?(\d+)\.\d°C/i 
					puts "Core: " + $1
					puts "High: " + $2
					cpuline = lcount
					cputemp = $1.to_i
				elsif  lcount - cpuline == 1 
					puts $_
					if $_ =~ /^\s*\(.*?crit.*?(\d+)\.\d°C/i 
						puts "Crit: " + $1
						critical = $1.to_i
					end
				end
				lcount += 1
			end
			if critical - cputemp < 6 && kill == true
				system("killall -9 cpuburn")
				TileHelpers.error_dialog(@tl.get_translation("toohotbody"), @tl.get_translation("toohothead"))
			end
		}
		return cputemp, critical
	end
	
	def create_ssd_smart_layer
		#### Panel for selection of partitions
		
		fixed = Gtk::Fixed.new
		#text5 = Gtk::Label.new
		#text5.width_request = 230
		#text5.wrap = true
		#text5.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		#forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		logotile = Gtk::Image.new("systestneutral.png")
		bodytext = TileHelpers.create_label("<b>" + @tl.get_translation("ssdhead") + "</b>\n\n" + @tl.get_translation("ssdbody") , 700)
		
		delscroll = Gtk::ScrolledWindow.new
		delscroll.height_request = 205
		delscroll.width_request = 700
		delscroll.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC ) 
		@ssdtable = Gtk::Table.new(1, 11, false)
		align = Gtk::Alignment.new(0, 0, 0.1, 0.1)
		align.add @ssdtable
		delscroll.add_with_viewport align
		anc = @ssdtable.get_ancestor(Gtk::Viewport)
		# anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#007dd2') )
		anc.modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse('#052f4c') )
		
		# fixed.put(forw, 853, 282)
		# fixed.put(text5, 605, 288)
		# fixed.put(logotile, 0, 0)
		fixed.put(bodytext, 0, 0)
		fixed.put(delscroll, 0, 155)
		TileHelpers.place_back(fixed, @extlayers)
		
		@extlayers["ssdhealthinfo"] = fixed
		@layers.push fixed
	end
	
	def create_memory_layers
		goodfixed = Gtk::Fixed.new
		badfixed = Gtk::Fixed.new
		goodlogotile = Gtk::Image.new("systestneutral.png")
		badlogotile = Gtk::Image.new("systestneutral.png")
		
		badbodytext = TileHelpers.create_label(@tl.get_translation("badmemlongbody") , 700)
		goodbodytext = TileHelpers.create_label(@tl.get_translation("goodmemlongbody") , 700)
		
		# goodfixed.put(goodlogotile, 0, 0)
		goodfixed.put(goodbodytext, 0, 0)
		
		# badfixed.put(badlogotile, 0, 0)
		badfixed.put(badbodytext, 0, 0)
		
		qrbutton = Gtk::EventBox.new.add Gtk::Image.new("qrram.png")
		qrbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				TileHelpers.open_pdf(qtl.get_translation("mempdfpath"))
			end
		}
		
		badfixed.put(qrbutton, 0, 160)
		
		TileHelpers.place_back(goodfixed, @extlayers)
		TileHelpers.place_back(badfixed, @extlayers)
		@extlayers["hardwaregoodmem"] = goodfixed
		@layers.push goodfixed
		@extlayers["hardwarebadmem"] = badfixed
		@layers.push badfixed
	end
	
	def create_sticktest_layer 
		selfixed = Gtk::Fixed.new
		selnext = Gtk::Label.new
		selnext.width_request = 230
		selnext.wrap = true
		selnext.set_markup("<span color='white'>" + @tl.get_translation("next") + "</span>")
		selforw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		sellogotile = Gtk::Image.new("systestneutral.png")
		selbodytext = TileHelpers.create_label("<b>" + @tl.get_translation("usbselhead") + "</b>\n\n" + @tl.get_translation("usbselbody") , 510)
		
		@usbtestcombo = Gtk::ComboBox.new
		@usbtestcombo.width_request = 380
		@usbtestcombo.height_request = 32
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		
		selfixed.put(selforw, 650, 352)
		selfixed.put(selnext, 402, 358)
		# selfixed.put(sellogotile, 0, 0)
		selfixed.put(selbodytext, 0, 0)
		selfixed.put(@usbtestcombo, 0, 130)
		selfixed.put(reread, 390, 130)
		TileHelpers.place_back(selfixed, @extlayers)
		
		# Test USB thumb drives for wear
		# @usbtestcombo = nil
		# @usbtestdrivelist = Array.new 
		
		reread.signal_connect('clicked') { 
			fill_usb_combo
		}
		
		selforw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 && @usbtestdrivelist.size < 1
				TileHelpers.error_dialog(@tl.get_translation("please_attach_usb"))
			elsif y.button == 1
				@extlayers.each { |k,v|v.hide_all }
				@extlayers["usbtestrunning"].show_all
				if @usbtestforfake == false 
					testresult = run_usbtest(@usbtestdrivelist[@usbtestcombo.active], @usbtestpgbar)
				else
					testresult = run_fake_usbtest(@usbtestdrivelist[@usbtestcombo.active], @usbtestpgbar)
				end
				puts testresult.join 
				if  testresult.include?(2) 
					@usbtestresult.set_markup("<span color='white'><b>" + @tl.get_translation("drivefakehead") + "</b>\n\n" + @tl.get_translation("drivefakebody") + "</span>")
				elsif testresult.include?(0) 
					@usbtestresult.set_markup("<span color='white'><b>" + @tl.get_translation("drivefailedhead") + "</b>\n\n" + @tl.get_translation("drivefailedbody") + "</span>")
				elsif @usbtestforfake == true 
					@usbtestresult.set_markup("<span color='white'><b>" + @tl.get_translation("drivefakeokhead") + "</b>\n\n" + @tl.get_translation("drivefakeokbody") + "</span>")
				else
					@usbtestresult.set_markup("<span color='white'><b>" + @tl.get_translation("driveokhead") + "</b>\n\n" + @tl.get_translation("driveokbody") + "</span>")
				end
				unless File.file?("/var/run/kill.sticktest")
					@extlayers.each { |k,v|v.hide_all }
					@extlayers["usbtestresult"].show_all 
				end
			end
		}
		
		
		@extlayers["usbteststart"] = selfixed
		@layers.push selfixed
		
	end
	
	def create_testrunning_layer
		selfixed = Gtk::Fixed.new
		sellogotile = Gtk::Image.new("systestneutral.png")
		selbodytext = TileHelpers.create_label("<b>" + @tl.get_translation("testrunninghead") + "</b>\n\n" + @tl.get_translation("testrunningbody") , 510)
		
		@usbtestpgbar = Gtk::ProgressBar.new
		@usbtestpgbar.width_request = 600
		@usbtestpgbar.height_request = 32
	
		# selfixed.put(sellogotile, 0, 0)
		selfixed.put(selbodytext, 0, 0)
		selfixed.put(@usbtestpgbar, 0, 130)
		backbutton = TileHelpers.place_back(selfixed, @extlayers, false)
		backbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("touch /var/run/kill.sticktest") 
				@extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		@extlayers["usbtestrunning"] = selfixed
		@layers.push selfixed
		
	end
	
	def create_testresult_layer
		selfixed = Gtk::Fixed.new
		sellogotile = Gtk::Image.new("systestneutral.png")
		@usbtestresult.width_request = 510
		@usbtestresult.wrap = true
		# selfixed.put(sellogotile, 0, 0)
		selfixed.put(@usbtestresult, 0, 0)
		backbutton = TileHelpers.place_back(selfixed, @extlayers)
		
		@extlayers["usbtestresult"] = selfixed
		@layers.push selfixed
		
	end
	
	def fill_usb_combo
		TileHelpers.set_lock 
		1000.downto(0) { |n|
			begin
				@usbtestcombo.remove_text(n)
			rescue
			end
		}
		@usbtestdrivelist = Array.new
		Dir.entries("/sys/block").each { |l|
			# drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ 
			d = MfsDiskDrive.new(l, false) if l =~ /[a-z]$/ 
			if l =~ /[a-z]$/ && d.usb == true
				if d.partitions.size > 0 && ( d.partitions[0].fs =~ /ntfs/i || d.partitions[0].fs =~ /fat/i )
					label = "#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
					@usbtestcombo.append_text(label)
					@usbtestdrivelist.push d.partitions[0]
				end
			end
		}
		if @usbtestdrivelist.size < 1 
			@usbtestcombo.append_text(@tl.get_translation("no_suitable_device"))
			@usbtestcombo.sensitive = false
		else
			@usbtestcombo.sensitive = true
		end
		@usbtestcombo.active = 0
		TileHelpers.remove_lock
	end
	
	def fill_ssd_health
		# @ssdtable
		drives = Array.new
		@ssdbars.each { |b|
			@ssdtable.remove b 
		}
		rowcount = 0
		Dir.entries("/sys/block").each { |l|
			# drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/ 
			if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				d =  MfsDiskDrive.new(l, false)
				d.smart_details 
				if d.ssd? && !d.smart_total_cycles.nil?
					p = Gtk::ProgressBar.new
					p.width_request = 740
					label = "#{d.vendor} #{d.model} - #{d.human_size} - #{d.device}"
					if d.usb == true
						label = label + " (USB)"
					else
						label = label + " (SATA/eSATA/IDE/NVME)"
					end
					p.text = label 
					p.fraction = 2500.0 / d.smart_total_cycles.to_f 
					@ssdtable.attach(p, 0, 1, rowcount, rowcount+1)
					@ssdbars.push(p) 
					rowcount += 1 
					@ssdtable.resize(rowcount, 1)
				else
				#	p = Gtk::ProgressBar.new
				#	p.width_request = 740
				#	label = "#{d.vendor} #{d.model} - #{d.human_size} - #{d.device} - TEST"
				#	p.text = label 
				#	p.fraction = 0.15 + 0.12 * rowcount.to_f 
				#	@ssdtable.attach(p, 0, 1, rowcount, rowcount+1)
				#	@ssdbars.push(p) 
				#	rowcount += 1 
				#	@ssdtable.resize(rowcount, 1)
				end
			end
		}
		TileHelpers.error_dialog(@tl.get_translation("no_suitable_ssd")) if rowcount < 1
		return rowcount
		
		# return true/false
	end
	
	def run_usbtest(device, pgbar=nil)
		TileHelpers.set_lock 
		# Run a read only test on the whole device - many broken sticks will exit here already
		whole_disk = MfsDiskDrive.new(device.parent)
		expected_blocks = whole_disk.size / 8388608
		pgbar.text = @tl.get_translation("read_only_test")
		0.upto(expected_blocks - 1) { |n|
			read_success = system("dd if=/dev/#{whole_disk.device} of=/dev/null bs=8388608 count=1 skip=#{n.to_s}")
			pgbar.fraction = n.to_f / expected_blocks.to_f
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			return [ 0 ] unless read_success == true
		}
		
		# Now mount, write and read again
		device.mount("rw")
		system("rm /var/run/kill.sticktest")
		mounted = device.mount_point 
		faillist = Array.new 
		if mounted.nil?
			
		end
		expected_tokens = device.free_space / 16777216
		
		system("mkdir \"#{mounted[0]}/cobitest\"")
		write_success = true
		token = 0
		ttok = ""
		pgbar.text = @tl.get_translation("writing_testdata") 
		while write_success == true
			ttok = sprintf("%08d", token)
			write_success = system("dc3dd tpat=#{ttok} cnt=32768 of=\"#{mounted[0]}/cobitest/#{ttok}.tst\" ") unless File.file?("/var/run/kill.sticktest")
			write_success = false if File.file?("/var/run/kill.sticktest")
			system("sync") 
			token += 1
			pgbar.fraction = token.to_f / expected_tokens.to_f
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		pgbar.fraction = 1.0
		puts device.free_space.to_s
		if File.file?("#{mounted[0]}/cobitest/#{ttok}.tst") && device.retrieve_occupation < 16777216
			puts "Removing truncated"
			FileUtils.rm("#{mounted[0]}/cobitest/#{ttok}.tst", :force => true)
			token = token - 1
		end
		failures = 0
		pgbar.text = @tl.get_translation("reading_testdata") 
		txt = ""
		0.upto(token - 1) { |n|
			ttok = sprintf("%08d", n)
			f = File.new("#{mounted[0]}/cobitest/#{ttok}.tst")
			txt = f.read unless File.file?("/var/run/kill.sticktest") 
			ref = ttok * 2097152
			f.close 
			FileUtils.rm("#{mounted[0]}/cobitest/#{ttok}.tst", :force => true)
			system("sync") 
			unless txt == ref 
				failures += 1 
				faillist.push(0)
			else
				faillist.push(1) 
			end
			pgbar.fraction = n.to_f / expected_tokens.to_f
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		}
		system("sync") 
		sleep 1.0
		device.umount
		pgbar.fraction = 1.0
		puts failures.to_s 
		TileHelpers.remove_lock
		return faillist 
	end
	
	def run_fake_usbtest(device, pgbar=nil)
		TileHelpers.set_lock 
		# Run a read only test on the whole device - many broken sticks will exit here already
		whole_disk = MfsDiskDrive.new(device.parent)
		# Count 8M blocks 
		expected_blocks = whole_disk.size / 8388608
		# Checksum of block with zero bytes
		zero8md5 = "96995b58d4cbf6aaa9041b4f00c7f6ae"
		# Create a testblock
		system("dd if=/dev/urandom bs=1M count=8 of=/var/run/lesslinux/8mrand.bin")
		rand8md5 = ` md5sum /var/run/lesslinux/8mrand.bin `.strip.split[0]
		$stderr.puts("Urandom block has checksum: " + rand8md5)
		# List of blocks contained zero bytes to restore
		zeroblocks = Array.new
		# Maximum half of device to check
		checksum = ""
		(expected_blocks - 3).downto(expected_blocks / 2) { |n|
			pgbar.text = @tl.get_translation("faketestprogread").gsub("BLOCKNUM", n.to_s)
			pgbar.pulse 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			IO.popen("dd if=/dev/#{whole_disk.device} bs=8M count=1 skip=#{n} | md5sum - ") { |l|
				while l.gets
					checksum = $_.strip.split[0]
					$stderr.puts("Got checksum: " + checksum)
				end
			}
			if checksum == zero8md5
				pgbar.text = @tl.get_translation("faketestprogwrite").gsub("BLOCKNUM", n.to_s)
				pgbar.pulse
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				system("dd if=/var/run/lesslinux/8mrand.bin of=/dev/#{whole_disk.device} bs=8M count=1 seek=#{n}")
				system("sync")
				pgbar.text = @tl.get_translation("faketestprogreadback").gsub("BLOCKNUM", n.to_s)
				pgbar.pulse 
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				IO.popen("dd if=/dev/#{whole_disk.device} bs=8M count=1 skip=#{n} | md5sum - ") { |l|
					while l.gets
						checksum = $_.strip.split[0]
						$stderr.puts("Got checksum: " + checksum)
					end
				}
				if checksum == rand8md5
					# Everything fine!
					zeroblocks.push(n)
				elsif checksum == zero8md5
					return [ 2 ]
				else
					return [ 0 ]
				end
			else
				# Block seems already to be written, ignore
			end
		}
		zeroblocks.each { |n|
			pgbar.text = @tl.get_translation("faketestprog2ndread").gsub("BLOCKNUM", n.to_s) 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			IO.popen("dd if=/dev/#{whole_disk.device} bs=8M count=1 skip=#{n} | md5sum - ") { |l|
				while l.gets
					checksum = $_.strip.split[0]
					$stderr.puts("Got checksum: " + checksum)
				end
			}
			if checksum == rand8md5
				# Everything fine!
			elsif checksum == zero8md5
				return [ 2 ]
			else
				return [ 0 ]
			end
			pgbar.text = @tl.get_translation("faketestprogrestore").gsub("BLOCKNUM", n.to_s) 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			system("dd if=/dev/zero of=/dev/#{whole_disk.device} bs=8M count=1 seek=#{n}") 
			system("sync")
		}
		TileHelpers.remove_lock 
		return Array.new 
	end
	
	def fill_profiletarget_combo(combobox)
		TileHelpers.set_lock 
		drives = Array.new
		suitableparts = Array.new
		199.downto(0) { |n|
			begin
				combobox.remove_text(n)
			rescue
			end
		}
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				begin
					d =  MfsDiskDrive.new(l, true)
					drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		# Now fill each combo box with the respective 
		drives.each { |d|
			d.partitions.each { |p|
				# iswin, winvers = p.is_windows
				if p.fs =~ /FAT/i || p.fs =~ /NTFS/i
					#p.umount
					#if p.label =~ /^usbdata/i
					#	system("mkdir -p /cobi/sicherung")
					#	p.mount("rw", "/cobi/sicherung") 
					#else
					#	p.mount("ro")
					#end
					suitableparts.push(p)
					desc = "#{p.device}, #{p.human_size} - #{p.fs}"
					desc = desc + " (Backup-Medium)" if p.label =~ /^usbdata/i
					combobox.append_text(desc)
				end
			}
		}
		if suitableparts.size > 0 
			# gobutton.sensitive = true 
			combobox.sensitive = true
			# switch_shelllabel(shelllabel, 0, gobutton)
		else
			combobox.append_text(@tl.get_translation("no_suitable_partition_found"))
			combobox.sensitive = false
			#wincombo.append_text("Windows 8.1 auf sdb1 (SATA/eSATA/IDE)") 
			# wincombo.sensitive = true
		end
		combobox.active = 0
		TileHelpers.remove_lock
		return suitableparts 
	end
	
	def run_netrepair
		TileHelpers.set_lock 
		drives = Array.new
		tempparts = Array.new
		winparts = 0
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/  || l =~ /nvme[0-9]n[0-9]$/ 
				begin
					d =  MfsDiskDrive.new(l, true)
					drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		# Now fill each combo box with the respective 
		drives.each { |d|
			d.partitions.each { |p|
				# iswin, winvers = p.is_windows
				registry = p.regfile
				if !registry.nil?
					$stderr.puts "Found Registry on #{p.device}"
					tempparts.push p
					p.umount
					p.mount("rw")
					mnt = p.mount_point
					# Copy the EXE file 
					if File.exists?("/lesslinux/cdrom/lesslinux/InternetReset.exe") && !mnt.nil?
						system("cp -v /lesslinux/cdrom/lesslinux/InternetReset.exe #{mnt[0]}")
					elsif File.exists?("/lesslinux/isoloop/lesslinux/InternetReset.exe") && !mnt.nil?
						system("cp -v /lesslinux/isoloop/lesslinux/InternetReset.exe #{mnt[0]}")
					end
					unless mnt.nil? 
						h = Hivex::open(mnt[0] + "/" + registry.regfile, { :write => 1})
						root = h.root()
						node = h.node_get_child(root, "Microsoft")
						node = h.node_get_child(node, "Windows")
						node = h.node_get_child(node, "CurrentVersion")
						node = h.node_get_child(node, "RunOnce")
						newrun = { :key => "InternetReset", :type => 1, :value => "C:\\InternetReset.exe\0".unpack("c*").pack("s21") }
						h.node_set_value(node, newrun)
						begin
							h.commit(mnt[0] + "/" + registry.regfile)
						rescue
							# TileHelpers.error_dialog(@tl.get_translation("error_fs_readonly"))
							winparts -= 1
						end
						h.close
						p.umount
						winparts += 1
					end
				else 
					p.umount
				end
			}
		}
		TileHelpers.remove_lock 
		if winparts > 0			
			TileHelpers.success_dialog(@tl.get_translation("netrepair_prepared"))
		else
			TileHelpers.error_dialog(@tl.get_translation("partition_mount_failed"), "Error" )
		end
	end
	
	def create_tvtargetlayer
		fixed = Gtk::Fixed.new
		@tvdlkilled = false
		back = TileHelpers.place_back(fixed, @extlayers, false)
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("tvtargetnet") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		@tvtargetcombo.height_request = 32
		@tvtargetcombo.width_request = 380
		@tvtargetprogress.width_request = 510
		@tvtargetprogress.height_request = 32
		@tvtargetprogress.text = @tl.get_translation("tvtargetprogress")
		deltext = TileHelpers.create_label(@tl.get_translation("selecttvtarget"), 510)
		# @sourcedrives = reread_drivelist(@sourcecombo)
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.width_request = 120
		reread.height_request = 32
		tvdl_running = false
		tvdl_vte = Vte::Terminal.new
		tvdl_vte.signal_connect("child_exited") { tvdl_running = false } 
		#@overwritecheck.active = true 
		#overwrite_label = Gtk::Label.new
		#overwrite_label.set_markup("<span color='white'>" + @tl.get_translation("tvtargettext") + "</span>")
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @tvtargetparts.size < 1 
					TileHelpers.error_dialog(@tl.get_translation("notvdrivebody"), @tl.get_translation("notvdrivehead"))
				else
					@tvtargetcombo.sensitive = false
					reread.sensitive = false
					TileHelpers.set_lock
					# Mount
					system("mkdir -p /var/run/lesslinux/tvtarget")
					@tvtargetparts[@tvtargetcombo.active].mount("rw", "/var/run/lesslinux/tvtarget") 
					# Download in VT
					tvdl_running = true
					tvdl_vte.fork_command("/usr/bin/wget", [ "/usr/bin/wget", "--no-check-certificate", "-c", "-O", "/var/run/lesslinux/tvtarget/HDR-Schnelltest.mp4", "https://i.computer-bild.de/downloads/11559451/HDR-Schnelltest.mp4" ] )
					while tvdl_running == true
						@tvtargetprogress.text = @tl.get_translation("downloadingteststuff")
						@tvtargetprogress.pulse
						while (Gtk.events_pending?)
							Gtk.main_iteration
						end
						sleep 0.5
					end
					# Download done, unmount
					@tvtargetparts[@tvtargetcombo.active].umount
					@tvtargetparts[@tvtargetcombo.active].force_umount
					@tvtargetcombo.sensitive = true
					reread.sensitive = true
					# Move on
					TileHelpers.remove_lock
					@extlayers.each { |k,v|v.hide_all }
					if @tvdlkilled == true
						TileHelpers.back_to_group
					else
						@extlayers["tvtestdescription"].show_all
					end
				end
			end
		}
		reread.signal_connect('clicked') { 
			@tvtargetparts = reread_tvtargetlist(@tvtargetcombo)
		}
		back.signal_connect("button-release-event") {
			system("killall -9 wget")
			system("sync")
			sleep 0.5
			@tvdlkilled = true
		}
		# fixed.put(tile, 0, 0)
		fixed.put(@tvtargetcombo, 0, 124)
		fixed.put(@tvtargetprogress, 0, 172)
		fixed.put(deltext, 0, 0)
		fixed.put(reread, 390, 124)
		fixed.put(forw, 650, 352)
		fixed.put(text5, 402, 358)
		#fixed.put(@overwritecheck, 130, 164)
		#fixed.put(overwrite_label, 156, 168)
		@extlayers["tvtargetselect"] = fixed
		@layers.push fixed
		return fixed
	end
	
	def create_tvtestlayer
		fixed = Gtk::Fixed.new
		TileHelpers.place_back(fixed, @extlayers)
		#text5 = Gtk::Label.new
		#text5.width_request = 250
		#text5.wrap = true
		#text5.set_markup("<span color='white'>" + @tl.get_translation("tvtestdescription") + "</span>")
		deltext = TileHelpers.create_label(@tl.get_translation("tvtestdescription"), 510)
		qrbutton = Gtk::EventBox.new.add Gtk::Image.new("qrtvtest.png")
		qrbutton.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				TileHelpers.open_pdf(@tl.get_translation("filefoldername"))
			end
		}
		tile = Gtk::EventBox.new.add Gtk::Image.new("rescuegreen.png")
		# fixed.put(tile, 0, 0)
		fixed.put(deltext, 0, 0)
		fixed.put(qrbutton, 0, 130)
		#fixed.put(text5, 605, 288)
		@extlayers["tvtestdescription"] = fixed
		@layers.push fixed
		return fixed
	end
	
	def reread_tvtargetlist(combobox)
		TileHelpers.set_lock 
		TileHelpers.umount_all
		100.downto(0) { |i| 
			begin
				combobox.remove_text(i) 
			rescue
			end
		}
		drives = Array.new
		auxdrives = Array.new
		Dir.entries("/sys/block").each { |l|
			auxdrives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		auxdrives.each { |d|
			if d.usb == true
				d.partitions.each { |p|
					if p.fs =~ /fat/i && p.label != "USBDATA"
						label = "#{d.vendor} #{d.model} - #{p.human_size} - #{p.device}"
						combobox.append_text(label)
						drives.push(p)
					end	
				}
			end
		}
		if drives.size < 1 
			combobox.append_text(@tl.get_translation("nosuitabletarget"))
			combobox.active = 0
			combobox.sensitive = false
		else
			combobox.active = 0
			combobox.sensitive = true
		end
		TileHelpers.remove_lock
		return drives
	end
	
end
