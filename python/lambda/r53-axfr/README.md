AWS Lambda function to mirror an on-premises DNS to Route 53 private hosted zone
with allowing to mirror into a hosted zone with different origin.


Due to Route 53 restriction which doesn't allow associating nested private hosted zones, 
this script converts child node names (including CNAME/PTR/SRV/MX targets) for an existing route 53 zone origin.

(e.g. mirror `activedirectory.example.org` on-premises zone to `example.org` Route 53 zone)

This script is a fork of

- https://github.com/awslabs/aws-lambda-mirror-dns-function
- https://aws.amazon.com/blogs/compute/powering-secondary-dns-in-a-vpc-using-aws-lambda-and-amazon-route-53-private-hosted-zones/


