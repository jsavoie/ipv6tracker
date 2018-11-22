CREATE TABLE `knownhosts` (
  `ipv6address` binary(16) NOT NULL,
  `lastseen` datetime DEFAULT NULL,
  `mac` bigint(20) unsigned DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ipv6address`),
  KEY `ipv6address` (`ipv6address`)
);
