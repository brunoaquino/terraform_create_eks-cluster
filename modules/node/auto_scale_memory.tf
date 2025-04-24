resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.cluster_name}-memory-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.auto_scale_memory.scale_up_evaluation
  metric_name         = "node_memory_utilization_over_node_allocatable"
  namespace           = "ContainerInsights"
  period              = var.auto_scale_memory.scale_up_period
  statistic           = "Average"
  threshold           = var.auto_scale_memory.scale_up_threshold

  dimensions = {
    ClusterName = aws_eks_node_group.eks_node_group.cluster_name
  }

  alarm_description = "This metric monitors memory utilization for scaling up"
  alarm_actions     = [aws_autoscaling_policy.scale_up_memory.arn]
}

resource "aws_autoscaling_policy" "scale_up_memory" {
  name                   = "${var.cluster_name}-nodes-scale-up-memory"
  scaling_adjustment     = var.auto_scale_memory.scale_up_add
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.auto_scale_memory.scale_up_cooldown
  autoscaling_group_name = aws_eks_node_group.eks_node_group.resources[0].autoscaling_groups[0].name
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  alarm_name          = "${var.cluster_name}-memory-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.auto_scale_memory.scale_down_evaluation
  metric_name         = "node_memory_utilization_over_node_allocatable"
  namespace           = "ContainerInsights"
  period              = var.auto_scale_memory.scale_down_period
  statistic           = "Average"
  threshold           = var.auto_scale_memory.scale_down_threshold

  dimensions = {
    ClusterName = aws_eks_node_group.eks_node_group.cluster_name
  }

  alarm_description = "This metric monitors memory utilization for scaling down"
  alarm_actions     = [aws_autoscaling_policy.scale_down_memory.arn]
}

resource "aws_autoscaling_policy" "scale_down_memory" {
  name                   = "${var.cluster_name}-nodes-scale-down-memory"
  scaling_adjustment     = var.auto_scale_memory.scale_down_remove
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.auto_scale_memory.scale_down_cooldown
  autoscaling_group_name = aws_eks_node_group.eks_node_group.resources[0].autoscaling_groups[0].name
}
