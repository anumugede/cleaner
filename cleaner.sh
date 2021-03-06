#!/bin/bash

#########################################################################################################
## Linux System Cleaning Script
##
## Code by	: Dimas Toha Pramawitra (Lonehack)
##			  <dms.pram@gmail.com>
## Created	: 04 Feb 2014
## Modified	: 13 Jun 2016
##
## This code is released to the public domain.
## You can use, modify, or distribute this code as you need without any restriction.
#########################################################################################################
## Feature
## - Clean packages cache
## - Remove old config files
## - Remove old kernels
## - Clean Trash
## - Clean swap and memory cache
##
## Suported OS
## - Debian based
## - RHEL based
## - SuSe based
#########################################################################################################

YELLOW="\033[1;33m"
RED="\033[1;31m"
WHITE="\033[1;37m"
ENDCOLOR="\033[0m"

#########################################################################################################
## help
#########################################################################################################

inv_help() {
	echo "$0 help				: Show help"
	echo "sudo $0				: basic cleaning (interactive)"
	echo "sudo $0 [OPTION]		: non-interactive"
	exit 0
}

com_help () {
	echo "$0 help			: Show this help and exit"
	echo "sudo $0			: basic cleaning (interactive)"
	echo "sudo $0 [OPTION]	: non-interactive"
	echo "Option :"
	echo "	-c|--clean		: Packages cleaning"
	echo "	-m|--memory		: Clean memory cache"
	echo "	--swap			: Clean swap"
	echo "	--big			: Show 10 biggest files in Home"
	echo "	--info			: Show storage & memory info"
	exit 0
}

if [ "$1" = "help" ];then
	com_help
fi

## User check
if [ $USER != root ]; then
	echo -e $RED"Error: must be root"$ENDCOLOR
	echo "Use sudo $0 or su -c $0"
	inv_help
	echo -e $YELLOW"Exiting..."$ENDCOLOR
	exit 0
fi

#########################################################################################################
## Error handler
#########################################################################################################

invalid () {
	echo -e $RED"Error : $1 : Invalid command!!!"$ENDCOLOR
	inv_help
}

error_check () {
	if [ "$?" = "1" ]; then
		echo -e $RED"Error : $1"$ENDCOLOR 1>&2
		exit 1
	fi
}

# abort when Ctrl+C pressed
trap ctrl_c INT
function ctrl_c() {
	echo -e $RED"Terminated by User!"$ENDCOLOR
	exit 0
}

#########################################################################################################
## Check & Initialization
#########################################################################################################

echo "Initialing ..."
## Distribution check & initialization
if [ -f /etc/debian_version ];then
	DIST="debian"
	PKG=$(which dpkg)
	PKGMGR=$(which apt-get)
	CLEAN="clean"
	DEL="purge"
elif [ -f /etc/redhat-release ];then
	DIST="redhat"
	PKG=$(which rpm)
	PKGMGR=$(which dnf)
	CLEAN="clean all"
	DEL="erase"
	if [ -z "$PKGMGR" ];then
		PKGMGR=$(which yum)
	fi
elif [ -f /etc/SuSe-release ];then
	DIST="Suse"
	PKG=$(which rpm)
	PKGMGR=$(which zypper)
	CLEAN="clean -a"
	DEL="remove"
else
	echo -e $RED"Your Linux Distribution not yet supported by this script"$ENDCOLOR
	echo -e $YELLOW"Install manualy or edit this script for your need"$ENDCOLOR
	exit 0
fi

#########################################################################################################
## Functions
#########################################################################################################

clean() {
	OLDCONF=$($PKG -l | grep "^rc" | awk '{print $2}')
	CURKERNEL=$(uname -r | sed 's/-*[a-z]//g' | sed 's/-386//g')
	LINUXPKG="linux-(image|headers|ubuntu-modules|restricted-modules)"
	METALINUXPKG="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"
	OLDKERNELS=$($PKG -l | awk '{print $2}' | grep -E $LINUXPKG | grep -vE $METALINUXPKG | grep -v $CURKERNEL)
	echo -e $YELLOW"Cleaning packages cache..."$ENDCOLOR
	$PKGMGR $CLEAN
	echo -e $YELLOW"Clean packages cache done!"$ENDCOLOR

	echo -e $YELLOW"Removing old config files..."$ENDCOLOR
	$PKGMGR $DEL $OLDCONF
	echo -e $YELLOW"Remove old config done!"$ENDCOLOR

	echo -e $YELLOW"Removing old kernels..."$ENDCOLOR
	$PKGMGR $DEL $OLDKERNELS
	echo -e $YELLOW"Remove old kernels done!"$ENDCOLOR

	echo -e $YELLOW"Emptying every trashes..."$ENDCOLOR
	rm -rf /home/*/.local/share/Trash/*/** &> /dev/null
	rm -rf /root/.local/share/Trash/*/** &> /dev/null
	echo -e $YELLOW"Trash cleaned!"$ENDCOLOR
}

swap_clean() {
	echo -e $YELLOW"Cleaning swap"$ENDCOLOR
	/sbin/swapoff -a
	/sbin/swapon -a
	echo -e $YELLOW"Clean swap done!"$ENDCOLOR
}

mem_clean() {
	echo -e $YELLOW"Cleaning memory cache..."$ENDCOLOR
	sync && echo 3 | tee /proc/sys/vm/drop_caches
	echo -e $YELLOW"Clean memory cache done!"$ENDCOLOR
}

result() {
	MOUNT=$(df -h)
	MEM=$(free -h)
	echo -e $YELLOW"Mounted drive info :"$ENDCOLOR
	echo "$MOUNT"
	echo -e $YELLOW"Memory usage :"$ENDCOLOR
	echo "$MEM"
}

list_big() {
	BIG=$(find $HOME -type f -size +1024k -print0 | xargs -0 ls -1hsS | head -n 10)
	echo -e $YELLOW"Biggest file :"$ENDCOLOR
	echo "$BIG"
}

#########################################################################################################
## main script
#########################################################################################################
if [ ! -z "$1" ];then
	## option
	for i in "$@" ;do
		case $i in
			-c|--clean)
			clean
			shift
			;;
			-m|--memory)
			mem_clean
			shift
			;;
			--swap)
			swap_clean
			shift
			;;
			--big)
			list_big
			shift
			;;
			--info)
			result
			;;
			*)
			invalid "$i" # unknown option
			;;
		esac
	done
	echo -e $YELLOW"Script Finished!"$ENDCOLOR
	exit 0
else
	clean
	echo -e $WHITE"We will clean your swap and memory"$ENDCOLOR
	echo -e $WHITE"sometimes we need to clean some memory cache in RAM"$ENDCOLOR
	echo -e $RED"But cleaning cache may slow the system down"
	echo -e "when reopen applications"$ENDCOLOR
	read -rsp $'Clean swap and memory cache? <y/N>\n' -n 1 key
	if [[ "$key" =~ ^[Yy]$ ]]; then
		# y pressed
		swap_clean
		mem_clean
	fi

	echo -e $WHITE"Showing Result..."$ENDCOLOR
	result

	read -rsp $'List 10 biggest file in Home? <y/N>\n' -n 1 key
	if [[ "$key" =~ ^[Yy]$ ]]; then
		# y pressed
		echo -e $YELLOW"Please wait, it will take long..."$ENDCOLOR
		list_big
	fi
	echo -e $YELLOW"Script Finished!"$ENDCOLOR
	exit 0
fi
