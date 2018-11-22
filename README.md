Project Description:
One difficulty that people have running IPv6 networks with SLAAC, is tracking abuse from IPv6 privacy addresses.  These addresses are temporary, and not encoded with a MAC address.

This project is a collection of simple scripts to collect data IPv6 neightbors tables from various layer3 routers in your network.  A description of files follows.

# Files that will run through cron
- poll-ipv6-neighbors.pl : The core script that is run perodically and will scrap the IPv6 neighbors from either a fortigate or a cisco device.
- expire-ipv6-entries.pl : Age out older entries from the database, the default is set to 30 days.
- populate-ipv6-usernames.pl : Will pull in radius logs from Windows radius servers and populate the username field.

# Web interface
- ipv6tracker.html : Uses jquery (not included), and allows you to query the database for a given IPv6 or MAC address
- ipv6tracker-ajax.php : Backend pulls records from the database.  I would recommend you create a unique account with only "select" rights this database.

# Various files other files
- create-database.sql : Creates the table we will use.  I would recommend creating a unique database and user for this.
- crontabs.txt : The cron jobs I personally run for this.  You can change the frequency if you wish.
- example-production-hosts.txt : A file passed as an argument to poll-ipv6-neighbors.pl.  I call this file prod-ssh-hosts.txt in my example crontabs.
				 The format for this file is host,username,password,type.  The two supported types are cisco/fortigate.  If you wish to support others 
				 please provide pull requests.
