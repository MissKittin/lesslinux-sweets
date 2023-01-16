#!/static/bin/ash
		
#lesslinux provides sound1
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
	for i in snd-hda-intel snd_pcm_oss snd_mixer_oss snd_hda_codec snd_pcm snd_timer \
	    snd_hda_codec_realtek snd_hda_codec_via snd_hda_codec_idt snd_hda_codec_analog \
	    snd_hda_codec_cmedia snd_hda_codec_nvhdmi snd_hda_codec_intelhdmi \
	    snd_hda_codec_conexant snd_hda_codec_si3054 snd_hda_codec_cirrus \
	    snd_hda_codec_atihdmi snd_hda_codec_ca0110 ; do
	    modprobe -v $i
	done
	sleep 1
	udevadm control --reload-rules
	udevadm trigger --verbose --subsystem-match sound 
    ;;
esac

# END		
