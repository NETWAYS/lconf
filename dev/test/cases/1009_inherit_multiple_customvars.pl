#!/usr/bin/perl -w

#
# inherit multiple customvars to host and service objects 
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
$testresult->{description} = 'multiple customvars will be exported to a host and service?';
$testresult->{message} = 'no output returned from testcase';
$testresult->{code}    = 3;

# the real test...
sub test {
	my $check_count = 6; my $counter = 0;
	
	# initialize ldap with test ldif
	my $result = initializeLDAP('1009_inherit_multiple_customvars.ldif');
	if ($result->{code} != 0) { $testresult->{message} = $result->{message}; $testresult->{code} = $result->{code}; }
	
	# export config
	mkdir('/tmp/out',0755) if !-d '/tmp/out';
	icingaConfigExport('/tmp/out');
	
	# read generated config file
	my $data = icingaConfigRead('/tmp/out/layer1/layer2/layer3/testhost.cfg');
	
	# customvar '_LAYER1' is defined for host 'testhost'?
	if (!defined($data->{HOSTS}->{testhost}->{_LAYER1}) && $data->{HOSTS}->{testhost}->{_LAYER1} ne 'from layer 1 - host') {
		$testresult->{message} = "customvar '_LAYER1' != 'from layer 1 - host' or customvar is not available";
		$testresult->{code} = 2;
	} else { $counter++; }
	
	# customvar '_LAYER2' is defined for host 'testhost'?
	if (!defined($data->{HOSTS}->{testhost}->{_LAYER2}) && $data->{HOSTS}->{testhost}->{_LAYER2} ne 'from layer 2 - host') {
		$testresult->{message} = "customvar '_LAYER2' != 'from layer 2 - host' or customvar is not available";
		$testresult->{code} = 2;
	} else { $counter++; }
	
	# customvar '_DIRECT' is defined for host 'testhost'?
	if (!defined($data->{HOSTS}->{testhost}->{_DIRECT}) && $data->{HOSTS}->{testhost}->{_DIRECT} ne 'direct entry - host') {
		$testresult->{message} = "customvar '_DIRECT' != 'direct entry - host' or customvar is not available";
		$testresult->{code} = 2;
	} else { $counter++; }
	
	# customvar '_LAYER1' is defined for service 'testservice'?
	if (!defined($data->{SERVICES}->{testservice}->{testhost}->{_LAYER1}) && $data->{SERVICES}->{testservice}->{testhost}->{_LAYER1} ne 'from layer 1 - service') {
		$testresult->{message} = "customvar '_LAYER1' != 'from layer 1 - service' or customvar is not available";
		$testresult->{code} = 2;
	} else { $counter++; }
	
	# customvar '_LAYER2' is defined for service 'testservice'?
	if (!defined($data->{SERVICES}->{testservice}->{testhost}->{_LAYER2}) && $data->{SERVICES}->{testservice}->{testhost}->{_LAYER2} ne 'from layer 2 - service') {
		$testresult->{message} = "customvar '_LAYER2' != 'from layer 2 - service' or customvar is not available";
		$testresult->{code} = 2;
	} else { $counter++; }
	
	# customvar '_DIRECT' is defined for service 'testservice'?
	if (!defined($data->{SERVICES}->{testservice}->{testhost}->{_DIRECT}) && $data->{SERVICES}->{testservice}->{testhost}->{_DIRECT} ne 'direct entry - service') {
		$testresult->{message} = "customvar '_DIRECT' != 'direct entry - service' or customvar is not available";
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
