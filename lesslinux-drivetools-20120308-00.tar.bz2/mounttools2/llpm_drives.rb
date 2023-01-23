#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"
require 'gtk2'
require 'MfsSinglePartition.rb'
require 'MfsDiskDrive.rb'

# Create a pipe menu for openbox. Call via wrapper and include like
#
#<menu id="MmDrives" label="Laufwerke" execute="sudo /usr/bin/llpm_drives" />
#<menu id="root-menu" label="Openbox 3">
#  <separator label="Applications" />
#  <menu id="apps-accessories-menu"/>
#  <menu id="apps-editors-menu"/>
#  <menu id="apps-graphics-menu"/>
#  <menu id="apps-net-menu"/>
#  <menu id="apps-office-menu"/>
#  <menu id="apps-multimedia-menu"/>
#  <menu id="apps-term-menu"/>
#  <menu id="apps-fileman-menu"/>
#  <separator label="LessLinux" />
#  <menu id="MmDrives"/> 
#  <separator label="System" />
#  <menu id="system-menu"/>
#  <separator />
#  <item label="Log Out">
#    <action name="Exit">
#      <prompt>yes</prompt>
#    </action>
#  </item>
#</menu>

doc = REXML::Document.new # (nil, { :respect_whitespace => %w{ script style } } )
root = REXML::Element.new "openbox_pipe_menu"
mct = 0

drives = Array.new
Dir.entries("/sys/block").each { |l|
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/ 
}
Dir.entries("/sys/block").each { |l|
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /sr[0-9]$/ 
}
internal_items = Array.new
external_items = Array.new
drives.each { |d|
	d.partitions.each { |p|
		drive = REXML::Element.new "menu"
		label = "#{p.device} (#{p.human_size}, #{p.fs.to_s})"
		label = "#{p.device} (#{p.human_size}, #{p.fs.to_s}, #{p.label.to_s})" unless p.label.to_s == ""
		iswindows, winversion = p.is_windows 
		label = "#{p.device} (#{p.human_size}, #{p.fs.to_s}, #{winversion})" if iswindows == true
		label = "#{p.device} (#{p.human_size}, Systemlaufwerk)" if p.system_partition?
		drive.add_attribute("label", label)
		drive.add_attribute("id", "lldrive-" + p.device)
		if p.mount_point.nil?
			system("mkdir -p /media/#{p.device}")
			ro = REXML::Element.new "item"
			ro.add_attribute("label", "Nur-lesbar einbinden") 
			ro.add_text "llpm_mount mount-ro #{p.device}"
			drive.add ro
			rw = REXML::Element.new "item"
			rw.add_attribute("label", "Schreibbar einbinden") 
			rw.add_text "llpm_mount mount-rw #{p.device}"
			drive.add rw
		elsif p.system_partition?
			act = REXML::Element.new "item"
			act.add_attribute("label", "Inhalt anzeigen")
			act.add_text "llpm_mount show #{p.device}"
			drive.add_element act
		else
			act = REXML::Element.new "item"
			act.add_attribute("label", "Inhalt anzeigen")
			act.add_text "llpm_mount show #{p.device}"
			drive.add_element act
			umnt = REXML::Element.new "item"
			umnt.add_attribute("label", "Einbindung lösen")
			umnt.add_text "llpm_mount umount #{p.device}"
			drive.add_element umnt
			rmnt =  REXML::Element.new "item"
			if p.mount_point[1].include?("ro") 
				rmnt.add_attribute("label", "Schreibbar einbinden")
				rmnt.add_text "llpm_mount mount-rw #{p.device}"
			else
				rmnt.add_attribute("label", "Nur-lesbar einbinden")
				rmnt.add_text "llpm_mount mount-rw #{p.device}"
			end
			drive.add_element rmnt
		end
		# root.add drive
		internal_items.push drive unless d.usb == true
		external_items.push drive if d.usb == true
	}
}
if internal_items.size > 0
	intsep = REXML::Element.new "separator"
	intsep.add_attribute("label", "Interne Laufwerke (SATA/ATA/SCSI)")
	root.add_element intsep
	internal_items.each{ |i| root.add i }
end
if external_items.size > 0
	extsep = REXML::Element.new "separator"
	extsep.add_attribute("label", "Externe Laufwerke (USB)")
	root.add_element extsep
	external_items.each{ |i| root.add i }
end

doc.add root
doc.write($stdout, 4)