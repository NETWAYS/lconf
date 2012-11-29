#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'test host with structural object and services ';
$testinfo->{description}->{long}  = 'service is below a sructuralObjects this is below a host';
$testinfo->{subtest}->{count}     = 4;

# the real test...
sub test {
	# get the ldap connection
	my $ldap = shift;
	
	# add base ldif and test ldif to ldap
	my $result;
	$result = testAddLdif($ldap, 'lib/test_base.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	$result = testAddLdif($ldap, 'cases/1024_service_below_structuralObject_below_host.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	
	# export config
	testConfigExport($cfg);
	
	# read generated config file
	my $data = testConfigRead($cfg->{test}->{output}.'/main/kunden/customer-1/loadbalancer/example-host.cfg');
	
	#
	# THE REAL TEST CASES - BEGIN
	#
	my $success_count = 0;
	
		# host object was written and hostname == 'example-host'
		if (!$data->{'HOSTS'}->{'example-host'}->{'host_name'} || $data->{'HOSTS'}->{'example-host'}->{'host_name'} ne 'example-host') {
			$testresult->{message} = "host 'example-host' not found or it's name is not 'example-host";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# service object was written and it's name is 'example-service'?
		if (!defined $data->{'SERVICES'}->{'example-service'}) {
			$testresult->{message} = "service 'example-service' not found";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
    ## the service above was written with contacts 'icingaadmin'?
		if (!defined $data->{'SERVICES'}->{'example-service'}->{'contacts'} && $data->{'SERVICES'}->{'example-service'}->{'contacts'} ne 'icingaadmin') {
			$testresult->{message} = "attribute contacts of service 'example-service' != 'icingaadmin'; value is set to '$data->{'SERVICES'}->{'example-service'}->{'contacts'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }
	
		# service object was written and _CV1 is 'value1'?
		if ($data->{'SERVICES'}->{'example-service'}->{'_CV1'} ne 'value1') {
			$testresult->{message} = "service's _CV1 != 'value1'; value is set to '$data->{'SERVICES'}->{'example-service'}->{'_CV1'}'";
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
