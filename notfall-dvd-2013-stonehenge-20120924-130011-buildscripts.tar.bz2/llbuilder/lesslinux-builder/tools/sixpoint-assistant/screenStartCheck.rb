#!/usr/bin/ruby
# encoding: utf-8

def get_start_screen(fwdbutton, simulate)
	min_mem = 768_000
	### min_mem = 2_000_000
	showthis = false
	allowskip = true
	batterywarn = false
	memorylimit = false
	icon_theme = Gtk::IconTheme.default
	begin
		batt_icon = icon_theme.load_icon("xfpm-primary-020-charging", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
	rescue
		batt_icon = icon_theme.load_icon("ac-adapter", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
	end
	mem_icon =  icon_theme.load_icon("gnome-dev-media-sdmmc", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
	if File.exist?("/proc/acpi/battery/BAT1") 
		IO.popen("cat /proc/acpi/battery/BAT1/state") { |l|
			while l.gets
				line = $_.strip
				if line =~ /^charging state/ 
					ltoks = line.split
					batterywarn = true if ltoks[2] == "discharging" 
				end
			end
		}
	end
	batterywarn = true if simulate.include?("discharging")
	memorylimit = true if virtual_memory < min_mem
	memorylimit = true if simulate.include?("mem768")
	vbox = Gtk::VBox.new(true, 0)
	# vbox.width_request = 440
	batt_box = Gtk::HBox.new(false, 10)
	# batt_box.width_request = 440
	batt_label = Gtk::Label.new(extract_lang_string("discharging"))
	batt_label.wrap = true
	batt_label.width_request = 500
	batt_box.pack_start(Gtk::Image.new(batt_icon), false, false, 0)
	batt_box.pack_start(batt_label, true, true, 0)
	
	mem_box = Gtk::HBox.new(false, 10)
	# mem_box.width_request = 440
	mem_label = Gtk::Label.new
	if memorylimit
		mem_label = Gtk::Label.new(extract_lang_string("low_memory")) 
		fwdbutton.sensitive = false
		allowskip = false
	end
	mem_label.wrap = true
	mem_label.width_request = 500
	mem_box.pack_start(Gtk::Image.new(mem_icon), false, false, 12)
	mem_rbox = Gtk::VBox.new(false, 0)
	drop_box = Gtk::HBox.new(false, 3)
	combobox = Gtk::ComboBox.new
	combobut = Gtk::Button.new(extract_lang_string("reread"))
	drop_box.pack_start(combobox, true, true, 0)
	drop_box.pack_start(combobut, false, true, 0)
	mem_rbox.pack_start(mem_label, false, true, 0)
	mem_rbox.pack_start(drop_box, false, true, 0)
	mem_box.pack_start(mem_rbox, true, true, 0)
	vbox.pack_start(batt_box, true, true, 0) if batterywarn == true
	vbox.pack_start(mem_box, true, true, 0) if memorylimit == true
	showthis = true if ( memorylimit == true || batterywarn == true )
	### showthis = true
	return vbox, showthis, allowskip, combobox, combobut
	
end

def virtual_memory
	vmem = 0
	IO.popen("cat /proc/meminfo") { |l|
		while l.gets
			line = $_.strip
			if line =~ /^MemTotal/
				ltoks = line.split
				vmem = ltoks[1].to_i
			end
		end
	}
	IO.popen("cat /proc/swaps") { |l|
		while l.gets
			ltoks = $_.strip.split
			vmem += ltoks[2].to_i
		end
	}
	return vmem
end



