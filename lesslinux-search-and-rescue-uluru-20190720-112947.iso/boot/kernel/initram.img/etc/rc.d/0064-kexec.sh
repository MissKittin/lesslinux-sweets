#!/static/bin/ash
		
#lesslinux provides kexec
#lesslinux verbose
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
case $1 in
    start)
	if mountpoint -q /lesslinux/cdrom ; then
		printf "$bold---> No kexec when the system root is mounted. $normal\n"
		exit 1
	fi
	if [ -n "$kexec" ] && [ -f /static/sbin/kexec ] ; then
		printf "\n$bold---> Downloading and booting kernel. $normal\n"
		conf=""
		append=""
		if echo "$kexec" | grep -E -q '^(http|https|ftp)\://' ; then
			wget -O /etc/lesslinux/kexec/custom.conf "$kexec"
			conf="/etc/lesslinux/kexec/custom.conf"
		elif echo "$kexec" | grep -q '^/etc' ; then
			conf="$kexec"
		fi
		cat "$conf" | while read ln ; do
			key=` echo "$ln" | awk -F '::::' '{print $1}' `
			val=` echo "$ln" | awk -F '::::' '{print $2}' `
			if [ "$key" = "kernel" ] ; then
				wget -O /etc/lesslinux/kexec/kernel.knl "$val"
			fi
			if [ "$key" = "initrd" ] ; then
				touch /etc/lesslinux/kexec/initrd.img
				wget -O - "$val" >> /etc/lesslinux/kexec/initrd.img
			fi
			if [ "$key" = "append" ] ; then
				kexec --force --reset-vga --initrd=/etc/lesslinux/kexec/initrd.img --command-line="$val" /etc/lesslinux/kexec/kernel.knl
			fi
		done
		kexec --force --reset-vga --initrd=/etc/lesslinux/kexec/initrd.img /etc/lesslinux/kexec/kernel.knl
		printf "$bold---> Kexec failed. Reboot in 30s. $normal\n"
		sleep 30
		reboot
	fi
    ;;
esac

		
