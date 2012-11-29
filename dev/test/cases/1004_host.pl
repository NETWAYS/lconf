#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'test a simple host';
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
	$result = testAddLdif($ldap, 'cases/1004_host.ldif');
	if ($result->{code} != 0) { $testresult->{code} = $result->{code}; $testresult->{message} = $result->{message}; return $testresult; }
	
	# export config
	testConfigExport($cfg);
	
	# read generated config file
	my $data = testConfigRead($cfg->{test}->{output}.'/main/example-host.cfg');
	
	#
	# THE REAL TEST CASES - BEGIN
	#
	my $success_count = 0;
	
		# definition is writte and it's name is 'example-host'?
		if (!$data->{'HOSTS'}->{'example-host'}->{'host_name'} || $data->{'HOSTS'}->{'example-host'}->{'host_name'} ne 'example-host') {
			$testresult->{message} = "host 'example-host' not found or it's name is not 'example-host";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# hosts address is '127.0.0.1'?
		if ($data->{'HOSTS'}->{'example-host'}->{'address'} ne '127.0.0.1') {
			$testresult->{message} = "host's address != '127.0.0.1'; value is set to '$data->{'HOSTS'}->{'example-host'}->{'address'}'";
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