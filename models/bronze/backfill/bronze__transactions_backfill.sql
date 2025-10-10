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
    epoch <= 629
    AND checkpoint_number < 96605300
