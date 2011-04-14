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
ICINGAUSER=icinga
ICINGAGROUP=icinga
ICINGABIN=$(which icinga)


if [ ! -x $ICINGABIN ] ; then
  ICINGABIN=/usr/local/icinga/bin/icinga
  if [ ! -x $ICINGABIN ] ; then
    echo "ERROR: Could not find icinga binary to check the config!"
    exit 2
  fi
fi

RUNUSER=$(whoami)
SUDOCOMMAND=""
if [ "$RUNUSER" != $ICINGAUSER ] ; then
  SUDOCOMMAND="sudo -u $ICINGAUSER"
fi


#################################################
# main
#################################################

install -d -o $ICINGAUSER -g $ICINGAGROUP $LCONFDIR
install -d -o $ICINGAUSER -g $ICINGAGROUP $LCONFTMP


# alter the icinga.cfg to check against the tmp dir
install -o $ICINGAUSER -g $ICINGAGROUP -m 640 $ICINGACONFIG $ICINGATMPCONFIG
sed 's/^\(cfg_.*\)/#lconftest#\1/' $ICINGACONFIG > $ICINGATMPCONFIG
echo cfg_dir=$LCONFTMP >> $ICINGATMPCONFIG


echo export config from LDAP
# export original full config from LDAP
(cd /usr/local/LConf/ ; $SUDOCOMMAND ./LConfExport.pl -o $LCONFTMP)
 
 
# first test the config within the tmp dir
if ( $ICINGABIN -v $ICINGATMPCONFIG ) then
 
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
  $SUDOCOMMAND -i rsync -a --del "$LCONFTMP"/ "$LCONFDIR"

  # reload the final config on the master
  echo reload config on Master $(hostname -f)
  $SUDOCOMMAND /etc/init.d/icinga reload

fi

