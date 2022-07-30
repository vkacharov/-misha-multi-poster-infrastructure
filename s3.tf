resource "aws_s3_bucket" "multi_poster_website_bucket" {
    bucket  = "misha-multi-poster-website-origin"
    acl     = "private"

    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_s3_bucket_public_access_block" "multi_poster_website_bucket_public_block" {
    bucket                  = aws_s3_bucket.multi_poster_website_bucket.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "multi_poster_website_bucket_policy" {
  bucket = aws_s3_bucket.multi_poster_website_bucket.id
  policy = data.aws_iam_policy_document.multi_poster_website_bucket_policy_document.json
}

data "aws_iam_policy_document" "multi_poster_website_bucket_policy_document" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.multi_poster_website_origin_access_identity.iam_arn]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.multi_poster_website_bucket.arn}/*",
    ]
  }
}