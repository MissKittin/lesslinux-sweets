#!/usr/bin/ruby
# encoding: utf-8

pid = File.new("/var/run/lesslinux/ddrescue.pid",  "w")
pid.write($$.to_s)
pid.close

system("rm /var/run/lesslinux/ddrescue.log") if File.exist?("/var/run/lesslinux/ddrescue.log")

count = ARGV.size / 2
0.upto(count - 1) { |i|
	infile = ARGV[i * 2]
	outfile = ARGV[i * 2 + 1]
	### outfile = "/dev/null"
	puts "Klone " + infile + " nach " + outfile
	system("ddrescue --force --max-retries=3 " + infile + " " + outfile + " /var/run/lesslinux/ddrescue.log")
	system("ddrescue --force --retrim " + infile + " " + outfile + " /var/run/lesslinux/ddrescue.log")
	system("rm /var/run/lesslinux/ddrescue.log")
}
