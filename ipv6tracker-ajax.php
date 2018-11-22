<?php
function mac2int($mac) {
    $mac = preg_replace("/[^0-9A-Fa-f]/", '', $mac);
    return base_convert($mac, 16, 10);
}

$database = mysqli_connect('--','--','--','ipv6tracker') or die ("Error; " . mysqli_error($database));

if ( isset($_POST['ipv6address']) ) {
	$ipv6address = trim(filter_input(INPUT_POST, 'ipv6address', FILTER_SANITIZE_STRING));
	echo "Querying $ipv6address<BR><BR>";
	$statement = $database->prepare("select hex(mac),lastseen,username from knownhosts where ipv6address=INET6_ATON(?)");
	$statement->bind_param("s", $ipv6address);
	$statement->execute();
	$statement->bind_result($mac, $lastseen, $username);
	print "<table width=50%>";
	print "<tr><td>MAC Address</td><td>Last Seen</td><td>Username</td></tr>";
	while ( $statement->fetch() ) {
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
	$statement = $database->prepare("select INET6_NTOA(ipv6address),lastseen,username from knownhosts where mac=?");
	$statement->bind_param("s", $macaddress);
	$statement->execute();
	$statement->bind_result($ipv6address, $lastseen, $username);
        print "<table width=50%>";
        print "<tr><td>IPv6 Address</td><td>Last Seen</td><td>Username</td></tr>";
	while ( $statement->fetch() ) {
		print "<tr><td>$ipv6address</td>";
		print "<td>$lastseen</td>";
		print "<td>$username</td></tr>";
	}
	print "</table>";
}
else {
	echo "Don't call the ajax component directly!";
}
?>
