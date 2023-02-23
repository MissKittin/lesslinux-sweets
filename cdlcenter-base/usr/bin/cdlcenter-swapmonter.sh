#!/bin/bash
# Name             : Swap-monter
# Author           : Maciej Kosmulski ( barnim@tmc.gda.pl )
# Created On       : 2003.08.05
# Last Modified By : Maciej Kosmulski ( barnim@tmc.gda.pl )
# Last Modified On : 2004.05.02
# Version          : 0.2
#
# Description      :
#	-c /dev/hdXY tworzy plik wymiany na podanej partycji w katalogu "cdlinux" i montuje go
#	-f /sciezka.dostepu/plik_wymiany.img montuje plik wymiany
#	-u odmontuje plik lub partycje wymiany
#       -u file - odmontowywuje wszystkie pliki wymiany
#       -u part - odmontowywuje wszystkie partycje wymiany
#	-m /dev/hdXY montuje podana partycje swap
#	-s wyszukuje partycje swap w systemie oraz pliki wymiany na dyskach
#       -q cichy tryb pracy
#	-h wyswietla pomoc
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

create_swap_file(){
    # poka¿e punkt montowania podanej partycji
    mount_point=`/bin/df -m | grep $partycja | awk '{ print $6 }'`
    if [ "$mount_point" == ""  ] ; then
	echo "Partycja nie jest zamontowana!"
	exit 1
    fi
    
    blok=1
    #miejsce dostepne na dysku w MB:
    disk_free=`/bin/df -m | grep $partycja | awk '{ print $4 }'`
    if [ -z $rozmiar ] ; then
	#ilosc pamieci ram w MB:
	memory=`/usr/bin/free -m | grep Mem | awk '{ print $2 }'`

	# jesli pamieci ponad 500 MB to niech i tak robi swap 512 MB
	if [ "$memory" -ge "500" ] ; then
	    bufor=512M
	    if [ "$bufor" -ge "$disk_free" ] ; then
		echo "Za ma³o miejsca na dysku !"
		exit 1
	    fi
	else 
	    bufor=$[$memory * 2]
	    if [ "$bufor" -ge "$disk_free" ] ; then
		echo "Za ma³o miejsca na dysku !"
		exit 1
	    fi
	    bufor=${bufor}M
	fi
    else
    	bufor=$rozmiar
  	if [ "$bufor" -ge "$disk_free" ] ; then
	    echo "Za ma³o miejsca na dysku !"
	    exit 1
	fi
	bufor=${bufor}M
    fi
    #sprawdz czy istnieje katalog
    if [ -d "$mount_point/cdlinux" ] ; then
	echo "Katalog $mount_point/cdlinux istnieje!" > /dev/null 2> /dev/null
    else
	mkdir $mount_point/cdlinux
    fi

    if [ -a "$mount_point/cdlinux/swap.img" ] ; then
	echo "Plik istnieje!"
    else
	echo "Tworzenie pliku wymiany na partycji $partycja..."
	echo "Proszê czekaæ..." 1>$OUT
	dd if=/dev/zero of=$mount_point/cdlinux/swap.img bs=$bufor count=$blok > /dev/null 2> /dev/null
    fi

    mkswap $mount_point/cdlinux/swap.img 
    swapon $mount_point/cdlinux/swap.img
    echo -e "Zrobione!" 1>$OUT
}

# wyszukuje pliku wymiany: /cdlinux/swap.img
# na ka¿dej zamontowanej partycji
search_img(){
    for mount_point in `mount | grep /dev/ | awk '{ print $3 }'`
    do
	if [ -d "$mount_point/cdlinux" ] ; then
	    echo "Katalog $mount_point/cdlinux istnieje!" > /dev/null 2> /dev/null

	    # jesli istnieje na danej partycji katalog cdlinux to sprawd¼ czy w nim jest plik swap.img:
	    if [ -a "$mount_point/cdlinux/swap.img" ] ; then
		LINUX_SWAP="$mount_point/cdlinux/swap.img"
		echo "$mount_point/cdlinux/swap.img"
	    fi

	fi
    done
}

# wyszukuje wszystko co moze przypominac swapa ;)
search_swap(){
    LINUX_SWAP=""
    LINUX_SWAP=`/sbin/fdisk -l /dev/[h,s]d[a-p]| grep swap | awk -F" " '{ print $1 }'`
    if [ "$LINUX_SWAP" != ""  ] ; then
        echo "$LINUX_SWAP" 
    fi
    
    search_img
    
    if [ "$LINUX_SWAP" = ""  ] ; then
	echo "Nie znaleziono partycji wymiany ani pliku wymiany na zamontowanych dyskach" 1>$OUT
    fi    
}

# montuje podany plik wymiany
swap_file_on(){
    if [ -a "$swap_file" ] ; then
	if [ "$swap_file" != "" ] ; then
	    echo "Montowanie pliku wymiany: $swap_file" 1>$OUT
	    swapon $swap_file
	else
	    echo "Brak nazwy pliku wymiany"
	fi
    else
	echo "Brak pliku wymiany: $swap_file"
	exit 1
    fi
}

# montuje istniej±c± partycje swap
swap_on(){
    LINUX_SWAP=""
    LINUX_SWAP=`/sbin/fdisk -l /dev/[h,s]d[a-p]| grep swap | awk -F" " '{ print $1 }'`
    if [ -b "$LINUX_SWAP" ] ; then
	if [ "$LINUX_SWAP" != ""  ] ; then
    	    echo "Uruchomianie partycji wymiany: $LINUX_SWAP" 1>$OUT
	    echo "$LINUX_SWAP none swap sw 0 0" >> /etc/fstab
    	    swapon $LINUX_SWAP
	else
	    echo "Podaj partycje wymiany (swap) do zamontowania"
	    exit 1
	fi
    else
	echo "Brak partycji do zamontowania"
    fi
}

# odmontowuje partycje lub plik swap
swap_off(){
    if [ "$swap_file" = "file" ] ; then
	for umount in `/sbin/swapon -s | grep -v Filename | grep file | cut -f 1 -d " "` ; do
	    `swapoff $umount`
	done
    elif [ "$swap_file" = "part" ] ; then
	for umount in `/sbin/swapon -s | grep -v Filename | grep partition | cut -f 1 -d " "` ; do
	    `swapoff $umount`
	done
    elif [ -f "$swap_file" ] ; then
	echo "Odmontowanie pliku lub partycji wymiany: $swap_file" 1>$OUT
	swapoff $swap_file
    else
	echo "Brak nazwy pliku lub partycji wymiany" ;
    fi
}

# pomoc ;)
help(){
    echo -e "\nU¿ycie:    cdlcenter-swap-monter.sh [opcje]" 
    echo -e "\nOpcje:\n  -c /dev/hdXY    tworzy plik wymiany na podanej partycji w katalogu \"cdlinux\" \n                  i montuje go" 
    echo -e "\n  -c /dev/hdXY -S rozmiar   tworzy plik wymiany na podanej partycji w katalogu \n                            \"cdlinux\" o rozmiarze \"rozmiar\" i montuje go" 
    echo -e "\n  -f /scie¿ka.dostêpu/plik_wymiany.img    montuje plik wymiany"
    echo -e "  -m    montuje partycje wymiany, je¿eli zostanie znaleziona"
    echo -e "\n  -u file     odmontowywuje wszystkie pliki wymiany"
    echo -e "  -u part     odmontowywuje wszystkie partycje wymiany"
    echo -e "\n  -s    wyszukuje partycje wymiany w systemie oraz pliki wymiany na dyskach"
    echo -e "\n  -q    cichy tryb pracy - tylko komunikaty b³êdów"
    echo -e "  -h    wy¶wietla pomoc (to, co w³a¶nie widzisz ;))\n"
}

OUT=`tty`

while getopts S:c:f:u:msqh WYBOR 2>/dev/null
do
    case $WYBOR in
        S)  rozmiar=$OPTARG;;
	c)  partycja=$OPTARG;;
	f)  swap_file=$OPTARG
	    swap_file_on ;;
	u)  swap_file=$OPTARG
	    swap_off ;;
	m)  swap_on ;;
        s)  search_swap ;;
	q)  OUT="/dev/null" ;;
        h)  help;;
        ?)  echo "Z³e polecenie, spróbuj z opcja -h";
        exit;;
    esac
done

if [ $partycja ] ; then
	create_swap_file
fi 
