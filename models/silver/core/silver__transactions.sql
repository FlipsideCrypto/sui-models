-- depends_on: {{ ref('bronze__transactions') }}
{{ config (
    materialized = "incremental",
    unique_key = "tx_digest",
    cluster_by = ['modified_timestamp::DATE','block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    tags = ['silver','core']
) }}

WITH bronze_txs AS (

    SELECT
        DATA :"checkpoint" :: bigint AS checkpoint_number,
        DATA :"digest" :: STRING AS tx_digest,
        TO_TIMESTAMP(
            DATA :"timestampMs"
        ) AS block_timestamp,
        partition_key,
        DATA AS transaction_json,
        _inserted_timestamp
    FROM

{% if is_incremental() %}
{{ ref('bronze__transactions') }}
WHERE
    DATA :error IS NULL
    AND _inserted_timestamp >= (
        SELECT
            COALESCE(MAX(_inserted_timestamp), '1900-01-01' :: TIMESTAMP) AS _inserted_timestamp
        FROM
            {{ this }})
        {% else %}
            {{ ref('bronze__transactions_FR') }}
        WHERE
            DATA :error IS NULL
        {% endif %}
    )
SELECT
    checkpoint_number,
    tx_digest,
    block_timestamp,
    partition_key,
    transaction_json,
    _inserted_timestamp,
    {{ dbt_utils.generate_surrogate_key(['checkpoint_number','tx_digest']) }} AS transactions_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    bronze_txs qualify ROW_NUMBER() over (
        PARTITION BY tx_digest
        ORDER BY
            _inserted_timestamp DESC
    ) = 1
