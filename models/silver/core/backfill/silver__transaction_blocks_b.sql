{{ config (
    materialized = "table"
) }}

WITH base AS (

    SELECT
        PARSE_JSON(VALUE) AS value_json,
        PARSE_JSON(
            VALUE :transaction_json
        ) AS transaction_json,
        PARSE_JSON(
            VALUE :effects_json
        ) AS efx_json
    FROM
        sui_dev.bronze.transactions_backfill
)
SELECT
    value_json :checkpoint :: NUMBER AS checkpoint_number,
    TO_TIMESTAMP(
        value_json :timestamp_ms :: NUMBER / 1000
    ) AS block_timestamp,
    value_json: transaction_digest :: STRING AS tx_digest,
    value_json: "transaction_kind" :: STRING AS tx_kind,
    value_json :"sender" :: STRING AS tx_sender,
    transaction_json :"data" [0] :"intent_message" :"intent" :"version" :: STRING AS message_version,
    -- TBD if this is real
    CASE
        WHEN efx_json :"V2" :"status" = 'Success' THEN TRUE
        ELSE FALSE
    END AS tx_succeeded,
    efx_json :"V2" :"status" :"Failure" :"error" :: STRING AS tx_error,
    efx_json: "V2" :"dependencies" AS tx_dependencies,
    value_json :"computation_cost" :: bigint AS gas_used_computation_fee,
    value_json: "non_refundable_storage_fee" :: bigint AS gas_used_non_refundable_storage_fee,
    value_json: "storage_cost" :: bigint AS gas_used_storage_fee,
    value_json: "storage_rebate" :: bigint AS gas_used_storage_rebate,
    value_json :"gas_budget" :: bigint AS gas_budget,
    value_json :"gas_owner" :: STRING AS gas_owner,
    value_json :"gas_price" :: bigint AS gas_price,
    (
        gas_used_computation_fee + gas_used_storage_fee - gas_used_storage_rebate
    ) / pow(
        10,
        9
    ) AS tx_fee
FROM
    base
