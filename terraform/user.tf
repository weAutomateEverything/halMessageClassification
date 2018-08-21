provider "aws" {
  profile = "cardpayments"
  region = "eu-west-1"
}


terraform {
  backend "s3" {
    bucket = "halmessageclassification"
    key    = "state"
    region = "eu-west-1"
    profile = "cardpayments"
  }
}