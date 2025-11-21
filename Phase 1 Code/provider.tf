provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = var.project_name
      Owner   = var.owner_tag
    }
  }
}

# -------------------------------------------------
# Secondary AWS provider specifically for WAFv2
# -------------------------------------------------
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
