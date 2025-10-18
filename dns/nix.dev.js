D("nix.dev",
	REG_NONE,
	DnsProvider(DSP_GANDI),

	// Domain is not used for mail
	SPF_BUILDER({
		label: "@",
		parts: [
			"v=spf1",
			"-all"
		]
	}),
	TXT("*._domainkey", "v=DKIM1; p="),
	DMARC_BUILDER({
		policy: "reject",
		subdomainPolicy: "reject",
		alignmentDKIM: "strict",
		alignmentSPF: "strict"
	}),

	TXT("@", "google-site-verification=J55RGHyOPKpHAyIHVfBy1RdY_LuVIvLyuyR8deO62YE"),

	A("@", "99.83.231.61"),
	A("@", "75.2.60.5"),
	CNAME("www", "nix-dev.netlify.app.")
);

