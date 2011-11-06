#!/usr/bin/perl -w

#
# check, if '/usr/local/LConf' is set as default prefix in configure.ac
#

# includes
use strict;

# define vars
my $testresult;

# default infos / settings
$testresult->{description} = 'default prefix is /usr/local/LConf ?';
$testresult->{message} = 'no output returned from testcase';
$testresult->{code}    = 3;

# the real test...
sub test {
	# path to configure.ac
	my $filename = '../../configure.ac';
	my @filecontent;
	
	# read file
	open(FILE, $filename) or die "Can't open file '$filename': $!\n";
	@filecontent = <FILE>;
	close(FILE);
	
	# parse content after 'AC_PREFIX_DEFAULT...'
	foreach(@filecontent) {
		if ($_ =~ /^AC_PREFIX_DEFAULT/) {
			# get default prefix
			$_ =~ m/AC_PREFIX_DEFAULT\((.*)\).*/;
			my $prefix = $1;
			
			# set exitcode and message
			if ($prefix eq '/usr/local/LConf') {
				$testresult->{message} = "prefix == /usr/local/LConf";
				$testresult->{code}    = 0;
			} else {
				$testresult->{message} = "prefix == $prefix";
				$testresult->{code}    = 2;
			}
		}
	}
	
	# return testresult
	return $testresult;
}

1;