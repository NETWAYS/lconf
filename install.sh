#!/usr/bin/perl -w

# includes
use strict;

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #
# setup 
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #

# vars
my $cfg;

# get current dir
$cfg->{mainDir} = $0;
$cfg->{mainDir} =~ s/\/[^\/]*$//;
$cfg->{mainDir} = '.' if $cfg->{mainDir} eq 'install.pl';
	
# tasks
my $FILES = {	
	'LConfExport.pl' => {
			'source' => '/source/LConfExport.pl.in', 
			'target' => '/',
			'changes' => {
					'PREFIX' => 'defined'
			}
	},
	
	'LConfImport.pl' => {
			'source' => '/source/LConfImport.pl.in', 
			'target' => '/',
			'changes' => {
					'PREFIX' => 'defined'
			}
	},
	
	'LConfSlaveExport.pl' => {
			'source' => '/source/LConfSlaveExport.pl.in',
			'target' => '/',
			'changes' => {
					'PREFIX' => 'defined'
			}
	},
	
	'config.pm' => {
			'source' => '/source/config.pm.in',
			'target' => '/etc',
			'changes' => {
					'LDAP_ROOT_DN' => 'defined',
					'USER' => 'defined',
					'LOCK_PATH' => '$PREFIX/var/LConfExport.lock',
					'HASHDUMP' => '$PREFIX/var/LConfExport.hashdump',
					'TMPDIR' => '$PREFIX/tmp',
					'STARTINGPOINT' => 'defined',
					'LDAP_PREFIX' => 'defined'
			}
	},
	
	'misc.pm' => {
			'source' => '/source/misc.pm.in',
			'target' => '/lib'
	},
	
	'ldap.pm' => {
			'source' => '/source/ldap.pm.in',
			'target' => '/lib'
	},
	
	'generate.pm' => {
			'source' => '/source/generate.pm.in',
			'target' => '/lib'
	}
	
};

# questions
my $QUESTIONS = {
	'1' => {
		'name' => 'PREFIX',
		'message' => 'Install files in...',
		'suggestion' => '/usr/local/LConf'
	},
	
	'2' => {
		'name' => 'USER',
		'message' => 'Install files with user...',
		'suggestion' => 'icinga'
	},
	
	'3' => {
		'name' => 'GROUP',
		'message' => 'Install files with group...',
		'suggestion' => 'icinga'
	},
	
	'4' => {
		'name' => 'LDAP_SCHEMA_DIR',
		'message' => "You can find LDAP schema files in...\nHINT: find /etc -name *.schema",
		'suggestion' => '/etc/ldap/schema'
	},
	
	'5' => {
		'name' => 'LDAP_ROOT_DN',
		'message' => 'Your ldap rootdn is...',
		'suggestion' => 'dc=example,dc=org'
	},
	
	'6' => {
		'name' => 'LDAP_PREFIX',
		'message' => 'Objectclass and attribute prefix will be...',
		'suggestion' => 'lconf'
	},
	
	'7' => {
		'name' => 'STARTINGPOINT',
		'message' => 'LConf Exporter should start exporting at...',
		'suggestion' => 'IcingaConfig'
	}
};


	
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #
# doing...
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #

# define vars
my $data;

# welcome message
$data .= "##############################\n";
$data .= "#    LConf Install Wizard    #\n";
$data .= "##############################\n";
$data .= "\n";
$data .= "...simple, stupid, but works!\n";
$data .= "\n";

# only run as root
my $id = qx(id -u);
ScriptExit(2, "You're not root! Please run installer as root...") if $id != 0;

# check for ldap utils
print "CHECK: ldap utils...\n";
my $ldapadd = qx(which ldapadd);
if (!defined $ldapadd || $ldapadd eq '') {
	ScriptExit(2, "OS package with ldap utils is not installed")
}

# check if perl ldap modules are in place
print "CHECK: Perl Modules\n";
eval { require Net::LDAP } or ScriptExit(2, "Perl module 'Net::LDAP' is not installed");
eval { require Net::LDAP::Entry } or ScriptExit(2, "Perl module 'Net::LDAP::Entry' is not installed");

# ask dumb questions
foreach my $question (sort keys %{$QUESTIONS}) {
	print "\n";
	print "=> USER INTERACTION NEEDED!\n";
	print "$QUESTIONS->{$question}->{message}\n";
	print "[$QUESTIONS->{$question}->{suggestion}]: ";
	
	$QUESTIONS->{$question}->{data} = <STDIN>; chomp($QUESTIONS->{$question}->{data});
	$QUESTIONS->{$question}->{data} = $QUESTIONS->{$question}->{suggestion} if $QUESTIONS->{$question}->{data} eq '';
	
	print "$QUESTIONS->{$question}->{name} = $QUESTIONS->{$question}->{data}\n\n";
}

# re-map the answers to config hash
foreach my $val (keys %{$QUESTIONS}) { $cfg->{$QUESTIONS->{$val}->{name}} = $QUESTIONS->{$val}->{data}; } 

# NOW, DO THE INSTALLATION JOB!!
# check ldap schema dir
print "CHECK: LDAP schema dir\n";
my $filecount = qx(ls $cfg->{LDAP_SCHEMA_DIR}/*.schema 2>/dev/null | wc -l);
$filecount =~ m/(\d+)/; $filecount = $1;
ScriptExit(2, "'$cfg->{LDAP_SCHEMA_DIR}' is not a LDAP schema directory!") if $filecount == 0;

print "INSTALL Dir structure\n";
mkdir("$cfg->{PREFIX}", 0750);
mkdir("$cfg->{PREFIX}/etc", 0750);
mkdir("$cfg->{PREFIX}/lib", 0750);
mkdir("$cfg->{PREFIX}/var", 0750);
mkdir("$cfg->{PREFIX}/tmp", 0750);

# create files
foreach my $file (keys %{$FILES}) {
	print "CREATE file $file\n";
	
	# read
	my $data = readFile("$cfg->{mainDir}/$FILES->{$file}->{source}");
	
	# change stuff
	foreach (keys %{$FILES->{$file}->{changes}}) {
		if ($FILES->{$file}->{changes}->{$_} eq 'defined') {
			# evaluate
			my $val = $FILES->{$file}->{changes}->{$_};
			eval "\$val=\$cfg->{\$_};";
			
			# replace
			$data =~ s/<-$_->/$val/;
		} else {
			# get var and evaluate
			$FILES->{$file}->{changes}->{$_} =~ m/.*\$([\d\w]+)\/.*/;
			my $val = $1; my $val_before = $val; eval "\$val=\$cfg->{\$val};";
			
			# replace
			$FILES->{$file}->{changes}->{$_} =~ s/\$$val_before/$val/;
			$data =~ s/<-$_->/$FILES->{$file}->{changes}->{$_}/;
		}
	}
	
	# generally, replace prefix with the real prefix
	$data =~ s/<-LDAP_PREFIX->/$cfg->{LDAP_PREFIX}/g;
	
	# write
	writeFile("$cfg->{PREFIX}$FILES->{$file}->{target}/$file", $data);
}

# create ldap schema file
print "CREATE ldap schema file\n";
$data = readFile("$cfg->{mainDir}/source/netways.schema.in");
$data =~ s/<-LDAP_PREFIX->/$cfg->{LDAP_PREFIX}/g;
writeFile("$cfg->{LDAP_SCHEMA_DIR}/netways.schema", $data);



# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #
# functions
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #

sub ScriptExit {
	my $code = shift;
	my $message = shift;
	
	my @state = ('OK', 'WARNING', 'ERROR');
	
	print "$state[$code]: $message\n";
	exit $code;
}

sub readFile {
	my $file = shift;
	my $data;
	
	open FILEHANDLE, "$file" or die "Can't read '$file': $!";
	while(<FILEHANDLE>) {
		$data .= $_;
	}
	close FILEHANDLE;
	
	return $data;
}

sub writeFile {
	my $file = shift;
	my $data = shift;
	
	
	open (FILEHANDLE, ">$file") or die $!;
	print FILEHANDLE $data;
	close(FILEHANDLE);
}
