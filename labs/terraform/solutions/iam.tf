resource "aws_iam_role" "firehose_stream_role" {
  name = "firehose-role-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"

  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Action": "sts:AssumeRole",
       "Principal": {
         "Service": "firehose.amazonaws.com"
       },
       "Effect": "Allow",
       "Sid": ""
     }
   ]
}
EOF
}

resource "aws_iam_role_policy" "firehose_stream_policy" {
  name = "firehose-stream-policy-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"
  role = aws_iam_role.firehose_stream_role.id

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
           "Effect": "Allow",
           "Action": "kinesis:*",
           "Resource": "*"
       },
      {
           "Effect": "Allow",
           "Action": [
               "s3:AbortMultipartUpload",
               "s3:GetBucketLocation",
               "s3:GetObject",
               "s3:ListBucket",
               "s3:ListBucketMultipartUploads",
               "s3:PutObject"
           ],
           "Resource": [
             "${aws_s3_bucket.main_dl_bucket.arn}",
             "${aws_s3_bucket.main_dl_bucket.arn}/*"
           ]
       },
       {
           "Sid": "",
           "Effect": "Allow",
           "Action": [
               "logs:PutLogEvents"
           ],
           "Resource": [
               "arn:aws:logs:${var.region}:${var.account_number}:log-group:/aws/kinesisfirehose/*"
           ]
       }
   ]
}
EOF
}


// Role & policies for Glue Crawler
resource "aws_iam_role" "glue_crawler_role" {
  name = "crawler-role-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "glue.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
EOF
}


data "aws_iam_policy" "glue_service_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_crawler_user_bucket_policy" {
  name = "user-bucket-policy-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"
  role = aws_iam_role.glue_crawler_role.id

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:PutObject"
        ],
        "Resource": [
             "${aws_s3_bucket.main_dl_bucket.arn}*"
        ]
    }
   ]
}
EOF
}

resource "aws_iam_policy_attachment" "crawler_attach_managed_policy" {
  name = "crawler-managed-service-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"
  roles = [
    aws_iam_role.glue_crawler_role.name]
  policy_arn = data.aws_iam_policy.glue_service_policy.arn
}


// Role and policies for Lambda
resource "aws_iam_role" "lambda_basic_role" {
  name = "lambda-basic-role-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"
  tags = merge(local.common_tags, )

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_basic_policy" {
  name = "lambda-basic-policy-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"
  role = aws_iam_role.lambda_basic_role.id

  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Effect": "Allow",
     "Resource": "*"
   },
   {
     "Effect": "Allow",
     "Action": "s3:*",
     "Resource": [
             "${aws_s3_bucket.main_dl_bucket.arn}",
             "${aws_s3_bucket.main_dl_bucket.arn}/*"]
   }
 ]
}
EOF
}

