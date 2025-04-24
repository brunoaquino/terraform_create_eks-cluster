# Grupo de logs para VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.cluster_name}"
  retention_in_days = 30

  tags = {
    Name        = format("%s-flow-logs", var.cluster_name)
    Environment = "dev"
  }
}

# IAM Role para Flow Logs
resource "aws_iam_role" "flow_logs_role" {
  name = format("%s-flow-logs-role", var.cluster_name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

# IAM Policy para Flow Logs
resource "aws_iam_role_policy" "flow_logs_policy" {
  name = format("%s-flow-logs-policy", var.cluster_name)
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.eks_vpc.id

  tags = {
    Name = format("%s-vpc-flow-logs", var.cluster_name)
  }
}
