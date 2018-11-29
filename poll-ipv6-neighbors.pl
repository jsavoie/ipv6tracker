#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Net::SSH2;

# Setup database connnection
my $db_handle = DBI->connect("dbi:mysql:database=ipv6tracker;host=--", "--", "--") or die "Cannot connect to the database";
my $updateaddress = $db_handle->prepare("replace into knownhosts set mac=?, lastseen=NOW(), ipv6address=INET6_ATON(?)");

sub mac_hex2num {
  my $mac_hex = shift;

  # Convert both tradditional and Cisco MAC formats
  $mac_hex =~ s/(:|-|\.)//g;

  $mac_hex = substr(('0'x12).$mac_hex, -12);
  my @mac_bytes = unpack("A2"x6, $mac_hex);

  my $mac_num = 0;
  foreach (@mac_bytes) {
    $mac_num = $mac_num * (2**8) + hex($_);
  }

  return $mac_num;
}

sub pollhost {
	my $ssh_host = shift;
	my $ssh_username = shift;
	my $ssh_password = shift;
	my $type = shift;

	my $ssh = Net::SSH2->new();

	# Choice was made to move onto the next host, rather than calling die here.
	$ssh->connect($ssh_host) or return;
	$ssh->auth_password($ssh_username, $ssh_password) or return;
	my $channel = $ssh->channel();

	if ($type eq "fortigate") {
		$channel->shell();

		# Read the FortiGate IPv6 neighbors table
		print $channel "diag ipv6 neighbor-cache list\n";

		while (my $line = <$channel>) {
			if ($line =~ /^\s*$/) {
				# IPv6 neighbors table ends with a blank line
				print $channel "exit\n";
			}
			elsif ($line =~ /\s(?<ipv6>([0-9a-f]{1,4}:){7,7}[0-9a-f]{1,4}|([0-9a-f]{1,4}:){1,7}:|([0-9a-f]{1,4}:){1,6}:[0-9a-f]{1,4}|([0-9a-f]{1,4}:){1,5}(:[0-9a-f]{1,4}){1,2}|([0-9a-f]{1,4}:){1,4}(:[0-9a-f]{1,4}){1,3}|([0-9a-f]{1,4}:){1,3}(:[0-9a-f]{1,4}){1,4}|([0-9a-f]{1,4}:){1,2}(:[0-9a-f]{1,4}){1,5}|[0-9a-f]{1,4}:((:[0-9a-f]{1,4}){1,6})|:((:[0-9a-f]{1,4}){1,7}|:)|fe80:(:[0-9a-f]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-f]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\s(?<mac>([0-9a-f][0-9a-f]:){5,5}([0-9a-f][0-9a-f]))\s/i)
			{
				my $ipv6address = $+{ipv6};
				my $macaddress = $+{mac};
				$updateaddress->execute(mac_hex2num($macaddress), $ipv6address);
			}
		}
	}
	elsif ($type eq "cisco") {
		$channel->shell();

		# Remove terminal screen pauses
		print $channel "terminal length 0\n";

                # Read the Cisco IPv6 neighbors table
		print $channel "show ipv6 neighbors\n";

                while (my $line = <$channel>) {
			if ($line =~ /^\s*$/) {
				# IPv6 neighbors table ends with a blank line
				print $channel "exit\n";
			}
			elsif ($line =~ /(?<ipv6>([0-9a-f]{1,4}:){7,7}[0-9a-f]{1,4}|([0-9a-f]{1,4}:){1,7}:|([0-9a-f]{1,4}:){1,6}:[0-9a-f]{1,4}|([0-9a-f]{1,4}:){1,5}(:[0-9a-f]{1,4}){1,2}|([0-9a-f]{1,4}:){1,4}(:[0-9a-f]{1,4}){1,3}|([0-9a-f]{1,4}:){1,3}(:[0-9a-f]{1,4}){1,4}|([0-9a-f]{1,4}:){1,2}(:[0-9a-f]{1,4}){1,5}|[0-9a-f]{1,4}:((:[0-9a-f]{1,4}){1,6})|:((:[0-9a-f]{1,4}){1,7}|:)|fe80:(:[0-9a-f]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-f]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\s+\d+\s(?<mac>[0-9a-f]{4,4}\.[0-9a-f]{4,4}\.[0-9a-f]{4,4})\s/i)
			{
                                my $ipv6address = $+{ipv6};
                                my $macaddress = $+{mac};
                                $updateaddress->execute(mac_hex2num($macaddress), $ipv6address);
			}
                }

	}
	else {
		die "No command defined for this host type!\n";
	}

	$channel->close();
	$ssh->disconnect();
}

open(HOSTLIST, "<", "$ARGV[0]") or die "$@";
while (<HOSTLIST>) {
	chomp;
	my @line = split(',');
	if (@line != 4) { die "Wrong format!\n"; }

	# print "Polling host $line[0]\n";
	pollhost($line[0], $line[1], $line[2], $line[3]);
}
close(HOSTLIST);

# disconnect from database
$db_handle->disconnect() or die "Cannot disconnect from database";
