output "bucket_name" {
  value = aws_s3_bucket.logs.bucket
}

output "s3_domain" {
  # I don't kno whow to get this from the S3 bucket resource :/.
  value = "s3.eu-west-1.amazonaws.com"
}

output "iam_role_arn" {
  value = aws_iam_role.fastly_log_forwarder.arn
}



output "period" {
  # Frequency that Fastly servers will push a file to S3, in seconds
  value = 3600
}

output "format" {
  value = "{${join(",", [for k, v in {
    asn                 = "%%{client.as.number}V",
    elapsed_usec        = "%%{json.escape(time.elapsed.usec)}V",
    fastly_is_edge      = "%%{if(fastly.ff.visits_this_service == 0, \"true\", \"false\")}V",
    fastly_server       = "\"%%{json.escape(server.identity)}V\"",
    geo_country         = "\"%%{json.escape(client.geo.country_name)}V\"",
    geo_region          = "\"%%{json.escape(client.geo.region.utf8)}V\"",
    geo_speed           = "\"%%{json.escape(client.geo.conn_speed)}V\"",
    host                = "\"%%{json.escape(if(req.http.Fastly-Orig-Host, req.http.Fastly-Orig-Host, req.http.Host))}V\"",
    request_method      = "\"%%{json.escape(req.method)}V\"",
    request_protocol    = "\"%%{json.escape(req.proto)}V\"",
    request_referer     = "\"%%{json.escape(req.http.referer)}V\"",
    request_size        = "%%{json.escape(req.bytes_read)}V",
    request_user_agent  = "\"%%{json.escape(req.http.User-Agent)}V\"",
    response_body_size  = "%%{resp.body_bytes_written}V",
    response_reason     = "%%{if(resp.response, \"%22\"+json.escape(resp.response)+\"%22\", \"null\")}V",
    response_state      = "\"%%{json.escape(fastly_info.state)}V\"",
    response_status     = "\"%%{resp.status}V\"",
    timestamp           = "\"%%{strftime(\\{\"%Y-%m-%dT%H:%M:%S%z\"\\}, time.start)}V\"",
    tls_client_cipher   = "\"%%{json.escape(if(tls.client.cipher, tls.client.cipher, \"null\"))}V\"",
    tls_client_protocol = "\"%%{json.escape(if(tls.client.protocol, tls.client.protocol, \"null\"))}V\"",
    url                 = "\"%%{json.escape(req.url)}V\"",
  } : "\"${k}\": ${v}"])}}"
}