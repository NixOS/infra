[
  .[]|
  { "provider": {
      "aws": {
        "region": . ,
        "alias": .
      }
    },
   "resource": {
     "aws_ami_copy": {
       "copy_\(.)": {
         "name": "${local.image_name}",
         "description": "${local.image_description}",
         "source_ami_id": "${aws_ami.nixos_ami.id}",
         "source_ami_region": "${var.aws_region}",
         "provider": "aws.\(.)",
         "lifecycle": { "ignore_changes": [ "deprecation_time" ] }
       }
     },
     "aws_ami_launch_permission": {
       "public_access_\(.)": {
         "image_id": "${aws_ami_copy.copy_\(.).id}",
         "group": "all",
         "provider": "aws.\(.)"
       }
     }
   },
   "output": {
     "ami_\(.)": {
       "value": {
         "id": "${aws_ami_copy.copy_\(.).id}",
         "arch": "${local.image_system}",
         "region": .
       }
     }
   }
  }
]
