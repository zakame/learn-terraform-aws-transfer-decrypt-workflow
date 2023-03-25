# Learn Terraform - Manage AWS Transfer Family with PGP Decryption Workflow

This repository contains a simple Terraform configuration for provisioning an [AWS Transfer Family][aws] server with a [PGP decryption step][pgp] on completed uploads, using a PGP private key secret on [AWS Secrets Manager][sm].

[aws]: https://aws.amazon.com/aws-transfer-family/
[pgp]: https://aws.amazon.com/about-aws/whats-new/2022/12/aws-transfer-family-built-in-pgp-decryption-file-uploads/
[sm]: https://aws.amazon.com/secrets-manager/

### References

- [AWS Transfer Family managed workflows](https://docs.aws.amazon.com/transfer/latest/userguide/transfer-workflows.html)
- [IAM policies for workflows - example with decrypt step](https://docs.aws.amazon.com/transfer/latest/userguide/workflow-execution-role.html#example-workflow-role-copy-tag)
- [Decrypt step details](https://docs.aws.amazon.com/transfer/latest/userguide/nominal-steps-workflow.html#decrypt-step-details)
- [PGP key management through Secrets Manager](https://docs.aws.amazon.com/transfer/latest/userguide/key-management.html#pgp-key-management)
