#!/usr/bin/perl -w

sub testInitializeLDAP {
	my $ldap = shift;
	
	# should we really initialize?
	print "Do you really want to initialize the ldap server?\n";
	print "All data will be erased during initialisation!\n";
	print "\n";
	print "If you know what you're doing, type 'YES': ";
	my $confirm = <STDIN>;
	chomp($confirm);

	if ($confirm eq 'YES' || $confirm eq 'yes') {
		# need to clear ldap tree?
		$result = LDAPsearch($ldap, $cfg->{ldap}->{rootDN}, "base", "ou=*");
		if (defined $result->{$cfg->{ldap}->{rootDN}}) {
			beVerbose('CLEANUP', $cfg->{ldap}->{rootDN});
			qx(ldapdelete -h $cfg->{ldap}->{server} -x -D $cfg->{ldap}->{binddn} -w $cfg->{ldap}->{bindpw} -r $cfg->{ldap}->{rootDN});
		}
		
		# check dir structure
		$result = LDAPsearch($ldap, $cfg->{ldap}->{rootDN}, "base", "ou=*");
		if (!defined($result)) {
			beVerbose("LDAP STRUCTURE", $cfg->{ldap}->{rootDN}." not available; will create it...");

			my $entry = Net::LDAP::Entry->new;
			$entry->dn($cfg->{ldap}->{rootDN});
			$entry->add(objectClass => "top");
			$entry->add(objectClass => "organizationalUnit");
			$entry->add(description => "init by LConfTest.pl");
			$entry->add(ou => $cfg->{ldap}->{rootNode});
			my $val = $entry->update($ldap);
			if ($val->code != 0) {
				beVerbose("LDAP ADD", "ERROR - CODE: ".$val->code." - ".$val->error);
				$result->{code} = 2; $result->{message} = $val->error;
			} else {
				$result->{code} = 0;
				$result->{message} = 'Initialisation finished!';			}
		}
	} else {
		$result->{code} = 2;
		$result->{message} = 'LDAP initialisation aborted!';
	}
	
	return $result;
}

sub testCheckServer {
	my $ldap = shift;
	my $result;
	
	# verbose info
	beVerbose('LDAP CHECK', 'Check initialization of ldap server');
	
	$result = LDAPsearch($ldap, $cfg->{ldap}->{rootDN}, "base", "ou=*");
	if ($result->{$cfg->{ldap}->{rootDN}}->{'description'}) {
		foreach(keys %{$result->{$cfg->{ldap}->{rootDN}}->{'description'}}) {
			if ("$_" eq 'init by LConfTest.pl') {
				$result->{code} = 0;
				$result->{message} = 'LDAP server is already initialized.';
			} else {
				$result->{code} = 2;
				$result->{message} = "You have to initialise your LDAP server with option -i."
			}
		}
	} else {
		$result->{code} = 2;
		$result->{message} = "You have to initialise your LDAP server with option -i."
	}
	
	return $result;
}

sub testAddLdif {
	my $ldap = shift;
	my $file = shift;
	
	# verbose info
	beVerbose('LDAP ADD', 'add file '.$file.' to ldap server');
	
	# import test ldif
	my $val = system("ldapadd -h $cfg->{ldap}->{server} -x -D $cfg->{ldap}->{binddn} -w $cfg->{ldap}->{bindpw} -f $file 1>/dev/null");
	if ($val != 0) {
		$exit->{code} = 2;
		$exit->{message} = "Can't import ldif file ".$file;
	} else {
		$exit->{code} = 0;
		$exit->{message} = "No Errors.";
	}
	
	return $exit;
}

sub testCleanLDAP {
	$ldap = shift;
	
	$result = LDAPsearch($ldap, $cfg->{ldap}->{rootDN}, "single", "objectclass=*");
	foreach my $val (keys %{$result}) {
		beVerbose('CLEANUP', $val);
		qx(ldapdelete -h $cfg->{ldap}->{server} -x -D $cfg->{ldap}->{binddn} -w $cfg->{ldap}->{bindpw} -r $val);
	}
}

1;
