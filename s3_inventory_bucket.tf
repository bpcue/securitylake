# Optional S3 bucket for OU inventory

###############################################################################
# Optional S3 bucket provisioning for OU inventory snapshots
###############################################################################

resource "aws_s3_bucket" "ou_inventory" {
  provider = aws.security_lake
  count  = var.create_ou_inventory_bucket ? 1 : 0
  bucket = var.ou_inventory_bucket

  tags = merge(var.tags, {
    Purpose = "SecurityLakeTenantInventory"
  })
}

resource "aws_s3_bucket_versioning" "ou_inventory" {
  provider = aws.security_lake
  count  = var.create_ou_inventory_bucket ? 1 : 0
  bucket = aws_s3_bucket.ou_inventory[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ou_inventory" {
  provider = aws.security_lake
  count  = var.create_ou_inventory_bucket ? 1 : 0
  bucket = aws_s3_bucket.ou_inventory[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ou_inventory" {
  provider = aws.security_lake
  count  = var.create_ou_inventory_bucket ? 1 : 0
  bucket = aws_s3_bucket.ou_inventory[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
