#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'vte'
require 'rexml/document'
require 'TileHelpers'

DLDIR="http://cdprojekte.mattiasschlenker.de/d1a31173-a292-47c2-941a-87614521b85f/"
DLFILE="Windows-Office-Aktualisierer.zip"
DLMD5="3f11e02f8771c554849a1c6585f3f835"

@dlrunning = false
@totalsize = 1
@downloaded = 0
@remainsize = 0
@blacklist = [ "WindowsXP-KB923789-x86-DEU.exe", "WindowsXP-KB946648-x86-DEU.exe", "WindowsXP-KB950760-x86-DEU.exe", "WindowsXP-KB950762-x86-DEU.exe", "WindowsXP-KB950974-x86-DEU.exe", "WindowsXP-KB951698-x86-DEU.exe", "WindowsXP-KB951748-x86-DEU.exe", "WindowsXP-KB952954-x86-DEU.exe", "WindowsXP-KB953155-x86-DEU.exe", "WindowsXP-KB954459-x86-DEU.exe", "WindowsXP-KB956841-x86-DEU.exe", "WindowsXP-KB957095-x86-DEU.exe", "WindowsXP-KB957097-x86-DEU.exe", "WindowsXP-KB958644-x86-DEU.exe", "WindowsXP-KB956802-x86-DEU.exe", "WindowsXP-KB960803-x86-DEU.exe", "WindowsXP-KB960859-x86-DEU.exe", "WindowsXP-KB961501-x86-DEU.exe", "WindowsXP-KB969059-x86-DEU.exe", "WindowsXP-KB971657-x86-DEU.exe", "WindowsXP-KB973507-x86-DEU.exe", "WindowsXP-KB973815-x86-DEU.exe", "WindowsXP-KB973869-x86-DEU.exe", "WindowsXP-KB973904-x86-DEU.exe", "WindowsXP-KB974112-x86-DEU.exe", "WindowsXP-KB974318-x86-DEU.exe", "WindowsXP-KB974392-x86-DEU.exe", "WindowsXP-KB974571-x86-DEU.exe", "WindowsXP-KB975025-x86-DEU.exe", "WindowsXP-KB923561-x86-DEU.exe", "WindowsXP-KB956572-x86-DEU.exe", "WindowsXP-KB952004-x86-DEU.exe", "WindowsXP-KB959426-x86-DEU.exe", "WindowsServer2003.WindowsXP-KB963093-x86-ENU.exe", "WindowsXP-KB956744-x86-DEU.exe", "WindowsXP-KB956844-x86-DEU.exe", "WindowsXP-KB972270-x86-DEU.exe" ]

def start_download(chooser, vte, pgbar) 
	return false unless File.directory? chooser.filename.to_s 
	$stderr.puts "Starting download"
	running = false
	vte.signal_connect("child_exited") { running = false }
	Dir.chdir chooser.filename
	if File.exists? DLFILE
		md5sum = ` md5sum #{DLFILE} `.strip.split[0]
		File.unlink DLFILE unless md5sum == DLMD5
	end
	unless File.exists? DLFILE
		pgbar.text = "Lade Basispaket herunter"
		running = true
		cmd = [ "wget", DLDIR + DLFILE ]
		vte.fork_command(cmd[0], cmd)
		while running == true
			pgbar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
		end
		md5sum = ` md5sum #{DLFILE} `.strip.split[0]
		unless md5sum == DLMD5
			File.unlink DLFILE
			return false
		end
	end
	pgbar.fraction = 1.0
	return true 
end

def unpack_base(chooser, vte, pgbar) 
	Dir.chdir chooser.filename
	pgbar.text = "Entpacke Basispaket"
	running = true
	vte.signal_connect("child_exited") { running = false }
	cmd = [ "unzip", "-o", DLFILE ]
	vte.fork_command(cmd[0], cmd)
	while running == true
		pgbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 0.2 
	end
	pgbar.fraction = 1.0
end

def read_xml(chooser) 
	Dir.chdir chooser.filename + "/Windows-Office-Aktualisierer"
	doc = REXML::Document.new File.new("genInstall.xml")
	doc.elements.each("allpatches/patchgroup") { |g|
		$stderr.puts g.attributes["applies"]
	}
	return doc
end

def calculate_size(checkboxes, patchgroups, pgbar, doc, chooser)
	flatgroups = Array.new
	totalsize = 0
	Dir.chdir chooser.filename + "/Windows-Office-Aktualisierer" unless chooser.filename.nil? 
	0.upto(checkboxes.size - 1) { |n|
		flatgroups = flatgroups + patchgroups[n] if checkboxes[n].active?
	}
	$stderr.puts flatgroups.uniq.join(" - ")
	#doc.elements.each("allpatches/patchgroup") { |g|
	#	$stderr.puts g.attributes["applies"]
	#	if flatgroups.include? g.attributes["applies"]
	#		g.elements.each("update/size") { |s|
	#			totalsize += s.text.to_i 
	#		}
	#	end
	#}
	doc.elements.each("allpatches/patchgroup") { |g|
		$stderr.puts g.attributes["applies"]
		if flatgroups.include? g.attributes["applies"]
			g.elements.each("update") { |u|
				file = u.elements["pkg"].text
				dir = u.elements["dir"].text
				size = 0
				size = u.elements["size"].text.to_i unless u.elements["size"].nil? 
				totalsize += size 
				if chooser.filename.nil?
					@remainsize += size
				elsif File.exists?("packages/" + dir + "/" + file) && File.size("packages/" + dir + "/" + file) == size 
					$stderr.puts("File #{file} exists and size matches")
				elsif g.attributes["applies"] == "xp" && @blacklist.include?(file)
					$stderr.puts("File #{file} is blacklisted and will be ignored")
				else
					@remainsize += size
				end
			}
		end
	}
	pgbar.text = "Downloadumfang ca. " + (@remainsize / 1048576).to_s + "MB" 
	$stderr.puts totalsize.to_s
	pgbar.fraction = 1.0
	@totalsize = totalsize
	return totalsize
end

def download_single(chooser, url, dir, file, sha1sum, pgbar, vte, size)
	return nil if @dlrunning == false
	Dir.chdir chooser.filename + "/Windows-Office-Aktualisierer"
	system("mkdir -p packages/#{dir}")
	if File.exists? "packages/" + dir + "/" + file
		pgbar.text = "Prüfe vorhandene Datei #{file}"
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		checksum = ` sha1sum packages/#{dir}/#{file} `.strip.split[0]
		File.unlink "packages/" + dir + "/" + file unless checksum == sha1sum 
	end
	unless File.exists?  "packages/" + dir + "/" + file
		pgbar.text = "Lade #{file} herunter"
		running = true
		vte.signal_connect("child_exited") { running = false }
		cmd = [ "wget", "-O", "packages/" + dir + "/" + file, url ]
		vte.fork_command(cmd[0], cmd)
		while running == true
			# pgbar.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
		end
		checksum = ` sha1sum packages/#{dir}/#{file} `.strip.split[0]
		unless checksum == sha1sum 
			File.unlink  "packages/" + dir + "/" + file
			return file
		end
	end
	@downloaded += size
	pgbar.fraction = @downloaded.to_f / @totalsize.to_f
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	return nil 
end

def download_all(checkboxes, patchgroups, pgbar, doc, vte, chooser)
	flatgroups = Array.new
	failed = Array.new
	totalsize = 0
	0.upto(checkboxes.size - 1) { |n|
		flatgroups = flatgroups + patchgroups[n] if checkboxes[n].active?
	}
	$stderr.puts flatgroups.uniq.join(" - ")
	doc.elements.each("allpatches/patchgroup") { |g|
		$stderr.puts g.attributes["applies"]
		if flatgroups.include? g.attributes["applies"]
			g.elements.each("update") { |u|
				unless u.elements["url"].nil?
					url = u.elements["url"].text
					file = u.elements["pkg"].text
					dir = u.elements["dir"].text
					sha1sum = u.elements["sha1sum"].text
					size = u.elements["size"].text.to_i 
					res = nil 
					unless g.attributes["applies"] == "xp" && @blacklist.include?(file)
						res = download_single(chooser, url, dir, file, sha1sum, pgbar, vte, size) 
					end
					failed.push res unless res.nil?
				end
			}
		end
	}
	puts failed.join(" - ") 
	return failed 
end

# Patchgroups

nicenames = [ "Windows XP", "Windows Vista", "Windows 7 (32 Bit)", "Windows 7 (64 Bit)", 
	"Office 2003", "Office 2007", "Office 2010", "Office 2013 (32 Bit)", "Office 2013 (64 Bit)" ]
checkboxes = Array.new 
patchgroups = [
	[ "net", "xpforce", "xpsp3", "xpie", "xpwmp11", "xp" ],
	[ "net", "vistaforce", "vistaie8", "vistaie9", "vistapresp1", "vistasp1", "vistasp2", "vista" ],
	[ "net", "win7ie11", "win7sp1", "win7" ],
	[ "net", "win764ie11", "win764sp1", "win764" ],
	[ "o2k3sp3", "o2k3" ],
	[ "o2k7sp3", "o2k7" ],
	[ "o2k10sp2", "o2k10" ],
	[ "o2k13sp1", "o2k13" ],
	[ "o2k1364sp1", "o2k1364" ]
]
doc = nil

window = Gtk::Window.new
window.title = "Windows- und Office-Aktualisierungen herunterladen"
# window.width_request = 600
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

lvb = Gtk::VBox.new

# Frame for selection of output directory

dframe = Gtk::Frame.new("Zielverzeichnis auswählen")
chooser = Gtk::FileChooserButton.new("", Gtk::FileChooser::ACTION_SELECT_FOLDER)
chooser.current_folder = "/media/disk"
chooser.width_request = 430
cbox = Gtk::HBox.new
cbox.pack_start_defaults chooser
cbutton = Gtk::Button.new("Laufwerke einbinden")
cbutton.width_request = 145
cbox.pack_start_defaults cbutton
dframe.add cbox
lvb.pack_start_defaults dframe

# Frame for selection of windows updates

wframe = Gtk::Frame.new("Windows-Aktualisierungen auswählen")
wbox = Gtk::VBox.new
0.upto(3) { |n|
	checkboxes[n] = Gtk::CheckButton.new(nicenames[n])
	wbox.pack_start_defaults(checkboxes[n]) 
}
wframe.add wbox
lvb.pack_start_defaults wframe

# Frame for selection of office updates

oframe = Gtk::Frame.new("Office-Aktualisierungen auswählen")
obox = Gtk::VBox.new
4.upto(nicenames.size - 1) {|n|
	checkboxes[n] = Gtk::CheckButton.new(nicenames[n])
	obox.pack_start_defaults(checkboxes[n]) 
}
oframe.add obox
lvb.pack_start_defaults oframe

# Frame for go, progess bar and terminal 

gframe = Gtk::Frame.new("Start und Fortschritt")
gbox = Gtk::VBox.new
vte = Vte::Terminal.new
vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
vte.height_request = 130
vte.width_request = 580
gbox.pack_start_defaults vte 

dlprogress = Gtk::ProgressBar.new
dlprogress.height_request = 32
dlprogress.width_request = 580
dlprogress.text = "Bitte Zielverzeichnis auswählen!"
gbox.pack_start_defaults dlprogress

gobutton = Gtk::Button.new("Herunterladen starten")
gobutton.height_request = 32
gobutton.width_request = 580
gobutton.sensitive = false
gbox.pack_start_defaults gobutton

gframe.add gbox
lvb.pack_start_defaults gframe

checkboxes.each { |c|
	c.signal_connect("clicked") {
		acount = 0
		checkboxes.each { |b|
			acount += 1 if b.active?
		}
		calculate_size(checkboxes, patchgroups, dlprogress, doc, chooser) unless doc.nil?
		gobutton.sensitive = false
		gobutton.sensitive = true if ( acount > 0 && !chooser.filename.nil?)
	}
}
chooser.signal_connect("current-folder-changed") {
	acount = 0
	checkboxes.each { |b|
		acount += 1 if b.active?
	}
	calculate_size(checkboxes, patchgroups, dlprogress, doc, chooser) unless doc.nil?
	gobutton.sensitive = false
	gobutton.sensitive = true if ( acount > 0 && !chooser.filename.nil?)
}

cbutton.signal_connect("clicked") {
	system("mmmmng.sh &") 
}

gobutton.signal_connect("clicked") {
	if @dlrunning == true
		gobutton.sensitive = false
		@dlrunning = false
		system("killall -9 wget")
		sleep 2.0
		dlprogress.text = "Herunterladen abgebrochen"
		dlprogress.fraction = 1.0
	else
		@downloaded = 0 
		chooser.sensitive = false
		gobutton.sensitive = false
		checkboxes.each { |c| c.sensitive = false }
		success = start_download(chooser, vte, dlprogress)
		unpack_base(chooser, vte, dlprogress) if success == true
		doc = read_xml(chooser)
		@remainsize = 0
		calculate_size(checkboxes, patchgroups, dlprogress, doc, chooser)
		# Ask again
		if TileHelpers.yes_no_dialog("Wollen Sie die ausgewählten Pakete jetzt herunterladen und vorhandene Pakete überprüfen? Der Downloadumfang beträgt ca. " + (@remainsize / 1048576).to_s + "MB.")
			@dlrunning = true
			gobutton.sensitive = true
			gobutton.label = "Herunterladen abbrechen"
			failed = download_all(checkboxes, patchgroups, dlprogress, doc, vte, chooser)
			if failed.size > 0
				TileHelpers.error_dialog("Die folgenden Pakete konnten nicht heruntergeladen werden: " + failed.join(", ") + "\n\nSofern es sich um einzelne Dateien handelt, stellt dies meist kein Problem dar. Öffnen Sie unter Windows das Programm \"genInstall.exe\", um die Windows-Aktualisierung zu starten.")
			else
				TileHelpers.success_dialog("Alle Pakete wurden erfolgreich heruntergeladen. Öffnen Sie unter Windows das Programm \"genInstall.exe\", um die Windows-Aktualisierung zu starten.")
			end
		end
		dlprogress.fraction = 1.0
		chooser.sensitive = true
		checkboxes.each { |c| c.sensitive = true }
		gobutton.label = "Herunterladen starten"
		gobutton.sensitive = true
		@dlrunning = false
	end
}

window.add lvb
window.show_all
Gtk.main
