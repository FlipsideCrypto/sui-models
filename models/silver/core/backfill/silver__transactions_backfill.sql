{{ config (
    materialized = "table"
) }}

WITH base AS (

    SELECT
        PARSE_JSON(
            A.value
        ) AS value_json,
        PARSE_JSON(
            A.value :transaction_json
        ) AS transaction_json,
        PARSE_JSON(
            A.value :effects_json
        ) AS efx_json,
        b.index AS payload_index,
        C.key AS payload_type,
        C.value AS payload_details
    FROM
        {{ ref('bronze__transactions_backfill') }} A,
        LATERAL FLATTEN(
            transaction_json :data [0] :intent_message :value :"V1" :kind :ProgrammableTransaction :commands
        ) b,
        LATERAL FLATTEN(
            b.value
        ) C
)
SELECT
    value_json :checkpoint :: NUMBER AS checkpoint_number,
    TO_TIMESTAMP(
        value_json :timestamp_ms :: NUMBER / 1000
    ) AS block_timestamp,
    value_json: transaction_digest :: STRING AS tx_digest,
    value_json: "transaction_kind" :: STRING AS tx_kind,
    value_json :"sender" :: STRING AS tx_sender,
    LOWER(
        object_keys(
            transaction_json :"data" [0] :"intent_message" :value
        ) [0]
    ) :: STRING AS message_version,
    CASE
        WHEN efx_json :"V2" :"status" = 'Success' THEN TRUE
        ELSE FALSE
    END AS tx_succeeded,
    payload_index,
    payload_type,
    payload_details,
    SYSDATE() AS inserted_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    base
