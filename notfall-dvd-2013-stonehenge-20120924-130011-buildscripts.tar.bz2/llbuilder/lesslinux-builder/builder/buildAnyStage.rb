
require 'hpricot'
require 'net/http'
require 'net/https'

class AnyStage
	
	def initialize (filename, sourcedir, builddir, unpriv, stage, dbh, unstable, sqlite, skiplist=nil, legacy=false, failpackages=[] )
		@buildfile = filename
		@srcdir = sourcedir
		@builddir = builddir
		@stage = stage
		@unstable = unstable
		@legacy = legacy
		@sqlite = sqlite
		@skiplist = Array.new
		@failpackages = failpackages
		@target_type = "chroot"
		if !skiplist.nil? && File.exist?(skiplist)
			@skiplist = File.read(skiplist).split("\n")
		end
		if File.exists?("scripts/" + @stage + ".legacy/" + @buildfile) && @legacy == true
			@downloader = FileDownLoader.new("scripts/" + @stage + ".legacy/" + @buildfile, @srcdir)
			@xfile = REXML::Document.new(File.new("scripts/" + @stage + ".legacy/" + @buildfile))
		elsif File.exists?("scripts/" + @stage + ".unstable/" + @buildfile) && @unstable == true
			@downloader = FileDownLoader.new("scripts/" + @stage + ".unstable/" + @buildfile, @srcdir)
			@xfile = REXML::Document.new(File.new("scripts/" + @stage + ".unstable/" + @buildfile))
		else
			@downloader = FileDownLoader.new("scripts/" + @stage + "/" + @buildfile, @srcdir)
			@xfile = REXML::Document.new(File.new("scripts/" + @stage + "/" + @buildfile))
		end
		@pkg_name = @xfile.elements["llpackages/package"].attributes["name"]
		@pkg_version = @xfile.elements["llpackages/package"].attributes["version"]
		@allowfail = false if @xfile.elements["llpackages/package"].attributes["allowfail"].nil?
		if @xfile.elements["llpackages/package"].attributes["allowfail"].to_s == "yes"
			@allowfail = true
		end
		unless @xfile.elements["llpackages/package"].attributes["install"].nil?
			@target_type =  @xfile.elements["llpackages/package"].attributes["install"].to_s
		end
		@strip = true
		begin
			@strip = false if @xfile.elements["llpackages/package"].attributes["strip"].strip == "no"
		rescue
		end
		@provides_deps = true
		begin
			@provides_deps = false if @xfile.elements["llpackages/package"].attributes["providedeps"].strip == "no"
		rescue
		end
		@depends_on = nil
		unless @xfile.elements["llpackages/package/builddeps"].nil?
			@depends_on = Array.new
			@xfile.elements.each("llpackages/package/builddeps/dep") { |d|
				@depends_on.push(d.text.strip)
			}
		end
		@workdir = Dir.pwd
		@unpriv = unpriv
		@dbh = dbh
		@pkg_time = Time.new.to_i
		@show_lib_cache = nil
		### $debug_messages.push("==> Initializing " + stage.to_s + " package: " + @pkg_name + " version: " + @pkg_version ) 
	end
	attr_reader :pkg_name, :pkg_version, :xfile, :allowfail, :depends_on, :skiplist, :legacy, :unstable, :target_type
	
	def download
		@downloader.download
	end
	
	def fix_version(version)
		@pkg_version = version
	end
	
	def unpack
		unless File.exists?(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version) 
			Dir.mkdir(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version)
		end
		if File.exists?(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/unpack.success") 
			puts sprintf("%015.4f", Time.now.to_f) + " unpack > Previous unpack of " + @pkg_name + " " + @pkg_version + " successful"
		else
			puts sprintf("%015.4f", Time.now.to_f) + " unpack > Unpacking " + @pkg_name + " " + @pkg_version
			$stdout.flush
			### Dir.chdir(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version)
			cvars = File.open(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/common_vars", 'w')
			cvars.write("SRCDIR=\"" + @srcdir + "\"\n")
			cvars.write("PKGVERSION=\"" + @pkg_version + "\"\n")
			cvars.write("PKGNAME=\"" + @pkg_name + "\"\n")
			cvars.write("CHROOT=\"" + @builddir + "/stage01/chroot\"\n")
			cvars.close
			upscript = File.open(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/unpack.sh", 'w')
			upscript.write("#!/bin/bash\n")
			upscript.write("cd " + @builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "\n")
			upscript.write(". common_vars\n")
			begin
				upscript.write(@xfile.elements["llpackages/package/unpack"].cdatas[0])
			rescue
				upscript.write("# Nothing to do here! \n")
			end
			upscript.write("\n# END\n")
			upscript.close
			retval = system("bash " + @builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/unpack.sh")
			if (retval == true)
				File.open(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/unpack.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			end
		end
	end
	
	def clean
		if File.exists?(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/clean.success") 
			puts sprintf("%015.4f", Time.now.to_f) + " clean  > Previous cleaning of " + @pkg_name + " " + @pkg_version + " successful"
		else
			puts sprintf("%015.4f", Time.now.to_f) + " clean  > Cleaning " + @pkg_name + " " + @pkg_version
			$stdout.flush
			upscript = File.open(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/clean.sh", 'w')
			upscript.write("#!/bin/bash\n")
			upscript.write("rm -rf '" + @builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + ".destdir'\n")
			upscript.write("cd '" + @builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "'\n")
			upscript.write(". common_vars\n")
			begin
				upscript.write(@xfile.elements["llpackages/package/clean"].cdatas[0])
			rescue
				puts sprintf("%015.4f", Time.now.to_f) + " clean  > Failed for " + @pkg_name + " " + @pkg_version + " (no clean section found)"
				$stdout.flush
				upscript.write("# Nothing to do here! \n")
				upscript.write("exit 1 \n")
			end
			upscript.write("\n# END\n")
			upscript.close
			retval = system("bash " + @builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/clean.sh")
			if (retval == true)
				File.open(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/clean.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			end
		end
	end
	
	def patch(log=false)
		if @xfile.elements["llpackages/package/unpack"].cdatas.size < 1
			puts sprintf("%015.4f", Time.now.to_f) + " patch  > Skipping patches for " + @pkg_name + " " + @pkg_version
			$stdout.flush
		else
			if File.exists?(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/patch.success")
				puts sprintf("%015.4f", Time.now.to_f) + " patch  > Patches already applied for " + @pkg_name + " " + @pkg_version
				$stdout.flush
			else
				puts sprintf("%015.4f", Time.now.to_f) + " patch  > Applying patches for " + @pkg_name + " " + @pkg_version
				$stdout.flush
				### Dir.chdir(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version )
				pscript =  File.open(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/patch.sh", 'w')
				pscript.write("#!/bin/bash\n")
				pscript.write("cd " + @builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "\n")
				pscript.write(". common_vars\n")
				begin
					pscript.write(@xfile.elements["llpackages/package/patch"].cdatas[0])
				rescue
					pscript.write("# Nothing to do here \n")
				end
				pscript.write("\n# END\n")
				pscript.close
				if (log == true)
					 retval = system("bash " + @builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/patch.sh > " + 
						@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + ".patch.log 2>&1")
				else
					retval = system("bash " + @builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/patch.sh")
				end
				if (retval == true)
					File.open(@builddir + "/" + @stage + "/build/" + @pkg_name + "-" + @pkg_version + "/patch.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
				end
			end 
		end
	end
	
	def show_libs 
		return Array.new if @provides_deps == false
		return @show_lib_cache unless @show_lib_cache.nil?
		# resset = @dbh.query("SELECT fname FROM llfiles WHERE stage='stage02' " + 
		#	" AND pkg_name='" + @dbh.escape_string(@pkg_name) + "' " + 
		#	" AND pkg_version='" + @dbh.escape_string(@pkg_version) + "' " + 
		#	" AND cleaned_type LIKE 'linux_x86_so_%' ")
		sqlite_resset = @sqlite.query( "SELECT fname FROM llfiles WHERE stage='stage02' " + 
			" AND pkg_name=? AND pkg_version=? AND cleaned_type LIKE 'linux_x86_so_%' ", 
			[ SQLite3::Database.quote(@pkg_name), SQLite3::Database.quote(@pkg_version) ] )
		# libset = Array.new
		sqlite_libset = Array.new
		# resset.each { |i| libset.push(i[0].strip) }
		sqlite_resset.each { |i| sqlite_libset.push(i[0].strip) }
		@show_lib_cache = sqlite_libset.sort.uniq
		return @show_lib_cache
	end	
	
	def show_links 
		# resset = @dbh.query("SELECT fname FROM llfiles WHERE stage='stage02' " + 
		#	" AND pkg_name='" + @dbh.escape_string(@pkg_name) + "' " + 
		#	" AND ftype='l' ")
		sqlite_resset = @sqlite.query("SELECT fname FROM llfiles WHERE stage='stage02' " + 
			" AND pkg_name=? AND ftype='l' ", [ SQLite3::Database.quote(@pkg_name) ] )
		# libset = Array.new
		sqlite_libset = Array.new
		# resset.each { |i| libset.push(i[0].strip) }
		sqlite_resset.each { |i| sqlite_libset.push(i[0].strip) }
		return sqlite_libset.sort.uniq
	end

	# Check if updates are available

	def check_updates
		update_found = false
		version_check = false
		version_found = nil
		@xfile.elements.each("llpackages/package/sources/check/page") { |page|
			begin
			resp = Net::HTTP.get_response(URI.parse(page.attributes["html"]))
			pagecontent = resp.body
			versions = Array.new
			hrefs = Array.new
			page.elements.each("atext") { |at|
				begin
					versions.push(at.attributes["linktext"].strip)
				rescue
				end
				begin
					hrefs.push(at.attributes["href"].strip)
				rescue
				end
			}
			hdoc = Hpricot.parse(pagecontent)
			(hdoc/:a).each { |a|
				version_check = true
				versions.each { |v|
					unless a.inner_text.strip[v].nil?
					# if versions.include?(a.inner_text.strip)
						update_found = true
						version_found = a.inner_text.strip
						puts sprintf("%015.4f", Time.now.to_f) + " check  > NEWER VERSION: " + @buildfile + 
							" current: " + @pkg_name + " " + @pkg_version + " found: " + 
							version_found
							$stdout.flush
					end
				}	
				if !a.attributes["href"].nil? && hrefs.include?(a.attributes["href"].strip)
					update_found = true
					version_found = a.attributes["href"].strip
					puts sprintf("%015.4f", Time.now.to_f) + " check  > NEWER VERSION: " + @buildfile + 
							" current: " + @pkg_name + " " + @pkg_version + " found: " + 
							version_found
					$stdout.flush
				end	
			}
			rescue Timeout::Error
				puts sprintf("%015.4f", Time.now.to_f) + " check  > Timeout when checking " + @pkg_name + " " + @pkg_version
			rescue
			end
		}
		# <manualcheck date="20110101" page="http://ftp.gnu.org/gnu/guile/ http://www.gnu.org/software/guile/" />
		@xfile.elements.each("llpackages/package/sources/manualcheck") { |check|
			datestr = check.attributes["date"]
			begin
				date = Time.utc(datestr[0..3], datestr[4..5], datestr[6..7])
			rescue
				date = Time.utc(1970, 1, 2)
			end
			interval = check.attributes["interval"].to_i
			if (date.to_i + (interval * 24 * 60 * 60) < Time.now.to_i)
				puts sprintf("%015.4f", Time.now.to_f) + " check  > MANUAL CHECK : " + @buildfile + " current: " + @pkg_name + " " + @pkg_version + " RECOMMENDED! " + check.attributes["page"]				
			end
			version_check = true
		}
		puts sprintf("%015.4f", Time.now.to_f) + " check  > VERSION CHECK: " + @buildfile + " current: " + @pkg_name + " " + @pkg_version + " FAILED!" if version_check == false
	end

	def build
		
	end

	def install
		
	end
	
	def filecheck
		
	end
	
end