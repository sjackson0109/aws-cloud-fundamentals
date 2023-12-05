## Preface

Author: Simon Jackson (sjackson0109)

Date: 04/12/2023

## Objective
To design and construct an Amazon Virtual Private Cloud (VPC) architecture that includes an EC2 instance within a public subnet and a database instance within *two* private subnets.

## Expected Solution
- As a cloud architect, your objective is to assist James in developing an AWS VPC that hosts both an EC2 instance and a database instance.
- The EC2 instance, serving the web application, should be placed in a public subnet, while the DB instance should be secured in a private subnet
- You are expected to provide `step-by-step instructions`` for creating and configuring these AWS resources, ensuring system security, reliability, and accessibility.


## Questions
- What form of service layer are we consuming? IaaS, PaaS, SaaS etc?
 <br> `VPCs` and `EC2` instances both as *IaaS* services
 <br> `RDS` is a *SaaS* service
- Do we need custom ip routing?
 <br> Yes. Public Subnet will receive `0.0.0.0/0` propagated from the Internet Gateway appliance; whilst the two `Private` tagged subnets, will not require any custom routes configuring. Route Propagation will not affect the private routes.  
- What kind of Network Firewall functionality will be required? Assuming (without a company rep to discuss compliance requirements with) that the AWS Security Groups acting as a layer 5 firewall will be sufficient.
 <br> WEB = http/s
 <br> SSH from WAN IP Address
 <br> DB = mysql (tcp/3306), allow ICMP for testing


## Step-by-step Instructions (GUI)
1. Create a VPC
 <br> Login to the AWS Management Console
 <br> Search `VPC` and select VPC from the Services dropdown
 <br> Select `Create VPC`
 <br> Choose `VPC only`, label the VPC `myvpc`, select `IPv4 CIDR manual input` and enter `10.99.0.0/16`, Select  `no IPv6 CIDR block`, click Create VPC
 <br> (wait for 30-40 seconds for completion)
 <br> Select `myvpc` to view the creation status
 <br> 
 <br> Select `Route tables` on the left navigation panel
 <br> Edit the default route-table, and add a tag `Name="public"`, click save.
 <br> Create a new route-table, add a default Name `Private`, click save.
 <br> 
 <br> Select `Subnets` on the left navigation panel
 <br> Create the first subnet, label the subnet `public`, enter a CIDR  `10.99.0.0/24`, select zone `no preference`, click Create Subnet
 <br> Create the second subnet, label the subnet `private1`, enter the CIDR `10.99.1.0/24`, select zone `us-east-1d`, click Create Subnet
 <br> Create the third subnet, label the subnet `private2`, enter the CIDR `10.99.1.0/24`, select zone `us-east-1b`, click Create Subnet
 <br> 
 <br> Edit the private subnet(s) you just created
 <br> Navigate to Route Table, in the bottom navigation panel, select `Edit route table association` and select the `private` route table
 <br> 
2. Create an Elastic IP
 <br> Select `Elastic IP Addresses` on the left navigation panel
 <br> Select `Allocate Elastic IP address`, click Create
 <br> 
3. Create Security Groups
 <br> Select `Security Groups`, lower down on the left navigation panel
 <br> Select `Create security group`, label the group `public`, enter a description `sg for public endpoints`, choose the VPC from the dropdown (note the tag in brackets should read `myvpc`).
 <br> Create Ingress FW Rules
 <br> - SSH (tcp/22) from my home wan ip (52.6.187.152/32)
 <br> - HTTP (tcp/80) from ANY public ip (0.0.0.0/0)
 <br> - HTTPS (tcp/443) from ANY public ip (0.0.0.0/0)
 <br> Create Egress FW Rules
 <br> - DNS (udp/53) to ANY public ip (0.0.0.0/0)
 <br> - HTTP (tcp/80) to ANY public ip (0.0.0.0/0)
 <br> - HTTPS (tcp/443) to ANY public ip (0.0.0.0/0)
 <br> - MySQL (tcp/3306) to `private` subnet (10.99.1.0/24)
 <br> Click `Create security group`
 <br> Select `Create security group`, label the group `private`, enter a description `sg for private endpoints`, choose the VPC from the dropdown (note the tag in brackets should read `myvpc`).
 <br> Create Ingress FW Rules
 <br> - MySQL (tcp/3306)  from `public` subnet (10.99.0.0/24)
 <br> Click  `Create security group`
 <br> 
4. Create a SSH key private/public key pair using
 <br> - `ssh-keygen -t rsa -N "" -b 2048 -C "simon.jackson"`
 <br> - (may not be required) convert the private key using `openssl rsa -RSAPublicKey_in -in -in id_rsa -pubout -out id_rsa.pub.pem`
 <br> Save the `-----BEGIN OPENSSH PRIVATE KEY-----` file to .\aws.rsa.key
 <br> Save the `ssh-rsa xxxxxxx` file to .\aws.rsa.pub
 <br> 
5. Create the EC2 Instance
 <br> Search `EC2` and select EC2 from the Services dropdown 
 <br> Select `Launch Instance`, label the instance `myec2`, cloose `Amazon Linux 2023 AMI` image, ensure the instance type is `t2.micro`. Select `create new key pair`, upload PRIVATE PEM and click OK.  Save the downloaded PUBLIC PEM.  Improt and convert to Putty PPK format later for use with Putty).
 <br> Select the network dropdown, select `myvpc` from the list
 <br> Select the subnet dropdown, select `public` from the list
 <br> Choose `Existing security group` and expand the dropdown, my list didn't update immediately, select the refresh icon to the side of the dropdown, select `public`
 <br> Expand the EBS volume from `8`gb to `20`gb. Click `launch instance`
 <br> 
6. Create an Internet Gateway
 <br> Search `VPC` and select VPC from the Services dropdown
 <br> Select `Internet Gateway` from the left navigation panel
 <br> Click `Create internet gateway`, label it `myigw` and click ok
 <br> Select the new internet gateway, select Actions > Attach to vpc, choose `myvpc` and click `Attach`
 <br> 
7. Associate the Elastic IP with the EC2 instance
 <br> Navigate to `Elastic IPs` on the lower left navigation panel
 <br> Select the one IP address created earlier (18.211.73.73), and select Actions > Associate Elastic IP address, select the instance from the dropdown.
 <br> 
8. Create an RDS database instance
 <br> Search `RDS` and select RDS from the Services dropdown
 <br> Select the `Create database` button, choose `Standard create`, and select `MySQL`, choose `community edition`, with engine version `5.7.44`. Select the `free tier` template. Under Settings set db instance identifier to `rdsinstance`, admin username to `rds_user` and  password set to `fcWeWBWDFARc3Eqx7dswY2R7`. Under Instance configuration choose `db.t3.micro`. Under Connectivity `do not connect` an ec2 compute resource. Leave network-type as IPv4. Replace the VPC with `myvpc`, and `create new db subnet group`, with public access OFF, select the VPC secrurity group called `private`. Leave CA as default, and password authentication as default. Click `Create database`.
 <br> Note: in my first attempt, i had to circle back to create a second private subnet, as the DB subnet group requires subnets in at least 2x availability zones.



## Step-by-step Instructions (terraform)
1. Download this repository to your local workstation
2. Install terraform
3. Install AWS CLI
4. Begin your lab, login via web browser to aws console. Create IAM user access key, place data in a post-it/notepad
5. Authenticate AWS CLI for the first-time, using `aws configure` to check the authentication details work.
6. Launch a BASH or PowerShell terminal. and set 3x variables:
 <br> - $env:AWS_ACCESS_KEY_ID="<KEY-GOES-HERE>"
 <br> - $env:AWS_SECRET_ACCESS_KEY="<SECRET-VALUE-GOES-HERE>"
 <br> - $env:AWS_REGION="us-east-1"
 
7. Initialise Terraform using `terraform init`
8. Plan for the buildout, using `terraform plan`. The following output should be visible:
```Plan: 19 to add, 0 to change, 0 to destroy.```
9. Apply all changes using `terraform apply -auto-approve`. The following output should be visible:
```Apply complete! Resources: 19 added, 0 changed, 0 destroyed.```