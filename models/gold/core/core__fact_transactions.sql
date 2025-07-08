{{ config (
    materialized = "incremental",
    unique_key = "fact_transactions_id",
    cluster_by = ['block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    tags = ['gold','core']
) }}

WITH base AS (

    SELECT
        A.checkpoint_number,
        A.block_timestamp,
        A.tx_digest,
        A.transaction_json :"transaction" :"data" :"transaction" :"kind" :: STRING AS tx_kind,
        A.transaction_json :"transaction" :"data" :"sender" :: STRING AS tx_sender,
        A.transaction_json :"transaction" :"data" :"messageVersion" :: STRING AS message_version,
        CASE
            WHEN transaction_json :"effects" :"status" :"status" = 'failure' THEN FALSE
            ELSE TRUE
        END AS tx_succeeded,
        b.index AS payload_index,
        C.key AS payload_type,
        C.value AS payload_details
    FROM
        {{ ref('silver__transactions') }} A,
        LATERAL FLATTEN(
            A.transaction_json :"transaction" :"data" :"transaction": "transactions"
        ) b,
        LATERAL FLATTEN(
            b.value
        ) C

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
    tx_succeeded,
    payload_index,
    payload_type,
    payload_details,
    {{ dbt_utils.generate_surrogate_key(['tx_digest','payload_index']) }} AS fact_transactions_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    base
