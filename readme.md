# Terraform AWS Infrastructure Automation

This project uses Terraform to automate the deployment of AWS infrastructure. Follow the instructions below to set up and deploy the environment using this repository.

## Prerequisites

Ensure you have the following installed:

- [Terraform](https://www.terraform.io/downloads)
- AWS CLI
- An AWS account with programmatic access (access key and secret key and session token)

## Getting Started

1. **Clone the Repository**

   ```bash
   git clone https://github.com/RayenRk/infrastructure.git
   cd infrastructure
   ```

2. **Configure AWS Credentials**

   Remove the .example extension from the terraform.tfvars file and add your own credentials.

3. **Initialize Terraform**

   Run the following command to initialize Terraform. This will download the necessary providers and set up the working directory.

   ```bash
   terraform init
   ```

4. **Review the Infrastructure Plan**

   To see what resources will be created, run:

   ```bash
   terraform plan
   ```

   This command helps you verify the resources and any changes before deployment.

5. **Apply the Configuration**

   Apply the Terraform configuration to provision the AWS resources:

   ```bash
   terraform apply
   ```

   Type `yes` when prompted to confirm the deployment.

6. **Verify Your Deployment**

   After Terraform completes, you can check the AWS Management Console to verify that the resources were created as expected.

7. **Destroy the Infrastructure (if needed)**

   When you’re done and want to tear down the infrastructure, run:

   ```bash
   terraform destroy
   ```

   Type `yes` to confirm the destruction of resources.

## Project Structure

- **`main.tf`** - Contains the primary Terraform configuration for AWS resources.
- **`terraform.tfvars`** - Defines any configurable variables.

## Best Practices

- Use a `.tfvars` file to store sensitive information (e.g., `terraform.tfvars`).
- For production environments, consider using a remote backend (such as an S3 bucket) for storing the Terraform state file.

## Notes

- Ensure your AWS user/role has the appropriate permissions to create and manage the resources defined in `main.tf`.

## License

This project is licensed under the MIT License.