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

	ALIAS("@", "nix-dev.netlify.app."),
	CNAME("www", "nix-dev.netlify.app.")
);

