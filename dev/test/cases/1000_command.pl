#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'test a simple command';
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
	my $data = testConfigRead($cfg->{test}->{output}.'/global/commands/check-host-alive.cfg');
	
	#
	# THE REAL TEST CASES - BEGIN
	#
	my $success_count = 0;

		# definition was written and it's name is 'check-host-alive'?
		if (!$data->{COMMANDS}->{'check-host-alive'}->{'command_name'} || $data->{COMMANDS}->{'check-host-alive'}->{'command_name'} ne 'check-host-alive') {
			$testresult->{message} = "command 'check-host-alive' not found or it's name is not 'check-host-alive";
			$testresult->{code} = 2;
		} else { $success_count++; }
	
		# command has the right attribute 'command line'?
		if ($data->{COMMANDS}->{'check-host-alive'}->{'command_line'} !~ /\$USER1\$\/check_ping -H \$HOSTADDRESS\$ -w 3000.0,80% -c 5000.0,100% -p 5/) {
			$testresult->{message} = "command's attribute 'command_line' != '\$USER1\$/check_ping -H \$HOSTADDRESS\$ -w 3000.0,80% -c 5000.0,100% -p 5'";
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