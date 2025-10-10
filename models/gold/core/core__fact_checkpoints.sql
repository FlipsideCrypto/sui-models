{{ config (
    materialized = "incremental",
    unique_key = "checkpoint_number",
    cluster_by = ['block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gold','core']
) }}

SELECT
    checkpoint_number,
    block_timestamp,
    checkpoint_json :"epoch" :: INT AS epoch,
    checkpoint_json :"digest" :: STRING AS checkpoint_digest,
    checkpoint_json :"previousDigest" :: STRING AS previous_digest,
    checkpoint_json :"networkTotalTransactions" :: bigint AS network_total_transactions,
    checkpoint_json :"validatorSignature" :: STRING AS validator_signature,
    ARRAY_SIZE(
        checkpoint_json :"transactions"
    ) AS tx_count,
    checkpoint_json :"transactions" AS transactions_array,
    {{ dbt_utils.generate_surrogate_key(['checkpoint_number']) }} AS fact_checkpoints_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    {{ ref('silver__checkpoints') }}

{% if is_incremental() %}
WHERE
    modified_timestamp >= (
        SELECT
            COALESCE(MAX(modified_timestamp), '1970-01-01' :: TIMESTAMP) AS modified_timestamp
        FROM
            {{ this }})
        {% endif %}

        {# {% if is_incremental() %}
        {% else %}
            #}
        UNION ALL
        SELECT
            checkpoint_number,
            block_timestamp,
            epoch,
            checkpoint_digest,
            previous_digest,
            network_total_transactions,
            validator_signature,
            tx_count,
            ARRAY_CONSTRUCT() AS transactions_array,
            {{ dbt_utils.generate_surrogate_key(['checkpoint_number']) }} AS fact_checkpoints_id,
            SYSDATE() AS inserted_timestamp,
            SYSDATE() AS modified_timestamp
        FROM
            {{ ref('silver__checkpoints_b') }}
            {# {% endif %} #}
