#!/bin/sh

PERLTIDY=`which perltidy`

for file in src/*.p{m,l}.in;
do
	if [ $file == "src/config.pm.in" ]; then
		continue;
	fi
	`$PERLTIDY -b $file -io -noll`
	rm -f $file.bak $file.ERR
done


# http://perltidy.sourceforge.net/perltidy.html
