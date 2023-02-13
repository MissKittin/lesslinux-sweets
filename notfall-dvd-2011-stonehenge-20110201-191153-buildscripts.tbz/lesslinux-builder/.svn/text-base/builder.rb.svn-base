#!/usr/bin/ruby
# encoding: utf-8

require "builder/buildAnyStage.rb"
require "builder/buildFirstStage.rb"
require "builder/buildSecondStage.rb"
require "builder/buildThirdStage.rb"
require "builder/fileDownLoader.rb"
require "builder/singleSourceFile.rb"
require "builder/fileChecker.rb"
require "builder/initramfsAssembly.rb"
require "builder/bootdiskAssembly.rb"
require "builder/packageBuilder.rb"
require "builder/packageVersion.rb"
require "rexml/document"
require "digest/sha1"
# require "mysql"
require 'optparse' 
require 'sqlite3'
require 'thread'

# require 'rdoc/usage'
# $debug_messages = Array.new

@run_tests = true
@skip_stages = Array.new
@pkg_list_file = nil
@config_file = "config/general.xml"
@brand_file = "config/branding.xml"
@kernel_file = "config/kernels.xml"
@unstable = false
@tstamp_now = Time.new.to_i
@breakpoint = nil
@ask_stage03 = false
@check_updates = false
@log_each = false
@full_image = false
@stracalyze = true
@force_stracalyze = false
@thread_count = 1
@force_linear = false
@skiplist = nil
@clean = true

# look for some commands
#
# perl
# unzip
# gunzip
# tar
# bunzip2
# mkisofs
# mksquashfs

opts = OptionParser.new 
opts.on('-n', '--no-test')    { @run_tests = false }
opts.on('-s', '--skip-stages', :REQUIRED )    { |i| @skip_stages = i.split(",") }
opts.on('-p', '--package-list', :REQUIRED ) { |i| @pkg_list_file = i.strip } 
opts.on('-c', '--config', :REQUIRED ) { |i| @config_file = i.chomp } 
opts.on('-b', '--branding', :REQUIRED ) { |i| @brand_file = i.chomp }
opts.on('-k', '--kernels', :REQUIRED ) { |i| @kernel_file = i.chomp }
opts.on('-u', '--unstable') { @unstable = true }
opts.on('-d', '--breakpoint', :REQUIRED ) { |i| @breakpoint = i.chomp }
opts.on('-a', '--ask') { @ask = true }
opts.on('-o', '--check-only') { @check_updates = true }
opts.on('-l', '--log') { @log_each = true }
opts.on('-f', '--full') { @full_image = true }
opts.on('-t', '--threads', :REQUIRED ) { |i| @thread_count = i.strip.to_i } 
opts.on('--no-stracalyze') { @stracalyze = false }
opts.on('--force-stracalyze') { @stracalyze = false ; @force_stracalyze = true}
opts.on('--force-linear') { @force_linear = true}
opts.on('--skip-files', :REQUIRED ) { |i| @skiplist = i.strip }
opts.on('--no-clean') { @clean = false}

opts.parse!

# raise "DebugBreakPoint"

xcfg = File.new( @config_file )
cfg = REXML::Document.new xcfg
@cfgroot = cfg.root
@srcdir = @cfgroot.elements["sourcedir"].text
@builddir = @cfgroot.elements["builddir"].text
@unpriv = @cfgroot.elements["unpriv"].text
@overlays = @cfgroot.elements["overlays"].text
@dbuser = @cfgroot.elements["database/user"].text
@dbname = @cfgroot.elements["database/dbname"].text
@dbpass = @cfgroot.elements["database/pass"].text
@modmodel = "old"
begin
	@modmodel = @cfgroot.elements["build/modmodel"].text.downcase.strip
rescue
end
@workdir = Dir.pwd
@build_timestamp = Time.now.strftime("%Y%m%d-%H%M%S")

xbranding = File.new @brand_file
@branding = REXML::Document.new xbranding
@dbh = nil

# Connect to SQLite3 database file
# This replaced the MySQL dependence eventually
unless File.exist?(@builddir + "/lesslinux.sqlite")
	system("mkdir -p " + @builddir)
	system("touch " + @builddir + "/lesslinux.sqlite")
	puts sprintf("%015.4f", Time.now.to_f) + " sqlite > Create database"  
	@sqlite = SQLite3::Database.new(@builddir + "/lesslinux.sqlite")
	@sqlite.execute("CREATE TABLE llfiles (id INTEGER PRIMARY KEY ASC, ftype CHAR(4), fsize INTEGER(18), modtime INTEGER(12), fowner INTEGER(6), fgroup INTEGER(6), fmode INTEGER(6), sha1sum CHAR(40), file_output TEXT, link_target TEXT, cleaned_type VARCHAR(256), pkg_name VARCHAR(80), pkg_version VARCHAR(40), pkg_time INTEGER(12), sub_pkg VARCHAR(40), stage VARCHAR(40), fname TEXT);")
	# FIXME Create Indexes!
	@sqlite.execute("CREATE INDEX ftype_idx ON llfiles (cleaned_type, pkg_name, stage) ")
else
	@sqlite = SQLite3::Database.new(@builddir + "/lesslinux.sqlite")
end

# Check for existence of  builddir and sourcedir
unless File.exists?(@builddir) && File.ftype(@builddir) == "directory"
	puts sprintf("%015.4f", Time.now.to_f) + " error > EXIT! Please create the directory " + @builddir + " first!" 
	$stdout.flush
	raise "NoBuilddir"
end
unless File.exists?(@srcdir) && File.ftype(@srcdir) == "directory"
	puts sprintf("%015.4f", Time.now.to_f) + " error > EXIT! Please create the directory " + @srcdir + " first!" 
	$stdout.flush
	raise "NoBuilddir"
end

# objects for stage 02 are also needed by stage three
@stage_two_scripts = []
@stage_two_objs = []
Dir.foreach("scripts/stage02") { |f|
	# fcomps = File.split(f)
	if (f =~ /\d+.*\.xml$/ )
		if @unstable == true && File.exists?("scripts/stage02.unstable/" + f)
			@stage_two_scripts.push(f)
		else
			@stage_two_scripts.push(f)
		end
	end
}
@stage_two_scripts.sort.each { |i| 
	@stage_two_objs.push(SecondStage.new(i, @srcdir, @builddir, @unpriv, "stage02", @dbh, @unstable, @sqlite))
}

puts sprintf("%015.4f", Time.now.to_f) + " info  > Number of threads requested " + @thread_count.to_s

#=============================================================================
#
# Some common functions - You might fold them, they are not essential for
# understanding the flow of the program
#
#=============================================================================

def read_pkglist(filename)
	pkg_list = Array.new
	f = File.new(filename)
	begin
		while (line = f.readline)
			# line.chomp
			# $stdout.print line if line =~ /blue/
			rawline = line.strip
			unless rawline == ""
				rawtoks = rawline.split
				pkg_list.push(rawtoks[0]) unless rawtoks[0] =~ /^#/
			end
		end
	rescue EOFError
		f.close
	end
	return pkg_list
end

def get_stage_one_objs
	stage_one_scripts = []
	Dir.foreach("scripts/stage01") { |f|
		# fcomps = File.split(f)
		if (f =~ /\d+.*\.xml$/ )
			if @unstable == true && File.exists?("scripts/stage01.unstable/" + f)
				stage_one_scripts.push(f)
			else
				stage_one_scripts.push(f)
			end
		end
	}
	stage_one_objs = []
	stage_one_scripts.sort.each { |i| stage_one_objs.push(FirstStage.new(i, @srcdir, @builddir, @unpriv, "stage01", @dbh, @unstable, @sqlite)) }
	return stage_one_objs
end


#=============================================================================
#
# The first stage is used to prepare a preliminary toolchain that will be
# stored in the folder /tools. It is partially cross built and should just
# be used for bootstrapping the "real" toolchain.
#
# You might have downloaded a copy of this toolchain that allows you to skip
# this step and save an hour or two.
#
#==============================================================================

def run_stage_one 
	# directory tools is needed by stage on, be sure it does not exist yet
	if File.exists?("/tools")
		puts sprintf("%015.4f", Time.now.to_f) + " error > EXIT! Directory or softlink /tools already exists"
		puts sprintf("%015.4f", Time.now.to_f) + " error > Too risky for me to continue. Remove /tools, then"
		puts sprintf("%015.4f", Time.now.to_f) + " error > try again."
		$stdout.flush
		raise "SoftlinkAlreadyThere"
	end
	# File.symlink(@builddir + "/stage01/chroot/tools", "/tools")
	system("mkdir /tools")
	system("mkdir -p " + @builddir + "/stage01/chroot/tools")
	system("mount -o bind " + @builddir + "/stage01/chroot/tools /tools")
	[ "/stage01", "/stage01/build","/stage01/chroot","/stage01/chroot/tools" ].each { |d|
		unless File.exists?(@builddir + d)
			Dir.mkdir(@builddir + d)
		end
	}
	# Stage 01 abfrühstücken
	# Alle Scripte in stage01 suchen
	stage_one_objs = get_stage_one_objs
	# Download first
	stage_one_objs.each { |i| i.download }
	# Unpack
	stage_one_objs.each { |i|
		i.unpack
		### Dir.chdir(@workdir)
		i.patch
		### Dir.chdir(@workdir)
		i.build
		### Dir.chdir(@workdir)
		i.install
		### Dir.chdir(@workdir)
		i.filecheck
		### Dir.chdir(@workdir)
	}
	system("umount /tools")
end

#=============================================================================
#
# After successfully building the first stage, we might want to backup the
# complete chroot for later builds. Since stage 01 is less prone to changes,
# this might save a lot of time later.
#
#=============================================================================

def save_stage_one
	unless File.exists? @builddir + "/stage01/chroot.tbz"
		### Dir.chdir(@builddir + "/stage01")
		system "tar -C " + @builddir + "/stage01 -cvjf " + @builddir + "/stage01/chroot.tbz chroot"
		# system "mysqldump --add-drop-table --password='" + @dbpass + "' -u '" + @dbuser + "' '" + @dbname + "' > chroot.sql "
		system "bzip2 -c " + @builddir + "/lesslinux.sqlite > " + @builddir + "/stage01/chroot.sqlite.bz2"
	end
end

#=============================================================================
#
# In the second stage the buildscripts chroot and use the toolchain to build 
# a linux distribution that uses normal paths. The result is a regular,
# complete linux that can be used as a chroot environment.
# 
# During the build installed and changed files are written to a database 
# which allows for easy package creation.
#
#=============================================================================

def build_stage02_package(p)
	$stdout.flush
	p.unpack
	### Dir.chdir(@workdir)
	p.patch
	### Dir.chdir(@workdir)
	p.build(@log_each, @force_stracalyze)
	### Dir.chdir(@workdir)
	if (@run_tests == true)  
		p.test_func
		### Dir.chdir(@workdir)
	end
end

def install_stage02_package(p)
	### Dir.chdir(@workdir)
	p.install(@log_each, @force_stracalyze)
	### Dir.chdir(@workdir)
	p.filecheck
	pb = PackageBuilder.new(@builddir, p.pkg_name, p.pkg_version, @dbh, @sqlite, @unstable)
	pb.create_pkgdesc unless File.exists?(@builddir + "/stage02/build/" + p.pkg_name + "-" + p.pkg_version + ".xml")
	### Dir.chdir(@workdir)
	p.clean if @clean == true
	if p.pkg_name == @breakpoint
		puts sprintf("%015.4f", Time.now.to_f) + " info  > Stop requested after this package!" + p.pkg_name + "-" + p.pkg_version
		puts sprintf("%015.4f", Time.now.to_f) + " info  > Either it failed or manually requested. Remove the file"
		puts sprintf("%015.4f", Time.now.to_f) + " info  > /tmp/LessLinux_Emergency_Exit before running builder.rb again."
		$stdout.flush
		system("touch /tmp/LessLinux_Emergency_Exit")
	end
end

def run_stage_two
	[ "/stage02","/stage02/build"  ].each { |d|
		unless File.exists?(@builddir + d)
			Dir.mkdir(@builddir + d)
		end
	}
	pkg_count = @stage_two_objs.size
	# Stage 02 abfrühstücken
	# Alle Scripte in stage02 suchen
	# Download first
	@stage_two_objs.each { |i|
		i.download
	}
	# Store built packages (just package_names) in an array
	built_packages = Array.new
	# Build a hash with package => [ deps ]
	pkg_deps = Hash.new
	# Build a list of packages where no dependencies are given
	pkg_nodeps = Array.new
	# Now extract dependencies
	@stage_two_objs.each { |i|
		if i.depends_on.nil?
			pkg_nodeps.push(i)
		else
			pkg_deps[i] = i.depends_on
		end
	}
	# Ready to build? mount!
	5.times { SecondStage.umount(@builddir) }
	SecondStage.mount(@builddir, @srcdir)
	# FIXME!
	# remove packages that have dependencies to packages that are not in the pkg_deps list
	all_dep_strings = Array.new
	all_pkg_strings = Array.new
	pkg_deps.each { |k,v|
		all_pkg_strings.push(k.pkg_name)
		all_dep_strings = all_dep_strings + v
	}
	unresolved_pkgs = all_dep_strings - all_pkg_strings
	# Re-build the Hash
	pkg_deps = Hash.new
	pkg_nodeps = Array.new
	@stage_two_objs.each { |i|
		if i.depends_on.nil?
			pkg_nodeps.push(i)
		elsif (i.depends_on & unresolved_pkgs).size > 0
			puts sprintf("%015.4f", Time.now.to_f) + " dep    > Unresolved dependencies for " + i.pkg_name + ": " +  (i.depends_on & unresolved_pkgs).join(", ")
			pkg_nodeps.push(i)
		else	
			pkg_deps[i] = i.depends_on
		end
	}
	###### Check if we have circular dependencies
	already_resolved = []
	cyclical_found = []
	@stage_two_objs.each { |k|
		unless k.depends_on.nil?
		# pkg_deps.each { |k,v|
			rescount = 0
			circle_found = false
			depends_on_circle = false
			remaining_deps = k.depends_on.clone
			# remaining_deps = (remaining_deps + v).compact
			while (remaining_deps.size > 0 && rescount < 1_000_000 && circle_found == false && depends_on_circle == false) 
				rescount += 1
				x = remaining_deps.pop
				if already_resolved.include?(x)
					### 
				elsif cyclical_found.include?(x)
					depends_on_circle = true
				else
					@stage_two_objs.each { |i|
						rescount += 1
						if x == i.pkg_name
							circle_found = true if !i.depends_on.nil? && i.depends_on.include?(k.pkg_name)
							if  i.depends_on.nil?
								puts sprintf("%015.4f", Time.now.to_f) + " dep    > WARN: Package " +  k.pkg_name + " depends on package with nil dependencies!"
								# k.depends_on = nil
							else
								# puts i.pkg_name
								# puts remaining_deps.join(", ")
								# puts pkg_deps[i].join(", ")
								# $stdout.flush
								# puts k.pkg_name
								# puts i.pkg_name
								# puts remaining_deps.join(", ")
								# puts pkg_deps[i].join(", ")
								remaining_deps = (remaining_deps + pkg_deps[i]).compact.uniq
							end
						end
					}
				end
			end
			if circle_found == true
				puts sprintf("%015.4f", Time.now.to_f) + " dep    > ERROR: Cyclical dependency found for " + k.pkg_name
				cyclical_found.push(k.pkg_name)
			elsif depends_on_circle == true
				puts sprintf("%015.4f", Time.now.to_f) + " dep    > ERROR: Depends on cyclical dependency " + k.pkg_name
				cyclical_found.push(k.pkg_name)
			elsif remaining_deps.size > 0
				puts sprintf("%015.4f", Time.now.to_f) + " dep    > WARN: Probable cyclical dependency for " + 
				k.pkg_name + ", remaining: " + k.depends_on.join(", ")
			elsif remaining_deps.size < 1
				puts sprintf("%015.4f", Time.now.to_f) + " dep    > OK: Dependencies resolve cleanly for " + k.pkg_name
				already_resolved.push(k.pkg_name)
			end
			$stdout.flush
		end
	}
	
	if cyclical_found.size > 0
		puts sprintf("%015.4f", Time.now.to_f) + " dep    > ERROR: Cyclical dependencies found!"
		puts sprintf("%015.4f", Time.now.to_f) + " dep    > Please either resolve or try to build with --force-linear!"
		raise "ErrorCyclicalDeps"
	end
	### raise "DebugBreakPoint"
	# now build all packages until the list is empty
	# use a build queue to build with a broadth first rule 
	build_queue = Array.new
	# use one variable to signalize if we have to stop
	
	if @force_linear == false
		t= Array.new
		m = Mutex.new
		work_in_progress = Array.new
		# s = Mutex.new
		@stage_two_objs.each { |k|
			if !k.depends_on.nil? && k.depends_on.size < 1
				puts sprintf("%015.4f", Time.now.to_f) + " queue  > Dependencies for package " + k.pkg_name + " resolved, init queue"
				build_queue.push(k)
			end
		}
		puts sprintf("%015.4f", Time.now.to_f) + " queue  > Start " + @thread_count.to_s + " threads for stage02 build!"
		0.upto(@thread_count - 1) { |n|
			work_in_progress[n] = nil 
			sleep n
			t[n] = Thread.new { 
			while pkg_deps.size > 0 && !File.exist?("/tmp/LessLinux_Emergency_Exit")
				puts sprintf("%015.4f", Time.now.to_f) + " queue  > " + (pkg_count - built_packages.size ).to_s + " packages of " +  pkg_count.to_s + " left to build"
				slept = false
				while build_queue.size < 1 && !File.exist?("/tmp/LessLinux_Emergency_Exit") && pkg_deps.size > 0
					puts sprintf("%015.4f", Time.now.to_f) + " queue  > Thread #" + n.to_s + " Zzzzzzzzzzz...." if slept == false
					slept = true
					$stdout.flush
					sleep @thread_count * 10 
				end
				puts sprintf("%015.4f", Time.now.to_f) + " queue  > Queue size " + build_queue.size.to_s
				$stdout.flush
				p = build_queue.shift
				# current_builds.push(p.pkg_name)
				if p.nil? # || work_in_progress.include?(p.pkg_name)
					puts sprintf("%015.4f", Time.now.to_f) + " queue  > Thread #" + n.to_s + " Ooops, someone was faster "
					$stdout.flush
					# work_in_progress[n] = nil
				else
					work_in_progress[n] = p.pkg_name
					puts sprintf("%015.4f", Time.now.to_f) + " queue  > Thread #" + n.to_s + " build " + p.pkg_name + " from dependency queue "
					$stdout.flush
					build_stage02_package(p)
					m.synchronize { 
						puts sprintf("%015.4f", Time.now.to_f) + " queue  > Thread #" + n.to_s + 
							" install " + p.pkg_name + " from dependency queue "
						$stdout.flush
						install_stage02_package(p)
						built_packages.push(p.pkg_name)
						pkg_deps.delete(p)
						work_in_progress[n] = nil
						pkg_deps.each { |k,v|
							if (v - built_packages).size < 1 && 
								!built_packages.include?(k.pkg_name) && 
								!work_in_progress.include?(k.pkg_name)
								build_queue.push(k)
								build_queue.uniq!
								puts sprintf("%015.4f", Time.now.to_f) + " queue  > Dependencies for package " +
									k.pkg_name + " resolved, queueing " unless  build_queue.include?(k)
								$stdout.flush
							end
						}
					}
				end
			end
			puts sprintf("%015.4f", Time.now.to_f) + " queue  > Nothing left to do for thread #" + n.to_s + " Exiting..."
			}
		}
		t.each { |i| i.join }
	end
	
	@stage_two_objs.each { |i|
		unless built_packages.include?(i.pkg_name)
			puts sprintf("%015.4f", Time.now.to_f) + " list   > Building " + i.pkg_name + " from list of packages without recorded dependencies "
			build_stage02_package(i)
			install_stage02_package(i)
			if File.exist?("/tmp/LessLinux_Emergency_Exit")
				5.times { SecondStage.umount(@builddir) }
				raise "EmergencyExit"
			end
		end
	}
	@stage_two_objs.each { |i|
		# FIXME: The Regexp implementation seems to leak memory. When analyzing ~100,000,000 lines
		# of strace log 5 to 50 bytes lost per line really sum up. Thus when trying again use the code 
		# from the stand alone strace script to the stracalyzer functions in buildSecondstage.rb
		# i.stracalyze
		if ( @stracalyze == true && 
			!File.exists?(@builddir + "/stage02/build/" + i.pkg_name + "-" + i.pkg_version + ".dependencies.txt") ) || @force_stracalyze == true
			system "ruby -I. builder/stracalyzer.rb " + @builddir + " " + i.pkg_name + " " + i.pkg_version
		end
		# raise "BreakpointReached"
	}
	5.times { SecondStage.umount(@builddir) }
end

#=============================================================================
#
# In stage three files from the second stage are transfered to the "assemble 
# directory". This directory is later converted to SquashFS files that make up
# your final distribution. Since just relevant subpackages are used, the 
# result is much smaller than the content of the build directory.
#
#=============================================================================

def run_stage_three
	stage_three_dirs = [ "/stage03", "/stage03/initramfs", "/stage03/build", "/stage03/squash", "/stage03/cdmaster" ]
	stage_three_dirs.each { |d|
		if File.exists?(@builddir + d)
			puts sprintf("%015.4f", Time.now.to_f) +
				" error > Please remove the directories " + 
				stage_three_dirs.join(" ") + " in " + @builddir + " first!"
			$stdout.flush
			raise "SomeDirectoriesTooMuch"
		end
	}
	stage_three_dirs.each { |d|
		unless File.exists?(@builddir + d)
			Dir.mkdir(@builddir + d)
		end
	}
	# Stage 03 (Bau des Initramfs und der Container) abfruehstuecken
	# Alle Scripte in Stage03 suchen

	stage_three_scripts = []
	stage_three_objs = []
	Dir.foreach("scripts/stage03") { |f|
		# fcomps = File.split(f)
		if (f =~ /\d+.*\.xml$/ )
			if @unstable == true && File.exists?("scripts/stage03.unstable/" + f)
				stage_three_scripts.push(f)
			else
				stage_three_scripts.push(f)
			end
		end
	}
	pkg_list = nil
	pkg_list = read_pkglist(@pkg_list_file) unless @pkg_list_file.nil?
	debug_pkglist = File.new("/tmp/lesslinux_" + @build_timestamp + "_all_packages.txt", 'w') 
	debug_skipped = File.new("/tmp/lesslinux_" + @build_timestamp + "_skipped_packages.txt" , 'w')
	stage_three_scripts.sort.each { |i| 
		# puts sprintf("%015.4f", Time.now.to_f) + " info   > Parsing " + i
		# $stdout.flush
		this_stage_three_obj = ThirdStage.new(i, @srcdir, @builddir, @unpriv, "stage03", @dbh, @unstable, @sqlite, @skiplist)
		debug_pkglist.write(this_stage_three_obj.pkg_name + "\n")
		if pkg_list.nil? || pkg_list.include?(this_stage_three_obj.pkg_name)   
			stage_three_objs.push(this_stage_three_obj)
		else
			debug_skipped.write(this_stage_three_obj.pkg_name + "\n")
		end
	}
	debug_pkglist.close
	debug_skipped.close
	# Download first
	stage_three_objs.each { |i| i.download }
	# Calculate dependencies
	additional_dependencies = Array.new
	provided_libs = Array.new
	provided_links = Array.new
	stage_three_objs.each { |i|
		deps = i.calculate_deps
		libs = i.show_libs
		links = i.show_links
		additional_dependencies = additional_dependencies  + deps
		provided_libs = provided_libs + libs
		provided_links = provided_links + links
		#puts "foreign deps for " + i.pkg_name + " " + deps.join(", ")
	}
	
	#puts "=== Dumping deps"
	#additional_dependencies.each  {  |a|
	#	puts a
	#}
	#puts "=== Found links"
	#provided_links.each  {  |a|
	#	puts a
	#}
	
	# raise "DebugBreakPoint"
	additional_dependencies.uniq!
	still_required_libs = additional_dependencies.clone
	additional_dependencies.each { |i|
		provided_libs.each { |l|
			unless l.index(i).nil?
				still_required_libs.delete(i)
			end
		}
		provided_links.each { |l|
			unless l.index(i).nil?
				still_required_libs.delete(i)
			end
		}
	}

	libs_stage_two = Array.new
	links_stage_two = Array.new
	really_unmet_deps = still_required_libs.clone
	additional_deps = Array.new
	@stage_two_objs.each { |i|
		still_required_libs.each { |j|
			i.show_libs.each { |k|
				provided_file = File.split(k)[1]
				# puts "GCC contains " + provided_file if i.pkg_name == "gcc"
				#if provided_file.index(j) == 0 || j.index(provided_file) == 0
				#	really_unmet_deps.delete(j)
				#	additional_deps.push(i)
				#	puts "Found required lib: " + j + " as " + provided_file + " in stage two package " + i.pkg_name
				#end
				unless k.index(j).nil?
					really_unmet_deps.delete(j)
					additional_deps.push(i)
					puts sprintf("%015.4f", Time.now.to_f) + " info   > Found required lib: " + j + " in stage two package " + i.pkg_name
					$stdout.flush
				end
			}
		}
		links = i.show_links
	}

	additional_names = additional_deps.collect { |x| x.pkg_name + "-" + x.pkg_version }
	puts sprintf("%015.4f", Time.now.to_f) + " info   > Adding required packages (minimal): " + additional_names.uniq.join(", ")
	puts sprintf("%015.4f", Time.now.to_f) + " info   > Still unmet dependencies: " + really_unmet_deps.uniq.join(", ")
	$stdout.flush
	
	# Now check for stage03 objects that do not have corresponding - i.e. name and 
	# version matches - stage02 objects
	
	stage2missing = Array.new
	
	stage_three_objs.each { |i|
		vers_match = false
		@stage_two_objs.each { |j| vers_match = true if i.pkg_name == j.pkg_name && i.pkg_version == j.pkg_version }
		vers_match = true if i.allowfail == true
		if vers_match == false 
			stage2missing.push(i.pkg_name + " " + i.pkg_version)
		end
		# raise "CorrespondingStage2Missing" if vers_match == false 
	}
	
	if stage2missing.size > 0
		stage2missing.each { |i|
			puts sprintf("%015.4f", Time.now.to_f) + " error  > " + i + " matching stage2 package missing!"
		}
		$stdout.flush
		raise "CorrespondingStage2Missing"
	end

	# If a full install is selected, instead of doing a package  install
	if @full_image == true
		ThirdStage.full_install(@builddir)
	end

	# Retrieve the list of files to skip
	skipfiles = ThirdStage.read_skiplist(@skiplist)

	# raise "DebugBreakPoint"
	# Install all regularily selected stage 03 packages

	pkglist = File.new(@builddir + "/stage03/pkglist.txt", "w")
	stage_three_objs.each { |i|
		i.makedirs
		i.touchfiles
		i.scriptgen
		i.assemble_modules(@kernel_file, @modmodel)
		i.unpack
		### Dir.chdir(@workdir)
		i.install
		### Dir.chdir(@workdir)
		i.pkg_install( ["minimal","bin","config","localization","tzdata","uncategorized","skel"], ["de", "en"], skipfiles) unless @full_image == true
		pkglist.write("full\t" + i.pkg_name + "\t" + i.pkg_version + "\n")
		### Dir.chdir(@workdir)
	}
	# Create temporary buildscripts for stage02 packages not yet included
	additional_deps.uniq.each { |a|
		a.dump_stage03_script
		dep = ThirdStage.new("added-dependency-" + a.pkg_name + ".xml", @srcdir, @builddir, @unpriv, "stage03", @dbh, @unstable, @sqlite)
		dep.unpack
		### Dir.chdir(@workdir)
		dep.install
		### Dir.chdir(@workdir)
		dep.pkg_install( ["minimal"], ["de", "en"], skipfiles) unless @full_image == true
		### Dir.chdir(@workdir)
		pkglist.write("mini\t" + a.pkg_name + "\t" + a.pkg_version + "\n")
	}
	pkglist.close
	
	# raise "DebugBreakPoint"
	# ThirdStage.create_softlinks(@builddir, @dbh)
	ThirdStage.create_softlinks_ng(@builddir, @dbh) unless @full_image == true
	ThirdStage.copy_firmware(@builddir)
	# raise "DebugBreakPoint"
	ThirdStage.create_squashfs(@builddir, @kernel_file)
	
	# include branding
	ThirdStage.write_branding(@builddir, @branding, @brand_file, @build_timestamp)
	ThirdStage.sync_overlay(@builddir, @overlays + "/initramfs")
	system("mv \"" + @builddir + "/stage03/pkglist.txt\" \"" +   @builddir + "/stage03/initramfs/etc/lesslinux/\"")
	#raise "DebugBreakPoint"
	
	# Build the initramfs' for kernel version independent stuff
	initramfs_assembly = InitramfsAssembly.new(@srcdir, @builddir, @dbh, "config/initramfs.xml")
	initrd_location = initramfs_assembly.build

	# Build the initramfs for kernel modules
	mod_locations = initramfs_assembly.assemble_modules(@kernel_file, @modmodel)

	# Synchronize Kernel and initramfs for modules to the CD build directory 
	# Build the ISO-Image
	bootable = BootdiskAssembly.new(@srcdir, @builddir, @dbh, "config/initramfs.xml", @build_timestamp, @branding)
	BootdiskAssembly.sync_overlay(@builddir, @overlays + "/bootdisk")
	BootdiskAssembly.copy_version(@builddir)
	#raise "DebugBreakPoint"
	unless @skip_stages.include?("bootconf")
		bootable.create_isoimage(@kernel_file, true)
	else
		bootable.create_isoimage(@kernel_file, false)
	end
	# clean up, remove added dependencies:
	system("rm scripts/stage03/added-dependency-*")
	
end

#=============================================================================
#
# And now run it...
#
#=============================================================================

if (@check_updates == true)
	get_stage_one_objs.each { |o| o.check_updates }
	@stage_two_objs.each { |o| o.check_updates }
else
	unless @skip_stages.include?("1")
		run_stage_one
		save_stage_one
	end
	run_stage_two unless @skip_stages.include?("2")
	run_stage_three unless @skip_stages.include?("3")
end

# @dbh.close
# puts $debug_messages.join("\n")
