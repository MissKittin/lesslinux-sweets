#!/usr/bin/ruby
# encoding: utf-8

require 'sqlite3'

db = ARGV[0]
sqlite = SQLite3::Database.new(db)
# CREATE TABLE knownfiles (id INTEGER PRIMARY KEY ASC, pkg_name VARCHAR(80), pkg_version VARCHAR(40), fname TEXT, fileout TEXT);
# CREATE TABLE llfiles (id INTEGER PRIMARY KEY ASC, ftype CHAR(4), fsize INTEGER(18), modtime INTEGER(12), fowner INTEGER(6), fgroup INTEGER(6), fmode INTEGER(6), sha1sum CHAR(40), file_output TEXT, link_target TEXT, cleaned_type VARCHAR(256), pkg_name VARCHAR(80), pkg_version VARCHAR(40), pkg_time INTEGER(12), sub_pkg VARCHAR(40), stage VARCHAR(40), fname TEXT);

packages_by_size = Hash.new
total_files = 0

qstring = "SELECT distinct pkg_name FROM llfiles "
resset = sqlite.query(qstring)
resset.each { |r|
	# puts "Found package: " + r[0]
	q2 = "SELECT COUNT(fname) FROM llfiles WHERE pkg_name='#{r[0]}' AND ftype='f' AND stage='stage02'"
	r2 = sqlite.query(q2)
	r2.each { |n|
		puts "Found package: " + r[0] + " " + n[0].to_s + " files"
		total_files += n[0].to_i
		if packages_by_size.has_key?(n[0].to_i) 
			packages_by_size[n[0].to_i].push(r[0])
		else
			packages_by_size[n[0].to_i] = [ r[0] ]
		end
	}
}

puts "Total files: " + total_files.to_s 
testcount = 0
info50 = false
info75 = false
info80 = false
info90 = false
info95 = false

sizes = packages_by_size.keys.sort
sizes.reverse.each { |n|
	packages_by_size[n].each { |p|
		puts p + " " + n.to_s
		testcount += n
		if testcount > total_files / 2 && info50 == false
			puts "====== 50% reached!" 
			info50 = true
		end
		if testcount.to_f > total_files.to_f * 0.75 && info75 == false
			puts "====== 75% reached!" 
			info75 = true
		end
		if testcount.to_f > total_files.to_f * 0.80 && info80 == false
			puts "====== 80% reached!" 
			info80 = true
		end
		if testcount.to_f > total_files.to_f * 0.90 && info90 == false
			puts "====== 90% reached!" 
			info90 = true
		end
		if testcount.to_f > total_files.to_f * 0.95 && info95 == false
			puts "====== 95% reached!" 
			info95 = true
		end
	}
}