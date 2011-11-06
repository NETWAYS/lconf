#!/usr/bin/perl -w

# includes
use strict;

sub icingaConfigExport {
	my $targetDir = shift;

	# path to Makefile
	my $filename = '../../Makefile';
	my $PREFIX;

	# read file and get install path ($PREFIX)
	open(IN,"<$filename") || die "Can't open file '$filename': $!";
	while(<IN>) { if ($_ =~ /^PREFIX\=/) { $_ =~ m/^PREFIX\=(.*)/; $PREFIX = $1; } }
	close(IN);

	# export
	beVerbose("INFO", "Export config to directory '$targetDir'");
	my $result = qx($PREFIX/LConfExport.pl -o $targetDir);
	
	# errors?
	if ($result !~ /^OK/) {
		print "LConfExport.pl: ".$result;
		exit 2;
	}

	# return result
	return $result;
}

1;
