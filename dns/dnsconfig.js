DEFAULTS(
	DefaultTTL("1h"),
	NAMESERVER_TTL("24h")
);
var REG_NONE = NewRegistrar("none");
var DSP_NETLIFY = NewDnsProvider("netlify");

require("nixos.org.js");

