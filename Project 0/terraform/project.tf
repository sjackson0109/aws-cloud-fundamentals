# Prepare terraform provider downloaded packages
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Initialise the providers
provider "aws" {
  # Hard coded credentials is a bad practice. USING EXPORT or $ENV: variables instead.
}

# Declare a single variable for your project
# Note: no need to be specific with data types
variable "project" {
  default = {}
}

# Create S3 Bucket(s)
resource "aws_s3_bucket" "s3" {
  for_each = var.project.storage.s3
  bucket   = each.value.bucket
  tags     = try(each.value.tags, var.project.tags)
}

# Secure the site with a CORS policy
resource "aws_s3_bucket_cors_configuration" "s3" {
  for_each = var.project.storage.s3
  bucket = aws_s3_bucket.s3[each.key].id
  dynamic "cors_rule" {
    for_each = try(each.cors_rules, {})
    content {
      allowed_headers = try(cors_rule.allowed_headers, ["*"])
      allowed_methods = try(cors_rule.allowed_methods, ["GET", "OPTIONS"])
      allowed_origins = try(cors_rule.allowed_origins, null)
      expose_headers  = try(cors_rule.expose_headers, null)
      max_age_seconds = try(cors_rule.max_age_seconds,null)
    }
  }
}

# Adjust the default values for Public Access
resource "aws_s3_bucket_public_access_block" "s3" {
  for_each = var.project.storage.s3
  bucket = aws_s3_bucket.s3[each.key].id
  block_public_acls       = try(each.public_access.block_public_acls, true)
  block_public_policy     = try(each.public_access.block_public_policy, true)
  ignore_public_acls      = try(each.public_access.ignore_public_acls, true)
  restrict_public_buckets = try(each.public_access.restrict_public_buckets, true)
}

resource "aws_s3_bucket_acl" "s3" {
  for_each = var.project.storage.s3
  bucket = aws_s3_bucket.s3[each.key].id
  acl    = try(each.value.acl,"private")
}

resource "aws_s3_bucket_versioning" "s3" {
  for_each = var.project.storage.s3
  bucket = aws_s3_bucket.s3[each.key].id
  versioning_configuration {
    status = try(each.value.versioning, "Disabled")
  }
}