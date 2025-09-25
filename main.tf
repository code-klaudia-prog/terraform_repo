provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_s3_bucket_object" "my_index" {
  bucket       = "${module.my_site.bucket_name}"
  key          = "index.html"
  content      = "<pre>Hello World!</pre>"
  content_type = "text/html; charset=utf-8"
}
