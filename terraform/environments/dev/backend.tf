terraform {
  backend "s3" {
    bucket         = "petclinic-terraform-state-739013795435-v2"
    key            = "petclinic/dev/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "petclinic-terraform-locks"
    encrypt        = true
  }
}
