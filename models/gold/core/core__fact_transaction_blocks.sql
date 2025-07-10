{{ config (
    materialized = "incremental",
    unique_key = "tx_digest",
    cluster_by = ['block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gold','core']
) }}

WITH base AS (

    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        transaction_json :"transaction" :"data" :"transaction" :"kind" :: STRING AS tx_kind,
        transaction_json :"transaction" :"data" :"sender" :: STRING AS tx_sender,
        transaction_json :"transaction" :"data" :"messageVersion" :: STRING AS message_version,
        CASE
            WHEN transaction_json :"effects" :"status" :"status" = 'failure' THEN FALSE
            ELSE TRUE
        END AS tx_succeeded,
        transaction_json :"effects" :"status" :"error" :: STRING AS tx_error,
        {# transaction_json :"transaction" :txSignatures AS tx_signatures, #}
        transaction_json :"effects": "dependencies" AS tx_dependencies,
        {# transaction_json :"effects": "gasObject" :"reference" :"digest" :: STRING AS gas_digest, #}
        transaction_json :"effects": "gasUsed" :"computationCost" :: bigint AS gas_used_computation_cost,
        transaction_json :"effects": "gasUsed" :"nonRefundableStorageFee" :: bigint AS gas_used_non_refundable_storage_fee,
        transaction_json :"effects": "gasUsed" :"storageCost" :: bigint AS gas_used_storage_cost,
        transaction_json :"effects": "gasUsed" :"storageRebate" :: bigint AS gas_used_storage_rebate,
        transaction_json :"transaction" :"data" :"gasData" :"budget" :: bigint AS gas_budget,
        transaction_json :"transaction" :"data" :"gasData" :"owner" :: STRING AS gas_owner,
        transaction_json :"transaction" :"data" :"gasData" :"price" :: bigint AS gas_price,
        {# transaction_json :"transaction" :"data" :"gasData" :"payment" AS gas_payments, #}
        (
            gas_used_computation_cost + gas_used_storage_cost - gas_used_storage_rebate
        ) / pow(
            10,
            9
        ) AS tx_fee
    FROM
        {{ ref('silver__transactions') }}

{% if is_incremental() %}
WHERE
    modified_timestamp >= (
        SELECT
            COALESCE(MAX(modified_timestamp), '1970-01-01' :: TIMESTAMP) AS modified_timestamp
        FROM
            {{ this }})
        {% endif %}
    )
SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    tx_kind,
    tx_sender,
    message_version,
    tx_fee,
    tx_succeeded,
    tx_error,
    tx_dependencies,
    gas_used_computation_cost,
    gas_used_non_refundable_storage_fee,
    gas_used_storage_cost,
    gas_used_storage_rebate,
    gas_price,
    gas_budget,
    gas_owner,
    {{ dbt_utils.generate_surrogate_key(['tx_digest']) }} AS fact_transaction_blocks_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    base
