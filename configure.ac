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

# configure options
AC_SUBST(exec_dir,[$exec_dir])

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


AC_ARG_WITH(lconf_cli_user,AC_HELP_STRING([--with-lconf-cli-user=<user>],[sets user name to run lconf on cli]),lconf_cli_user=$withval,lconf_cli_user=lconf) 
AC_SUBST(lconf_cli_user)
AC_DEFINE_UNQUOTED(DEFAULT_LCONF_CLI_USER,"$lconf_cli_user",[user name to run lconf on cli])

AC_ARG_WITH(lconf_cli_group,AC_HELP_STRING([--with-lconf-cli-group=<group>],[sets group name to run lconf on cli]),lconf_cli_group=$withval,lconf_cli_group=lconf) 
AC_SUBST(lconf_cli_group)
AC_DEFINE_UNQUOTED(DEFAULT_LCONF_CLI_GROUP,"$lconf_cli_group",[group name to run lconf on cli])

AC_ARG_WITH(ldap_server,AC_HELP_STRING([--with-ldap-server=<ip-of-ldap-server>],[sets ldap servers ip]),ldap_server=$withval,ldap_server=127.0.0.1) 
AC_SUBST(ldap_server)
AC_DEFINE_UNQUOTED(DEFAULT_LDAP_SERVER,"$ldap_server",[sets ldap servers ip])

AC_ARG_WITH(ldap_dn,AC_HELP_STRING([--with-ldap-dn=<ldap servers dn>],[sets ldap servers dn]),ldap_dn=$withval,ldap_dn='dc=netways'$comma'dc=org') 
AC_SUBST(ldap_dn)
AC_DEFINE_UNQUOTED(DEFAULT_LDAP_DN,"$ldap_dn",[sets ldap servers dn])

ldap_bind_dn='cn=admin'$comma$ldap_dn
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



# check requirements
AC_PATH_PROG([LDAPSEARCH],[ldapsearch])
if test -z $ac_cv_path_LDAPSEARCH ; then AC_MSG_ERROR([ Could not find the command 'ldapsearch'; package 'ldaputils' is installed? ]); fi 
AC_PATH_PROG([LDAPADD],[ldapadd])
if test -z $ac_cv_path_LDAPADD ; then AC_MSG_ERROR([ Could not find the command 'ldapadd'; package 'ldaputils' is installed? ]); fi
AC_MSG_NOTICE([checking for perl... ])
perl -e "use strict" 2>/dev/null
if test $? != 0; then AC_MSG_ERROR([ Could not find and exec perl; perl packages are installed? ]); fi
AC_MSG_NOTICE([checking for perl Net::LDAP... ])
perl -e "use Net::LDAP" 2>/dev/null
if test $? != 0; then AC_MSG_ERROR([ Could not find perl module 'Net::LDAP'; packages is installed? ]); fi
AC_MSG_NOTICE([checking for perl Net::LDAP::Entry... ])
perl -e "use Net::LDAP::Entry" 2>/dev/null
if test $? != 0; then AC_MSG_ERROR([ Could not find perl module 'Net::LDAP::Entry'; packages is installed? ]); fi


# exit
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
