#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'test alias with inherited services and sub-inherited attributes';
$testinfo->{description}->{long}  = 'long description';
$testinfo->{subtest}->{count}     = 8;

# the real test...
sub test {
	# get the ldap connection
	my $ldap = shift;
	
	# add base ldif and test ldif to ldap
	my $result;
	$result = testAddLdif($ldap, 'lib/test_base.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	$result = testAddLdif($ldap, 'cases/1021_alias_inherit_service_with_sub-inherited_attributes.ldif');
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
		
		# service object was written and it's name is 'example-service'?
		# --> service below host object
		if (!defined $data->{'SERVICES'}->{'example-service'}) {
			$testresult->{message} = "service 'example-service' not found";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# service object was written and it's name is 'example-service-2'?
		# --> service inherited from parent element
		if (!defined $data->{'SERVICES'}->{'example-service-2'}) {
			$testresult->{message} = "service 'example-service-2' not found";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# service object was written and it's name is 'example-service-3'?
		# --> service inherited from alias; alias below hostobject
		if (!defined $data->{'SERVICES'}->{'example-service-3'}) {
			$testresult->{message} = "service 'example-service-3' not found";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# service object was written and _CV1 is 'value1'?
		if ($data->{'SERVICES'}->{'example-service-3'}->{'_CV1'} ne 'value1') {
			$testresult->{message} = "service's _CV1 != 'value1'; value is set to '$data->{'SERVICES'}->{'example-service-3'}->{'_CV1'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# service object was written and _CV2 is 'value2'?
		if ($data->{'SERVICES'}->{'example-service-3'}->{'_CV2'} ne 'value2') {
			$testresult->{message} = "service's _CV2 != 'value2'; value is set to '$data->{'SERVICES'}->{'example-service-3'}->{'_CV2'}'";
			$testresult->{code} = 2;	
		} else { $success_count++; }
		
		# service object was written and _CV1 is 'value1'?
		if ($data->{'SERVICES'}->{'example-service-4'}->{'_CV1'} ne 'value1') {
			$testresult->{message} = "service's _CV1 != 'value1'; value is set to '$data->{'SERVICES'}->{'example-service-4'}->{'_CV1'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }
			
		# service object was written and _CV2 is 'value2'?
		if ($data->{'SERVICES'}->{'example-service-4'}->{'_CV2'} ne 'value2') {
			$testresult->{message} = "service's _CV2 != 'value2'; value is set to '$data->{'SERVICES'}->{'example-service-4'}->{'_CV2'}'";
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