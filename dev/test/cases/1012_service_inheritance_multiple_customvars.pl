#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'test a service and inheritance of multiple customvars';
$testinfo->{description}->{long}  = 'long description';
$testinfo->{subtest}->{count}     = 6;

# the real test...
sub test {
	# get the ldap connection
	my $ldap = shift;
	
	# add base ldif and test ldif to ldap
	my $result;
	$result = testAddLdif($ldap, 'lib/test_base.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	$result = testAddLdif($ldap, 'cases/1012_service_inheritance_multiple_customvars.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	
	# export config
	testConfigExport($cfg);
	
	# read generated config file
	my $data = testConfigRead($cfg->{test}->{output}.'/main/test-struct-1/test-struct-2/example-host.cfg');
	
	#
	# THE REAL TEST CASES - BEGIN
	#
	my $success_count = 0;
	
		# host object was written and hostname == 'example-host'
		if (!$data->{'HOSTS'}->{'example-host'}->{'host_name'} || $data->{'HOSTS'}->{'example-host'}->{'host_name'} ne 'example-host') {
			$testresult->{message} = "host 'example-host' not found or it's name is not 'example-host";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# host's ip is '127.0.0.1'?
		if ($data->{'HOSTS'}->{'example-host'}->{'address'} ne '127.0.0.1') {
			$testresult->{message} = "host's ip != '127.0.0.1'; value is set to '$data->{'HOSTS'}->{'example-host'}->{'address'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# service object was written and it's name is 'example-service'?
		if (!$data->{'SERVICES'}->{'example-service'}->{'service_description'} || $data->{'SERVICES'}->{'example-service'}->{'service_description'} ne 'example-service') {
			$testresult->{message} = "service 'example-service' not found or it's name is not 'example-service";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# service object was written and it's contact is 'icingaadmin'?
		if ($data->{'SERVICES'}->{'example-service'}->{'contacts'} ne 'icingaadmin') {
			$testresult->{message} = "service's contact != 'icingaadmin'; value is set to '$data->{'SERVICES'}->{'example-service'}->{'contacts'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# service object was written and _CV1 is 'value1'?
		if ($data->{'SERVICES'}->{'example-service'}->{'_CV1'} ne 'value1') {
			$testresult->{message} = "service's _CV1 != 'value1'; value is set to '$data->{'SERVICES'}->{'example-service'}->{'_CV1'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# service object was written and _CV2 is 'value2'?
		if ($data->{'SERVICES'}->{'example-service'}->{'_CV2'} ne 'value2') {
			$testresult->{message} = "service's _CV2 != 'value2'; value is set to '$data->{'SERVICES'}->{'example-service'}->{'_CV2'}'";
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