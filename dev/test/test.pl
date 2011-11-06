#!/usr/bin/perl -w

# COPYRIGHT:
#
# This software is Copyright (c) 2011 NETWAYS GmbH
#                                <support@netways.de>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from http://www.fsf.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.fsf.org.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to NETWAYS GmbH.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# this Software, to NETWAYS GmbH, you confirm that
# you are the copyright holder for those contributions and you grant
# NETWAYS GmbH a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# Nagios and the Nagios logo are registered trademarks of Ethan Galstad.

=head1 NAME

test.pl - LConf Test-Framework

=head1 SYNOPSIS

test.pl		[-a]
			[-s <test number>]
			[-l]
			[-i]
			[-v]
			[-h]
			[-V]
				
LConf Test-Framework

=head1 OPTIONS

=over

=item -a|-all

Test package with all testcases

=item -s|--single <test number>

Do a single testcase

=item -l|--list

List all testcases

=item -i|--initialize

Initialize the ldap server for testing

=item -v|--verbose [<path to logfile>]

Verbose mode. If no logfile specified, verbose output will be printed to STDOUT

=item -h|--help

print help page

=item -V|--version

print plugin version

=cut

# set libs
use lib '/tmp/LConf-1.2-install-test/';

# includes
use strict;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use Net::LDAP;
use etc::config;
use lib::ldap;
use lib::misc;
use lib::test_ldap;

# version string
my $version = '1.2';

# define states
our @state = ('OK', 'WARNING', 'ERROR', 'UNKNOWN');

# get command-line parameters
our $opt;
GetOptions(
	"a|all"			=> \$opt->{all},
	"s|single=s"	=> \$opt->{single},
	"l|list"		=> \$opt->{list},
	"i|initialize"	=> \$opt->{initialize},
	"v|verbose:s"	=> \$opt->{verbose},
	"h|help"		=> \$opt->{help},
	"V|version"		=> \$opt->{version}
);


# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #
# help and version page
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #

# should print version?
if (defined $opt->{version}) { print $version."\n"; exit 0; }

# should print help?
if ($opt->{help}) { pod2usage(1); }
if (!$opt->{all} && !$opt->{single} && !$opt->{list} && !$opt->{initialize}) { pod2usage(1); }


# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #
# let's go!
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #

# define vars
use vars qw($cfg);
my $testcases;
my $result;

# set default output
$result->{message}  = "No Errors!";
$result->{errcount} = 0;
$result->{code}     = 0;

# check current dir
if ($ENV{'PWD'} !~ /test$/) {
	print $state[3]." - You're not in directory 'test'\n";
	exit 3;	
}

# get all testcases
opendir(DIRHANDLE, "./cases/") || die "Can't open dir: $!";
my @files = readdir(DIRHANDLE);
closedir DIRHANDLE;
foreach(@files) {
	if ("$_" !~ /^\./ && "$_" !~ /ldif$/) {
		$testcases->{$_}->{name} = $_;
	}
}

# a single testcase?
if (defined $opt->{single}) {
	my $tmphash;
	foreach(keys %{$testcases}) { if ($_ =~ /^$opt->{single}/) { $tmphash->{$_}->{name} = $_; } }
	$testcases = $tmphash;
}

# list only?
if (defined $opt->{list}) {	
	foreach(sort keys %{$testcases}) {
		if ($_ !~ /^0000_/) {
			print $_."\n";
		}
	}
	exit 0;
}

# initialize?
if (defined $opt->{initialize}) {
	# connect to LDAP
	our $ldap = LDAPconnect('login');
	
	# initialize LDAP
	my $result = initializeLDAP($ldap);
	
	# disconnect from LDAP
	$ldap->unbind();
	
	# exit
	print $state[$result->{code}]." - ".$result->{message}."\n";
	exit $result->{code};
}

# do the job!
foreach(sort keys %{$testcases}) {
	# exclude 0000_template.pl
	if ($_ !~ /^0000/) {
		# info output
		print "--> doing testcase '$_'\n";
	
		# include testcase
		require 'cases/'.$_;
	
		# exec testcase
		my $testresult = test();
	
		# info output
		print "description: ".$testresult->{description}."\n";
		print "result: ".$testresult->{message}."\n";
		print "exitcode: ".$testresult->{code}."\n";
		print "\n\n";
	
		# set global error code
		if ($result->{code} lt $testresult->{code}) {
			$result->{errcount}++;
			$result->{code} = $testresult->{code};
		}
	
		# undef test function
		undef &test;
	}
}

# exit
print $state[$result->{code}]." - ".$result->{errcount}." Error(s) found!\n";
exit $result->{code};



