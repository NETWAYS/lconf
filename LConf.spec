#
# spec file for package LConf
#
# (c) 2012-2013 Netways GmbH, support@netways.de
#
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#

%if "{_vendor}" == "suse"
%define installdir /srv/www/%{name}
%endif
%if "{_vendor}" == "redhat"
%define installdir /var/www/%{name}
%endif

Name:           LConf
Summary:        LDAP based configuration tool for Icinga and Nagios
Version:        1.3rc
Release:        1
Url:            https://www.netways.org/projects/lconf
License:        GPL v2 or later
Group:          System/Monitoring
%if "{_vendor}" == "suse"
BuildRequires:  apache2-devel
%if 0%{?suse_version} > 1020
BuildRequires:  fdupes
%endif
PreReq:         apache2
%endif 
Requires:       openldap2 >= 2.3
Requires:       perl(Net::LDAP)
Requires:	perl(Parallel::ForkManager) >= 0.7.6
%if "{_vendor}" == "suse"
Requires:       openldap2-client
%endif
%if "{_vendor}" == "redhat"
Requires:       openldap-clients
%endif
BuildRequires:  perl(Net::LDAP)
%if "{_vendor}" == "suse"
Recommends:     rsync
Recommends:	icinga
%endif
Source0:        %name-%version.tar.gz
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%if "{_vendor}" == "suse"
%define         apxs2 /usr/sbin/apxs2-prefork
%define         apache2_sysconfdir %(%{apxs2} -q SYSCONFDIR)
%endif

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
	--with-ldap-config-style=old

# replace dn and bind-dn later? FIXME

make

%install
%{__make} install \
    DESTDIR="%{buildroot}" \
    INSTALL_OPTS="" \
    INIT_OPTS=""

install -m0755 contrib/LConfSlaveExportRules.pl "%{buildroot}%{_bindir}/LConfSlaveExportRules.pl"
# FIXME sed all required paths
#install -m0755 contrib/LConfDeploy.sh "%{buildroot}%{_bindir}/LConfDeploy.sh"

touch %{buildroot}/var/%{name}/lconf.tmp/lconf.identify
mkdir -p %{buildroot}%{_sysconfdir}/icinga/lconf


%pre
# Add icinga user
%{_sbindir}/groupadd lconf 2> /dev/null || :
%{_sbindir}/useradd -c "lconf" -s /sbin/nologin -r -d %{_localstatedir}/%{name} -g lconf icinga 2> /dev/null || :


%clean
rm -rf %buildroot

%files
# FIXME - README.SUSE with the schema explainations (changes to dc=local)????

%defattr(644,root,root)
%doc src/*.ldif contrib README doc/LICENSE doc/README.RHEL 
%dir %{_libdir}/%{name}
%{_libdir}/%{name}/
%defattr(755,root,root)
%dir %{_libdir}/%{name}/custom
#%config(noreplace) %{_libdir}/%{name}/custom/
%defattr(755,root,root)
%{_bindir}/LConfExport.pl
%{_bindir}/LConfSlaveExport.pl
%{_bindir}/LConfSlaveExportRules.pl
%{_bindir}/LConfSlaveSync.pl
%{_bindir}/LConfImport.pl
%defattr(644,icinga,icinga)
%dir %{_localstatedir}/%{name}
%dir %{_localstatedir}/%{name}/lconf.tmp
%{_localstatedir}/%{name}/lconf.tmp
%dir %{_sysconfdir}/%{name}
%dir %{_sysconfdir}/icinga/lconf
%defattr(644,root,root)
%config(noreplace) %{_sysconfdir}/%{name}/*

%changelog
* Mon Jan 07 2013 michael.friedrich@netways.de
- updated using latest git changes, add rhel support

* Tue Dec 11 2012 michael.friedrich@netways.de
- initial version for 1.3rc, suse
