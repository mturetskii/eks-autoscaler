# Terraform EKS Deployment

## Overview

This repository contains sample Terraform configurations for deploying an Amazon EKS cluster and associated resources. Key components include:

- **EKS Cluster**: A Kubernetes cluster configured with OIDC for secure integration with AWS services.
- **Cluster Autoscaler**: Automatically adjusts the number of nodes in your cluster based on resource usage. Deployed using **IAM Roles for Service Accounts (IRSA)** for fine-grained permissions.
- **Metrics Server**: Provides resource metrics (CPU, memory) required for Horizontal Pod Autoscaler (HPA).
- **Horizontal Pod Autoscaler (HPA)**: Automatically scales pods based on CPU utilization.
- **VPC Configuration**: A customizable Virtual Private Cloud (VPC) is created to host the EKS cluster, including both public and private subnets.
- **Example Workloads**: Sample deployments and services to test autoscaling functionality.

## Setup Instructions

1. Initialize Terraform:
```bash
   terraform init
```

2. Apply the configuration:
```bash
   terraform apply -var="aws_profile=your-profile" -var="aws_region=your-region" -var="cluster_name=your-cluster-name"
```

## Notes

- Ensure you have the AWS CLI configured on your machine with the required credentials.
- Use appropriate IAM permissions for Terraform to manage AWS resources.
- Customize additional variables and modules as needed for your use case.
