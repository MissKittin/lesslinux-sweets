#!/static/bin/ash

#lesslinux provides earlynet

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Start Networking

case $1 in 
  start)
    if [ "$nonet" -gt 0 ] ; then
      printf "$bold===> Skipping networking $normal\n"
    else
      if [ "$dhcp" -gt 0 ] ; then
          printf "$bold===> Setting up early networking (DHCP/ethernet) $normal\n"
	  for i in 0 1 2 3 4 5 6 7 8 9 ; do
	      udhcpc -q -s /static/share/udhcpc/default.script -i eth$i > /dev/null 2>&1 &
	  done
	  sleep 15
      else
	  # staticnet=|iface|ip|mask|dns|gateway|
	  netif=` echo "$staticnet" | awk -F '|' '{print $2}' `
	  ip=` echo "$staticnet" | awk -F '|' '{print $3}' `
	  mask=` echo "$staticnet" | awk -F '|' '{print $4}' `
	  dns=` echo "$staticnet" | awk -F '|' '{print $5}' `
	  gw=` echo "$staticnet" | awk -F '|' '{print $6}' ` 
          printf "$bold===> Setting up networking (static/ethernet)                              "
          ifconfig $netif inet $ip netmask $mask
          echo "nameserver $dns" > /etc/resolv.conf
          route add default gw $gw
          if ifconfig $netif > /dev/null 2>&1 ; then
              printf "$success"
          else       
              printf "$failed"
          fi
      fi
    fi
  ;;
  stop)
    printf "$bold===> Stopping ethernet networking                                "
    if ifconfig $netif down > /dev/null 2>&1 ; then
      printf "$success"
    else
      printf "$failed"
    fi  
  ;;
esac    

printf "$normal"

# END		
