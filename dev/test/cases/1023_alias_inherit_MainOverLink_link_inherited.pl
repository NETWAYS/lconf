#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'test alias with treerewrite-mode MainOverLink; link inherited';
$testinfo->{description}->{long}  = 'long description';
$testinfo->{subtest}->{count}     = 7;

# the real test...
sub test {
	# get the ldap connection
	my $ldap = shift;
	
	# add base ldif and test ldif to ldap
	my $result;
	$result = testAddLdif($ldap, 'lib/test_base.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	$result = testAddLdif($ldap, 'cases/1023_alias_inherit_MainOverLink_link_inherited.ldif');
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
		# --> service below host object (part 1)
		if (!defined $data->{'SERVICES'}->{'example-service'}) {
			$testresult->{message} = "service 'example-service' not found";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# the service above (part1) was written with contacts 'icingaadmin'?
		if (!defined $data->{'SERVICES'}->{'example-service'}->{'contacts'} && $data->{'SERVICES'}->{'example-service'}->{'contacts'} ne 'icingaadmin') {
			$testresult->{message} = "attribute contacts of service 'example-service' != 'icingaadmin'; value is set to '$data->{'SERVICES'}->{'example-service'}->{'contacts'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# service object was written and it's name is 'example-service-2'?
		# --> service inherited from parent element (part 2)
		if (!defined $data->{'SERVICES'}->{'example-service-2'}) {
			$testresult->{message} = "service 'example-service-2' not found";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# the service above (part2) was written with contacts 'icingaadmin'?
		if (!defined $data->{'SERVICES'}->{'example-service-2'}->{'contacts'} && $data->{'SERVICES'}->{'example-service-2'}->{'contacts'} ne 'icingaadmin') {
			$testresult->{message} = "attribute contacts of service 'example-service-2' != 'icingaadmin'; value is set to '$data->{'SERVICES'}->{'example-service-2'}->{'contacts'}'";
			$testresult->{code} = 2;
		} else { $success_count++; }

		# service object was written and it's name is 'example-service-3'?
		# --> service inherited from alias; alias below hostobject (part 3)
		if (!defined $data->{'SERVICES'}->{'example-service-3'}) {
			$testresult->{message} = "service 'example-service-3' not found";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# the service above (part3) was written with contacts 'icingaadmin'?
		if (!defined $data->{'SERVICES'}->{'example-service-3'}->{'contacts'} && $data->{'SERVICES'}->{'example-service-3'}->{'contacts'} ne 'icingaadmin') {
			$testresult->{message} = "attribute contacts of service 'example-service-3' != 'icingaadmin'; value is set to '$data->{'SERVICES'}->{'example-service-3'}->{'contacts'}'";
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