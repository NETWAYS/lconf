#!/usr/bin/perl -w

sub initializeLDAP {
	my $ldif = shift;
	my $exit;
	my $result;

	# ldap connect
	my $ldap = LDAPconnect('login');

	# need to clear ldap tree?
	$result = LDAPsearch($ldap, $cfg->{ldap}->{dn}, "sub", "ou=LConf");
	if (defined $result->{'ou=LConf,'.$cfg->{ldap}->{dn}}) {
		qx(ldapdelete -h $cfg->{ldap}->{server} -x -D $cfg->{ldap}->{binddn} -w $cfg->{ldap}->{bindpw} -r ou=LConf,$cfg->{ldap}->{dn});
	}

	# check dir structure
	$result = LDAPsearch($ldap, $cfg->{ldap}->{dn}, "sub", "ou=LConf");
	if (!defined($result)) {
		beVerbose("LDAP STRUCTURE", "ou=LConf,$cfg->{ldap}->{dn} not available; will create it...");

		my $entry = Net::LDAP::Entry->new;
		$entry->dn("ou=LConf,$cfg->{ldap}->{dn}");
		$entry->add(objectClass => "top");
		$entry->add(objectClass => "organizationalUnit");
		$entry->add(ou => "LConf");
		my $result = $entry->update($ldap);
		if ($result->code != 0) {
			beVerbose("LDAP ADD", "ERROR - CODE: ".$result->code." - ".$result->error);
			$exit->{code} = 2; $exit->{message} = $result->error;
		}
	}

	# import test ldif
	my $val = qx(ldapadd -h $cfg->{ldap}->{server} -x -D $cfg->{ldap}->{binddn} -w $cfg->{ldap}->{bindpw} -f cases/$ldif);
	if ($val =~ /ldap_add\:/) {
		$exit->{code} = 2;
		$exit->{message} = $val;
	} else {
		$exit->{code} = 0;
		$exit->{message} = "No Errors.";
	}

	# ldap disconnect
	$ldap->unbind();

	return $exit;
}

1;
