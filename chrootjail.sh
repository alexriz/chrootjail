#!/bin/sh
#
PRODUCTNAME="ChrootJail"
VERSION="1.0.0"
RELEASE="14 Feb 2014"
COPYRIGHT="(c) Copyright by Alex Yegerev (alexriz)"
#
#####################################################################

# Print help guide
if [[ $1 == --help ]] ; then
	echo "  Usage: $0 [OPTION]"
	echo "  --help      display this help and exit"
	echo "  --version   output version information and exit"
	exit
fi

# Print version information
if [[ $1 == --version ]] ; then
	echo "$PRODUCTNAME $VERSION $RELEASE"
	echo "$COPYRIGHT"
	exit
fi

# Check that the user root
if [[ $USER != root ]] ; then
	echo "Error: You must be root to run this script."
	exit 1
fi

# Check existence of necessary files
echo "Checking for which..."
if [[ -f /usr/bin/which || -f /bin/which || -f /sbin/which || -f /usr/sbin/which ]];
  then echo "  OK";
  else echo "  failed

Please install which-binary!
"
exit 2
fi

# 

exit