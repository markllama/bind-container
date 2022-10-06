#!/usr/bin/bash

if [ -r /etc/rc.d/init.d/functions ]; then
	. /etc/rc.d/init.d/functions
else
success() {
	echo $" OK "
}

failure() {
	echo -n " "
	echo $"FAILED"
}
fi

# This script changes named UID/GID to 0

sed -i -e '/^named/s/:25/:0/g' /etc/passwd
chown 0:0 /run/named
