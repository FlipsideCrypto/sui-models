{{ config (
    materialized = "incremental",
    unique_key = ['tx_digest'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    cluster_by = "block_timestamp::DATE",
    tags = ['streamline_realtime']
) }}

SELECT
    checkpoint_number,
    block_timestamp,
    b.index AS tx_index,
    b.value :: STRING AS tx_digest,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id,
FROM
    {{ ref("streamline__checkpoints_complete") }},
    LATERAL FLATTEN(
        transactions_array
    ) b

{% if is_incremental() %}
WHERE
    modified_timestamp >= (
        SELECT
            COALESCE(MAX(modified_timestamp), '1970-01-01' :: DATE) modified_timestamp
        FROM
            {{ this }})
        {% endif %}
