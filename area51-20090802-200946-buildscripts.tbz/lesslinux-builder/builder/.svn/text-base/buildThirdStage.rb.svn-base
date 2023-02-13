
class ThirdStage < AnyStage
	
	def calculate_deps
		resset = @dbh.query("SELECT fname FROM llfiles WHERE stage='stage02' " + 
			" AND pkg_name='" + @dbh.escape_string(@pkg_name) + "' " + 
			" AND pkg_version='" + @dbh.escape_string(@pkg_version) + "' " + 
			" AND ( cleaned_type LIKE 'linux_x86_exe_%' OR cleaned_type LIKE 'linux_x86_so_%' ) ")
		binset = Array.new
		# All objects provided
		resset.each { |i| binset.push(i[0].strip) }
		# All objects needed
		depset = Array.new
		binset.each { |b|
			IO.popen("chroot " +   @builddir + "/stage01/chroot ldd " + b ) { |f|
				while f.gets
					depset.push($_.split[0])
				end
			}
		}
		depset.uniq!
		depset.delete("/lib/ld-linux.so.2")
		depset.delete("libc.so.6")
		depset.delete("linux-gate.so.1")
		depset.delete("statically")
		resdeps = depset.clone
		depset.each { |d|
			binset.each { |b|
				unless b.index(d).nil?
					resdeps.delete(d)
				end
			}
		}
		return resdeps
	end

	def makedirs
		@xfile.elements.each("llpackages/dirs/dir") { |i|
			system("install -m " + i.attributes["mode"] + " -d " + @builddir + "/stage03/initramfs" + i.text )
		}
	end

	def touchfiles
		@xfile.elements.each("llpackages/files/file") { |i|
			File.new(@builddir + "/stage03/initramfs" + i.text , 'w').close
			File.chmod(i.attributes["mode"].to_i(8), @builddir + "/stage03/initramfs" + i.text )
			File.chown(i.attributes["owner"].to_i, i.attributes["group"].to_i, @builddir + "/stage03/initramfs" + i.text )
		}
		@xfile.elements.each("llpackages/links/softlink") { |i|
			system("ln -sv " + i.attributes["target"] + " " + @builddir + "/stage03/initramfs/" + i.text  )
		}
	end
	
	def scriptgen
		@xfile.elements.each("llpackages/scripts/scriptdata") { |i|
			outfile = File.open(@builddir + "/stage03/initramfs" + i.attributes["location"], 'w')
			outfile.write(i.cdatas[0])
			outfile.write("\n")
			outfile.close
			File.chmod(i.attributes["mode"].to_i(8), 
				@builddir + "/stage03/initramfs" + i.attributes["location"])
			File.chown(i.attributes["owner"].to_i, 
				i.attributes["group"].to_i, 
				@builddir + "/stage03/initramfs" + i.attributes["location"])
		}
		@xfile.elements.each("llpackages/scripts/modlist") { |i|
			provides = i.attributes["provides"]
			hwenv = i.attributes["hwenv"]
			outfile = File.open(@builddir + "/stage03/initramfs/etc/rc.confd/" + provides + "." + hwenv + ".modules" , 'w')
			i.elements.each("module") { |j| outfile.write(j.text + "\n") }
			outfile.close
		}
	end
	
	def install
		if File.exists?(@builddir + "/stage03/build/" + @pkg_name + "/install.success") 
			puts "-> previous installation of " + @pkg_name + " successful"
		else
			puts "-> installing " + @pkg_name + " " + @pkg_version 
			Dir.chdir(@builddir + "/stage03/build/" + @pkg_name + "-" + @pkg_version)
			# Script to enter chroot and trigger the installscript
			iscript = File.open("install.sh", 'w')
			iscript.write("#!/bin/bash\n")
			iscript.write("INITRAMFS='" + @builddir + "/stage03/initramfs'; export INITRAMFS\n")
			iscript.write("SQUASHFS='" + @builddir + "/stage03/squash'; export INITRAMFS\n")
			iscript.write(". common_vars\n")
			begin
				iscript.write(@xfile.elements["llpackages/package/install"].cdatas[0])
			rescue
				iscript.write("# Nothing to do here!\n")
			end
			iscript.write("\n\n")
			iscript.close
			File.chmod(0755, "install.sh")
			retval = system("./install.sh")
			if (retval == true)
				File.open("install.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			end
		end
	end
	
	# Install prepared files from the file list generated in the last step
	
	def pkg_install ( subpkgs, langs )
		# Currently just check for automatically generated file from the last build
		# FIXME: Add prepared/modified versions later
		# FIXME: Add possibility to skip later
		pfile = nil
		if File.exists?("scripts/pkg_content/" + @pkg_name + "-" + pkg_version + ".xml" )
			pfile = REXML::Document.new(File.new("scripts/pkg_content/" + @pkg_name + "-" + pkg_version + ".xml", "r"))
		elsif File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + pkg_version + ".xml" ) 
			pfile = REXML::Document.new(File.new(@builddir + "/stage02/build/" + @pkg_name + "-" + pkg_version + ".xml" , "r"))
		elsif xfile.elements["llpackages/package"].attributes["allowfail"].nil?
			puts "=> trying to install nonexistent package! " + @pkg_name + "-" + pkg_version
			puts "   You might want to add the attribute 'allowfail=yes'!"
			raise "StageThreeInstallError"
		else
			return 0
		end
		installed_files = 0
		initramfsdirs = ["etc", "static",  "var" ]
		ignoredirs = [ "boot",  "dev", "home", "llbuild", "media", "mnt", "proc", "root", "sys", "tmp", "tools" ]
		squashdirs = [ "bin",  "lib",  "opt", "sbin",  "srv", "usr" ]
		pfile.elements.each("pkgdesc/subpackage") { |s|
			s.elements.each("softlink") { |l|
				path = l.attributes["path"].strip
				initramfsdirs.each{ |i|
					if l.attributes["path"].index(i) == 1
						#system("tar -C " + @builddir + "/stage01/chroot/ -c '" + path.sub(/^\//, '') + 
						#"' -f - | tar -C " + @builddir + "/stage03/initramfs/ -xvf - ")
					end
				}
				squashdirs.each{ |i|
					if l.attributes["path"].index(i) == 1
						#system("tar -C " + @builddir + "/stage01/chroot/ -c '" + path.sub(/^\//, '') + 
						#"' -f - | tar -C " + @builddir + "/stage03/squash/ -xvf - ")
					end
				}
			}
			if subpkgs.include?(s.attributes["name"].strip)
				s.elements.each("file") { |l|
					path = l.attributes["path"].strip
					initramfsdirs.each{ |i|
						if l.attributes["path"].index(i) == 1
							system("tar -C " + @builddir + "/stage01/chroot/ -c '" + path.sub(/^\//, '') + 
							"' -f - | tar -C " + @builddir + "/stage03/initramfs/ -xvf - ")
							system("strip " + @builddir + "/stage03/initramfs/" + path.sub(/^\//, ''))
							installed_files += 1
						end
					}
					squashdirs.each{ |i|
						if l.attributes["path"].index(i) == 1
							system("tar -C " + @builddir + "/stage01/chroot/ -c '" + path.sub(/^\//, '') + 
							"' -f - | tar -C " + @builddir + "/stage03/squash/ -xvf - ")
							system("strip " + @builddir + "/stage03/squash/" + path.sub(/^\//, ''))
							installed_files += 1
						end
					}
				}
			end
			s.elements.each("directory") { |d|
				initramfsdirs.each{ |i|
					if d.attributes["path"].strip.index(i) == 1
						unless system("test -d '"+ @builddir + "/stage03/initramfs" + d.attributes["path"].strip  + "'")
							puts "-> create nonexistent directory " + d.attributes["path"].strip
							system("mkdir -p -m " + d.attributes["mode"].slice(-3 .. -1) + " '" +
								@builddir + "/stage03/initramfs" + d.attributes["path"].strip  + "'")
						end
					end
				}
				squashdirs.each{ |i|
					if d.attributes["path"].strip.index(i) == 1
						unless system("test -d '"+ @builddir + "/stage03/squash" + d.attributes["path"].strip  + "'")
							puts "-> create nonexistent directory " + d.attributes["path"].strip
							system("mkdir -p -m " + d.attributes["mode"].slice(-3 .. -1) + " '" + 
								@builddir + "/stage03/squash" + d.attributes["path"].strip  + "'")
						end
					end
				}
			}
		}
		if installed_files < 1 && @xfile.elements["llpackages/package"].attributes["allowfail"].nil?
			puts "=> installation did not result in new files!"
			puts "   either check the pkg-file " + @pkg_name + "-" + pkg_version + ".xml"
			puts "   or remove the package from being included in stage03!"
			puts "   You might want to add the attribute 'allowfail=yes'!"
			raise "StageThreeInstallError"
		end
	end

	def assemble_modules (kconfig)
		kcfg = REXML::Document.new(File.new(kconfig))
		kcfg.elements.each("kernels/kernel") { |k|
			klong = k.elements["long"].text
			kname = k.attributes["short"]
			puts "=> adding modules for " + klong
			[ "/", "/static", "/static/modules" ].each { |d|
				begin
					Dir.mkdir( @builddir + "/stage03/cpio-" + kname + d )
				rescue
					puts "->dir seems to exist"
				end
			}
			@xfile.elements.each("llpackages/scripts/modlist") { |i|
				i.elements.each("module") { |j|
					IO.popen("find " + @builddir + "/stage01/chroot/lib/modules/" +  klong + " -type f -name " + j.text + ".ko"  ) { |f|
						while f.gets
							system("rsync -vP " + $_.strip + " " + @builddir + "/stage03/cpio-" + kname + "/static/modules/")
						end
					}
				}
			}
		}
		# raise "DebugBreakPoint"
	end

	
	def ThirdStage.create_softlinks (builddir, dbh )
		# Find all links
		all_links = dbh.query("SELECT DISTINCT fname FROM llfiles WHERE ftype='l' AND fname NOT LIKE '/tools/%' ORDER BY fname ASC" )
		expdir = File.expand_path(builddir + "/stage01/chroot")
			reprexp = Regexp.new('^' + expdir)
		all_softlinks = Array.new
		IO.popen("find " + expdir + " -xdev -type l") { |f|
			while f.gets
				[ "bin",  "lib",  "opt", "sbin",  "srv", "usr" ].each { |d|
					lnk = $_.strip.sub(reprexp, '')
					if lnk.index(d) == 1
						all_softlinks.push $_.strip.sub(reprexp, '')
					end
				}
			end
		}
		# 3 times to guarantee the maximum depth of chained links
		3.times {
			all_softlinks.each { |l|
				unless system("ls -la '"+ builddir + "/stage03/squash" + l.to_s + "' > /dev/null 2>&1 " )
					# find out if parent directory exists
					parentdir = nil
					IO.popen("dirname '" + l.to_s + "' ") { |f|
						while f.gets
							aux_par = $_
							unless aux_par.nil?
								parentdir = aux_par.strip
								puts parentdir
							end
						end
					}
					# find target of softlink
					linktarget = nil
					IO.popen(" ls -la '" + builddir + "/stage01/chroot" + l.to_s + "' ") { |f|
						while f.gets
							aux_tar = $_
							begin
								linktarget = aux_tar.split(' -> ')[1].strip
							rescue 
								puts '=> ls failed: ' +  aux_tar.to_s
							end
						end
					}
					# link if softlink is not vanished
					unless linktarget.nil?
						# create parent directory if necessary
						unless parentdir.nil? 
							system("mkdir -pv '"+ builddir + "/stage03/squash" + parentdir + "' " )
						end
						system("ln -sv '" +   linktarget + "' '" + builddir + "/stage03/squash" + l.to_s + "' ")
					end
				end
			}
		}	
		# first find all Softlinks in busybox' /bin and /sbin
		["/bin/", "/sbin/"].each { |d|
			#puts("LC_ALL=C find " + builddir + "/stage03/initramfs/static" + d + " -type l " + 
			#" -exec file -F ':::::' {} \\\; | grep busybox | awk -F '::::: ' '{print \$1}'")
			IO.popen("LC_ALL=C find " + builddir + "/stage03/initramfs/static" + d + " -type l " + 
			" -exec file -F ':::::' {} \\\; ") { |f|
				while f.gets 
					pin = $_.strip
					if pin["busybox"]
						softlink = pin.split('::::: ')[0].sub(builddir + "/stage03/initramfs/static" + d, '')
						# Check if an according entry exists in /bin, /sbin, /usr/bin, /usr/sbin, /usr/local/bin, /usr/local/sbin, 
						newloc = nil
						[ "/bin/", "/sbin/", "/usr/bin/", "/usr/sbin/", "/usr/local/bin/", "/usr/local/sbin/" ].each { |t|
							if system("test -e " + builddir + "/stage03/squash" + t + softlink) || 
									system("test -f " + builddir + "/stage03/squash" + t + softlink)
								newloc = t + softlink
							end
						}
						if newloc.nil?
							system("ln -s /static/bin/busybox " + builddir + "/stage03/squash" + d + softlink)
						end
					end
				end
			}
		}
	end
	
	def ThirdStage.copy_firmware (builddir)
		system("tar -C " + builddir + "/stage01/chroot/ -c 'lib/firmware' -f - | tar -C " + builddir + "/stage03/squash/ -xvf - ")
	end
	
	def ThirdStage.create_squashfs (builddir)
		mksquashfs = "mksquashfs4"
		squashdirs = [ "bin",  "lib",  "opt", "sbin",  "srv", "usr", "usrbin" ]
		kconfig = "config/kernels.xml"
		kcfg = REXML::Document.new(File.new(kconfig))
		kcfg.elements.each("kernels/kernel") { |k|
			klong = k.elements["long"].text
			kname = k.attributes["short"]
			system("mkdir -p -m 0755 " + builddir + "/stage03/squash/m" + kname )
			system("mkdir -p -m 0755 " + builddir + "/stage03/squash/lib/modules/" + klong )
			system("rsync -aP " + builddir + "/stage01/chroot/lib/modules/" + klong + "/ " +  builddir + "/stage03/squash/m" + kname + "/" )
			system(mksquashfs + " " + builddir + "/stage03/squash/m" + kname + " " + builddir + "/stage03/squash/m" + kname + ".sqs -noappend" )
		}
		# FIXME! FIXME! FIXME!
		system("mv " + builddir + "/stage03/squash/usr/bin " + builddir + "/stage03/squash/usrbin")
		system("mkdir -m 0755 " + builddir + "/stage03/squash/usr/bin")
		
		squashdirs.each { |d|
			if system("test -d " + builddir + "/stage03/squash/" + d)
				system(mksquashfs + " " + builddir + "/stage03/squash/" + d + " " + builddir + "/stage03/squash/" + d + ".sqs -noappend" ) 
			end
		}
	end
	
end
