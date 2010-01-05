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
install -d -g $USER -o $GROUP -m 750 $PREFIX
install -d -g $USER -o $GROUP -m 750 $PREFIX/etc

ScriptOutput CREATE "LConf Exporter"
cat $DIR_SOURCE/LConfExport.pl.in | sed s/@prefix@/$PREFIX_QUOTED/ > $DIR_SOURCE/LConfExport.pl
ScriptOutput INSTALL "LConf Exporter"
install -g $USER -o $GROUP -m 750 $DIR_SOURCE/LConfExport.pl $PREFIX/

ScriptOutput CREATE "LConf Importer"
cat $DIR_SOURCE/LConfImport.pl.in | sed s/@prefix@/$PREFIX_QUOTED/ > $DIR_SOURCE/LConfImport.pl
ScriptOutput INSTALL "LConf Importer"
install -g $USER -o $GROUP -m 750 $DIR_SOURCE/LConfImport.pl $PREFIX/

ScriptOutput INSTALL "LDAP schema file"
install -g root -o root -m 644 $DIR_SOURCE/netways.schema $DIR_SCHEMA/

ScriptOutput INSTALL "Default templates"
install -g $USER -o $GROUP -m 640 $DIR_SOURCE/default-templates.cfg $PREFIX/etc/

ScriptOutput CREATE "LConf config file"
cat $DIR_SOURCE/config.pm.in | sed s/@domain@/$ROOTDN/ > $DIR_SOURCE/config.pm
ScriptOutput INSTALL "LConf config file"
install -g $USER -o $GROUP -m 700 $DIR_SOURCE/config.pm $PREFIX/etc/

ScriptOutput CREATE "LDAP base ldif"
cat $DIR_SOURCE/base.ldif.in | sed s/@domain@/$ROOTDN/ > $DIR_SOURCE/base.ldif

WizardManualy
