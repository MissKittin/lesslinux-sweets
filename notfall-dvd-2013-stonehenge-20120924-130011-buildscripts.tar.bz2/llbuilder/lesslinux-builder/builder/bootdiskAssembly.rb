
class BootdiskAssembly 
	
	def initialize (srcdir, builddir, dbh, cfgfile, build_timestamp, branding)
		@srcdir =srcdir
		@builddir = builddir
		@dbh = dbh
		@cfgfile = cfgfile
		# @xfile = REXML::Document.new(File.new(cfgfile))
		@tstamp = Time.new.to_i
		@branding = branding
		@build_timestamp = build_timestamp
	end
	
	def create_isoimage (kconfig, write_bootconf)
		root = @branding.root
		squashdirs = [ "bin",  "lib",  "opt", "sbin",  "srv", "usr", "usrbin" ] # , "optkaspersky" ]
		kcfg = REXML::Document.new(File.new(kconfig))
		[ "/stage03/cdmaster/boot/isolinux/", "/stage03/cdmaster/lesslinux/" ].each { |d|
			system( "mkdir -p " + @builddir  + d )
		}
		puts "=> building ISO-Image"
		puts "-> Syncing squashfs containers"
		mfile = File.new(@builddir  + "/stage03/cdmaster/lesslinux/mount.txt", "w")
		mods = File.new(@builddir  + "/stage03/cdmaster/lesslinux/modules.txt", "w")
		boot_sha = File.new(@builddir  + "/stage03/cdmaster/lesslinux/boot.sha", "w")
		squash_sha = File.new(@builddir  + "/stage03/cdmaster/lesslinux/squash.sha", "w")
		squashdirs.each { |d|
			if system("test -f " + @builddir + "/stage03/squash/" + d + ".sqs")
				system("mv -v "  + @builddir + "/stage03/squash/" + d + ".sqs " + @builddir  + "/stage03/cdmaster/lesslinux/" )
				# FIXME! FIXME! FIXME!
				if d != "usrbin" ### && d != "optkaspersky"
					mfile.write(d + ".sqs /" + d + "\n")
				elsif d == "usrbin"
					mfile.write("usrbin.sqs /usr/bin\n")
				## elsif d == "optkaspersky"
				## 	mfile.write("optkaspersky.sqs /opt/kaspersky\n")
				end
				tmphash = Digest::SHA1.hexdigest(File.read(@builddir  + "/stage03/cdmaster/lesslinux/" + d + ".sqs"))
				squash_sha.write( tmphash.to_s + "  " + d + ".sqs\n" )
			end
		}
		kcfg.elements.each("kernels/kernel") { |k|
			klong = k.elements["long"].text
			kname = k.attributes["short"]
			puts "-> adding kernel and ramdisk for " + klong
			system( "rsync -vP " + @builddir + "/stage03/cpio-" + kname + ".gz " + @builddir  + "/stage03/cdmaster/boot/isolinux/i" + kname + ".img" )
			system( "rsync -vP " + @builddir + "/stage01/chroot/boot/vmlinuz-" + klong + " " + @builddir  + "/stage03/cdmaster/boot/isolinux/l" + kname )
			# system( "rsync -vP " + @builddir + "/stage01/chroot/boot/vmlinuz-" + klong + " " + @builddir  + "/stage03/cdmaster/boot/isolinux/linux" )
			system("rsync -avP "  + @builddir + "/stage03/squash/m" + kname + ".sqs " + @builddir  + "/stage03/cdmaster/lesslinux/" )
			[ "l" + kname, "i" + kname + ".img" ].each { |r|
				tmphash = Digest::SHA1.hexdigest(File.read(@builddir  + "/stage03/cdmaster/boot/isolinux/" + r ))
				boot_sha.write( tmphash.to_s + "  " + r  + "\n")
			}
			if system("test -f " + @builddir  + "/stage03/cdmaster/lesslinux/m" + kname + ".sqs")
				tmphash = Digest::SHA1.hexdigest(File.read(@builddir  + "/stage03/cdmaster/lesslinux/m" + kname + ".sqs"))
				squash_sha.write( tmphash.to_s + "  m" + kname + ".sqs\n" )
			end
			mods.write(klong + " m" + kname + ".sqs" + "\n")
		}
		# memtest_exists = system("test -f " + @builddir + "/stage01/chroot/boot/memtest.bin")
		system( "rsync -vP " + @builddir + "/stage01/chroot/boot/memtest.img " + @builddir  + "/stage03/cdmaster/boot/isolinux/" ) if File.exist?(@builddir + "/stage01/chroot/boot/memtest.img")
		mfile.close
		mods.close
		puts "-> adding kernel independent ramdisk"
		system( "rsync -vP " + @builddir + "/stage03/initramfs.gz " + @builddir  + "/stage03/cdmaster/boot/isolinux/initram.img" )
		system( "rsync -vP ./bin/initramfs/devs.img " + @builddir  + "/stage03/cdmaster/boot/isolinux/devs.img" )
		# FIXME: remove hardcoded overlay!
		# system( "rsync -vP ./bin/initramfs/home.img " + @builddir  + "/stage03/cdmaster/boot/isolinux/home.img" )
		[ "initram.img", "devs.img" ].each { |r|
			tmphash = Digest::SHA1.hexdigest(File.read(@builddir  + "/stage03/cdmaster/boot/isolinux/" + r ))
			boot_sha.write( tmphash.to_s + "  " + r + "\n")
		}
		puts "-> adding minimal bootloader config"
		if write_bootconf == true
		[ "syslinux.cfg", "boot/isolinux/isolinux.cfg" ].each { |c|
			isolinux_cfg = File.open(@builddir  + "/stage03/cdmaster/" + c, 'w')
			isolinux_cfg.write("DEFAULT /boot/isolinux/menu.c32\nTIMEOUT 300\n\nPROMPT 0\n\n" + 
				"MENU TITLE COMPUTERBILD Sicher surfen 2009\nMENU TABMSG  \nMENU AUTOBOOT Automatischer Start in # Sekunde{,n}...\n\n")
			entryid = 0
			kcfg.elements.each("kernels/kernel") { |k|
				klong = k.elements["long"].text
				kname = k.attributes["short"]
				
				# Mediumboot!
				isolinux_cfg.write("LABEL " + entryid.to_s + "\nMENU LABEL Komplettstart\n") #  + klong + "\nMENU DEFAULT\n" )
				isolinux_cfg.write("KERNEL /boot/isolinux/l" + kname + "\n")
				# security=smack pax_softmode=1" )
				isolinux_cfg.write("APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i" + kname + 
					".img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1" +  
					" quiet lang=de " )
				if c == "syslinux.cfg"
					#isolinux_cfg.write(" skipservices=|luksmount|mountcdrom|loadata| ")
					isolinux_cfg.write(" toram=999999999 skipservices=|mountcdrom|loadata|installer|xconfgui|roothash| ")
				else
					#isolinux_cfg.write(" skipservices=|luksmount|mountumass| ")
					isolinux_cfg.write(" toram=800000 ejectonumass=1 skipservices=|installer|xconfgui|roothash| ")
				end
				isolinux_cfg.write(" hwid=unknown \n")
				isolinux_cfg.write("TEXT HELP\n")
				isolinux_cfg.write("  Mit dieser Auswahl laesst sich die Darstellung optimal an Ihren Monitor\n" + 
						   "  anpassen. Ausserdem haben Sie Zugriff auf Ihre Laufwerke, etwa um Dateien\n" + 
						   "  aus dem Internet zu speichern.\nENDTEXT\n\n\n")
				entryid += 1
				
				# Fastboot!
				isolinux_cfg.write("LABEL " + entryid.to_s + "\nMENU LABEL Schnellstart\n") #  + klong + "\n" )
				isolinux_cfg.write("KERNEL /boot/isolinux/l" + kname + "\n")
				# security=smack pax_softmode=1" )
				isolinux_cfg.write("APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i" + kname + 
					".img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1" +  
					" quiet lang=de" )
				if c == "syslinux.cfg"
					#isolinux_cfg.write(" skipservices=|luksmount|mountcdrom|loadata| ")
					isolinux_cfg.write("  toram=999999999 skipservices=|mountcdrom|loadata|hwproto|xconfgui|installer|runtimeconf|roothash| ")
				else
					#isolinux_cfg.write(" skipservices=|luksmount|mountumass| ")
					isolinux_cfg.write(" toram=999999999 ejectonumass=1 skipservices=|hwproto|xconfgui|installer|runtimeconf|roothash| ")
				end
				isolinux_cfg.write(" hwid=unknown \n")
				isolinux_cfg.write("TEXT HELP\n")
				isolinux_cfg.write("  Moechten Sie einfach nur im Internet surfen, waehlen Sie diese Option.\n" + 
						   "  Die Surf-CD startet dann mit einer Standard-Einstellung fuer alle\n" + 
						   "  Monitore und ohne Laufwerkszugriff.\nENDTEXT\n\n\n")
				entryid += 1
				
				# Fastboot with res
				[ "800x600", "1024x600", "1024x768", "1280x800", "1280x1024", "1440x900", "1680x1050" ].each { |res|
					isolinux_cfg.write("LABEL " + entryid.to_s + "\nMENU HIDE\nMENU LABEL Fastboot " + res + "\nMENU INDENT 3\n" )
					isolinux_cfg.write("KERNEL /boot/isolinux/l" + kname + "\n")
					# security=smack pax_softmode=1" )
					isolinux_cfg.write("APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i" + kname + 
						".img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1" +  
						" quiet lang=de toram=999999999 xmode=" + res)
					if c == "syslinux.cfg"
						#isolinux_cfg.write(" skipservices=|luksmount|mountcdrom|loadata| ")
						isolinux_cfg.write(" skipservices=|mountcdrom|loadata|hwproto|xconfgui|installer|runtimeconf|roothash| ")
					else
						#isolinux_cfg.write(" skipservices=|luksmount|mountumass| ")
						isolinux_cfg.write(" ejectonumass=1 skipservices=|hwproto|xconfgui|installer|runtimeconf|roothash| ")
					end
					isolinux_cfg.write(" hwid=unknown \n\n\n")
					entryid += 1
				}
				
				# Installation!
				isolinux_cfg.write("LABEL " + entryid.to_s + "\nMENU LABEL Installation\n" ) # + klong + "\n" )
				isolinux_cfg.write("MENU HIDE\n") if c == "syslinux.cfg"
				isolinux_cfg.write("KERNEL /boot/isolinux/l" + kname + "\n")
				# security=smack pax_softmode=1" )
				isolinux_cfg.write("APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i" + kname + 
					".img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1" +  
					" quiet lang=de toram=9999999999 " )
				if c == "syslinux.cfg"
					#isolinux_cfg.write(" skipservices=|luksmount|mountcdrom|loadata| ")
					isolinux_cfg.write(" skipservices=|mountcdrom|loadata|xconfgui|dbus|wicd|runtimeconf|alsaprepare|ffprep|roothash| ")
				else
					#isolinux_cfg.write(" skipservices=|luksmount|mountumass| ")
					isolinux_cfg.write(" skipservices=|mountumass|xconfgui|dbus|wicd|runtimeconf|alsaprepare|ffprep|roothash| ")
				end
				isolinux_cfg.write(" hwid=unknown \n")
				isolinux_cfg.write("TEXT HELP\n")
				isolinux_cfg.write("  Installieren Sie die Surf-CD auf einem USB-Laufwerk (Speicherstift,\n" + 
						   "  Speicherkarte, Festplatte). Ihre Einstellungen, E-Mails und Dateien\n" + 
						   "  werden dann in einem Datentresor sicher verwahrt.\nENDTEXT\n\n\n")
				entryid += 1
			}
			#if memtest_exists == true
			#	isolinux_cfg.write("LABEL " + entryid.to_s + "\nMENU LABEL Speichertest\n" ) # + klong + "\n" )
			#	isolinux_cfg.write("KERNEL /boot/isolinux/memtest.bin\n")
			#	isolinux_cfg.write("TEXT HELP\n")
			#	isolinux_cfg.write("  Testen Sie Ihren Arbeitsspeicher auf Beschaedigungen.\nENDTEXT\n\n\n")
			#	entryid += 1
			#end
			isolinux_cfg.close
		}
		end
		boot_sha.close
		squash_sha.close
		puts "-> adding bootloader"
		[ "menu.c32", "vesamenu.c32", "isolinux.bin", "ifcpu.c32", "reboot.c32", "chain.c32" ].each { |f|
			# system("rsync -vP ./bin/syslinux/" + f  + ".3.73 " + @builddir  + "/stage03/cdmaster/boot/isolinux/" + f)
			system("install -m 0755 " + @builddir  + "/stage01/chroot/usr/share/syslinux/" + f + " " + @builddir  + "/stage03/cdmaster/boot/isolinux/")
		}
		puts "-> Building squashfs for modules"
		puts "-> mastering ISO"
		oldpwd = Dir.getwd
		Dir.chdir( @builddir  + "/stage03/cdmaster" )
		system("zip -r ../" + root.elements["brandshort"].text.strip + "-" + root.elements["updater/buildidentifier"].text.strip + @build_timestamp + "-boot.zip boot")
		Dir.chdir( @builddir  + "/stage03" )
		system(" mkisofs -input-charset utf8 -r -J -pad -o " + 
			root.elements["brandshort"].text.strip + "-" +
			root.elements["updater/buildidentifier"].text.strip + 
			@build_timestamp + ".iso -b boot/isolinux/isolinux.bin " + 
			" -no-emul-boot -boot-info-table -boot-load-size 4 -c boot/isolinux/boot.cat -V " + root.elements["brandshort"].text.strip + " cdmaster")
		system(" mkisofs -input-charset utf8 -r -J -pad -o " + 
			root.elements["brandshort"].text.strip + "-" +
			root.elements["updater/buildidentifier"].text.strip + 
			@build_timestamp + "-bootonly.iso -b boot/isolinux/isolinux.bin " + 
			" -no-emul-boot -boot-info-table -boot-load-size 4 -c boot/isolinux/boot.cat -V " + root.elements["brandshort"].text.strip + " -m lesslinux cdmaster")
		if system("which perl") && system("test -f " + @builddir  + "/stage01/chroot/usr/share/syslinux/isohybrid.pl") 
			system("perl " + @builddir  + "/stage01/chroot/usr/share/syslinux/isohybrid.pl " +  
				@builddir  + "/stage03/" + root.elements["brandshort"].text.strip + "-" + 
				root.elements["updater/buildidentifier"].text.strip + 
				@build_timestamp + ".iso")
		else
			$stderr.puts "+++> isohybrid not found, resulting ISO will not be bootable from USB stick!"
		end
		Dir.chdir(oldpwd)
	end
	
	def BootdiskAssembly.sync_overlay(builddir, overlaydir)
		system("rsync -avHP '" + overlaydir + "/' " + builddir  + "/stage03/cdmaster/")
	end
	
	def BootdiskAssembly.copy_version(builddir)
		system("mkdir -p " + builddir + "/stage03/cdmaster/lesslinux")
		system("cp -v " + builddir + "/stage03/initramfs/etc/lesslinux/updater/version.txt " + builddir + "/stage03/cdmaster/lesslinux/version.txt")
		# FIMXE: It should be possible to  tell by CLI switch whether ISOhybrid should be stretched or not!
		# system("cp -v " + builddir + "/stage03/initramfs/etc/lesslinux/updater/version.txt " + builddir + "/stage03/cdmaster/lesslinux/stretch.me")
	end
	
end