How to View Terraform Files

Opening .tf Files

Terraform files (.tf) are plain text files that can be opened with any text editor:

Windows:

Notepad (builtin)
Notepad++ (recommended) https://notepadplusplus.org/
VS Code (best) https://code.visualstudio.com/

Mac:

TextEdit (builtin)
VS Code (recommended) https://code.visualstudio.com/

Linux:

nano or vim (terminal)
gedit (GUI)
VS Code (recommended)

Quick Start

1. Extract the downloaded file

   bash
   unzip terraformawsinfrastructure.zip

   OR

   tar xzf terraformawsinfrastructure.tar.gz

2. Open in VS Code (Recommended)

   bash
   cd terraformawsinfrastructure
   code .

3. Or use any text editor
   Rightclick on .tf file
   Choose "Open with..."
   Select your text editor

Project Structure

terraformawsinfrastructure/
├── README.md ← Start here
├── modules/ ← Reusable Terraform modules
│ ├── vpc/ ← VPC with subnets, NAT
│ │ ├── main.tf ← Main VPC configuration
│ │ ├── variables.tf ← Input variables
│ │ └── outputs.tf ← Output values
│ ├── eks/ ← EKS Kubernetes cluster
│ ├── rds/ ← PostgreSQL database
│ ├── s3/ ← S3 buckets
│ ├── iam/ ← IAM roles and policies
│ ├── monitoring/ ← CloudWatch monitoring
│ └── securitygroups/ ← Security group rules
├── environments/ ← Environment configurations
│ ├── dev/ ← Development environment
│ ├── staging/ ← Staging environment
│ └── prod/ ← Production environment
├── scripts/ ← Automation scripts
│ ├── setupbackend.sh ← Setup S3 backend
│ └── deploy.sh ← Deploy infrastructure
└── docs/ ← Documentation
├── ARCHITECTURE.md ← Architecture overview
└── TROUBLESHOOTING.md ← Common issues

Next Steps

1. Read the main [README.md](README.md)
2. Review [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
3. Configure your environment in `environments/dev/terraform.tfvars`
4. Deploy using `./scripts/deploy.sh dev plan`

Need Help?

Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
All files are plain text use any text editor
For best experience, use VS Code with Terraform extension
