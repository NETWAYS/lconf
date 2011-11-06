#!/usr/bin/perl -w

#
# a service from template tree (link) will be overwritten by a service from main tree
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
$testresult->{description} = 'main-tree service overwrites linked service?';
$testresult->{message} = 'no output returned from testcase';
$testresult->{code}    = 3;

# the real test...
sub test {
	my $check_count = 2; my $counter = 0;
	
	# initialize ldap with test ldif
	my $result = initializeLDAP('1007_services_from_main_vs_services_from_template.ldif');
	if ($result->{code} != 0) { $testresult->{message} = $result->{message}; $testresult->{code} = $result->{code}; }
	
	# export config
	mkdir('/tmp/out',0755) if !-d '/tmp/out';
	icingaConfigExport('/tmp/out');
	
	# read generated config file
	my $data = icingaConfigRead('/tmp/out/layer1/layer2/layer3/testhost.cfg');
	
	# service 'testservice-linked' was written?
	if (!defined($data->{SERVICES}->{'testservice-linked'}->{testhost})) {
		$testresult->{message} = "service 'testservice-linked' not found";
		$testresult->{code} = 2;
	} else { $counter++; }

	# contact of 'testservice-linked' = 'test-contact-from-maintree' ?
	if (defined($data->{SERVICES}->{'testservice-linked'}->{testhost}->{contacts}) && $data->{SERVICES}->{'testservice-linked'}->{testhost}->{contacts} ne 'test-contact-from-maintree') {
		$testresult->{message} = "contacts of service != 'test-contact-from-maintree'; service = $data->{SERVICES}->{'testservice-linked'}->{testhost}->{contacts}";
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
