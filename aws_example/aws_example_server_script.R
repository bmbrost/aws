###
###
### Script to be executed in RStudio Server. Uses cloudyR facilities to retrieve
### files from an Amazon S3 bucket, save output to the bucket, send AWS updates
### via email/text, and stop/terminate the EC2 instance.
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
library(aws.ec2metadata)  # AWS instance metadata
library(aws.sns)  # AWS Simple Notification Service


###
### AWS credentials
###

# AWS access keys from file downloaded from IAM Console
aws.key <- ""  # add AWS access key here...
aws.secret <- ""  # add AWS secret access key here...

# Add AWS credentials to environment
Sys.setenv("AWS_ACCESS_KEY_ID"=aws.key,"AWS_SECRET_ACCESS_KEY" = aws.secret,
           "AWS_DEFAULT_REGION" = "us-west-2")
Sys.getenv()  # check environmental variables

# Note: if the environmental variables above are not set, need to specify 'key' and 'secret' 
# arguments to cloudyR AWS functions


###
### Retrieve files from S3 bucket
###

# Read file from S3 bucket
read.csv(text=rawToChar(get_object(object="test.csv", bucket="brost-testing")))

# Read R object from S3 bucket
s3load(object="test",bucket="brost-testing")

# Load Rdata file from S3 bucket
s3load(object="test.Rdata",bucket="brost-testing")


###
### Do some processing in R...
###



###
### Save output
###

# Save object in workspace to S3 bucket
s3save(list=c("test2"),bucket="brost-testing",object="test2")

# Save workspace to S3 bucket
s3save(list=ls(all.names=TRUE),bucket="brost-testing",object="test_out.Rdata") 


###
### AWS Simple Notification Services
###

# Create notification topic
aws.update <- create_topic(name = "awsUpdate")
set_topic_attrs(aws.update, attribute = c(DisplayName = "AWS Update"))
# delete_topic(aws.update)

# Subscribe to notification service
subscribe(aws.update, "1-928-814-9703", "sms") # SMS example
subscribe(aws.update, "brian.brost@noaa.gov", "email") # email example

# Check status of subscriptions
list_subscriptions(aws.update)

# Specify messages for various endpoints
msgs <- list()
msgs$default = "This is the default message." # required
msgs$email = "Your AWS process is complete."
msgs$sms = "Your AWS process is complete."

# Publish messages...
publish(topic=aws.update, message=msgs, subject = "AWS Update")


###
### Stop/terminate EC2 instance
###

instance.id <- metadata$instance_id()  # EC2 instance ID
stop_instances(instance.id)
# terminate_instances(instance.id)


###
### AWS Simple Email Services
###

# # Verify email address - check email and click link to verify
# verify_id("brian.brost@noaa.gov")

# # Check verification status
# get_verification_attrs("brian.brost@noaa.gov")

# # Send an email
# send_email(message="Test Email Body",
	# subject="Test Email",
	# from="brian.brost@noaa.gov", to="brian.brost@noaa.gov")


###
### Send email using non-cloudyR packages
###

# install.packages("sendmailR")
# install.packages("gmailR")
# library(gmailr)
# library(sendmailR)  # send email

# Using gmailr...
# send_message(mime(
	# to="brian.brost@noaa.gov",
	# from="brian.brost@noaa.gov",
	# subject="Your AWS process has finished",
	# body="Your AWS process has completed. Please login to AWS and terminate your process as soon as 	possible."))
	
# Using sendmailR...
# sendmail(from="<brian.brost@noaa.gov>",to="<brian.brost@noaa.gov>",
	# subject="Your AWS process has finished",
	# msg="Your AWS process has completed. Please login to AWS and terminate your process as soon as 	possible.",
	# control=list(smtpServer="aspmx.l.google.com"))



