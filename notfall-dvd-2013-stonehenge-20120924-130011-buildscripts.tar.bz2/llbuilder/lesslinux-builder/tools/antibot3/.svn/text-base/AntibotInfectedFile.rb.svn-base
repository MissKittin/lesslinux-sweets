#!/usr/bin/ruby
# encoding: utf-8

class AntibotInfectedFile

	def initialize(path, mountpoint, uuid, infection, scanparams, fileout=nil, logdb=nil, tstamp=0, act=nil, fulllog=[])
		@logdb = logdb
		@tstamp = tstamp
		@uuid = uuid
		@raw_infection = infection
		@fulllog = fulllog
		@relpath = path.gsub(mountpoint, "").strip
		@methods = [ "do_nothing", "desinfect", "remove" ]
		@selected_method = "desinfect"
		@raw_infection =~ /\[(.*?)\]/ 
		@short_infection = $1
		@type = @raw_infection.strip.split[0].gsub(":", "")
		@scanparams = scanparams 
		@fileout = fileout
		@action_taken = nil
		@integrated_action = act
		update_method
		update_action unless act.nil? || act.to_s == ""
		write_dbentry
		puts "Infected - Path:       " + @relpath
		puts "Infected - UUID:       " + @uuid
		puts "Infected - Infection:  " + @type + " - " + @short_infection
	end
	
	attr_reader :raw_infection, :uuid, :relpath, :short_infection, :action_taken, :fulllog

	def update_action
		return false if @integrated_action.nil?
		if @integrated_action == "repaired"
			@action_taken = "desinfect"
		elsif @integrated_action == "moved" || @integrated_action == "deleted"
			@action_taken = "delete"
		elsif  @integrated_action == "renamed"
			@action_taken = "rename"
		end
		puts "Writing action taken to database" 
		@logdb.execute("UPDATE single_infection SET action = ? WHERE fpath = ? AND uuid = ? AND scantime = ? ",
			[ SQLite3::Database.quote(@action_taken),
			SQLite3::Database.quote(@relpath),
			SQLite3::Database.quote(@uuid),
			SQLite3::Database.quote(@tstamp.to_i.to_s) ] ) unless @logdb.nil? || @action_taken.nil? 
	end

	def update_method
		return false if @fileout.nil?
		if @fileout =~ /archive data/i 
			@selected_method = "do_nothing"
		elsif @fileout =~ /CD-ROM filesystem/i
			@selected_method = "do_nothing"
		end
		return true
	end

	def write_dbentry
		return false if @logdb.nil?
		@logdb.execute("INSERT INTO single_infection " + 
			" (scantime, uuid, fpath, infection, fileout) " + 
			" VALUES ( ?,   ?,     ?,         ?,       ?) " ,
			[ SQLite3::Database.quote(@tstamp.to_i.to_s),
			SQLite3::Database.quote(@uuid),
			SQLite3::Database.quote(@relpath),
			SQLite3::Database.quote(@short_infection),
			SQLite3::Database.quote(@fileout.to_s) ] )
	end

	# requires Gtk::

	def create_list_entry
		flabel = Gtk::Label.new(@relpath)
		falign = Gtk::Alignment.new(0.0, 0.0, 0.0, 0.0)
		falign.add flabel
		ilabel = Gtk::Button.new(@short_infection)
		ilabel.relief = Gtk::RELIEF_NONE
		ialign = Gtk::Alignment.new(0.0, 0.0, 0.0, 0.0)
		ialign.add ilabel
		# do nothing
		nchk = Gtk::RadioButton.new("")
		nchk.tooltip_text = "Nichts tun"
		# desinfect
		dchk = Gtk::RadioButton.new(nchk, "")
		dchk.tooltip_text = "Desinfizieren" 
		# remove
		rchk = Gtk::RadioButton.new(nchk, "")
		rchk.tooltip_text = "Löschen"
		ilabel.tooltip_text = "In der Avira-Virendatenbank nachschlagen"
		ilabel.signal_connect("clicked") {
			system("su surfer firefox http://www.avira.com/de/support-virus-lab?sq=" + @short_infection + " & ")
		}
		nchk.active = true if @selected_method == "do_nothing"
		dchk.active = true if @selected_method == "desinfect"
		rchk.active = true if @selected_method == "remove"
		dchk.signal_connect("clicked") { 
			@selected_method = "desinfect" if dchk.active? == true
		}
		nchk.signal_connect("clicked") { 
			@selected_method = "do_nothing" if nchk.active? == true
		}
		rchk.signal_connect("clicked") { 
			@selected_method = "remove" if rchk.active? == true
		}
		return [ falign, ialign, nchk, dchk, rchk ] 
	end
	
	def create_backup(mounted, delete_when_failed, truncate, backup, localbackup, pgbar=nil)
		if @selected_method == "do_nothing"
			puts "Ignoring: " + @uuid + " - " + @relpath 
			return true
		end
		if (delete_when_failed == true || @selected_method == "remove") && backup == true
			return copy_encrypted(mounted, pgbar)
		end
		return true
	end
	
	def desinfect(mounted, delete_when_failed, truncate, backup, localbackup, pgbar=nil)
		if @selected_method == "do_nothing"
			@logdb.execute("UPDATE single_infection SET action = ? WHERE fpath = ? AND uuid = ? AND scantime = ? ",
				[ SQLite3::Database.quote("do_nothing"),
				SQLite3::Database.quote(@relpath),
				SQLite3::Database.quote(@uuid),
				SQLite3::Database.quote(@tstamp.to_i.to_s) ] ) unless @logdb.nil?
			puts "Ignoring: " + @uuid + " - " + @relpath 
			return true
		end
		if @selected_method == "remove"
			return truncate(mounted) if truncate == true
			return remove(mounted)
		end
		# Get the SHA1SUM of the file - from this we can easily determine if desinfection succeeded
		pre_sha = ` sha1sum '#{mounted}/#{@relpath}' `.strip.split[0] 
		puts "SHA1SUM before desinfection: " + pre_sha
		scanparams = Array.new
		@scanparams.each { |x|
			if x =~ /^'--defaultaction/ 
				scanparams.push "'--defaultaction=clean,ignore'"
			elsif x =~ /^\// || x =~ /^'\//
				scanparams.push "'" + mounted + "/" + @relpath + "'"
			else
				scanparams.push x
			end
		}
		scanparams.push("'" + mounted + "/" + @relpath + "'") unless scanparams[-1] =~ /^'\// 
		puts "Scan parameters: " + scanparams.join(" ")
		# Now run Avira to desinfect
		run_avira(scanparams, pgbar)
		post_sha = ` sha1sum '#{mounted}/#{@relpath}' `.strip.split[0] 
		puts "SHA1SUM after desinfection: " + post_sha
		@logdb.execute("UPDATE single_infection SET sha1pre = ?, sha1post = ? WHERE fpath = ? AND uuid = ? AND scantime = ? ",
				[ SQLite3::Database.quote(pre_sha),
				SQLite3::Database.quote(post_sha),
				SQLite3::Database.quote(@relpath),
				SQLite3::Database.quote(@uuid),
				SQLite3::Database.quote(@tstamp.to_s) ] ) unless @logdb.nil?
		if post_sha.strip == pre_sha.strip && delete_when_failed == true
			return truncate(mounted) if truncate == true
			return remove(mounted)
		elsif post_sha.strip == pre_sha.strip
			@logdb.execute("UPDATE single_infection SET action = ? WHERE fpath = ? AND uuid = ? AND scantime = ? ",
				[ SQLite3::Database.quote("do_nothing"),
				SQLite3::Database.quote(@relpath),
				SQLite3::Database.quote(@uuid),
				SQLite3::Database.quote(@tstamp.to_i.to_s) ] ) unless @logdb.nil?
			@action_taken = "do_nothing"
		else
			@logdb.execute("UPDATE single_infection SET action = ? WHERE fpath = ? AND uuid = ? AND scantime = ? ",
				[ SQLite3::Database.quote("desinfect"),
				SQLite3::Database.quote(@relpath),
				SQLite3::Database.quote(@uuid),
				SQLite3::Database.quote(@tstamp.to_i.to_s) ] ) unless @logdb.nil?
			@action_taken = "desinfect"
		end
		return true
	end
	
	def run_avira(scanparams, pgbar=nil)
		tn = Time.now.to_f.to_s
		scancl = "LANGUAGE=en_GB:en LC_ALL=en_GB.UTF-8 ruby scancl_wrapper.rb /var/run/scancl.#{tn}.ret /AntiVir/scancl " + scanparams.join(" ")
		puts "Running command: " + scancl
		scanout = Array.new
		last_pulse = Time.now.to_f
		IO.popen(scancl) { |l|
			while l.gets
				now = Time.now.to_f
				unless pgbar.nil? || now - last_pulse < 0.1 
					last_pulse = now
					pgbar.text = "Desinfiziere Datei " + @relpath 
					pgbar.pulse
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
				end
				line = $_
				scanout.push(line) unless line.strip =~ /^-TickTock-$/ 
			end
		}
		retval = File.read("/var/run/scancl.#{tn}.ret").strip.to_i 
		@logdb.execute("UPDATE single_infection SET scancl = ? , action = ?, retvalue = ?, scanout = ? WHERE fpath = ? AND uuid = ? AND scantime = ? ",
			[ SQLite3::Database.quote(scancl),
			SQLite3::Database.quote("desinfect"),
			SQLite3::Database.quote(retval.to_i.to_s), 
			SQLite3::Database.quote(scanout.join), 
			SQLite3::Database.quote(@relpath),
			SQLite3::Database.quote(@uuid),
			SQLite3::Database.quote(@tstamp.to_i.to_s) ] ) unless @logdb.nil?
		@action_taken = "desinfect"
	end
	
	def remove(mounted)
		puts "Running: rm '#{mounted}/#{@relpath}' " 
		# return false unless File.exist?(mounted + "/" + @relpath + ".antibot3")
		if system("rm '#{mounted}/#{@relpath}' ")
			@logdb.execute("UPDATE single_infection SET action = ? WHERE fpath = ? AND uuid = ? AND scantime = ? ",
				[ SQLite3::Database.quote("remove"),
				SQLite3::Database.quote(@relpath),
				SQLite3::Database.quote(@uuid),
				SQLite3::Database.quote(@tstamp.to_i.to_s) ] ) unless @logdb.nil?
			@action_taken = "remove"
			return true
		end
		return false
	end
	
	def truncate(mounted)
		puts "Running: echo -n '' > '#{mounted}/#{@relpath}' " 
		# return false unless File.exist?(mounted + "/" + @relpath + ".antibot3")
		if system("echo -n '' > '#{mounted}/#{@relpath}' ")
			@logdb.execute("UPDATE single_infection SET action = ? WHERE fpath = ? AND uuid = ? AND scantime = ? ",
				[ SQLite3::Database.quote("truncate"),
				SQLite3::Database.quote(@relpath),
				SQLite3::Database.quote(@uuid),
				SQLite3::Database.quote(@tstamp.to_i.to_s) ] ) unless @logdb.nil?
			@action_taken = "truncate"
			return true
		end
		return false
	end
		
	def copy_encrypted(mounted, pgbar=nil)
		puts "Running: openssl enc -aes-128-cbc -k AntiBot3.0 -in '#{mounted}/#{@relpath}' -out '#{mounted}/#{@relpath}.antibot3' "
		return false if File.exist?(mounted + "/" + @relpath + ".antibot3")
		command = "openssl enc -aes-128-cbc -k AntiBot3.0 -in '#{mounted}/#{@relpath}' -out '#{mounted}/#{@relpath}.antibot3' "
		unless pgbar.nil?
			last_pulse = Time.now.to_f
			IO.popen("ruby generic_wrapper.rb /var/run/filebak.ret " + command ) { |l|
				while l.gets
					now = Time.now.to_f
					unless now - last_pulse < 0.1 
						last_pulse = now
						pgbar.text = "Sichere Datei " + @relpath 
						pgbar.pulse
						while (Gtk.events_pending?)
							Gtk.main_iteration
						end
					end
				end
			}
			retval = File.read("/var/run/filebak.ret").strip.to_i
			if retval > 0
				system("rm -f '#{mounted}/#{@relpath}.antibot3' ")
				return false
			end
			@logdb.execute("UPDATE single_infection SET bakup = ? WHERE fpath = ? AND uuid = ? AND scantime = ? ",
				[ SQLite3::Database.quote("#{@relpath}.antibot3"),
				SQLite3::Database.quote(@relpath),
				SQLite3::Database.quote(@uuid),
				SQLite3::Database.quote(@tstamp.to_i.to_s) ] ) unless @logdb.nil?
			return true
		end
		return true if system(command)
		return false
	end

	

end