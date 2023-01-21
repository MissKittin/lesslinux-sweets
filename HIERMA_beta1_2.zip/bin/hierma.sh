#!/usr/bin/env bash
# HIERMA, the solution to integrating the installation of the operating
# system, drivers, and updates into a simple scripted routine.
# Copyright (C) 2019 Kugee
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# The above notice applies to all scripts included in the core HIERMA
# distribution. You should find a file called GPLv2.txt in the root of
# the distribution; this contains a copy of version 2 of the
# GNU General Public License.

# Some initial global variables
boot=0
export LOG=0
export DBDEFINED=0

export scriptdir="$(dirname $0)"
export DIALOGOPTS="--backtitle \"$(cat $scriptdir/version)\""
trap hierma_exit INT

# Beta 1.2 now uses a better methodology for handling command line arguments,
# which more easily allows for varied combinations of such.
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in

    -f|--file)
        # Grab a database file. 
        export hdb="$2"
        shift
        shift
        if [ ! -z "$hdb" ]; then
            export hdb_base=$(basename $hdb)
            # hierma_init.sh needs to know if a file has been specified
            # through this variable, because $EXPRESS is not defined
            # until a database has been selected.
            export DBDEFINED=1
        fi
    ;;
    -s|--section)
        # Select the section of a database file.
        export hsect="$2"
        shift
        shift
    ;;
    -l|--enable-logging)
        # Write a logfile of HIERMA's operations to the working path
        # as hier_log.txt. This is copied to the destination path afterwards.
        export LOG=1
        shift
    ;;
    --boot-env)
        # Run HIERMA in a special bootable environment mode.
        # Don't use this in a normal shell on your own Unix box, as
        # it enables the script to execute shutdown commands.
        boot=1
        shift
    ;;
    --cigarette)
        shift
        # Probably gonna remove this later. Kudos if you find this.
        export entry_opt="CIGARETTE"
    ;;

esac
done
set -- "${POSITIONAL[@]}"

if [ $boot = 1 ]; then
    if [ ! -z "$hdb" ] && [ ! -z "$hsect" ]; then
        export entry_opt="UBOOTENV"
    else
        export entry_opt="BOOTENV"
    fi
fi

# Fill empty variables that would otherwise be used with
# command line switches.
if [ -z "$hdb" ]; then
    export hdb="$scriptdir/hierma.conf"
    export hdb_base="hierma.conf"
fi
if [ -z "$hsect" ]; then
    export hsect="default"
fi

#export entry_opt="$1"
osname=$(uname)

# Some *nixes don't have GNU sed, which is required for HIERMA to
# function correctly. To compensate, the script redirects sed to one of
# some possible locations GNU sed may be at.
#
# (Is there a better way to do this?)
sedver="$(sed --version | grep 'sed (GNU sed)')"
if [ -z "$sedver" ]; then
    gsedpath="$(which gsed)"
    if [ -z "$gsedpath" ]; then
        alias sed=/usr/local/bin/sed
        sed # check if it exists there
        if [ $? = 127 ]; then
            export DIALOGRC="$scriptdir/derror"
            dialog --title "FATAL: GNU sed not found!!" --msgbox "HIERMA requires GNU sed to be installed on your system, as it makes use of additional functions not present in other implementations of sed, such as BSD sed. Please don't get back with me until you install GNU sed.\n\nHIERMA will now exit." 10 70
            unset DIALOGRC
            exit 1
        fi
    else
        alias sed="$gsedpath"
    fi
fi

# Default settings. These are to be overwritten by the user.
current_step="init"

hierma_exit() {
    # Let's be real now... there needs to be a better way to handle
    # deleting temporary files. Some users may have .tmp files in their
    # directory that they may need for things, and they could get
    # destroyed by running HIERMA.

    # A menu dialog is only displayed if running in a bootable environment.
    # In other cases, just exit the program.
    exitcmd="$1"
    if [ "$entry_opt" = "BOOTENV" ]; then
        if [ -z "$exitcmd" ]; then
            exitchoice=$(dialog --title "Leaving HIERMA" --menu "You are about to leave HIERMA..." 12 60 5 \
            "Reload" "Restart the HIERMA script" \
            "Reboot" "Restart the computer" \
            "Halt" "Shut down $osname" \
            "Poweroff" "Power off the computer (requires ACPI)" \
            "Shell" "Drop to a BASH prompt" 3>&1 1>&2 2>&3)
            if [ $? = 0 ]; then
        		case "$exitchoice" in
				'Reload')
					rm working.conf working.comp *.tmp 2> /dev/null
					current_step="init"
					;;
		        'Reboot') reboot ;;
		        'Halt') halt ;;
		        'Poweroff') poweroff ;;
		        'Shell')
		            echo "When you're done, type \"exit\" to return to HIERMA."
		            bash
		            ;;
		        esac
            fi
        else
            $exitcmd # usually reboot
        fi
	else
        # Don't keep HIERMA's mount directories upon exiting.
        if [ "$(id -un)" = "root" ]; then
            ls -1 /mnt | grep "^hierma_" > hmnt.tmp
            while read hmnt; do
                umount /mnt/$hmnt
                rmdir /mnt/$hmnt
            done < hmnt.tmp
        fi
        rm working.conf working.comp lastdir *.tmp 2> /dev/null
		exit
    fi
}

if [ "$osname" != "Linux" ]; then
# Warn the user if not running Linux, as other Unix-like systems are
# currently not supported.
dialog --title 'Warning' --yesno "You are attempting to run HIERMA on $ostype. Currently, only Linux is supported, and some of the external utilities HIERMA uses in its scripts may not work correctly.\n\nDo you still want to run HIERMA on this system?" 9 75

elif [ "$(id -un)" != "root" ]; then
dialog --title 'Notice: Not Root' --yesno "You are not running HIERMA as root. This is fine if you're only preparing a directory on a device that you have user-level write access to, but some steps will be skipped, such as mounting a disk or installing a boot manager.\n\nDo you still want to run this script?" 10 70

elif [ "$entry_opt" = "BOOTENV" ]; then
# Only provide the "Begin" button if booting from the CD.
dialog --ok-label "Begin" --title 'Welcome to HIERMA!' --msgbox "HIERMA is used to prepare hard disks for the installation of legacy operating systems quickly and easily.\n\nTo make the most of this utility, you may want to supply at least one medium containing a collection of updates and/or drivers. While HIERMA doesn't necessarily install them itself, it copies and updates files to lay everything out for your operating system, which proceeds to run its setup program with little or no user intervention. Read /doc/quikstrt.txt for more details.\n\nThis interactive routine will walk you through the steps to prepare a hard disk for installation. Ready to get started?" 16 75

elif [ "$entry_opt" = "CIGARETTE" ]; then
# This is too obvious...
dialog --msgbox "NO SMOKING" 5 16
exit 5

elif [ "$entry_opt" = "UBOOTENV" ]; then
# Do not provide user interactivity for hierma_init.sh, and do not output
# a welcome dialog or GPL notice. A configuration database needs to have
# hierma_express set to a non-zero value to allow for non-interactive use.
dialog --title 'Non-Interactive Setup' --infobox "Loading section $hsect in database $hdb_base" 3 70

else
# If running from a normal shell, provide the option to exit.
dialog --yes-label "Begin" --no-label "Exit" --title 'Welcome to HIERMA!' --yesno "HIERMA is used to prepare hard disks for the installation of legacy operating systems quickly and easily.\n\nTo make the most of this utility, you may want to supply at least one medium containing a collection of updates and/or drivers. While HIERMA doesn't necessarily install them itself, it copies and updates files to lay everything out for your operating system, which proceeds to run its setup program with little or no user intervention. Read /doc/quikstrt.txt for more details.\n\nThis interactive routine will walk you through the steps to prepare a hard disk for installation. Ready to get started?" 16 75
fi

exitstatus=$?
if [ $exitstatus = 0 ]; then
dialog --title "A Reminder..." --yes-label "OK" --no-label "Read" --yesno "Copyright (C) 2019 Kugee\n\nHIERMA is distributed under the terms of version 2 of the GNU General Public License, and you are free to distribute and/or modify it under these terms, or under any later version of the GNU GPL. While this program is distributed in the hope that it will be useful, it comes with ABSOLUTELY NO WARRANTY.\n\nYou should be able to find a copy of the GNU GPL in GPLv2.txt at the HIERMA core directory or in the root of the distribution. If this file is missing, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.\n\nSelect \"Read\" to read the full license." 18 75
if [ $? = 1 ]; then
    # Allow users to read GPLv2 and know their rights.
    # Liberate knowledge and software!
    dialog --title "GNU General Public License Version 2" --exit-label "Done" --textbox "$scriptdir/GPLv2.txt" 23 78
    # Reminder: For those unfamiliar with GPLv2, DO NOT EVER CHANGE THE
    # EXIT LABEL TO "AGREE". Agreeing is not mandatory UNLESS the user is
    # redistributing HIERMA, modified or otherwise. As such, the label
    # should respect these terms.
fi
current_step="init"
memprompt=1
while (true); do
    # The variable keeps track of which step the user is at.
    # When a case option finishes running its course, the while loop
    # runs again and moves to wherever the step variable now indicates.
    case $current_step in
    'init')
        #if [ $memprompt = 1 ]; then
            # Check installed memory only once here, and notify user if
            # it's too low.
        #    "$scriptdir/memcheck.sh"
        #    memprompt=0
        #fi

        "$scriptdir/hierma_init.sh"
        if [ $? = 0 ]; then
            #export EXPRESS=$("$scriptdir/hierma_getparm.sh" hierma_express)
            #if [ -z $EXPRESS ]; then
                # Fill it up if it is not defined in the database.
            #    export EXPRESS=0
            #fi
            # Express mode will not be supported in this release.
            # Stay tuned for beta 1.4 or something.
            export EXPRESS=0
            current_step="setdest"
        else
            hierma_exit
        fi
        ;;
	'setdest')
        udeststatus=1
        if [ $EXPRESS = 1 ]; then
            "$scriptdir/hierma_udest.sh"
            udeststatus=$?
        fi

        if [ $udeststatus = 0 ] && [ $EXPRESS = 1 ]; then
            current_step="instopt"
        else
		    "$scriptdir/hierma_setdest.sh"
		    if [ $? = 0 ]; then
			    current_step="instopt"
		    else
			    current_step="init"
		    fi
        fi
		;;
    'instopt')
        "$scriptdir/hierma_instmthd.sh"
        if [ $? = 0 ]; then
            current_step="install"
        else
            current_step="setdest"
        fi
        ;;
	'install')
		instopt=$($scriptdir/hierma_getparm.sh instopt)
		case $instopt in
			'local')
                cdexit=2
                while [ $cdexit = 2 ]; do
                    "$scriptdir/cdinstall.sh"
                    cdexit=$?
                done
                # REMINDER: GET SOURCE CODE FOR:
                # expat2, libidn, openssl, readline6
				if [ $cdexit = 0 ]; then
					current_step="config"
                else
                    current_step="instopt"
				fi
				;;
			'ftp')
                ftpexit=2
                while [ $ftpexit = 2 ]; do
                    "$scriptdir/ftpinstall.sh"
                    ftpexit=$?
                done
				if [ $ftpexit = 0 ]; then
					current_step="config"
                else
                    current_step="instopt"
				fi
				;;
			*)
				# A lack of an install method in the database is an error.
				export DIALOGRC="$scriptdir/derror"
				dialog --title "ERROR: No Install Type Specified" --msgbox "An installation method was not specified in the database, so HIERMA does not know which script to execute next. You will be taken back to the installation method dialog to specify where your operating system is to be installed from." 12 60
				unset DIALOGRC
				current_step="instopt"
				;;
		esac
		;;
    'config')
        if [ $EXPRESS = 1 ]; then
            # Don't run the configuration menu at all, just go with what's
            # set in the database when running update_msbatch.sh. Any
            # missing fields here is Windows' own problem, not mine.
            configexit=0
        else
            "$scriptdir/config_menu.sh"
            configexit=$?
        fi

        if [ $configexit = 0 ]; then
            if [ ! -f msbatch.inf ]; then
                "$scriptdir/update_msbatch.sh" CREATE
            else
                "$scriptdir/update_msbatch.sh"
            fi
            current_step="comp"
        else
            current_step="install"
        fi
        ;;
    'comp')
        if [ $EXPRESS = 1 ]; then
            # Only select components from the database:
            # TODO: Implement this, see comp.sh comments.
            compexit=0
        else
            "$scriptdir/comp.sh"
            compexit=$?
        fi

        if [ $compexit = 0 ]; then
            current_step="dcopy"
        else
            current_step="config"
        fi
        ;;
    'dcopy')
        "$scriptdir/infdcopy.sh"
        drexit=$?
        if [ $drexit = 0 ]; then
            # Skipping update dialogs for now.
            current_step="bootmgr"
        elif [ $drexit = 3 ]; then
            current_step="dcopy"
        else
            current_step="comp"
        fi
        ;;
    'updcfg')
        "$scriptdir/updates_config.sh"
        updexit=$?
        if [ $updexit = 0 ]; then
            current_step="updinst"
        elif [ $updexit = 2 ]; then
            current_step="finish"
        else
            current_step="dcopy"
        fi
        ;;
    'updinst')
        "$scriptdir/updates_install.sh"
        if [ $? = 0 ]; then
            current_step="bootmgr"
        else
            current_step="finish"
        fi
        ;;
    'bootmgr')
        "$scriptdir/hierma_bootmgr.sh"
        bootexit=$?
        echo $bootexit
        if [ $bootexit = 0 ]; then
            current_step="finish"
        elif [ $bootexit = 3 ]; then
            current_step="bootmgr"
        else
            current_step="dcopy"
        fi
        ;;
    'finish')
        "$scriptdir/hierma_finish.sh"
        if [ "$entry_opt" = "BOOTENV" ]; then
            dialog --title "Dinner's Ready!" --msgbox "HIERMA has prepared your new setup directory and is ready to reboot. If you have installed a boot manager to a hard disk, it should load the boot image and execute your setup program. Otherwise, you'll need to run the batch file from the new setup directory after loading a DOS boot disk.\n\nGood luck!" 11 75
            hierma_exit reboot
        else
            dialog --title "Dinner's Ready!" --msgbox "HIERMA has prepared your new setup directory. You can now copy it to a hard disk, a new CD, put it on a local server, or remaster the HIERMA boot CD to include it." 7 75
            # I'm hoping this isn't required.
            #unalias sed
            hierma_exit
        fi
        ;;
    esac
done
fi
