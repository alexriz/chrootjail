ChrootJail
==========

ChrootJail for ArchLinux

	Usage: $0 [OPTION]
	-u    Set user name
	-j    Set jail directory
	-g    Set user group (def.: jail)
	-s    Set additional package
	-d    Set home directory
	--help      display this help and exit
	--version   output version information and exit

How to install
==========
	git clone git@github.com:alexriz/chrootjail.git
	cd chrootjail
	sudo make install

Example
==========
	sudo jailadd.sh -u testuser -g jail -j /srv/jail/testuser -s "nano mc" -d /home/testuser