#!/static/bin/ash
		
if check_lax_sudo ; then
	sudo /etc/lesslinux/updater/updater.sh
else
	/usr/bin/llaskpass-mount.rb | sudo -S /etc/lesslinux/updater/updater.sh
fi

		
