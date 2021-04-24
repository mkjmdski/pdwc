from unittest import main, TestCase
import boto3
import configparser as cp
import warnings
import os


class TestInfraKinesis(TestCase):

    def setUp(self):
        self.kinesis_client = boto3.client('kinesis')

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

        kinesis_stream_name_pattern = "cryptostock-dev-{account_number}-{student_initials}-{student_index_no}"
        self.kinesis_stream_name = kinesis_stream_name_pattern.format(account_number=self.config["account_number"],
                                                                      student_initials=self.config["student_initials"],
                                                                      student_index_no=self.config["student_index_no"])

    def test_kinesis_data_stream_exists(self):
        kinesis_streams = self.kinesis_client.list_streams()["StreamNames"]

        find_stream = next((stream for stream in kinesis_streams if stream == self.kinesis_stream_name), None)

        self.assertEqual(find_stream, self.kinesis_stream_name)

    def test_kinesis_data_stream_config(self):
        expected_no_of_shards = 1

        stream_config = self.kinesis_client.describe_stream(StreamName=self.kinesis_stream_name)

        # check no of shards
        no_of_shards = len(stream_config["StreamDescription"]["Shards"])
        self.assertEqual(no_of_shards, expected_no_of_shards)

    def test_kinesis_data_stream_tags(self):
        tags = self.kinesis_client.list_tags_for_stream(StreamName=self.kinesis_stream_name)["Tags"]

        find_env_tag = next((tag["Value"] for tag in tags if tag.get("Key") == "Environment"), None)
        self.assertEqual(find_env_tag.upper(), "DEV")

    def test_kinesis_data_stream_monitoring(self):
        expected_monitors = ['IncomingBytes', 'OutgoingRecords', 'IncomingRecords', 'OutgoingBytes']

        stream_monitoring = \
            self.kinesis_client.describe_stream(StreamName=self.kinesis_stream_name)["StreamDescription"][
                "EnhancedMonitoring"]

        current_monitors = next((x["ShardLevelMetrics"] for x in stream_monitoring if x.get("ShardLevelMetrics")), None)
        self.assertTrue(set(current_monitors).issuperset(set(expected_monitors)))


if __name__ == '__main__':
    main()
