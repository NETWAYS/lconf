#!/usr/bin/perl -w

#
# check, if 'blubb' is ok
#

# includes
use strict;

# define vars
my $testresult;

# default infos / settings
$testresult->{description} = 'blubb is ok?';
$testresult->{message} = 'no output returned from testcase';
$testresult->{code}    = 3;

# the real test...
sub test {
	if (my $blubb) {
		$testresult->{message} = 'lalala is blubb';
		$testresult->{code}    = 0;
	}
	
	# return testresult
	return $testresult;
}

1;