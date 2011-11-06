#!/usr/bin/perl -w

#
# test link(s) during tree process
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
$testresult->{description} = 'link(s) during tree process will be used?';
$testresult->{message} = 'no output returned from testcase';
$testresult->{code}    = 3;

# the real test...
sub test {
	my $check_count = 3; my $counter = 0;
	
	# initialize ldap with test ldif
	my $result = initializeLDAP('1003_link_during_tree_process.ldif');
	if ($result->{code} != 0) { $testresult->{message} = $result->{message}; $testresult->{code} = $result->{code}; }
	
	# export config
	mkdir('/tmp/out',0755) if !-d '/tmp/out';
	icingaConfigExport('/tmp/out');
	
	# read generated config file
	my $data = icingaConfigRead('/tmp/out/layer1/layer2/layer3/testhost.cfg');

	# service 'testservice' (from main-tree) is defined for host 'testhost'?
	if (!defined($data->{SERVICES}->{'testservice'}->{testhost})) {
		$testresult->{message} = "service 'testservice' not found";
		$testresult->{code} = 2;
	} else { $counter++; }

	# service 'testservice-linked' (from link 1) is defined for host 'testhost'?
	if (!defined($data->{SERVICES}->{'testservice-linked'}->{testhost})) {
		$testresult->{message} = "service 'testservice-linked' not found";
		$testresult->{code} = 2;
	} else { $counter++; }
	
	# service 'testservice-linked2' (from link 2) is defined for host 'testhost'?
	if (!defined($data->{SERVICES}->{'testservice-linked2'}->{testhost})) {
		$testresult->{message} = "service 'testservice-linked2' not found";
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
