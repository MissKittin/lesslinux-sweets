#!/usr/bin/ruby

# require 'gtk2'
# require "rexml/document"

LANGUAGE = ENV['LANGUAGE'][0..1]

if system("test -f $HOME/.lesslinux/keymaps." + LANGUAGE)
	# read the keymaps
	keymaps = Array.new
	File.open(ENV['HOME'] + "/.lesslinux/keymaps." + LANGUAGE).each { |line|
		ltoks = line.strip.split
		keymaps.push ltoks[0] unless ltoks == "" || ltoks[0] =~ /^#/
	}
	# read the current map, if not available, assume the first map in the list ist current
	current_map = keymaps[0]
	if system("test -f $HOME/.lesslinux/keymap.active")
		File.open(ENV['HOME'] + "/.lesslinux/keymap.active").each { |line|
			current_map = line.strip
		}
	end
	# now find the position of the current_map
	map_pos = keymaps.index(current_map)
	if map_pos.nil?
		next_pos = 0
	else
		next_pos = map_pos + 1
	end
	next_pos = 0 if next_pos == keymaps.size
	# finally switch to the selected map
	$stderr.puts("Switching to keymap index " + next_pos.to_s + " map: " + keymaps[next_pos].to_s)
	system("setxkbmap -rules xorg -model pc105 -layout " + keymaps[next_pos].to_s)
	# announce the switch
	# system("echo 'message: Keyboard layout switched to " + keymaps[next_pos].to_s + "' | zenity --notification --listen")
	# write the new map to the file and exit
	system("zenity --info --text 'Keyboard layout switched to " + keymaps[next_pos].to_s + ".'")
	system("echo " + keymaps[next_pos] + " > $HOME/.lesslinux/keymap.active")
else
	$stderr.puts "No file .lesslinux/keymaps." + LANGUAGE + " found in home directory, exiting without switching maps."
end
