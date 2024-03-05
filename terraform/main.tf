
data "aws_vpc" "default" {
  filter {
    name   = "tag:Name"
    values = ["default"]
  }
}

# these are the default subnets that came with
# the AWS account when I created it
data "aws_subnet" "subnet_a" {
  filter {
    name   = "tag:Name"
    values = ["subnet-a"]
  }
}

data "aws_subnet" "subnet_b" {
  filter {
    name   = "tag:Name"
    values = ["subnet-b"]
  }
}

data "aws_subnet" "subnet_c" {
  filter {
    name   = "tag:Name"
    values = ["subnet-c"]
  }
}

data "aws_security_group" "ecs_security_group" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

#ensure my public IP is able to ingress into the sg
resource "aws_vpc_security_group_ingress_rule" "allow_my_http_ipv4" {
  security_group_id = data.aws_security_group.ecs_security_group.id
  cidr_ipv4         = "${local.my_public_ip}/32"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_my_port_8080" {
  security_group_id = data.aws_security_group.ecs_security_group.id
  cidr_ipv4         = "${local.my_public_ip}/32"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow_my_port_3000" {
  security_group_id = data.aws_security_group.ecs_security_group.id
  cidr_ipv4         = "${local.my_public_ip}/32"
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_ingress_rule" "allow_internal_port_3000" {
  security_group_id = data.aws_security_group.ecs_security_group.id
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_ingress_rule" "allow_internal_port_8080" {
  security_group_id = data.aws_security_group.ecs_security_group.id
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

#retrieve the ECR image location as data
#public ECR is only in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_ecrpublic_repository" "lightfeather" {
  provider        = aws.us_east_1
  repository_name = "lightfeather"
}

# create the IAM policy and role, and attach it
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "devops-code-challenge-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ecs_task_execution_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_policy.arn
}

resource "aws_cloudwatch_log_group" "lightfeather" {
  name = "/ecs/lightfeather"
}

resource "aws_cloudwatch_log_group" "frontend" {
  name = "/ecs/frontend"
}

resource "aws_ecs_cluster" "app" {
  name = "app"
}

resource "aws_ecs_task_definition" "lightfeather" {
  family = "lightfeather"

  container_definitions = <<EOF
  [
    {
      "name": "lightfeather",
      "image": "${aws_ecrpublic_repository.lightfeather.repository_uri}:latest",
      "portMappings": [
        {
          "containerPort": ${local.lightfeather_port},
          "hostPort": ${local.lightfeather_port}
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "us-east-2",
          "awslogs-group": "/ecs/lightfeather",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
  EOF

  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "${local.lightfeather_cpu}"
  memory                   = "${local.lightfeather_memory}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
}

resource "aws_ecs_service" "lightfeather" {
  name            = "lightfeather"
  cluster         = aws_ecs_cluster.app.id
  desired_count   = local.lightfeather_count
  depends_on      = [aws_iam_role.ecs_task_execution_role]
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.lightfeather.arn
  network_configuration {
    assign_public_ip = true
    subnets          = [data.aws_subnet.subnet_a.id,data.aws_subnet.subnet_b.id,data.aws_subnet.subnet_c.id]
    security_groups  = [data.aws_security_group.ecs_security_group.id]
  }
}
