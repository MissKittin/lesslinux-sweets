#!/usr/bin/ruby
require 'thread'

t = [ "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l" ]
u = [ "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x" ]

def build_threaded(z)
	mutex = Mutex.new
	b = Array.new
	f = Array.new
	[0, 1, 2].each { |i|
		b[i] = Thread.new {
			while z.size > 0
				x = z.pop
				puts "building " + x
				s = rand(30)
				sleep s
				puts "finished building " + x + " took " + s.to_s
				s = rand(15)
				mutex.synchronize { 
					puts "installing " + x
					sleep s
					puts "finished installing " + x + " took " + s.to_s
				}
				t = rand(100)
				if t > 75
					puts "FAILED " + x
					f.push(x)
				end
			end
		}
	}
	b.each { |i| i.join }
	puts "FINISHED THREAD GROUP..." 
	if f.size > 0
		puts "INSTALLATION OF " + f.join(", ") + " FAILED!"
		raise "ShitHappens"
	end
end

build_threaded(t)
build_threaded(u)