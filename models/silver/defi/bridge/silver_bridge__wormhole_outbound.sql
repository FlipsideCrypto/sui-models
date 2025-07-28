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
        tx_sender,
        parsed_json,
        CASE
            WHEN event_address = '0x5306f64e312b581766351c07af79c72fcb1cd25147157fdc2f8ad76de9a3fb6a' THEN TRUE
            ELSE FALSE
        END AS is_basic
    FROM
        sui.core.fact_events {# {{ ref('core__fact_events') }} #}
    WHERE
        tx_succeeded
        AND (
            (
                event_address = '0x5306f64e312b581766351c07af79c72fcb1cd25147157fdc2f8ad76de9a3fb6a'
                AND event_resource = 'WormholeMessage' {# AND block_timestamp :: DATE >= '2025-07-01' #}
            )
            OR (
                package_id = '0x2aa6c5d56376c371f88a6cc42e852824994993cb9bab8d3e6450cbe3cb32b94e'
                AND event_resource = 'DepositForBurn' {# AND block_timestamp :: DATE >= '2025-07-01' #}
            )
        )

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
        AND A.address_owner = b.tx_sender
    WHERE
        amount < 0
        AND coin_type <> '0x2::sui::SUI'
)
SELECT
    A.checkpoint_number,
    A.block_timestamp,
    A.tx_digest,
    A.tx_sender,
    A.event_index,
    0 AS source_chain,
    NULL AS destination_chain,
    COALESCE(
        -1 * bc.amount,
        C.parsed_json :amount :: INT
    ) AS amount,
    A.tx_sender AS source_address,
    NULL AS destination_address,
    bc.coin_type,
    '0x5306f64e312b581766351c07af79c72fcb1cd25147157fdc2f8ad76de9a3fb6a' AS bridge_address,
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
    LEFT JOIN wh_mess C
    ON A.tx_digest = C.tx_digest
    AND C.is_basic = FALSE
WHERE
    A.is_basic
