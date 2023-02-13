#!/usr/bin/ruby

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
require "mysql"
require 'optparse' 

# require 'rdoc/usage'

$debug_messages = Array.new

@run_tests = true
@skip_stages = Array.new

opts = OptionParser.new 
opts.on('-n', '--no-test')    { @run_tests = false }
opts.on('-s', '--skip-stages', :REQUIRED )    { |i| @skip_stages = i.split(",") }
opts.parse!

# raise "DebugBreakPoint"

xcfg = File.new( "config/general.xml" )
cfg = REXML::Document.new xcfg
@cfgroot = cfg.root
@srcdir = @cfgroot.elements["sourcedir"].text
@builddir = @cfgroot.elements["builddir"].text
@unpriv = @cfgroot.elements["unpriv"].text
@dbuser = @cfgroot.elements["database/user"].text
@dbname = @cfgroot.elements["database/dbname"].text
@dbpass = @cfgroot.elements["database/pass"].text
@workdir = Dir.pwd

# Connect to database
@dbh = Mysql.real_connect("localhost",  @dbuser, @dbpass, @dbname)

# Check for existence of  builddir and sourcedir
unless File.exists?(@builddir) && File.ftype(@builddir) == "directory"
	puts "=> please create the directory " + @builddir + " first"
	raise "NoBuilddir"
end
unless File.exists?(@srcdir) && File.ftype(@srcdir) == "directory"
	puts "=> please create the directory " + @srcdir + " first"
	raise "NoBuilddir"
end

# objects for stage 02 are also needed by stage three
@stage_two_scripts = []
@stage_two_objs = []
Dir.foreach("scripts/stage02") { |f|
	if (f =~ /\d+.*\.xml$/ )
		@stage_two_scripts.push f
	end
}
@stage_two_scripts.sort.each { |i| 
	@stage_two_objs.push(SecondStage.new(i, @srcdir, @builddir, @unpriv, "stage02", @dbh))
}


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
		puts "=> directory/softlink tools already exists -- exiting!"
		raise "SoftlinkAlreadyThere"
	end
	File.symlink(@builddir + "/stage01/chroot/tools", "/tools")
	[ "/stage01", "/stage01/build","/stage01/chroot","/stage01/chroot/tools" ].each { |d|
		unless File.exists?(@builddir + d)
			Dir.mkdir(@builddir + d)
		end
	}
	# Stage 01 abfrühstücken
	# Alle Scripte in stage01 suchen
	stage_one_scripts = []
	stage_one_objs = []
	Dir.foreach("scripts/stage01") { |f|
		if (f =~ /\d+.*\.xml$/ )
			stage_one_scripts.push f
		end
	}
	stage_one_scripts.sort.each { |i| stage_one_objs.push(FirstStage.new(i, @srcdir, @builddir, @unpriv, "stage01", @dbh)) }
		# Download first
		stage_one_objs.each { |i| i.download }
		# Unpack
		stage_one_objs.each { |i|
		i.unpack
		Dir.chdir(@workdir)
		i.patch
		Dir.chdir(@workdir)
		i.build
		Dir.chdir(@workdir)
		i.install
		Dir.chdir(@workdir)
		i.filecheck
		Dir.chdir(@workdir)
	}
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
		Dir.chdir(@builddir + "/stage01")
		system "tar cvjf chroot.tbz chroot"
		system "mysqldump --add-drop-table --password='" + @dbpass + "' " + 
			" -u '" + @dbuser + "' '" + @dbname + "' > chroot.sql "   
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

def run_stage_two
	[ "/stage02","/stage02/build"  ].each { |d|
		unless File.exists?(@builddir + d)
			Dir.mkdir(@builddir + d)
		end
	}
	# Stage 02 abfrühstücken
	# Alle Scripte in stage02 suchen

	
	# Download first
	@stage_two_objs.each { |i| i.download }
	@stage_two_objs.each { |i|
		i.unpack
		Dir.chdir(@workdir)
		i.patch
		Dir.chdir(@workdir)
		i.build
		Dir.chdir(@workdir)
		if (@run_tests == true)  
			i.test_func
			Dir.chdir(@workdir)
		end
		i.install
		Dir.chdir(@workdir)
		i.filecheck
		pb = PackageBuilder.new(@builddir, i.pkg_name, i.pkg_version, @dbh)
		pb.create_pkgdesc
		Dir.chdir(@workdir)
	}
	
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
			puts "=> please remove the directories " + stage_three_dirs.join(" ") + " in " + @builddir + " first!"
			raise "SomeDirectoriesTooMuch"
		end
	}
	stage_three_dirs.each { |d|
		unless File.exists?(@builddir + d)
			Dir.mkdir(@builddir + d)
		end
	}
	# Stage 03 (Bau des Initramfs und der Container) abfrühstücken
	# Alle Scripte in Stage03 suchen

	stage_three_scripts = []
	stage_three_objs = []
	Dir.foreach("scripts/stage03") { |f|
		if (f =~ /\d+.*\.xml/ )
			stage_three_scripts.push f
		end
	}

	stage_three_scripts.sort.each { |i| stage_three_objs.push(ThirdStage.new(i, @srcdir, @builddir, @unpriv, "stage03", @dbh)) }
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
				unless k.index(j).nil?
					really_unmet_deps.delete(j)
					additional_deps.push(i)
					puts "Found required lib: " + j + " in stage two package " + i.pkg_name
				end
			}
		}
		links = i.show_links
	}

	additional_names = additional_deps.collect { |x| x.pkg_name + "-" + x.pkg_version }
	puts "=> adding required packages (minimal): " + additional_names.uniq.join(", ")
	puts "=> still unmet dependencies: " + really_unmet_deps.uniq.join(", ")

	# raise "DebugBreakPoint"
	# Install all regularily selected stage 03 packages

	stage_three_objs.each { |i|
		i.makedirs
		i.touchfiles
		i.scriptgen
		i.assemble_modules("config/kernels.xml")
		i.unpack
		Dir.chdir(@workdir)
		i.install
		Dir.chdir(@workdir)
		i.pkg_install( ["minimal","bin","config","localization","tzdata","uncategorized","skel"], ["de", "en"])
		Dir.chdir(@workdir)
	}

	# Create temporary buildscripts for stage02 packages not yet included

	additional_deps.uniq.each { |a|
		a.dump_stage03_script
		dep = ThirdStage.new("added-dependency-" + a.pkg_name + ".xml", @srcdir, @builddir, @unpriv, "stage03", @dbh)
		dep.unpack
		Dir.chdir(@workdir)
		dep.install
		Dir.chdir(@workdir)
		dep.pkg_install( ["minimal"], ["de", "en"])
		Dir.chdir(@workdir)
	}

	# raise "DebugBreakPoint"
	ThirdStage.create_softlinks(@builddir, @dbh)
	ThirdStage.copy_firmware (@builddir)
	# raise "DebugBreakPoint"
	ThirdStage.create_squashfs(@builddir)

	# Build the initramfs' for kernel version independent stuff
	initramfs_assembly = InitramfsAssembly.new(@srcdir, @builddir, @dbh, "config/initramfs.xml")
	initrd_location = initramfs_assembly.build

	# Build the initramfs for kernel modules
	mod_locations = initramfs_assembly.assemble_modules("config/kernels.xml")

	# Synchronize Kernel and initramfs for modules to the CD build directory 
	# Build the ISO-Image
	bootable = BootdiskAssembly.new(@srcdir, @builddir, @dbh, "config/initramfs.xml")
	BootdiskAssembly.sync_overlay(@builddir, "/mnt/archiv/LessLinux/overlays/bootdisk")
	bootable.create_isoimage("config/kernels.xml")

end

unless @skip_stages.include?("1")
	run_stage_one
	save_stage_one
end
run_stage_two unless @skip_stages.include?("2")
run_stage_three unless @skip_stages.include?("3")

@dbh.close

puts $debug_messages.join("\n")


