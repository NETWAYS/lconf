#
# spec file for package LConf
#
# (c) 2012-2013 Netways GmbH, support@netways.de
#
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#


Name:           LConf
Summary:        LDAP based configuration tool for Icinga and Nagios
Version:        1.3.0rc2
Release:        4%{?dist}%{?custom}
Url:            https://www.netways.org/projects/lconf
License:        GPL v2 or later
Group:          System/Monitoring
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
Source0:        %name-%version.tar.gz

BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

Requires:       perl(Net::LDAP)
Requires:	perl(Parallel::ForkManager) >= 0.7.6
BuildRequires:  perl(Net::LDAP)
BuildRequires:  perl(Parallel::ForkManager) >= 0.7.6


%description
LConf is a LDAP based configuration tool for Icinga® and Nagios®. All
configuration elements are stored on a LDAP server and exported to text-based
configuration files. Icinga® / Nagios® uses only these config files and will
work independent from the LDAP during runtime.

%prep
%setup -qn lconf-lconf

%build
%configure \
	--prefix="%{_datadir}/%{name}" \
	--datadir="%{_datadir}/%{name}" \
	--datarootdir="%{_datadir}/%{name}" \
	--sysconfdir="%{_sysconfdir}/%{name}" \
	--libdir="%{_libdir}/%{name}" \
	--with-temp-dir="%{_localstatedir}/%{name}/lconf.tmp" \
	--with-export-script-dir="%{_libdir}/%{name}/custom" \
	--with-lconf-cli-user=icinga \
	--with-lconf-cli-group=icinga \
	--with-ldap-server=localhost \
	--with-ldap-dn="dc=local" \
	--with-ldap-bind-dn="cn=Manager,dc=local" \
	--with-ldap-config-style=old \
	--with-icinga-user=icinga \
	--with-icinga-config="%{_sysconfdir}/icinga" \
	--with-icinga-binpath="%{_bindir}"

# replace dn and bind-dn later? FIXME

make

%install
%{__make} install \
    DESTDIR="%{buildroot}" \
    INSTALL_OPTS="" \
    INIT_OPTS=""

# LConfDeploy
install -m0755 contrib/LConfDeploy.sh "%{buildroot}%{_bindir}/LConfDeploy.sh"
sed -i -e 's|^ICINGABIN="/usr/local/icinga/bin/icinga"|ICINGABIN="%{_bindir}/icinga"|' \
    -e 's|^LCONFDIR="/usr/local/icinga/etc/lconf"|LCONFDIR="%{_sysconfdir}/icinga/lconf"|' \
    -e 's|^LCONFTMP="/usr/local/icinga/lconf.tmp"|LCONFTMP="%{_localstatedir}/spool/%{name}/lconf.tmp"|' \
    -e 's|^ICINGACONFIG=/usr/local/icinga/etc/icinga.cfg|ICINGACONFIG=%{_sysconfdir}/icinga/icinga.cfg|' \
    -e 's|^ICINGATMPCONFIG=/usr/local/icinga/etc/icinga.tmp.cfg|ICINGATMPCONFIG=%{_localstatedir}/spool/%{name}/icinga.tmp.cfg|' \
	"%{buildroot}%{_bindir}/LConfDeploy.sh"
rm contrib/LConfDeploy.sh{,.in}
mkdir -p %{buildroot}%{_localstatedir}/spool/icinga/perfdata-local
mkdir -p %{buildroot}%{_sysconfdir}/icinga/lconf
mkdir -p %{buildroot}%{_localstatedir}/spool/%{name}/lconf.tmp
# user has not right to write in /var/run directly
mkdir -p %{buildroot}%{_localstatedir}/run/%{name}
# init-script
mkdir "%{buildroot}%{_sysconfdir}/init.d"
install -m0755 contrib/lconf-slavesync "%{buildroot}%{_sysconfdir}/init.d/lconf-slavesync"
rm contrib/lconf-slavesync{,.in}
sed -i -e 's|^DAEMON=/usr/local/LConf/LConfSlaveSync.pl|DAEMON=%{_bindir}/LConfSlaveSync.pl|' \
	"%{buildroot}%{_sysconfdir}/init.d/lconf-slavesync"
# change config for master-slave setups
sed -i -e 's|/var/LConf/lconf.tmp|%{_localstatedir}/spool/%{name}/lconf.tmp|' \
    -e 's|/usr/local/icinga/var/perfdata-local|/var/spool/icinga/perfdata-local|' \
    -e 's|/usr/local/icinga/var/perfdata-remote|/var/spool/icinga/perfdata-remote|' \
    -e 's|/usr/local/icinga/var/spool/checkresults|/var/spool/icinga/checkresults|' \
    -e 's|/usr/local/icinga/var/rw/icinga.cmd|/var/spool/icinga/cmd/icinga.cmd|' \
    -e 's|/var/LConfSlaveSync.pid|/var/run/Lconf/LConfSlaveSync.pid|' \
    -e 's|/var/LConfSlaveSync.debug|/var/log/icinga/LConfSlaveSync.debug|' \
	"%{buildroot}%{_sysconfdir}/%{name}/config.pm"


%if "%{_vendor}" == "suse"
touch %{buildroot}/var/%{name}/lconf.tmp/lconf.identify
%endif
mkdir -p %{buildroot}%{_sysconfdir}/icinga/lconf


%pre
# Add icinga user
%{_sbindir}/groupadd lconf 2> /dev/null || :
%{_sbindir}/useradd -c "lconf" -s /sbin/nologin -r -d %{_localstatedir}/%{name} -g lconf icinga 2> /dev/null || :


%clean
rm -rf %buildroot

%files
# FIXME - README.SUSE with the schema explainations (changes to dc=local)????

%defattr(644,root,root,755)
%doc src/*.schema src/*.ldif contrib README doc/LICENSE doc/README.RHEL 
%dir %{_libdir}/%{name}
%{_libdir}/%{name}/
%defattr(755,root,root,755)
%dir %{_libdir}/%{name}/custom
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


%defattr(644,root,root)
%config(noreplace) %{_sysconfdir}/%{name}/*
%defattr(755,root,root)
%config(noreplace) %{_sysconfdir}/init.d/lconf-slavesync

%changelog
* Mon Apr 22 2013 christian.dengler@netways.de
- add additional configure options

* Tue Mar 26 2013 christian.dengler@netways.de
- install scripts for slave export and sync correctly
- remove them from the docs

* Wed Feb 27 2013 Markus Frosch <markus.frosch@netways.de>
- Fix directory permissions for SuSE
- Added old schema to doc file

* Thu Jan 28 2013 christian.dengler@netways.de
- disable AutoReqProv; correct Requires

* Thu Jan 17 2013 christian.dengler@netways.de
- adjust version number, add additional BuildRequires, fix broken macro definition

* Mon Jan 07 2013 michael.friedrich@netways.de
- updated using latest git changes, add rhel support

* Tue Dec 11 2012 michael.friedrich@netways.de
- initial version for 1.3rc, suse
