#!/bin/sh
#
PRODUCTNAME="ChrootJail"
VERSION="1.0.0"
RELEASE="14 Feb 2014"
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
		* ) 
			echo "  Error[$ERR_CODE]: Unknown error."
			exit $ERR_CODE
			;;
	esac
}

umount_tmpdir(){
	echo "Unmounting temp directory..."
	if umount $TMPDIR;
		then error 0;
		else error 5
	fi
}

rm_tmpdir(){
	echo "Removing temp directory..."
	if rm -r $TMPDIR;
		then error 0;
		else error "Fail"
	fi
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
declare -A argTree
arg_state="def"
for arg in "$@"; do
	if echo $arg | grep -e "^-\{1,2\}[a-zA-Z0-9]" &> /dev/null ;
		then 
			case $arg in
				-a )
					arg_state="-a"
					;;
				--add )
					arg_state="-a"
					;;
				-r )
					arg_state="-r"
					;;
				--remove )
					arg_state="-r"
					;;
				-m )
					arg_state="-m"
					;;
				--mod )
					arg_state="-m"
					;;
				-d )
					arg_state="-d"
					;;
				--dir )
					arg_state="-d"
					;;
				-g )
					arg_state="-g"
					;;
				--group )
					arg_state="-g"
					;;
				-j )
					arg_state="-j"
					;;
				--jail )
					arg_state="-j"
					;;
				-S )
					arg_state="-S"
					;;
				* )
					ERR=4
					ERR_ARG=$arg
					break
					;;
			esac;
		else 
			case $arg_state in
				def )
					argTree[$arg_state]="${argTree[$arg_state]} $arg"
					;;
				-a )
					argTree[$arg_state]=$arg
					;;
				-r )
					argTree[$arg_state]=$arg
					;;
				-m )
					argTree[$arg_state]=$arg
					;;
				-d )
					argTree[$arg_state]=$arg
					;;
				-g )
					argTree[$arg_state]=$arg
					;;
				-j )
					argTree[$arg_state]=$arg
					;;
				-S )
					argTree[$arg_state]="${argTree[$arg_state]} $arg"
					;;
				* )
					ERR="Fail"
					ERR_ARG=$arg_state
					break
					;;
			esac;
	fi
done
if [[ $ERR ]]; then
	error $ERR $ERR_ARG
fi
echo "======================"
for k in ${!argTree[@]}; do
	echo "  $k: ${argTree[$k]}";
done
echo "======================"

# Make temp dir
TMPDIR=~/mnt-$RANDOM
echo "Making temp directory $TMPDIR..."
if mkdir $TMPDIR;
	then echo "  OK";
	else exit 3
fi

# Make jail dir
JAIL=/home/webdev/jail
echo "Making jail directory $JAIL..."
if mkdir $JAIL;
	then echo "  OK";
	else echo "  Fail"
		rm_tmpdir
		exit 3
fi

# Mount jail to tmpdir
echo "Mounting jail to tmpdir..."
if mount -o bind $JAIL $TMPDIR;
	then echo "  OK";
	else echo "  Fail"
fi

# Cleaning...
echo "Cleaning..."
umount_tmpdir
rm_tmpdir

exit