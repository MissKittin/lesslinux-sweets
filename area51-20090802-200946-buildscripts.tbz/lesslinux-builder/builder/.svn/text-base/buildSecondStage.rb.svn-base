

class SecondStage < AnyStage
	
	def build
		if File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/build.success") 
			puts "-> previous build of " + @pkg_name + " successful"
		else
			puts "-> building " + @pkg_name + " " + @pkg_version 
			Dir.chdir(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version)
			# Mount functions
			mscript = File.open("mount.sh", 'w')
			mscript.write("for i in /dev /tmp\ndo\nmount -o bind ${i} ${CHROOTDIR}${i}\ndone\n")
			mscript.write("mount -o bind " + @builddir + "/stage02/build ${CHROOTDIR}/llbuild/build\n")
			mscript.write("mount -o bind " + @srcdir + " ${CHROOTDIR}/llbuild/src\n")
			mscript.write("mount -vt devpts devpts ${CHROOTDIR}/dev/pts\n")
			mscript.write("mount -vt tmpfs shm ${CHROOTDIR}/dev/shm\n")
			mscript.write("mount -vt proc proc ${CHROOTDIR}/proc\n")
			mscript.write("mount -vt sysfs sysfs ${CHROOTDIR}/sys\n")
			mscript.close
			# Umount functions
			uscript = File.open("umount.sh", 'w')
			uscript.write("for i in /dev/pts /dev/shm /dev /proc /tmp /llbuild/src /llbuild/build /sys \ndo\numount ${CHROOTDIR}${i}\ndone\n\n")
			uscript.write("for i in /dev/pts /dev/shm /dev /proc /tmp /llbuild/src /llbuild/build /sys \ndo\n")
			uscript.write("if mountpoint ${CHROOTDIR}${i}\n then \n")
			uscript.write(" \n sleep 10 \n umount ${CHROOTDIR}${i} \n fi \n");
			uscript.write("if mountpoint ${CHROOTDIR}${i}\n then \n")
			uscript.write(" \n echo \"${CHROOTDIR}${i} still mounted, please unmount and press enter\" \n read z \n fi \n");
			uscript.write("done\n");
			uscript.write("if mountpoint ${CHROOTDIR}/llbuild/build \n then \n")
			uscript.write(" \n echo \"${CHROOTDIR}/llbuild/build still mounted, please unmount and press enter\" \n read z \n fi \n");
			uscript.write("if mountpoint ${CHROOTDIR}/llbuild/src \n then \n")
			uscript.write(" \n echo \"${CHROOTDIR}/llbuild/src still mounted, please unmount and press enter\" \n read z \n fi \n");
			uscript.close
			# Script to enter chroot and trigger the buildscript
			bscript = File.open("chroot_and_build.sh", 'w')
			bscript.write("#!/bin/bash\n")
			bscript.write("CHROOTDIR='" + @builddir + "/stage01/chroot'; export CHROOTDIR\n")
			bscript.write(". mount.sh\n")
			bscript.write('chroot ${CHROOTDIR} /tools/bin/env -i HOME=/root TERM="$TERM" PS1=\'\u:\w\$ \'' + 
				' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin ' + 
				' /tools/bin/bash /llbuild/build/' + @pkg_name +  "-" + @pkg_version + "/build_in_chroot.sh\n")
			bscript.write(". umount.sh\n")
			bscript.close
			File.chmod(0755, "chroot_and_build.sh")
			# Write the buildscript to be triggered
			tscript = File.open("build_in_chroot.sh", 'w')
			tscript.write("#!/bin/bash\n")
			tscript.write("cd /llbuild/build/" + @pkg_name + "-" + @pkg_version + "\n\n")
			tscript.write(". common_vars\n")
			tscript.write("SRCDIR=/llbuild/src; export SRCDIR\n")
			tscript.write("LC_ALL=POSIX; export LC_ALL\n\n")
			tscript.write(@xfile.elements["llpackages/package/build"].cdatas[0])
			tscript.write("\n\n")
			tscript.close
			File.chmod(0755, "build_in_chroot.sh")
			retval = system("./chroot_and_build.sh")
			if (retval == true)
				File.open("build.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			end
		end
	end

	def install
		if File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/install.success") 
			puts "-> previous installation of " + @pkg_name + "-" + @pkg_version + " successful"
		else
			puts "-> installing " + @pkg_name + " " + @pkg_version 
			Dir.chdir(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version)
			# Script to enter chroot and trigger the installscript
			bscript = File.open("chroot_and_install.sh", 'w')
			bscript.write("#!/bin/bash\n")
			bscript.write("CHROOTDIR='" + @builddir + "/stage01/chroot'; export CHROOTDIR\n")
			bscript.write(". mount.sh\n")
			bscript.write('chroot ${CHROOTDIR} /tools/bin/env -i HOME=/root TERM="$TERM" PS1=\'\u:\w\$ \'' + 
				' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin ' + 
				' /tools/bin/bash /llbuild/build/' + @pkg_name + "-" + @pkg_version + "/install_in_chroot.sh\n")
			bscript.write(". umount.sh\n")
			bscript.close
			File.chmod(0755, "chroot_and_install.sh")
			# Write the installscript to be triggered
			tscript = File.open("install_in_chroot.sh", 'w')
			tscript.write("#!/bin/bash\n")
			tscript.write("cd /llbuild/build/" + @pkg_name + "-" + @pkg_version + "\n\n")
			tscript.write(". common_vars\n")
			tscript.write("SRCDIR=/llbuild/src; export SRCDIR\n")
			tscript.write("LC_ALL=POSIX; export LC_ALL\n\n")
			tscript.write(@xfile.elements["llpackages/package/install"].cdatas[0])
			tscript.write("\n\n")
			tscript.close
			File.chmod(0755, "install_in_chroot.sh")
			retval = system("./chroot_and_install.sh")
			if (retval == true)
				File.open("install.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			end
		end
	end
	
	# test functionality
	def test_func
		if @xfile.elements["llpackages/package/test"].cdatas.size < 1 || File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/test.success") 
			puts '-> skipping tests'
		else
			puts "-> testing " + @pkg_name + " " + @pkg_version 
			Dir.chdir(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version )
			# Script to enter chroot and trigger the testscript
			bscript = File.open("chroot_and_test.sh", 'w')
			bscript.write("#!/bin/bash\n")
			bscript.write("CHROOTDIR='" + @builddir + "/stage01/chroot'; export CHROOTDIR\n")
			bscript.write(". mount.sh\n")
			bscript.write('chroot ${CHROOTDIR} /tools/bin/env -i HOME=/root TERM="$TERM" PS1=\'\u:\w\$ \'' + 
				' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin ' + 
				' /tools/bin/bash /llbuild/build/' + @pkg_name + "-" + @pkg_version + "/test_in_chroot.sh\n")
			bscript.write(". umount.sh\n")
			bscript.close
			File.chmod(0755, "chroot_and_test.sh")
			# Write the testscript to be triggered
			tscript = File.open("test_in_chroot.sh", 'w')
			tscript.write("#!/bin/bash\n")
			tscript.write("cd /llbuild/build/" + @pkg_name +  "-" + @pkg_version + "\n\n")
			tscript.write(". common_vars\n")
			tscript.write("SRCDIR=/llbuild/src; export SRCDIR\n")
			tscript.write("LC_ALL=POSIX; export LC_ALL\n\n")
			tscript.write(@xfile.elements["llpackages/package/test"].cdatas[0])
			tscript.write("\n\n")
			tscript.close
			File.chmod(0755, "test_in_chroot.sh")
			retval = system("./chroot_and_test.sh")
			puts '=> type "Yes" if the result of the test of ' + @pkg_name + " " + @pkg_version + " looks reasonable "
			rstring = $stdin.read
			if (rstring.strip == "Yes" )
				File.open("test.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			else 
				raise "TestFailed"
			end
		end
	end
	
	def filecheck
		# Read all files
		ignore_dirs = [ "/dev", "/tools", "/proc", "/tmp" ]
		if File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/check.success") 
			puts "-> previous check of " + @pkg_name + " successful"
		else
			modified_files = 0
			expdir = File.expand_path(@builddir + "/stage01/chroot")
			reprexp = Regexp.new('^' + expdir)
			f_tuples = Hash.new
			d_tuples = Hash.new
			l_tuples = Hash.new
			# Query all files from database
			qstring = "SELECT fname, fsize, modtime, ftype FROM llfiles WHERE ftype='f' ORDER BY fname ASC, modtime ASC "
			# puts qstring
			resset = @dbh.query(qstring)
			resset.each { |r|
				fpath = r[0].sub(reprexp, '').strip
				f_tuples[fpath] = [ r[1].to_i , r[2].to_i ]
			}
			qstring = "SELECT fname, modtime, ftype FROM llfiles WHERE ftype='d' ORDER BY fname ASC, modtime ASC "
			resset = @dbh.query(qstring)
			resset.each { |r|
				fpath = r[0].sub(reprexp, '').strip
				d_tuples[fpath] = r[1].to_i 
			}
			qstring = "SELECT fname, modtime, ftype FROM llfiles WHERE ftype='l' ORDER BY fname ASC, modtime ASC "
			resset = @dbh.query(qstring)
			resset.each { |r|
				fpath = r[0].sub(reprexp, '').strip
				l_tuples[fpath] = r[1].to_i 
			}
			# puts("find " + expdir + " -xdev -type f -printf '%T@ %s %h/%f\\n'")
			# raise "DebugBreakpoint"
			IO.popen("find " + expdir + " -xdev -type f -printf '%T@ %s %h/%f\\n'") { |f|
				while f.gets
					triple = $_.strip.split(' ')
					fpath = triple[2].sub(reprexp, '').strip
					fsize = triple[1].to_i
					modtime = triple[0].to_i
					forbidden = nil
					ignore_dirs.each { |d|
						if fpath.index(d) == 0
							forbidden = true
						end
					}
					if forbidden.nil?
						if f_tuples[fpath].nil?
							# puts ' => checking ' + fpath + ' ' + modtime.to_s + ' nil ' + fsize.to_s + ' nil'
							x = FileChecker.new(fpath, modtime, nil, fsize, nil, 
								expdir, @pkg_name, @pkg_time, @pkg_version, "f", "stage02", @dbh)
							modified_files += x.save
						else
							if f_tuples[fpath][1].to_i != modtime || f_tuples[fpath][0].to_i != fsize
								x = FileChecker.new(fpath, modtime, f_tuples[fpath][1].to_i, fsize, f_tuples[fpath][0].to_i, 
								expdir, @pkg_name, @pkg_time, @pkg_version, "f", "stage02", @dbh)
								modified_files += x.save
							end
						end
					end
				end
			}
			# raise "DebugBreakpoint"
			# Query all dirs from database
			# Read all dirs
			IO.popen("find " + expdir + " -xdev -type d -printf '%T@ %s %h/%f\n'") { |f|
				while f.gets
					triple = $_.strip.split(' ')
					fpath = triple[2].sub(reprexp, '').strip
					modtime = triple[0].to_i
					# if d_tuples[fpath].to_i != modtime
					# just check for dirs that did not exist before
					if d_tuples[fpath].nil?
						x = FileChecker.new(fpath, modtime, d_tuples[fpath].to_i, 0, 0, 
							expdir, @pkg_name, @pkg_time, @pkg_version, "d", "stage02", @dbh)
						# modified_files += x.save
					end
				end
			}
			# Read all Softlinks
			# Query all softlinks from database
			IO.popen("find " + expdir + " -xdev -type l -printf '%T@ %s %h/%f\n'") { |f|
				while f.gets
					triple = $_.strip.split(' ')
					fpath = triple[2].sub(reprexp, '').strip
					modtime = triple[0].to_i
					# if l_tuples[fpath].to_i != modtime
					# just check for softlinks that did not exist before
					# FIXME: also check for changed softlinks!
					if l_tuples[fpath].nil?
						x = FileChecker.new(fpath, modtime, l_tuples[fpath].to_i, 0, 0, 
							expdir, @pkg_name, @pkg_time, @pkg_version, "l", "stage02", @dbh)
						# modified_files += x.save
					end
				end
			}
			if modified_files > 0
				File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/check.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			else
				puts '==> ERROR: No modified files found! Please check the build descriptions!'
				raise "NoModifiedFilesFound"
			end
		end
	end
	
	def dump_stage03_script
		# dumpfile = REXML::Document.new(File.new("scripts/stage03/added-dependency-" + @pkg_name + ".xml"))
		doc = REXML::Document.new
		doc.add_element("llpackages")
		skel = doc.root.add_element("package")
		skel.add_attribute("name", @pkg_name)
		skel.add_attribute("version", @pkg_version)
		skel.add_attribute("class", "autodep")
		outfile = File.open("scripts/stage03/added-dependency-" + @pkg_name + ".xml", "w")
		doc.write( outfile, 4)
		outfile.close
	end
end
