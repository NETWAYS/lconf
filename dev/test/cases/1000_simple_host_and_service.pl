#!/usr/bin/perl -w

#
# check export of a simple host and service
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
$testresult->{description} = 'export a simple host and service?';
$testresult->{message} = 'no output returned from testcase';
$testresult->{code}    = 3;

# the real test...
sub test {
	my $check_count = 4; my $counter = 0;
	
	# initialize ldap with test ldif
	my $result = initializeLDAP('1000_simple_host_and_service.ldif');
	if ($result->{code} != 0) { $testresult->{message} = $result->{message}; $testresult->{code} = $result->{code}; }
	
	# export config
	mkdir('/tmp/out',0755) if !-d '/tmp/out';
	icingaConfigExport('/tmp/out');
	
	# read generated config file
	my $data = icingaConfigRead('/tmp/out/testhost.cfg');

	# host 'testhost' was written?
	if (!defined($data->{HOSTS}->{testhost}->{host_name})) {
		$testresult->{message} = "host 'testhost' not found";
		$testresult->{code} = 2;
	} else { $counter++; }

	# host = 'testhost' ?
	if (defined($data->{HOSTS}->{testhost}->{host_name}) && $data->{HOSTS}->{testhost}->{host_name} ne 'testhost') {
		$testresult->{message} = "host != 'testhost'; host = $data->{HOSTS}->{testhost}->{host_name}";
		$testresult->{code} = 2;
	} else { $counter++; }

	# service 'testservice' was written?
	if (!defined($data->{SERVICES}->{testservice}->{testhost})) {
		$testresult->{message} = "service 'testservice' not found";
		$testresult->{code} = 2;
	} else { $counter++; }

	# service_description = 'testservice' ?
	if (defined($data->{SERVICES}->{testservice}->{testhost}->{service_description}) && $data->{SERVICES}->{testservice}->{testhost}->{service_description} ne 'testservice') {
		$testresult->{message} = "service != 'testservice'; service = $data->{SERVICES}->{testservice}->{testhost}->{service_description}";
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
