# OU inventory publisher infrastructure

###############################################################################
# OU inventory publisher (Lambda + EventBridge)
###############################################################################

data "archive_file" "ou_inventory_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/tenant_ou_inventory"
  output_path = "${path.module}/build/tenant_ou_inventory.zip"
}

resource "aws_iam_role" "ou_inventory_lambda" {
  provider    = aws.security_lake
  name_prefix = "securitylake-ou-sync-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ou_inventory_lambda" {
  provider = aws.security_lake
  role     = aws_iam_role.ou_inventory_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OrganizationsRead"
        Effect = "Allow"
        Action = [
          "organizations:ListAccountsForParent"
        ]
        Resource = "*"
      },
      {
        Sid    = "WriteInventory"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          local.ou_inventory_objects_arn
        ]
      },
      {
        Sid      = "ListInventoryBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = local.ou_inventory_bucket_arn
      },
      {
        Sid    = "Logging"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "ou_inventory_lambda" {
  provider          = aws.security_lake
  name              = "/aws/lambda/${local.ou_inventory_lambda_name}"
  retention_in_days = 30
}

resource "aws_lambda_function" "ou_inventory" {
  provider      = aws.security_lake
  function_name = local.ou_inventory_lambda_name
  role          = aws_iam_role.ou_inventory_lambda.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  timeout       = 300

  filename         = data.archive_file.ou_inventory_package.output_path
  source_code_hash = data.archive_file.ou_inventory_package.output_sha256

  environment {
    variables = {
      INVENTORY_BUCKET = var.ou_inventory_bucket
      INVENTORY_PREFIX = local.ou_inventory_prefix_clean
      TARGET_OUS       = local.tenant_inventory_target_list
    }
  }

  depends_on = [aws_iam_role_policy.ou_inventory_lambda]
}

# EventBridge rule for Organizations account lifecycle events
resource "aws_cloudwatch_event_rule" "ou_inventory_org_events" {
  provider    = aws.security_lake
  name        = "securitylake-ou-sync-org-events"
  description = "Trigger OU inventory sync when Organization account membership changes."

  event_pattern = jsonencode({
    "source" : ["aws.organizations"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["organizations.amazonaws.com"],
      "eventName" : [
        "CreateAccountResult",
        "InviteAccountToOrganization",
        "MoveAccount",
        "RemoveAccountFromOrganization",
        "CloseAccount"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "ou_inventory_org_events" {
  provider  = aws.security_lake
  rule      = aws_cloudwatch_event_rule.ou_inventory_org_events.name
  target_id = "lambda"
  arn       = aws_lambda_function.ou_inventory.arn
}

resource "aws_lambda_permission" "allow_eventbridge_org_events" {
  provider      = aws.security_lake
  statement_id  = "AllowExecutionFromEventBridgeOrg"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ou_inventory.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ou_inventory_org_events.arn
}

# Scheduled safety net (daily sync)
resource "aws_cloudwatch_event_rule" "ou_inventory_scheduled" {
  provider            = aws.security_lake
  name                = "securitylake-ou-sync-daily"
  description         = "Daily OU inventory refresh."
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "ou_inventory_scheduled" {
  provider  = aws.security_lake
  rule      = aws_cloudwatch_event_rule.ou_inventory_scheduled.name
  target_id = "lambda"
  arn       = aws_lambda_function.ou_inventory.arn
}

resource "aws_lambda_permission" "allow_eventbridge_schedule" {
  provider      = aws.security_lake
  statement_id  = "AllowExecutionFromEventBridgeSchedule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ou_inventory.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ou_inventory_scheduled.arn
}
