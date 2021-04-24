-- lab 3.3

WITH CTE AS
(

 SELECT date_format(from_unixtime(transaction_ts),'%Y-%m-%dT%H') as HourlyBucket,
  RANK() OVER(PARTITION BY  date_format(from_unixtime(transaction_ts),'%Y-%m-%dT%H'), symbol ,type ORDER BY dollar_amount DESC) as rnk, *
 FROM "datalake_dev_100603781557_jk_12345"."crawler_stockdata"

)
select *
from CTE
where rnk=1
order by 1, 4, 8

-- LAB 4.2

CREATE EXTERNAL TABLE processed_stockdata(
  transaction_date timestamp,
  price double,
  amount double,
  dollar_amount double,
  type string,
  trans_id bigint)
PARTITIONED BY (
  symbol string,
  year integer,
  month integer,
  day integer,
  hour integer
  )
ROW FORMAT SERDE
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  's3://datalake-dev-100603781557-jk-12345/processed-zone/stockdata/'


MSCK REPAIR TABLE processed_stockdata;

-- LAB 5

--          .----------.   .----------.   .----------.
--          |  SOURCE  |   |  INSERT  |   |  DESTIN. |
-- Source-->|  STREAM  |-->| & SELECT |-->|  STREAM  |-->Destination
--          |          |   |  (PUMP)  |   |          |
--          '----------'   '----------'   '----------'


CREATE OR REPLACE STREAM "DESTINATION_SQL_STREAM"
("symbol" VARCHAR(10), "type" VARCHAR(10), "trans_id" BIGINT,
    "dollar_amount" DOUBLE, "AvgLast30seconds" DOUBLE, "CntLast30seconds"  INT,
    "SumLast30rows" DOUBLE, "CntLast30rows"  INT, "max_tran_id" BIGINT );

CREATE OR REPLACE PUMP "STREAM_PUMP" AS INSERT INTO "DESTINATION_SQL_STREAM"
SELECT STREAM "symbol", "type", "trans_id", "dollar_amount", "AvgLast30seconds", "CntLast30seconds"
 , "SumLast30rows", "CntLast30rows", "max_tran_id"
FROM (

    SELECT STREAM "symbol", "type", "trans_id", "dollar_amount",
        AVG("dollar_amount") OVER LAST_30_SECS AS "AvgLast30seconds",
        COUNT(*)  OVER LAST_30_SECS AS "CntLast30seconds",
        SUM("dollar_amount") OVER LAST_30_ROWS AS "SumLast30rows",
        COUNT(*)  OVER LAST_30_ROWS AS "CntLast30rows",
        MAX("trans_id") OVER LAST_30_ROWS AS "max_tran_id"
    FROM "SOURCE_SQL_STREAM_001"
    WHERE "symbol" = 'BTC_USD'
    WINDOW
        LAST_30_SECS AS (PARTITION BY "symbol", "type" RANGE INTERVAL '30' SECOND PRECEDING),
        LAST_30_ROWS AS (PARTITION BY "symbol", "type" ROWS 30 PRECEDING)
)
WHERE "dollar_amount" > 4 * ("AvgLast30seconds");
