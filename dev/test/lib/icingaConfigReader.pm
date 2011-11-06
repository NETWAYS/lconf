#!/usr/bin/perl -w

# includes
use strict;

sub icingaConfigRead {
	my $filename = shift;
	
	our @OBJECTSCACHE;
	my (@TMP, $firstline);
	my (@ID_TIMEPERIODS, @ID_CONTACTS, @ID_CONTACTGROUPS, @ID_HOSTS, @ID_HOSTGROUPS, @ID_COMMANDS, @ID_SERVICES);
	my ($TIMEPERIODS, $CONTACTS, $CONTACTGROUPS, $HOSTS, $HOSTGROUPS, $COMMANDS, $SERVICES);
	
	# read config file
	beVerbose("INFO", "Read config file '$filename'");
	open(IN,"<$filename") || die "Can't open file '$filename': $!";
	($firstline,@TMP)=<IN>;
	close(IN);
	
	# build ONE file...
	push(@OBJECTSCACHE, $firstline);
	foreach(@TMP) { push(@OBJECTSCACHE, $_); }
	
	# get ID's
	my $counter = 1;
	foreach(@OBJECTSCACHE) {
		push(@ID_TIMEPERIODS, $counter)         if $_ =~ /define timeperiod\s+/;
		push(@ID_CONTACTS, $counter)            if $_ =~ /define contact\s+/;
		push(@ID_CONTACTGROUPS, $counter)       if $_ =~ /define contactgroup\s+/;
		push(@ID_HOSTS, $counter)               if $_ =~ /define host\s+/;
		push(@ID_HOSTGROUPS, $counter)          if $_ =~ /define hostgroup\s+/;
		push(@ID_COMMANDS, $counter)            if $_ =~ /define command\s+/;
 		push(@ID_SERVICES, $counter)            if $_ =~ /define service\s+/;
		$counter++;
	}
	
	# get Items
	$TIMEPERIODS    = getItems(@ID_TIMEPERIODS);            beVerbose("READ CONFIG FILE", "TIMEPERIODS imported");
	$CONTACTS       = getItems(@ID_CONTACTS);               beVerbose("READ CONFIG FILE", "CONTACTS imported");
	$CONTACTGROUPS  = getItems(@ID_CONTACTGROUPS);          beVerbose("READ CONFIG FILE", "CONTACTGROUPS imported");
	$HOSTS          = getItems(@ID_HOSTS);                  beVerbose("READ CONFIG FILE", "HOSTS imported");
	$HOSTGROUPS     = getItems(@ID_HOSTGROUPS);             beVerbose("READ CONFIG FILE", "HOSTGROUPS imported");
	$COMMANDS       = getItems(@ID_COMMANDS);               beVerbose("READ CONFIG FILE", "COMMANDS imported");
	$SERVICES       = getServiceItems(@ID_SERVICES);        beVerbose("READ CONFIG FILE", "SERVICES imported");

	# consoldidate
	my $return;
	$return->{TIMEPERIODS} = $TIMEPERIODS if defined $TIMEPERIODS;
	$return->{CONTACTS} = $CONTACTS if defined $CONTACTS;
	$return->{CONTACTGROUPS} = $CONTACTGROUPS if defined $CONTACTGROUPS;
	$return->{HOSTS} = $HOSTS if defined $HOSTS;
	$return->{HOSTGROUPS} = $HOSTGROUPS if defined $HOSTGROUPS;
	$return->{COMMANDS} = $COMMANDS if defined $COMMANDS;
	$return->{SERVICES} = $SERVICES if defined $SERVICES;
	
	# return
	return $return;

sub getItems {
	my @ID_ARRAY   = @_;
	my $hash;
	
	foreach(@ID_ARRAY) {
		# determine name for hashref
		$OBJECTSCACHE[$_+1] =~ m/[\w]+\s(.*)/;
		my $name = $1;

		# get all elements for this item
		my $counter   = $_;
		my $run_again = 'true';

		# decide mode: default or timeperiod?
		my $mode = 'default';
		$mode = 'timeperiod' if $OBJECTSCACHE[$counter] =~ /define timeperiod/;

		while($run_again eq 'true') {
			if ($OBJECTSCACHE[$counter] !~ /define/) {
				my ($val1, $val2);

				if ($mode eq 'timeperiod') {
					if ($OBJECTSCACHE[$counter] =~ /timeperiod_name/ || $OBJECTSCACHE[$counter] =~ /alias/) {
						$OBJECTSCACHE[$counter] =~ m/([\w]+)\s*(.*)/;
						$val1 = $1; $val2 = $2;
					} else {
						$OBJECTSCACHE[$counter] =~ m/(.*)\s+([\d\W]+)/;
						$val1 = $1; $val2 = $2;
					}
				} else {
					$OBJECTSCACHE[$counter] =~ m/([\w]+)\s*(.*)/;
					$val1 = $1; $val2 = $2;
				}
				$hash->{$name}->{$val1} = $val2;
			}
			$counter++;
			$run_again = 'exit' if $OBJECTSCACHE[$counter] =~ /}$/;
		}
		
	}
	
	return $hash;
}

sub getServiceItems {
	my @ID_ARRAY   = @_;
	my $hash;

	foreach(@ID_ARRAY) {
		# determine name for hashref
		$OBJECTSCACHE[$_+1] =~ m/[\w]+\s(.*)/;
		my $name1 = $1;

		$OBJECTSCACHE[$_+2] =~ m/[\w]+\s(.*)/;
		my $name2 = $1;

		# get all elements for this item
		my $counter   = $_;
		my $run_again = 'true';

		while($run_again eq 'true') {
			if ($OBJECTSCACHE[$counter] !~ /define/) {
				$OBJECTSCACHE[$counter] =~ m/([\w]+)\s*(.*)/;
				$hash->{$name1}->{$name2}->{$1} = $2 if $1 ne "host_name";
			}

			$counter++;
			$run_again = 'exit' if $OBJECTSCACHE[$counter] =~ /}$/;
		}
	}
	return $hash;
}

}

1;