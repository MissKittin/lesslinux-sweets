#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'vte'
require "rexml/document"
require 'optparse'
require 'InfoScreen'
require 'SambaScreen'
require 'WindowsScreen'
require 'PhotorecScreen'
require 'MobilerecScreen'
require 'RescueScreen'
require 'VirusScreen'
require 'TileHelpers'

@simulate = Array.new
@deco = true
opts = OptionParser.new 
opts.on('-s', '--simulate', :REQUIRED ) { |i| i.split(",").each { |j| @simulate.push(j) } }
opts.on('--no-deco') { @deco = false } 
opts.parse!

window = Gtk::Window.new
window.border_width = 10
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

if @deco == false
	window.deletable = false
	window.decorated = false
	window.allow_grow = false
	window.allow_shrink = false
end

window.title = "Notfall-CD 4.0"
window.signal_connect('delete_event') { false }
window.signal_connect('destroy') { 
	system("rm /var/run/lesslinux/assistant_running")
	Gtk.main_quit
}

# Layout table

table = Gtk::Table.new(3,    7,    false)
table.row_spacings = 10
table.column_spacings = 10

button = Array.new
button[0] = Gtk::EventBox.new.add Gtk::Image.new("reparieren.png")
button[1] = Gtk::EventBox.new.add Gtk::Image.new("viren.png")
button[2] = Gtk::EventBox.new.add Gtk::Image.new("erase.png")
button[3] = Gtk::EventBox.new.add Gtk::Image.new("password.png")
button[4] = Gtk::EventBox.new.add Gtk::Image.new("recover.png")
button[5] = Gtk::EventBox.new.add Gtk::Image.new("photorec.png")
button[6] = Gtk::EventBox.new.add Gtk::Image.new("samba.png")
button[7] = Gtk::EventBox.new.add Gtk::Image.new("rescue.png")
button[8] = Gtk::EventBox.new.add Gtk::Image.new("shutdown.png")
button[9] = Gtk::EventBox.new.add Gtk::Image.new("desktop.png")
button[10] = Gtk::EventBox.new.add Gtk::Image.new("info.png")

desctexts = [ 
"Stürzt Windows häufig ab, oder startet der PC nur noch mit einer Fehlermeldung? Für solche Fälle gibt es viele mögliche Ursachen. Solange es nicht an einer defekten Hardware liegt, kann das Problem meist von der Notfall-CD behoben werden. Wählen Sie dazu diese Option, und folgen Sie den weiteren Anweisungen.", 
"Merkwürdige PC-Ausfälle, langsames Arbeitstempo und eine scheinbar grundlos ratternde Festplatte können auf eine Viren-Infektion hindeuten. Mit dieser Funktion überprüfen Sie den Computer auf Schadsoftware und löschen sie. Das klappt sogar bei Viren, die unter Windows nicht entdeckt oder entfernt werden können.",
"Möchten Sie Ihren Computer verkaufen, Ihre alte Festplatte oder einen USB-Stick entsorgen? Dann sollten Sie sicherstellen, dass niemand an Ihre persönlichen Dateien kommt. Ein Klick auf diesen Eintrag startet den Datenschredder der Notfall-CD, der den Inhalt beliebiger Laufwerke unwiederbringlich löscht.", 
"Sie haben Ihr Windows-Kennwort vergessen und sind vom PC ausgesperrt? Mit diesem Notfall-Werkzeug können Sie das Zugangspasswort zurücksetzen und sich wieder am Betriebssystem anmelden. Vergessen Sie aber nicht, danach ein neues Kennwort unter Windows einzurichten.",
"Haben Sie versehentlich wichtige Dateien von der Festplatte gelöscht und den Windows-Papierkorb geleert? Dann wählen Sie diese Rettungs-Funktion. Damit stellen Sie beliebige Dateien wieder her, solange deren Speicherbereich auf dem Laufwerk nicht anderweitig überschrieben wurde.", 
"Wurden unersetzliche Bilder von einer Kamera oder einem Mobiltelefon gelöscht, hilft in vielen Fällen diese Option. Schließen Sie das Gerät per USB-Kabel an oder legen Sie dessen Speicherkarte ins Lesegegerät im PC. Danach sucht die Notfall-CD gelöschte Daten und stellt sie wieder her. ", 
"Sie möchten die Daten auf diesem PC sichern, haben aber kleine externe Festplatte frei? Falls Sie ein Heimnetzwerk besitzen, können Sie die Festplatte dieses Computers freigeben und von einem anderen PC darauf zugreifen. So lassen sich Dateien direkt auf dem zweiten Computer sichern.", 
"Bei drohendem Festplatten-Ausfall bietet die Notfall-CD automatisch eine Komplettsicherung aller Daten. Per Klick auf diesen Eintrag können Sie eine Sicherung manuell anstoßen oder zurückspielen. Zudem lassen sich einzelne Dateien auf USB-Laufwerken oder in der COMPUTER BILD Cloud sichern.", 
"Diese Auswahl schaltet den Computer aus und wirft die Notfall-CD aus dem Laufwerk. Um Windows zu starten, entnehmen Sie die CD und schalten den Computer wieder ein.", 
"Weitere Rettungsprogramme sowie einen kompletten Notfall-Arbeitsplatz finden Sie in dieser erweiterten Oberfläche. Damit können Sie zum Beispiel ohne Windows im Internet surfen, E-Mails schreiben und Dateien herunterladen. ", 
"Hier erfahren Sie mehr über Urheber und Entstehung der Notfall-CD 4.0." ]
descriptions = Hash.new
infolabel = Gtk::Label.new
infolabel.set_markup("<span color='white'>Bewegen Sie die Maus über eine der Kacheln.</span>")
infolabel.wrap = true
infolabel.width_request = 500

0.upto(5) { |n|
	button[n].set_size_request(250, 120)
}
6.upto(10) { |n|
	button[n].set_size_request(120, 120)
}

0.upto(10) { |n|
	descriptions[button[n]] = desctexts[n]
	button[n].signal_connect('enter-notify-event') { |x, y|
		# puts "Entered: " + descriptions[x]
		infolabel.set_markup("<span color='white'>" + descriptions[x] + "</span>")
	}
	button[n].signal_connect('button-release-event') { |x, y|
		if y.button == 1 
			# puts "Clicked: " + descriptions[x]
		elsif y.button == 2 && x == button[10]
			puts "Middle clicked info"
			system("/usr/games/xtris &")
		end
	}
	
}

options = Gtk::FILL|Gtk::EXPAND
table.attach(button[0],  0,  2,  0,  1, options, options, 0,    0)
table.attach(button[4],  2,  4,  0,  1, options, options, 0,    0)
table.attach(button[5],  4,  6,  0,  1, options, options, 0,    0)
table.attach(button[1],  0,  2,  1,  2, options, options, 0,    0)
table.attach(button[3],  2,  4,  1,  2, options, options, 0,    0)
table.attach(button[2],  4,  6,  1,  2, options, options, 0,    0)

table.attach(button[7],  6,  7,  0,  1, options, options, 0,    0)
table.attach(button[6],  6,  7,  1,  2, options, options, 0,    0)
table.attach(button[10], 4,  5,  2,  3, options, options, 0,    0)
table.attach(button[9],  5,  6,  2,  3, options, options, 0,    0)
table.attach(button[8],  6,  7,  2,  3, options, options, 0,    0)
table.attach(infolabel,  0,  4,  2,  3, options, options, 0,    0)

window.set_size_request(972, 548)
window.border_width = 0

bgimg = Gtk::Image.new("bg_notfall.png")

fixed = Gtk::Fixed.new
fixed.put(bgimg, 0, 0)
fixed.put(table, 35, 136)

#
# Now create some objects for each task - return windows as "named layers"
# 

layers = Hash.new
layers["start"] = table

# First the simple info screen
infoscreen = InfoScreen.new(layers, button[10])
infoscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now the Samba share
sambascreen = SambaScreen.new(layers, button[6])
sambascreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now fix windows
winfixscreen = WindowsScreen.new(layers, button[0])
winfixscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now Photorec
photorecscreen = PhotorecScreen.new(layers, button[4])
photorecscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now Photorec
mobilerecscreen = MobilerecScreen.new(layers, button[5])
mobilerecscreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now Rescue
rescuescreen = RescueScreen.new(layers, button[7] )
rescuescreen.layers.each { |k| fixed.put(k, 35, 136) }

# Now virus screen
virusscreen = VirusScreen.new(layers, button[1] )
virusscreen.layers.each { |k| fixed.put(k, 35, 136) }

# No separate layer for desktop mode
button[9].signal_connect('button-release-event') {
	system("touch /var/run/lesslinux/requested_desktop")
	system("chown 1000:1000 /var/run/lesslinux/requested_desktop")
	Gtk.main_quit 
}

# No separate layer for shutdown
button[8].signal_connect('button-release-event') {
	system("touch /var/run/lesslinux/requested_shutdown")
	Gtk.main_quit 
}

#
# Show everything
#

window.add fixed
window.show_all 
layers.each { |k,v| v.hide_all }
layers["start"].show_all 

Gtk.main
