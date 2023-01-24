#! /bin/sh -e

curl --fail https://ftp.ripe.net/ripe/asnames/asn.txt > /tmp/asn.txt

sed -e 's/^\([0-9]\+\) \(.\+\), \([A-Z][A-Z]\)$/\1\t\2\t\3/; t; d' < /tmp/asn.txt > /tmp/asn.tsv

aws s3 cp /tmp/asn.tsv s3://nixos-athena/all-asns/list.tsv
