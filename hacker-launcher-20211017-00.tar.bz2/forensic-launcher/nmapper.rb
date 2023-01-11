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



def dummyrun(progbar, vte, protobutton)
	addr = get_addr
	if addr.nil? 
		error_dialog("Fehler!", "Konnte keine IP-Adresse finden. Bitte Netzwerkverbindung herstellen.")
		exit 1
	end
	addtoks = addr.split(".")
	addtoks[3] = "0/24"
	progbar.text = "Untersuchung läuft..."
	vte.fork_command("nmap", [ "nmap", "-sV", "--version-intensity", "9", "-T4", "-F", addtoks.join("."), "-oX", "/tmp/nmap.xml" ])
	capturecount = 0 
	@vterunning = true
	while @vterunning == true
		sleep 0.5
		progbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end
	progbar.fraction = 1.0
	progbar.text =  "Untersuchung abgeschlossen."
	system("ruby nmap2human.rb")
	system("xsltproc /tmp/nmap.xml -o /tmp/nmap.html")
	system("firefox file:///tmp/protocol.html &")
	# sleep 5.0
	# system("firefox file:///tmp/nmap.html &") if protobutton.active?
	exit 0
end

def get_addr
	addr = nil
	IO.popen("ip addr") { |l|
		while l.gets 
			toks = $_.strip.split
			if toks[0] == "inet" 
				unless toks[1] =~ /^127/
					addr = toks[1]
				end
			end
		end
	}
	return addr 
end

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

netframe = Gtk::Frame.new("Funktionsweise")
# netcombo = Gtk::ComboBox.new
# netframe.add netcombo

netlabel = Gtk::Label.new("Diese Funktion prüft alle im lokalen Netzwerk erreichbaren Geräte auf verfügbare  Dienste und deren Sicherheit. Um die Prüfung durchzuführen, schalten Sie bitte alle zu scannenden Geräte ein. Nach Abschluss der Analyse erhalten Sie eine Geräteliste mit Handlungsempfehlungen. Aus rechtlichen Gründen darf die Anwendung dieses Werkzeuges nur in ihrem eigenen Netzwerk erfolgen.")
netlabel.wrap = true
netlabel.width_request = 480
netframe.add netlabel 

# Frame choice of passwordlist

listframe = Gtk::Frame.new("Haftung")
listbox = Gtk::VBox.new
#~ shortradio = Gtk::RadioButton.new("Deutsches Wörterbuch (2 Mio. Einträge, Dauer weniger als 30 Minuten)")
#~ longradio = Gtk::RadioButton.new(shortradio, "Passwortdatenbank und deutsches Wörterbuch (65 Mio. Einträge, Dauer mehrere Stunden)")
#~ listbox.pack_start_defaults(shortradio)
#~ listbox.pack_start_defaults(longradio)

legalcheck = Gtk::CheckButton.new("Ich bin mir bewusst, dass die Anwendung in fremden Netzwerken strafbar ist.")

listframe.add legalcheck

# Frame progress and output

progframe = Gtk::Frame.new("Fortschritt und Ausgabe")
progbox = Gtk::VBox.new
progbar = Gtk::ProgressBar.new
progbar.height_request = 32
progbar.text = "Bitte Suche starten"
vte = Vte::Terminal.new
vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
vte.height_request = 270
vte.width_request = 760
vte.signal_connect("child_exited") { @vterunning = false }
progbox.pack_start_defaults(progbar)
# progbox.pack_start_defaults(vte)
progframe.add progbox

# Button Start/Stop

gobutton = Gtk::Button.new("Jetzt verwundbare Geräte finden")
gobutton.width_request = 500
gobutton.sensitive = false 
protobutton = Gtk::CheckButton.new("Detailliertes Protokoll im Browser anzeigen")
protobutton.active = true
goframe = Gtk::Frame.new("Start")
gobox = Gtk::VBox.new
# gobox.pack_start_defaults(protobutton) 
gobox.pack_start_defaults(gobutton) 
goframe.add gobox

lvb.pack_start_defaults netframe
lvb.pack_start_defaults progframe
lvb.pack_start_defaults listframe
lvb.pack_start_defaults goframe

legalcheck.signal_connect("clicked") {
	if legalcheck.active?
		gobutton.sensitive = true
	else
		gobutton.sensitive = false
	end
}

gobutton.signal_connect('clicked') {
	#~ # iface, channel, bssid = get_net_params(@networks[netcombo.active])
	#~ if @networks[netcombo.active] =~ /managed_wep/ || @networks[netcombo.active] =~ /managed_none/
		#~ error_dialog("Keine Verschlüsselung", "Das gewählte Netzwerk ist nicht (ausreichend) verschlüsselt.")
	#~ else
		#~ gobutton.sensitive = false
		#~ netcombo.sensitive = false
		#~ netname = @networks[netcombo.active].split(/\swifi_/)[0].gsub("*AO", "").strip
		#~ # iface, channel, bssid = get_net_params(netname)
	#~ info_dialog("Bitte Verbindungsversuch starten", "Trennen Sie nach dem Klick auf \"OK\" ein anderes Gerät (Smartphone, Tablet, Notebook, Drucker) mehrfach vom ausgewählten Netzwerk und verbinden Sie erneut, damit ein Handshake zwischen Basisstation und Endgerät aufgezeichnet werden kann.")
		#~ bssid = capture_handshake(progbar, vte, netname)
		#~ [ shortradio, longradio ].each { |w| w.sensitive = false }
		#~ analyze_packets(progbar, shortradio, vte, bssid)
	#~ end
	gobutton.sensitive = false 
	dummyrun(progbar, vte, protobutton)
}

window.add(lvb) 
window.set_title("Verwundbare Geräte im lokalen Netzwerk finden")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

# fill_network_combo(netcombo)

window.show_all
Gtk.main
