#!/usr/bin/ruby
# encoding: utf-8

require 'thread'

# Arguments: retfile, command
retfile = ARGV[0]
params = ARGV
params.delete_at(0)

def scan_threaded(retfile, params=[])
	retfile = "/var/run/generic_wrapper.ret" if retfile.nil?
	finished = false
	b = Array.new
	b[0] = Thread.new {
		pesc = params.collect { |p| "'#{p}'" }
		system("LANGUAGE=en_GB:en LC_ALL=en_GB.UTF-8 " + pesc.join(" "))
		retval = $?
		$stderr.puts "#{pesc.join(' ')} returned: " + retval.to_s
		e = retval.exitstatus.to_i
		e = 99999 if retval.exitstatus.nil? 
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

scan_threaded(retfile, params)
