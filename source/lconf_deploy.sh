#!/bin/bash
# LConf deploy script 

#################################################
# config
#################################################

SATELLIT="satellit1 satellit2 satellit3"
LCONFDIR="/etc/icinga/lconf"
LCONFTMP="/etc/icinga/lconf.tmp"
ICINGACONFIG=/etc/icinga/icinga.cfg
ICINGATMPCONFIG=/etc/icinga/icinga.tmp.cfg

RUNUSER=$(whoami)
SUDOCOMMAND=""
if [ "$RUNUSER" != "icinga" ] ; then
  SUDOCOMMAND="sudo -u icinga"
fi


#################################################
# main
#################################################

install -d -o icinga -g icinga $LCONFDIR
install -d -o icinga -g icinga $LCONFTMP


# alter the icinga.cfg to check against the tmp dir
install -o icinga -g icinga -m 640 $ICINGACONFIG $ICINGATMPCONFIG
sed 's/^\(cfg_.*\)/#lconftest#\1/' $ICINGACONFIG > $ICINGATMPCONFIG
echo cfg_dir=$LCONFTMP >> $ICINGATMPCONFIG


echo export config from LDAP
# export original full config from LDAP
(cd /usr/local/LConf/ ; $SUDOCOMMAND ./LConfExport.pl -o $LCONFTMP)
 
 
# first test the config within the tmp dir
if ( icinga -v $ICINGATMPCONFIG ) then
 
  # copy the preliminary config in place to pass the check
  $SUDOCOMMAND rsync -a --del "$LCONFTMP"/* "$LCONFDIR"
 
  # generate config for satellites
  # this process may alter the original config
  # (disable checks of satellite components on the master...)
  for HOST in $SATELLIT ; do
    echo deploy config on $HOST
    (cd /usr/local/LConf/ ; \
     $SUDOCOMMAND \
     ./LConfSlaveExport.pl -H $HOST \
     -s $LCONFTMP \
     -t $LCONFDIR -v )
  done

  # copy the final config in place
  $SUDOCOMMAND rsync -a --del "$LCONFTMP"/* "$LCONFDIR"

  # reload the final config on the master
  echo reload config on Master $(hostname -f)
  $SUDOCOMMAND /etc/init.d/icinga reload

fi

