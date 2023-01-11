#!/usr/bin/ruby
# encoding: utf-8

class CheckScreen
	def initialize(extlayers, simulate=Array.new)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		@tl = MfsTranslator.new(lang, "CheckScreen.xml")
		@layers = Array.new
		@fixed = Gtk::Fixed.new
		@show = false
		@simulate = simulate
		@tilesshown = 0 
		
		text4 = Gtk::Label.new
		text4.width_request = 250
		text4.wrap = true
		text4.set_markup("<span color='white'>" + @tl.get_translation("shutdown") + "</span>")
		back = Gtk::EventBox.new.add Gtk::Image.new("cancel.png")
		text5 = Gtk::Label.new
		text5.width_request = 250
		text5.wrap = true
		text5.set_markup("<span color='white'>" + @tl.get_translation("anyway") + "</span>")
		forw  = Gtk::EventBox.new.add Gtk::Image.new("forward.png")
		@fixed.put(forw, 650, 352)
		@fixed.put(text5, 402, 358)
		@fixed.put(back, 650, 402)
		@fixed.put(text4, 402, 408)
		
		forw.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				
				extlayers.each { |k,v|v.hide_all }
				TileHelpers.back_to_group
			end
		}
		back.signal_connect('button-release-event') { |x, y|
			if y.button == 1 
				system("/usr/bin/shutdown-wrapper.sh") 
			end
		}
		
		check_memory 
		check_hiberfil_imsm
		
		extlayers["checkscreen"] = @fixed
		@layers[0] = @fixed
		@show = true if @tilesshown > 0 
	end
	
	attr_reader :layers, :show
	
	def check_memory
		badmem = false
		IO.popen("dmesg") { |l|
			while l.gets
				badmem = true if $_ =~ / bad mem addr /
			end
		}
		badmem = true if @simulate.include?("badmem")
		return false if badmem == false
		
		icon_memory = Gtk::EventBox.new.add  Gtk::Image.new("memorycorrupt.png")
		text_memory = TileHelpers.create_label("<b>" + @tl.get_translation("badmemhead") + "</b>\n\n" +@tl.get_translation("badmembody") , 450)
		icon_memory.signal_connect("button-release-event") { |x,y| }
		
		# @fixed.put(icon_memory, 0, @tilesshown * 130)
		@fixed.put(text_memory, 0, @tilesshown * 130)
		@tilesshown += 1 
		
	end
	
	def check_hiberfil_imsm
		imsm = false
		hibernated = false
		auxdrives = Array.new
		Dir.entries("/sys/block").each { |l|
			auxdrives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ 
		}
		auxdrives.each { |d|
			imsm = true if d.imsm? == true 
			hibernated = true if d.hibernated? == true
		}
		imsm = true if @simulate.include?("imsm")
		hibernated = true if @simulate.include?("hiberfil")  
		
		icon_imsm =  Gtk::EventBox.new.add  Gtk::Image.new("imsmactive.png")
		text_imsm = TileHelpers.create_label("<b>" + @tl.get_translation("imsmhead") + "</b>\n\n" + @tl.get_translation("imsmbody"), 450)
		
		icon_hiberfil = Gtk::EventBox.new.add  Gtk::Image.new("hyperboot.png")
		text_hiberfil = TileHelpers.create_label("<b>" + @tl.get_translation("hiberhead") + "</b>\n\n" +@tl.get_translation("hiberbody")  , 450)
		#icon_hiberfil.signal_connect("button-release-event") { |x,y| 
		#	# remove_hiberfil(auxdrives) 
		#}
		if hibernated == true 
			# @fixed.put(icon_hiberfil, 0, @tilesshown * 130)
			@fixed.put(text_hiberfil, 0, @tilesshown * 130)
			@tilesshown += 1 
		end
	
		if imsm == true
			# @fixed.put(icon_imsm, 0, @tilesshown * 130)
			@fixed.put(text_imsm, 0, @tilesshown * 130)
			@tilesshown += 1 
		end
		
	end

	def remove_hiberfil(drives)
		continue = TileHelpers.yes_no_dialog(@tl.get_translation("hiberdiabody"), @tl.get_translation("hiberdiahead"))
		return false unless continue == true
		drives.each { |d|
			d.partitions.each { |p|
				if p.fs =~ /ntfs/
					p.remove_hiberfil 
				end
			}
		}
		
	end

	
end