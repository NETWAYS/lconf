#
# spec file for package LConf
#
# (c) 2012-2014 Netways GmbH, support@netways.de
#
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#

%define revision 0

Name:           LConf
Summary:        LDAP based configuration tool for Icinga and Nagios
Version:        1.4.1
Release:        %{revision}%{?dist}%{?custom}
Url:            https://www.netways.org/projects/lconf
License:        GPL v2 or later
Group:          Applications/System
AutoReqProv: 	no
%if 0%{?suse_version} > 1020
BuildRequires:  fdupes
%endif
%if "%{_vendor}" == "suse"
Requires:       openldap2 >= 2.3
Requires:       openldap2-client
BuildRequires:	openldap2-client
%endif
%if "%{_vendor}" == "redhat"
Requires:       openldap >= 2.3
Requires:       openldap-clients
BuildRequires:	openldap-clients
%endif
%if "%{_vendor}" == "suse"
Recommends:     rsync
Recommends:	icinga
%endif
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

Requires:       perl(Net::LDAP)
Requires:	perl(Parallel::ForkManager) >= 0.7.6
BuildRequires:  perl(Net::LDAP)
BuildRequires:  perl(Parallel::ForkManager) >= 0.7.6

%if "%{_vendor}" == "suse"
%define slavesynccmdpipepath %{_localstatedir}/run/icinga/icinga.cmd
%endif
%if "%{_vendor}" == "redhat"
%define slavesynccmdpipepath %{_localstatedir}/spool/icinga/cmd/icinga.cmd
%endif

%define slavesynclocaldir %{_localstatedir}/spool/icinga/perfdata-local
%define slavesyncremotedir %{_localstatedir}/spool/icinga/perfdata-remote
%define slavesynccrspooldir %{_localstatedir}/spool/icinga/checkresults
%define slavesyncpid %{_localstatedir}/run/LConfSlaveSync.pid
%define slavesynclogdir %{_localstatedir}/log/icinga

%description
LConf is a LDAP based configuration tool for Icinga® and Nagios®. All
configuration elements are stored on a LDAP server and exported to text-based
configuration files. Icinga® / Nagios® uses only these config files and will
work independent from the LDAP during runtime.

%prep
#%setup -qn lconf-lconf
%setup -qn %{name}-%{version}

%build
%configure \
	--prefix="%{_datadir}/%{name}" \
	--datadir="%{_datadir}/%{name}" \
	--datarootdir="%{_datadir}/%{name}" \
	--sysconfdir="%{_sysconfdir}/%{name}" \
	--libdir="%{_libdir}/%{name}" \
	--with-temp-dir="%{_localstatedir}/spool/%{name}/lconf.tmp" \
	--with-export-script-dir="%{_libdir}/%{name}/custom" \
	--with-lconf-cli-user=icinga \
	--with-lconf-cli-group=icinga \
	--with-ldap-server="localhost" \
	--with-ldap-dn="dc=netways,dc=org" \
	--with-ldap-bind-dn="cn=Manager,dc=netways,dc=org" \
	--with-ldap-config-style=new \
	--with-icinga-user=icinga \
	--with-icinga-config="%{_sysconfdir}/icinga" \
	--with-icinga-binpath="%{_bindir}" \
	--with-slavesync-local-dir="%{slavesynclocaldir}" \
	--with-slavesync-remote-dir="%{slavesyncremotedir}" \
	--with-slavesync-checkresult-spool-dir="%{slavesynccrspooldir}" \
	--with-slavesync-extcmd-pipe-path="%{slavesynccmdpipepath}" \
	--with-slavesync-log-dir="%{slavesynclogdir}" \
	--with-slavesync-pid-file="%{slavesyncpid}"

%{__make}

%{__rm} -f contrib/*.in

%install
%{__rm} -rf %{buildroot}
%{__make} install-basic install-config \
    DESTDIR="%{buildroot}" \
    INSTALL_OPTS="" \
    INIT_OPTS=""

mkdir -p %{buildroot}%{_localstatedir}/spool/icinga/perfdata-local
mkdir -p %{buildroot}%{_sysconfdir}/icinga/lconf
mkdir -p %{buildroot}%{_localstatedir}/spool/%{name}/lconf.tmp

# user has no permission to write to /var/run directly
mkdir -p %{buildroot}%{_localstatedir}/run/%{name}

# init-script
mkdir "%{buildroot}%{_sysconfdir}/init.d"
install -m0755 contrib/lconf-slavesync "%{buildroot}%{_sysconfdir}/init.d/lconf-slavesync"
rm contrib/lconf-slavesync
sed -i -e 's|^DAEMON=/usr/local/LConf/LConfSlaveSync.pl|DAEMON=%{_bindir}/LConfSlaveSync.pl|' \
	"%{buildroot}%{_sysconfdir}/init.d/lconf-slavesync"

mkdir -p %{buildroot}%{_sysconfdir}/icinga/lconf


%pre
# Add icinga user
%{_sbindir}/groupadd lconf 2> /dev/null || :
%{_sbindir}/useradd -c "lconf" -s /sbin/nologin -r -d %{_localstatedir}/%{name} -g lconf icinga 2> /dev/null || :


%clean
%{__rm} -rf %{buildroot}


%files
%defattr(644,root,root,755)
%doc src/*.schema src/*.ldif README doc/LICENSE doc/README.RHEL doc/CHANGELOG contrib
%dir %{_libdir}/%{name}
%{_libdir}/%{name}/
%defattr(755,root,root,755)
#%dir %{_libdir}/%{name}/custom
#%config(noreplace) %{_libdir}/%{name}/custom/
%defattr(755,root,root)
%{_bindir}/*
%defattr(644,icinga,icinga,755)
%dir %{_sysconfdir}/%{name}
%dir %{_sysconfdir}/icinga/lconf
%dir %{_localstatedir}/spool/icinga/perfdata-local
%dir %{_localstatedir}/spool/%{name}
%dir %{_localstatedir}/spool/%{name}/lconf.tmp
%dir %{_localstatedir}/run/%{name}

%if ! ( "%{_vendor}" == "redhat" || 0%{?rhel} < 6 ) || ! ( "%{_vendor}" == "suse" || 0%{?sles_version} <= 1101 )
%ghost %attr(644,icinga,icinga)%{_localstatedir}/spool/%{name}/lconf.tmp/lconf.identify
%endif

%defattr(644,root,root)
%config(noreplace) %{_sysconfdir}/%{name}/*
%defattr(755,root,root)
%config(noreplace) %{_sysconfdir}/init.d/lconf-slavesync

%changelog
* Thu Mar 13 2014 Michael Friedrich <michael.friedrich@netways.de>
- update to 1.4.1

* Tue Dec 03 2013 Michael Friedrich <michael.friedrich@netways.de>
- update to 1.4.0

* Wed Oct 09 2013 Michael Friedrich <michael.friedrich@netways.de>
- update development branch to 1.4.0-0.dev

* Wed Sep 11 2013 Michael Friedrich <michael.friedrich@netways.de>
- don't install LConfDeploy automatically

* Mon Jun 24 2013 Christian Dengler <christian.dengler@netways.de>
- update to 1.3.1
- add ghost-file (file only exists if LConf-Export is running

* Mon May 27 2013 Michael Friedrich <michael.friedrich@netways.de>
- update to 1.3.0
- add doc/CHANGELOG to docs
- use correct temp dir
- remove sed orgy on slavesync and use upstream configure options

* Mon Apr 22 2013 Christian Dengler <christian.dengler@netways.de>
- add additional configure options

* Tue Mar 26 2013 Christian Dengler <christian.dengler@netways.de>
- install scripts for slave export and sync correctly
- remove them from the docs

* Wed Feb 27 2013 Markus Frosch <markus.frosch@netways.de>
- Fix directory permissions for SuSE
- Added old schema to doc file

* Thu Jan 28 2013 Christian Dengler <christian.dengler@netways.de>
- disable AutoReqProv; correct Requires

* Thu Jan 17 2013 Christian Dengler <christian.dengler@netways.de>
- adjust version number, add additional BuildRequires, fix broken macro definition

* Mon Jan 07 2013 Michael Friedrich <michael.friedrich@netways.de>
- updated using latest git changes, add rhel support

* Tue Dec 11 2012 Michael Friedrich <michael.friedrich@netways.de>
- initial version for 1.3rc, suse
