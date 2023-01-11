#!/usr/bin/ruby

require 'rexml/document'
require 'glib2'
require 'gtk2'
require 'vte'
require 'MfsTranslator.rb'
require 'optparse'
require 'VirusScreen'
require 'TileHelpers'

def fill_wlan_combo(combo=nil)
	combo = @wpacombo if combo.nil?
	netcount = 0
	@wifinetworks = Array.new
	100.downto(0) { |n|
		begin
			combo.remove_text(n)
		rescue
		end
	}
	get_networks.each { |n|
		if n.strip.length > 0
			netcount += 1
			combo.append_text n
			@wifinetworks.push n
		end
	}
	# FIXME translate
	combo.append_text(@tl.get_translation("nowifinetsfound")) if netcount < 1 
	combo.active = 0 
	return netcount 
end

def get_networks 
	# First find interfaces:
	interfaces = Array.new
	networks = Array.new
	IO.popen("/usr/sbin/iwconfig 2>&1") { |l|
		while l.gets
			line = $_.strip
			if line =~ /ESSID/
				interfaces.push(line.split[0])
			end
		end
	}
	#interfaces.each { |i|
	#system("connmanctl enable wifi")
	system("connmanctl scan wifi")
	begin
		IO.popen("connmanctl services") { |l|
			while l.gets
				line = $_.strip
				netname = line
				networks.push(netname) if netname.size > 0 
			end
		}
	rescue
		$stderr.puts "Running connmanctl failed"
	end
	return networks
end

def get_net_params(netname)
	interfaces = Array.new
	networks = Array.new
	iface = nil
	bssid = nil
	channel = 0
	IO.popen("/usr/sbin/iwconfig 2>&1") { |l|
		while l.gets
			line = $_.strip
			if line =~ /ESSID/
				interfaces.push(line.split[0])
			end
		end
	}
	interfaces.each { |i|
		tmpbssid = nil
		tmpchannel = nil
		IO.popen("iwlist #{i} scan") { |l|
			while l.gets
				line = $_.strip
				if line.split[0] =~ /Cell/ 
					tmpbssid = line.split[-1]
				end
				if line.split[0] =~ /Channel/ 
					tmpchannel = line.split(":")[-1].to_i
				end
				if line.split[0] =~ /ESSID/
					if line == "ESSID:\"#{netname}\""
						iface = i
						channel = tmpchannel
						bssid = tmpbssid
					end
				end
			end
		}
	}
	$stderr.puts("Found: #{iface}, #{channel}, #{bssid}")
	return iface, channel, bssid 
end

def start_pkgcapture(netname)
		# keyfound = false
		vtetext = ""
		iface, channel, bssid = get_net_params(netname)
		# No interface, exit, move to start page
		#if iface.nil?
		#	TileHelpers.error_dialog(@tl.get_translation("error_no_iface_found"))
		#	extlayers.each { |k,v|v.hide_all }
		#	TileHelpers.back_to_group
		#	return false
		#end
		# TileHelpers.set_lock
		cmdstr = "airmon-ng start #{iface}"
		puts "Starting: " + cmdstr
		system(cmdstr)
		sleep 2 
		# First run the collection:
		cmdarr = [ "airodump-ng", "-c", channel.to_s, "--bssid", bssid, "-w", "/tmp/airodump", iface + "mon" ]
		puts "Starting: " + cmdarr.join(" ")
		@wpacollectvte.fork_command(cmdarr[0], cmdarr)
		@wpadumprunning = true
		# @wpacollectvte.fork_command("/bin/sleep", [ "sleep", "30" ] )
		capturecount = 0 
		while @wpadumprunning == true
			sleep 0.5
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			vtetext = @wpacollectvte.get_text(false) #.join("")
			if vtetext =~ /WPA handshake/ || capturecount > 600  
				system("killall -15 airodump-ng")
				@wpadumprunning = false
				# @wpacollectvte.reset(true, true)
			end
			capturecount += 1 
		end
		@wpacollectvte.reset(true, true)
		system("airmon-ng stop #{iface}mon")
		# Killed? Go back!
		if @wpacrackkilled == true
			# extlayers.each { |k,v|v.hide_all }
			# TileHelpers.back_to_group
			@wpacrackkilled = false 
			# TileHelpers.remove_lock 
			return false
		end
		return true 
		# Now switch to analyze:
end		

def analyze_capture(wpashortradio, bssid)
	# Start analyzing:
	# FIXME translate
	if File.exists? "/var/run/lesslinux/wordlist/" + @tl.get_translation("dictfile")
		$stderr.puts("Found wordlist")
	else
		system("mkdir -p /var/run/lesslinux/wordlist")
		if File.exists?("/lesslinux/blobpart/wordlist.sqs")
			system("mount -o loop /lesslinux/blobpart/wordlist.sqs /var/run/lesslinux/wordlist")
		elsif  File.exists?("/lesslinux/isoloop/lesslinux/blob/wordlist.sqs")
			system("mount -o loop /lesslinux/isoloop/lesslinux/blob/wordlist.sqs /var/run/lesslinux/wordlist")
		else
			system("mount -o loop /lesslinux/cdrom/lesslinux/blob/wordlist.sqs /var/run/lesslinux/wordlist")
		end
	end
	wordlist = "everything.txt"
	wordlist = @tl.get_translation("dictfile") if wpashortradio.active?
	caplist = Array.new
	Dir.entries("/tmp").each { |f|
		caplist.push("/tmp/" + f) if f =~ /airodump.*?\.cap/ 
	}
	@wpabruterunning = true
	@wpabrutevte.fork_command("aircrack-ng", [ "aircrack-ng",  "-w", "/var/run/lesslinux/wordlist/" + wordlist,  "-b", bssid ] + caplist )
	while @wpabruterunning == true
		sleep 0.5
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		vtetext = @wpabrutevte.get_text(false) #.join("")
		if vtetext =~ /KEY FOUND/   
			keyfound = true
		end
	end
	if @wpacrackkilled == true
		@wpacrackkilled = false 
		return false
	end
	if vtetext =~ /packets contained no eapol data/i || vtetext =~ /got no data packets from target/i
		TileHelpers.error_dialog(@tl.get_translation("result_no_handshake"), "Error")
	elsif keyfound == true
		wifipsk = ""
		$stderr.puts("key found")
		if vtetext =~ /KEY FOUND!\s\[\s(.*?)\s\]/
			wifipsk = $1
			$stderr.puts("Key is: " + wifipsk) 
		end
		# Key was found dialog
		$stderr.puts("key found")
		TileHelpers.success_dialog(@tl.get_translation("result_key_cracked").gsub("WIFIPSK", wifipsk), @tl.get_translation("result_key_cracked_head"))
	else
		# Key not found dialog
		$stderr.puts("Key not found")
		TileHelpers.success_dialog(@tl.get_translation("result_couldnt_crack"), @tl.get_translation("result_couldnt_crack_head"))
	end
	# extlayers.each { |k,v|v.hide_all }
	exit 0
end


lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "VirusScreen.xml"
tlfile = "/usr/share/lesslinux/drivetools/VirusScreen.xml" if File.exists?("/usr/share/lesslinux/drivetools/VirusScreen.xml")
@tl = MfsTranslator.new(lang, tlfile)

# @vsc = VirusScreen.new(Hash.new, Gtk::Button.new("Click Me!"), nil)
@wpacombo = Gtk::ComboBox.new
@wifinetworks = Array.new
fill_wlan_combo
@wpadumprunning = false
@wpacrackkilled = false
@wpabruterunning = false

# Create a new assistant widget with no pages. */
assistant = Gtk::Assistant.new
assistant.set_size_request(700, 450)   # 450, 300
assistant.signal_connect('destroy') { Gtk.main_quit }
assistant.set_title("WLAN Sicherheitscheck")

# Start page info etc.

startlabel = Gtk::Label.new
startlabel.wrap = true
startlabel.width_request = 660
startlabel.set_markup(@tl.get_translation("wpacrackstart"))
assistant.append_page(startlabel)
assistant.set_page_title(startlabel, "WLAN Sicherheitscheck")
assistant.set_page_complete(startlabel, true)
assistant.set_page_type(startlabel, Gtk::Assistant::PAGE_INTRO)

# Second page choose network

confbox = Gtk::VBox.new
optlabel = Gtk::Label.new
optlabel.wrap = true
optlabel.set_markup("Wählen Sie hier das zu untersuchende Netzwerk und mit welchen Wörterbuch die Sicherheit getestet werden soll:")
optlabel.width_request = 660
confbox.pack_start(optlabel, false)
confbox.pack_start(@wpacombo, false)
wbshortbutton = Gtk::CheckButton.new(@tl.get_translation("wpacrackshort"))
wblongbutton = Gtk::CheckButton.new(@tl.get_translation("wpacracklong"), wbshortbutton)
wbshortbutton.active = true
confbox.pack_start(wbshortbutton, false)
confbox.pack_start(wblongbutton, false)
assistant.append_page(confbox)
assistant.set_page_complete(confbox, true) if @wifinetworks.size > 0
assistant.set_page_title(confbox, "Einstellungen")

# Third page capture handshake

captbox = Gtk::VBox.new
captlabel = Gtk::Label.new
captlabel.wrap = true
captlabel.width_request = 660
captlabel.set_markup(@tl.get_translation("wpacrackcollect"))
@wpacollectvte = Vte::Terminal.new
captbox.pack_start(captlabel, false)
captbox.pack_start(@wpacollectvte, true)
startbutton = Gtk::Button.new("Paketmitschnitt starten")
captbox.pack_start(startbutton, false)
startbutton.signal_connect("clicked") {
	startbutton.sensitive = false 
	$stderr.puts("VTE shown, start capture")
	netname = @wifinetworks[@wpacombo.active].split(/\swifi_/)[0].gsub("*AO", "").gsub("*AR", "").strip
	iface, channel, bssid = get_net_params(netname)
	$stderr.puts("Capturing: #{netname}") 
	$stderr.puts("WB Short?" + wbshortbutton.active?.to_s)
	result = start_pkgcapture(netname) 
	if result == false
		TileHelpers.error_dialog(@tl.get_translation("no_handshake_captured"), "Error")
		exit 0
	end
	TileHelpers.success_dialog("Paketmitschnitt erfolgreich. Es wird nun die Analyse gestartet", "Success")
	assistant.set_page_complete(captbox, true)
	assistant.current_page = 3
	analyze_capture(wbshortbutton, bssid)
}
assistant.append_page(captbox)
assistant.set_page_title(captbox, "Paketmitschnitt starten")

# assistant.set_page_type(captbox, Gtk::Assistant::PAGE_PROGRESS)

#@wpacollectvte.signal_connect("child_exited") {
#	assistant.set_page_complete(captbox, true)
#	assistant.current_page = 3
#}

# Fourth page analyze the whole thing

procbox = Gtk::VBox.new
proclabel = Gtk::Label.new
proclabel.wrap = true
proclabel.width_request = 660
proclabel.set_markup("Der Paketmitschnitt wird nun ausgewertet und es wird versucht, das WPA(2)-Passwort zu ermitteln. Bitte haben Sie etwas Geduld. Das Terminalfenster zeigt den Fortschritt.")
@wpabrutevte = Vte::Terminal.new
@wpabrutevte.signal_connect("child_exited") { @wpabruterunning = false }
procbox.pack_start(proclabel, false)
procbox.pack_start(@wpabrutevte, true)
assistant.append_page(procbox)
assistant.set_page_type(procbox, Gtk::Assistant::PAGE_PROGRESS)
assistant.set_page_title(procbox, "Auswertung des Mitschnitts")

# Fifth page display results

#~ assistant.set_forward_page_func { |curr|

	#~ if (curr == 2) 
		#~ #assistant.current_page = 2
		#~ #$stderr.puts("VTE shown, start capture")
		#~ #netname = @wifinetworks[@wpacombo.active].split(/\swifi_/)[0].gsub("*AO", "").gsub("*AR", "").strip
		#~ #$stderr.puts("Capturing: #{netname}") 
		#~ #$stderr.puts("WB Short?" + wbshortbutton.active?.to_s)
		#~ #@wpadumprunning = true
		#~ #start_pkgcapture(netname) 
		#~ # captvte.fork_command("top", [ "top" ])
		#~ #assistant.current_page = 3
		#~ #$stderr.puts("VTE shown, start processing the dump")
		
		
	#~ elsif (curr == 3)
		
	#~ end
	#~ curr + 1
#~ }




#window = Gtk::Window.new
#window.signal_connect("delete_event") {
#      puts "delete event occurred"
#        false
#}
#
#window.signal_connect("destroy") {
#        puts "destroy event occurred"
#        Gtk.main_quit
#}


# lvb = Gtk::VBox.new
# lvb.pack_start_defaults(@wpacombo)
#lvb.pack_start_defaults(ifaceframe)
#lvb.pack_start_defaults(passframe)
#lvb.pack_start_defaults(go)

#window.border_width = 10
#window.width_request = 400 
#window.set_title("LessLinux WPA test")
#window.window_position = Gtk::Window::POS_CENTER_ALWAYS
#window.add lvb

#window.show_all
assistant.signal_connect(     'cancel')  { 
	assistant.destroy
}

assistant.show_all
Gtk.main