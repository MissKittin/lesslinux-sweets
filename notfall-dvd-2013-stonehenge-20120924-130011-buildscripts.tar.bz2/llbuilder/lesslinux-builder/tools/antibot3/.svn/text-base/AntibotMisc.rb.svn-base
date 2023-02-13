#!/usr/bin/ruby
# encoding: utf-8

class AntibotMisc
	
	def AntibotMisc.machine_id
		manufacturer = ` dmidecode -s system-manufacturer `
		type = ` dmidecode -s system-product-name `
		version = ` dmidecode -s system-version `
		uuid = ` dmidecode -s system-uuid `
		mid = manufacturer.strip
		mid = mid + " " + type.strip unless type =~ /^none/i
		mid = mid + " " + version.strip unless version =~ /^none/i 
		mid = mid + " " + uuid.strip.downcase
		return mid 
	end

	def AntibotMisc.boot_options
		retval = Hash.new
		retval["debug"] = false
		retval["internal"] = false
		bootline = ` cat /proc/cmdline `.strip.split
		bootline.each { |t|
			if t =~ /^antibot=/
				btoks = t.split('|')
				btoks.each { |b|
					retval["debug"] = true if b.strip == "debug"
					retval["internal"] = true if b.strip == "internal"
				}
			end
		}
		return retval 
	end

	def AntibotMisc.cancel_dialog(assi)
		dialog = Gtk::Dialog.new("Programm beenden und neu starten?",
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES ],
			     [ Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO ]
			     )
		quest = Gtk::Label.new("Wollen Sie den Computer jetzt neu starten?")
		quest.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image);
		hbox.pack_start_defaults(quest);
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run { |resp|
			 if resp == Gtk::Dialog::RESPONSE_YES
				system("touch /var/run/lesslinux/reboot_requested")
				assi.destroy
			end
			dialog.destroy
		}
	end
	
	def AntibotMisc.info_dialog(text, title=nil)
		title = "Info" if title.nil?
		dialog = Gtk::Dialog.new(title,
                             $main_application_window,
                             Gtk::Dialog::MODAL,
                             [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NO ]
			     )
		quest = Gtk::Label.new(text)
		quest.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image);
		hbox.pack_start_defaults(quest);
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run { |resp| dialog.destroy }
	end

end