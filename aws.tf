terraform {
  #required_version = ">= 0.12"
  #required_version = ">= 0.12"
  #required_version = ">= 0.12"
  #required_version = ">= 0.12"
  backend "s3" {
    bucket = "protomolecula"
    key    = "gorillaterraform.tfstate"
    region = "us-east-1"
  }
}
