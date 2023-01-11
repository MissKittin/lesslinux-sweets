#!/usr/bin/ruby
# encoding: utf-8

require 'time'
require 'net/http'
require 'uri'
require "rexml/document"
require "resolv"

class LicenseScreen

	def initialize(layers, fixed, topbuttons)
		@layers = layers
		@fixed = fixed
		@top_buttons = topbuttons
		@lang = ENV['LANGUAGE'][0..1]
		@lang = ENV['LANG'][0..1] if @lang.nil?
		@lang = "en" if @lang.nil?
		@tl = MfsTranslator.new(@lang, "LicenseScreen.xml") 
		create_first_layer 
	end
	
	def question_dialog(title, text, default=false)
		dialog = Gtk::Dialog.new(
			title,
			$mainwindow,
			Gtk::Dialog::MODAL,
			[ Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES ],
			[ Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO ]
		)
		if default == true
			dialog.default_response = Gtk::Dialog::RESPONSE_YES
		else
			dialog.default_response = Gtk::Dialog::RESPONSE_NO
		end
		dialog.has_separator = false
		label = Gtk::Label.new
		label.set_markup(text)
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image)
		hbox.pack_start_defaults(label)
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run { |resp|
			case resp
			when Gtk::Dialog::RESPONSE_YES
				dialog.destroy
				return true
			else
				dialog.destroy
				return false
			end
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
	
	def create_first_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::NO) 
		ok = Gtk::Button.new(Gtk::Stock::YES)
		fx.put(bgimg, 0, 0)
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("license_start"))
		fx.put(infolabel, 250, 100)
		# Text area
		txarea = Gtk::TextView.new
		txarea.wrap_mode = Gtk::TextTag::WRAP_WORD
		eula = "Ooops, no EULA found!"  
		disctext = eula 
		if File.exist?("/etc/lesslinux/secuperts/eula.en.txt")
			disctext = File.new("/etc/lesslinux/secuperts/eula.en.txt").read
		end
		if File.exist?("eula.#{@lang}.txt")
			disctext = File.new("eula.#{@lang}.txt").read
		end
		if File.exist?("/etc/lesslinux/secuperts/eula.#{@lang}.txt")
			disctext = File.new("/etc/lesslinux/secuperts/eula.#{@lang}.txt").read
		end
		txarea.buffer.text = disctext 
		txarea.width_request = 728
		txarea.height_request = 295
		scrolled_win = Gtk::ScrolledWindow.new
		scrolled_win.border_width = 3
		scrolled_win.add(txarea)
		scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
		fx.put(scrolled_win, 247, 220)
		# Input field for license key
		liclabel = Gtk::Label.new(@tl.get_translation("license_key")) 
		liclabel.height_request = 32
		# fx.put(liclabel, 250, 468)
		licinput = Gtk::Entry.new
		licinput.text = read_license
		licinput.height_request = 32
		licinput.width_request = 534
		# fx.put(licinput, 458, 468)
		# Text to ask if accepted or not
		acclabel = Gtk::Label.new
		acclabel.wrap = true 
		acclabel.width_request = 730
		acclabel.set_markup(@tl.get_translation("do_you_accept")) 
		# fx.put(acclabel, 250, 468)
		[ ok, cancel ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		cancel.signal_connect("clicked") { 
			system("shutdown-wrapper.sh") 
		}
		ok.signal_connect("clicked") { 
			if ( licinput.text.strip.size > 0 && LicenseScreen.offline_check(licinput.text.strip) == true ) || licinput.text.strip.size < 1
				LicenseScreen.online_check(licinput.text.strip) if LicenseScreen.offline_check(licinput.text.strip) == true 
				@layers.each { |k,v| v.hide_all }
				FileUtils.touch("/var/run/lesslinux/license_accepted") 
				FileUtils.mkdir_p("/etc/lesslinux/secuperts")
				unless licinput.text.strip == ""
					# FIXME: quick check first
					lichandle = File.new("/etc/lesslinux/secuperts/license.txt", "w")
					lichandle.write(licinput.text.strip + "\n")
					lichandle.close
				end
				@layers["start"].show_all 
				@top_buttons.each { |v| v.show_all }
			elsif LicenseScreen.offline_check(licinput.text.strip) == false
				error_dialog( @tl.get_translation('invalid_key_title'), @tl.get_translation('invalid_key_text') )
			end
		}
		fx.put(ok, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		@fixed.put(fx, 0, 0)
		@layers["license"] = fx
	end
	
	def read_license
		licfile = "/etc/lesslinux/secuperts/license.txt"
		lictext = ""
		if File.exists? licfile
			lictext = File.new(licfile).read.strip
		end
		return lictext
	end
	
	def LicenseScreen.offline_check(key=nil)
		return true
	end
	
	def LicenseScreen.online_check(key=nil)
		return true
	end
	
	def LicenseScreen.get_features(doc=nil)
		features = Array.new
		return features 
	end
	
	def LicenseScreen.usb_serial
		scsidev = -1
		hwid = nil
		boot_device = File.new("/var/run/lesslinux/install_source").read.strip 
		if boot_device =~ /^\/dev\/(sd[a-z])[0-9]/
			parent = $1
			if File.directory?("/sys/block/#{parent}/device/scsi_device")
				Dir.entries("/sys/block/#{parent}/device/scsi_device").each { |f|
					scsidev = f.split(":")[0].to_i if  f.split(":")[0].to_i > 0
				}
			end
			if File.exists?("/proc/scsi/usb-storage/#{scsidev}")
				File.open("/proc/scsi/usb-storage/#{scsidev}").each { |l|
					if l.strip =~ /^serial number/i 
						hwid = l.split(": ")[1].strip.gsub("-", "")
					end
				}
			end
		end
		return hwid
	end
	
	def LicenseScreen.bios_serial
		uuid = nil
		IO.popen("dmidecode") { |l|
			while l.gets
				ltoks = $_.strip.split(":")
				uuid = ltoks[1].strip.gsub("-", "") if ltoks[0] =~ /uuid/i
			end
		}
		return uuid 
	end
	
end

