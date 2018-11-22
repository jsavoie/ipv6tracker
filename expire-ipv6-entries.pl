#!/usr/bin/perl

use strict;
use warnings;
use DBI;

# Setup database connnection
my $db_handle = DBI->connect("dbi:mysql:database=ipv6tracker;host=--", "--", "--") or die "Cannot connect to the database";
my $deleteoldrecords = $db_handle->prepare("delete from knownhosts where lastseen < DATE_ADD(NOW(), INTERVAL -? DAY)");
my $deletebrokenrecords = $db_handle->prepare("delete from knownhosts where mac is NULL or lastseen is NULL");

# Delete entries older than 30 days
$deleteoldrecords->execute(30);

# Purge broken records
$deletebrokenrecords->execute();

# disconnect from database
$db_handle->disconnect() or die "Cannot disconnect from database";
