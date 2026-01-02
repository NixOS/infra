D("nixcon.org",
	REG_NONE,
	DnsProvider(DSP_GANDI),

	CAA_BUILDER({
		label: "@",
		iodef: "mailto:infra+caa@nixos.org",
		iodef_critical: true,
		issue: ["letsencrypt.org"],
		issue_critical: true,
		issuewild: "none",
		issuewild_critical: true,
	}),

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

	// https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain
	A("@", "185.199.109.153"),
	A("@", "185.199.111.153"),
	AAAA("@", "2606:50c0:8001::153"),
	AAAA("@", "2606:50c0:8003::153"),

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
	CNAME("vouchers", "cache.ners.ch."),

	// 2025 bee game
	CNAME("bee", "cache.ners.ch.")
);
