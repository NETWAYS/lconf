#!/usr/bin/perl -w

# includes
use strict;

sub testConfigRead {
	my $filename = shift;
	my $return;
	my @FILEDATA;
	
	# read file
	beVerbose("INFO", "Read file '$filename'");
	open(IN,"<$filename") || die "Can't open file '$filename': $!";
	while(<IN>) { push(@FILEDATA, $_) if $_ !~ /^\n/; }
	close(IN);
	
	my $linecount = @FILEDATA;
	my $counter = 0;
	while($counter <= $linecount) {
		if (defined $FILEDATA[$counter]) {
			
			if ($FILEDATA[$counter] =~ /define host {/) {
				my $attcount = $counter+1;
				my $tmp_hash; my $item; my $value;
				
				NEXTLINE_HOSTS:
				if ($FILEDATA[$attcount] !~ /^}/) {
					$FILEDATA[$attcount] =~ m/([\w]+)\s*(.*)/;
					$item = $1; $value = $2;
					$tmp_hash->{$item} = $value;
				}
				
				if ($FILEDATA[$attcount] !~ /^}/) { $attcount++; goto NEXTLINE_HOSTS;
				} else { $counter = $attcount; $return->{'HOSTS'}->{$tmp_hash->{'host_name'}} = $tmp_hash; }
			}
			
			if ($FILEDATA[$counter] =~ /define service {/) {
				my $attcount = $counter+1;
				my $tmp_hash; my $item; my $value;
				
				NEXTLINE_SERVICES:
				if ($FILEDATA[$attcount] !~ /^}/) {
					$FILEDATA[$attcount] =~ m/([\w]+)\s*(.*)/;
					$item = $1; $value = $2;
					$tmp_hash->{$item} = $value;
				}
				
				if ($FILEDATA[$attcount] !~ /^}/) { $attcount++; goto NEXTLINE_SERVICES;
				} else { $counter = $attcount; $return->{'SERVICES'}->{$tmp_hash->{'service_description'}} = $tmp_hash; }
			}
			
			if ($FILEDATA[$counter] =~ /define command {/) {
				my $attcount = $counter+1;
				my $tmp_hash; my $item; my $value;
				
				NEXTLINE_COMMANDS:
				if ($FILEDATA[$attcount] !~ /^}/) {
					$FILEDATA[$attcount] =~ m/([\w]+)\s*(.*)/;
					$item = $1; $value = $2;
					$tmp_hash->{$item} = $value;
				}
							
				if ($FILEDATA[$attcount] !~ /^}/) { $attcount++; goto NEXTLINE_COMMANDS;
				} else { $counter = $attcount; $return->{'COMMANDS'}->{$tmp_hash->{'command_name'}} = $tmp_hash; }
			}
			
			if ($FILEDATA[$counter] =~ /define contact {/) {
				my $attcount = $counter+1;
				my $tmp_hash; my $item; my $value;
							
				NEXTLINE_CONTACTS:
				if ($FILEDATA[$attcount] !~ /^}/) {
					$FILEDATA[$attcount] =~ m/([\w]+)\s*(.*)/;
					$item = $1; $value = $2;
					$tmp_hash->{$item} = $value;
				}
									
				if ($FILEDATA[$attcount] !~ /^}/) { $attcount++; goto NEXTLINE_CONTACTS;
				} else { $counter = $attcount; $return->{'CONTACTS'}->{$tmp_hash->{'contact_name'}} = $tmp_hash; }
			}
			
			if ($FILEDATA[$counter] =~ /define contactgroup {/) {
				my $attcount = $counter+1;
				my $tmp_hash; my $item; my $value;
									
				NEXTLINE_CONTACTGROUPS:
				if ($FILEDATA[$attcount] !~ /^}/) {
					$FILEDATA[$attcount] =~ m/([\w]+)\s*(.*)/;
					$item = $1; $value = $2;
					$tmp_hash->{$item} = $value;
				}
									
				if ($FILEDATA[$attcount] !~ /^}/) { $attcount++; goto NEXTLINE_CONTACTGROUPS;
				} else { $counter = $attcount; $return->{'CONTACTGROUPS'}->{$tmp_hash->{'contactgroup_name'}} = $tmp_hash; }
			}
			
			if ($FILEDATA[$counter] =~ /define timeperiod {/) {
				my $attcount = $counter+1;
				my $tmp_hash; my $item; my $value;
									
				NEXTLINE_TIMEPERIODS:
				if ($FILEDATA[$attcount] !~ /^}/) {
					$FILEDATA[$attcount] =~ m/([\w]+)\s*(.*)/;
					$item = $1; $value = $2;
					$tmp_hash->{$item} = $value;
				}
												
				if ($FILEDATA[$attcount] !~ /^}/) { $attcount++; goto NEXTLINE_TIMEPERIODS;
				} else { $counter = $attcount; $return->{'TIMEPERIODS'}->{$tmp_hash->{'timeperiod_name'}} = $tmp_hash; }
			}
		}
		
		$counter++;
	}
	
	return $return;
}

1;