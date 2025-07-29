-- depends_on: {{ ref('core__fact_events') }}
{{ config (
    materialized = "incremental",
    unique_key = ["tx_digest", "event_index"],
    cluster_by = ['modified_timestamp::DATE','block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['scheduled_non_core']
) }}

WITH core_events AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        tx_sender,
        event_index,
        type,
        event_address,
        event_module,
        event_resource,
        transaction_module,
        parsed_json,
        modified_timestamp
    FROM
        {{ ref('core__fact_events') }}
    WHERE
{% if is_incremental() %}
        modified_timestamp >= (
            SELECT
                COALESCE(MAX(modified_timestamp), '1900-01-01'::TIMESTAMP) AS modified_timestamp
            FROM
                {{ this }}
        )
        AND
{% endif %}
        event_module IN (
            'cetus',
            'turbos',
            'bluefin',
            'flowx_clmm',
            'momentum',
            'obric',
            'magma'
        )
        -- limit to 30 days for dev
        AND block_timestamp >= sysdate() - interval '30 days'
),
swaps AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        tx_sender,
        event_index,
        type,
        event_module,
        event_resource,
        transaction_module,
        event_address AS platform_address,
        COALESCE(parsed_json:pool::STRING, parsed_json:pool_address::STRING, parsed_json:pool_id::STRING) AS pool_address,
        parsed_json:amount_in::NUMBER AS amount_in_raw,
        parsed_json:amount_out::NUMBER AS amount_out_raw,
        parsed_json:a2b::BOOLEAN AS a_to_b,
        parsed_json:fee_amount::NUMBER AS fee_amount_raw,
        parsed_json:partner_id::STRING AS partner_address,
        COALESCE(parsed_json:steps::NUMBER, 1) AS steps,
        IFF(
            parsed_json:a2b::BOOLEAN,
            parsed_json:coin_a:name::STRING,
            parsed_json:coin_b:name::STRING
        ) AS token_in_type,
        IFF(
            parsed_json:a2b::BOOLEAN,
            parsed_json:coin_b:name::STRING,
            parsed_json:coin_a:name::STRING
        ) AS token_out_type,
        tx_sender AS trader_address,
        modified_timestamp,
        parsed_json
    FROM core_events
)
SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    event_index,
    type,
    event_module,
    event_resource,
    platform_address,
    pool_address,
    amount_in_raw,
    amount_out_raw,
    a_to_b,
    fee_amount_raw,
    partner_address,
    steps,
    IFF(
        LEFT(token_in_type, 2) = '0x',
        token_in_type,
        '0x' || token_in_type
    ) AS token_in_type,
    IFF(
        LEFT(token_out_type, 2) = '0x',
        token_out_type,
        '0x' || token_out_type
    ) AS token_out_type,
    trader_address,
    parsed_json,
    {{ dbt_utils.generate_surrogate_key(['tx_digest', 'platform_address', 'trader_address', 'token_in_type', 'token_out_type', 'amount_in_raw', 'amount_out_raw']) }} AS dex_swaps_id,
    SYSDATE() AS inserted_timestamp,
    modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    swaps
