DEFAULTS(
	DefaultTTL("1h"),
	NAMESERVER_TTL("24h")
);
var REG_NONE = NewRegistrar("none");
var DSP_GANDI = NewDnsProvider("gandi");

require("nixos.org.js");

