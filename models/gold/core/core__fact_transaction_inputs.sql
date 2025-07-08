{{ config (
    materialized = "incremental",
    unique_key = "fact_transaction_inputs_id",
    cluster_by = ['block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
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
        b.index AS input_index,
        b.value AS input_value,
        input_value :"initialSharedVersion" :: STRING AS initial_shared_version,
        input_value :"mutable" :: BOOLEAN AS mutable,
        input_value :"objectId" :: STRING AS object_id,
        input_value :"objectType" :: STRING AS object_type,
        input_value :"type" :: STRING AS TYPE,
        input_value :"version" :: bigint AS version,
        input_value :"digest" :: STRING AS digest,
        input_value :"value" :: STRING AS VALUE,
        input_value :"valueType" :: STRING AS value_type
    FROM
        {{ ref('silver__transactions') }} A,
        LATERAL FLATTEN(
            A.transaction_json :"transaction" :"data" :"transaction": "inputs"
        ) b

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
    input_index,
    TYPE,
    version,
    object_id,
    object_type,
    digest,
    VALUE,
    value_type,
    initial_shared_version,
    mutable,
    {{ dbt_utils.generate_surrogate_key(['tx_digest','input_index']) }} AS fact_transaction_inputs_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    base
