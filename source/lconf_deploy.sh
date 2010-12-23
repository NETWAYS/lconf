#!/bin/bash
# LConf deploy script 

#################################################
# config
#################################################

SATELLIT="satellit1 satellit2 satellit3"
LCONFDIR="/etc/icinga/lconf"
LCONFTMP="/etc/icinga/lconf.tmp"


#################################################
# main
#################################################

install -d -o icinga -g icinga $LCONFDIR
install -d -o icinga -g icinga $LCONFTMP


echo export config from LDAP
# export original full config from LDAP
(cd /usr/local/LConf/ ; sudo -u icinga ./LConfExport.pl -o $LCONFTMP)

# copy the preliminary config in place to pass the check
rsync -a --del "$LCONFTMP"/* "$LCONFDIR"

# generate config for satellites
# this process may alter the original config
# (disable checks of satellite components on the master...)
if ( icinga -v /etc/icinga/icinga.cfg ) then
  
  for HOST in $SATELLIT ; do
    echo deploy config on $HOST
    (cd /usr/local/LConf/ ; \
     sudo -u icinga \
     ./LConfSlaveExport.pl -H $HOST \
     -s $LCONFTMP \
     -t $LCONFDIR -v )
  done

  # copy the final config in place
  rsync -a --del "$LCONFTMP"/* "$LCONFDIR"

  # reload the final config on the master
  echo reload config on Master $(hostname -f)
  /etc/init.d/icinga reload

fi

