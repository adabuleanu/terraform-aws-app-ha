resource "aws_s3_bucket" "web_bucket" {
  bucket = "my-unique-web-app"

  tags = merge(local.tags, tomap({ Name = "Web App Bucket" }))
}

resource "aws_s3_object" "web_app" {
  for_each = var.web_apps

  bucket = aws_s3_bucket.web_bucket.id
  key    = format("app/%s", basename(each.value["path"]))
  source = each.value["path"]

  tags = var.tags
}
