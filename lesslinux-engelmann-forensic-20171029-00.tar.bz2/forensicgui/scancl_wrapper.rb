#!/usr/bin/ruby
# encoding: utf-8

require 'thread'

# Environment to run in
ENV['LANGUAGE'] = "en_US:en"
ENV['LC_ALL'] = "en_US.UTF-8"
ENV['LANG'] = "en_US.UTF-8"
ENV['PATH'] = '/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin'

# Arguments: retfile, scancl, parameter
retfile = ARGV[0]
scancl = ARGV[1]
params = ARGV
params.delete_at(0)
params.delete_at(0)

# puts params.join(", ")
# puts retfile
# puts scancl

def scan_threaded(retfile, scancl=nil, params=[])
	scancl = "/AntiVir/scancl" if scancl.nil?
	retfile = "/var/run/scancl.ret" if retfile.nil?
	finished = false
	b = Array.new
	b[0] = Thread.new {
		pesc = params.collect { |p| "'#{p}'" }
		system("'#{scancl}' " + pesc.join(" "))
		retval = $?
		e = retval.exitstatus.to_i
		e = 99999 if retval.exitstatus.nil? 
		# $stderr.puts "scancl returned: " + retval.to_s
		File.open(retfile, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f|
			f.write(e.to_s + "\n")
		}
		finished = true
	}
	b[1] = Thread.new {
		while finished == false
			puts "-TickTock-"
			$stdout.flush
			sleep 0.1
		end
	}
	b.each { |i| i.join }
end 

scan_threaded(retfile, scancl, params)
