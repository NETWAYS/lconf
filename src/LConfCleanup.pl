#!/usr/bin/env perl
#
## @author Robin Schneider <robin.schneider@hamcos.de>
## @company hamcos IT Service GmbH http://www.hamcos.de
## @license GPLv2 <https://www.gnu.org/licenses/gpl-2.0.html>
## License choosen to be compatible with LConf (also licensed under GPLv2).

# Documentation {{{

=encoding UTF-8
=head1 NAME

LConfCleanup.pl - Cleanup unreferenced objects in your LConf.

=head1 DESCRIPTION

Allows you to find entries in the global OU like commands and contact groups
which are not referenced in your active LConf configuration and move them to a
different subtree.

Warning: Make sure that your last LConf export was successfully otherwise this
script might leave your LConf LDAP database in an inconsistent state.
Also make sure that the LConf export does not change while this script is
running. You can use --lconf-export-dir to point the script to a snapshot of
the directory to ensure this.

=head1 SYNOPSIS

LConfCleanup.pl [arguments]

=head1 USAGE

Connect to LDAP server as configured in /etc/LConf/config.pm, check if commands,contactgroups,contacts,hostgroups,servicegroups are referenced in the last configuration export and write LDAP commands to the specified LDIF file to move them if they are not referenced:

  ./LConfCleanup.pl --output-ldif-file /tmp/ldif


Read ./ldap_global_subtree.ldif, check if commands are referenced in the last configuration export and write LDAP commands to the specified LDIF file to move them if they are not referenced:

  ./LConfCleanup.pl --input-ldif-file ./ldap_global_subtree.ldif --output-ldif-file /tmp/ldif --entry-type commands


Connect to LDAP server as configured in /etc/LConf/config.pm, check if commands,contactgroups,contacts,hostgroups,servicegroups are referenced in the last configuration export and if not, move them in LDAP:

  ./LConfCleanup.pl --output-mode ldap --verbose

=head1 OPTIONS

=over

=item -v|--verbose [<path to logfile>]

Verbose mode. If no logfile specified, verbose output will be printed to STDOUT.

=item -d|--debug [<path to logfile>]

Debug mode. If no logfile specified, debug output will be printed to STDOUT. Debug mode implies verbose mode.

=item -n|--dry-run

Only show what would happen. Implies --verbose.

=item -e|--entry-type

Comma separated list of "entry types" (OUs in the global OU in LConf) to check.
Defaults to B<commands,contactgroups,contacts,hostgroups,servicegroups>.

=item -t|--target-subtree

The argument will be part of the new DN for unreferenced entries.
The complete target DN will look like this: ou=$entry_type,$target_subtree,$cfg->{ldap}->{rootDN}
It defaults to ou=unused.

=item -m|--output-mode

This script supports two modes. B<ldif> (default) and B<ldap>.

In B<ldif> mode this script will write the changes to the file path given by --output-ldif-file (required in this mode).

In B<ldap> mode it connects to the LDAP server as configured in /etc/LConf/config.pm and applies all the changes directly.

=item -i|--input-ldif-file

Use the given LDIF export dump instead of connecting to the LDAP server as configured in /etc/LConf/config.pm for data input.

This is unrelated to the --output-mode parameter.

=item -o|--output-ldif-file

File path to which the changes will be written to in LDIF format when --output-mode is "ldif".

=item -D|--lconf-export-dir

Directory path of LConf to use for checking if the entry is referenced. If not
given, it defaults to the directory given in /etc/LConf/config.pm as
$cfg->{export}->{tmpdir}.

=item -h|--help

Print help page.

=item -V|--version

Print LConfCleanup version.

=back

=head1 REQUIRED ARGUMENTS

Which arguments are required depends on in which output mode the script is running.

By default only the --output-ldif-file argument is required.

=head1 DEPENDENCIES

Required modules:

    Net::LDAP
    Net::LDAP::Entry
    Net::LDAP::LDIF
    File::Next

On Debian those dependencies are packaged. Just install them:

B<libfile-next-perl libnet-ldap-perl>

Additionally, you will need to have LConf installed.

=head1 CONFIGURATION

This scripts defaults to the LDAP configuration specified in F</etc/LConf/config.pm>.
Some configuration options can be overwritten using arguments. Example: --lconf-export-dir

=head1 EXIT STATUS

0   Nothing had to be done or changes where made/written successfully.

1   The script could not find any objects.

2   Any other error which which caused the script to die.

=head1 DIAGNOSTICS

Exit status is zero if no errors occur.  Errors result in a non-zero exit status and a diagnostic message being written to standard error.

=head1 BUGS AND LIMITATIONS

None that I know of. Submit patches if you find bugs :)

=head1 INCOMPATIBILITIES

None that I am aware of.

=head1 AUTHOR

Robin Schneider <robin.schneider@hamcos.de>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Robin Schneider <robin.schneider@hamcos.de>

hamcos IT Service GmbH http://www.hamcos.de

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; version 2 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=cut

# }}}

# Preamble {{{
use strict;
use warnings;
use autodie;
use utf8;
use open qw(:std :utf8);
binmode STDOUT, ':encoding(UTF-8)';
use feature qw(say);

# use feature qw(say signatures);
# signatures is still experimental … Perl …

use Net::LDAP;
use Net::LDAP::Entry;
use Net::LDAP::LDIF;

use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use File::Next;

use Data::Dump qw(dump);

# LConf includes
# use lib '@SYSCONF_DIR@';
use lib '/etc/LConf';
use config;

use lib '/usr/lib/LConf/';
use lib '/usr/lib64/LConf/';
use ldap;
use misc;

# }}}

use version; our $VERSION = qv('0.7.0');

## Global data structures {{{
use vars qw($ldap $cfg %itemMap);

my %allowed_entrie_types = (
    commands      => 1,
    contactgroups => 1,
    contacts      => 1,
    hostgroups    => 1,
    servicegroups => 1,
    timeperiods   => 1,
);

## This hash is only used in LDIF mode.
## In LDAP mode we can simply search for the wanted entry using LDAP search.
## In LDIF mode we don’t have that option.
my %DN_to_entry_hash = (
    ## "$DN" => Instance of Net::LDAP::Entry,
);

my %entry_hash = (
    ## Hash is automatically field by either a LDAP search or a LDIF file read.

    # ## entry_type
    # commands => {

    #     ## entry_name
    #     'check_coffee_machine' => {
    #         ref_count => 0,
    #     },
    # },
);
## }}}

=head1 SUBROUTINES

=over
=cut

sub check_file_if_objects_are_used { ## {{{

=item check_file_if_objects_are_used()

Check if the file $filepath uses objects from %{$entry_hash_ref}.
=cut

    my $entry_hash_ref = shift;
    my $filepath       = shift;

    ## Reading all lines of a file and `grep`ing over it performs better
    ## than going over the file line by line and run multiple regex searches on
    ## each line. This is a trade-off between RAM and CPU time where CPU time is more sacred.
    open( my $file_fh, '<:encoding(UTF-8)', $filepath );
    my @lines = <$file_fh>;
    close($file_fh);

    foreach my $entry_type ( keys %{$entry_hash_ref} ) {
        foreach my $entry_name ( keys %{ $entry_hash_ref->{$entry_type} } ) {
            $entry_hash_ref->{$entry_type}->{$entry_name}->{ref_count} +=
                scalar grep { m/\b$entry_name\b/xms } @lines;
        }
    }
} ## end sub check_file_if_objects_are_used
## }}}

sub check_if_objects_are_used { ## {{{

=item check_if_objects_are_used()

Check if objects is used in %entry_hash below $export_base_path.
=cut

    my $entry_hash_ref           = shift;
    my $export_base_path         = shift;
    my $export_base_path_escaped = quotemeta $export_base_path;

    my $file_iter = File::Next::files(
        {
            file_filter => sub {
                not $File::Next::name =~ m/
                      ^$export_base_path_escaped\/(:?
                          [^\/]+ # Only include files in subdirectories.
                          # |
                          # [^\/]+?\/(:?global)\/.+ # Skip global directory.
                          # Can not skip global directory because objects might refer to each other!
                      )
                      \z
                  /xms
                    and not $File::Next::name =~ m/~\z/xms;
                }
        },
        $export_base_path
    );

    while ( defined( my $filepath = $file_iter->() ) ) {

        DebugOutput("Parsing $filepath");

        check_file_if_objects_are_used( $entry_hash_ref, $filepath );

    }
} ## end sub check_if_objects_are_used
## }}}

sub count_monitoring_nodes { ## {{{

=item count_monitoring_nodes()

Returns the number of directories below $export_base_path.
=cut

    my $export_base_path = shift;

    opendir( my $dh, $export_base_path );
    my @number_of_monitoring_nodes =
        grep { not /^\.\.?\z/xms and -d "$export_base_path/$_" and -d "$export_base_path/$_/global" } readdir $dh;
    closedir($dh);

    DebugOutput("Monitoring nodes: @number_of_monitoring_nodes");
    DebugOutput( "Number of monitoring nodes " . scalar @number_of_monitoring_nodes );

    return scalar @number_of_monitoring_nodes;
}
## }}}

sub get_object_names_from_ldif { ## {{{

=item get_object_names_from_ldif()

Read LDIF file and write the found LDAP entries to %entry_hash.
=cut

    my $entry_hash_ref         = shift;
    my $input_ldif_file        = shift;
    my $wanted_entry_types_ref = shift;
    my $DN_to_entry_hash_ref   = shift;

    my $input_ldif = Net::LDAP::LDIF->new( $input_ldif_file, "r", onerror => 'undef' );
    unless ($input_ldif) {
        die "'$input_ldif_file' could not be read.";
    }

    while ( not $input_ldif->eof() ) {
        my $entry = $input_ldif->read_entry();
        if ( $input_ldif->error() ) {
            die "Error msg: " . $input_ldif->error() . "\n" . "Error lines:\n" . $input_ldif->error_lines() . "\n";
        }
        else {

            unless ( defined $entry->{asn}->{attributes} ) {
                warn dump $entry;

                die "AP search did not return expected attributes."
                    . " One cause could be that the cn object contains sub elements."
                    . " This is usually a mistake.";
            }

            ## We don’t care about the attributes. To avoid database/directory
            ## inconsistency, a modrdn changetype is used which moves a entity.
            # my $attrs_hash = { map { $_->{type} => $_->{vals} } @{ $entry->{asn}->{attributes} } };
            my $DN       = $entry->{asn}->{objectName};
            my $re_match = $DN =~ /^\s*?
                (?:cn=(?<entry_name>[^,]+?),) ## Might fail when comma is esapced in cn but that case is handled by the follwing match.
                ou=(?<entry_type>[^,]+?),
                ou=.*
                $/ixms;

            my $entry_type = $+{entry_type};
            my $entry_name = $+{entry_name};

            if ( $re_match and $wanted_entry_types_ref->{$entry_type} ) {
                $entry_hash_ref->{$entry_type}->{$entry_name} = {
                    ref_count => 0,

                    # entry => $entry,
                };
            }
            elsif ($DN_to_entry_hash_ref) {
                $DN_to_entry_hash_ref->{$DN} = $entry;
            }

        } ## end else [ if ( $input_ldif->error...)]
    } ## end while ( not $input_ldif->...)
    $input_ldif->done();
} ## end sub get_object_names_from_ldif
## }}}

sub get_object_names_from_ldap { ## {{{

=item get_object_names_from_ldap()

Query LDAP and write entries to %entry_hash.
=cut

    my $entry_hash_ref = shift;

    foreach my $entry_type ( keys %{$entry_hash_ref} ) {
        my $search_result = LDAPsearch(
            $ldap,
            "ou=$entry_type,ou=global,ou=IcingaConfig,"
                . $cfg->{ldap}->{rootDN},
            'sub',
            '(& (objectclass=*) (cn=*) )'

                # '(& (objectclass=*) (cn=*) (cn=check-coffee_machine) )'
                # Useful for debugging.
        );

        # warn dump %{$search_result};

        foreach my $entry_name ( sort keys %{$search_result} ) {
            my $entry_name = $search_result->{$entry_name}->{cn};
            if ( defined $entry_name ) {
                $entry_hash_ref->{$entry_type}{$entry_name}->{ref_count} = 0;
            }
            else {
                die 'CN attribute not available. Not expected to happen TM.';
            }
        }
    } ## end foreach my $entry_type ( keys...)
} ## end sub get_object_names_from_ldap
## }}}

sub rename_objects { ## {{{

=item rename_objects()

Rename objects in LDAP which have a ref count equal to the number of monitoring
nodes.
Because every monitoring node gets the same global directory which contains the
object definitions if both counts are equal than only the object definition
exists and no references to the object.
=cut

    my $entry_hash_ref       = shift;
    my $opt                  = shift;
    my $DN_to_entry_hash_ref = shift;

    my $target_subtree   = $opt->{target_subtree};
    my $output_mode      = $opt->{output_mode};
    my $output_ldif_file = $opt->{output_ldif_file};
    my $ldif;

    if ( $output_mode eq 'ldif' ) {
        $ldif = Net::LDAP::LDIF->new(
            $output_ldif_file, "w",
            onerror => 'warn',
            change  => '1',
            wrap    => 0
        );

        # $ldif->write_version();
    }

    ## Ensure that target OU where unreferenced objects will be moved to does exist.
    clone_ldap_entry(
        "ou=global,ou=IcingaConfig,$cfg->{ldap}->{rootDN}",
        "$opt->{target_subtree},$cfg->{ldap}->{rootDN}",
        { ou => 1 }, ## Filter out OU.
        $DN_to_entry_hash_ref,
        $ldif,
        $opt->{input_ldif_file},
    );

    my $ldap_result;

    foreach my $entry_type ( sort keys %{$entry_hash_ref} ) {

        my $source_dn = "ou=$entry_type,ou=global,ou=IcingaConfig,$cfg->{ldap}->{rootDN}";
        my $target_dn = "ou=$entry_type,$target_subtree,$cfg->{ldap}->{rootDN}";

        clone_ldap_entry( $source_dn, $target_dn, undef, $DN_to_entry_hash_ref, $ldif, $opt->{input_ldif_file} );

        foreach my $entry_name ( sort keys %{ $entry_hash_ref->{$entry_type} } ) {

            my $ref_count =
                $entry_hash_ref->{$entry_type}->{$entry_name}->{ref_count};
            if ( $opt->{number_of_monitoring_nodes} == $ref_count ) {
                beVerbose( 'Unreferenced Object (marked for moving)', "$entry_type: $entry_name\n" );

                unless ( $opt->{dry_run} ) {

                    if ($ldif) {
                        my $entry = Net::LDAP::Entry->new;
                        $entry->dn("cn=$entry_name,$source_dn");
                        $entry->changetype('modrdn');
                        $entry->add( "newrdn"       => "cn=$entry_name" );
                        $entry->add( "deleteoldrdn" => "1" );
                        $entry->add( "newsuperior"  => $target_dn );
                        $ldif->write_entry($entry);

                    }
                    else {
                        $ldap_result = $ldap->moddn(
                            "cn=$entry_name,$source_dn",
                            newrdn         => "cn=$entry_name",
                            "deleteoldrdn" => "1",
                            "newsuperior"  => $target_dn,
                        );

                        dump $ldap_result;
                        if ( not $ldap_result
                            or $ldap_result->{resultCode} != 0 )
                        {
                            die "Could not delete object in LDAP. Message: $ldap_result->{errorMessage}";
                        }
                    }

                } ## end unless ( $opt->{dry_run} )
            } ## end if ( $opt->{number_of_monitoring_nodes...})
            elsif ( $opt->{number_of_monitoring_nodes} > $ref_count ) {
                say "$entry_type: $entry_name was only found $ref_count time"
                    . ( $ref_count == 1 ? '' : 's' )
                    . " in the export. It is very lickly that your export is incomplete.";
                if ( $output_mode ne 'ldif' ) {
                    die 'Exiting.';
                }
            }
        } ## end foreach my $entry_name ( sort...)
    } ## end foreach my $entry_type ( sort...)
} ## end sub rename_objects
## }}}

sub add_ldap_object { ## {{{

=item add_ldap_object()

Could be used instead of copy_ldap_ou but it makes more assumptions about the LDAP structure.
=cut

    my $target_dn = shift;
    my $attrs     = shift;

    my $ldap_result = $ldap->add( $target_dn, attrs => $attrs, );

    unless ($ldap_result) {
        die "Could not create object in LDAP. Message: $ldap_result>{errorMessage}.";
    }

}
## }}}

sub clone_ldap_entry { ## {{{

=item clone_ldap_entry()

Copy LDAP object from source to target DN.
=cut

    my $source_dn            = shift;
    my $target_dn            = shift;
    my $filter_attrs         = shift;
    my $DN_to_entry_hash_ref = shift;
    my $ldif                 = shift;
    my $input_ldif_file      = shift;
    ## If $ldif is not given, do a live update against LDAP.

    die "$DN_to_entry_hash_ref not given" unless $DN_to_entry_hash_ref;

    my $ldap_result;
    my $attributes;

    if ($input_ldif_file) {
        unless ( $DN_to_entry_hash_ref->{$source_dn} ) {
            die "Internal error: $source_dn not found in \%{$DN_to_entry_hash_ref}"
                . " This error may also be caused by not matching LDAP configuration in /etc/LConf/config.pm and --input-ldif-file.";
        }
        $attributes = $DN_to_entry_hash_ref->{$source_dn}->{asn}->{attributes};

    }
    else {

        $ldap_result = $ldap->search(
            base   => $source_dn,
            scope  => 'base',
            deref  => 'never',
            filter => '(objectClass=*)',
        );

        unless ( defined $ldap_result->{entries}[0]->{asn}->{attributes} ) {
            warn dump $ldap_result;

            die "LDAP search did not return expected attributes for base '$source_dn'."
                . " One cause could be that the cn object contains sub elements."
                . " This is usually a mistake.";
        }
        $attributes = $ldap_result->{entries}[0]->{asn}->{attributes};
    }

    my @attrs =
        grep { ( $filter_attrs and not exists $filter_attrs->{ $_->{type} } ) or not $filter_attrs; } @{$attributes};

    ## Create list as expected by $ldap->add.
    my $attrs_list = [ map { ( $_->{type}, $_->{vals} ) } @attrs ];

    # warn dump $attrs_list;

    my $attrs_hash = { map { $_->{type} => $_->{vals} } @attrs };

    # warn dump $attrs_hash;

    if ($ldif) {
        my $entry = Net::LDAP::Entry->new;
        $entry->dn($source_dn);

        # $entry->changetype( 'changetype' );
        # warn dump @attrs;
        foreach my $ldap_key ( keys %{$attrs_hash} ) {
            $entry->add( "$ldap_key" => $attrs_hash->{$ldap_key} );
        }
        $ldif->write_entry($entry);

    }
    else {
        $ldap_result = $ldap->add( $target_dn, attrs => $attrs_list );

        unless ($ldap_result) {
            die "Could not create object in LDAP. Message: $ldap_result>{errorMessage}.";
        }
    }
} ## end sub clone_ldap_entry
## }}}

sub remove_unreferenced_from_hash { ## {{{

=item remove_unreferenced_from_hash()

Remove objects with reference count equal zero from %entry_hash below. Might be useful for printing the hash.
=cut

    my $entry_hash_ref = shift;

    foreach my $entry_type ( keys %{$entry_hash_ref} ) {
        foreach my $entry_name ( keys %{ $entry_hash_ref->{$entry_type} } ) {
            unless ( $entry_hash_ref->{$entry_type}->{$entry_name}->{ref_count} ) {
                delete $entry_hash_ref->{$entry_type}->{$entry_name};
            }
        }
    }
}
## }}}

sub unreferenced_objects_exist { ## {{{

=item unreferenced_objects_exist()

Return 1 if there are unreferenced objects.
=cut

    my $entry_hash_ref             = shift;
    my $number_of_monitoring_nodes = shift;

    foreach my $entry_type ( keys %{$entry_hash_ref} ) {
        foreach my $entry_name ( keys %{ $entry_hash_ref->{$entry_type} } ) {
            if ( $number_of_monitoring_nodes < $entry_hash_ref->{$entry_type}->{$entry_name}->{ref_count} ) {
                return 1;
            }
        }
    }

    return 0;
} ## end sub unreferenced_objects_exist
## }}}

sub count_objects { ## {{{

=item count_objects()

Return the number of objects.
=cut

    my $entry_hash_ref = shift;
    my $count          = 0;

    foreach my $entry_type ( keys %{$entry_hash_ref} ) {
        $count += scalar keys %{ $entry_hash_ref->{$entry_type} };
    }

    return $count;
}
## }}}

sub delete_LDAP_entry_from_objects { ## {{{

=item delete_LDAP_entry_from_objects()

Delete Net::LDAP::Entry for each element in %${entry_hash_ref}.
Useful for printing out only the ref_count.
=cut

    my $entry_hash_ref = shift;

    foreach my $entry_type ( keys %{$entry_hash_ref} ) {
        foreach my $entry_name ( keys %{ $entry_hash_ref->{$entry_type} } ) {
            delete $entry_hash_ref->{$entry_type}->{$entry_name}->{entry};
        }
    }

    return 0;
}
## }}}

=back
=cut

# command-line arguments {{{

our $opt = { ## no critic qw(Variables::ProhibitPackageVars)
    ## config.pm from LConf requires me to do that.
    entry_types      => 'commands,contactgroups,contacts,hostgroups,servicegroups',
    target_subtree   => 'ou=unused',
    output_mode      => 'ldif',
    lconf_export_dir => $cfg->{export}->{tmpdir}
};
GetOptions(
    "v|verbose:s"          => \$opt->{verbose},
    "d|debug:s"            => \$opt->{debug},
    'n|dry-run|?'          => \$opt->{dry_run},
    'e|entry-type:s'       => \$opt->{entry_types},
    't|target-subtree:s'   => \$opt->{target_subtree},
    'm|output-mode:s'      => \$opt->{output_mode},
    'i|input-ldif-file:s'  => \$opt->{input_ldif_file},
    'o|output-ldif-file:s' => \$opt->{output_ldif_file},
    'D|lconf-export-dir:s' => \$opt->{lconf_export_dir},
    'h|help|?'             => \$opt->{help},
    'version|V'            => \$opt->{version},
);

pod2usage(1) if $opt->{help};
if ( $opt->{version} ) {
    say "Version: $VERSION";
    exit(0);
}

## --dry-run and --debug imply --verbose.
$opt->{verbose} =
    ( not defined( $opt->{verbose} ) and defined( $opt->{dry_run} ) )
    ? q{}
    : $opt->{verbose};
$opt->{verbose} =
    ( not defined( $opt->{verbose} ) and defined( $opt->{debug} ) )
    ? q{}
    : $opt->{verbose};

if ( $opt->{output_mode} eq 'ldif' and not $opt->{output_ldif_file} ) {
    die "--output-ldif-file not given in LDIF mode!";
}
unless ( { 'ldif' => 1, 'ldap' => 1 }->{ $opt->{output_mode} } ) {
    die "Output mode '$opt->{output_mode}' is currently not supported!";
}

my @wanted_entry_types = split( /,\s*/xms, $opt->{entry_types} );
foreach my $entry_type (@wanted_entry_types) {

    unless ( $allowed_entrie_types{$entry_type} ) {
        die "Object type '$entry_type' is currently not supported.";
    }

    $entry_hash{$entry_type} = {};
}

# }}}

## Go Perl, go …

my $exit_code = 0;

if ( $opt->{input_ldif_file} ) {
    my %wanted_entry_types = map { $_ => 1 } @wanted_entry_types;

    get_object_names_from_ldif( \%entry_hash, $opt->{input_ldif_file}, \%wanted_entry_types, \%DN_to_entry_hash );

}
else {
    our $ldap = LDAPconnect('auth');
    get_object_names_from_ldap( \%entry_hash );
    $ldap->unbind();
    $ldap = undef;
}

check_if_objects_are_used( \%entry_hash, $opt->{lconf_export_dir} );
$opt->{number_of_monitoring_nodes} =
    count_monitoring_nodes( $opt->{lconf_export_dir} );

if ( unreferenced_objects_exist( \%entry_hash, $opt->{number_of_monitoring_nodes} ) ) {
    unless ( $opt->{input_ldif_file} ) {
        our $ldap = LDAPconnect('auth');
    }
    rename_objects( \%entry_hash, $opt, \%DN_to_entry_hash );
    unless ( $opt->{input_ldif_file} ) {
        $ldap->unbind();
        $ldap = undef;
    }
    remove_unreferenced_from_hash( \%entry_hash );
}
elsif ( count_objects( \%entry_hash ) ) {
    if ( $opt->{output_ldif_file} ) {
        if ( -f $opt->{output_ldif_file} ) {
            unlink $opt->{output_ldif_file};
        }
    }
    say "Looks good. No unreferenced objects found in LDAP/LConf.";
}
else {
    if ( $opt->{output_ldif_file} ) {
        unlink $opt->{output_ldif_file} or 1;
    }
    warn "The script could not find any objects.";
    $exit_code = 1;
}

## Not needed in %entry_hash.
# delete_LDAP_entry_from_objects( \%entry_hash );

DebugOutput( dump \%entry_hash );

exit($exit_code);
