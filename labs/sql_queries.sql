WITH hourly_trades AS (
    SELECT
        date_format(from_unixtime(transaction_ts), '%Y-%m-%dT%H') AS HourlyBucket,
        ROW_NUMBER() OVER (
            PARTITION BY
                symbol,
                "type",
                date_format(from_unixtime(transaction_ts), '%Y-%m-%dT%H')
            ORDER BY dollar_amount DESC
        ) AS rnk,
        transaction_ts,
        symbol,
        price,
        amount,
        dollar_amount,
        "type",
        trans_id,
        date_format(from_unixtime(transaction_ts), '%Y')  AS "year",
        month,
        day,
        hour
    FROM datalake_raw_174202832180_mm_s1203137.crawler_year_2026
)
SELECT *
FROM hourly_trades
WHERE rnk = 1
ORDER BY HourlyBucket, symbol, "type";