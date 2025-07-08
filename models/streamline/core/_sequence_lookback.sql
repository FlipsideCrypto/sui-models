{{ config(
    materialized = 'ephemeral',
    enabled = false
) }}

SELECT
    COALESCE(MIN(checkpoint_number), 0) AS checkpoint_number
FROM
    {{ ref("core__fact_checkpoints") }}
WHERE
    block_timestamp >= DATEADD('hour', -72, TRUNCATE(SYSDATE(), 'HOUR'))
    AND block_timestamp < DATEADD('hour', -71, TRUNCATE(SYSDATE(), 'HOUR'))
