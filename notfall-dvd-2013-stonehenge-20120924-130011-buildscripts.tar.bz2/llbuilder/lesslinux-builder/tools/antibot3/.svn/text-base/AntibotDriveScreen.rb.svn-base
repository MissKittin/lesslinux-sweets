#!/usr/bin/ruby
# encoding: utf-8

require "MfsDiskDrive.rb"
require "MfsSinglePartition.rb"

class AntibotDriveScreen
	
	def initialize(assi)
		@assistant = assi
		@wdgt = Gtk::ScrolledWindow.new
		@wdgt.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		@vbox = Gtk::VBox.new(false, 6)
		@drives = Array.new
		@int_drives = Array.new
		@ext_drives = Array.new
		@int_buttons = Hash.new
		@ext_buttons = Hash.new
		@saved_states = Hash.new
		@error_messages = Hash.new
		@intlabel = nil
		@extlabel = nil
		@int_vbox = Gtk::VBox.new(false, 3)
		@ext_vbox = Gtk::VBox.new(false, 3)
		longdesc = Gtk::Label.new("Welche Laufwerke wollen Sie untersuchen? Damit die Antibot-CD alle vorhandenen Festplatten und Partitionen auf Schädlinge überprüft, lassen Sie die Vorauswahl einfach unverändert.")
		longdesc.wrap = true
		longdesc.width_request = 550 
		@vbox.pack_start(longdesc , false, false, 10)
		@wdgt.add_with_viewport @vbox
		@wdgt.show_all
		# Do not read yet, this saves some precious seconds
		# Hell yes, read, otherwise we run into an "it is there but not showed issue"
		reread_drivelist 
	end
	
	attr_reader :wdgt, :ext_drives, :int_drives, :saved_states
	attr_accessor :int_buttons, :ext_buttons, :vbox # , :int_vbox, :ext_vbox

	def reread_drivelist
		# @vbox.destroy 
		# @vbox = Gtk::VBox.new(false, 6)
		@drives = Array.new
		Dir.entries("/sys/block").each { |l|
			@drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/ 
		}
		@int_drives = Array.new
		@ext_drives = Array.new
		@int_buttons.each { |k,v|
			v.destroy
			@int_buttons.delete(k)
		}
		@ext_buttons.each { |k,v|
			v.destroy
			@ext_buttons.delete(k)
		}
		@error_messages.each { |k,v|
			v.destroy
			@error_messages.delete(k)
		}
		@intlabel.destroy unless @intlabel.nil?
		@extlabel.destroy unless @extlabel.nil?
		@intlabel = Gtk::Label.new("<b>Interne Laufwerke</b>")
		@intlabel.use_markup = true
		@extlabel = Gtk::Label.new("<b>Externe Laufwerke</b>")
		@extlabel.use_markup = true
		@drives.each { |d|
			if d.usb == true
				@ext_drives.push(d)
			else
				@int_drives.push(d)
			end
		}
		intparts = 0
		@int_drives.each { |d|
			d.partitions.each { |p| intparts += create_button(d, p, true) }
		}
		extparts = 0
		@ext_drives.each { |d|
			d.partitions.each { |p| extparts += create_button(d, p, false) }
		}
		( @int_drives + @ext_drives ).each { |d| res = create_smart_box(d) }
		if intparts > 0 
			@vbox.pack_start(@intlabel, false, false, 0)
			@int_drives.each { |d|
				@vbox.pack_start(@error_messages[d.device], false, false, 0) if @error_messages.has_key?(d.device)
				d.partitions.each { |p|
					if @int_buttons.has_key?(p.uuid)
						puts "Adding button for UUID: " + p.uuid
						@vbox.pack_start(@int_buttons[p.uuid], false, false, 0)
					end
				}
			}
		end
		if extparts > 0 
			@vbox.pack_start(@extlabel, false, false, 0)
			@ext_drives.each { |d|
				@vbox.pack_start(@error_messages[d.device], false, false, 0) if @error_messages.has_key?(d.device)
				d.partitions.each { |p|
					if @ext_buttons.has_key?(p.uuid)
						puts "Adding button for UUID: " + p.uuid
						@vbox.pack_start(@ext_buttons[p.uuid], false, false, 0)
					end
				}
			}
		end
		@vbox.show_all
		dump_marked
		count_marked 
	end

	def dump_marked
		@saved_states.each { |k,v|
			puts "UUID: " + k + " marked for scan " + v.to_s 
		}
	end
	
	def count_marked
		marked = 0
		@saved_states.each { |k,v| marked += 1 if v == true }
		puts "Currently marked: " + marked.to_s
		@assistant.set_page_complete(@wdgt, false) if marked < 1
		@assistant.set_page_complete(@wdgt, true) if marked > 0
		return marked
	end
	
	def create_button(d, p, internal=true)
		if p.fs =~ /ext/ || p.fs =~ /fat/ || p.fs =~ /ntfs/ || p.fs =~ /btrfs/ 
			button_text = d.device + ", Partition " + p.device.to_s + ", " + p.fs.to_s + " " + p.label.to_s + " " + p.human_size
			button_text = d.device + " (" + d.vendor + " " + d.model + "), Partition " + p.device.to_s + ", " + p.fs.to_s + 
				" " + p.label.to_s + " " + p.human_size if internal == false
			s, i, e = d.error_log 
			windows, winvers = p.is_windows if e.size < 1
			button_text = button_text + " - " + winvers if windows == true
			button = Gtk::CheckButton.new
			button.active = true
			if !p.mount_point.nil? && p.mount_point[0] =~ /^\/lesslinux\// 
				button_text = button_text + " (Systemlaufwerk)"
				button.active = false 
				@saved_states[p.uuid] = false
				button.sensitive = false # if p.mount_point[0] =~ /^\/lesslinux\/antibot/ 
			end
			button.label = button_text
			if @saved_states.has_key?(p.uuid) 
				button.active = @saved_states[p.uuid] 
			else
				@saved_states[p.uuid] = button.active?
			end
			button.signal_connect("clicked") {
				if button.active? == false
					puts "Remove " + p.uuid
					@saved_states[p.uuid] = false
				else
					puts "Add " + p.uuid
					@saved_states[p.uuid] = true
				end
				dump_marked
				count_marked 
			}
			puts "Adding button (int) for " + p.uuid.to_s 
			@int_buttons[p.uuid] = button if internal == true
			@ext_buttons[p.uuid] = button if internal == false
			return 1
		end
		return 0
	end

	def create_smart_box(d)
		s, i, e = d.error_log
		return false if s == false
		return false if e.size < 1
		hbox = Gtk::HBox.new(false, 3)
		icon = Gtk::Image.new("icons/warning32.png")
		msg = Gtk::Label.new("<b>Die Festplatte #{d.vendor.to_s} #{d.model.to_s} (#{d.device.to_s}) weist Fehler auf. Bitte prüfen Sie das Laufwerk schnellstmöglich und ersetzen Sie es gegebenenfalls!</b>")
		msg.wrap = true
		msg.use_markup = true
		msg.width_request = 500
		hbox.pack_start(icon, false, false, 2)
		hbox.pack_start(msg, true, true, 2)
		@error_messages[d.device] = hbox
		return true
	end
	
	# We should assume that UUIDs of partitions are really unique. However,
	# sometimes after cloning the UUID of the original and the clone are
	# identical. This could cause some strange behaviour. So tell the user
	# what to do if this happens.
	#
	# Returns
	#
	# true:  if two or more partions have the same UUID
	# false: if UUIDs are truly unique
	
	def check_uuids
		uuids = Array.new
		( @int_drives + @ext_drives ).each { |d|
			d.partitions.each { |p|
				if uuids.include? p.uuid
					AntibotMisc.info_dialog("Achtung: Mehrere Partitionen verwenden die gleiche UUID. Die UUID sollte einmalig sein, kann in Einzelfällen nach dem Klonen jedoch erhalten bleiben. Bitte entfernen Sie nun Laufwerke mit doppelter UUID oder verwenden Sie die bereistehenden Kommandozeilenprogramme, um die UUID zu ändern. Klicken Sie anschließend auf \"OK\".", "Doppelte UUID gefunden")
					return true
				else
					uuids.push p.uuid
				end
			}
		}
		return false
	end
	
	# Create some understandable error message if no internal drives were found.
	# Usually this indicates an unsupported IDE/SATA/SCSI chipset. Give a hint
	# indicating the problem.
	#
	# Returns:
	#
	# true:  the problem exists that no internal drives are found
	# false: no problem
	
	def check_drives
		if @int_drives.size < 1
			AntibotMisc.info_dialog("Achtung: Es wurden keine internen Laufwerke gefunden. Dies deutet auf einen nicht unterstützten IDE-/SATA-/SCSI-Chipsatz hin, was möglicherweise durch eine Systemaktualisierung behoben werden kann. Schließen Sie externe SATA- oder USB-Laufwerke nun an. Klicken Sie anschließend auf \"OK\".", "Keine internen Laufwerke")
			return true
		end
		return false
	end

end