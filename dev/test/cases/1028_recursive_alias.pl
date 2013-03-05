#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'Test recursive alias';
$testinfo->{description}->{long}  = 'Test recursive aliases (aliases below of an aliased structural object)';
$testinfo->{subtest}->{count}     = 9;

# the real test...
sub test {
	# get the ldap connection
	my $ldap = shift;
	
	# add base ldif and test ldif to ldap
	my $result;
	$result = testAddLdif($ldap, 'lib/test_base.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	$result = testAddLdif($ldap, 'cases/1028_recursive_alias.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	
	# export config
	testConfigExport($cfg);
	
	# read generated config file
	my $data = testConfigRead($cfg->{test}->{output}.'/main/kunden/customer-1/example-host.cfg');
	
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

		if ($data->{'SERVICES'}->{'service-1'}->{'contacts'} ne 'customer-1_service_contact,template-1_service_contact') {
			$testresult->{message} = "service-1's contact != 'customer-1_service_contact,template-1_service_contact'; value is set to '$data->{'SERVICES'}->{'service-1'}->{'contacts'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }

		if (!defined( $data->{'SERVICES'}->{'service-2'})) {
			$testresult->{message} = "service-2 does not exist";
			$testresult->{code} = 2;
		} else { $success_count++; }

		if ($data->{'SERVICES'}->{'service-2'}->{'contacts'} ne 'customer-1_service_contact,template-2_service_contact') {
			$testresult->{message} = "service-2's contact != 'customer-1_service_contact,template-2_service_contact'; value is set to '$data->{'SERVICES'}->{'service-2'}->{'contacts'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }

		if (!defined( $data->{'SERVICES'}->{'service-3'})) {
			$testresult->{message} = "service-3 does not exist";
			$testresult->{code} = 2;
		} else { $success_count++; }

		if ($data->{'SERVICES'}->{'service-3'}->{'contacts'} ne 'customer-1_service_contact,template-1_service_contact,template-3_service_contact') {
			$testresult->{message} = "service-3's contact != 'customer-1_service_contact,template-1_service_contact,template-3_service_contact'; value is set to '$data->{'SERVICES'}->{'service-3'}->{'contacts'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }

		if (!defined( $data->{'SERVICES'}->{'service-4'})) {
			$testresult->{message} = "service-4 does not exist";
			$testresult->{code} = 2;
		} else { $success_count++; }

		if ($data->{'SERVICES'}->{'service-4'}->{'contacts'} ne 'service-4_contact') {
			$testresult->{message} = "service-4's contact != 'service-4_contact'; value is set to '$data->{'SERVICES'}->{'service-4'}->{'contacts'}'";
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
