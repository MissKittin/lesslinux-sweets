#!/usr/bin/ruby
# encoding: utf-8

require "resolv"

class NetworkScreen	
	def initialize(extlayers)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "NetworkScreen.xml")
		@layers = Array.new
		@nextscreen = "start"
		@networkcombo = Gtk::ComboBox.new
		@pwentry = Gtk::Entry.new
		### Some global variables for networks
		@networks = Array.new
		@radiowlan = nil
		@radioether = nil
		@radionone = nil
		
		nwscreen = create_connect_layer(extlayers)
		@layers[0] = nwscreen
		extlayers["networks"] = nwscreen
	end
	attr_reader :layers
	attr_accessor :nextscreen
	
	def create_connect_layer(extlayers)
		fixed = Gtk::Fixed.new
		tile = Gtk::EventBox.new.add Gtk::Image.new("network.png")
		nwlabel = TileHelpers.create_label("<b>" + @tl.get_translation("nethead") + "</b>\n\n" + @tl.get_translation("netbody"), 510)
		labelwlan = TileHelpers.create_label(@tl.get_translation("radiowlan"), 250)
		labelether = TileHelpers.create_label(@tl.get_translation("radioether"), 500)
		labelnone = TileHelpers.create_label(@tl.get_translation("radionone"), 500)
		namelab = TileHelpers.create_label(@tl.get_translation("inputssid"), 100)
		passlab = TileHelpers.create_label(@tl.get_translation("inputkey"), 100)
		continue = TileHelpers.create_label(@tl.get_translation("goconnect"), 220)
		@pwentry.visibility = false
		@networkcombo.width_request = 330
		@networkcombo.height_request = 32
		@pwentry.width_request = 435
		reread = Gtk::Button.new(@tl.get_translation("reread"))
		reread.height_request = 32
		reread.width_request = 100
		reread.signal_connect("clicked") { fill_wlan_combo } 
		@radiowlan = Gtk::RadioButton.new()
		@radioether = Gtk::RadioButton.new(@radiowlan)
		@radionone = Gtk::RadioButton.new(@radiowlan)
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		# fixed.put(tile, 0, 0)
		fixed.put(nwlabel, 0, 0)
		fixed.put(@radiowlan, 0, 60)
		fixed.put(labelwlan, 30, 65)
		fixed.put(namelab, 30, 93)
		fixed.put(passlab, 30, 130)
		fixed.put(@networkcombo, 135, 88)
		fixed.put(reread, 470, 88)
		fixed.put(@pwentry, 135, 125)
		fixed.put(@radioether, 0, 160)
		fixed.put(labelether, 30, 165)
		fixed.put(@radionone, 0, 190)
		fixed.put(labelnone, 30, 195)
		fixed.put(forw, 650, 352)
		fixed.put(continue, 402, 358)
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				if @radiowlan.active? 
					puts "Connect to WLAN..."
					connect_to_wlan
				elsif @radioether.active?
					puts "Connect to ethernet..."
					connect_to_ethernet
				end
				if test_connection || @radionone.active?
					system("/etc/lesslinux/updater/update_wrapper.sh --quiet") if test_connection 
					extlayers.each { |k,v| v.hide_all }
					extlayers[@nextscreen].show_all
				elsif
					TileHelpers.error_dialog(@tl.get_translation("failedbody"), @tl.get_translation("failedhead"))
				end
			end
		}
		tile.signal_connect('button-release-event') { |x,y|
			if y.button == 1 
				system("wicd-gtk -n &") 
			end
		}
		return fixed
	end
	
	def connect_to_wlan
		return 1 if @networks.size < 1
		essid = @networks[@networkcombo.active].split("wifi_")[0].strip  
		netid = "wifi_" + @networks[@networkcombo.active].split("wifi_")[1] 
		system("connmanctl scan wifi")
		key = @pwentry.text 
		
		# buttons.each { |b| b.sensitive = false }
		dwin = Gtk::Window.new
		dwin.set_default_size(400, 40)
		pgbar = Gtk::ProgressBar.new
		pgbar.width_request = 300
		dwin.add(pgbar)
		dwin.deletable = false
		dwin.show_all
		ccount = 0
		connect_vte = Vte::Terminal.new
		#netnum = -1
		#system("wicd-cli --wireless -S")
		#IO.popen("wicd-cli --wireless -l") { |l|
		#	while l.gets 
		#		ltoks = $_.strip.split
		#		netnum = ltoks[0].to_i if ltoks[3] == essid
		#	end
		#}
		#if key == ""
		#	system("wicd-cli --wireless -n " + netnum.to_s + " -p encryption -s False")
		#else
		#	system("wicd-cli --wireless -n " + netnum.to_s + " -p encryption -s True")
		#	system("wicd-cli --wireless -n " + netnum.to_s + " -p enctype -s wpa")
		#	system("wicd-cli --wireless -n " + netnum.to_s + " -p encryption_method -s wpa")
		#	system("wicd-cli --wireless -n " + netnum.to_s + " -p key -s " + key)
		#end
		if key == ""
			system("connmanctl connect #{netid}")
		else
			connect_vte.fork_command("connmanctl")
			sleep(0.2)
			connect_vte.feed_child("agent on\n")
			sleep(0.2)
			connect_vte.feed_child("connect #{netid}\n")
			sleep(0.2)
			connect_vte.feed_child(key + "\n")
			sleep(0.2)
			connect_vte.feed_child("quit\n")
		end
		connect_success = false
		while ccount < 50 
			pgbar.pulse
			# pgbar.text = "Verbinde mit WLAN #{essid}"
			pgbar.text = @tl.get_translation("connectingwifi").gsub("ESSID", essid) 
			sleep 0.1
			ccount += 1
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		dwin.destroy
		connect_vte.destroy 
		# buttons.each { |b| b.sensitive = true }
	end
	
	def connect_to_ethernet
		dwin = Gtk::Window.new
		dwin.set_default_size(400, 40)
		pgbar = Gtk::ProgressBar.new
		pgbar.width_request = 300
		dwin.add(pgbar)
		dwin.deletable = false
		dwin.show_all
		ccount = 0
		connect_success = false
		system("connmanctl connect ethernet")
		# system("dhcpcd &") 
		while connect_success == false && ccount < 600 
			pgbar.pulse
			pgbar.text = @tl.get_translation("connectingether")
			sleep 0.1
			ccount += 1
			connect_success = test_connection if ccount % 100 == 5 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			
		end
		dwin.destroy
	end
	
	def test_connection
		# Check the network by "digging" for www.computerbild.de
		# if this works, routing and name resolution should work
		connected = false
		address = nil 
		r = Resolv::DNS.new
		r.timeouts = [ 1, 1, 1, 1 ]
		begin
			address = r.getaddress("www.computerbild.de")
			connected = true if address.to_s.size > 0
		rescue
			connected = false
		end
		return connected 
	end
	
	def test_link
		return true if test_connection == true 
		link = false
		IO.popen("ip link") { |l| 
			while l.gets
				ltoks = $_.split
				if ltoks[1] =~ /eth/ 
					link = true unless ltoks[2] =~ /NO-CARRIER/
				end
			end
		} 
		return link 
	end
	
	def fill_wlan_combo
		100.downto(0) { |n|
			begin
				@networkcombo.remove_text(n)
			rescue
			end
		}
		@networks = Array.new
		get_networks.each { |k,v|
			v.each { |n| @networks.push(n) }
		}
		@networks.uniq.each { |n|
			@networkcombo.append_text n
		}
		@networkcombo.active = 0 unless @networks.size < 1 
	end
	
	def get_networks 
		# First find interfaces:
		interfaces = Array.new
		networks = Hash.new
		IO.popen("/usr/sbin/iwconfig 2>&1") { |l|
			while l.gets
				line = $_.strip
				if line =~ /ESSID/
					interfaces.push(line.split[0])
				end
			end
		}
		interfaces.each { |i|
			networks[i] = Array.new
			system("connmanctl enable wifi")
			system("connmanctl scan wifi")
			IO.popen("connmanctl services") { |l|
				while l.gets
					line = $_.strip
					netname = line
					networks[i].push(netname) if netname.size > 0 
				end
			}
		#	IO.popen("/usr/sbin/iwlist " + i + " scan") { |l|
		#		while l.gets
		#			line = $_.strip
		#			if line =~ /^ESSID\:\"(.*?)\"/
		#				netname = $1.strip
		#				networks[i].push(netname) if netname.size > 0 
		#			end
		#		end
		#	}
		}
		return networks
		
		
		
	end
	
	def get_addresses
		addresses = Array.new
		IO.popen("ip -f inet address") { |l|
			while l.gets
				line = $_.strip
				if line =~ /^inet/
					ltoks = line.split 
					addtoks = ltoks[1].split("/")
					addresses.push(addtoks[0]) unless addtoks[0] =~ /^127.0/ 
				end
			end
		}
		return addresses 
	end
	
end