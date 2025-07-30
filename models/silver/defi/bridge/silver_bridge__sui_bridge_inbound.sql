-- depends_on: {{ ref('bronze__checkpoints') }}
{{ config (
    materialized = "incremental",
    unique_key = "tx_digest",
    cluster_by = ['modified_timestamp::DATE','block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['silver','defi','non_core']
) }}

{% if execute %}

{% if is_incremental() %}
{% set min_bd_query %}

SELECT
    MIN(
        block_timestamp :: DATE
    )
FROM
    {{ ref('core__fact_events') }}
WHERE
    modified_timestamp >= (
        SELECT
            MAX(modified_timestamp)
        FROM
            {{ this }}
    ) {% endset %}
    {% set min_bd = run_query(min_bd_query) [0] [0] %}
{% endif %}
{% endif %}

WITH claims AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        event_index,
        tx_sender,
        parsed_json :message_key :source_chain :: INT AS source_chain,
    FROM
        {{ ref('core__fact_events') }}
    WHERE
        tx_succeeded
        AND event_address = '0x000000000000000000000000000000000000000000000000000000000000000b'
        AND event_resource = 'TokenTransferClaimed' {# AND block_timestamp :: DATE >= '2025-07-01' #}

{% if is_incremental() %}
AND modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}
),
bc AS (
    SELECT
        A.tx_digest,
        b.event_index,
        A.coin_type,
        A.amount,
        A.address_owner
    FROM
        {{ ref('core__fact_balance_changes') }} A
        JOIN claims b
        ON A.tx_digest = b.tx_digest
    WHERE
        A.address_owner <> A.tx_sender
        AND amount > 0

{% if is_incremental() %}
AND A.block_timestamp :: DATE :: DATE >= '{{ min_bd }}'
{% endif %}
)
SELECT
    A.checkpoint_number,
    A.block_timestamp,
    A.tx_digest,
    A.tx_sender,
    A.event_index,
    A.source_chain,
    0 AS destination_chain,
    bc.amount,
    NULL :: STRING AS source_address,
    bc.address_owner AS destination_address,
    bc.coin_type,
    '0x000000000000000000000000000000000000000000000000000000000000000b' AS bridge_address,
    {{ dbt_utils.generate_surrogate_key(['tx_digest']) }} AS sui_bridge_inbound_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    claims A
    JOIN bc USING (
        tx_digest,
        event_index
    )
