###
###
### Script to be executed locally. Uses cloudyR facilities to set up an Amazon S3 bucket, 
###	transfer files to/from a bucket, delete files, start an Amazon EC2 instance,
### access RStudio Server, and stop/terminate an instance.
###
### B.M. Brost (20170823)
###
###

# See https://github.com/cloudyr for additional information about cloudyR packages

rm(list=ls())


###
### Install and load cloudyR packages
###

install.packages(c("aws.s3","aws.sns"))
install.packages(c("aws.ec2","aws.ses","aws.ec2metadata"),
	 repos=c(getOption("repos"), "http://cloudyr.github.io/drat"))

library(aws.s3)  # AWS Simple Storage Service
library(aws.ec2)  # AWS Elastic Compute Cloud
library(aws.ses)  # AWS Simple Email Services
# library(aws.ec2metadata)  # AWS instance metadata
library(aws.sns)  # AWS Simple Notification Service


###
### AWS credentials
###

# AWS key file downloaded from IAM Console
aws.key <- read.csv("~/Documents/projects/AWS_access_key.csv",stringsAsFactors=FALSE)  

# Add AWS credentials to environment
Sys.setenv("AWS_ACCESS_KEY_ID"=aws.key[1],"AWS_SECRET_ACCESS_KEY" = aws.key[2],
	"AWS_DEFAULT_REGION" = "us-west-2")
Sys.getenv()  # check environmental variables

# Note: if the environmental variables above are not set, need to specify 'key' and 'secret' 
# arguments to cloudyR AWS functions


###
### AWS Simple Storage Service (S3)
###

# List existing S3 buckets
bucketlist()

# Create a new S3 bucket
put_bucket(bucket="brost-testing")

# Save object in current R workspace to S3 bucket
test <- matrix(rnorm(100),50,2)  # create object
s3save(list=c("test"),bucket="brost-testing",object="test")  # upload object to bucket

# Copy local file to S3 bucket
write.csv(test,"~/Git/aws/aws_example/test.csv",row.names=FALSE)  # write object
put_object("~/Git/aws/aws_example/test.csv",object="test.csv",bucket="brost-testing")  # upload object to bucket

# Copy local Rdata file to S3 bucket
save(list=c("test"), file="~/Git/aws/aws_example/test.Rdata")  # save Rdata file
put_object("~/Git/aws/aws_example/test.Rdata",object="test.Rdata",bucket="brost-testing")  # upload Rdata file to bucket

# List contents of bucket
get_bucket("brost-testing")

# Retrieve objects from S3 bucket
read.csv(text = rawToChar(get_object(object="test.csv", bucket="brost-testing")))
s3load(object="test",bucket="brost-testing")
s3load(object="test.Rdata",bucket="brost-testing")

# Save S3 object locally
save_object(object="test_out.Rdata",bucket="brost-testing",file="~/Git/aws/aws_example/test_out.Rdata")

# Delete individual object from S3 bucket
delete_object(object="test",bucket="brost-testing")
delete_object(object="test.csv",bucket="brost-testing")
delete_object(object="test.Rdata",bucket="brost-testing")

# Delete all objects in S3 bucket
lapply(get_bucket("brost-testing"),function(x) delete_object(x$Key,bucket="brost-testing"))

# View contents of bucket
get_bucket("brost-testing")

# Delete (empty) S3 bucket
delete_bucket("brost-testing")


###
### AWS Elastic Compute Cloud (EC2)
###

# Preconfigured AMI from http://www.louisaslett.com/RStudio_AMI/
image <- "ami-82ccade2"  # us-west-2 region

# Describe the AMI 
describe_images(image)

# Check VPC and security group settings
subnet <- describe_subnets()  # subnet
security.groups <- describe_sgroups()  # security group IDs
lapply(security.groups,function(x) x$groupDescription)

# Launch the instance using appropriate settings
ec2.inst <- run_instances(image=image,type="t2.micro",subnet=subnet[[1]],sgroup=security.groups[[3]])
# monitor_instances(ec2.inst)
# describe_instances(ec2.inst)

# EC2 instance ID
instance.id <- monitor_instances(ec2.inst)[[1]]$instanceId

# Get public IP address for accessing RStudio Server
public.ip <- describe_instances(ec2.inst)[[1]]$instancesSet[[1]]$networkInterfaceSet$association$publicIp
public.ip <- paste0("http://",public.ip)

# Open RStudio Server in Safari tab
browseURL(url=public.ip,browser="/usr/bin/open -a 'Safari'")

# Get public DNS for access to RStudio Server
# public.dns <- describe_instances(ec2.inst)[[1]]$instancesSet[[1]]$networkInterfaceSet$association$publicDnsName
# public.dns <- paste0("http://",public.dns)
                  
# Stop and terminate the instances
stop_instances(ec2.inst[[1]])
# terminate_instances(ec2.inst[[1]])

