# `umbriel`

## Provisioning

If you recreate `umbriel`, it will generate a new `DKIM` signature. That's ok to
do, but you'll need to update the corresponding `mail._domainkey.*` `TXT` DNS
record in `terraform/dns.tf` with the generated key in
`/var/dkim/mail-test.nixos.org.mail.txt`.

TODO: declaratively manage the `DKIM` key once
<https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/merge_requests/344>
lands.
