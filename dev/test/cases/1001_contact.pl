#!/usr/bin/perl -w

# includes
use strict;

# define vars
our $testinfo;
my $testresult;

# default test infos
$testinfo->{description}->{short} = 'test a simple contact';
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
	my $data = testConfigRead($cfg->{test}->{output}.'/global/contacts/icingaadmin.cfg');
	
	#
	# THE REAL TEST CASES - BEGIN
	#
	my $success_count = 0;

		# definition is written and it's name is 'icingaadmin'?
		if (!$data->{CONTACTS}->{'icingaadmin'}->{contact_name} || $data->{CONTACTS}->{'icingaadmin'}->{contact_name} ne 'icingaadmin') {
			$testresult->{message} = "contact 'icingaadmin' not found or it's name is not 'icingaadmin";
			$testresult->{code} = 2;
		} else { $success_count++; }
		
		# contact has mailaddress icinga@localhost?
		if ($data->{CONTACTS}->{'icingaadmin'}->{'email'} !~ /icinga\@localhost/) {
			$testresult->{message} = "contact's mailaddress != 'icinga\@localhost'; value is set to '$data->{CONTACTS}->{'icingaadmin'}->{'email'}'";
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