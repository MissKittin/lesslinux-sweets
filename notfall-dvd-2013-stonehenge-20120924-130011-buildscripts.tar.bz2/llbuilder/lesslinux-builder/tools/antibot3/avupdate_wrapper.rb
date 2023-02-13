#!/usr/bin/ruby
# encoding: utf-8

require 'thread'

# Arguments: pidfile logfile avupdate
retfile = ARGV[0]
avupdate = ARGV[1]
args = ARGV
args.delete_at(0)
args.delete_at(1)

def update_threaded(retfile, avupdate=nil, args)
	avupdate = "/AntiVirUpdate/avupdate" if avupdate == nil
	retfile = "/var/run/avupdate.ret" if retfile.nil?
	finished = false
	command = avupdate
	args.each { |a| command = command + " '#{a}'" }
	# mutex = Mutex.new
	b = Array.new
	b[0] = Thread.new {
		$stderr.puts "Running: #{command}" 
		system(command)
		retval = $?
		$stderr.puts "avupdate returned: " + retval.to_s
		File.open(retfile, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f|
			f.write(retval.exitstatus.to_s + "\n")
		}
		finished = true
	}
	b[1] = Thread.new {
		while finished == false
			puts "-TickTock-"
			$stdout.flush
			sleep 0.02
		end
	}
	b.each { |i| i.join }
end

update_threaded(retfile, avupdate, args)
