#!/usr/bin/ruby
# encoding: utf-8

device = ARGV[0]
size = ARGV[1].to_i
logfile = ARGV[2]
chunk_size = 64 * 1024 * 1024
chunk_count = (size / chunk_size).to_i
last_chunk = size % chunk_size
bs = 1024 * 1024
count = 64

puts chunk_count
puts last_chunk

loghandle = File.new(logfile, "w")

0.upto(chunk_count) { |i|
	if File.exist?("/tmp/" + device.gsub("/", "_") + ".stop")
		File.unlink("/tmp/" + device.gsub("/", "_") + ".stop")
		exit 1
	end
	seek = i * count
	if i == chunk_count
		bs = 1024
		count = last_chunk / bs.to_i
		seek = i * 64 * 1024
	end
	puts sprintf("%06d", i) + " Running: dd if=/dev/zero of=" + device + " bs=" + bs.to_s + " count=" + count.to_s + " seek=" + seek.to_s 
	chunk_success = system("dd if=/dev/zero of=" + device + " bs=" + bs.to_s + " count=" + count.to_s + " seek=" + seek.to_s) 
	## chunk_success = system("dd of=/dev/null if=" + device + " bs=" + bs.to_s + " count=" + count.to_s + " skip=" + seek.to_s) 
	if chunk_success
		loghandle.write sprintf("%06d", i) + " OK\n" 
	else
		loghandle.write sprintf("%06d", i) + " FAIL\n" 
	end
	loghandle.flush
}

loghandle.close
