#!/static/bin/ash
		
#lesslinux provides firewall
#lesslinux license BSD
#lesslinux description
# Start iptables firewall with very simple rules

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in
    start)
	printf "$bold===> Starting firewall $normal\n"
	# Module laden
	modprobe ip_tables
	modprobe ip_conntrack
	modprobe ip_conntrack_irc
	modprobe ip_conntrack_ftp

	# Tabelle flushen
	iptables -F
	iptables -t nat -F
	iptables -t mangle -F
	iptables -X
	iptables -t nat -X
	iptables -t mangle -X

	# Default-Policies setzen
	iptables -P INPUT DROP
	iptables -P OUTPUT DROP
	iptables -P FORWARD DROP

	# MY_REJECT-Chain
	iptables -N MY_REJECT

	# MY_REJECT fuellen
	iptables -A MY_REJECT -p tcp -m limit --limit 7200/h -j LOG --log-prefix "REJECT TCP "
	iptables -A MY_REJECT -p tcp -j REJECT --reject-with tcp-reset
	iptables -A MY_REJECT -p udp -m limit --limit 7200/h -j LOG --log-prefix "REJECT UDP "
	iptables -A MY_REJECT -p udp -j REJECT --reject-with icmp-port-unreachable
	iptables -A MY_REJECT -p icmp -m limit --limit 7200/h -j LOG --log-prefix "DROP ICMP "
	iptables -A MY_REJECT -p icmp -j DROP
	iptables -A MY_REJECT -m limit --limit 7200/h -j LOG --log-prefix "REJECT OTHER "
	iptables -A MY_REJECT -j REJECT --reject-with icmp-proto-unreachable

	# MY_DROP-Chain
	iptables -N MY_DROP
	iptables -A MY_DROP -m limit --limit 7200/h -j LOG --log-prefix "PORTSCAN DROP "
	iptables -A MY_DROP -j DROP

	# Alle verworfenen Pakete protokollieren
	iptables -A INPUT -m state --state INVALID -m limit --limit 7200/h -j LOG --log-prefix "INPUT INVALID "
	iptables -A OUTPUT -m state --state INVALID -m limit --limit 7200/h -j LOG --log-prefix "OUTPUT INVALID "
	iptables -A FORWARD -m state --state INVALID -m limit --limit 7200/h -j LOG --log-prefix "FORWARD INVALID "

	# Korrupte Pakete zurueckweisen
	iptables -A INPUT -m state --state INVALID -j DROP
	iptables -A OUTPUT -m state --state INVALID -j DROP
	iptables -A FORWARD -m state --state INVALID -j DROP

	# Stealth Scans etc.
	iptables -A INPUT -p tcp --tcp-flags ALL NONE -j MY_DROP
	iptables -A FORWARD -p tcp --tcp-flags ALL NONE -j MY_DROP
	iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j MY_DROP
	iptables -A FORWARD -p tcp --tcp-flags SYN,FIN SYN,FIN -j MY_DROP
	iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j MY_DROP
	iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN,RST -j MY_DROP
	iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j MY_DROP
	iptables -A FORWARD -p tcp --tcp-flags FIN,RST FIN,RST -j MY_DROP
	iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j MY_DROP
	iptables -A FORWARD -p tcp --tcp-flags ACK,FIN FIN -j MY_DROP
	iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j MY_DROP
	iptables -A FORWARD -p tcp --tcp-flags ACK,PSH PSH -j MY_DROP
	iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -j MY_DROP
	iptables -A FORWARD -p tcp --tcp-flags ACK,URG URG -j MY_DROP

	# Loopback-Netzwerk-Kommunikation zulassen
	iptables -A INPUT -i lo -j ACCEPT
	iptables -A OUTPUT -o lo -j ACCEPT

	# Maximum Segment Size (MSS) fuer das Forwarding an PMTU anpassen
	iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

	# Connection-Tracking aktivieren
	iptables -A OUTPUT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

	# Default-Policies mit REJECT
	iptables -A INPUT -j MY_REJECT
	iptables -A OUTPUT -j MY_REJECT
	iptables -A FORWARD -j MY_REJECT

	# Routing
	echo 0 > /proc/sys/net/ipv4/ip_forward 2> /dev/null

	echo 1 > /proc/sys/net/ipv4/tcp_syncookies 2> /dev/null
	for i in /proc/sys/net/ipv4/conf/*; do echo 0 > $i/accept_source_route 2> /dev/null; done
	for i in /proc/sys/net/ipv4/conf/*; do echo 0 > $i/accept_redirects 2> /dev/null; done
	for i in /proc/sys/net/ipv4/conf/*; do echo 2 > $i/rp_filter 2> /dev/null; done
	for i in /proc/sys/net/ipv4/conf/*; do echo 1 > $i/log_martians 2> /dev/null; done
	for i in /proc/sys/net/ipv4/conf/*; do echo 0 > $i/bootp_relay 2> /dev/null; done
	for i in /proc/sys/net/ipv4/conf/*; do echo 0 > $i/proxy_arp 2> /dev/null; done

	echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses 2> /dev/null
	echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts 2> /dev/null

	# Max. 500/Sekunde (5/Jiffie) senden
	echo 5 > /proc/sys/net/ipv4/icmp_ratelimit

	# Speicherallozierung und -timing fuer IP-De/-Fragmentierung
	echo 262144 > /proc/sys/net/ipv4/ipfrag_high_thresh
	echo 196608 > /proc/sys/net/ipv4/ipfrag_low_thresh
	echo 30 > /proc/sys/net/ipv4/ipfrag_time

	# TCP-FIN-Timeout zum Schutz vor DoS-Attacken setzen
	echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout

	# Maximal 3 Antworten auf ein TCP-SYN
	echo 3 > /proc/sys/net/ipv4/tcp_retries1

	# TCP-Pakete maximal 15x wiederholen
	echo 15 > /proc/sys/net/ipv4/tcp_retries2
    ;;
    stop)
	printf "$bold===> Stopping firewall $normal\n"
	iptables -F
	iptables -t nat -F
	iptables -t mangle -F
	iptables -X
	# iptables -t nat -X
	iptables -t mangle -X
	# echo 0 > /proc/sys/net/ipv4/ip_forward

	# Default-Policies setzen
	iptables -P INPUT ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -P FORWARD ACCEPT
    ;;
esac

# The end       
