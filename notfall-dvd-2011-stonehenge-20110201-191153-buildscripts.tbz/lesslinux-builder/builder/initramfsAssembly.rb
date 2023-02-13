
class InitramfsAssembly
	
	def initialize (srcdir, builddir, dbh, cfgfile)
		@srcdir =srcdir
		@builddir = builddir
		@dbh = dbh
		@cfgfile = cfgfile
		# @xfile = REXML::Document.new(File.new(cfgfile))
		@tstamp = Time.new.to_i
	end

	def build
		puts "=> building initramfs"
		puts "-> creating list of files"
		system("bash ./bin/scripts/gen_initramfs_list.sh " + @builddir + "/stage03/initramfs > /tmp/initramfs.list." + @tstamp.to_s )
		puts "-> packing initramfs"
		system("./bin/i686/gen_init_cpio /tmp/initramfs.list." +  @tstamp.to_s + " | gzip -c > " + @builddir + "/stage03/initramfs.gz" )
		return @builddir + "/stage03/initramfs.gz"
	end

	def assemble_modules(cfgfile, modmodel)
		kcfg = REXML::Document.new(File.new(cfgfile))
		rsyncable = ""
		rsyncable = "--rsyncable" if system("gzip --help | grep -q rsyncable")
		kcfg.elements.each("kernels/kernel") { |k|
			klong = k.elements["long"].text
			kname = k.attributes["short"]
			puts "=> adding modules for " + klong
			if modmodel == "new"
				system("mkdir -p " + @builddir + "/stage03/cpio-" + kname + "/lesslinux/modules")
				system("mv " + @builddir + "/stage03/squash/m" + kname + ".sqs " + 
					@builddir + "/stage03/cpio-" + kname + "/lesslinux/modules/" + klong + ".sqs")
			end
			puts '-> creating list of files '
			system("bash ./bin/scripts/gen_initramfs_list.sh " + @builddir + "/stage03/cpio-" + kname + " > /tmp/cpio-" + kname + ".list." + @tstamp.to_s )
			puts '-> packing initramfs for ' +  klong
			system("./bin/i686/gen_init_cpio /tmp/cpio-" + kname + ".list." +  @tstamp.to_s + " | gzip -c " + rsyncable + " > " + @builddir + "/stage03/cpio-" + kname + ".gz" )
		}
	end

end