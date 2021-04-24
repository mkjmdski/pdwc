from unittest import main, TestCase
import boto3
import configparser as cp
import warnings
import os


class TestInfraKinesisFH(TestCase):

    def setUp(self):
        self.firehose_client = boto3.client('firehose')
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

        firehose_stream_name_pattern = "firehose-dev-{account_number}-{student_initials}-{student_index_no}"
        self.firehose_stream_name = firehose_stream_name_pattern.format(account_number=self.config["account_number"],
                                                                        student_initials=self.config[
                                                                            "student_initials"],
                                                                        student_index_no=self.config[
                                                                            "student_index_no"])

        kinesis_stream_name_pattern = "cryptostock-dev-{account_number}-{student_initials}-{student_index_no}"
        self.kinesis_stream_name = kinesis_stream_name_pattern.format(account_number=self.config["account_number"],
                                                                      student_initials=self.config["student_initials"],
                                                                      student_index_no=self.config["student_index_no"])

    def test_kinesis_firehose_exists(self):
        deliver_streams = self.firehose_client.list_delivery_streams()["DeliveryStreamNames"]
        find_stream = next((stream for stream in deliver_streams if stream == self.firehose_stream_name), None)

        self.assertEqual(find_stream, self.firehose_stream_name)

    def test_kinesis_firehose_source(self):
        config = self.firehose_client.describe_delivery_stream(DeliveryStreamName=self.firehose_stream_name)
        source = config["DeliveryStreamDescription"]["Source"]["KinesisStreamSourceDescription"]["KinesisStreamARN"]

        kinesis_stream_config = self.kinesis_client.describe_stream(StreamName=self.kinesis_stream_name)
        kds_arn = kinesis_stream_config["StreamDescription"]["StreamARN"]

        self.assertEqual(kds_arn, source)

    def test_kinesis_firehose_dest_config(self):
        config = self.firehose_client.describe_delivery_stream(DeliveryStreamName=self.firehose_stream_name)
        destination = config["DeliveryStreamDescription"]["Destinations"][0]

        expected_pref = 'raw-zone/stockdata/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/'
        expected_err_pref = 'raw-zone/stockdata_errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/'

        dest_prefix = destination.get("S3DestinationDescription", None).get("Prefix", None)
        dest_errors_prefix = destination.get("S3DestinationDescription", None).get("ErrorOutputPrefix", None)

        self.assertEqual(dest_prefix, expected_pref)
        self.assertEqual(expected_err_pref, dest_errors_prefix)


if __name__ == '__main__':
    main()
