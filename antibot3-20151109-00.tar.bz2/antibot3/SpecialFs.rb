#!/usr/bin/ruby
# encoding: utf-8

class SpecialFs
	
	def initialize(toks)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		tlfile = "AntibotAviraScanner.xml"
		tlfile = "/usr/share/lesslinux/antibot3/AntibotAviraScanner.xml" if File.exists?("/usr/share/lesslinux/antibot3/AntibotAviraScanner.xml")
		@tl = MfsTranslator.new(lang, tlfile)
		@dev = toks[0].gsub('\040', ' ').gsub('\134', '\\')
		@mntpoint = toks[1].gsub('\040', ' ').gsub('\134', '\\')
		@fs = toks[2]
		@opts = toks[3].split(",")
		@fct = nil
	end
	
	attr_reader :dev, :mntpoint, :fs, :opts 
	
	def rw? 
		return true if @opts.include?("rw")
	end
	
	def filecount(pgbar=nil)
		return @fct unless @fct.nil?
		count_files(pgbar)
		return @fct
	end
	
	def device
		return @dev 
	end
	
	def uuid
		return @dev.gsub("/", "_") 
	end
	
	def mount_point
		return [ @mntpoint, @opts  ]
	end
	
	def count_files(pgbar=nil)
		dir = @mntpoint
		file_counter = 0 
		pgbar.activity_mode = true unless pgbar.nil?
		last_pulse = Time.now.to_f
		IO.popen("find '" + dir + "' -xdev -type f ") { |f|
			while f.gets
				file_counter += 1
				unless pgbar.nil?
					now = Time.now.to_f
					if now - last_pulse > 0.1
						last_pulse = now
						pgbar.text = @tl.get_translation("analyze").gsub("DEVICE",  @dev).gsub("FILECOUNT", file_counter.to_s)
						# $stderr.puts "Dateien auf " + @device + ": " + file_counter.to_s 
						pgbar.pulse
						while Gtk.events_pending?
							Gtk.main_iteration
						end
					end
				end
			end
		}
		file_counter = nil if $?.nil?
		pgbar.activity_mode = false unless pgbar.nil?
		pgbar.fraction = 1.0 unless pgbar.nil?
		@fct = file_counter 
	end
	
end