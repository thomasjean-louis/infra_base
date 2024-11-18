# Infra_base
Terraform repository used to manage resources available 24/7 and deployed on aws Dev and Prod accounts. 

## Resources

### Access and rights
IAM users, roles, policies used by the [Terraform repo](https://github.com/thomasjean-louis/infra) to manage the resources needed for the "Serverless multi-player game" demo project.

### DNS
Route53 hosted zones and records, required to manage the [presentation website](https://github.com/thomasjean-louis/presentationWebsite) and projects domain names.

### Orchestration
Lambda functions combined with cloudwatch events to schedule [terraform](https://github.com/thomasjean-louis/infra) deployments.

### Monitoring
SES notifications for realtime alerts.
DynamoDb table and Cloudwatch log groups to keep track of past events (new connection, server launch)


### Demo
Resources that have to be built before the [demo terraform deployment](https://github.com/thomasjean-louis/infra) :
* Cognito users,
* ECR repositories, to host [proxy](https://github.com/thomasjean-louis/proxy) and [game](https://github.com/thomasjean-louis/gameserver) servers docker images. 


