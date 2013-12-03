#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

# include some meta
m4_include([m4/version.m4])

# Which version of AC
AC_PREREQ(2.61)

# info and default prefix
AC_INIT(LConf, [LCONF_VERSION], support@netways.de)

PKG_VERSION=LCONF_VERSION
AC_SUBST(PKG_VERSION)

dnl Figure out how to invoke "install" and what install options to use.
AC_PROG_INSTALL
AC_SUBST(INSTALL)

AC_PREFIX_DEFAULT(/usr/local/LConf)

test "$prefix" = "NONE" && prefix='/usr/local/LConf'
test "$exec_prefix" = "NONE" && exec_prefix='${prefix}'

# set special stuff
exec_dir=`pwd`;
comma=,
icinga_prefix='/usr/local/icinga'

# configure options
AC_SUBST(exec_dir,[$exec_dir])

dnl cli
AC_ARG_WITH(lconf_cli_user,AC_HELP_STRING([--with-lconf-cli-user=<user>],[sets user name to run lconf on cli]),lconf_cli_user=$withval,lconf_cli_user=lconf) 
AC_SUBST(lconf_cli_user)
AC_DEFINE_UNQUOTED(DEFAULT_LCONF_CLI_USER,"$lconf_cli_user",[user name to run lconf on cli])

AC_ARG_WITH(lconf_cli_group,AC_HELP_STRING([--with-lconf-cli-group=<group>],[sets group name to run lconf on cli]),lconf_cli_group=$withval,lconf_cli_group=lconf) 
AC_SUBST(lconf_cli_group)
AC_DEFINE_UNQUOTED(DEFAULT_LCONF_CLI_GROUP,"$lconf_cli_group",[group name to run lconf on cli])

dnl ldap
AC_ARG_WITH(ldap_server,AC_HELP_STRING([--with-ldap-server=<ip-of-ldap-server>],[sets ldap servers ip]),ldap_server=$withval,ldap_server=127.0.0.1) 
AC_SUBST(ldap_server)
AC_DEFINE_UNQUOTED(DEFAULT_LDAP_SERVER,"$ldap_server",[sets ldap servers ip])

AC_ARG_WITH(ldap_dn,AC_HELP_STRING([--with-ldap-dn=<ldap servers dn>],[sets ldap servers dn]),ldap_dn=$withval,ldap_dn='dc=netways'$comma'dc=org') 
AC_SUBST(ldap_dn)
AC_DEFINE_UNQUOTED(DEFAULT_LDAP_DN,"$ldap_dn",[sets ldap servers dn])

ldap_bind_dn='cn=Manager'$comma$ldap_dn
AC_ARG_WITH(ldap_bind_dn,AC_HELP_STRING([--with-ldap-bind-dn=<ldap bind dn>],[sets ldap bind dn]),ldap_bind_dn=$withval,ldap_bind_dn=$ldap_bind_dn) 
AC_SUBST(ldap_bind_dn)
AC_DEFINE_UNQUOTED(DEFAULT_LDAP_BIND_DN,"$ldap_bind_dn",[sets ldap bind dn])

AC_ARG_WITH(ldap_bind_password,AC_HELP_STRING([--with-ldap-bind-password=<ldap bind password>],[sets ldap bind password]),ldap_bind_password=$withval,ldap_bind_password=) 
AC_SUBST(ldap_bind_password)
AC_DEFINE_UNQUOTED(DEFAULT_LDAP_BIND_PASSWORD,"$ldap_bind_password",[sets ldap bind password])

AC_ARG_WITH(ldap_prefix,AC_HELP_STRING([--with-ldap-prefix=<ldap prefix>],[sets lconf's ldap prefix]),ldap_prefix=$withval,ldap_prefix=lconf) 
AC_SUBST(ldap_prefix)
AC_DEFINE_UNQUOTED(DEFAULT_LDAP_PREFIX,"$ldap_prefix",[sets lconf's ldap prefix])

AC_ARG_WITH(ldap_config_style,AC_HELP_STRING([--with-ldap-config-style=<new/old>],[sets ldap config style; new -> cn=config; old -> slapd.conf]),ldap_config_style=$withval,ldap_config_style=new) 
AC_SUBST(ldap_config_style)
AC_DEFINE_UNQUOTED(DEFAULT_LDAP_CONFIG_STYLE,"$ldap_config_style",[sets ldap config style])

dnl icinga 1.x

AC_ARG_WITH(icinga_user,AC_HELP_STRING([--with-icinga-user=<user id of icinga>],[sets the user id of the icinga process]),icinga_user=$withval,icinga_user=icinga) 
AC_SUBST(icinga_user)
AC_DEFINE_UNQUOTED(DEFAULT_ICINGA_USER,"$icinga_user",[sets the user id of the icinga process])

AC_ARG_WITH(icinga_binpath,AC_HELP_STRING([--with-icinga-binpath=<path to the icinga binary>],[sets the path to the icinga binary]),icinga_binpath=$withval,icinga_binpath=/usr/local/icinga/bin) 
AC_SUBST(icinga_binpath)
AC_DEFINE_UNQUOTED(DEFAULT_ICINGA_BINPATH,"$icinga_binpath",[sets the path to the icinga binary])

AC_ARG_WITH(icinga_config,AC_HELP_STRING([--with-icinga-config=<icinga configuration directory>],[sets the path to the icinga config directory]),icinga_config=$withval,icinga_config=/usr/local/icinga/etc) 
AC_SUBST(icinga_config)
AC_DEFINE_UNQUOTED(DEFAULT_ICINGA_CONFIG,"$icinga_config",[icinga configuration directory])


dnl icinga 2.x
AC_ARG_WITH(icinga2_user,AC_HELP_STRING([--with-icinga2-user=<user id of icinga>],[sets the user id of the icinga 2 process]),icinga2_user=$withval,icinga2_user=icinga) 
AC_SUBST(icinga2_user)
AC_DEFINE_UNQUOTED(DEFAULT_ICINGA2_USER,"$icinga2_user",[sets the user id of the icinga 2 process])

AC_ARG_WITH(icinga2_binpath,AC_HELP_STRING([--with-icinga2-binpath=<path to the icinga 2 binary>],[sets the path to the icinga 2 binary]),icinga2_binpath=$withval,icinga2_binpath=/usr/sbin) 
AC_SUBST(icinga2_binpath)
AC_DEFINE_UNQUOTED(DEFAULT_ICINGA2_BINPATH,"$icinga2_binpath",[sets the path to the icinga 2 binary])

AC_ARG_WITH(icinga2_config,AC_HELP_STRING([--with-icinga2-config=<icinga 2 configuration directory>],[sets the path to the icinga 2 config directory]),icinga2_config=$withval,icinga2_config=/etc/icinga2)
AC_SUBST(icinga2_config)
AC_DEFINE_UNQUOTED(DEFAULT_ICINGA2_CONFIG,"$icinga2_config",[icinga 2 configuration directory])


dnl Location of export script path
EXPORTSCRIPTDIR=no
AC_ARG_WITH(export-script-dir,AC_HELP_STRING([--with-export-script-dir=<path>],[sets path to lconf export script (pre,mid,post.pl)]),EXPORTSCRIPTDIR=$withval,EXPORTSCRIPTDIR=no)
if test x$EXPORTSCRIPTDIR = xno; then
        EXPORTSCRIPTDIR="$prefix/custom"
fi
AC_SUBST(EXPORTSCRIPTDIR)

dnl Location of temp path
TMPDIR=no
AC_ARG_WITH(temp-dir,AC_HELP_STRING([--with-temp-dir=<path>],[sets path to temp directory path]),TMPDIR=$withval,TMPDIR=no)
if test x$TMPDIR = xno; then
        TMPDIR="$prefix/tmp"
fi
AC_SUBST(TMPDIR)

dnl TreeRewrite Method (default: None, Alternative: MainOverLink)
TREEREWRITEMETHOD=no
AC_ARG_WITH(treerewrite-method,AC_HELP_STRING([--with-treerewrite-method=<None|MainOverLink>],[sets treerewrite method (default: None)]),TREEREWRITEMETHOD=$withval,TREEREWRITEMETHOD=no)
if test x$TREEREWRITEMETHOD = xno; then
        TREEREWRITEMETHOD="None"
fi
AC_SUBST(TREEREWRITEMETHOD)


dnl Slave Sync

dnl Location of slave sync local dir
SLAVESYNC_LOCAL_DIR=no
AC_ARG_WITH(slavesync-local-dir,AC_HELP_STRING([--with-slavesync-local-dir=<path>],[sets path to slavesync local directory path]),SLAVESYNC_LOCAL_DIR=$withval,SLAVESYNC_LOCAL_DIR=no)
if test x$SLAVESYNC_LOCAL_DIR = xno; then
        SLAVESYNC_LOCAL_DIR="$icinga_prefix/var/perfdata-local"
fi
AC_SUBST(SLAVESYNC_LOCAL_DIR)

dnl Location of slave sync remote dir
SLAVESYNC_REMOTE_DIR=no
AC_ARG_WITH(slavesync-remote-dir,AC_HELP_STRING([--with-slavesync-remote-dir=<path>],[sets path to slavesync remote directory path]),SLAVESYNC_REMOTE_DIR=$withval,SLAVESYNC_REMOTE_DIR=no)
if test x$SLAVESYNC_REMOTE_DIR = xno; then
        SLAVESYNC_REMOTE_DIR="$icinga_prefix/var/perfdata-remote"
fi
AC_SUBST(SLAVESYNC_REMOTE_DIR)

dnl Location of slave sync checkresult spool dir
SLAVESYNC_CHECKRESULT_SPOOL_DIR=no
AC_ARG_WITH(slavesync-checkresult-spool-dir,AC_HELP_STRING([--with-slavesync-checkresult-spool-dir=<path>],[sets path to slavesync checkresult spool directory path]),SLAVESYNC_CHECKRESULT_SPOOL_DIR=$withval,SLAVESYNC_CHECKRESULT_SPOOL_DIR=no)
if test x$SLAVESYNC_CHECKRESULT_SPOOL_DIR = xno; then
        SLAVESYNC_CHECKRESULT_SPOOL_DIR="$icinga_prefix/var/spool/checkresults"
fi
AC_SUBST(SLAVESYNC_CHECKRESULT_SPOOL_DIR)

dnl Location of slave sync external command pipe
SLAVESYNC_EXTCMD_PIPE_PATH=no
AC_ARG_WITH(slavesync-extcmd-pipe-path,AC_HELP_STRING([--with-slavesync-extcmd-pipe-path=<path>],[sets path to slavesync extcmd pipe path]),SLAVESYNC_EXTCMD_PIPE_PATH=$withval,SLAVESYNC_EXTCMD_PIPE_PATH=no)
if test x$SLAVESYNC_EXTCMD_PIPE_PATH = xno; then
        SLAVESYNC_EXTCMD_PIPE_PATH="$icinga_prefix/var/rw/icinga.cmd"
fi
AC_SUBST(SLAVESYNC_EXTCMD_PIPE_PATH)

dnl Location of slave sync pid file
SLAVESYNC_PID_FILE=no
AC_ARG_WITH(slavesync-pid-file,AC_HELP_STRING([--with-slavesync-pid-file=<path>],[sets path to slavesync pid file]),SLAVESYNC_PID_FILE=$withval,SLAVESYNC_PID_FILE=no)
if test x$SLAVESYNC_PID_FILE = xno; then
        SLAVESYNC_PID_FILE="$prefix/var/LConfSlaveSync.pid"
fi
AC_SUBST(SLAVESYNC_PID_FILE)

dnl Location of slave debug log
SLAVESYNC_LOG_DIR=no
AC_ARG_WITH(slavesync-log-dir,AC_HELP_STRING([--with-slavesync-log-dir=<path>],[sets path to slavesync log dir]),SLAVESYNC_LOG_DIR=$withval,SLAVESYNC_LOG_DIR=no)
if test x$SLAVESYNC_LOG_DIR = xno; then
        SLAVESYNC_LOG_DIR="$prefix/var"
fi
AC_SUBST(SLAVESYNC_LOG_DIR)



# check requirements
AC_PATH_PROG([LDAPSEARCH],[ldapsearch])
if test -z $ac_cv_path_LDAPSEARCH ; then AC_MSG_ERROR([ Could not find the command 'ldapsearch'; package 'ldaputils' is installed? ]); fi 
AC_PATH_PROG([LDAPADD],[ldapadd])
if test -z $ac_cv_path_LDAPADD ; then AC_MSG_ERROR([ Could not find the command 'ldapadd'; package 'ldaputils' is installed? ]); fi
AC_MSG_NOTICE([checking for perl... ])
perl -e "use strict" 2>/dev/null
if test $? != 0; then AC_MSG_ERROR([ Could not find and exec perl; perl packages are installed? ]); fi

for module in Net::LDAP Net::LDAP::Entry Parallel::ForkManager; do
    AC_MSG_NOTICE([checking for perl $module... ])
    perl -e "use $module" 2>/dev/null
    if test $? != 0; then AC_MSG_ERROR([ Could not find perl module '$module'; perl package is installed? ]); fi
done

forkmanager_min="0.7.6"
AC_MSG_NOTICE([checking for perl Parallel::ForkManager version... ])
#perl -MParallel::ForkManager -Mversion -e 'my $version = version->new($Parallel::ForkManager::VERSION); my $iwant = version->new('$forkmanager_min'); print "Version found: $version\n"; exit 1 unless $version >= $iwant;'
perl -e "use  Parallel::ForkManager $forkmanager_min" 
if test $? != 0; then AC_MSG_ERROR([ perl module 'Parallel::ForkManager' needs to be at least version $forkmanager_min ]); fi


# exit
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
