#!/usr/bin/perl -w

#
# copyright and license header in LConfExport.pl?
#

# includes
use strict;

# define vars
my $testresult;

# default infos / settings
$testresult->{description} = 'copyright and license info in LConfExport.pl?';
$testresult->{message} = 'no output returned from testcase';
$testresult->{code}    = 3;

# the real test...
sub test {
	# get all scripts
	my $filename = '../../src/LConfExport.pl.in';
	
	# set requirement vars;
	my $req;
	$req->{copyright}->{state}   = 'false'; $req->{copyright}->{value} = 'copyright';
	$req->{companyname}->{state} = 'false'; $req->{companyname}->{value} = 'NETWAYS GmbH';
	$req->{license}->{state}     = 'false'; $req->{license}->{value} = 'GNU General Public License';
	
	# read file
	open(FILE, $filename) or die "Can't open file '$filename': $!\n";
	my @filecontent = <FILE>;
	close(FILE);
	
	# check filecontent
	foreach my $line (@filecontent) {
		foreach my $req_check (keys %{$req}) {
			if ($line =~ /$req->{$req_check}->{value}/i) {
				$req->{$req_check}->{state} = 'true';
			}
		}
	}
	
	# decide output and error code
	$testresult->{code} = 0;
	$testresult->{message} = '';
	
	foreach(keys %{$req}) {
		if ($req->{$_}->{state} eq 'false') {
			$testresult->{code} = '3';
			$testresult->{message} .= 'no '.$_.' found; ';
		}
	}
	
	if ($testresult->{code} == 0) {
		$testresult->{message} = 'no errors found';
	}
	
	# return testresult
	return $testresult;
}

1;