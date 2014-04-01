#!/bin/sh
#
PRODUCTNAME="ChrootJail"
VERSION="1.0.1"
RELEASE="01 Apr 2014"
COPYRIGHT="(c) Copyright by Alex Yegerev (alexriz)"
#
#####################################################################

# Functions
print_help(){
	echo "  Usage: $0 [OPTION]"
	echo "  --help      display this help and exit"
	echo "  --version   output version information and exit"
}

print_version(){
	echo "$PRODUCTNAME $VERSION $RELEASE"
	echo "$COPYRIGHT"
}

error(){
	ERR_CODE=$1 || 0
	case $ERR_CODE in
		0 ) 
			echo "  OK"
			;;
		Fail )
			echo "  Fail"
			;;
		1 ) 
			echo "  Error[$ERR_CODE]: You must be root to run this script."
			exit $ERR_CODE
			;;
		2 ) 
			echo "  Error[$ERR_CODE]: $2."
			exit $ERR_CODE
			;;
		3 ) 
			echo "  Error[$ERR_CODE]: Failed to create directory ($2)."
			exit $ERR_CODE
			;;
		4 ) 
			echo "  Error[$ERR_CODE]: $2 is undefined argument."
			exit $ERR_CODE
			;;
		5 ) 
			echo "  Error[$ERR_CODE]: Mounting error."
			exit $ERR_CODE
			;;
		6 ) 
			echo "  Error[$ERR_CODE]: Abort!."
			exit $ERR_CODE
			;;
		* ) 
			echo "  Error[$ERR_CODE]: Unknown error."
			exit $ERR_CODE
			;;
	esac
}

umount_tmpdir(){
	if umount $TMPDIR > /dev/null 2>&1;
		then error 0;
		else error 5
	fi
}

cleaner(){
	echo "Cleaning..."
	echo "Unmounting temp directory..."
	umount_tmpdir
	echo "Removing $TMPDIR directory..."
	rm -r $TMPDIR > /dev/null 2>&1
}

# Print help guide
if [[ $1 == --help ]] ; then
	print_help
	exit
fi

# Print version information
if [[ $1 == --version ]] ; then
	print_version
	exit
fi

# Check that the user root
if [[ $USER != root ]] ; then
	error 1
fi

# Check existence of necessary files
echo "Checking for which..."
if [[ -f /usr/bin/which || -f /bin/which || -f /sbin/which || -f /usr/sbin/which ]];
	then error 0;
	else error 2 "Please install which-binary!"
fi

# Checking for chroot
echo "Checking for chroot..."
if [[ $(which chroot) ]];
	then error 0;
	else error 2 "Please install chroot-package/binary!"
fi

# Checking for pacstrap
echo "Checking for pacstrap..."
if [[ $(which pacstrap) ]];
	then error 0;
	else error 2 "Please install pacstrap-package/binary!"
fi

# Specify the packages you want to install to the jail
PKG="bash filesystem util-linux openssh"

# Parse arguments
while getopts ":u:j:g:s:d:" opt; do
	case "${opt}" in
		u )
			u=${OPTARG}
			;;
		j )
			j=${OPTARG}
			;;
		g )
			g=${OPTARG}
			;;
		s )
			s=${OPTARG}
			;;
		d )
			d=${OPTARG}
			;;
		* )
			error 4 "-${opt}"
			;;
	esac
done

# pacstrap pkgs
APPS="$PKG ${s}"

# Get account settings to create
if [[ -n ${u} ]] ;
	then USERNAME=${u};
	else error 4 user
fi
if [[ -n ${j} ]] ;
	then JAIL=${j};
	else error 4 jail path
fi
if [[ -n ${g} ]] ;
	then USERGROUP=${g};
	else USERGROUP="jail"
fi
if [[ -n ${g} ]] ;
	then HOMEDIR=${d};
	else HOMEDIR="/home/${u}"
fi

echo "+------+-----------------------------------------------+"
echo "user:   $USERNAME"
echo "jail:   $JAIL"
echo "group:  $USERGROUP"
echo "pkg:    $APPS"
echo "home:   $HOMEDIR"
echo "+------+-----------------------------------------------+"

read -p "Continue? [Y/n] " CONTINUE
if [[ -n $CONTINUE && $CONTINUE != "y" ]]; then
	error 6
fi

# Make temp dir
TMPDIR=~/mnt-$RANDOM
echo "Making temp directory $TMPDIR..."
if mkdir $TMPDIR > /dev/null 2>&1;
	then error 0;
	else error 3 $TMPDIR
fi

# Make jail dir
echo "Making jail directory $JAIL..."
if mkdir $JAIL > /dev/null 2>&1 ;
	then error 0;
	else rm -r $TMPDIR
		error 3 $JAIL
fi

# Mount jail to tmpdir
echo "Mounting jail to tmpdir..."
if mount -o bind $JAIL $TMPDIR > /dev/null 2>&1;
	then error 0;
	else rm -r $TMPDIR > /dev/null 2>&1
		rm -r $JAIL > /dev/null 2>&1
		error 5
fi

# Creation environment
pacstrap $TMPDIR $APPS

# Creating necessary devices
[ -r $JAIL/dev/urandom ] || mknod $JAIL/dev/urandom c 1 9
[ -r $JAIL/dev/null ]    || mknod -m 666 $JAIL/dev/null    c 1 3
[ -r $JAIL/dev/zero ]    || mknod -m 666 $JAIL/dev/zero    c 1 5
[ -r $JAIL/dev/tty ]     || mknod -m 666 $JAIL/dev/tty     c 5 0 

# Creating user
useradd -m -d $HOMEDIR -g $USERGROUP -s /bin/bash $USERNAME

# Set password for chroot user
passwd $USERNAME

# Add users to $JAIL/etc/passwd
#
# check if file exists (ie we are not called for the first time)
# if yes skip root's entry and do not overwrite the file
grep /etc/passwd -e "^root" > $JAIL/etc/passwd
grep /etc/group -e "^root" > $JAIL/etc/group
grep /etc/shadow -e "^root" > $JAIL/etc/shadow
grep /etc/passwd -e "^$USERNAME:" >> $JAIL/etc/passwd
grep /etc/group -e "^$USERNAME:" >> $JAIL/etc/group
grep /etc/shadow -e "^$USERNAME:" >> $JAIL/etc/shadow

# Copy User home dir to chroot
cp -a $HOMEDIR $JAIL/home/

# Cleaning...
cleaner

exit