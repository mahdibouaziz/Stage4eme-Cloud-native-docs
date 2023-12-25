# Manual steps

DOC: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html#thumbstep2

oidc.eks.us-east-2.amazonaws.com/id/CE3E1BC238F08F6A7257A668F59C5120

https://oidc.eks.us-east-2.amazonaws.com/id/CE3E1BC238F08F6A7257A668F59C5120/.well-known/openid-configuration

oidc.eks.us-east-2.amazonaws.com

openssl s_client -servername oidc.eks.us-east-2.amazonaws.com -showcerts -connect oidc.eks.us-east-2.amazonaws.com:443

openssl x509 -in certificate.crt -fingerprint -sha1 -noout

# Solution2 use the kubergrunt CLI

https://github.com/gruntwork-io/kubergrunt

Kubergrunt is a standalone go binary with a collection of commands to fill in the gaps between Terraform, Helm, and Kubectl.
