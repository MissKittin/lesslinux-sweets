#!/usr/bin/ruby
# encoding: utf-8


require 'glib2'
require 'gtk2'
require "rexml/document"
require 'fileutils'
# require 'MfsTranslator'
require 'digest/sha1'
require 'vte'

def error_dialog(title, text) 
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
end

def info_dialog(title, text) 
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
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
			$stderr.puts("Cannot run connmanctl")
		end
		@networks = networks
		@interfaces = interfaces
	end

def fill_network_combo(combo)
	get_networks
	if @networks.size < 1 || @interfaces.size < 1
		error_dialog("Keine Netze gefunden", "Es wurde kein Netzwerk zur Analyse oder keine geeignete Netzwerkschnittstelle gefunden! Abbruch.")
		exit 1
	end
	@networks.each { |n| combo.append_text n }
	combo.active = 0
end

# Get BSSID, channel and usable interface of a certain network
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

def capture_handshake(progbar, vte, netname)
	iface, channel, bssid = get_net_params(netname)
	handshakefound = false
	# No interface, exit, move to start page
	if iface.nil?
		error_dialog("Keine Netze gefunden", "Es wurde kein Netzwerk zur Analyse oder keine geeignete Netzwerkschnittstelle gefunden! Abbruch.")
		exit 1
	end
	progbar.text = "Warte auf Handshake"
	# First run the collection:
	# system("/etc/rc.d/0589-connman.sh stop")
	system("airmon-ng start #{iface}")
	@vterunning = true
	vte.fork_command("airodump-ng", [ "airodump-ng", "-c", channel.to_s, "--bssid", bssid, "-w", "/tmp/airodump", iface + "mon" ])
	capturecount = 0 
	while @vterunning == true
		sleep 0.5
		progbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		vtetext = vte.get_text(false) #.join("")
		if vtetext =~ /WPA handshake/ || capturecount > 600  
			handshakefound = true if vtetext =~ /WPA handshake/
			system("killall -15 airodump-ng")
			# @vterunning = false
		end
		capturecount += 1 
	end
	system("airmon-ng stop #{iface}mon")
	# system("/etc/rc.d/0589-connman.sh start")
	return bssid
end
	
def analyze_packets(pgbar, radiobutton, vte, bssid)
	wordlist = "everything.txt"
	wordlist = "german.txt" if radiobutton.active?
	if system("mountpoint /var/run/lesslinux/wordlist") 
		$stderr.puts "Found wordlists"
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
	caplist = Array.new
	vtetext = ""
	vte.reset(true, true)
	keyfound = false
	pgbar.text = "Analysiere verschlüsselte Handshakes"
	Dir.entries("/tmp").each { |f|
		caplist.push("/tmp/" + f) if f =~ /airodump.*?\.cap/ 
	}
	if caplist.size < 1
		error_dialog("Keine Handshakes", "Es wurden keine Paketmitschnitte mit Handshakes gefunden. Bitte starten Sie das Programm erneut.")
		exit 1
	end
	@vterunning = true
	vte.fork_command("aircrack-ng", [ "aircrack-ng",  "-w", "/var/run/lesslinux/wordlist/" + wordlist,  "-b", bssid ] + caplist )
	while @vterunning == true
		sleep 0.5
		pgbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		vtetext = vte.get_text(false) #.join("")
		if vtetext =~ /KEY FOUND/   
			keyfound = true
		end
	end
	if vtetext =~ /packets contained no eapol data/i || vtetext =~ /got no data packets from target/i
		error_dialog("Keine Handshakes", "Es wurden keine Paketmitschnitte mit Handshakes gefunden. Bitte starten Sie das Programm erneut.")
		exit 1
	elsif keyfound == true
		wifipsk = ""
		$stderr.puts("key found")
		if vtetext =~ /KEY FOUND!\s\[\s(.*?)\s\]/
			wifipsk = $1
			$stderr.puts("Key is: " + wifipsk) 
		end
		# Key was found dialog
		$stderr.puts("key found")
		boxtext = 'Ihr WLAN-Kennwort lautet „WIFIPSK“ und ist unsicher. Sie sollten es umgehend ändern. Ein sicheres Passwort enthält mindestens acht Zeichen, darunter Groß- und Kleinbuchstaben, Ziffern sowie Sonderzeichen und sollte nur einmal verwendet werden. Tipp: Bilden Sie eine Eselsbrücke wie „Jeden Morgen um 8 verlässt meine 40-jährige Frau das Haus“. Daraus entsteht das Passwort „JMu8vm40-jFdH“.'.gsub("WIFIPSK", wifipsk)
		info_dialog("WLAN-Kennwort ist unsicher", boxtext)
	else
		# Key not found dialog
		$stderr.puts("Key not found")
		info_dialog('Sicheres Kennwort', 'Gratulation! Das verwendete WLAN-Kennwort konnte nicht geknackt werden.')
	end
	exit 0
end

@networks = Array.new
@interfaces = Array.new
@vterunning = false

lvb = Gtk::VBox.new
window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

# Frame choice of network

netframe = Gtk::Frame.new("Auswahl des Netzwerkes")
netcombo = Gtk::ComboBox.new
netframe.add netcombo

# Frame choice of passwordlist

listframe = Gtk::Frame.new("Auswahl der Passwortliste")
listbox = Gtk::VBox.new
shortradio = Gtk::RadioButton.new("Deutsches Wörterbuch (2 Mio. Einträge, Dauer weniger als 30 Minuten)")
longradio = Gtk::RadioButton.new(shortradio, "Passwortdatenbank und deutsches Wörterbuch (65 Mio. Einträge, Dauer mehrere Stunden)")
listbox.pack_start_defaults(shortradio)
listbox.pack_start_defaults(longradio)
listframe.add listbox

# Frame progress and output

progframe = Gtk::Frame.new("Fortschritt und Ausgabe")
progbox = Gtk::VBox.new
progbar = Gtk::ProgressBar.new
progbar.height_request = 32
progbar.text = "Bitte Netzwerk wählen und Untersuchung starten"
vte = Vte::Terminal.new
vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
vte.height_request = 270
vte.width_request = 760
vte.signal_connect("child_exited") { @vterunning = false }
progbox.pack_start_defaults(progbar)
progbox.pack_start_defaults(vte)
progframe.add progbox

# Button Start/Stop

gobutton = Gtk::Button.new("Jetzt Verschlüsselung untersuchen")
gobutton.width_request = 500

lvb.pack_start_defaults netframe
lvb.pack_start_defaults listframe
lvb.pack_start_defaults progframe
lvb.pack_start_defaults gobutton

gobutton.signal_connect('clicked') {
	# iface, channel, bssid = get_net_params(@networks[netcombo.active])
	if @networks[netcombo.active] =~ /managed_wep/ || @networks[netcombo.active] =~ /managed_none/
		error_dialog("Keine Verschlüsselung", "Das gewählte Netzwerk ist nicht (ausreichend) verschlüsselt.")
	else
		gobutton.sensitive = false
		netcombo.sensitive = false
		netname = @networks[netcombo.active].split(/\swifi_/)[0].gsub("*AO", "").strip
		# iface, channel, bssid = get_net_params(netname)
	info_dialog("Bitte Verbindungsversuch starten", "Trennen Sie nach dem Klick auf \"OK\" ein anderes Gerät (Smartphone, Tablet, Notebook, Drucker) mehrfach vom ausgewählten Netzwerk und verbinden Sie erneut, damit ein Handshake zwischen Basisstation und Endgerät aufgezeichnet werden kann.")
		bssid = capture_handshake(progbar, vte, netname)
		[ shortradio, longradio ].each { |w| w.sensitive = false }
		analyze_packets(progbar, shortradio, vte, bssid)
	end
}

window.add(lvb) 
window.set_title("WPA-Verschlüsselung testen")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

fill_network_combo(netcombo)

window.show_all
Gtk.main
