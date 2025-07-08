{{ config (
    materialized = "incremental",
    unique_key = "fact_changes_id",
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
        b.index AS change_index,
        b.value AS change_value,
        change_value :"type" :: STRING AS TYPE,
        change_value :"sender" :: STRING AS sender,
        change_value :"digest" :: STRING AS digest,
        change_value :"objectId" :: STRING AS object_id,
        change_value :"objectType" :: STRING AS object_type,
        change_value :"version" :BIGINT AS version,
        change_value :"previousVersion" :BIGINT AS previous_version,
        change_value :"owner" :"ObjectOwner" :: STRING AS object_owner,
    FROM
        {{ ref('silver__transactions') }} A,
        LATERAL FLATTEN(
            A.transaction_json :"objectChanges"
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
    change_index,
    TYPE,
    sender,
    digest,
    object_id,
    object_type,
    version,
    previous_version,
    object_owner,
    {{ dbt_utils.generate_surrogate_key(['tx_digest','change_index']) }} AS fact_changes_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    base
