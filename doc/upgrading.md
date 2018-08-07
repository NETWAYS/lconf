# Upgrading LConf

## Upgrading from 1.4.x to 1.5.x

* TreeRewrite recursion loop has been refactored. No more process
forks but additional memory required.
* perl module Parallel::ForkManager was dropped

* New configure option '--with-ldap-person' for generating the schema.
Default empty, could be set to 'AUXILIARY'.

* There were new attributes added to the schema definition.
Please make sure to update netways.schema in your LDAP server
configuration, and apply the itemMap changes from config.pm!
**Note**: `tools/dev/update_schema_*` provide additional hints.

You will recognize the following attributes:

* host address6
* contact address1-6
* servicegroup servicegroupmembers
* contactgroup contactgroupmembers

The frontend (LConf Icinga Web or Standalone) requires an update to
1.5.x as well to use these new attributes!

If you are using Nagios (tm), make sure to set the export method in config.pm
to '0' in order to write `address6` as custom variable instead. This
has been implemented for compatibility reasons.


## Upgrading from 1.3.x to 1.4.x

* LConf Export features Icinga 2.x configuration format. Must be
configured/set on the command line.

Additional files were added:
    * default-templates.conf
    * LConfDeployIcinga2.sh

> **Note**
>
> These changes include function parameter updates and require a full
> update (except custom scripts).

* `$cfg->{ldap}->{port}` in config.pm allows to define an additional
ldap port.

* `$cfg->{export}->{format}` specifies the configuration format on export.
Can be overridden with the `--format` parameter for the export scripts.

* configure options:
    * --with-treerewrite-method=<None/MainOverLink>
    * --with-icinga2-user=<user id of icinga>
    * --with-icinga2-binpath=<path to the icinga 2 binary>
    * --with-icinga2-config=<icinga 2 configuration directory>

* new `%itemMapIcinga2` in config.pm for Icinga 2 - must be updated at all cost!!!

    Old          | New                       | Notes
  ---------------|---------------------------|--------------------------------------------------
                 | $cfg->{ldap}->{port}      | Optional ldap port. If omitted, defaults to 389.
                 | $cfg->{export}->{format}  | Optional export format. 1..Icinga1x, 2..Icinga2x


## Upgrading from 1.2.x to 1.3.x

* perl module Parallel::ForkManager (>= 0.7.6) is needed
Packages only ship 0.7.5 which is too old! The functionality
of passing data structs back from the child to the parent
is required to speed up performance during LConfExport!

* There were new attributes added to the schema definition.
Please make sure to update netways.schema in your LDAP server
configuration, and apply the itemMap changes from config.pm!

* LConf\*.pl scripts are moved into $prefix/bin by default

* custom scripts are now located in $prefix/lib/custom/
     * can be set with configure

* contrib/lconf\_deploy.sh is renamed to contrib/LConfDeploy.sh

* inheritance of attributes across main and template trees. 
This feature is disabled by default. To enable it you simply need to set a
config option in config.pm. Please let the feature disabled if you're not sure
about it or read section "TreeRewrite" of the documentation for further
information.

* new configure options
    * --with-export-script-dir=<path>  sets path to lconf export script
      			  (pre,mid,post.pl)
    * --with-temp-dir=<path>  sets path to temp directory path
    * --with-slavesync-local-dir=<path>
                          sets path to slavesync local directory path
    * --with-slavesync-remote-dir=<path>
                          sets path to slavesync remote directory path
    * --with-slavesync-checkresult-spool-dir=<path>
                          sets path to slavesync checkresult spool directory
                          path
    * --with-slavesync-extcmd-pipe-path=<path>
                          sets path to slavesync extcmd pipe path
    * --with-slavesync-pid-file=<path>
                          sets path to slavesync pid file
    * --with-slavesync-log-dir=<path>
                          sets path to slavesync log dir

* custom vars can now be used to name a service

    A servicename like: http_$_SERVICEPORT$

    can be replaced to "http_8080" when this attribute is set:

    lconfServiceCustomvar => _PORT 8080

* lconfcheckcommand is deprecated. use lconf{host,service}checkcommand instead.
LConf Web will only recognize those.

> **WARNING**
>
> Changed/New config.pm options

  Old                                                   | New                                                                   | Notes                                                                 
  ------------------------------------------------------|-----------------------------------------------------------------------|------------------------------------------------------------------------
  $cfg->{export}->{timestamp}                           | optional                                                              | this file is now located in the export directory                      
  $cfg->{export}->{hashdump}                            | optional                                                              | this file is now located in the export directory                      
  $cfg->{export}->{lockfile}                            | optional                                                              | this file is now located in the export directory                      
                                                        | $cfg->{ldap}->{rootNode} = 'LConf';                                   | newly added to reflect the ldap's root tree better                    
                                                        | $cfg->{export}->{onlydiffs} = 0;                                      | only export Config Diffs (experimental)                               
                                                        | $cfg->{export}->{childs} = 2;                                         | max Childs in parallel on LConfExport                                 
  $cfg->{slavesync}->{directIO} = '0';                  | $cfg->{slavesync}->{directIO} = '1';                                  | use spooldir for checkresults by default, not external command pipe   
                                                        | $cfg->{export}->{enablemidmaster} = 0;                                | enable mid-master.pl script for distributed setup, master cfg chg     
  $cfg->{ldap}->{dn} = 'dc=local';                      | $cfg->{ldap}->{rootDN} = 'ou='.$cfg->{ldap}->{rootNode}.',dc=local';  | renamed for better identification, requires rootNode to be set        
  $cfg->{export}->{startingpoint} = 'IcingaConfig';     | $cfg->{export}->{exportDN} = 'ou=IcingaConfig'; # below rootDN        | exportDN as starting point (no more hardcoded ou=)                    
                                                        | $cfg->{ldap}->{tls}->{verify} = 'require';                            | opt-in, newly added for ldap TLS connections                         
                                                        | $cfg->{ldap}->{tls}->{cafile} = '/etc/openldap/CA.crt';               | opt-in, newly added for ldap TLS connections                         
                                                        | $cfg->{ldap}->{tls}->{sslversion} = 'tlsv1';                          | opt-in, newly added for ldap TLS connections                          

LconfSlaveExport(Rules).pl options:

    -D|--hashdump=/path/to/LConfExport.hashdump


### Distributed Passive Master

If you installing a distributed setup, it may become necessary to install
a passive master, which still does some active checks (the easy way - disable
service checks globally in icinga.cfg).
In order to accomplish that, you will need a method to manipulate the master
config only, while leaving the slaves intact.
For that reason, you can set $cfg->{export}->{enablemidmaster} = 1 
allowing you to add your own mid-master.pl script changing values of your
hosts and services (check the icinga-web-dn.pl for some samples). These
modifications will then be written as master config exclusively while the
hashdump contains valid unmodified configs for the slaves, exported via
lconf slave export (rules).


### LConfSlaveExportRules

Within a distributed Master/Slave setup, you may encounter the problem
that you cannot export the configuration based on your trees and config
within the LConf export mechanism, but do that via pattern matching.

This is where LConfSlaveExportRules replaces LConfSlaveExport - it will
match defined attributes against a pattern, and also puts those rules against
targets for deployment, slave name and location.

Furthermore, within such a setup, with a "cut off" config mechanism, it does
not make much sense to let the slaves check parents and/or dependencies. So
in order to stay sane on this, you can disable those for the export then.

Below an example for all services having a CV with pattern 'Nuernberg', 
being exported to satelite1.icinga into /etc/icinga/lconf

    #
    # LConfSlaveExportRules.pl
    #
    $cfg->{slaveexportrules} = {
        'rules' => {
            'service-rule1' => {
                'object' => 'lconfservice',
               'attribute' => 'lconfservicecustomvar',
               'pattern' => 'Nuernberg'
            },
        },
        'targets' => {
            'satelite1.icinga' => {
               'targetDir' => '/etc/icinga/lconf',
               'rulemap' => 'service-rule1'
            },
        },
        'settings' => {
           'slaveexportparents' => 0,
           'slaveexportdependencies' => 0,
        },
    };

<!-- vi: sw=4 ts=4 expandtab : -->
