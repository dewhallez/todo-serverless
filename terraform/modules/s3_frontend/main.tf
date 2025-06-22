# terraform/modules/s3/main.tf

# S3 Bucket for Static Website Hosting
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "${var.project_name}-frontend" # Unique bucket name based on project
  # acl    = "public-read" # ACL for public read access (deprecated, use bucket policy instead)

  tags = {
    Environment = "production"
    Project     = var.project_name
  }
}

# S3 Bucket Public Access Block
# This is crucial for S3 website hosting to work correctly
resource "aws_s3_bucket_public_access_block" "frontend_bucket_public_access_block" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket Policy to allow public read access to objects
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*" # Grant access to all objects in the bucket
      },
    ]
  })
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "frontend_bucket_website_configuration" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html" # Your main HTML file
  }

  error_document {
    key = "index.html" # Redirect all errors to index.html for SPA behavior
  }
}

output "website_endpoint" {
  description = "The S3 static website endpoint URL."
  value       = aws_s3_bucket_website_configuration.frontend_bucket_website_configuration.website_endpoint
}

output "bucket_name" {
  description = "The name of the S3 bucket for the frontend."
  value       = aws_s3_bucket.frontend_bucket.bucket
}

variable "project_name" {
  description = "The name of the project."
  type        = string
}
