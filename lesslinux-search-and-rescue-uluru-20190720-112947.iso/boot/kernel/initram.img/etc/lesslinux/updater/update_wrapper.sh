#!/static/bin/ash
		
if check_lax_sudo ; then
	sudo /etc/lesslinux/updater/updater.sh $1
else
	sudo /etc/lesslinux/updater/updater.sh $1
	# /usr/bin/llaskpass-mount.rb | sudo -S /etc/lesslinux/updater/updater.sh $1
fi

		
