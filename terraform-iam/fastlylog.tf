module "fastlylogs" {
  source             = "./fastlylog"
  fastly_customer_id = local.fastly_customer_id
}
