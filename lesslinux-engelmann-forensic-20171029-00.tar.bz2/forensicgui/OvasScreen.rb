#!/usr/bin/ruby
# encoding: utf-8

require 'vte'

class OvasScreen
	
	def initialize(layers, fixed)
		@layers = layers
		@fixed = fixed
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "OvasScreen.xml") 
		@start_label = @tl.get_translation("start_label") 
		@install_vte = nil 
		@updating = false
		create_first_layer 
		# create_scan_layer
	end
	attr_reader :start_label

	def create_first_layer
		bgimg = Gtk::Image.new("background.png")
		fx = Gtk::Fixed.new
		cancel = Gtk::Button.new(Gtk::Stock::CANCEL) 
		ok = Gtk::Button.new(Gtk::Stock::APPLY)
		fx.put(bgimg, 0, 0)
		
		# Label
		infolabel = Gtk::Label.new
		infolabel.wrap = true
		infolabel.width_request = 730
		infolabel.set_markup(@tl.get_translation("ovas_start")) 
		fx.put(infolabel, 250, 100)
		
		@install_vte = Vte::Terminal.new
		@install_vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
		@install_vte.height_request = 260
		@install_vte.width_request = 740
		
		fx.put(@install_vte, 250, 260)
		
		# Target
		#target_label = Gtk::Label.new(@tl.get_translation("target") )
		#@target_combo = Gtk::ComboBox.new
		#@target_combo.width_request = 526
		#@target_combo.height_request = 32
		#fx.put(@target_combo, 250, 260)
		#fx.put(reread, 780, 260)
		#fx.put(target_label, 250, 228)
		
		[ ok, cancel ].each { |w|
			w.width_request = 128
			w.height_request = 32 
		}
		cancel.signal_connect("clicked") { 
			#unless kill_recovery
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
			#end
		}
		ok.signal_connect("clicked") { 
			ok.sensitive = false
			cancel.sensitive = false
			@updating = true
			@install_vte.signal_connect("child_exited") { @updating = false }
			@install_vte.fork_command("bash", ["bash", "/usr/bin/openvas-headless.sh"] )
			while @updating == true
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				sleep 0.2 
			end
			start_redis 
			unless check_daemons
				TileHelpers.error_dialog( @tl.get_translation("error_openvas_daemons"), "Error" )
			else
				system("su surfer -c 'firefox http://127.0.0.1:9392/' &") 
			end
			ok.sensitive = true
			cancel.sensitive = true 
			# And jump back
			@layers.each { |k,v| v.hide_all }
			@layers["start"].show_all 
			#@layers.each { |k,v| v.hide_all }
			#mount_all(@target_devices[@target_combo.active])
			#@layers["vss_locking"].show_all 
		}
		fx.put(ok, OK_X, OK_Y)
		fx.put(cancel, CANCEL_X, CANCEL_Y)
		@fixed.put(fx, 0, 0)
		@layers["ovas_start"] = fx
	end
	
	def prepare_scan
		
	end

	def start_redis
		redis_running = false
		IO.popen("ps waux") { |l|
			while l.gets 
				redis_running = true if $_.strip.split[10] =~ /redis/ 
			end
		}
		system("redis-server /etc/openvas/redis.conf") unless redis_running == true 
	end
	
	def check_environment 
		if system("mountpoint /lesslinux/blobpart") 
			return true
		else
			return TileHelpers.yes_no_dialog( @tl.get_translation("error_openvas_ram"), "Question" ) 
		end
	end
	
	def check_daemons
		openvassd_running = false
		openvasmd_running = false
		gsad_running = false 
		IO.popen("ps waux") { |l|
			while l.gets 
				openvasmd_running = true if $_ =~ /openvasmd/ 
				openvassd_running = true if $_ =~ /openvassd/ 
				gsad_running = true if $_ =~ /gsad/ 
			end
			
		}
		openvassd_running && openvasmd_running && gsad_running 
	end
end
