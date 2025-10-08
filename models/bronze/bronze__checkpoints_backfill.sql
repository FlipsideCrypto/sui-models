{{ config (
    materialized = 'view'
) }}

SELECT
    VALUE,
    EPOCH,
    DATA
FROM streamline.sui.checkpoints_backfill
where epoch = 906
and data:sequence_number::int between 197140000 and 197140050
