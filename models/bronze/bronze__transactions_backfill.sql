{{ config (
    materialized = 'view'
) }}

SELECT
    VALUE,
    EPOCH,
    DATA
FROM streamline.sui.transactions_backfill
where epoch = 700 
and value:checkpoint::int = 121948955
