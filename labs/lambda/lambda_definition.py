import os
import urllib.parse
import boto3
import awswrangler as wr
import pandas as pd

ssm = boto3.client("ssm")


def etl_function(event, context):
    param_name = os.environ["PROCESSED_BUCKET_SSM_PARAM"]
    processed_bucket = ssm.get_parameter(Name=param_name)["Parameter"]["Value"]

    record = event["Records"][0]
    bucket = record["s3"]["bucket"]["name"]
    key = urllib.parse.unquote(record["s3"]["object"]["key"])
    full_src_path = 's3://{bucket}/{key}'.format(bucket=bucket, key=key)

    print(f'Processing key = {full_src_path}')
    df = wr.s3.read_json(path=full_src_path, lines=True)

    filename = key.split('/')[-1][-36:]
    dest_prefix = f"s3://{processed_bucket}"

    df['transaction_date'] = pd.to_datetime(df['transaction_ts'], unit='s')
    df['year'] = df['transaction_date'].dt.year
    df['month'] = df['transaction_date'].dt.month
    df['day'] = df['transaction_date'].dt.day
    df['hour'] = df['transaction_date'].dt.hour

    cols_to_return = ["transaction_date", "price", "amount", "dollar_amount", "type", "trans_id"]

    new_keys = []
    for [symbol, year, month, day, hour], data in df.groupby(['symbol', 'year', 'month', 'day', 'hour']):
        partitions = f"symbol={symbol}/year={year}/month={month}/day={day}/hour={hour}"
        full_key_name = '/'.join([dest_prefix, partitions, filename + '.parquet'])

        print(f'Saving a new key = {full_key_name}')
        new_keys.append(full_key_name)

        wr.s3.to_parquet(
            df=data[cols_to_return],
            path=full_key_name,
            compression='snappy'
        )

    return {
        'key': key,
        'statusCode': 200,
        'new_keys': new_keys
    }


if __name__ == "__main__":
    event = ""
    context = ""

    response = etl_function(event, context)