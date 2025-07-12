-- depends_on: {{ ref('bronze__checkpoints') }}
-- depends_on: {{ ref('bronze__checkpoints_FR') }}
{{ config (
    materialized = "incremental",
    unique_key = ['checkpoint_number'],
    merge_exclude_columns = ["inserted_timestamp"],
    cluster_by = "ROUND(checkpoint_number, -5)",
    tags = ['streamline_realtime'],
    post_hook = enable_search_optimization(
        '{{this.schema}}',
        '{{this.identifier}}',
        'ON EQUALITY(checkpoint_number)'
    ),
) }}

SELECT
    DATA :"result": "sequenceNumber" :: bigint AS checkpoint_number,
    TO_TIMESTAMP(
        DATA :"result" :"timestampMs"
    ) AS block_timestamp,
    DATA :"result": "transactions" AS transactions_array,
    ARRAY_SIZE(
        DATA :"result": "transactions"
    ) AS tx_count,
    partition_key,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    file_name,
    '{{ invocation_id }}' AS _invocation_id,
FROM

{% if is_incremental() %}
{{ ref('bronze__checkpoints') }}
{% else %}
    {{ ref('bronze__checkpoints_FR') }}
{% endif %}
WHERE
    DATA :error IS NULL

{% if is_incremental() %}
AND _inserted_timestamp >= (
    SELECT
        COALESCE(MAX(_INSERTED_TIMESTAMP), '1970-01-01' :: DATE) max_INSERTED_TIMESTAMP
    FROM
        {{ this }})
    {% endif %}

    qualify ROW_NUMBER() over (
        PARTITION BY checkpoint_number
        ORDER BY
            _inserted_timestamp DESC
    ) = 1
