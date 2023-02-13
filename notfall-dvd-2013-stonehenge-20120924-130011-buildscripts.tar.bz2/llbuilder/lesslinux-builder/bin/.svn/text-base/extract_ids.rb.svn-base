#!/usr/bin/ruby

# traverse and extract USB and PCI IDs from kernel sources 
# Start in the directory given as argument

require "rexml/document"
require "digest/sha1"
require "mysql"
require 'optparse' 

@startdir = "."

opts = OptionParser.new 
opts.on('-d', '--directory', :REQUIRED )    { |i| @startdir = i }
opts.parse!

@dirs_to_check = [ @startdir ]
@found_files = []
@pci_files = []
@xmlout  = REXML::Document.new
@xmlout.add_element("deviceids")
@pci_xmlout = REXML::Document.new
@pci_xmlout.add_element("deviceids")

def grep_usb_ids (fname)
	return false if fname =~ /\.txt$/
	f = File.open(fname)
	flines = f.readlines
	usb_reg = /\{\s*USB_DEVICE\s*\(\s*(0x[A-Fa-f0-9]{3,4})\s*,\s*(0x[A-Fa-f0-9]{3,4})s*\)/
	pci_reg = /\{\s*PCI_DEVICE\s*\(\s*(0x[A-Fa-f0-9]{3,4})\s*,\s*(0x[A-Fa-f0-9]{3,4})s*\)/
	lcount = 0
	devids = Array.new
	pciids = Array.new
	flines.each { |l|
		usb_match = usb_reg.match(l)  
		pci_match = pci_reg.match(l)
		unless usb_match.nil?
			unless usb_match[1].to_i(16) == 0 && usb_match[2].to_i(16) == 0
				# puts lcount.to_s + " vendor: "  + match[1].to_i(16).to_s(16) + " device: " + match[2].to_i(16).to_s(16) + " in " + l
				devids.push( [ usb_match[1].to_i(16).to_s(16), usb_match[2].to_i(16).to_s(16) ] )
			end
		end
		unless pci_match.nil?
			unless pci_match[1].to_i(16) == 0 && pci_match[2].to_i(16) == 0
				puts lcount.to_s + " vendor: "  + pci_match[1].to_i(16).to_s(16) + " device: " + pci_match[2].to_i(16).to_s(16) + " in " + l
				pciids.push( [ pci_match[1].to_i(16).to_s(16), pci_match[2].to_i(16).to_s(16) ] )
			end
		end
		lcount += 1
	}
	# find out, if name of the object corresponds with source name
	objs = []
	pci_objs = []
	if devids.size > 0 || pciids.size > 0
		begin
			fdir = File.split(fname)[0]
			mkf = File.open(fdir + "/Makefile")
			mkflines = mkf.readlines
		rescue
			mkflines = []
		end
		obj_reg = /([a-zA-Z0-9_\-]*)\.o($|\s)/
	end
	if devids.size > 0
		mkflines.each { |l|
			match = obj_reg.match(l)
			unless match.nil?
				objs.push match[1].strip
				puts match[1]
			end
		}
	end
	if devids.size > 0
		@found_files.push(fname)
		skel = @xmlout.root.add_element("usbmodule")
		skel.add_attribute("path", fname.split(@startdir + "/")[1])
		skel.add_attribute("module", File.split(fname)[1].gsub(/\.h$/, "").gsub(/\.c$/, ""))
		unless objs.include? File.split(fname)[1].gsub(/\.h$/, "").gsub(/\.c$/, "").strip
			skel.add_attribute("mkfmodules", objs.join(" "))
		end
		devids.each { |d|
			device = skel.add_element("dev")
			device.add_attribute("vendor", d[0])
			device.add_attribute("id", d[1])
		}
	end
	if pciids.size > 0
		@pci_files.push(fname)
		skel = @pci_xmlout.root.add_element("pcimodule")
		skel.add_attribute("path", fname.split(@startdir + "/")[1])
		skel.add_attribute("module", File.split(fname)[1].gsub(/\.h$/, "").gsub(/\.c$/, ""))
		unless objs.include? File.split(fname)[1].gsub(/\.h$/, "").gsub(/\.c$/, "").strip
			skel.add_attribute("mkfmodules", pci_objs.join(" "))
		end
		pciids.each { |d|
			device = skel.add_element("dev")
			device.add_attribute("vendor", d[0])
			device.add_attribute("id", d[1])
		}
	end
end

while @dirs_to_check.size > 0
	checkme = @dirs_to_check.pop
	Dir.foreach(checkme) { |i|
		unless i == "." || i == ".."
			# puts i
			if File.ftype(checkme + "/" + i) == "directory" 
				#puts "dir:  " + checkme + "/" + i
				@dirs_to_check.push(checkme + "/" + i)
			elsif File.ftype(checkme + "/" + i) == "file" 
				#puts "file: " + checkme + "/" + i
				grep_usb_ids(checkme + "/" + i)
			end
		end
	}
end

fcount = 0
@found_files.sort.uniq.each { |f|
	#puts f
	fcount += 1
}

puts fcount.to_s + " source files found"
 
outfile = File.open("/tmp/usb_modules.xml", 'w')
@xmlout.write( outfile, 4)

pci_outfile = File.open("/tmp/pci_modules.xml", 'w')
@pci_xmlout.write( pci_outfile, 4)