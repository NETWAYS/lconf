#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'test a simple contactgroup';
$testinfo->{description}->{long}  = 'long description';
$testinfo->{subtest}->{count}     = 2;

# the real test...
sub test {
	# get the ldap connection
	my $ldap = shift;
	
	# add base ldif and test ldif to ldap
	my $result = testAddLdif($ldap, 'lib/test_base.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
		
	# export config
	testConfigExport($cfg);
	
	# read generated config file
	my $data = testConfigRead($cfg->{test}->{output}.'/global/contactgroups/admins.cfg');
	
	#
	# THE REAL TEST CASES - BEGIN
	#
	my $success_count = 0;
	
		# definition is written and it's name is 'admins'?
		if (!$data->{'CONTACTGROUPS'}->{'admins'}->{'contactgroup_name'} || $data->{'CONTACTGROUPS'}->{'admins'}->{'contactgroup_name'} ne 'admins') {
			$testresult->{message} = "contactgroup 'admins' not found or it's name is not 'admins";
			$testresult->{code} = 2;
		} else { $success_count++; }

		# contact has mailaddress icinga@localhost?
		if ($data->{'CONTACTGROUPS'}->{'admins'}->{'members'} !~ /icingaadmin/) {
			$testresult->{message} = "contactgroup's members != 'icingaadmin'; value is set to '$data->{'CONTACTGROUPS'}->{'admins'}->{'members'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }
	
	#
	# THE REAL TEST CASES - END
	#
	
	# set message and code to OK ?
	if ($success_count == $testinfo->{subtest}->{count}) {
		$testresult->{message} = "no errors";
		$testresult->{code} = 0;
	}
	
	# clean the ldap tree
	testCleanLDAP($ldap);
	
	# return testresult
	return $testresult;
}

1;