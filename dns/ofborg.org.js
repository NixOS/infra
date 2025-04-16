D("ofborg.org",
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

	ALIAS("@", "core.ofborg.org."),

	A("core", "136.144.57.217"),
	AAAA("core", "2604:1380:45f1:400::3"),
	CNAME("events", "core"),
	CNAME("monitoring", "core"),
	CNAME("webhook", "core"),

	A("core01", "138.199.148.47"),
	AAAA("core01", "2a01:4f8:c012:cda4::1"),
	CNAME("gh-webhook", "core01"),
	CNAME("logs", "core01"),
	CNAME("messages", "core01")
);

