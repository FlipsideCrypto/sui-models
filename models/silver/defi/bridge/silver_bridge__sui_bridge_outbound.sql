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

WITH base_events AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        tx_sender,
        event_index,
        parsed_json,
        modified_timestamp
    FROM
        {{ ref('core__fact_events') }}
    WHERE
        tx_succeeded
        AND event_address = '0x000000000000000000000000000000000000000000000000000000000000000b'
        AND event_resource = 'TokenDepositedEvent' {# AND block_timestamp :: DATE >= '2025-07-01' #}

{% if is_incremental() %}
AND modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}
),
deposits_base AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        tx_sender,
        event_index,
        '0x' || LISTAGG(
            CASE
                WHEN s.value :: INTEGER = 0 THEN '00'
                WHEN s.value :: INTEGER < 16 THEN '0' || SUBSTR(
                    '0123456789abcdef',
                    s.value :: INTEGER + 1,
                    1
                )
                ELSE SUBSTR('0123456789abcdef', FLOOR(s.value :: INTEGER / 16) + 1, 1) || SUBSTR('0123456789abcdef', MOD(s.value :: INTEGER, 16) + 1, 1)
            END,
            ''
        ) within GROUP (
            ORDER BY
                s.index
        ) AS sender_address,
        parsed_json :source_chain :: INT AS source_chain,
        parsed_json :target_chain :: INT AS target_chain,
        parsed_json :token_type :: STRING AS token_type,
        parsed_json :amount :: bigint AS amount,
        parsed_json :seq_num :: INT AS seq_num,
        modified_timestamp
    FROM
        base_events e,
        LATERAL FLATTEN(
            input => e.parsed_json :sender_address
        ) s
    GROUP BY
        ALL
),
deposits_target AS (
    SELECT
        tx_digest,
        event_index,
        '0x' || LISTAGG(
            CASE
                WHEN s.value :: INTEGER = 0 THEN '00'
                WHEN s.value :: INTEGER < 16 THEN '0' || SUBSTR(
                    '0123456789abcdef',
                    s.value :: INTEGER + 1,
                    1
                )
                ELSE SUBSTR('0123456789abcdef', FLOOR(s.value :: INTEGER / 16) + 1, 1) || SUBSTR('0123456789abcdef', MOD(s.value :: INTEGER, 16) + 1, 1)
            END,
            ''
        ) within GROUP (
            ORDER BY
                s.index
        ) AS target_address
    FROM
        base_events e,
        LATERAL FLATTEN(
            input => e.parsed_json :target_address
        ) s
    GROUP BY
        ALL
),
bc AS (
    SELECT
        A.tx_digest,
        b.event_index,
        A.coin_type
    FROM
        {{ ref('core__fact_balance_changes') }} A
        JOIN deposits_base b
        ON A.tx_digest = b.tx_digest
        AND A.address_owner = b.sender_address
        AND - A.amount = b.amount

{% if is_incremental() %}
WHERE
    A.block_timestamp :: DATE :: DATE >= '{{ min_bid }}'
{% endif %}
)
SELECT
    A.checkpoint_number,
    A.block_timestamp,
    A.tx_digest,
    A.tx_sender,
    A.event_index,
    A.source_chain,
    A.target_chain AS destination_chain,
    A.amount,
    A.sender_address AS source_address,
    b.target_address AS destination_address,
    bc.coin_type,
    '0x000000000000000000000000000000000000000000000000000000000000000b' AS bridge_address,
    {{ dbt_utils.generate_surrogate_key(['tx_digest']) }} AS sui_bridge_outbound_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    deposits_base A
    JOIN deposits_target b USING (
        tx_digest,
        event_index
    )
    JOIN bc USING (
        tx_digest,
        event_index
    )
