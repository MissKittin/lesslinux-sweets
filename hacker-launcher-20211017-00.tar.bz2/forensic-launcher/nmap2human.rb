#!/usr/bin/ruby 
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"
require 'fileutils'

f = "/tmp/nmap.xml"
xml = REXML::Document.new File.new(f)

outfile = "/tmp/protocol.html"
outs = File.open(outfile, "w")

outs.write "<!DOCTYPE html>\n<html lang=\"de\">\n<head><title>NMAP-Auswertung</title></head>\n<body>"
outs.write "<p><a href=\"./nmap.html\" target=\"_blank\">Link zum detaillierten Protokoll</a></p>\n"

allprintports = [ 427, 515, 631, 2000, 9100 ]

nmr = xml.elements["/nmaprun"] 
nmr.elements.each("host") { |h|
	notes = Array.new
	a = h.elements["address"].attributes["addr"]
	puts a 
	outs.write "<h2>Gerät mit IP-Adresse #{a}</h2>"
	pct = 0
	printports = Array.new
	h.elements["ports"].elements.each("port") { |p|
		pct += 1
		# <service name="ssh" product="OpenSSH" version="8.2p1 Ubuntu 4ubuntu0.3" extrainfo="Ubuntu Linux; protocol 2.0" ostype="Linux" method="probed" conf="10">
		tp = p.attributes["portid"].to_i
		s = p.elements["service"]
		sname = s.attributes["name"]
		sproduct = s.attributes["product"]
		sversion = s.attributes["version"]
		puts " " + tp.to_s + "(" + sname.to_s + ", " + sproduct.to_s + ", " + sversion.to_s + ")"
		if tp == 21
			notes.push "<li>FTP-Server auf NAS-Geräten stellen ein Risiko dar, weil der Datentransfer unverschlüsselt erfolgt und Angreifer im entsprechenden Netzwerk zum Beispiel Passwörter mitlesen könnten. Deaktivieren Sie den FTP-Server im Konfigurationsmenü des Geräts.</li>"
		elsif tp == 23
			notes.push "<li>Telnet-Ports werden oft von Malware geöffnet. Falls Sie den Port selbst geöffnet haben (etwa, um auf einen Router oder ein NAS zuzugreifen), nutzen Sie besser den Dienst SSH.</li>"
		elsif tp == 25
			notes.push "<li>Posteingangsserver in privaten Netzwerken können zwar keinen Schaden anrichten, werden aber gelegentlich von spezieller Malware für NAS-Laufwerke installiert. Bitte überprüfen Sie das betroffene Gerät auf Schadsoftware.</li>"
		elsif tp == 111
			notes.push "<li>Auf diesem Gerät ist der Rpcbind-Dienst von außen zugänglich. Dieser Dienst kann für Angriffe mißbraucht werden. Schalten Sie ihn ab, wenn Sie ihn nicht (beispielsweise für NFS-Freigaben benötigen.</li>"
		elsif tp == 139 || tp == 445
			if sversion.to_s =~ /[1-3]\../
				notes.push "<li>Dieses Gerät verwendet eine veraltete Version des SMB-Protokolls (\"Windows-Freigaben\"), das Angriffe ermöglicht. Prüfen Sie, ob eine aktualisierte Firmware für das Gerät erhältlich ist, oder ob es andere Verbindungen bereitstellt (etwa WebDAV).</li>"
			end
		elsif allprintports.include? tp
			printports.push tp
		end
	}
	if printports.size > 2
		notes.push "<li>Bei diesem Gerät scheint es sich um einen Netzwerkdrucker zu handeln. Da solche Geräte häufig Sicherheitslücken haben, prüfen Sie, ob ein Firmware-Update bereitsteht.</li>"
	end
	outs.write "<p>Geöffnete Ports: #{pct}</p>\n"
	if notes.size > 0
		outs.write "<ul>" + notes.uniq.join("\n") + "</ul>\n"
	else
		outs.write("Keine Auffälligkeiten.")
	end
	# Portcount anzeigen
	#
	# Immer kritisch
	# 
	# 23 Telnet kritisch
	# 21 FTP kritisch
	# 25 SMTP
	# 111 rpcbind
	#
	# Samba Version ermitteln: 1. 2. und 3. sind kritisch
	# 139 + 445
	#
	# Reine Printer immer kritisch
	
	
}

outs.write "</body>\n</html>\n"
outs.close