locals {
  image_info_file = file("${var.image_store_path}/nix-support/image-info.json")

  image_info   = jsondecode(local.image_info_file)
  image_system = local.image_info.system
  root_disk    = local.image_info.disks.root

  is_zfs   = lookup(local.image_info.disks, "boot", null) != null ? true : false
  zfs_boot = local.is_zfs ? local.image_info.disks.boot : null

  label_suffix      = local.is_zfs ? "-ZFS" : ""
  image_label       = "${local.image_info.label}${local.label_suffix}"
  image_name        = "NixOS-${local.image_label}-${local.image_system}"
  image_description = "NixOS ${local.image_label} ${local.image_system}"

  arch_mapping = {
    "aarch64-linux" = "arm64"
    "x86_64-linux"  = "x86_64"
  }

  image_logical_bytes = (
    local.is_zfs ? local.zfs_boot.logical_bytes : local.root_disk.logical_bytes
  )
  image_logical_gigabytes = floor(
    (local.image_logical_bytes - 1) / 1024 / 1024 / 1024 + 1
  )
  zfs_boot_file = local.is_zfs ? { boot = local.zfs_boot.file } : {}
  image_files = merge(
    { root = local.root_disk.file }
    , local.zfs_boot_file
  )
}

resource "aws_s3_object" "image_file" {
  for_each = local.image_files
  bucket   = var.bucket
  key      = trimprefix(each.value, "/")
  source   = each.value
}

resource "aws_ebs_snapshot_import" "image_import" {
  for_each = aws_s3_object.image_file
  disk_container {
    description = "nixos-image-${local.image_label}-${local.image_system}"
    format      = "VHD"
    user_bucket {
      s3_bucket = each.value.bucket
      s3_key    = each.value.key
    }
  }

  role_name = var.service_role_name
}

locals {
  # When ZFS is used the boot device is "boot"
  boot_snapshot = (local.is_zfs ?
    aws_ebs_snapshot_import.image_import["boot"] :
    aws_ebs_snapshot_import.image_import["root"]
  )
}

resource "aws_ami" "nixos_ami" {
  name                = local.image_name
  virtualization_type = "hvm"
  root_device_name    = "/dev/xvda"
  architecture        = local.arch_mapping[local.image_system]
  boot_mode           = local.image_info.boot_mode
  ena_support         = true
  sriov_net_support   = "simple"

  ebs_block_device {
    device_name           = "/dev/xvda"
    snapshot_id           = local.boot_snapshot.id
    volume_size           = local.boot_snapshot.volume_size
    delete_on_termination = true
    volume_type           = "gp3"
  }

  dynamic "ebs_block_device" {
    for_each = local.is_zfs ? { zfs = true } : {}

    content {
      device_name           = "/dev/xvdb"
      snapshot_id           = aws_ebs_snapshot_import.image_import["root"].id
      volume_size           = aws_ebs_snapshot_import.image_import["root"].id
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }

  lifecycle {
    ignore_changes = [deprecation_time]
  }
}

resource "aws_ami_launch_permission" "public_access" {
  image_id = aws_ami.nixos_ami.id
  group    = "all"
}

output "ami" {
  value = {
    region = var.aws_region
    arch   = local.image_system
    id     = aws_ami.nixos_ami.id
  }
}
