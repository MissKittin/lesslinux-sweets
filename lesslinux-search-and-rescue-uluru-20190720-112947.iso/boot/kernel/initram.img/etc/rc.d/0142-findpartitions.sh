#!/static/bin/ash

#lesslinux provides findpartitions
#lesslinux patience
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh
. /etc/rc.lang/en/messages.sh
[ -f "/etc/rc.lang/$lang/messages.sh" ] && . /etc/rc.lang/$lang/messages.sh
. /etc/rc.subr/progressbar
. /var/run/lesslinux/startup_vars
		
case $1 in
    start)
	device=''
	device=$outerdevice
	[ -z "$device" ] && exit 0
	# Check if there is enough space behind the partition table for another ISO image
	devsize=`     parted -m -s ${device} unit b print | grep msdos | awk -F ':|B:' '{print $2}' ` 
	partend=`     parted -m -s ${device} unit b print | grep '^1'  | awk -F ':|B:' '{print $3}'  `
	isosize=`     parted -m -s ${device} unit b print | grep '^1'  | awk -F ':|B:' '{print $2}'  `
	isotwostart=` expr $devsize - $isosize - 8388608 ` 
	# Determine the end of our new loop device by matching an 8M chunk towards the end of the device: 
	loopendblock=` expr '(' $devsize - $isosize ')' / 8388608 - 1 ` 
	# Create a loop device with correct parameters 
	freeloop=` losetup -f ` 
	losetup -o ` expr $partend + 1 ` --sizelimit ` expr $loopendblock '*' 8388608 - $partend - 1 ` $freeloop $device
	# Backup the partition table 
	parted -s -m $freeloop unit B print > /var/run/lesslinux/looppart.txt
	p1start=` grep '^1' /var/run/lesslinux/looppart.txt | awk -F ':|B:' '{print $2}' `
	
	if [ -z "$p1start" ] ; then
		losetup -d $freeloop
	else
		partx -a $freeloop 
	fi
    ;;
esac
		
# The end	
