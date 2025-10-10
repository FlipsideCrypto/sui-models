{{ config (
    materialized = "table"
) }}

WITH parsed_checkpoint_data AS (

    SELECT
        -- Parse the VALUE JSON column
        PARSE_JSON(VALUE) AS value_json
    FROM
        sui_dev.bronze.checkpoints_backfill
)
SELECT
    value_json :sequence_number :: NUMBER AS checkpoint_number,
    TO_TIMESTAMP(
        value_json :timestamp_ms :: NUMBER / 1000
    ) AS block_timestamp,
    value_json :epoch :: STRING AS epoch,
    value_json :checkpoint_digest :: STRING AS checkpoint_digest,
    value_json :previous_checkpoint_digest :: STRING previous_digest,
    value_json :network_total_transaction :: STRING network_total_transactions,
    value_json :validator_signature :: STRING AS validator_signature,
    value_json :total_transactions :: INT AS tx_count
FROM
    parsed_checkpoint_data
