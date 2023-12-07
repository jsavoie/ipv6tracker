<?php
function mac2int($mac) {
    $mac = preg_replace("/[^0-9A-Fa-f]/", '', $mac);
    return base_convert($mac, 16, 10);
}

$database = mysqli_connect('--','--','--','ipv6tracker') or die ("Error; " . mysqli_error($database));

if ( isset($_POST['ipv6address']) ) {
	$ipv6address = trim(filter_input(INPUT_POST, 'ipv6address', FILTER_SANITIZE_STRING));
	echo "Querying $ipv6address<BR><BR>";
	$statement = $database->prepare("select hex(knownhosts.mac),lastseen,authenticatedusers.username from knownhosts left join authenticatedusers on knownhosts.mac = authenticatedusers.mac where ipv6address=INET6_ATON(?) order by lastseen desc");
	$statement->bind_param("s", $ipv6address);
	$statement->execute();
	$statement->bind_result($mac, $lastseen, $username);
	print "<table width=50%>";
	print "<tr><td>MAC Address</td><td>Last Seen</td><td>Username</td></tr>";
	while ( $statement->fetch() ) {
		// Fix for addresses that start with 0s
		$mac = str_pad($mac, 12, "0", STR_PAD_LEFT);

		print "<tr><td>" . implode(':', str_split($mac,2)) . "</td>";
		print "<td>$lastseen</td>";
		print "<td>$username</td></tr>";
	}
        print "</table>";
}
elseif ( isset($_POST['macaddress']) ) {
	$macaddress = trim(filter_input(INPUT_POST, 'macaddress', FILTER_SANITIZE_STRING));
	echo "Querying $macaddress<BR><BR>";
	$macaddress = mac2int($macaddress);

	// Search for the username associated from this MAC
	$statement1 = $database->prepare("select username from authenticatedusers where mac=?");
	$statement1->bind_param("s", $macaddress);
	$statement1->execute();
	$statement1->bind_result($username);
	while ( $statement1->fetch() ) {
		print "Found username: $username<BR><BR>";
	}

	// Search for all the IPv6 addresses this MAC has used
	$statement2 = $database->prepare("select INET6_NTOA(knownhosts.ipv6address),lastseen from knownhosts where mac=? order by lastseen desc");
	$statement2->bind_param("s", $macaddress);
	$statement2->execute();
	$statement2->bind_result($ipv6address, $lastseen);
        print "<table width=50%>";
        print "<tr><td>IPv6 Address</td><td>Last Seen</td></tr>";
	while ( $statement2->fetch() ) {
		print "<tr><td>$ipv6address</td>";
		print "<td>$lastseen</td></tr>";
	}
	print "</table>";
}
else {
	echo "Don't call the ajax component directly!";
}
?>
