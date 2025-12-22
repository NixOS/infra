D("nixos.org",
	REG_NONE,
	DnsProvider(DSP_GANDI),

	TXT("@", "apple-domain-verification=OvacO4lGB9A6dBFg"),
	TXT("@", "brevo-code:f580a125e215ecb440363a15cdf47a17"),	
	TXT("@", "google-site-verification=Pm5opvmNjJOwdb7JnuVJ_eFBPaZYWNcAavY-08AJoGc"),
	// bluesky account/domain binding
	TXT("_atproto", "did=did:plc:bf43o4nxudgubwt4iljpayb7"),

	CAA_BUILDER({
		label: "@",
		iodef: "mailto:infra+caa@nixos.org",
		iodef_critical: true,
		issue: ["letsencrypt.org"],
		issue_critical: true,
		issuewild: "none",
		issuewild_critical: true,
	}),

	// nixos.org mailing
	MX("@", 10, "umbriel"),
	SPF_BUILDER({
		label: "@",
		parts: [
			"v=spf1",
			"a:umbriel.nixos.org",
			"-all"
		]
	}),
	DMARC_BUILDER({
		policy: "none",
	}),

	// discourse
	A("discourse", "195.62.126.31"),
	AAAA("discourse", "2a02:248:101:62::146f"),
	MX("discourse", 10, "mail.nixosdiscourse.fcio.net."),
	DMARC_BUILDER({
		label: "discourse",
		policy: "none",
	}),
	SPF_BUILDER({
		label: "discourse",
		parts: [
			"v=spf1",
			"ip4:185.105.252.151",
			"ip6:2a02:248:101:62::1479",
			"-all"
		]
	}),
	TXT("mail._domainkey.discourse", "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDmxDhMfDl6lnueSRCjYiWIDeTAJXR9Yw0PfpBfG7GPUIkMyqy9jVGpb4ECVTt9S1zfpr4dbtCgir781oVwZiwGIWzC8y8XsD37wernQIPN4Yubnrnpw+6lill4uA/AuyU/ghbeZ5lW03pHD//2EW4YEu+Jw4aS4rF0Wtk+BlJRCwIDAQAB"),

	// fastly
	CNAME("_acme-challenge.cache", "k2hql6g4rigivyu6nn.fastly-validations.com."),
	CNAME("_acme-challenge.cache-staging", "kqwx9cvuf7lvjo8u9b.fastly-validations.com."),
	CNAME("_acme-challenge.channels", "9u55qij5w2odiwqxfi.fastly-validations.com."),
	CNAME("_acme-challenge.artifacts", "bsk6mjvi6b1r6wekb0.fastly-validations.com."),
	CNAME("_acme-challenge.releases", "s731ezp9ameh5f349b.fastly-validations.com."),
	CNAME("_acme-challenge.tarballs", "vnqm62k5sjx9jogeqg.fastly-validations.com."),
	CNAME("cache", "dualstack.n.sni.global.fastly.net."),
	CNAME("cache-staging", "dualstack.n.sni.global.fastly.net."),
	CNAME("channels", "dualstack.n.sni.global.fastly.net."),
	CNAME("artifacts", "dualstack.n.sni.global.fastly.net."),
	CNAME("releases", "dualstack.n.sni.global.fastly.net."),
	CNAME("tarballs", "dualstack.n.sni.global.fastly.net."),

	// hydra.nixos.org
	A("haumea", "46.4.89.205"),
	AAAA("haumea", "2a01:4f8:212:41c9::1"),

	A("mimas", "157.90.104.34"),
	AAAA("mimas", "2a01:4f8:2220:11c8::1"),
	CNAME("hydra", "mimas"),
	CNAME("queue-runner.hydra", "mimas"),

	A("pluto", "37.27.99.100"),
	AAAA("pluto", "2a01:4f9:3070:15e0::1"),
	CNAME("alerts", "pluto"),
	CNAME("grafana", "pluto"),
	CNAME("monitoring", "pluto"),
	CNAME("prometheus", "pluto"),

	A("titan", "159.69.62.224"),
	AAAA("titan", "2a01:4f8:231:e53::1"),

	// hydra builfarm
	AAAA("eager-heisenberg.mac", "2a01:4f8:d1:a027::2"),
	A("elated-minsky.builder", "167.235.95.99"),

	AAAA("elated-minsky.builder", "2a01:4f8:2220:1b03::1"),

	A("enormous-catfish.mac", "142.132.140.199"),

	A("goofy-hopcroft.builder", "135.181.225.104"),
	AAAA("goofy-hopcroft.builder", "2a01:4f9:3071:2d8b::1"),

	A("growing-jennet.mac", "23.88.76.75"),

	A("hopeful-rivest.builder", "135.181.230.86"),
	AAAA("hopeful-rivest.builder", "2a01:4f9:3080:388f::1"),

	A("intense-heron.mac", "23.88.75.215"),

	AAAA("kind-lumiere.mac", "2a09:9340:808:60a::1"),

	A("maximum-snail.mac", "23.88.76.161"),

	A("sleepy-brown.builder", "162.55.130.51"),
	AAAA("sleepy-brown.builder", "2a01:4f8:271:5c14::1"),

	A("sweeping-filly.mac", "142.132.141.35"),

	// hydra staging area
	A("staging-hydra", "157.180.25.203"),
	AAAA("staging-hydra", "2a01:4f9:c012:d5d3::1"),
	CNAME("queue-runner.staging-hydra", "staging-hydra"),

	// services infra
	A("caliban", "65.109.26.213"),
	AAAA("caliban", "2a01:4f9:5a:186c::2"),
	CNAME("chat", "caliban"),
	CNAME("live", "caliban"),
	CNAME("matrix", "caliban"),
	CNAME("nixpkgs-swh", "caliban"),
	CNAME("survey", "caliban"),
	CNAME("vault", "caliban"),
	DMARC_BUILDER({
		label: "caliban",
		policy: "none"
	}),
	SPF_BUILDER({
		label: "caliban",
		parts: [
			"v=spf1",
			"ip4:65.109.26.213",
			"ip6:2a01:4f9:5a:186c::2",
			"-all"
		]
	}),
	TXT("mail._domainkey.caliban", "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDCLtvNH4Ly+9COXf7InptMvoA7I5O347D7+j+saECt7RRe8yNz4TmhJTyJik+bg7e3+l7EJM0vE6k7xtpGBXACY6CCmg/8EgUi6YnDd126ttJHWpoqO96w4SWX93G+ZnoSC8O5rTPqdaTTkntYDTrw5u5n+7RA8GarZadgmaEzwIDAQAB"),

	A("umbriel", "37.27.20.162"),
	AAAA("umbriel", "2a01:4f9:c011:8fb5::1"),
	// See `nixos.org.mail.key` in `non-critical-infra/modules/mailserver/default.nix`.
	TXT("mail._domainkey", "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcgNq4+Y23GxN8Mdza437tL5DuJJZU1y6VzTCwSi6cBNLyBDci2cmqXx/gm1sA3yv7+h+8/OyJpEgcbCIW/Ygs1XLuECqvXVX8MU6Djn4KY+d2sU1tlUdqvNM86puoneQtjEv9rDsjf3HGqaeOcjetFnQW7H+qcNcaEShxyKztzQIDAQAB"),
	CNAME("freescout", "umbriel.nixos.org."),

	// ngi
	A("makemake.ngi", "116.202.113.248"),
	AAAA("makemake.ngi", "2a01:4f8:231:4187::"),
	CNAME("buildbot.ngi", "makemake.ngi.nixos.org."),
	CNAME("cryptpad.ngi", "makemake.ngi.nixos.org."),
	CNAME("cryptpad-sandbox.ngi", "makemake.ngi.nixos.org."),
	CNAME("summer", "makemake.ngi.nixos.org."),

	A("tracker-staging.security", "188.245.41.195"),
	AAAA("tracker-staging.security", "2a01:4f8:1c1b:b87b::1"),

	A("tracker.security", "91.99.31.214"),
	AAAA("tracker.security", "2a01:4f8:1c1b:6921::1"),

	// wiki
	A("wiki", "65.21.240.250"),
	AAAA("wiki", "2a01:4f9:c012:8178::"),
	// Direct access to wiki server in Helsinki (for deployments)
	A("he1.wiki", "65.21.240.250"),
	AAAA("he1.wiki", "2a01:4f9:c012:8178::"),
	DMARC_BUILDER({
		label: "wiki",
		policy: "none"
	}),
	SPF_BUILDER({
		label: "wiki",
		parts: [
			"v=spf1",
			"ip4:65.21.240.250",
			"ip6:2a01:4f9:c012:8178::",
			"-all"
		]
	}),
	TXT("mail._domainkey.wiki", "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDa+KjIljYr3q5MWWK7sEYzjR8OcA32zBh9BCPo6/HlY1q2ODTYsmE/FDZWpYMzM5z+ddnuGYdXia322XnZaNpZNoq1TbGYuQ5DsgAEK09CGoLuzONg3PSXTrkG7E2Sd6wstwHGJ5FHxSLKtNoWkknt9F5XAFZgXapO0w54p+BWvwIDAQAB"),

	// test.wiki subdomain with Fastly
	CNAME("test.wiki", "dualstack.n.sni.global.fastly.net."),
	CNAME("_acme-challenge.test.wiki", "zsz0meyel8hxoy9dtb.fastly-validations.com."),

	// github org/domain binding
	TXT("_github-challenge-nixos", "9e10a04a4b"),

	// github pages
	CNAME("mobile", "nixos.github.io."),
	CNAME("ngi", "ngi-nix.github.io."),
	CNAME("reproducible", "nixos.github.io."),

	TXT("_github-pages-challenge-ngi-nix.ngi", "4e8bffbb7ced2aec7be1f8cf3561d6"),
	TXT("_github-pages-challenge-nixos", "f3a423ba6916e972cfb1e74f82f601"),

	// netlify pages
	A("@", "75.2.60.5"),
	A("@", "99.83.231.61"),
	CNAME("brand", "nixos-brand.netlify.app."),
	CNAME("common-styles", "nixos-common-styles.netlify.app."),
	CNAME("planet", "nixos-planet.netlify.app."),
	CNAME("search", "nixos-search.netlify.app."),
	CNAME("status", "nixos-status.netlify.app."),
	CNAME("weekly", "nixos-weekly.netlify.com."),
	CNAME("www", "nixos-homepage.netlify.app."),
);
