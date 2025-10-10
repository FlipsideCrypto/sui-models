{{ config (
    materialized = 'view'
) }}

SELECT
    VALUE,
    epoch,
    DATA
FROM
    streamline.sui.events
WHERE
    epoch <= 629
    AND VALUE: checkpoint :: INT < 96605300
    AND epoch = 628
