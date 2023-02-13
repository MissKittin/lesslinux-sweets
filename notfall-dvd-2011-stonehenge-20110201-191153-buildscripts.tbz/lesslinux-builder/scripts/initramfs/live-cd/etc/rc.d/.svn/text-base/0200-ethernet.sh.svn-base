#!/static/bin/ash

PATH=/static/bin:/static/sbin:/bin:/sbin

. /etc/rc.conf
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Start Networking

case $1 in 
	start)
		if [ "$nonet" -gt 0 ] ; then
			printf "$bold===> Skipping networking $normal\n"
		else
			if [ "$dhcp" -gt 0 ] ; then
				printf "$bold===> Setting up networking (DHCP) $normal\n"
				udhcpc -R -i $netif
			else
				printf "$bold===> Setting up networking (static)                              "
				ifconfig $netif inet $ip netmask $mask
				echo "nameserver $dns" > /etc/resolv.conf
				route add default gw $gw
				hostname $host
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
