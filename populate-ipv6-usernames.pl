#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Filesys::SmbClient;
use Date::Calc qw( Today Add_Delta_Days );

# Login details
my $smbuser = "--";
my $smbworkgrp = "--";
my $smbpass = "--";
my @smbservers = qw ("--" "--");

# Hash of successful logins
my %logins;

# Setup database connnection
my $db_handle = DBI->connect("dbi:mysql:database=ipv6tracker;host=--", "--", "--") or die "Cannot connect to the database";
my $updateusername = $db_handle->prepare("replace into authenticatedusers set username=?, mac=?");

sub mac_hex2num {
  my $mac_hex = shift;

  # Convert both tradditional and Cisco MAC formats
  $mac_hex =~ s/(:|-|\.|")//g;

  $mac_hex = substr(('0'x12).$mac_hex, -12);
  my @mac_bytes = unpack("A2"x6, $mac_hex);

  my $mac_num = 0;
  foreach (@mac_bytes) {
    $mac_num = $mac_num * (2**8) + hex($_);
  }

  return $mac_num;
}

foreach my $server (@smbservers) {
	# Get the radius log
	local *RLOG;
	tie(*RLOG, 'Filesys::SmbClient');
	my $smb = new Filesys::SmbClient(username => $smbuser, workgroup => $smbworkgrp, password => $smbpass);

	# Log file is saved in the format IN + shortyear + month + day. log
	my ($year, $month, $day) = Add_Delta_Days(Today(), -1);
	my $radiuslog = sprintf("IN%02d%02d%02d.log", $year % 100, $month, $day);

	# Choice was made to move onto the next host, rather than calling die here.
	open (RLOG, "smb://$server/Logfiles/$radiuslog", "<") or next;

	# Process the log, save successful logins to a hash
	while (<RLOG>) {
		my @line = split(',');

		# Only process on valid log entries
		if ((defined $line[6]) and (defined $line[8])) {
			my $username = $line[6];
			$username =~ s/"//g;
			my $macaddress = mac_hex2num($line[8]);

			# Don't store empty values, or machine account logins
			if (($username ne "") and ($macaddress !=0) and ($username !~ /\/Computers\//)) {
				$logins{$macaddress} = $username;
			}
		}
	}
	close(RLOG);
}

# Update database records
for my $login ( sort keys %logins ) {
	# print "Found successful login with MAC $login using account $logins{$login}\n";
	$updateusername->execute($logins{$login}, $login);
}

# disconnect from database
$db_handle->disconnect() or die "Cannot disconnect from database";
