-- depends_on: {{ ref('bronze__transactions') }}
-- depends_on: {{ ref('bronze__transactions_FR') }}
{{ config (
    materialized = "incremental",
    unique_key = ['tx_digest'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    cluster_by = "block_timestamp::DATE",
    tags = ['streamline_realtime'],
    post_hook = enable_search_optimization(
        '{{this.schema}}',
        '{{this.identifier}}',
        'ON EQUALITY(tx_digest)'
    ),
) }}

SELECT
    DATA :"checkpoint" :: bigint AS checkpoint_number,
    DATA :"digest" :: STRING AS tx_digest,
    TO_TIMESTAMP(
        DATA :"timestampMs"
    ) AS block_timestamp,
    partition_key,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    file_name,
    '{{ invocation_id }}' AS _invocation_id,
FROM

{% if is_incremental() %}
{{ ref('bronze__transactions') }}
{% else %}
    {{ ref('bronze__transactions_FR') }}
{% endif %}
WHERE
    DATA :error IS NULL
    AND block_timestamp IS NOT NULL

{% if is_incremental() %}
AND _inserted_timestamp >= (
    SELECT
        COALESCE(MAX(_INSERTED_TIMESTAMP), '1970-01-01' :: DATE) max_INSERTED_TIMESTAMP
    FROM
        {{ this }})
    {% endif %}

    qualify ROW_NUMBER() over (
        PARTITION BY tx_digest
        ORDER BY
            _inserted_timestamp DESC
    ) = 1
