#!/usr/bin/ruby
# encoding: utf-8
require 'gtk2'
require 'uri' 
require 'vte' if RUBY_PLATFORM =~ /linux/i

# THIS is not open source, proprietary license COMPUTER BILD

# Find mail client

def pathsep 
	if RUBY_PLATFORM =~ /linux/i
		return "/"
	else
		return "\\"
	end
end

def sevenzip
	if RUBY_PLATFORM =~ /linux/i
		return "7za"
	else
		path = nil
		rawreg = ` reg query "HKLM\\SOFTWARE\\7-Zip" /v Path `.split("\n")
		rawreg.each { |l|
			if l =~ /REG_SZ/
				path = l.gsub("REG_SZ", "").gsub("Path", "").strip + "\\7z.exe" 
				path = nil unless File.exists?(path) 
			end
		}
		return path unless path.nil?
		reg64 = ENV['WINDIR'] + "\\sysnative\\reg.exe"
		rawreg = ` #{reg64} query "HKLM\\SOFTWARE\\7-Zip" /v Path `.split("\n")
		rawreg.each { |l|
			if l =~ /REG_SZ/
				path = l.gsub("REG_SZ", "").gsub("Path", "").strip + "\\7z.exe"
				path = nil unless File.exists?(path) 
			end
		}
		return path unless path.nil?
		return "7z.exe" 
	end
	return nil 
end

def mailer_is_thunderbird
	return true if RUBY_PLATFORM =~ /linux/
	reg64 = ENV['WINDIR'] + "\\sysnative\\reg.exe"
	begin
		rawreg = ` #{reg64} query "HKCU\\SOFTWARE\\Clients\\Mail" /ve `.split("\n")
		rawreg.each { |l|
			if l =~ /REG_SZ/ && l =~ /thunderbird/i 
				return true
			end	
		}
	rescue
	end
	rawreg = ` reg query "HKCU\\SOFTWARE\\Clients\\Mail" /ve `.split("\n")
	rawreg.each { |l|	
		if l =~ /REG_SZ/ && l =~ /thunderbird/i 
			return true
		end	
	}
	begin
		rawreg = ` #{reg64} query "HKLM\\SOFTWARE\\Clients\\Mail" /ve `.split("\n")
		rawreg.each { |l|
			if l =~ /REG_SZ/ && l =~ /thunderbird/i 
				return true
			end	
		}
	rescue
	end
	rawreg = ` reg query "HKLM\\SOFTWARE\\Clients\\Mail" /ve `.split("\n")
	rawreg.each { |l|	
		if l =~ /REG_SZ/ && l =~ /thunderbird/i 
			return true
		end	
	}
	return false
end


def desktop
	if RUBY_PLATFORM =~ /linux/i
		return ENV['HOME'] + "/Desktop"
	else
		return ENV['HOMEDRIVE'] + ENV['HOMEPATH'] + "\\Desktop"  
	end
end

# Generic Info box
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

def move_old(outfile)
	return false unless File.exists?(outfile)
	suffix = ".7z"
	suffix = ".zip" if outfile =~ /\.zip$/ 
	stripped_out = outfile.gsub(suffix, "")
	mtime = File.mtime(outfile)
	moved_out = stripped_out + mtime.strftime("-%Y%m%d-%H%M%S") + suffix
	File.rename(outfile, moved_out) 
end

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

# Run a command with progress bar
def run_with_progress(command, title="Be patient...", pgtext="Creating archive")
	unless RUBY_PLATFORM =~ /linux/i
		command = command.map { |x| "\"#{x}\""  } 
		cli = command.join(" ")
		IO.popen(cli) { |l| }  
		return true
	end
	ctoks = command # .split
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 450
	pgbar.height_request = 24
	pgbar.text = pgtext
	dialog.vbox.add(pgbar)
	vte = Vte::Terminal.new
	cmd_running = true
	dialog.show_all
	vte.signal_connect("child-exited") { cmd_running = false } 
	vte.fork_command(ctoks[0], ctoks)
	while cmd_running == true
		pgbar.pulse
		sleep 0.2
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end
	dialog.destroy
end

# Update filelist
def update_filelist(newfile, textfield)
	# puts "Current text:" + textfield.text 
	# puts "New file:" + newfile
	subst = "file:///"
	subst = "file://" if RUBY_PLATFORM =~/linux/i 
	textfield.text = textfield.text + newfile.gsub(subst, "")
	list = textfield.text.split("\n")
	list.map! { |x| URI.unescape(x.strip) } 
	list = list.uniq.sort
	textfield.text = list.join("\n") + "\n"
	puts "Files to put in archive:" 
	puts list.join("\n")
end

# Print options etc.
def assemble_archive(textfield, zip, mail, filelist, password, outdir )
	puts "Text length: " + textfield.text.strip.size.to_s
	puts "Zip requested? " + zip.to_s
	puts "Mail requested? " + mail.to_s
	puts "Files to add: " + filelist.text 
	puts "Password (chars): " + password.size.to_s 
	puts "Outdir: " + outdir
	# Check if the output folder exists
	
	# Create temporary folder if mail requested
	rnd = rand(1_000_000_000_000_000)
	tmpdir = nil
	if RUBY_PLATFORM =~/linux/i
		tmpdir = "/tmp"
	else
		tmpdir = ENV['TEMP'] 
	end
	rnddir = tmpdir + pathsep + rnd.to_s 
	Dir.mkdir(rnddir, 0700)
	outfile = nil
	outpref = nil
	targ = nil
	if mail == true
		# outdir = rnddir
		pref = "tarnmailer"
	else
		t = Time.now
		# pref = t.strftime("%Y%m%d-%H%M")
		pref = "tarnmailer"
	end
	if zip == true
		targ = "-tzip"
		outfile = outdir + pathsep + "#{pref}.zip"
	else
		targ = "-t7z"
		outfile = outdir + pathsep + "#{pref}.7z"
	end
	# Move old outfile if necessary
	move_old(outfile)
	# Write the text file
	tlines = textfield.text.strip.split("\n")
	ttext = tlines.join("\r\n") + "\r\n"
	mailfile = File.new("#{rnddir}#{pathsep}mail.txt", "w")
	mailfile.write "\uFEFF" unless RUBY_PLATFORM =~ /mingw/  
	mailfile.write ttext 
	mailfile.close 
	opts = [ sevenzip, "a" ]
	opts.push targ
	opts.push "-p" + password
	opts.push "-mhe=on" if zip == false 
	opts.push "-mem=AES256" if zip == true 
	opts.push outfile
	opts.push "#{rnddir}#{pathsep}mail.txt" if textfield.text.strip.size > 0 
	filelist.text.split("\n").each { |f|
		opts.push(f.strip) if f.strip.size > 0 
	}
	# v = Vte::Terminal.new
	# v.fork_command(opts[0], opts)
	
	puts opts.join(" ") 
	run_with_progress(opts, "Archiv wird erstellt", "Erstelle das Archiv #{outfile} - bitte haben Sie Geduld!") 
	
	# system(opts.join(" "))
	# puts outfile
	# Assemble the archive!
	# v = Vte::Terminal.new
	# v.fork_command("7z", [ "7z", "a", "-t7z", "/tmp/test.7z",  "-sitest.txt" ]) 
	# sleep 3
	
	File.unlink "#{rnddir}#{pathsep}mail.txt"
	# return path to archive
	return outfile if File.exists?(outfile)
	return nil
end

# Check for valid password

def check_password(entry, filelist, textbuffer)
	return true if entry.size > 9 && entry =~ /[A-Z]/ && entry =~ /[a-z]/ && entry =~ /[0-9]/ && ( filelist.text.strip.size > 0 || textbuffer.text.strip.size > 0 )
	return false
end

# Which operating system?
puts RUBY_PLATFORM

# Create a new assistant widget with no pages. */
assistant = Gtk::Assistant.new
assistant.set_size_request(550, -1)   # 450, 300
assistant.signal_connect('destroy') { Gtk.main_quit }
assistant.title = "COMPUTER BILD Tarnmailer"

pages = Array.new

# Page 0 Welcome

intro_text = Gtk::Label.new
intro_text.width_request = 520 
intro_text.wrap = true
intro_text.set_markup("Dieses Programm erstellt verschlüsselte Zip-Dateien, die Sie direkt per E-Mail verschicken oder zuvor auf dem Desktop speichern können. Im nächsten Fenster geben Sie den Text der E-Mail ein und fügen bei Bedarf weitere Dateien hinzu. Das gesamte E-Mail-Paket wird danach mit der Verschlüsselungsmethode AES-256 gesichert und ist damit nach heutigem Stand der Technik spionagesicher.")
pages[0] = assistant.append_page intro_text
assistant.set_page_title(intro_text, "COMPUTER BILD Tarnmailer")
assistant.set_page_complete(intro_text, true)

# Page 1 Text
mail_text = Gtk::Label.new
mail_text.width_request = 520 
mail_text.wrap = true
mail_text.set_markup("Bitte tippen Sie hier den E-Mail-Text ein. Im verschlüsselten Paket wird er als Datei mit den Namen \"mail.txt\" erscheinen.")
lbox = Gtk::VBox.new(false, 5)
lbox.pack_start_defaults(mail_text)
buffer = Gtk::TextBuffer.new
tview = Gtk::TextView.new(buffer)
tview.width_request = 520
tview.height_request = 240
lbox.pack_start_defaults(tview)
pages[1] = assistant.append_page lbox
assistant.set_page_title(lbox, "Texteingabe")
assistant.set_page_complete(lbox, true)

# Page 2 Drag and Drop
drag_text = Gtk::Label.new
drag_text.width_request = 520 
drag_text.wrap = true
drag_text.set_markup("Bei Bedarf fügen Sie dem E-Mail-Paket nun beliebige Dateien hinzu. Dazu ziehen Sie sie einfach mit der Maus in dieses Fenster.")
dbox =  Gtk::VBox.new(false, 5)
dbox.pack_start_defaults(drag_text)
flist = Gtk::TextBuffer.new
lview = Gtk::TextView.new(flist)
lview.width_request = 520
lview.height_request = 240
dbox.pack_start_defaults(lview)
Gtk::Drag.dest_set(lview,  Gtk::Drag::DEST_DEFAULT_DROP, [["text/uri-list", 0, 0]], Gdk::DragContext::ACTION_COPY| Gdk::DragContext::ACTION_MOVE)
lview.signal_connect("drag_data_received") { |w, context, x, y, data, info, time|
	newfile = data.data
	Gtk::Drag.finish(context, true, false, 0)
	update_filelist(newfile, flist)
}
pages[2] = assistant.append_page dbox
assistant.set_page_title(dbox, "Weitere Dateien hinzufügen")
assistant.set_page_complete(dbox, true)

# Page 3 Options
obox =  Gtk::VBox.new(false, 5)
alabel = Gtk::Label.new("Archivformat - In welchen Format soll das Archiv erstellt werden?")
alabel.width_request = 520
alabel.wrap = true
obox.pack_start(alabel, false, false, 0)
ztype = Gtk::RadioButton.new("Zip")
t7ype = Gtk::RadioButton.new(ztype, "7z")
obox.pack_start(ztype, false, false, 0)
obox.pack_start(t7ype, false, false, 0)
slabel = Gtk::Label.new("Versandoptionen - Wollen Sie das erstellte Archiv abspeichern oder direkt per Email verschicken?") 
slabel.width_request = 520
slabel.wrap = true
obox.pack_start(slabel, false, false, 0)
sarch = Gtk::RadioButton.new("E-Mail-Paket auf den Desktop legen")
apath = Gtk::FileChooserButton.new("Ausgabeverzeichnis", Gtk::FileChooser::ACTION_SELECT_FOLDER)
apath.current_folder = desktop
smail = Gtk::RadioButton.new(sarch, "Versand per E-Mail")
# mtype, mcmd = mailer
# smail.sensitive = false if mtype.nil? 
obox.pack_start(sarch, false, false, 0)
# obox.pack_start(apath, false, false, 0)
obox.pack_start(smail, false, false, 0)
plabel = Gtk::Label.new("Legen sie hier ein Passwort fest. Es muss mindestens 10 Zeichen, darunter wenigstens einen Großbuchstaben, einen Kleinbuchstaben und eine Ziffer enthalten.") 
plabel.width_request = 520
plabel.wrap = true 
obox.pack_start(plabel, false, false, 0)
pentry = Gtk::Entry.new
pentry.width_request = 520
obox.pack_start(pentry, false, false, 0)
pshow = Gtk::CheckButton.new("Passwort anzeigen")
pshow.active = true
pshow.signal_connect("clicked") { pentry.visibility = pshow.active? }
obox.pack_start(pshow, false, false, 0)

pages[3] = assistant.append_page obox
assistant.set_page_title(obox, "Archiv- und Versandoptionen")
assistant.set_page_complete(obox, true)
assistant.set_page_type(obox, Gtk::Assistant::PAGE_CONFIRM) 
assistant.set_page_complete(obox, false)
pentry.signal_connect("key-release-event") {
	assistant.set_page_complete(obox,check_password(pentry.text, flist, buffer))
}

assistant.signal_connect( 'cancel')  { assistant.destroy }
assistant.signal_connect(   'close')   { |w| assistant.destroy}
assistant.signal_connect(   "apply") { 
	outfile = assemble_archive(buffer, ztype.active?, smail.active?, flist, pentry.text, apath.filename )
	mbody = "Sehr geehrte/r Empfänger/in,\n\nim Anhang dieser E-Mail befindet sich eine verschlüsselte Nachricht. Sie lässt sich nur durch Eingabe des dazugehörigen Passworts öffnen. Dieses Passwort erhalten Sie beim Absender der E-Mail.\n\nFalls sich die Datei an Ihrem Computer nicht öffnen lässt, benötigen Sie dazu das Gratis-Programm 7zip. Das können Sie von der Internetseite www.computerbild.de/11703 (Windows, 32 Bit) beziehungsweise www.computerbild.de/11704 (Windows, 64 Bit) überspielen.\n\n\nNachricht erstellt von COMPUTER BILD Tarnmailer, www.computerbild.de\n"
	msubj = "Verschluesselter E-Mail-Anhang von COMPUTER BILD Tarnmailer"
	if outfile.nil? 
		error_dialog("Fehler", "Die Erstellung des Archivs ist fehlgeschlagen.")
		exit 1
	elsif smail.active? == true
		if RUBY_PLATFORM =~ /mingw/ 
			bodyfile = ENV['TEMP']  + "\\tarnmailer.txt"
			mbfile = File.open(bodyfile, "w")
			mbfile.write(mbody)
			mbfile.close 
			mailto = "-to \"1@3\""
			mailto = "" if mailer_is_thunderbird
			IO.popen("SendToVB.exe #{mailto} -f \"#{outfile}\" -bodyfile \"#{bodyfile}\" -s \"#{msubj}\" ") { |l| } 
			# sleep 5
			# File.unlink(bodyfile) 
		else
			mbody = mbody.gsub("\n", "%0D%0A") .gsub(",", "%2C") 
			system("thunderbird -compose subject='#{msubj}',body='#{mbody}',attachment='file://#{outfile}' &")
		end
		# info_dialog("Archiv erstellt", "Sie können die Datei #{outfile} nach erfolgtem Mailversand löschen.")
		exit 0 
	else
		info_dialog("Archiv erstellt", "Das Archiv #{outfile} wurde erfolgreich erstellt!")
		exit 0
	end
	#v = Vte::Terminal.new
	#v.fork_command("7z", [ "7z", "a", "-t7z", "/tmp/test.7z",  "-sitest.txt" ]) 
	#sleep 3
	#v.feed_child("Hallo Welt!\n\cd")
}
assistant.show_all
Gtk.main