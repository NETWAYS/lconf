#!/usr/bin/perl -w

# includes
use strict;

sub testSlaveExport {
	my $cfg = shift;
	my $targetDir = $cfg->{test}->{output};

	# path to Makefile
	my $filename = '../../Makefile';
	my $PREFIX;

	# read file and get install path ($PREFIX)
	open(IN,"<$filename") || die "Can't open file '$filename': $!\n -> Just do a ./configure; make; make install\n\n";
	while(<IN>) { if ($_ =~ /^PREFIX\=/) { $_ =~ m/^PREFIX\=(.*)/; $PREFIX = $1; } }
	close(IN);
	
	# target dir exists?
	mkdir($targetDir,0755) if !-d $targetDir;
	mkdir("$targetDir/slave-export",0755);

	# export
	beVerbose("INFO", "Export config to directory '$targetDir'");
	my $result = qx($PREFIX/bin/LConfSlaveExport.pl -n -D $cfg->{test}->{output}/LConfExport.hashdump  -H localhost -o $cfg->{test}->{output}/slave-export);
	
	# errors?
	if ($result !~ /^OK/) {
		print "LConfExport.pl: ".$result;
		exit 2;
	}

	# return result
	return $result;
}

1;
