{{ config (
    materialized = 'view'
) }}

SELECT
    VALUE,
    epoch,
    DATA
FROM
    {{ source('bronze_streamline', 'events_backfill') }}
WHERE
    epoch <= 629
    AND VALUE: checkpoint :: INT < 96605300
    AND epoch = 628
