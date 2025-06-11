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
	CNAME("messages", "core01"),

	A("build01", "185.119.168.10"),

	A("build02", "185.119.168.11"),

	A("build03", "185.119.168.12"),

	A("build04", "185.119.168.13"),

	A("build05", "142.132.171.106"),
	AAAA("build05", "2a01:4f8:1c1b:6d41::"),

	A("eval01", "95.217.15.9"),
	AAAA("eval01", "2a01:4f9:c012:cf00::1"),

	A("eval02", "95.216.209.162"),
	AAAA("eval02", "2a01:4f9:c012:17c6::1"),

	A("eval03", "37.27.189.4"),
	AAAA("eval03", "2a01:4f9:c012:e37b::1"),

	A("eval04", "95.217.18.12"),
	AAAA("eval04", "2a01:4f9:c012:273b::"),
);

