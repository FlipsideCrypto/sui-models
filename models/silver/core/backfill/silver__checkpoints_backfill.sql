{{ config (
    materialized = "table"
) }}

WITH parsed_checkpoint_data AS (

    SELECT
        PARSE_JSON(VALUE) AS value_json
    FROM
        {{ ref('bronze__checkpoints_backfill') }}
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
    value_json :total_transaction_blocks :: INT AS tx_count,
    SYSDATE() AS inserted_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    parsed_checkpoint_data
