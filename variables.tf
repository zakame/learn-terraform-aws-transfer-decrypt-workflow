variable "region" {
  default     = "us-east-2"
  description = "AWS region"
}

variable "transfer_user_key" {
  description = "Public SSH key for Transfer user"
}

variable "transfer_pgp_secret" {
  default = {
    PGPPrivateKey = "foo"
    PGPPassphrase = "bar"
  }
  description = "PGP Private key and passphrase for decrypt workflow"

  type      = map(string)
  sensitive = true
}
  