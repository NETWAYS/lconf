#!/usr/bin/perl -w

#
# test additive inheritance
#
# tredel, 2011
#

# includes
use strict;
use lib::icingaConfigReader;
use lib::icingaConfigExporter;

# define vars
my $testresult;

# default infos / settings
$testresult->{description} = 'additive inheritance will sum up contacts?';
$testresult->{message} = 'no output returned from testcase';
$testresult->{code}    = 3;

# the real test...
sub test {
	my $check_count = 4; my $counter = 0;
	
	# initialize ldap with test ldif
	my $result = initializeLDAP('1008_additive_inheritance.ldif');
	if ($result->{code} != 0) { $testresult->{message} = $result->{message}; $testresult->{code} = $result->{code}; }
	
	# export config
	mkdir('/tmp/out',0755) if !-d '/tmp/out';
	icingaConfigExport('/tmp/out');
	
	# read generated config file
	my $data = icingaConfigRead('/tmp/out/layer1/layer2/layer3/testhost.cfg');
	
	# 'contacts' is defined for host 'testhost'?
	if (!defined($data->{HOSTS}->{testhost}->{contacts})) {
		$testresult->{message} = "host 'testhost' has no contacts";
		$testresult->{code} = 2;
	} else { $counter++; }
	
	# contacts != 'test-contact-host,test-contact-host2'?
	if (defined($data->{HOSTS}->{testhost}->{contacts}) && $data->{HOSTS}->{testhost}->{contacts} ne 'test-contact-host,test-contact-host2') {
		$testresult->{message} = "contacts on host 'testhost' != 'test-contact-host,test-contact-host2'; contacts = $data->{HOSTS}->{testhost}->{contacts}";
		$testresult->{code} = 2;
	} else { $counter++; }
	
	# 'contacts' is defined for service 'testservice'?
	if (!defined($data->{SERVICES}->{testservice}->{testhost}->{contacts})) {
		$testresult->{message} = "service 'testservice' has no contacts";
		$testresult->{code} = 2;
	} else { $counter++; }
	
	# contacts != 'test-contact-service,test-contact-service2'?
	if (defined($data->{SERVICES}->{testservice}->{testhost}->{contacts}) && $data->{SERVICES}->{testservice}->{testhost}->{contacts} ne 'test-contact-service,test-contact-service2') {
		$testresult->{message} = "contacs on service 'test-contact-service,test-contact-service2' != 'test-contact-service'; contacts = $data->{SERVICES}->{testservice}->{testhost}->{contacts}";
		$testresult->{code} = 2;
	} else { $counter++; }
	
	# set message and code to OK ?
	if ($counter == $check_count) {
		$testresult->{message} = "no errors";
		$testresult->{code} = 0;
	}

	# return testresult
	return $testresult;
}

1;
