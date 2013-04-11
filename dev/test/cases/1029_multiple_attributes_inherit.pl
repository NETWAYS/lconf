#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'Test to inherit multiple attributes';
$testinfo->{description}->{long}  = 'Test to inerhit multiple attributes like description or customvars';
$testinfo->{subtest}->{count}     = 3;

# the real test...
sub test {
	# get the ldap connection
	my $ldap = shift;
	
	# add base ldif and test ldif to ldap
	my $result;
	$result = testAddLdif($ldap, 'lib/test_base.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	$result = testAddLdif($ldap, 'cases/1029_multiple_attributes_inherit.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	
	# export config
	testConfigExport($cfg);
	testSlaveExport($cfg);
	
	# read generated config file
	my $data = testConfigRead($cfg->{test}->{output}.'/slave-export/main/kunden/customer-1/example-host.cfg');
	
	#
	# THE REAL TEST CASES - BEGIN
	#
	my $success_count = 0;
	
		if (!$data->{'HOSTS'}->{'example-host'}->{'host_name'} || $data->{'HOSTS'}->{'example-host'}->{'host_name'} ne 'example-host') {
			$testresult->{message} = "host 'example-host' not found or it's name is not 'example-host";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		if (!defined( $data->{'SERVICES'}->{'service-1'})) {
			$testresult->{message} = "service-1 does not exist";
			$testresult->{code} = 2;
		} else { $success_count++; }


        if ($data->{'SERVICES'}->{'service-1'}->{'active_checks_enabled'} ne '1') {
            $testresult->{message} = "service-1's active_checks_enabled != '1'. Value is set to '$data->{'SERVICES'}->{'service-1'}->{'active_checks_enabled'}'";
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
    #testCleanLDAP($ldap);
	
	# return testresult
	return $testresult;
}

1;
