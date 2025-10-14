{{ config (
    materialized = 'view'
) }}

SELECT
    VALUE,
    epoch,
    DATA
FROM
    {{ source(
        'bronze_streamline',
        'events'
    ) }}
WHERE
    epoch <= 629
    AND VALUE: checkpoint :: INT < 96605300
