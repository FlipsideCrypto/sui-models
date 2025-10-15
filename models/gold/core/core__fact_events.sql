{{ config (
    materialized = "incremental",
    unique_key = "fact_events_id",
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
        b.value AS event_value,
        event_value :"id" :"eventSeq" :: INT AS event_index,
        event_value :"packageId" :: STRING AS package_id,
        event_value :"transactionModule" :: STRING AS transaction_module,
        event_value :"sender" :: STRING AS sender,
        event_value :"type" :: STRING AS TYPE,
        event_value :"parsedJson" AS parsed_json
    FROM
        {{ ref('silver__transactions') }} A,
        LATERAL FLATTEN(
            A.transaction_json :"events"
        ) b

{% if is_incremental() %}
WHERE
    modified_timestamp >= (
        SELECT
            COALESCE(MAX(modified_timestamp), '1970-01-01' :: TIMESTAMP) AS modified_timestamp
        FROM
            {{ this }})
        {% endif %}

{% if is_incremental() %}
{% else %}
    UNION ALL
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        tx_kind,
        tx_sender,
        message_version,
        tx_succeeded,
        NULL AS event_value,
        event_index,
        package_id,
        transaction_module,
        sender,
        TYPE,
        parsed_json
    FROM
        {{ ref('silver__events_backfill') }} A
        JOIN {{ ref('silver__transaction_blocks_backfill') }}
        b USING (
            checkpoint_number,
            tx_digest
        )
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
    event_index,
    TYPE,
    SPLIT_PART(
        TYPE,
        '::',
        1
    ) AS event_address,
    SPLIT_PART(
        TYPE,
        '::',
        2
    ) AS event_module,
    REPLACE(
        TYPE,
        event_address || '::' || event_module || '::'
    ) AS event_resource,
    package_id,
    transaction_module,
    sender,
    parsed_json,
    {{ dbt_utils.generate_surrogate_key(['tx_digest','event_index']) }} AS fact_events_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    base
