DEFAULTS(
	DefaultTTL("1h"),
	NAMESERVER_TTL("24h")
);
var REG_NONE = NewRegistrar("none");
var DSP_GANDI = NewDnsProvider("gandi");

require("ofborg.org.js");
require("nix.dev.js");
require("nixos.org.js");

