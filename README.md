# AWS Mini-Infra Report
Video Tutorials and Troubleshooting [https://www.youtube.com/playlist?list=PLxKrRFAs8UQJ9xG6nh9WIEOntrBTMoiTc]


#### Objective 

This project demonstrates the automated provisioning of a highly available network infrastructure in Amazon Web Services (AWS) using Terraform, managed via HashiCorp Cloud Platform (HCP) Terraform. The goal was to create a multi-AZ (Availability Zone) Virtual Private Cloud (VPC) with public and private subnets, outbound gateways, and security resources. The declarative source code, written in HCL (HashiCorp Configuration Language), is publicly accessible on GitHub at code-klaudia-prog. 

#### Methodology 

###### Provisioned AWS Services 

- VPC (with CIDR 10.0.0.0/16). 
- Public and Private Subnets in distinct AZs. 
- Internet Gateway (IGW). 
- NAT Gateways (for high availability). 
- Test EC2 instance with a Security Group. 


###### Provisioning Workflow 

The deployment methodology followed the Infrastructure as Code (IaC) practice, integrating version control with remote state management: 

- Development of the Terraform code locally. 
- Pushing the code to the GitHub repository. 
- Connection between GitHub and HCP Terraform. The repository used was code-klaudia-prog/terraform_repo. 
- The Workspace in HCP Terraform (with the necessary environment variables for AWS, such as AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY) automates the deployment and applies the infrastructure directly in AWS. 
- Network Infrastructure Details (VPC and Subnets) The VPC design ensures resource redundancy and isolation, distributing components across two Availability Zones (AZs) in the North Virginia region (us-east-1). 

 
###### Addressing Scheme (CIDR)  

VPC 
vpc-avancada-tf 10.0.0.0/16 vpc-0cf5a5c7a5030068f 


Resource           Availability Zone                Resource Name           CIDR Block (IPv4)            Subnet ID 

Public Subnet 1      (AZ 1a)            vpc-avancada-tf--public-us-east-1a     10.0.1.0/24         subnet-07f0aaa3d19313980 

Private Subnet 1     (AZ 1a)            vpc-avancada-tf-private-us-east-1      10.0.2.0/24         subnet-08e0f231c94d181b7 

Public Subnet 2      (AZ 1b)            vpc-avancada-tf--public-us-east-1      10.0.3.0/24         subnet-0e8280d1b860487a8 

Private Subnet 2     (AZ 1b)            vpc-avancada-tf-private-us-east-1b     10.0.4.0/24         subnet-0342db2e334a2887 

###### Infrastructure Diagram  

###### Connectivity Gateways Outbound and Inbound traffic to the Internet is managed through the following Gateways. The use of multiple NAT Gateways (with single_nat_gateway = false) ensures Fault Tolerance and High Availability, with one NAT Gateway provisioned per Availability Zone. 

 
###### Route Table Configuration Routing is configured differently for the public and private subnets. 

Connectivity Tests and Deployment Challenges To test routing and confirm that outbound traffic from the private subnets is routed through the NAT Gateway, a test EC2 instance was implemented in one of the private subnets (10.0.2.0/24 or 10.0.4.0/24). 

###### Bastion Host and Private Instance Connectivity Direct communication with the internet is not possible from resources in the private subnet. Thus, to access the private EC2 instance, a Bastion Host (or Jump Server) deployed in a public subnet is used. 

###### Test Flow (SSH): 

- Initial SSH connection to the Bastion Host (in the public subnet). 
- From the Bastion Host terminal, an SSH command is run to the private IP of the EC2 instance. 
- The Security Group of the private instance allows SSH access (Port 22) only from resources within the VPC CIDR (10.0.0.0/16). 

###### Outbound Internet Test (NAT Gateway) Once connected to the private EC2 instance, outbound access to the Internet (which validates the NAT Gateway) is tested using a ping command: ping -c 3 amazon.com The Security Group of the private instance must include an Outbound Rule that allows all outbound traffic (from_port =0, to_port =0, protocol =−1, cidr_blocks =["0.0.0.0/0"]). 

Deployment Results in AWS 5.1 Automatic VPC Creation in AWS (Refers to Figure 2, which shows the VPC subnets in the AWS console) 

###### Creation of Subnets in AWS in 2 Availability Zones in the North Virginia region (Refers to Figure 3, which shows the subnets in the AWS console) 

###### Confirmation of Internet Gateway Deployment (Refers to Figure 5, which shows the Internet Gateway in the AWS console) 

###### Confirmation of NAT Gateway Deployment (Refers to Figure 6, which shows the two NAT Gateways in the AWS console: vpc-avancada-tf-us-east-1a and vpc-avancada-tf-us-east-1b) 

###### Security Group deployed in AWS (Refers to Figure 7, showing one Security Group in the AWS console) 

###### Errors and Troubleshooting 6.1 Common Deployment Errors The deployment process revealed two critical errors that validate IaC best practices: 

Invalid AMI :

Terraform successfully completed the plan, but the apply failed because the specified AMI ID (ami-09def150731bdbcc2) did not exist in the region where the deployment was being performed. 
The error messages confirmed: api error InvalidAMIID.NotFound: The image id 'ami-09def150731bdbcc2' does not exist. 
The fix involved correcting the AMI ID to the correct one (ami-052064a798f08f0d3). 

Note: Due to time constraints, some variables, such as the ami_id, remained hardcoded. 

Security Group and Subnet Association 
The EC2 instance was attempted to be provisioned in a subnet, but the Security Group referenced in the declaration was associated with a different VPC (or different network). 
The error message was: api error InvalidParameter: Security group sg-00e3718d8e7e51390 and subnet subnet-0c579cdd17a50701c belong to different networks. 
The fix involved changes to the source code to explicitly set the vpc_id for the Security Group using module.vpc.vpc_id. 

Corrective Deployment (Refers to Figures 13, showing the successful Terraform run after corrections, with resources added, changed, and destroyed.) 

###### Conclusion
###### Final Considerations 

The project demonstrated the successful provisioning of a complex, multi-AZ AWS infrastructure, using the Terraform + HCP + GitHub pipeline. The provisioned environment (VPC with IGW and NAT Gateways) was validated with connectivity tests that confirmed the isolation and outbound Internet capability of the private resources. The resolution of AMI and Security Group association errors highlights the importance of resource verification and state consistency in the IaC process. 
 

### 1st Deployment Services

#### AWS Route Table
![AWS Route Table](https://github.com/code-klaudia-prog/terraform_repo/blob/main/Screenshots/AWS%20Route%20Table.png)
### 


#### AWS Bastion Host
![AWS Bastion Host](https://github.com/code-klaudia-prog/terraform_repo/blob/main/Screenshots/Acesso%20ao%20Bastiao.png)
### 


#### AWS Bastion Host deployed on public subnet
![AWS Bastion Host deployed on public subnet](https://github.com/code-klaudia-prog/terraform_repo/blob/main/Screenshots/Bastion%20Host%20na%20Subnet%20Publica.png)
### 


#### AWS Private EC2
![AWS Private EC2](https://github.com/code-klaudia-prog/terraform_repo/blob/main/Screenshots/EC2%20na%20Subrede%20Privada.png)
### 


#### AWS private EC2 and Bastion hos
![AWS private EC2 and Bastion host](https://github.com/code-klaudia-prog/terraform_repo/blob/main/Screenshots/Instancia%20EC2%20Privada%20e%20Bastion%20Host.png)
### 


#### AWS Internet Gateway
![AWS Internet Gateway](https://github.com/code-klaudia-prog/terraform_repo/blob/main/Screenshots/Internet%20Gateway.png)
### 


#### AWS NAT Gateway
![AWS NAT Gateway](https://github.com/code-klaudia-prog/terraform_repo/blob/main/Screenshots/NAT%20Gateways.png)
### 


#### AWS Route Table
![AWS Route Table](https://github.com/code-klaudia-prog/terraform_repo/blob/main/Screenshots/AWS%20Route%20Table.png)
### 


#### AWS VPC
![AWS VPC](https://github.com/code-klaudia-prog/terraform_repo/blob/main/Screenshots/VPC.png)

# Disclaimer

- In order to simplify the video, we have been using the correct git workflow
- Always recall that in a corporative scenario, if you commit to the main branch, youre fired
- Developent iterations are done with Feature-branches
- Feature branches are usually deleted after erged with the dev branch
- Although this is not mandatory, the good practices recommend that the commit message is not
  longer than 72 characters

# Busted
#### I've been using hardcoded variables all along because I was slopy and in a hurry
![Busted](https://github.com/code-klaudia-prog/terraform_repo/blob/main/Screenshots/busted.png)

