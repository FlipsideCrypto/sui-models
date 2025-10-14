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
        'checkpoints_backfill'
    ) }}
WHERE
    epoch <= 629
    AND VALUE: sequence_number :: INT < 96605300
