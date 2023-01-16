#!/static/bin/ash
		
#lesslinux provides kaspersky
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	if mountpoint -q /opt/kaspersky/kav4ws/var ; then
	    printf "$bold===> Skipping Kaspersky, already mounted $normal\n"
	else
	    printf "$bold===> Preparing Kaspersky Antivirus $normal\n"
	    rand=` dd if=/dev/urandom bs=1M count=1 | sha1sum | awk '{print $1}' `
	    tar -cf /tmp/kaspersky_${rand}.tar /opt/kaspersky/kav4ws/var
	    mount -o mode=755 -t tmpfs tmpfs /opt/kaspersky/kav4ws/var
	    tar -C / -xf /tmp/kaspersky_${rand}.tar
	    rm /tmp/kaspersky_${rand}.tar
	    mkdir /opt/kaspersky/kav4ws/var/bases.backup
	    if [ -f /etc/lesslinux/branding/kaspersky.key ] ; then
		mv /opt/kaspersky/kav4ws/var/licenses/appinfo.dat /opt/kaspersky/kav4ws/var/licenses/appinfo.bak
		/opt/kaspersky/kav4ws/bin/kav4ws-licensemanager -a/etc/lesslinux/branding/kaspersky.key
	    fi
	    echo '' >> /etc/sudoers
	    echo '# added by /etc/rc.d/0600-kaspersky.sh' >> /etc/sudoers
	    echo 'surfer  ALL = NOPASSWD: /opt/kaspersky/kav4ws/bin/kav4ws-keepup2date' >> /etc/sudoers
	    echo 'surfer  ALL = NOPASSWD: /opt/computerbild/avfrontend/virusfrontend' >> /etc/sudoers
	fi
    ;;
    stop)
	printf "$bold===> Unmounting Kaspersky signatures $normal\n"
	if mountpoint -q /opt/kaspersky/kav4ws/var ; then
		fuser -km -9 /opt/kaspersky/kav4ws/var
	fi
	umount /opt/kaspersky/kav4ws/var
    ;;
esac

		
