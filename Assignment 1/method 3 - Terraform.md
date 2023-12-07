## Step-by-step Instructions (terraform)
1. Download this repository to your local workstation
2. Install terraform
3. Begin your lab, login via web browser to aws console.
4. Follow the README.md instructions at the root of this repo, describing `Generating your Access Key`. You will need these credentials
5. Launch a BASH or PowerShell terminal. and set 3x variables:
```
$env:AWS_ACCESS_KEY_ID="<KEY-GOES-HERE>"
$env:AWS_SECRET_ACCESS_KEY="<SECRET-VALUE-GOES-HERE>"
$env:AWS_REGION="us-east-1"
```

6. Initialise Terraform using `terraform init`
After a series of downloads, a green comment should indicate the plan can proceed.

7. Plan for the buildout, using `terraform plan`. The following output should be visible:
> Plan: 19 to add, 0 to change, 0 to destroy.

8. Apply all changes using `terraform apply -auto-approve`. The following output should be visible:
> Apply complete! Resources: 19 added, 0 changed, 0 destroyed.