# Terraform Project for Setting Up a Secure Environment on Azure

## Project Description

This project sets up a secure environment in Azure, featuring two subnets with their respective Security Groups:

- **Subnet 1**: Hosts the Client Server.
- **Subnet 2**: Hosts the Database.

Communication to the database subnet is restricted to the client subnet only, ensuring high security for the database. Each subnet hosts a Virtual Machine (VM) for necessary resources.

## Prerequisites

- **Terraform**: Version `v1.9.7`
- **Providers**:
  - `hashicorp/azurerm` version `v4.8.0`
  - `hashicorp/http` version `v3.4.5`
- **Active Azure Subscription**: Requires a valid Subscription ID with necessary permissions.

## Installation and Execution

### 1. Clone the Project

Clone the project repository to your local machine:

```bash
git clone https://github.com/noga-x-space/eshop-terraform-infrastructure.git
cd https://github.com/noga-x-space/eshop-terraform-infrastructure.git
```

### 2. Configure Variables

Create a `terraform.tfvars` file in the project directory and set the following variables:

```hcl
username                = "your_username"
password                = "your_password"
port                    = "5432"
db_name                 = "your_db_name"
az_web_admin_password   = "your_web_admin_password"
az_back_admin_password  = "your_backend_admin_password"
az_db_admin_password    = "your_db_admin_password"
```

**Notes**:

- `username`: System or database username.
- `password`: User password.
- `port`: Database listening port (default: `5432`).
- `db_name`: Database name.
- `az_web_admin_password`: Web machine admin password.
- `az_back_admin_password`: Backend machine admin password.
- `az_db_admin_password`: Database admin password.

> **Important**: Keep passwords and sensitive data secure. Avoid sharing publicly.

### 3. Initialize the Project

Initialize Terraform to download required providers:

```bash
terraform init
```

### 3.0 config for Windows

If Windows user, run the next command:

```bash
.\dos2unix.exe *
```

### 4. Review the Plan

Review the resource creation plan:

```bash
terraform plan
```

### 5. Apply the Plan

Create resources by running:

```bash
terraform apply -var-file="variables.tfvars"  
```

Confirm the action when prompted.

## Variables

The project utilizes variables defined in the `variables.tf` file:

- `username` (String): System username.
- `password` (String, Sensitive): User password.
- `host` (String): Hostname (default: empty).
- `port` (String): Database port (default: `postgres`).
- `db_name` (String): Database name.
- `postgres_version` (String): PostgreSQL version (default: `16`).
- `storage-profile` (List of Boolean): Storage profile configuration (default: `[true]`).
- `az_web_admin_password` (String, Sensitive): Web machine admin password.
- `az_db_admin_password` (String, Sensitive): Database admin password.
- `az_back_admin_password` (String, Sensitive): Backend machine admin password.

**Notes**:

- Sensitive variables will not appear in output or state files.
- Ensure sensitive variables are only defined in `terraform.tfvars`, not in source code.

## Resources Created

This project provisions the following Azure resources:

- **Virtual Network (VNet)**: Includes two subnets.
- **Subnets**:
  - **Subnet 1**: Hosts the Client Server.
  - **Subnet 2**: Hosts the Database.
- **Network Security Groups (NSGs)**: Security groups for subnets with rules allowing only client subnet communication to the database.
- **Virtual Machines (VMs)**:
  - Web/Client VM in Subnet 1.
  - Database VM in Subnet 2.
- **PostgreSQL Database**: Installed on the VM in Subnet 2.


## Important Notes

- **Security**: Keep sensitive information secure. Do not share files like `terraform.tfvars` publicly.
- **Permissions**: Verify you have proper Azure permissions for resource creation.
- **Costs**: Azure resources may incur charges. Delete unnecessary resources to avoid costs.

## Cleaning Up Resources

To remove all created resources, run:

```bash
terraform destroy
```

Confirm the action when prompted.


