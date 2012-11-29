#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'test host inheritance with multiple customvars';
$testinfo->{description}->{long}  = 'long description';
$testinfo->{subtest}->{count}     = 2;

# the real test...
sub test {
	# get the ldap connection
	my $ldap = shift;
	
	# add base ldif and test ldif to ldap
	my $result;
	$result = testAddLdif($ldap, 'lib/test_base.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	$result = testAddLdif($ldap, 'cases/1006_host_inheritance_multiple_customvars.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	
	# export config
	testConfigExport($cfg);
	
	# read generated config file
	my $data = testConfigRead($cfg->{test}->{output}.'/main/test-struct-1/example-host.cfg');
	
	#
	# THE REAL TEST CASES - BEGIN
	#
	my $success_count = 0;
	
	# host's _CV1 is 'value1'?
	if ($data->{'HOSTS'}->{'example-host'}->{'_CV1'} ne 'value1') {
		$testresult->{message} = "host's _CV1 != 'value1'; value is set to '$data->{'HOSTS'}->{'example-host'}->{'_CV1'}'";
		$testresult->{code} = 2;
	} else { $success_count++; }
	
	# host's _CV2 is 'value2'?
	if ($data->{'HOSTS'}->{'example-host'}->{'_CV2'} ne 'value2') {
		$testresult->{message} = "host's _CV2 != 'value2'; value is set to '$data->{'HOSTS'}->{'example-host'}->{'_CV2'}'";
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