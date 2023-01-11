#!/usr/bin/ruby 
# encoding: utf-8


require 'glib2'
require 'gtk2'
require "rexml/document"
require 'fileutils'
# require 'MfsTranslator'
require 'digest/sha1'
require 'vte'
require 'MfsSinglePartition'
require 'MfsDiskDrive'

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



def dummyrun(progbar, vte)
	get_partitions(progbar)
	get_users(progbar)
	write_proto 
	@partitions.each { |p| p.umount } 
	progbar.fraction = 1.0
	progbar.text =  "Untersuchung abgeschlossen."
	system("su surfer -c \"firefox file:///tmp/basecheck.html\" &")
	info_dialog("Ende", "Die Analyse ist abgeschlossen. Das Protokoll wird nun in Firefox geöffnet.")
	exit 0
end

def write_proto
	outfile = "/tmp/basecheck.html"
	outstream = File.new(outfile, "w")
	outstream.write "<!DOCTYPE html>\n<html lang=\"de\">\n" + 
		"<head><title>Basis-Sicherheitscheck</title></head>\n<body>" +
		"<h2>Basis-Sicherheitscheck</h2>\n" +
		"<h3>Verschlüsselte Laufwerke (Bitlocker)</h3>"
	if @encrypted.size > 0
		outstream.write "<ul>\n"
		@encrypted.each { |p|
			outstream.write("<li>" + p.device + "</li>")
		}
		outstream.write "</ul>\n"
	else
		outstream.write "<p>Keine verschlüsselten Laufwerke gefunden</p>\n"
	end
	outstream.write "<h3>Unverschlüsselte NTFS-Laufwerke ohne Profile</h3>\n"
	outstream.write "<ul>\n"
	unect = 0
	@partitions.each { |p|
		unless @profiledirs.has_key?(p)
			outstream.write("<li>" + p.device + "</li>")
		end
	}
	outstream.write "</ul>\n"
	if unect > 0 && @profiledirs.size < 1
		outstream.write "<p><a href=\"https://www.computerbild.de/artikel/cb-Tipps-Software-Windows-10-Pro-Tutorial-zu-Hyper-V-und-Bitlocker-und-Gpedit-22237131.html\" target=\"_blank\">So geht's: Bitlocker und Veracrypt aktivieren.</a></p>\n" 
	end
	if @profiledirs.size > 0
		outstream.write "<h3>Unverschlüsselte NTFS-Laufwerke mit Profilen</h3>\n"
		outstream.write "<ul>\n"
		@partitions.each { |p|
			if @profiledirs.has_key?(p)
				outstream.write("<li>" + p.device + "</li>")
			end
		}
		outstream.write "</ul>\n"
		outstream.write "<p><a href=\"https://www.computerbild.de/artikel/cb-Tipps-Software-Windows-10-Pro-Tutorial-zu-Hyper-V-und-Bitlocker-und-Gpedit-22237131.html\" target=\"_blank\">So geht's: Bitlocker und Veracrypt aktivieren.</a></p>\n" 
		@profiledirs.each { |p,u|
			puts "Profiles on " + p.device + ": " + u.join(", ")
			u.each { |d|
				outstream.write "<h4>Analyse \"#{d}\"</h4>\n"
				snippet = "<p>Für die folgenden Logins können Passwörter leicht ausgelesen werden:</p>\n"
				snippet += "<ul>\n"
				ff = false
				pct = 0
				Dir.entries(d).each { |f|
					ff = true if f == "signons.sqlite" || f == "logins.json" 
				}
				if ff == true
					IO.popen("bash ffdecwrap.sh \"" + d + "\"") { |line|
						while line.gets 
							ltoks = $_.strip.split(";")
							url = ltoks[0].sub(/^\"/, "")
							url = url.sub(/\"$/, "")
							if url =~ /^[a-z]+:\/\/[a-z0-9]/
								user = ltoks[1].sub(/^\"/, "")
								user = user.sub(/\"$/, "")
								pct += 1
								snippet += "<li>\n"
								snippet += url + ", Nutzername: " + user
								snippet += "</li>\n"
							end
						end
					}
					snippet += "</ul>\n"
					if pct > 0
						outstream.write snippet
						outstream.write "<p><a href=\"https://www.computerbild.de/artikel/cb-Ratgeber-Software-Passwort-verwalten-2209036.html\" target=\"_blank\">So geht's: Passwörter sicher verwalten.</a></p>\n"
					else
						outstream.write "<p>Keine Passwörter gespeichert oder Passwörter mit Masterpasswort oder TPM gesichert</p>\n"
					end
				else
					fullversion = nil
					majorversion = 0
					begin
						fullversion = File.new(d.sub(/\/Default$/, "") + "/Last Version").read.strip
						majorversion = fullversion.split(".")[0].to_i
					rescue
					end
					if fullversion.nil?
						outstream.write "<p>Die Version von Chrome/Chromium/Edge konnte nicht identifiziert werden.</p>\n"
					elsif majorversion < 60
						outstream.write "<p>Dies scheint ein altes Profil zu sein. Passwörter von Chrome #{fullversion} können leicht ausgelesen werden. Löschen Sie es oder aktualisieren Sie eine veraltete Browserversion.</p>\n"
					else 
						outstream.write "<p>Die Passwortdatenbank von Chrome/Chromium/Edge #{fullversion} wird durch Windows-Funktionen geschützt. Solange Sie ein starkes Login-Kennwort verwenden, ist dieses Profil sicher.</p>\n"
					end
					
				end
				
			}
		}
	end
	outstream.write("</body></html>\n")
	outstream.close 
end


def get_partitions(pgbar)
	@drives = Array.new
	@partitions = Array.new
	@encrypted = Array.new 
	pgbar.text = "Suche Windows-Partitionen"
	Dir.entries("/sys/block").each { |l|
		now = Time.new.to_f
		if now - @last_pulse > 0.10
			pgbar.pulse
			@last_pulse = now
		end
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		if l =~ /[a-z]$/ 
			begin
				d =  MfsDiskDrive.new(l, true)
				@drives.push(d) 
			rescue 
				$stderr.puts "Failed adding: #{l}"
			end
		end
	}
	Dir.entries("/sys/block").each { |l|
		now = Time.new.to_f
		if now - @last_pulse > 0.10
			pgbar.pulse
			@last_pulse = now
		end
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		if ( l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/ || l=~ /nvme[0-9]n[0-9]$/ )
			pgbar.pulse
			begin 
				d =  MfsDiskDrive.new(l, true)
				@drives.push(d) 
			rescue 
				$stderr.puts "Failed adding: #{l}"
			end
		end
	}
	@drives.each { |d|
		d.partitions.each { |p|
			now = Time.new.to_f
			if now - @last_pulse > 0.10
				pgbar.pulse
				@last_pulse = now
			end
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			@partitions.push p if p.fs =~ /ntfs/i
			@encrypted.push p if p.fs =~ /bitlocker/i
		}
	}
	puts "NTFS-Partitionen: " + @partitions.size.to_s
	puts "Bitlocker-Partitionen: " + @encrypted.size.to_s
end

def get_users(pgbar)
	pgbar.pulse
	pgbar.text = "Suche Nutzerprofile"
	@users = Hash.new 
	@profiledirs = Hash.new 
	@partitions.each { |p|
		now = Time.new.to_f
		if now - @last_pulse > 0.10
			pgbar.pulse
			@last_pulse = now
		end
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		p.mount
		mnt = p.mount_point
		ucount = 0
		unless mnt.nil?
			if File.directory?(mnt[0] + "/Users")
				Dir.entries(mnt[0] + "/Users").each { |d|
					unless d == "." || d == ".." || d == "desktop.ini" 
						unless File.symlink?(mnt[0] + "/Users/" + d)
							ucount += 1
							@users[p] = [] unless @users.has_key?(p)
							@users[p].push d
						end
					end
				}
			
			end
		end
	}
	@users.each { |p,u|
		puts p.device + " " + u.join(", ")
		u.each { |d|
			profiledirs = traverse_profiles(p.mount_point[0] + "/Users/" + d, pgbar)
			@profiledirs[p] = profiledirs unless profiledirs.size < 1 
		}
	}
	@partitions.each { |p| p.umount unless @profiledirs.has_key?(p) }
	
end

def traverse_profiles(startpath, pgbar)
	profiledirs = []
	now = Time.new.to_f
	# puts "Traversing: " + startpath 
	if now - @last_pulse > 0.10
		pgbar.text = "Untersuche " + startpath.split("/")[-1] if startpath.split("/")[-1].size < 50
		pgbar.pulse
		@last_pulse = now
	end
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	Dir.entries(startpath).each { |f|
		if File.file?(startpath + "/" + f) && ( f == "signons.sqlite" || f == "logins.json" || f == "Login Data" ) 
			puts "Found " + startpath + "/" + f
			profiledirs.push(startpath)
		elsif File.directory?(startpath + "/" + f) && !File.symlink?(startpath + "/" + f)
			unless  f == "." || f == ".."
				profiledirs = profiledirs + traverse_profiles(startpath + "/" + f, pgbar)
			end
		end
	}
	return profiledirs
end

@profiledirs = Hash.new
@last_pulse = Time.now.to_f 
@users = Hash.new
@encrypted = Array.new
@partitions = Array.new 
@drives = Array.new
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

netlabel = Gtk::Label.new("Dieses Programm prüft Ihren Rechner Computer auf Schwachstellen wie unverschlüsselte Dateisysteme und ungeschützte Passwortdatenbanken. Nach Abschluss der Prüfung erhalten Sie wird ein Protokoll mit Handlungsempfehlungen angezeigt.")
netlabel.wrap = true
netlabel.width_request = 480
netframe.add netlabel 

# Frame choice of passwordlist

listframe = Gtk::Frame.new("Haftung")
# listbox = Gtk::VBox.new
#~ shortradio = Gtk::RadioButton.new("Deutsches Wörterbuch (2 Mio. Einträge, Dauer weniger als 30 Minuten)")
#~ longradio = Gtk::RadioButton.new(shortradio, "Passwortdatenbank und deutsches Wörterbuch (65 Mio. Einträge, Dauer mehrere Stunden)")
#~ listbox.pack_start_defaults(shortradio)
#~ listbox.pack_start_defaults(longradio)

legalcheck = Gtk::CheckButton.new("Ich bin mir bewusst, dass die Anwendung auf fremden Computern strafbar ist.")
listframe.add legalcheck

# Frame progress and output

progframe = Gtk::Frame.new("Fortschritt und Ausgabe")
progbox = Gtk::VBox.new
progbar = Gtk::ProgressBar.new
progbar.height_request = 32
progbar.text = "Bitte Sicherheitscheck starten"
vte = Vte::Terminal.new
vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
vte.height_request = 270
vte.width_request = 760
vte.signal_connect("child_exited") { @vterunning = false }
progbox.pack_start_defaults(progbar)
# progbox.pack_start_defaults(vte)
progframe.add progbox

# Button Start/Stop

gobutton = Gtk::Button.new("Jetzt Sicherheitscheck durchführen")
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
	dummyrun(progbar, vte)
}

window.add(lvb) 
window.set_title("Basis-Sicherheitscheck")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

# fill_network_combo(netcombo)

window.show_all
Gtk.main