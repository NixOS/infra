D("nixcon.org",
	REG_NONE,
	DnsProvider(DSP_GANDI),

	MX("@", 10, "umbriel.nixos.org."),
	SPF_BUILDER({
		label: "@",
		parts: [
			"v=spf1",
			"a:umbriel.nixos.org",
			"-all"
		]
	}),
	// Matching private key in `non-critical-infra/secrets/nixcon.org.mail.key.umbriel`
	TXT("mail._domainkey", "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC1wQ2uPZfdlGmjDDxeNVet7IEFxS55TpWuqQWNKmd4fX8HcKKw7kVHXU5+gjT37wMUI27ZZnIobYhumnl+BLiXZqbuzAt7s3dbJU2de2ZWxOqcDRbK6m2A3AwIAiMzzRUjx14EWgnw55KRi2enpLyS0pKGdvSquHnxaySkAF8YIwIDAQAB"),
	DMARC_BUILDER({
		policy: "none",
	}),

	// Websites
	TXT("_github-pages-challenge-nixcon", "6608e513e09036ab8cadb7ca4eb71b"),

	ALIAS("@", "nixcon.github.io."),
	CNAME("www", "nixcon.github.io."),

	CNAME("2015", "nixcon.github.io."),
	CNAME("2016", "nixcon.github.io."),
	CNAME("2017", "nixcon.github.io."),
	CNAME("2018", "nixcon.github.io."),
	CNAME("2019", "nixcon.github.io."),
	CNAME("2020", "nixcon.github.io."),
	CNAME("2022", "nixcon.github.io."),
	CNAME("2023", "nixcon.github.io."),
	CNAME("2024-na", "nixcon.github.io."),
	CNAME("2024", "nixcon.github.io."),
	CNAME("2025", "nixcon.github.io."),

	// Scheduling
	CNAME("cfp", "pretalx.com."),
	CNAME("talks", "pretalx.com."),

	// Ticketing
	CNAME("tickets", "nixcon.cname.pretix.eu."),

	// 2025 ticket voucher eligibility check
	CNAME("vouchers", "ners.ch.")
);
