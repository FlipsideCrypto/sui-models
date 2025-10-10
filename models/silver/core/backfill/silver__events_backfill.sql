{{ config (
    materialized = "table"
) }}

WITH base AS (

    SELECT
        PARSE_JSON(
            A.value
        ) AS value_json,
        PARSE_JSON(
            A.value :event_json
        ) AS event_json
    FROM
        {{ ref('bronze__events_backfill') }} A
)
SELECT
    value_json :checkpoint :: INT AS checkpoint_number,
    TO_TIMESTAMP(
        value_json :timestamp_ms :: NUMBER / 1000
    ) AS block_timestamp,
    value_json: transaction_digest :: STRING AS tx_digest,
    value_json :event_index :: INT AS event_index,
    value_json :"package" :: STRING AS package_id,
    value_json :"module" :: STRING AS transaction_module,
    value_json :"sender" :: STRING AS sender,
    value_json :"event_type" :: STRING AS TYPE,
    event_json AS parsed_json,
    SYSDATE() AS inserted_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    base
