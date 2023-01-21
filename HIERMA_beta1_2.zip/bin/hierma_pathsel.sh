#!/usr/bin/env bash
# HIERMA path selection tool.
# Arguments:
# $1 = type of path selection (LOCAL, FTP)
# $2 = field in database to modify (ex: src_path)
lastdir="$(cat lastdir 2> /dev/null)"
dest_path="$("$scriptdir/hierma_getparm.sh" dest_path)"
if [ -z "$lastdir" ]; then
    # Default path is the working directory the user was in upon
    # initiating the script.
    lastdir='./'
fi

ftp_command() {
# Return the appropriate lftp command to stdout, depending on what
# credentials were specified.

if [ -z $ftpuser ]; then
    ftpcmd="lftp ${ftpserver}${ftppath}"
elif [ -z $ftppass ]; then
    ftpcmd="lftp -u $ftpuser ${ftpserver}${ftppath}"
else
    ftpcmd="lftp -u $ftpuser,"$ftppass" ${ftpserver}${ftppath}"
fi

}

while (true); do
case $1 in
	'LOCAL')
	    localpath="$(dialog --title 'Select Local Path' --dselect "$lastdir" 12 50 3>&1 1>&2 2>&3)"
        if [ $? = 0 ]; then
            # Gonna have to be more mindful of potential user errors...
            # and really figure out how to handle invalid FTP settings.
            if [ "$localpath" = "$dest_path" ]; then
                export DIALOGRC="$scriptdir/derror"
                dialog --title "ERROR: Source and Destination Match" --msgbox "The source path you selected is exactly the same as the destination! Please choose a different source path." 6 60
                unset DIALOGRC
            else
                # Obviously you don't know how to use this program.
                ls "$localpath" > /dev/null 2>&1
                lsexit=$?
                if [ $lsexit != 0 ]; then
                    # Store the error message.
                    lserror=$(ls $localpath 2>&1)
                    export DIALOGRC="$scriptdir/derror"
                    dialog --title "ERROR: Directory Not Accessible" --msgbox "This directory is not accessible. ls returned:\n\n     $lserror\n\nPlease choose a different file or directory." 11 70
                    unset DIALOGRC lserror
                else            
                    localpath2="$(echo $localpath | sed 's|/$||')"
                    localpath="$localpath2"
                    unset localpath2
                    "$scriptdir/hierma_setparm.sh" "$2" "$localpath"
                    echo "$localpath" > lastdir
                    exit 0
                fi
            fi
        else
            exit 1
        fi
        ;;
    'FTP')
        ftppath=$($scriptdir/hierma_getparm.sh "$2")
        ftpserver=$($scriptdir/hierma_getparm.sh "$3")
        ftpuser=$($scriptdir/hierma_getparm.sh "$4")
        ftppass=$($scriptdir/hierma_getparm.sh "$5")
        dialog --title 'Install from FTP Server' --insecure --mixedform "Specify the hostname or IP address of your FTP server and its credentials. You can also enter the path where your files are located if necessary.\n\nKeep in mind that passwords are not encrypted over FTP, and are stored in plain text in the configuration database. It is recommended that you configure your server for anonymous read-only FTP connections.\n\nTo specify a non-default port number, type something like hierma.foo:8001 in the server field." 20 60 4 \
            'Server:' 1 1 "$ftpserver" 1 25 50 50 0 \
            'Path:' 2 1 "$ftppath" 2 25 50 50 0 \
            'Username:' 3 1 "$ftpuser" 3 25 50 50 0 \
            'Password:' 4 1 "$ftppass" 4 25 50 50 1 2> ftpauth.tmp
        if [ $? = 0 ]; then
            # Overwrite the variables and assign them to the database fields.
            ftpserver="$(sed -n '1p' ftpauth.tmp)"
            ftppath="$(sed -n '2p' ftpauth.tmp)"
            ftpuser="$(sed -n '3p' ftpauth.tmp)"
            ftppass="$(sed -n '4p' ftpauth.tmp)"
            if [ -z $ftpserver ]; then
                export DIALOGRC="$scriptdir/derror"
                dialog --title "ERROR: FTP Server Not Set" --msgbox "An FTP server was not specified in the dialog form." 5 57
                unset DIALOGRC
                rm ftpauth.tmp
            else
                rm ftpauth.tmp
                ftp_command
                if [ "$ftppath" ]; then
                    if [ -z "$(echo $ftppath | grep ^/)" ]; then
                        "$scriptdir/hierma_setparm.sh" "$2" "/$ftppath"
                    else
                        "$scriptdir/hierma_setparm.sh" "$2" "$ftppath"
                    fi
                else
                    "$scriptdir/hierma_setparm.sh" "$2" DELETE
                fi
                "$scriptdir/hierma_setparm.sh" "$3" "$ftpserver"
                if [ "$ftppath" ]; then
                    "$scriptdir/hierma_setparm.sh" "$4" "$ftpuser"
                else
                    "$scriptdir/hierma_setparm.sh" "$4" DELETE
                fi
                if [ "$ftppath" ]; then
                    "$scriptdir/hierma_setparm.sh" "$5" "$ftppass"
                else
                    "$scriptdir/hierma_setparm.sh" "$5" DELETE
                fi
                $ftpcmd -e "ls; bye" 2> lftp.err
                if [ "$(grep 'Fatal' lftp.err)" ]; then
                    export DIALOGRC="$scriptdir/derror"
                    dialog --title "ERROR: Can't Connect to Server" --msgbox "Could not connect to the FTP server. lftp returned:\n\n    $(cat lftp.err)\n\nCheck to be sure your credentials are correct and the FTP server is running, and try again." 10 75
                    unset DIALOGRC
                    rm lftp.err 2> /devnull
                else
                    rm lftp.err 2> /dev/null
                    exit 0
                fi
            fi
        else
            exit 1
        fi
        ;;
esac
done
