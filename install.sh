#!/bin/bash

# set dirs
DIR_SOURCE=./source
DIR_MAIN=`pwd`

# load functions
. $DIR_SOURCE/functions.base
. $DIR_SOURCE/functions.wizard

# welcome screen
WizardWelcome

# only run as root
if [ `id -u` != 0 ]; then
	ScriptExit "You're not root! Please run installer as root..."
fi

# check for ldap utils
ScriptOutput CHECK "ldap utils"
PROG_LDAPADD=`which ldapadd`
if [ "$?" != 0 ]; then
	ScriptExit "OS package with ldap utils is not installed"
fi

# check if perl (with ldap modules) is in place
ScriptOutput CHECK "Perl Modules"
perl -e "use strict" 2>/dev/null
if [ "$?" != 0 ]; then
	ScriptExit "Perl is not installed!";
fi

perl -e "use Net::LDAP" 2>/dev/null
if [ "$?" != 0 ]; then
	ScriptExit "Perl module 'Net::LDAP' is not installed"
fi

perl -e "use Net::LDAP::Entry" 2>/dev/null
if [ "$?" != 0 ]; then
        ScriptExit "Perl module 'Net::LDAP::Entry' is not installed"
fi

WizardAsk
echo ""

# quote $PREFIX
PREFIX_QUOTED=`echo $PREFIX | sed s/\\\\//\\\\\\\\\\\\//g`

# check ldap schema dir
ScriptOutput CHECK "LDAP schema dir"
RETURN=`ls $DIR_SCHEMA/*.schema 2>/dev/null | wc -l`
if [ $RETURN -lt 3 ]; then
	ScriptExit "$DIR_SCHEMA is not a LDAP schema directory!"
fi

ScriptOutput INSTALL "Dir structure"
install -d -o $USER -g $GROUP -m 750 $PREFIX
install -d -o $USER -g $GROUP -m 750 $PREFIX/etc
install -d -o $USER -g $GROUP -m 750 $PREFIX/var

ScriptOutput CREATE "LConf Exporter"
cat $DIR_SOURCE/LConfExport.pl.in | sed -e "s/@prefix@/$PREFIX_QUOTED/g" > $DIR_SOURCE/LConfExport.pl.tmp1
cat $DIR_SOURCE/LConfExport.pl.tmp1 | sed -e "s/@ldapprefix@/$LDAPPREFIX/g" > $DIR_SOURCE/LConfExport.pl
ScriptOutput INSTALL "LConf Exporter"
install -o $USER -g $GROUP -m 750 $DIR_SOURCE/LConfExport.pl $PREFIX/

ScriptOutput CREATE "LConf Importer"
cat $DIR_SOURCE/LConfImport.pl.in | sed -e "s/@prefix@/$PREFIX_QUOTED/g" > $DIR_SOURCE/LConfImport.pl.tmp1
cat $DIR_SOURCE/LConfImport.pl.tmp1 | sed -e "s/@ldapprefix@/$LDAPPREFIX/g" > $DIR_SOURCE/LConfImport.pl
ScriptOutput INSTALL "LConf Importer"
install -o $USER -g $GROUP -m 750 $DIR_SOURCE/LConfImport.pl $PREFIX/

ScriptOutput CREATE "LConf Slave Exporter"
cat $DIR_SOURCE/LConfSlaveExport.pl.in | sed -e "s/@prefix@/$PREFIX_QUOTED/g" > $DIR_SOURCE/LConfSlaveExport.pl.tmp1
cat $DIR_SOURCE/LConfSlaveExport.pl.tmp1 | sed -e "s/@ldapprefix@/$LDAPPREFIX/g" > $DIR_SOURCE/LConfSlaveExport.pl
ScriptOutput INSTALL "LConf Slave Exporter"
install -o $USER -g $GROUP -m 750 $DIR_SOURCE/LConfSlaveExport.pl $PREFIX/

ScriptOutput CREATE "LConf Slave Syncer"
cat $DIR_SOURCE/LConfSlaveSync.pl.in | sed -e "s/@prefix@/$PREFIX_QUOTED/g" > $DIR_SOURCE/LConfSlaveSync.pl
ScriptOutput INSTALL "LConf Slave Syncer"
install -o $USER -g $GROUP -m 750 $DIR_SOURCE/LConfSlaveSync.pl $PREFIX/

ScriptOutput CREATE "LConf config file"
cat $DIR_SOURCE/config.pm.in | sed -e "s/@domain@/$ROOTDN/g" > $DIR_SOURCE/config.pm.tmp1
cat $DIR_SOURCE/config.pm.tmp1 | sed -e "s/@user@/$USER/g" > $DIR_SOURCE/config.pm.tmp2
cat $DIR_SOURCE/config.pm.tmp2 | sed -e "s/@prefix@/$PREFIX_QUOTED/g" > $DIR_SOURCE/config.pm
ScriptOutput INSTALL "LConf config file"
install -o $USER -g $GROUP -m 700 $DIR_SOURCE/config.pm $PREFIX/etc/

ScriptOutput INSTALL "LDAP schema file"
cat $DIR_SOURCE/netways.schema.in | sed -e "s/@ldapprefix@/$LDAPPREFIX/g" > $DIR_SOURCE/netways.schema
install -o root -g root -m 644 $DIR_SOURCE/netways.schema $DIR_SCHEMA/

ScriptOutput INSTALL "Default templates"
install -o $USER -g $GROUP -m 640 $DIR_SOURCE/default-templates.cfg $PREFIX/etc/

ScriptOutput CREATE "LDAP base ldif"
cat $DIR_SOURCE/base.ldif.in | sed -e "s/@domain@/$ROOTDN/g" > $DIR_SOURCE/base.ldif

WizardManualy
