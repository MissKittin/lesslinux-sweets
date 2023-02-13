

class AnyStage
	
	def initialize (filename, sourcedir, builddir, unpriv, stage, dbh)
		@buildfile = filename
		@srcdir = sourcedir
		@builddir = builddir
		@stage = stage
		@downloader = FileDownLoader.new("scripts/" + @stage + "/" + @buildfile, @srcdir)
		@xfile = REXML::Document.new(File.new("scripts/" + @stage + "/" + @buildfile))
		@pkg_name = @xfile.elements["llpackages/package"].attributes["name"]
		@pkg_version = @xfile.elements["llpackages/package"].attributes["version"]
		@workdir = Dir.pwd
		@unpriv = unpriv
		@dbh = dbh
		@pkg_time = Time.new.to_i
		$debug_messages.push("==> Initializing " + stage.to_s + " package: " + @pkg_name + " version: " + @pkg_version ) 
	end
	attr_reader :pkg_name, :pkg_version, :xfile
	
	def download
		@downloader.download
	end
	
	def unpack
		unless File.exists?(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version) 
			Dir.mkdir(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version)
		end
		if File.exists?(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/unpack.success") 
			puts "-> previous unpacking of " + @pkg_name + " successful"
		else
			puts "-> unpacking " + @pkg_name + " " + @pkg_version 
			Dir.chdir(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version)
			cvars = File.open("common_vars", 'w')
			cvars.write("SRCDIR=\"" + @srcdir + "\"\n")
			cvars.write("PKGVERSION=\"" + @pkg_version + "\"\n")
			cvars.write("PKGNAME=\"" + @pkg_name + "\"\n")
			cvars.close
			upscript = File.open("unpack.sh", 'w')
			upscript.write("#!/bin/bash\n. common_vars\n")
			begin
				upscript.write(@xfile.elements["llpackages/package/unpack"].cdatas[0])
			rescue
				upscript.write("# Nothing to do here! \n")
			end
			upscript.write("\n# END\n")
			upscript.close
			retval = system("bash unpack.sh")
			if (retval == true)
				File.open("unpack.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			end
		end
	end
	
	def patch
		if @xfile.elements["llpackages/package/unpack"].cdatas.size < 1
			puts '-> skipping patches'
		else
			if File.exists?(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/patch.success")
				puts '-> previous patching successful'
			else
				puts '-> patching'
				Dir.chdir(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version )
				pscript =  File.open("patch.sh", 'w')
				pscript.write("#!/bin/bash\n. common_vars\n")
				begin
					pscript.write(@xfile.elements["llpackages/package/patch"].cdatas[0])
				rescue
					pscript.write("Nothing to do here \n")
				end
				pscript.write("\n# END\n")
				pscript.close
				retval = system("bash patch.sh")
				if (retval == true)
					File.open("patch.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
				end
			end 
		end
	end
	
	def show_libs 
		resset = @dbh.query("SELECT fname FROM llfiles WHERE stage='stage02' " + 
			" AND pkg_name='" + @dbh.escape_string(@pkg_name) + "' " + 
			" AND pkg_version='" + @dbh.escape_string(@pkg_version) + "' " + 
			" AND cleaned_type LIKE 'linux_x86_so_%' ")
		libset = Array.new
		resset.each { |i| libset.push(i[0].strip) }
		return libset.sort.uniq
	end	
	
	def show_links 
		resset = @dbh.query("SELECT fname FROM llfiles WHERE stage='stage02' " + 
			" AND pkg_name='" + @dbh.escape_string(@pkg_name) + "' " + 
			" AND ftype='l' ")
		libset = Array.new
		resset.each { |i| libset.push(i[0].strip) }
		return libset.sort.uniq
	end

	def build
		
	end

	def install
		
	end
	
	def filecheck
		
	end
	
end