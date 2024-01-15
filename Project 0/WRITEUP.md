## Preface

Author: Simon Jackson (sjackson0109)

Date: 30/11/2023

## Objective
Deploy a static website inside an S3 bucket using the AWS management console. Tools required: AWS Management Console

## Expected Solution
- Screenshots demonstrating the bucket, configuration/policies and external http/s access. Uploading file changes, demonstrate version-history etc.
- Configure index handling
- Configure error document handling

## Questions
- What form of service layer are we consuming? PaaS, SaaS etc?
 <br> `S3` is a *PaaS* service
- Do we need custom ip routing?
 <br> No. Not IP routing, but DNS binding could be achieved easily enough. Likely a CNAME record.
- Are we unblocking public access to the s3 bucket? Default position is `block public`, so assumed YES
- How can we limit HTTP/S traffic inbound? CORS policies can be applied to the bucket to limit the allowed headers, methods and cache age.
- Do we have a sample webpage. 

## Step-by-step Instructions (GUI)
1. Create S3 Bucket
 <br> Login to AWS Management Console, and search for S3.
 <br> Select S3 from the suggested results
 <br> Click `Create Bucket`
2. Create a folder structure on the bucket
 <br> Include the following folders:
   | Folder Name | 
   |-------------|
   | img |
   | logs |
   | err | 
3. Upload HTML files into the root of your bucket
4. Upload a `404.html` into the `err` folder
5. Enable HTTP access to your S3 Bucket
6. Ensure public access is disabled
7. Modify the access policy to include:
 <br> GetBucketObject permission to anonymous users
 <br> 301 redirect at the root for any filename that returns http404, to `./err/404.html` 
8. Upload image files into the `img` folder
9. Access your bucket directly on the native AWS S3 hosted web-access address

## Step-by-step Instructions (terraform)
1. Download this repository to your local workstation
2. Install terraform
3. Install AWS CLI
4. Begin your lab, login via web browser to aws console. Create IAM user access key, place data in a post-it/notepad
5. Authenticate AWS CLI for the first-time, using `aws configure` to check the authentication details work.
6. Launch a BASH or PowerShell terminal. and set 3x variables:
```
 $env:AWS_ACCESS_KEY_ID="<KEY-GOES-HERE>"
 $env:AWS_SECRET_ACCESS_KEY="<SECRET-VALUE-GOES-HERE>"
 $env:AWS_REGION="us-east-1"
```
7. Initialise Terraform using `terraform init`
8. Plan for the buildout, using `terraform plan`. The following output should be visible:
```
Plan: 19 to add, 0 to change, 0 to destroy.
```
9. Apply all changes using `terraform apply -auto-approve`. The following output should be visible:
```
Apply complete! Resources: 19 added, 0 changed, 0 destroyed.
```