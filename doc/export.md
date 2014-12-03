# LConf Export

LConf consists of two modules:

* LConf Backend, holding the LDAP backend and export/import capabilities
* LConf Fromtend (Standalone Web or Icinga Web Int

## Icinga 1.x and Nagios

https://www.netways.org/projects/lconf/wiki/Wiki#Icinga-Nagios-basic-configuration

## Icinga 2.x

This export contains a migration path from LConf Backend 1.x objects to Icinga 2.x object
configuration.

There are certain limitations due to the changed configuration format
whilst introducing new features, and changing existing attributes.

https://www.netways.org/projects/lconf/wiki/Wiki#Export-Icinga-2x-Configuration-Format

* Host/Service Contacts and Contactgroups will automatically be converted into Host/Service Notification Objects, Commands and Users.
    * If there are no contact notification commands defined, the migration export does not generate any notification objects
* Depencenies and Escalations will be converted into Icinga 2.x Dependency and Notification objects
* All changed runtime macros (such as $HOSTADDRESS$) will be converted into the Icinga 2.x native runtime macros (e.g. $address$, $host.state$, etc)
* LConf Export does not use any apply rules with assign/ignore. Look into the Icinga 2 configuration documentation for details on manual configuration.

The migration export logic is integrated into `src/generate.pm` and uses helper functions
from `src/misc.pm`. The LConf LDAP TreeRewrite and config object generation happens
independant of this migration export.

The common naming schema for functions is `gen___1x` and `gen___2x`. Services are bound to
host objects by the `host_name` attribute. The `apply` keyword is not used, all
exported objects know about their single object relation already.

By default all exported objects import these templates:

  Type	             | Template
  -------------------|-------------------
  Host               | `generic-host`
  Service            | `generic-service`
  User (Contact)     | `generic-user`
  CheckCommand       | `generic-check-command`
  EventCommand       | `generic-event-command`
  NotificationCommand | `generic-notification-command`
  Notification (Host) | `mail-host-notification`
  Notification (Service) | `mail-service-notification`

### Icinga 2.x LConf Best Practice

#### Icinga 2.x Command Arguments

Icinga 2 already ships [Plugin Check Commands](http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/configuring-icinga2#plugin-check-commands)
for the most common Monitoring Plugins. Additionally you should consider defining
your own CheckCommand objects outside of the LConf LDAP tree, and only reference
the CheckCommand name as `lconfservicecheckcommand` or similar.

When it comes to passing command arguments to these CheckCommands, you can
use the Icinga 2.x custom attributes which are available as Icinga 1.x custom
variables in LConf Frontend and Backend.

* Look up the exact command argument name in the
[Icinga 2.x documentation](http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/configuring-icinga2#plugin-check-commands)
or in your own definition
* Use the old Icinga 1.x custom var notation with a leading `_` prefix and all characters upper-case

For example, defining a new `ping4` CheckCommand argument in your `properties` tab:

    lconfservicecustomvar 	| _ping_wrta 200

The Icinga 2.x migration export will make sure to remove the leading `_` character. It
will not attempt to change the string to lower case!

    vars.ping_wrta = 200

on the exported service then.


#### Icinga 2.x Apply Rules

Use [apply rules](http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#using-apply)
outside of LConf where it is reasonable to do so.

* A set of unique custom variables set for the hosts/services
* Common group membership
* Generic name pattern for hosts, allowing to apply [notifications](http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#notifications)
for all hosts and its services (same for escalations, dependencies, etc)

Manage your users and notifications outside of LConf and only ensure that your exported host and service objects
provide enough patterns for your notifications.


    apply Notification "notify-cust-xy-mysql" to Service {
      import "generic-notification"

      users = [ "noc-xy", "mgmt-xy" ]

      assign where match("*has gold support 24x7*", service.notes) && (host.vars.customer == "customer-xy" || host.vars.always_notify == true
      ignore where match("*internal", host.name) || (service.vars.priority < 2 && host.is_clustered == true)
    }



### Icinga 2.x LConf Limitations

While it is still reasonable to organize host and service objects and their attributes
inside the LConf LDAP tree, the migration export does not use any sorts of
[apply rules](http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#using-apply)
supported by Icinga 2.

#### Converting Contacts to Notificiations

Notifications have been revamped and changed in Icinga 2.x so there are certain requirements
to allow the LConf export a migration.

Icinga 1.x uses the `host/service -> contact -> host/service_notification_commands` logic
for generating notifications on alerts.

Icinga 2.x introduces a new `Notification` object for host and service objects defining
a type (and optional escalation) and the users and usergroups, as well as the required
`NotificationCommand`.

There is an ugly workaround for migration the old contacts notification style into the
new `Notification` objects, but this required the following conditions met:

* host/service objects have `contacts` and `contactgroups` set
* all contacts for host/service objects **must** have at least one `host_notification_command`
and `service_notification_command` defined

If one of these requirements is missing, the migration export will not generate any notification
object.

> **Note**
>
> The relation `host/service -> contacts -> notification_command` will generate one `Notification`
> object per command per contact per host/service. This is certainly something you do not want
> for readability and maintenance. Consider using notification apply rules instead.

The LConf exporter works in a similar fashion as described [here](http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/migration#manual-config-migration-hints-notifications).

This hack might increase the LConfExport.pl runtime in larger setups.

#### Mapping Custom Variables to Custom Attributes

The Icinga 1.x style of defining a custom variable in LConf still uses the `_` prefix.

    lconfservicecustomvar 	| _MYCUSTOMVAR This is a test.

The Icinga 2.x LConf export will remove the `_` prefix and add the key to
the `vars` dictionary. If the custom variable value is empty, a warning is logged
on export and the custom variable is skipped.

#### Mapping Groups

All groups in Icinga 1.x a separated by a comma `,` (with our without trailing whitespaces).

    lconfhostgroups 	| webserver, testserver , internalserver

The Icinga 2.x LConf export converts this comma-separated list into the Icinga 2.x
array notation as double-quoted strings.

    groups = [ "webserver", "testserver", "internalserver" ]

#### Mapping Host Alias

Icinga 2.x only supports the `display_name` attribute. Therefore the LConf export
overwrites the `display_name` attribute with lconfhostalias if set.

#### Mapping Intervals

`check_interval`, `retry_interval` and `notification_interval` automatically get
the `m` suffix making them minute durations in Icinga 2.x.

#### Mapping Notification and Dependency Options to Type and State Filters

The Icinga 1.x notation of `w,u,c,r,f,s` and more is converted
into Icinga 2.x type and state filters.

`src/misc.pm` contains the functions

* convert_notification_options_to_filter_2x
* convert_dependendy_failure_criteria_2x

#### Mapping Commands

All LConf Icinga 1.x commands are treated as `CheckCommand` objects by default
(which means, they are not copied again).
All notification and eventhandler commands are copied from the check commands
and get their exclusive type assigned. They are collected into the host object configuration
file, similar to dependencies.

The command objects defined in LConf backend will be exported as is, only the double quote character `"`
is escaped with a leading slash `\"` in the command line.

#### Mapping ARGn Command Arguments

The LConf export for Icinga 2.x splits the `check_command` string by `!` and assumes each token
following the `ARGn` schema.

    lconfservicecheckcommand | ping4!100!20!200!40

will be converted to

    check_command = "ping4"
    vars.ARG1 = 100
    vars.ARG2 = 20
    vars.ARG3 = 200
    vars.ARG4 = 40

If custom variables are used as command arguments like `$_HOSTMYCUSTOMVAR$`, the export
logic tries to fetch its current value from the host or service object and pass that directly
into `vars.ARG...` as new value.

#### Mapping Command Runtime Macros

Furthermore all runtime macros will be converted to the respective
[Icinga 2.x supported runtime macros](http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/migration#differences-1x-2-runtime-macros).
LConfExport.pl will log warnings for runtime macros which cannot be converted.

`$USER1$` is not replaced, as it may be used for a different use case than just the PluginDir.
Instead, all exported LConf command objects automatically inherit from a template defined in
`default-templates.conf` which sets the `vars.USER1` custom attribute to the `PluginDir` constant.
That way you can easily control the mapping between global 1.x USER macros and Icinga 2.x global
constants.

    template CheckCommand "generic-check-command" {
      import "plugin-check-command"
      vars.plugindir = PluginDir
      vars.USER1 = PluginDir
    }

Take the following example from LConf frontend configuration for command objects:

    lconfcommandline | $USER1$/check_ping -H $HOSTADDRESS$ -w $ARG1$,$ARG2$% -c $ARG3$,$ARG4$%

will be converted to

    import "generic-check-command"
    command = "$USER1$/check_ping -H $address$ -w $ARG1$,$ARG2$% -c $ARG3$,$ARG4$%"


`src/misc.pm` contains the function for converting all legacy macros to Icinga 2.x runtime macros.

* convert_legacy_command_macros_2x


#### Converting Host Parents to Host Dependencies

There are only host dependencies in Icinga 2.x. The LConf export takes care of converting
the parent host(s) into host dependencies added to this host object.

#### Converting Escalations to Notifications

All host and service escalations from Icinga 1.x are converted into Icinga 2.x `Notification`
objects with a `begin` and `end` time range.

    begin = first_notification * notification_interval
    end = last_notification * notification_interval




