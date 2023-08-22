module "foundation" {
  source = "./foundation"
  fastly_customer_id = local.fastly_customer_id
}

module "raito" {
  source = "./raito"
}
