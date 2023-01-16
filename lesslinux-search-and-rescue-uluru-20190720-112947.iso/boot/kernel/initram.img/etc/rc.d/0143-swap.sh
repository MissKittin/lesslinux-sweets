#!/static/bin/ash
		
#lesslinux provides swap
#lesslinux parallel
#lesslinux license BSD
#lesslinux description
# Prepare development and build environment of LessLinux

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh

format_and_mount_swap() {
	auxuuid=$1
	auxpart=$2
	[ -z "$auxpart" ] && exit 1
	swapkey=/lesslinux/cryptkeys/swap.key
	mkdir -m 0700 /lesslinux/cryptkeys
	dd if=/dev/urandom bs=1M count=4 of=${swapkey} 
	chmod 0600 ${swapkey} 
	cryptsetup luksFormat --uuid=${auxuuid} -c aes-xts-plain64 -s 512 -h sha512 --use-urandom -i 5000 -q ${auxpart} ${swapkey} 
	shortpart=` echo $auxpart | sed 's%/dev/%%g' `
	cryptsetup luksOpen --key-file ${swapkey} ${auxpart} ${shortpart} && \
		ln -s /dev/mapper/${shortpart} /dev/mapper/cryptoswap && \
		ln -s /dev/mapper/${shortpart} ${auxpart}.child 
 	rm ${swapkey} 
	mkswap /dev/mapper/${shortpart}
	swapon /dev/mapper/${shortpart}
}

case $1 in
    start)
	if [ -n "$swap" ] ; then
		printf "$bold===> Preparing swap... $normal\n"
		swappart=` blkid -U $swap `
		[ -z "$swappart" ] && exit 1 
		parttype=` blkid -o udev $swappart | grep 'ID_FS_TYPE=' | awk -F '=' '{print $2}'  ` 
		if [ "$parttype" = crypto_LUKS ] ; then
			format_and_mount_swap $swap $swappart
		elif [ "$parttype" = swap ] ; then
			swapon $swappart
		fi
	else
		swappart=` blkid -o device -t PARTLABEL="${brandshort}-SWAP" `
		[ -z "$swappart" ] && swappart=` blkid -L LessLinuxSwap `
		[ -z "$swappart" ] && exit 1 
		swapuuid=` blkid -o udev $swappart | grep 'ID_FS_UUID=' | awk -F '=' '{print $2}' ` 
		format_and_mount_swap $swapuuid $swappart
	fi
	touch /var/log/lesslinux/bootlog/swap.done
    ;;
    stop)
	swaps=` cat /proc/swaps | grep '^/' | awk '{print $1}' ` 
	for f in $swaps ; do
		swapoff $f
		cryptsetup luksClose $f
		losetup -d $f
	done
    ;;
esac
	
		
