#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'test a simple timeperiod';
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
	my $data = testConfigRead($cfg->{test}->{output}.'/global/timeperiods/24x7.cfg');
	
	#
	# THE REAL TEST CASES - BEGIN
	#
	my $success_count = 0;
	
		# definition is written and it's alias is '24 Hours A Day, 7 Days A Week'?
		if (!$data->{'TIMEPERIODS'}->{'24x7'}->{'alias'} || $data->{'TIMEPERIODS'}->{'24x7'}->{'alias'} ne '24 Hours A Day, 7 Days A Week') {
			$testresult->{message} = "timeperiod '24x7' not found or it's alias is not '24 Hours A Day, 7 Days A Week";
			$testresult->{code} = 2;
		} else { $success_count++; }

		# timeperiods sunday has value '00:00-24:00'?
		if ($data->{'TIMEPERIODS'}->{'24x7'}->{'sunday'} !~ /00:00-24:00/) {
			$testresult->{message} = "timperiod's sunday value != '00:00-24:00'; value is set to '$data->{'TIMEPERIODS'}->{'24x7'}->{'sunday'}'";
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