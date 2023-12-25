# Create EKS Cluster (This is done using the EKS cluster module)

- In this example we are going to use the eks module in order to create an EKS cluster.
- we are going to use managed node groups which will creates our autoscaling groups with the needed Tags
- Each autoscaling group must has those 2 tags for the Autoscaler to work properly:
  - `k8s.io/cluster-autoscaler/<cluster name>	owned	Yes`
  - `k8s.io/cluster-autoscaler/enabled	true	Yes`

# Create the OIDC Provider (This is done using the EKS cluster module)

- Copy the OIDC link from the EKS cluser configuration: `https://oidc.eks.REGION.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXX`
- Go to IAM, Identity Providers, Add Provider, OIDC, for the value paste `sts.amazonaws.com`

# Create IAM Policy for auto scaler

- Go to Poicies, Create Policy with those permissions

```
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "autoscaling:DescribeAutoScalingGroups",
              "autoscaling:DescribeAutoScalingInstances",
              "autoscaling:DescribeLaunchConfigurations",
              "autoscaling:DescribeTags",
              "autoscaling:SetDesiredCapacity",
              "autoscaling:TerminateInstanceInAutoScalingGroup",
              "ec2:DescribeLaunchTemplateVersions"
          ],
          "Resource": "*",
          "Effect": "Allow"
      }
  ]
}
```

You can name the policy `AmazonEKSClusterAutoscalerPolicy`

# Create IAM Role with the Policy created

- Go to Roles, Create Role, `Web Identity`, select the OIDC Provider that we created for our cluster, and select the audience
- Select the Policy that we created `AmazonEKSClusterAutoscalerPolicy`
- Name this role `AmazonEKSClusterAutoscalerRole`

# Change the Role

- Go to the Role `AmazonEKSClusterAutoscalerRole` go to `Trust relationships`, click on `Edit trust policy` and update it
- The update should be like that:
  - From this: `"StringEquals": {
	"oidc.eks.us-east-2.amazonaws.com/id/XXXXXXXX:aud": "sts.amazonaws.com"
}`
  - To this: `"StringEquals": {
	"oidc.eks.us-east-2.amazonaws.com/id/XXXXXXXX:sub  ": "system:serviceaccount:kube-system:cluster-autoscaler"
}`

# Deploy the Auto scaler to the EKS Cluster

- Apply the manifest called 00-cluster-autoscaler.yaml

https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md

# Automating the stuff

## Create EKS Cluster - (This is done using the EKS cluster module)

## Create the OIDC Provider - (This is done using the EKS cluster module)

## Create IAM Policy for auto scaler

- Go to Poicies, Create Policy with those permissions

```
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "autoscaling:DescribeAutoScalingGroups",
              "autoscaling:DescribeAutoScalingInstances",
              "autoscaling:DescribeLaunchConfigurations",
              "autoscaling:DescribeTags",
              "autoscaling:SetDesiredCapacity",
              "autoscaling:TerminateInstanceInAutoScalingGroup",
              "ec2:DescribeLaunchTemplateVersions"
          ],
          "Resource": "*",
          "Effect": "Allow"
      }
  ]
}
```

You can name the policy `EKSClusterAutoscalerPolicy`

## Create IAM Role with the Policy created

- Go to Roles, Create Role, `Web Identity`, select the OIDC Provider that we created for our cluster, and select the audience
- Select the Policy that we created `AmazonEKSClusterAutoscalerPolicy`
- Name this role `AmazonEKSClusterAutoscalerRole`

## Change the Role

- Go to the Role `AmazonEKSClusterAutoscalerRole` go to `Trust relationships`, click on `Edit trust policy` and update it
- The update should be like that:
  - From this: `"StringEquals": {
	"oidc.eks.us-east-2.amazonaws.com/id/XXXXXXXX:aud": "sts.amazonaws.com"
}`
  - To this: `"StringEquals": {
	"oidc.eks.us-east-2.amazonaws.com/id/XXXXXXXX:sub  ": "system:serviceaccount:kube-system:cluster-autoscaler"
}`

## Deploy the Auto scaler to the EKS Cluster
 