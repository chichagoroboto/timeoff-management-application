
# TimeOff.Management

Web application for managing employee absences.

<a href="https://travis-ci.org/timeoff-management/timeoff-management-application"><img align="right" src="https://travis-ci.org/timeoff-management/timeoff-management-application.svg?branch=master" alt="Build status" /></a>

## Features

**Multiple views of staff absences**

Calendar view, Team view, or Just plain list.

**Tune application to fit into your company policy**

Add custom absence types: Sickness, Maternity, Working from home, Birthday etc. Define if each uses vacation allowance.

Optionally limit the amount of days employees can take for each Leave type. E.g. no more than 10 Sick days per year.

Setup public holidays as well as company specific days off.

Group employees by departments: bring your organisational structure, set the supervisor for every department.

Customisable working schedule for company and individuals.

**Third Party Calendar Integration**

Broadcast employee whereabouts into external calendar providers: MS Outlook, Google Calendar, and iCal.

Create calendar feeds for individuals, departments or entire company.

**Three Steps Workflow**

Employee requests time off or revokes existing one.

Supervisor gets email notification and decides about upcoming employee absence.

Absence is accounted. Peers are informed via team view or calendar feeds.

**Access control**

There are following types of users: employees, supervisors, and administrators.

Optional LDAP authentication: configure application to use your LDAP server for user authentication.

**Ability to extract leave data into CSV**

Ability to back up entire company leave data into CSV file. So it could be used in any spreadsheet applications.

**Works on mobile phones**

The most used customer paths are mobile friendly:

* employee is able to request new leave from mobile device

* supervisor is able to record decision from the mobile as well.

**Lots of other little things that would make life easier**

Manually adjust employee allowances
e.g. employee has extra day in lieu.

Upon creation employee receives pro-rated vacation allowance, depending on start date.

Email notification to all involved parties.

Optionally allow employees to see the time off information of entire company regardless of department structure.

## Screenshots

![TimeOff.Management Screenshot](https://raw.githubusercontent.com/timeoff-management/application/master/public/img/readme_screenshot.png)

## Installation

### Cloud hosting

Visit http://timeoff.management/

Create company account and use cloud based version.

### Self hosting

Install TimeOff.Management application within your infrastructure:

(make sure you have Node.js (>=4.0.0) and SQLite installed)

```bash
git clone https://github.com/timeoff-management/application.git timeoff-management
cd timeoff-management
npm install
npm start
```
Open http://localhost:3000/ in your browser.

## Run tests

We have quite a wide test coverage, to make sure that the main user paths work as expected.

Please run them frequently while developing the project.

Make sure you have Chrome driver installed in your path and Chrome browser for your platform.

If you want to see the browser execute the interactions prefix with `SHOW_CHROME=1`

```bash
USE_CHROME=1 npm test
```

(make sure that application with default settings is up and running)

Any bug fixes or enhancements should have good test coverage to get them into "master" branch.

## Updating existing instance with new code

In case one needs to patch existing instance of TimeOff.Managenent application with new version:

```bash
git fetch
git pull origin master
npm install
npm run-script db-update
npm start
```
## Architecture to be deployed

The simplest way to deploy the timeoff-management-application application create a docker image to run this application, and deploy the infrastructure required for it to run for this we will use github action as CI / CD so that everything is CODE. For this we must know the following tools:

###What is GitHub Actions?

GitHub Actions is an API for cause and effect on GitHub: orchestrate any workflow, based on any event, while GitHub manages the execution, provides rich feedback, and secures every step along the way. With GitHub Actions, workflows and steps are just code in a repository, so you can create, share, reuse, and fork your software development practices.

####What is AWS ECS ?
Amazon Elastic Container Service (Amazon ECS) is a scalable, high-performance container orchestration service that supports Docker containers and allows you to easily run and scale containerized applications on AWS.
It is amazon's way of allowing us to run and manage Containers at scale. ECS eliminates the need for us to install and run our orchestration engine for running, monitoring, and managing our clusters.
 
###What is AWS ECR ?
ECR (Elastic Container Repository) which is a fully-managed Docker container registry that makes it easy for developers to store, manage, and deploy Docker container images.
Deploying ECS can be a rather difficult error-prone task that would benefit from the immutability that Infrastructure as code provides. 
 
###What is Terraform ?
Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions.
It allows you to describe your infrastructure via configuration files. Once you have your files in place, the Terraform CLI allows you to spin up cloud resources from the command line.

The following diagram shows the infrastructure used for this case:

## Screenshots
![Architecture Screenshot](https://github.com/chichagoroboto/timeoff-management-application/blob/master/pictures/Diagram.png)

solo nos queda inicar  con el despliegue 
guardaremos el tfstate el terraform en un bucket s3 para asi tener a la mano siempre el  

```bash
  backend "s3" {
    bucket = "protomolecula"
    key    = "gorillaterraform.tfstate"
    region = "us-east-1"
  }
}
```

###Provisioning infrastructure on AWS

We will provision the infrastructure necessary to run our cloud application successfully using the AWS provider Terraform.
We continue with the trraform code that creates the infra Create Default VPC, Subnets, ECS Service, Task Definitions, IAM Role for ECS Execution, ECR Lifecycle Policy, Security Groups

```bash
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-1b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "us-east-1c"
}

resource "aws_ecr_repository" "my_ecr_repo" {
  name = "my-ecr-repo"
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster" # Naming the cluster
}


resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my-task",
      "image": "${aws_ecr_repository.my_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_alb" "application_load_balancer" {
  name               = "test-lb-tf" # Naming our load balancer
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}",
    "${aws_default_subnet.default_subnet_c.id}"
  ]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_default_vpc.default_vpc.id}" # Referencing the default VPC
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}" # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our tagrte group
  }
}

resource "aws_ecs_service" "my_service" {
  name            = "my-service"                             # Naming our first service
  cluster         = "${aws_ecs_cluster.my_cluster.id}"       # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.my_task.arn}" # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Setting the number of containers to 3

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our target group
    container_name   = "${aws_ecs_task_definition.my_task.family}"
    container_port   = 3000 # Specifying the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true                                                # Providing our containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"] # Setting the security group
  }
}


resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
### Configure GitHub Actions
GitHub Actions make use of a YAML-formatted workflow file. This file establishes the configuration for things such as what events should include action processes, the type of runner to use, and the configuration of the jobs with the required steps to reach completion. In order for the GitHub Actions process to pick up the YAML file, there’s a specific location for it to live. Each repository using actions requires a directory structure of /.github/workflows

For this case we will create two yml files, the first one is terraform.yml, it will be embedded to show all the required infrastructure for our application to run. The second file is aws.yml. This workflow will create and send the image of the TimeOff.Management application to Amazon ECR.
When the pipeline ends it will automatically load the application in the URL of our application load balancer

## Screenshots

![Architecture Screenshot](https://github.com/chichagoroboto/timeoff-management-application/blob/master/pictures/Diagram1.png)

## Feedback

Please report any issues or feedback to <a href="https://twitter.com/FreeTimeOffApp">twitter</a> or Email: pavlo at timeoff.management

