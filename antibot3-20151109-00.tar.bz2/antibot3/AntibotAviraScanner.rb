#!/usr/bin/ruby
# encoding: utf-8

class AntibotAviraScanner
	
	def initialize(drvscreen, params, logdir=nil)
		lang = ENV['LANGUAGE'][0..1]
		lang = ENV['LANG'][0..1] if lang.nil?
		lang = "en" if lang.nil?
		tlfile = "AntibotAviraScanner.xml"
		tlfile = "/usr/share/lesslinux/antibot3/AntibotAviraScanner.xml" if File.exists?("/usr/share/lesslinux/antibot3/AntibotAviraScanner.xml")
		@tl = MfsTranslator.new(lang, tlfile)
		@drivescreen = drvscreen 
		@params = params
		@logdir = logdir
		@qparams = params.collect { |x| "'#{x}'" }  
		@infections = Hash.new
		@return_codes = Hash.new
		@statistics = Hash.new
		@killed = false
		@partcount = -1
		@logdb = nil
		@tstamp = Time.now.to_i
		@hrtime = Time.new.strftime("%Y%m%d-%H%M%S") 
		@debug = AntibotMisc.boot_options["debug"]
		@avira_version = nil
		prepare_logdb
	end
	attr_reader :infections, :killed, :return_codes, :tstamp, :params, :logdir
	attr_accessor :logbd
	
	def kill_scan
		@killed = true
		system("rm /var/run/lesslinux/scan_running") 
		system("killall -9 find")
		system("killall -9 scancl")
	end
	
	def prepare_logdb
		return true unless @logdb.nil?
		system("mkdir -p /var/log/antibot3")
		# @logdb = SQLite3::Database.new(@logdir + "/fulllog.sqlite") unless @logdir.nil?
		@logdb = SQLite3::Database.new("/var/log/antibot3/fulllog-#{tstamp.to_s}.sqlite") if File.directory?("/var/log/antibot3")
		@logdb = SQLite3::Database.new("/tmp/fulllog-#{tstamp.to_s}.sqlite") unless File.directory?("/var/log/antibot3")
		begin
			@logdb.execute("CREATE TABLE single_infection " + 
				" (id INTEGER PRIMARY KEY ASC, scantime INTEGER(12), uuid VARCHAR(80), fpath VARCHAR(200), bakup VARCHAR(200), "  + 
				"  infection VARCHAR(120), scancl VARCHAR(120), sha1pre CHAR(40), sha1post CHAR(40), retvalue INT(6), " + 
				" fileout VARCHAR(120), scanout VARCHAR(800), action CHAR(20), retval INTEGER(5) ); ")
		rescue
		end
		# FIXME! Create indices!
	end
	
	def prepare_scan(pgbar=nil, label=nil)
		puts "Preparing scan:"
		now = Time.new.strftime("%Y%m%d-%H%M%S") 
		system("blkid | grep -v squashfs > '/var/log/antibot3/#{now}-laufwerke.txt' ") if File.directory?("/var/log/antibot3")
		@partcount = 0
		@drivescreen.dump_marked
		# Find out if we have to unmount partititions: 
		# Do not care if partitions are rw-mounted, but get verbose if
		# unmount fails.
		( @drivescreen.int_drives + @drivescreen.ext_drives ).each { |d| 
			d.partitions.each { |p|
				if @drivescreen.saved_states[p.uuid] == true && !@params.include?("--defaultaction=ignore")
					p.umount
					if !p.mount_point.nil? && p.mount_point[1].include?("ro")
						AntibotMisc.info_dialog(@tl.get_translation("drive-mounted").gsub("DEVICE",  p.device), @tl.get_translation("mounted-title"))
					end
				end
			}
		}
		( @drivescreen.int_drives + @drivescreen.ext_drives ).each { |d| 
			d.partitions.each { |p|
				if @drivescreen.saved_states[p.uuid] == true
					puts "Marked for scan: " + p.uuid
					p.filecount(pgbar) unless @killed == true
					@partcount += 1
				end
			}
		}
		@drivescreen.special_drives.each { |d|
			if @drivescreen.saved_states[d.dev] == true
				puts "Marked for scan: " + d.dev
				d.filecount(pgbar) unless @killed == true
				@partcount += 1
			end
		}
		unless pgbar.nil?
			pgbar.text = @tl.get_translation("partition-count").gsub("NUM", @partcount.to_s) 
			pgbar.text = @tl.get_translation("scan-cancelled") if @killed == true
		end
	end
	
	def check_avira(pgbar=nil)
		return true, 0 unless @avira_version.nil?
		@avira_version = Array.new
		scancl = "ruby generic_wrapper.rb /var/run/scancl.version.ret /AntiVir/scancl --version"
		lastupd = Time.now.to_f
		IO.popen(scancl) { |l|
			while l.gets
				line = $_ 
				unless line.strip == "-TickTock-" 
					@avira_version.push(line)
					puts line
				end
				unless pgbar.nil? || Time.now.to_f - lastupd < 0.1
					lastupd = Time.now.to_f
					pgbar.pulse
					pgbar.text = @tl.get_translation("check-avira") 
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
				end
			end
		}
		retval = File.read("/var/run/scancl.version.ret").strip.to_i
		@avira_version = nil if retval > 1
		return false, retval if @avira_version.nil?
	end
	
	# interval: delta in seconds (integer) for the signature update
	# FIXME! Use proxy settings
	# FIXME! Change avupdate script to return proper exit code!
	
	def update_signatures(interval, parameters=[], pgbar=nil)
		return false, @tl.get_translation("key-missing") unless File.exist?("/AntiVir/hbedv.key")
		return true, nil if File.stat("/AntiVir/hbedv.key").mtime.to_f + interval.to_f > Time.now.to_f 
		lastupd = Time.now.to_f
		now = Time.new.strftime("%Y%m%d-%H%M%S") 
		log = File.new(@logdir + "/" + now + "-avupdate.txt", "w") unless @logdir.nil?
		log = File.new(@logdir + "/" + now + "-avupdate.txt", "w") if @logdir.nil? && @debug == true
		command = "ruby generic_wrapper.rb /var/run/avupdate.ret /AntiVirUpdate/avupdate"
		parameters.each { |p| command = command + " '#{p}'" } 
		IO.popen(command) { |l|
			while l.gets
				line = $_
				unless pgbar.nil? || Time.now.to_f - lastupd < 0.1
					lastupd = Time.now.to_f
					pgbar.pulse
					pgbar.text = @tl.get_translation("sigupdate") 
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
				end
				unless line.strip == "-TickTock-" 
					puts line
					log.write(line) unless @logdir.nil?
				end
			end
		}
		log.close unless @logdir.nil?
		retval = -1
		begin
			retval = File.read("/var/run/avupdate.ret").strip.to_i
		rescue
		end
		puts "avupdate returned: " + retval.to_s
		unless pgbar.nil?
			pgbar.text = @tl.get_translation("update-done") 
			pgbar.fraction = 1.0
		end
		if retval == 0
			# touch the key file
			system("touch /AntiVir/hbedv.key")
			return true, nil
		elsif retval == 1
			# no update available - do nothing
			return true, nil
		else
			# Update failed
			return false, @tl.get_translation("update-failed") 
		end
	end
	
	# FIXME: Test settings!
	# FIXME: Test proper handling of boot sector scan
	
	def scan_partition(p, pc=0, pgbar=nil, label=nil)
		system("touch /var/run/lesslinux/scan_running") 
		if @killed == true
			pgbar.text = @tl.get_translation("scan-cancelled") unless pgbar.nil?
			system("rm /var/run/lesslinux/scan_running") 
			return false
		end
		p.filecount(pgbar)
		mode = "rw"
		mode = "ro" if @params.include?("--defaultaction=ignore")
		if p.class.to_s == "MfsSinglePartition"
			begin
				p.umount
				p.mount(mode)
			rescue
				AntibotMisc.info_dialog(@tl.get_translation("mount-failed"), "Error!")
				return false
			end
		end
		filect = 0
		lastfname = nil
		infected = Array.new
		last_pulse = Time.now.to_f
		unless pgbar.nil?
			pgbar.text =  @tl.get_translation("scan-start").gsub("NUM", pc.to_s).gsub("TOTAL",  @partcount.to_s)
			pgbar.fraction = 0.0 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		unless @params[-1] =~/^\// 
			if p.mount_point.nil?
				AntibotMisc.info_dialog(@tl.get_translation("mount-failed"), "Error!")
				return false
			end
		end
		scancl = "/usr/bin/ruby scancl_wrapper.rb /var/run/scancl.#{p.uuid}.ret /AntiVir/scancl " + @qparams.join(" ") + " "
		scancl = scancl + "'#{p.mount_point[0]}'" unless @params[-1] =~/^\// 
		puts "Running command: " + scancl
		now = Time.new.strftime("%Y%m%d-%H%M%S") 
		log = File.new(@logdir + "/scancl-" + p.device.gsub("/", "_") + "-" + now + ".txt", "w") unless @logdir.nil?
		prefix = Array.new
		prefix_finished = false
		suffix = Array.new
		suffix_started = false
		# file_lines = Array.new
		# alert = false
		last_count_change = Time.now.to_f
		last_count = 0
		last_file = 0
		line_count = 0
		filecmd = ` which file `
		last_six_lines = Array.new
		IO.popen(scancl) { |l|
			while l.gets
				now = Time.now.to_f
				line = nil
				raw = $_
				# Throw away all those lines "TickTock" - generated from the wrapper script
				unless raw.strip == "-TickTock-"
					begin
						puts raw.strip if raw =~ /ä/
						line = raw
					rescue
						line =  raw.encode("UTF-8", "binary", :undef => :replace, :invalid => :replace, :replace => '_') 
						line = line.encode("binary", "UTF-8", :undef => :replace, :invalid => :replace, :replace => '_') 
						puts line.strip
					end
					line_count += 1
				end
				# Increase filecount and log last filename count if line starts with "/"
				# this might be imprecise because archives sometimes appear with more than one line
				# therefore those two variables should just be used for rough statistics
				if !line.nil? && line.strip =~ /^\//
					filect += 1
					lastfname = line.strip
				end
				# Treat all files as prefix until the first line starting with "/" appears
				if !line.nil? && prefix_finished == false
					if line.strip =~ /^\//
						prefix_finished = true
						unless @logdir.nil?
							prefix.each { |l| log.write(l) }
							0.upto(1) { |n| log.write("\n") }
						end
					else
						prefix.push(line)
					end
				end
				
				# Start pushing to suffix as soon as a line starting with Statistics appears
				if !line.nil? && ( line.strip =~ /^Statistics/ || suffix_started == true )
					suffix.push(line)
					suffix_started = true
				end
				
				# Somehow Aviras documentation of scancl is imprecise: The documentation says that
				# every file appears with three lines in the log. However our tests have shown that
				# sometimes it's four lines (nested archives). To properly recognize, we keep a ring
				# buffer of six lines. As soon as the first line in the buffer starts with "/" and
				# the second with "Date" we are sure to have a new file. From the last two or three
				# lines in the buffer we can then judge if the proceeding file has three or four
				# lines.
				#
				# FIXME! Tell Avira to either fix the documentation or the behaviour of the scanner.
				#
				# FIXME! When Avira is run in desinfection mode on a ro mounted filesystem, output
				# will be garbled (missing line break, name of next file in brackets. This is very
				# bad to parse. We currently try to avoid this situation by telling users to unmount 
				# themselves. But this does not work in pure CLI mode.
				
				if !line.nil?
					last_six_lines.push(line)
					last_six_lines.shift if last_six_lines.size > 6
					# Do not do anything if the buffer is not yet ready
					if last_six_lines.size > 5
						# let's check if three lines indicate an infection:
						if last_six_lines[0] =~ /^\// && last_six_lines[1].strip =~ /^date:/i && last_six_lines[2].strip =~ /^ALERT/
							fileout = nil
							fileout = ` file -b '#{last_six_lines[0].strip}' `.strip unless filecmd == ""
							puts "ALERT:  " + last_six_lines[0]
							0.upto(2) { |n| log.write(last_six_lines[n]) unless @logdir.nil? }
							# find out whether something has been done with the file
							act = nil
							slc = nil
							if last_six_lines[5].strip =~ /^date:/i 
								log.write(last_six_lines[3]) unless @logdir.nil?
								act = last_six_lines[3].split[-1].gsub("[", "").gsub("]", "")
								slc = last_six_lines[0..3]
							else
								act = last_six_lines[2].split[-1].gsub("[", "").gsub("]", "")
								slc = last_six_lines[0..2]
							end
							puts "Action taken on file: " + act unless act.nil?
							newinf = AntibotInfectedFile.new(last_six_lines[0], p.mount_point[0], p.uuid, last_six_lines[2], @qparams, fileout, @logdb, @tstamp, act, slc)
							infected.push newinf
						end
					end					
				end
				
				# This is just GUI stuff, used to move the progress bar. If Avira keeps scanning one 
				# file for more than two seconds, the progress bar will show the file name and it will
				# pulse.
				
				unless pgbar.nil? || now - last_pulse < 0.1 
					last_pulse = now
					unless p.filecount(pgbar).nil?
						if filect.to_i > 0
							if filect.to_i > last_count
								last_count = filect.to_i
								last_count_change = now
								pgbar.fraction = filect.to_f / p.filecount(pgbar).to_f
								pgtext = @tl.get_translation("scan-progress").gsub("NUM", pc.to_s).gsub("TOTAL",  @partcount.to_s).gsub("FILES", filect.to_s) 
								pgtext = pgtext + @tl.get_translation("scan-malware-multiple").gsub("NUM", infected.size.to_s) if infected.size > 1
								pgtext = pgtext + @tl.get_translation("scan-malware-single") if infected.size == 1
								pgbar.text = pgtext
							elsif now - last_count_change > 2.0
								pgbar.pulse
								chopped_fname = lastfname.to_s.split("/")[-1] 
								pgbar.text = @tl.get_translation("check-file").gsub("FNAME", chopped_fname)
							end
						else 
							pgbar.pulse
						end
					end
					while (Gtk.events_pending?)
						Gtk.main_iteration
					end
				end
			end
		}
		# Flush the saved lines from the suffix:
		log.write("\n\n") unless @logdir.nil?
		@statistics[p] = Array.new
		suffix.each{ |l| 
			log.write(l) unless @logdir.nil?
			@statistics[p].push(l) unless l.strip == ""
		}
		log.close unless @logdir.nil?
		unless pgbar.nil?
			pgbar.text = @tl.get_translation("scan-done").gsub("NUM", pc.to_s).gsub("TOTAL",  @partcount.to_s) 
			pgbar.fraction = 1.0 
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		p.umount if p.class.to_s == "MfsSinglePartition"
		@infections[p] = infected
		@return_codes[p] = File.read("/var/run/scancl.#{p.uuid}.ret").strip.to_i 
		puts "Scanning partition: #{p.device} #{p.uuid} terminated with code #{@return_codes[p]} "
		return false if @killed == true
	end
	
	def run_scan(pgbar=nil, label=nil)
		# Reset variable for kill
		@killed = false
		system("touch /var/run/lesslinux/scan_running") 
		pc = 1
		failures = Array.new
		( @drivescreen.int_drives + @drivescreen.ext_drives ).each { |d|
			d.partitions.each { |p|
				if @drivescreen.saved_states[p.uuid] == true
					scan_partition(p, pc, pgbar, label)
					pc += 1
				end
			}
		}
		@drivescreen.special_drives.each { |d|
			if @drivescreen.saved_states[d.dev] == true
				scan_partition(d, pc, pgbar, label)
				pc += 1
			end
		}
		system("rm /var/run/lesslinux/scan_running") 
		if failures.size > 0
			# FIXME: Show error message indicating failed scan!
		end
	end
	
	def dump_scan_results
		
	end
	
	def dump_html_log
		return true if @logdb.nil?
		csslines = Array.new
		jslines = Array.new
		File.open("scanlog.css").each { |line| csslines.push(line.strip) unless line.strip == "" }
		File.open("scanlog.js").each { |line| jslines.push(line.strip) unless line.strip == "" } 
		# Read some rquired information
		dmiinfo = Array.new
		IO.popen("dmidecode --type system") { |l|
			while l.gets
				dmiinfo.push($_)
			end
		}
		# Build XML document 
		doc = REXML::Document.new(nil, { :respect_whitespace => %w{ script style } } )
		root = REXML::Element.new "html"
		body = REXML::Element.new "body"
		body.add_attribute("onload", "jsinit();") 
		head = REXML::Element.new "head"
		m1 = REXML::Element.new "meta"
		m1.add_attribute("http-equiv", "Content-Type")
		m1.add_attribute("content", "text/html; charset=UTF-8")
		css = REXML::Element.new "style"
		css.add_attribute("type", "text/css")
		css.add(REXML::Text.new("\n" + csslines.join(" \n ") + "\n", true, nil, true ))
		cs2 = REXML::Element.new "link"
		cs2.add_attribute("rel", "stylesheet")
		cs2.add_attribute("type", "text/css")
		cs2.add_attribute("href", "override.css")
		js = REXML::Element.new "script"
		js.add_attribute("type", "text/javascript")
		js.add(REXML::Text.new("\n" + jslines.join(" \n ") + "\n", true, nil, true ))
		head.add m1
		head.add cs2
		head.add css
		head.add js 
		t = REXML::Element.new "title"
		t.add_text @tl.get_translation("html-title")
		head.add t
		root.add head
		root.add body
		doc.add root
		# Header section with general information
		allhead = REXML::Element.new "h1"
		allhead.add_text @tl.get_translation("html-title")
		warndiv = REXML::Element.new "div"
		warndiv.add_attribute("class", "warndiv")
		warntxt = @tl.get_translation("html-warn") 
		warndiv.add_text warntxt
		genhead = REXML::Element.new "h2"
		genhead.add_text @tl.get_translation("html-common") 
		body.add allhead
		body.add warndiv
		body.add genhead
		pgen = REXML::Element.new "p"
		pgen.add_attribute("class", "pgen")
		pgen.add_text @tl.get_translation("html-date") + ": " + Time.now.to_s 
		pgen.add REXML::Element.new "br"
		pgen.add_text @tl.get_translation("html-param") + " "  + @params.join(" ")
		body.add pgen
		# div boxes "Computer" and "Avira"
		divgen = REXML::Element.new "div"
		agen = REXML::Element.new "a" 
		agen.add_text @tl.get_translation("html-comp-view") 
		agen.add_attribute("href", "#divgen")
		agen.add_attribute("id", "showcomp")
		age2 = REXML::Element.new "a" 
		age2.add_text @tl.get_translation("html-comp-hide") 
		age2.add_attribute("href", "#divgen")
		age2.add_attribute("id", "hidecomp")
		divgen.add agen
		# divgen.add REXML::Element.new "br"
		divgen.add age2
		dmipre = REXML::Element.new "pre"
		dmipre.add_text dmiinfo.join("")
		dmipre.add_attribute("id", "dmipre")
		divgen.add dmipre
		divavr = REXML::Element.new "div"
		aavr = REXML::Element.new "a" 
		aavr.add_text @tl.get_translation("html-avira-view") 
		aavr.add_attribute("href", "#avrgen")
		aavr.add_attribute("id", "showavira")
		aav2 = REXML::Element.new "a" 
		aav2.add_text @tl.get_translation("html-avira-hide") 
		aav2.add_attribute("href", "#avrgen")
		aav2.add_attribute("id", "hideavira")
		divgen.add aavr
		# divgen.add REXML::Element.new "br"
		divgen.add aav2
		avrpre = REXML::Element.new "pre"
		avrpre.add_text @avira_version.join("")
		avrpre.add_attribute("id", "avrpre")
		divgen.add avrpre
		body.add divgen
		# div box for scanned drives
		divdrv = REXML::Element.new "div"
		divdrv.add_attribute("id", "divdrives")
		divext = REXML::Element.new "div"
		divext.add_attribute("id", "extdrives")
		divext.add_attribute("class", "intextdrives")
		divint = REXML::Element.new "div"
		divint.add_attribute("id", "intdrives")
		divint.add_attribute("class", "intextdrives")
		divspec = REXML::Element.new "div"
		divspec.add_attribute("id", "specialdrives")
		divspec.add_attribute("class", "intextdrives")
		hint = REXML::Element.new "h3"
		hint.add_text @tl.get_translation("html-drives-internal") 
		hext = REXML::Element.new "h3"
		hext.add_text @tl.get_translation("html-drives-external") 
		hspec = REXML::Element.new "h3"
		hspec.add_text @tl.get_translation("html-drives-external") 
		divint.add hint
		divext.add hext
		divspec.add hspec
		divdrv.add divint
		divdrv.add divext
		divdrv.add divspec if @drivescreen.special_drives.size > 0
		body.add divdrv
		# General Info for each drive
		int_divs = Hash.new
		ext_divs = Hash.new
		spec_divs = Hash.new
		@drivescreen.int_drives.each { |d|
			int_divs[d.device] =  REXML::Element.new "div"
			int_divs[d.device].add_attribute("id", "drive-#{d.device}")
			int_divs[d.device].add_attribute("class", "drivebox")
			divint.add int_divs[d.device]
		}
		@drivescreen.ext_drives.each { |d|
			ext_divs[d.device] =  REXML::Element.new "div"
			ext_divs[d.device].add_attribute("id", "drive-#{d.device}")
			ext_divs[d.device].add_attribute("class", "drivebox")
			divext.add ext_divs[d.device]
		}
		@drivescreen.special_drives.each { |d|
			spec_divs[d.device] =  REXML::Element.new "div"
			spec_divs[d.device].add_attribute("id", "drive-#{d.device}")
			spec_divs[d.device].add_attribute("class", "drivebox")
			divspec.add spec_divs[d.device]
		}
		@drivescreen.special_drives.each { |d|
			h = REXML::Element.new "h4"
			# h.add_text d.vendor + " " + d.model + " - " + d.human_size 
			prefix = @tl.get_translation("html-address")  + ": "
			prefix = @tl.get_translation("html-device") + ": " if d.dev =~ /^\/dev\//
			h.add_text prefix + d.dev 
			# Link to fold SMART info
			a = REXML::Element.new "a"
			a.add_text @tl.get_translation("html-smart-view") 
			a.add_attribute("href", "#" + d.device + "-unfold")
			a.add_attribute("id", "showsmart-" + d.device)
			a.add_attribute("class", "showsmart")
			a.add_attribute("onclick", 'showsmart("' + d.device + '");')
			b = REXML::Element.new "a"
			b.add_text @tl.get_translation("html-smart-hide") 
			b.add_attribute("href", "#" + d.device + "-unfold")
			b.add_attribute("id", "hidesmart-" + d.device)
			b.add_attribute("class", "hidesmart")
			b.add_attribute("onclick", 'hidesmart("' + d.device + '");')
			# Smart information
			smart_adiv = REXML::Element.new "div"
			smart_adiv.add_attribute("class", "smartouter")
			smart_adiv.add_attribute("id", "smart-" + d.device)
			smart_summ = REXML::Element.new "div"
			smart_summ.add_attribute("class", "smartsummary")
			# smart_adiv.add a
			# smart_adiv.add REXML::Element.new "br"
			# smart_adiv.add b
			smart_link = REXML::Element.new "a"
			smart_link.add_attribute("target", "_blank")
			smart_link.add_attribute("href", @tl.get_translation("html-smart-href") )
			smart_link.add_attribute("title", @tl.get_translation("html-smart-title") )
			smart_link.add_text "S.M.A.R.T."
			smart_summ.add_text @tl.get_translation("html-smart-pre")
			smart_summ.add smart_link
			smart_summ.add_text @tl.get_translation("html-smart-post")
			smart_adiv.add smart_summ
			# Now Partition by partition
			pboxes = Array.new
			# d.partitions.each { |p|
				pouterbox = REXML::Element.new "div"
				pinnerbox = REXML::Element.new "div"
				pinnerbox.add_attribute("class", "pinnerbox")
				pshort = REXML::Element.new "div"
				pshort.add_attribute("class", "psummary")
				phead = REXML::Element.new "h5"
				# windows, winvers = p.is_windows
				prefix = @tl.get_translation("html-address")  + ": "
				prefix = @tl.get_translation("html-device") + ": " if d.dev =~ /^\/dev\//
				pht = prefix + @tl.get_translation("html-drive-desc").gsub("DEVICE", d.dev).gsub("FILESYS", d.fs).gsub("MOUNTPOINT", d.mntpoint) 
				pht = pht + " " + @tl.get_translation("html-drive-ro") unless d.rw? 
				err_msg = hr_error_code(d)
				pht += " - " + err_msg unless err_msg.nil? 
				phead.add_text pht
				pouterbox.add phead
				pouterbox.add pshort
				if !@statistics[d].nil? && @statistics[d].size > 0
					divstat = REXML::Element.new "div"
					divstat.add_attribute("class", "statistics")
					pouterbox.add divstat
					prestat = REXML::Element.new "pre"
					prestat.add_text @statistics[d].join("")
					divstat.add prestat
				end
				if @infections[d].nil?
					pshort.add_text @tl.get_translation("html-drive-ignored")
					pouterbox.add_attribute("class", "pouterbox")
				elsif @infections[d].size > 0
					pshort.add_text @tl.get_translation("html-drive-infected")
					# retrieve table with infected files
					pinnerbox.add infected_table(d)
					pouterbox.add pinnerbox
					pouterbox.add_attribute("class", "pouterbox-red")
				else
					pshort.add_text @tl.get_translation("html-drive-ok")
					pouterbox.add_attribute("class", "pouterbox-green")
					pouterbox.add_attribute("class", "pouterbox-red") unless err_msg.nil? 
				end
				
				pboxes.push pouterbox # if p.fs =~ /ext/ || p.fs =~ /fat/ || p.fs =~ /ntfs/ || p.fs =~ /btrfs/ 
			# }
			
			spec_divs[d.device].add h
			spec_divs[d.device].add smart_adiv
			pboxes.each { |pb| spec_divs[d.device].add pb }
		}	
		( @drivescreen.int_drives + @drivescreen.ext_drives ).each { |d|
			h = REXML::Element.new "h4"
			h.add_text d.vendor + " " + d.model + " - " + d.human_size 
			# Link to fold SMART info
			a = REXML::Element.new "a"
			a.add_text @tl.get_translation("html-smart-view")  
			a.add_attribute("href", "#" + d.device + "-unfold")
			a.add_attribute("id", "showsmart-" + d.device)
			a.add_attribute("class", "showsmart")
			a.add_attribute("onclick", 'showsmart("' + d.device + '");')
			b = REXML::Element.new "a"
			b.add_text @tl.get_translation("html-smart-hide")   
			b.add_attribute("href", "#" + d.device + "-unfold")
			b.add_attribute("id", "hidesmart-" + d.device)
			b.add_attribute("class", "hidesmart")
			b.add_attribute("onclick", 'hidesmart("' + d.device + '");')
			# Smart information
			smart_adiv = REXML::Element.new "div"
			smart_adiv.add_attribute("class", "smartouter")
			smart_adiv.add_attribute("id", "smart-" + d.device)
			smart_idiv = REXML::Element.new "div"
			smart_idiv.add_attribute("class", "smartinfo")
			smart_ediv = REXML::Element.new "div"
			smart_ediv.add_attribute("class", "smarterror")
			smart_ipre = REXML::Element.new "pre"
			smart_epre = REXML::Element.new "pre"
			smart_summ = REXML::Element.new "div"
			smart_summ.add_attribute("class", "smartsummary")
			s, i, e = d.error_log
			smart_ipre.add_text i.join("")
			smart_epre.add_text e.join("")
			smart_idiv.add smart_ipre
			smart_ediv.add smart_epre
			smart_adiv.add a
			# smart_adiv.add REXML::Element.new "br"
			smart_adiv.add b
			smart_link = REXML::Element.new "a"
			smart_link.add_attribute("target", "_blank")
			smart_link.add_attribute("href", @tl.get_translation("html-smart-href"))
			smart_link.add_attribute("title", @tl.get_translation("html-smart-title"))
			smart_link.add_text "S.M.A.R.T."
			if s == true
				if e.size < 1
					smart_summ.add_text @tl.get_translation("html-smartlog-pre")
					smart_summ.add smart_link
					smart_summ.add_text @tl.get_translation("html-smartlog-post")
				else
					smart_summ.add_text @tl.get_translation("html-smarterr-pre")
					smart_summ.add smart_link
					smart_summ.add_text @tl.get_translation("html-smarterr-post")
				end
			else
				smart_summ.add_text @tl.get_translation("html-smartno-pre")
				smart_summ.add smart_link
				smart_summ.add_text @tl.get_translation("html-smartno-post")
			end
			smart_adiv.add smart_summ
			smart_adiv.add smart_idiv
			smart_adiv.add smart_ediv if e.size > 0
			# Now Partition by partition
			pboxes = Array.new
			d.partitions.each { |p|
				pouterbox = REXML::Element.new "div"
				pinnerbox = REXML::Element.new "div"
				pinnerbox.add_attribute("class", "pinnerbox")
				pshort = REXML::Element.new "div"
				pshort.add_attribute("class", "psummary")
				phead = REXML::Element.new "h5"
				windows, winvers = p.is_windows
				pht = p.device.to_s + ", " + p.fs.to_s + " " + p.label.to_s + " " + p.human_size
				pht = pht + " - " + winvers if windows == true
				pht = pht + " (UUID: #{p.uuid})"
				pht = pht + " - " + @tl.get_translation("html-drive-antibot") if p.system_partition? == true
				err_msg = hr_error_code(p)
				pht += " - " + err_msg unless err_msg.nil? 
				phead.add_text pht
				pouterbox.add phead
				pouterbox.add pshort
				if !@statistics[p].nil? && @statistics[p].size > 0
					divstat = REXML::Element.new "div"
					divstat.add_attribute("class", "statistics")
					pouterbox.add divstat
					prestat = REXML::Element.new "pre"
					prestat.add_text @statistics[p].join("")
					divstat.add prestat
				end
				if @infections[p].nil?
					pshort.add_text @tl.get_translation("html-drive-ignored")
					pouterbox.add_attribute("class", "pouterbox")
				elsif @infections[p].size > 0
					pshort.add_text @tl.get_translation("html-drive-infected")
					# retrieve table with infected files
					pinnerbox.add infected_table(p)
					pouterbox.add pinnerbox
					pouterbox.add_attribute("class", "pouterbox-red")
				else
					pshort.add_text @tl.get_translation("html-drive-ok")
					pouterbox.add_attribute("class", "pouterbox-green")
					pouterbox.add_attribute("class", "pouterbox-red") unless err_msg.nil? 
				end
				
				pboxes.push pouterbox if p.fs =~ /ext/ || p.fs =~ /fat/ || p.fs =~ /ntfs/ || p.fs =~ /btrfs/ 
			}
			if ext_divs.has_key? d.device
				ext_divs[d.device].add h
				ext_divs[d.device].add smart_adiv
				pboxes.each { |pb| ext_divs[d.device].add pb }
			else
				int_divs[d.device].add h
				int_divs[d.device].add smart_adiv
				pboxes.each { |pb| int_divs[d.device].add pb }
			end
		}
		# @logdir @tstamp
		unless @logdir.nil?
			outfile = File.new(@logdir + "/scanprotokoll-" + @hrtime.to_s + ".html", File::CREAT|File::TRUNC|File::RDWR) 
		else
			system("mkdir -p " + @tl.get_translation("html-proto-dir"))
			outfile = File.new( @tl.get_translation("html-proto-dir") + "/" + @tl.get_translation("html-proto-prefix")  + @hrtime.to_s + ".html", File::CREAT|File::TRUNC|File::RDWR)
		end
		doc.write(outfile) # , 4)
		outfile.close
	end
	
	def infected_table(p)
		inftab = REXML::Element.new "table"
		inffirst = REXML::Element.new "tr"
		[ @tl.get_translation("inftable-fpath"), 
			@tl.get_translation("inftable-malware"), 
			@tl.get_translation("inftable-action"), "loglines" ].each { |i|
			td = REXML::Element.new "td"
			td.add_text i
			td.add_attribute("class", "fulllog") if i == "loglines"
			inffirst.add td
		}
		thead = REXML::Element.new "thead"
		thead.add inffirst
		inftab.add thead
		tbody = REXML::Element.new "tbody"
		lct = 0
		infections[p].each { |i|
			tr = REXML::Element.new "tr"
			fn = REXML::Element.new "td"
			ic = REXML::Element.new "td"
			ac = REXML::Element.new "td"
			fl = REXML::Element.new "td"
			fp = REXML::Element.new "pre"
			il = REXML::Element.new "a"
			il.add_attribute("href", @tl.get_translation("inftable-href") + i.short_infection)
			il.add_attribute("target", "_blank")
			il.add_attribute("title", @tl.get_translation("inftable-link").gsub("VIRUS", i.short_infection))
			fl.add_attribute("class", "fulllog") 
			fn.add_text i.relpath
			ic.add il
			il.add_text i.short_infection
			if i.action_taken == "desinfect" 
				ac.add_text @tl.get_translation("inftable-act-desinf") 
			elsif i.action_taken == "delete" 
				ac.add_text @tl.get_translation("inftable-act-delete") 
			elsif i.action_taken == "truncate" 
				ac.add_text  @tl.get_translation("inftable-act-truncate") 
			elsif i.action_taken == "rename" 
				ac.add_text @tl.get_translation("inftable-act-rename") 
			else
				ac.add_text @tl.get_translation("inftable-act-none") 
			end
			tr.add fn
			tr.add ic
			tr.add ac
			tr.add fl
			fl.add fp
			fp.add_text i.fulllog.join
			tr.add_attribute("class", "oddline") if lct % 2 == 1
			tr.add_attribute("class", "evenline") if lct % 2 == 0
			tbody.add tr			
			lct += 1
		}
		inftab.add tbody
		return inftab 
	end
	
	def inf_count
		inf_count = 0
		@infections.each { |k,v|
			v.each { |f| inf_count += 1 }
		}
		return inf_count
	end
	
	def vir_count 
		vir_count = 0
		@infections.each { |k,v|
			v.each { |f| vir_count += 1 if f.relpath =~ /\.vir$/i }
		}
		return vir_count
	end
	
	def hr_error_code(partition)
		code = @return_codes[partition] 
		case code
			when 99999
				return @tl.get_translation("error-99999") # "Virenscan abgebrochen oder gestoppt"
			when 203
				return @tl.get_translation("error-203") #"Abbruch: Ungültiger Programmaufruf"
			when 204
				return @tl.get_translation("error-204") #"Abbruch: Ungültiges Verzeichnis"
			when 205
				return @tl.get_translation("error-205") #"Abbruch: Protokoll konnte nicht erstellt werden"
			when 210
				return @tl.get_translation("error-210") #"Abbruch: Beschädigte Antibot-Installation"
			when 211
				return @tl.get_translation("error-211") #"Abbruch: Selbstcheck fehlgeschlagen"
			when 212
				return @tl.get_translation("error-212") #"Abbruch: Virensignaturen konnten nicht gelesen werden"
			when 213
				return @tl.get_translation("error-213") #"Abbruch: Scan-Engine und Signaturen inkompatibel"
			when 214
				return @tl.get_translation("error-214") #"Abbruch: Lizenzdatei ungültig"
			when 215
				return @tl.get_translation("error-215") #"Abbruch: Selbstcheck fehlgeschlagen"
			when 216 
				return @tl.get_translation("error-216") #"Fehler: Datei-Zugriff verweigert"
			when 217
				return @tl.get_translation("error-217") #"Fehler: Ordner-Zugriff verweigert"
			else
				return nil
		end
	end
	
end
