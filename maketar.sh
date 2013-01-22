#!/bin/bash
###
# Make a tarball
# (c) 2012 NETWAYS GmbH
# by Markus Frosch <markus.frosch@netways.de
###

name="LConf"
gitbranch=`git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/^\* //' -e 's/\//_/g' -e 's/[^A-Za-z0-9\-\_]//g'`
githash=`git log --no-color -n 1 | head -n 1 | sed -e 's/^commit //' | head -c 8`

# pack initial package
git archive --worktree-attributes \
    -o ../$name-$gitbranch-$githash.tar.gz \
    --prefix=$name-$gitbranch-$githash/ \
    HEAD


