
class FileChecker
	
	def initialize (file_to_check, modtime, modtime_old, size, size_old, basepath, pkg_name, pkg_time, pkg_version, ftype, stage, dbh)
		@file_to_check = file_to_check.strip
		if file_to_check == ''
			@file_to_check  = '/'
		end
		@fullpath = basepath + "/" + file_to_check.strip
		@basepath = basepath
		@pkg_name = pkg_name
		@pkg_time = pkg_time
		@pkg_version = pkg_version
		@ftype = ftype
		@sha1sum = nil
		@size = size
		@size_old = size_old
		@modtime = modtime
		@modtime_old = modtime_old
		@file_output = ""
		@fmode = 0
		@uid = 0
		@gid = 0
		@dbh = dbh
		@stage = stage
		@ftypes = REXML::Document.new(File.new("config/filetypes.xml"))
	end
	
	def save
		# Search for files with exact matches in name, size, modtime and type
		#qstring = "SELECT fname, fsize, modtime, ftype FROM llfiles " + 
		#	" WHERE " + 
		#	" fsize=" + @size.to_i.to_s + " AND " +
		#	" fname='" + @dbh.escape_string(@file_to_check) + "' AND " +
		#	" modtime=" + @modtime.to_i.to_s + " AND " +
		#	" ftype='" + @ftype + "' "
		# puts qstring
		#resset = @dbh.query(qstring)
		# nothing found, so 
		if @modtime_old.nil? || @modtime_old != @modtime || @size.to_i != @size_old.to_i
			begin 
				if (@ftype == "f")
					@size = File.stat(@fullpath).size
				end
				@modtime = File.stat(@fullpath).mtime.to_i
				@fmode = sprintf("%o", File.stat(@fullpath).mode).to_i
				@uid = File.stat(@fullpath).uid
				@gid = File.stat(@fullpath).gid
			rescue
				puts '  -> softlink, destination not found?'
			end
			if (@ftype == "f")
				if @sha1sum.nil?
					@sha1sum = Digest::SHA1.hexdigest(File.read(@fullpath))
				end
				IO.popen("LC_ALL=POSIX file -F '::::' '" + @fullpath + "' | awk -F ':::: ' '{print $2}' ") { |f|
					@file_output = f.gets.strip
				}
				puts "  -> new/changed file: " + @file_to_check  
			end
			qstring = "INSERT INTO llfiles " + 
			" (fname, fsize, modtime, ftype, " + 
			" fowner, fgroup, fmode, sha1sum, " + 
			" file_output, pkg_name, pkg_version, " + 
			" pkg_time, stage) VALUES ('" +
			@dbh.escape_string(@file_to_check)	+ "', " +
			@size.to_i.to_s + ", " + 
			@modtime.to_i.to_s + ", '" +
			@ftype + "', " +
			@uid.to_s + ", " +
			@gid.to_s + ", " +
			@fmode.to_s + ", '" +
			@sha1sum.to_s + "', '" + 
			@dbh.escape_string(@file_output.to_s) + "', '" +
			@dbh.escape_string(@pkg_name) +  "', '" +
			@dbh.escape_string(@pkg_version) +  "', " +
			@pkg_time.to_i.to_s + ", '" + 
			@stage + "' )"
			# puts qstring
			@dbh.query(qstring)
			# raise "DebugBreakPoint"
			# Classify the file type
			@file_type = nil
			@ftypes.elements.each("filetypes/pathoverride") { |t|
				short_type = t.attributes["short"]
				t.elements.each("pathregexp") { |e|
					r = Regexp.new e.text.strip
					if @file_type.nil? 
						if r =~ @file_to_check
							@file_type = short_type
						end
					end
				}
			}
			@ftypes.elements.each("filetypes/ftype") { |t|
				short_type = t.attributes["short"]
				t.elements.each("fileout") { |e|
					if @file_type.nil? 
						match = @file_output[e.text.strip]
						unless match.nil?
							@file_type = short_type
						end
					end
				}
			}
			unless @file_type.nil?
				qstring = "UPDATE llfiles SET cleaned_type='" + @dbh.escape_string(@file_type) + 
					"' WHERE fname='" + @dbh.escape_string(@file_to_check) + "' "
				@dbh.query(qstring)
			end
			return 1 if @ftype == "f"			
		end
		return 0
	end
	
	def read_all
		
	end
	
end