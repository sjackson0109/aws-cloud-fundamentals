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

## Writeup(s)
Follow the `method x` links below there are further instructions on building each of the environments; click through to find out more:
- Method 1 - [`AWS Console`](./method%201%20-%20AWS%20Console.md)
- Method 2 - [`AWS CLI`](./method%202%20-%20AWS%20CLI.md)
- Method 3 - [`Terraform Code`](./method%203%20-%20Terraform.md)

There are of course many ways of achieving the same goal.
