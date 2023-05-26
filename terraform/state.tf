terraform {
  backend "s3" {
    bucket       = "STATE_BUCKET_NAME"
    key          = "STATE_BUCKET_KEY"
    region       = "AWS_REGION"
    session_name = "terraform"
    profile      = "AWS_PROFILE"
  }
}
