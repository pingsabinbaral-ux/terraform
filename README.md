# Terraform Learning Projects (AWS)

A collection of small, hands-on Terraform examples that provision AWS resources. Each folder is a self-contained project that demonstrates one core Terraform concept, progressing from a single EC2 instance to variables, dependencies, conditionals, modules, and workspaces.

All examples target the **`us-east-2` (Ohio)** region and use the **`t3.micro`** instance type by default.

## Table of Contents

- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Walkthroughs](#project-walkthroughs)
  - [1. First EC2 Instance](#1-first-ec2-instance)
  - [2. Terraform Variables](#2-terraform-variables)
  - [3. Resource Dependencies](#3-resource-dependencies)
  - [4. Conditional Expressions & Locals](#4-conditional-expressions--locals)
  - [5. Modules](#5-modules)
  - [6. Workspaces](#6-workspaces)
- [Cleaning Up](#cleaning-up)
- [Notes](#notes)
- [License](#license)

## Repository Structure

```
terraform/
├── First EC2_Instance/            # Basic provider + single EC2 resource
├── Terraform_Variables/           # Input variables and outputs
├── Resource Dependencies/         # Explicit dependencies with depends_on (S3 + EC2)
├── Conditional Expressions & Locals/  # Ternary expressions and local values
├── Modules/                       # Reusable EC2 module
│   └── ec2-module/
├── Workspaces/                    # Multiple environments from one codebase
└── LICENSE
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed (`terraform -version` to verify)
- An AWS account
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured with credentials:

  ```bash
  aws configure
  ```

- IAM permissions to create EC2 instances (and S3 buckets for the *Resource Dependencies* example)

> **Cost warning:** these examples create real AWS resources. A `t3.micro` is inexpensive but is not always covered by the free tier, so run `terraform destroy` when you're done.

## Quick Start

The folder names contain spaces, so wrap them in quotes when using `cd`.

```bash
# Clone the repository
git clone https://github.com/pingsabinbaral-ux/terraform.git
cd terraform

# Pick a project
cd "Terraform_Variables"

# Standard Terraform workflow
terraform init       # download the AWS provider
terraform plan       # preview the changes
terraform apply      # create the resources
terraform destroy    # tear everything down
```

## Project Walkthroughs

### 1. First EC2 Instance

**Folder:** `First EC2_Instance/`

The simplest possible configuration: configure the AWS provider and launch one EC2 instance.

- Resource: `aws_instance.my_ec2`
- Region, instance type, and tag are hard-coded

> **Before you apply:** `main.tf` uses the placeholder `ami-xxxxxxxxxxxxxx`. Replace it with a valid AMI ID for `us-east-2` (find one in the EC2 console under *Launch instance*), or look one up with the AWS CLI. Later examples avoid this by looking up the AMI automatically.

### 2. Terraform Variables

**Folder:** `Terraform_Variables/`

Introduces input variables, a data source, and outputs.

- **Data source:** `aws_ami` finds the latest Amazon Linux 2 AMI automatically
- **Variables:** `aws_region`, `instance_type`, `instance_name`
- **Output:** `instance_public_ip`

Override defaults from the command line:

```bash
terraform apply -var="instance_type=t3.small" -var="instance_name=my-server"
```

### 3. Resource Dependencies

**Folder:** `Resource Dependencies/`

Shows how to control creation order with `depends_on`. The EC2 instance is created only after the S3 bucket exists.

- Resources: `aws_s3_bucket.my_bucket`, `aws_instance.my_ec2`
- Variables: `aws_region`, `instance_type`, `instance_name`, `bucket_name`
- **Output:** `bucket_name`

> S3 bucket names are **globally unique**. If the default `unique-bucket-terraform` is already taken, pass your own:
>
> ```bash
> terraform apply -var="bucket_name=your-own-unique-bucket-name"
> ```

### 4. Conditional Expressions & Locals

**Folder:** `Conditional Expressions & Locals/`

Demonstrates a ternary expression stored in a `locals` block. The instance's `Name` tag changes based on the instance type:

```hcl
locals {
  name_tag = var.instance_type == "t3.micro" ? "Micro Instance" : "Standard Instance"
}
```

- **Output:** `instance_name_tag`

Try it with different instance types and compare the result:

```bash
terraform apply                                  # Name tag: "Micro Instance"
terraform apply -var="instance_type=t3.small"    # Name tag: "Standard Instance"
```

### 5. Modules

**Folder:** `Modules/`

Packages EC2 creation into a reusable module and calls it from the root configuration.

```
Modules/
├── main.tf            # Root config: provider, AMI lookup, module call
├── variables.tf
└── ec2-module/        # Reusable module
    ├── main.tf        # aws_instance resource
    ├── variables.tf   # ami, instance_type, name
    └── output.tf      # instance_id
```

The root module calls the child module like this:

```hcl
module "ec2_instance" {
  source        = "./ec2-module"
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  name          = "MyModuleEC2"
}
```

Run Terraform from the `Modules/` folder (not from inside `ec2-module/`).

### 6. Workspaces

**Folder:** `Workspaces/`

Uses Terraform workspaces to manage multiple environments (for example `dev`, `staging`, `prod`) from a single configuration. The workspace name is injected into the resource tags:

```hcl
tags = {
  Name        = "EC2-${terraform.workspace}"
  Environment = terraform.workspace
}
```

- **Output:** `workspace_name`

```bash
terraform workspace list            # show workspaces (starts on "default")
terraform workspace new dev         # create and switch to "dev"
terraform apply                     # creates "EC2-dev"

terraform workspace new prod        # create and switch to "prod"
terraform apply                     # creates "EC2-prod"

terraform workspace select dev      # switch back
```

Each workspace keeps its own separate state, so `dev` and `prod` instances don't interfere with each other.

## Cleaning Up

To avoid ongoing charges, destroy the resources in every project you applied:

```bash
terraform destroy
```

For the **Workspaces** example, destroy each workspace separately:

```bash
terraform workspace select dev
terraform destroy

terraform workspace select prod
terraform destroy
```

## Notes

- Terraform state files (`terraform.tfstate`, `terraform.tfstate.backup`) and the `.terraform/` directory are generated locally and can contain sensitive data. Do **not** commit them. Add a `.gitignore` such as:

  ```gitignore
  .terraform/
  *.tfstate
  *.tfstate.*
  *.tfvars
  crash.log
  ```

- The examples look up the AMI with the filter `amzn2-ami-hvm-*-x86_64-gp2` (Amazon Linux 2, x86_64). If you change the instance type to an ARM-based one (such as `t4g.*`), you'll need an ARM64 AMI instead.

## License

This project is released under the [CC0 1.0 Universal](LICENSE) license. You are free to copy, modify, and use it for any purpose.
