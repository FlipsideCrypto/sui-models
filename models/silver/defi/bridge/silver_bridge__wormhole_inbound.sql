-- depends_on: {{ ref('bronze__checkpoints') }}
{{ config (
    materialized = "incremental",
    unique_key = "tx_digest",
    cluster_by = ['modified_timestamp::DATE','block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['silver','defi','non_core']
) }}

WITH wh_mess AS (

    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        event_index,
        tx_sender
    FROM
        sui.core.fact_events {# {{ ref('core__fact_events') }} #}
    WHERE
        tx_succeeded
        AND event_address = '0x26efee2b51c911237888e5dc6702868abca3c7ac12c53f76ef8eba0697695e3d'
        AND event_resource = 'TransferRedeemed' {# AND block_timestamp :: DATE >= '2025-07-01' #}

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
        A.amount
    FROM
        sui.core.fact_balance_changes {# {{ ref('core__fact_balance_changes') }} #}  A
        JOIN wh_mess b
        ON A.tx_digest = b.tx_digest
    WHERE
        amount > 0
        AND A.address_owner = A.tx_sender
)
SELECT
    A.checkpoint_number,
    A.block_timestamp,
    A.tx_digest,
    A.tx_sender,
    A.event_index,
    NULL AS source_chain,
    0 AS destination_chain,
    bc.amount AS amount,
    NULL AS source_address,
    A.tx_sender AS destination_address,
    bc.coin_type,
    '0x26efee2b51c911237888e5dc6702868abca3c7ac12c53f76ef8eba0697695e3d' AS bridge_address,
    {{ dbt_utils.generate_surrogate_key(['a.tx_digest']) }} AS wormhole_outbound_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    wh_mess A
    JOIN bc USING (
        tx_digest,
        event_index
    )
