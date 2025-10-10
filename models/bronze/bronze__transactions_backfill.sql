{{ config (
    materialized = 'view'
) }}

SELECT
    VALUE,
    epoch,
    DATA
FROM
    streamline.sui.transactions_backfill
WHERE
    epoch = 700
    AND VALUE :checkpoint :: INT = 121932315
