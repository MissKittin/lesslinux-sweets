#!/static/bin/ash
		
#lesslinux provides extraconfig
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
      # Make it possible to dd a gzipped tarball with maximum 29kB at position 3072 bytes of the DVD
      # 1k at position 2048 bytes is reserved for license information on commercial products
      #
      # The tarball will be unpacked in the root directory, so many config files might be overwritten:
      dd if=` cat /var/run/lesslinux/install_source ` bs=1024 skip=3 count=29 | tar -C / -xvzf - 
    ;;
esac
		
