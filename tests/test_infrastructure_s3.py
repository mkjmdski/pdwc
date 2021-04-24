from unittest import main, TestCase
import boto3
import configparser as cp
import warnings
import os


class TestInfraS3(TestCase):

    def setUp(self):
        self.s3_client = boto3.client('s3')

        # read configuration
        # making path universal for running tests from the module / outside
        cwd = os.getcwd()
        extra_dot = '.' if cwd.endswith('tests') else ''
        config_path = extra_dot + "./labs/terraform/terraform.tfvars"

        with open(config_path, 'r') as f:
            config_string = '[main]\n' + f.read()
        config = cp.ConfigParser()
        config.read_string(config_string)

        self.config = {param: (
            config["main"][param].replace('"', '') if isinstance(config["main"][param], str) else config["main"][param]
        ) for param in config["main"]}

        warnings.filterwarnings("ignore", category=ResourceWarning, message="unclosed.*<ssl.SSLSocket.*>")

        bucket_name_pattern = "datalake-dev-{account_number}-{student_initials}-{student_index_no}"
        self.bucket_name = bucket_name_pattern.format(account_number=self.config["account_number"],
                                                      student_initials=self.config["student_initials"],
                                                      student_index_no=self.config["student_index_no"])

    def test_main_s3_bucket_exists(self):
        s3_buckets = self.s3_client.list_buckets()["Buckets"]

        find_bucket = next((bucket["Name"] for bucket in s3_buckets if bucket["Name"] == self.bucket_name), None)

        self.assertEqual(find_bucket, self.bucket_name)

    def test_main_s3_bucket_comfig(self):
        tags = self.s3_client.get_bucket_tagging(
            Bucket=self.bucket_name
        )["TagSet"]

        find_env_tag = next((tag["Value"] for tag in tags if tag.get("Key") == "Environment"), None)
        self.assertEqual(find_env_tag.upper(), "DEV")


if __name__ == '__main__':
    main()
