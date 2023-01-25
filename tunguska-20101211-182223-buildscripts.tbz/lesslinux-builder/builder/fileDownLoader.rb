

class FileDownLoader

	@buildfile = nil
	@srcdir = nil
	@xfile = nil
	@dltokens = nil

	def initialize  (buildfile, srcdir)
		puts '-> parsing ' + buildfile
		@buildfile = buildfile
		@srcdir = srcdir
		dltokens = []
		# begin 
			@xfile = REXML::Document.new(File.new(@buildfile))
			@xfile.elements.each("llpackages/package/sources/file") { |f|
				pkgname = f.elements["pkg"].text
				shahash = f.elements["pkg"].attributes["sha1"]
				dllocations = Array.new
				f.elements.each("mirror") { |m| dllocations.push(m.text) }
				dllocations = dllocations + [ "http://distfiles.lesslinux.org/", "http://distfiles.lesslinux.org/old/" ]
				srctoken = SingleSourceFile.new(@srcdir, pkgname, shahash, dllocations)
				dltokens.push(srctoken)
			}
			@dltokens = dltokens
		# rescue
		#	puts '*> failed parsing downloads for ' + buildfile
		# end
	end

	def download
		@dltokens.each { |d| d.download }
	end
	

end