#!/bin/bash
# LConf deploy script 

#################################################
# config
#################################################
SATELLITS=""
for SH_ARG in $@; do
	SATELLIT="$SATELLITS $SH_ARG"
done
# Define where your icinga binary lies
ICINGABIN="/usr/local/icinga/bin/icinga"
# Path of your LConf installation
LCONFBINPATH="/usr/local/LConf"
# Define where to export the config to
LCONFDIR="/usr/local/icinga/etc/lconf"
# Define where to export the temporary config to
LCONFTMP="/usr/local/icinga/lconf.tmp"
# Define where your icinga config lies
ICINGACONFIG=/usr/local/icinga/etc/icinga.cfg
# Define where your temporary created icinga config should lie
ICINGATMPCONFIG=/usr/local/icinga/etc/icinga.tmp.cfg

ICINGAUSER="icinga"
ICINGAGROUP="icinga"

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

(cd $LCONFBINPATH ;$SUDOCOMMAND ./LConfExport.pl -o $LCONFTMP)	

if [ $? != "0" ]; then
	exit $?	
fi
(cd $LCONFBINPATH 
if [ -f ./etc/default-templates.cfg ]; then 
	$SUDOCOMMAND cp ./etc/default-templates.cfg  $LCONFTMP 
fi 
)

 
# first test the config within the tmp dir
if ( $ICINGABIN -v $ICINGATMPCONFIG ) then
 
  # copy the preliminary config in place to pass the check
  $SUDOCOMMAND -i rsync -a --del "$LCONFTMP"/* "$LCONFDIR"
 
  # generate config for satellites
  # this process may alter the original config
  # (disable checks of satellite components on the master...)
  for HOST in $SATELLIT ; do
    echo deploy config on $HOST
    (cd $LCONFBINBATH ; \
     $SUDOCOMMAND \
     $LCONFBINPATH/LConfSlaveExport.pl -H $HOST \
     -s $LCONFTMP \
     -t $LCONFDIR -v )
  done

  # copy the final config in place
  $SUDOCOMMAND rsync -a --del "$LCONFTMP"/* "$LCONFDIR"

  # reload the final config on the master
  echo reload config on Master $(hostname -f)
  $SUDOCOMMAND /etc/init.d/icinga reload
  exit $?
else 
	exit 1	
fi


