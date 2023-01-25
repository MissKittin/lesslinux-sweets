#!/static/bin/ash
		
#lesslinux provides alsaprepare
#lesslinux license BSD
#lesslinux description
# Load some alsa modules

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
case $1 in
    start)
	printf "$bold===> Preparing sound $normal"
	# Load modules
	for i in snd_pcm_oss snd_mixer_oss snd_hda_codec snd_pcm snd_timer ; do
	    modprobe -v $i
	done
	mdev -s
	# Make nodes, not war
	mkdir -m 0755 /dev/snd
	# crw-rw----+  1 root audio 116,  0 2009-06-11 09:38 controlC0
	mknod /dev/snd/controlC0	c 116  0
	# crw-rw----+  1 root audio 116,  4 2009-06-11 09:38 hwC0D0
	mknod /dev/snd/hwC0D0		c 116  4
	# crw-rw----+  1 root audio 116, 24 2009-06-11 09:38 pcmC0D0c
	mknod /dev/snd/pcmC0D0c		c 116 24
	# crw-rw----+  1 root audio 116, 16 2009-06-25 09:59 pcmC0D0p
	mknod /dev/snd/pcmC0D0p		c 116 16
	# crw-rw----+  1 root audio 116, 17 2009-06-11 09:38 pcmC0D1p
	mknod /dev/snd/pcmC0D1p		c 116 17
	# crw-rw----+  1 root audio 116, 26 2009-06-11 09:38 pcmC0D2c
	mknod /dev/snd/pcmC0D2c		c 116 26
	# crw-rw----+  1 root audio 116,  1 2009-06-11 09:38 seq
	mknod /dev/snd/seq		c 116 1
	# crw-rw----+  1 root audio 116, 33 2009-06-11 09:38 timer
	mknod /dev/snd/timer		c 116 33
	mknod /dev/mixer		c  14  0
	chown root:audio /dev/snd/* /dev/mixer
	chmod 0660 /dev/snd/* /dev/mixer
    ;;
esac

# END		
