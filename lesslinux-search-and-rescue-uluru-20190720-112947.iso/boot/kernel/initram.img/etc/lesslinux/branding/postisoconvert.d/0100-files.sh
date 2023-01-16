#!/static/bin/ash
		
PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin:
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
# check, if the files needed exist - some of those directories are defaults of customers
# and not used on normal LessLinux builds

for d in Data Runtime Software Programme Windows-Programme Programs Windows-Programs Lizenzen lizenzen licenses legal ; do
	[ -d /lesslinux/cdrom/${d} ] && tar -C /lesslinux/cdrom -cf - ${d} | tar -C /lesslinux/data -xf -
done
for f in liesmich.html readme.html LIESMICH.html README.html Start.exe Start.inf ; do 
	[ -f /lesslinux/cdrom/${f} ] && tar -C /lesslinux/cdrom -cf - ${f} | tar -C /lesslinux/data -xf -
done

		
