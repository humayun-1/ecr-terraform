# Terraform Deployment Instructions

To deploy the infrastructure, follow these steps:

1. Initialize the Terraform working directory by running:

**terraform init**

2. Apply the Terraform configuration using the provided variables file by running:

**terraform apply -var-file="tfvars/main.tfvars" --auto-approve**

3. Command to login docker

**aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 140023385240.dkr.ecr.us-east-1.amazonaws.com**

This will deploy the infrastructure according to the configuration defined in the Terraform files.

4. Command to delete all resources

**aws ecr batch-delete-image --repository-name next-app --image-ids $(aws ecr list-images --repository-name next-app --query 'imageIds[*].imageDigest' --output json | jq -r '.[]' | paste -sd " " -) && aws autoscaling delete-auto-scaling-group --auto-scaling-group-name next-app-asg --force && terraform destroy -auto-approve**

This command sequence will delete all the resources created by Terraform, including the ECR repository, the auto-scaling group, and the associated instances. It ensures a clean removal of all infrastructure components to avoid any unnecessary costs or resource usage.