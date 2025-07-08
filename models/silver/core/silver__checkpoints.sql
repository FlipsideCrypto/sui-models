-- depends_on: {{ ref('bronze__checkpoints') }}
{{ config (
    materialized = "incremental",
    unique_key = "checkpoint_number",
    cluster_by = ['modified_timestamp::DATE','block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    tags = ['silver','core']
) }}

WITH bronze_checks AS (

    SELECT
        DATA :"result" :"sequenceNumber" :: bigint AS checkpoint_number,
        TO_TIMESTAMP(
            DATA :"result" :"timestampMs"
        ) AS block_timestamp,
        partition_key,
        DATA :result AS checkpoint_json,
        _inserted_timestamp
    FROM

{% if is_incremental() %}
{{ ref('bronze__checkpoints') }}
WHERE
    _inserted_timestamp >= (
        SELECT
            COALESCE(MAX(_inserted_timestamp), '1900-01-01' :: TIMESTAMP) AS _inserted_timestamp
        FROM
            {{ this }})
        {% else %}
            {{ ref('bronze__checkpoints_FR') }}
        {% endif %}
    )
SELECT
    checkpoint_number,
    block_timestamp,
    partition_key,
    checkpoint_json,
    _inserted_timestamp,
    {{ dbt_utils.generate_surrogate_key(['checkpoint_number']) }} AS checkpoints_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    bronze_checks qualify ROW_NUMBER() over (
        PARTITION BY checkpoint_number
        ORDER BY
            _inserted_timestamp DESC
    ) = 1
