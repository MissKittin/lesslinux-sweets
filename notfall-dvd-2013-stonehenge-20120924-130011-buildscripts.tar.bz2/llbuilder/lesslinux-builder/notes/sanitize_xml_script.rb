#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"
require "digest/sha1"

xfile = ARGV[0]
raise "NoFileSpecified" if xfile.nil?

doc= REXML::Document.new(File.new(xfile).read)
if doc.elements["llpackages/package"].attributes["install"].nil?
	puts "DESTDIR:  " + xfile + " does not specify installation to destdir"
end
if doc.elements["llpackages/package/sources/manualcheck"].nil?
	puts "MANCHK:   " + xfile + " does not specify date for manual check"
else
	# chkdate = doc.elements["llpackages/package/sources/manualcheck"].attributes["date"].to_i 
end
if doc.elements["llpackages/package/sources/check"].nil?
	puts "AUTOCHK:  " + xfile + " does not specify URLs for automatic check"
end
if doc.elements["llpackages/package/clean"].nil?
	puts "CLEAN:    " + xfile + " does not specify clean section"
end
if doc.elements["llpackages/package/builddeps"].nil?
	puts "BUILDDEP: " + xfile + " does not specify dependencies"
end
