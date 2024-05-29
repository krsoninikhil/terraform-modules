# terraform-modules
Reusable terraform modules for aws resources

## Resources Created

### msk

`msk` creates a AWS Managed Kafka with following resources:
- MSK itself along with nodes defined by `no_of_nodes` variable with instance type defined by `instance_type`
- Brokers are publicly accessible if `make_public` is true
- Security groups to allow traffic on relevant ports
- Secrets in secret manager for the users specified by `scram_users` variable
- Both IAM and SCRAM based auth is enabled

### ecs_cluster and ecs_service

`ecs_cluster` allows you create a ECS cluster and then keep adding any new services using the `ecs_service` module
- `ecs_cluster` a launch template and autoscaling group for nodes and then a cluster and the created autoscaling group is set to cluster's capacity provider.
- It also sets up the relevant IAM roles which are required to allow nodes created to register as container instances
- A security group where ingress are created based on values provided in `connect_from`
- `ecs_service` will create all the resources required to deploy a new service with a dummy nginx service. You can update the docker image name in the task definition either manually or via CI/CD pipeline to deploy a new version of you service.
- Resources required for a service are -- task definition with a cloud watch log group, target group with ingress on specified `port`, ecs service with autoscaling policy. It will also map the target group on ELB is you provide the value for `route`

### ec2

`ec2` modules allows you to create a instance with autoscaling, specify the ports to open and put it behind an ELB.
- An EC2 instance with type specified by `instance_type`
- A Launch Template to allow enabling auto scalling group if required
- An autoscaling group unless `autoscalling.enabled` is set to false
- You can specify the no. of max and min nodes to provision under the created autoscaling group if it's enabled
- An elastic IP is attached to the instance
- A security group to allow connections to the instance with ingress rules based on `connections` variable
- If `connections` are specified, instances are added to a target group with port mapping based on `connections` value
- If a ELB listener (`listern_arn`) and routes in `connections` are provided, the paths are mapped to ELB routed to the provided ports
- You can specify any user script to run after launching the instance by setting base64 encoded script to  `user_data` 
- You can also specify the user data in [cloud-init](https://cloudinit.readthedocs.io/en/latest/explanation/introduction.html) format by setting the yaml template file path to `user_data_template_file` 

## Support

If you need any help in using these modules, feel fee to [get in touch](https://nikhilsoni.me/contact/).