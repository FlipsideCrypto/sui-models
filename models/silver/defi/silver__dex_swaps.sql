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
        (
            type = '0xeffc8ae61f439bb34c9b905ff8f29ec56873dcedf81c7123ff2f1f67c45ec302::cetus::CetusSwapEvent' -- Cetus
            OR type = '0x91bfbc386a41afcfd9b2533058d7e915a1d3829089cc268ff4333d54d6339ca1::pool::SwapEvent' -- Turbos
            OR type = '0x3b6d71bdeb8ce5b06febfd3cfc29ecd60d50da729477c8b8038ecdae34541b91::bluefin::BluefinSwapEvent' -- Bluefin
            OR type = '0xd675e6d727bb2d63087cc12008bb91e399dc7570100f72051993ec10c0428f4a::events::SwapCompletedEventV2' -- Aftermath AMM
            OR type = '0x25929e7f29e0a30eb4e692952ba1b5b65a3a4d65ab5f2a32e1ba3edcb587f26d::pool::Swap' -- FlowX
            OR type = '0xe8f996ea6ff38c557c253d3b93cfe2ebf393816487266786371aa4532a9229f2::settle::Swap' -- DeepBook
            OR type = '0x0018f7bbbece22f4272ed2281b290f745e5aa69d870f599810a30b4eeffc1a5e::momentum::MomentumSwapEvent' -- Momentum
            OR type = '0x200e762fa2c49f3dc150813038fbf22fd4f894ac6f23ebe1085c62f2ef97f1ca::obric::ObricSwapEvent' -- OBRIC
        )
        -- limit to 30 days for dev
        AND block_timestamp >= sysdate() - interval '30 days'
),

fact_transactions AS (
    -- At least flowx requires token type from the transaction payload
    SELECT
        tx_digest,
        payload_index,
        payload_details
    FROM
        {{ ref('core__fact_transactions') }}
    WHERE
        payload_type = 'MoveCall'
        AND payload_details:type_arguments IS NOT NULL
{% if is_incremental() %}
        AND modified_timestamp >= (
            SELECT
                COALESCE(MAX(modified_timestamp), '1900-01-01'::TIMESTAMP) AS modified_timestamp
            FROM
                {{ this }}
        )
{% endif %}
    -- limit to 30 days for dev
    AND block_timestamp >= sysdate() - interval '30 days'
),

cetus_swaps AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        event_index,
        'Cetus' AS platform,
        event_address AS platform_address,
        parsed_json:pool::STRING AS pool_address,
        parsed_json:amount_in::NUMBER AS amount_in_raw,
        parsed_json:amount_out::NUMBER AS amount_out_raw,
        parsed_json:a2b::BOOLEAN AS a_to_b,
        parsed_json:fee_amount::NUMBER AS fee_amount_raw,
        parsed_json:partner_id::STRING AS partner_address,
        NULL AS referral_amount_raw,
        parsed_json:steps::NUMBER AS steps,
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
        transaction_module,
        modified_timestamp
    FROM core_events
    WHERE type = '0xeffc8ae61f439bb34c9b905ff8f29ec56873dcedf81c7123ff2f1f67c45ec302::cetus::CetusSwapEvent'
        AND transaction_module = 'cetus'
),

turbos_swaps AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        event_index,
        'Turbos' AS platform,
        event_address AS platform_address,
        parsed_json:pool::STRING AS pool_address,
        parsed_json:amount_in::NUMBER AS amount_in_raw,
        parsed_json:amount_out::NUMBER AS amount_out_raw,
        parsed_json:a_to_b::BOOLEAN AS a_to_b,
        parsed_json:fee_amount::NUMBER AS fee_amount_raw,
        NULL AS partner_address,
        NULL AS referral_amount_raw,
        1 AS steps,
        IFF(
            parsed_json:a_to_b::BOOLEAN,
            parsed_json:coin_a:name::STRING,
            parsed_json:coin_b:name::STRING
        ) AS token_in_type,
        IFF(
            parsed_json:a_to_b::BOOLEAN,
            parsed_json:coin_b:name::STRING,
            parsed_json:coin_a:name::STRING
        ) AS token_out_type,
        tx_sender AS trader_address,
        transaction_module,
        modified_timestamp
    FROM core_events
    WHERE type = '0x91bfbc386a41afcfd9b2533058d7e915a1d3829089cc268ff4333d54d6339ca1::pool::SwapEvent'
        AND transaction_module = 'turbos'
),

bluefin_swaps AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        event_index,
        'Bluefin' AS platform,
        event_address AS platform_address,
        parsed_json:pool::STRING AS pool_address,
        parsed_json:amount_in::NUMBER AS amount_in_raw,
        parsed_json:amount_out::NUMBER AS amount_out_raw,
        parsed_json:a2b::BOOLEAN AS a_to_b,
        NULL AS fee_amount_raw,
        NULL AS partner_address,
        NULL AS referral_amount_raw,
        1 AS steps,
        IFF(
            parsed_json:a2b::BOOLEAN,
            parsed_json:coin_a:name::STRING,
            parsed_json:coin_b:name::STRING
        )::STRING AS token_in_type,
        IFF(
            parsed_json:a2b::BOOLEAN,
            parsed_json:coin_b:name::STRING,
            parsed_json:coin_a:name::STRING
        )::STRING AS token_out_type,
        tx_sender AS trader_address,
        transaction_module,
        modified_timestamp
    FROM core_events
    WHERE type = '0x3b6d71bdeb8ce5b06febfd3cfc29ecd60d50da729477c8b8038ecdae34541b91::bluefin::BluefinSwapEvent'
),

aftermath_amm_swaps AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        event_index,
        'Aftermath AMM' AS platform,
        event_address AS platform_address,
        NULL AS pool_address,
        parsed_json:amount_in::NUMBER AS amount_in_raw,
        parsed_json:amount_out::NUMBER AS amount_out_raw,
        NULL AS a_to_b,
        parsed_json:router_fee::NUMBER AS fee_amount_raw,
        parsed_json:referrer::STRING AS partner_address, -- or router_fee_recipient?
        parsed_json:router_fee::NUMBER AS referral_amount_raw, -- router vs referrer?
        1 AS steps,
        parsed_json:type_in::STRING AS token_in_type,
        parsed_json:type_out::STRING AS token_out_type,
        parsed_json:swapper::STRING AS trader_address,
        transaction_module,
        modified_timestamp
    FROM core_events
    WHERE type = '0xd675e6d727bb2d63087cc12008bb91e399dc7570100f72051993ec10c0428f4a::events::SwapCompletedEventV2'
),

flowx_swaps AS (
    SELECT
        e.checkpoint_number,
        e.block_timestamp,
        e.tx_digest,
        e.event_index,
        'FlowX' AS platform,
        e.event_address AS platform_address,
        e.parsed_json:pool_id::STRING AS pool_address,
        -- FlowX uses amount_x/amount_y with x_for_y direction flag
        IFF(
            parsed_json:x_for_y::BOOLEAN,
            parsed_json:amount_x::NUMBER,
            parsed_json:amount_y::NUMBER
        ) AS amount_in_raw,
        IFF(
            parsed_json:x_for_y::BOOLEAN,
            parsed_json:amount_y::NUMBER,
            parsed_json:amount_x::NUMBER
        ) AS amount_out_raw,
        e.parsed_json:x_for_y::BOOLEAN AS a_to_b,
        e.parsed_json:fee_amount::NUMBER AS fee_amount_raw,
        NULL AS partner_address,
        NULL AS referral_amount_raw,
        1 AS steps,
        -- Token types based on swap direction
        IFF(
            e.parsed_json:x_for_y::BOOLEAN,
            tx.payload_details:type_arguments[0]::STRING,
            tx.payload_details:type_arguments[1]::STRING
        ) AS token_in_type,
        IFF(
            e.parsed_json:x_for_y::BOOLEAN,
            tx.payload_details:type_arguments[1]::STRING,
            tx.payload_details:type_arguments[0]::STRING
        ) AS token_out_type,
        e.parsed_json:sender::STRING AS trader_address,
        e.transaction_module,
        e.modified_timestamp
    FROM core_events e
    LEFT JOIN fact_transactions tx ON e.tx_digest = tx.tx_digest 
        AND tx.payload_details:module::STRING = 'flowx_clmm'
    WHERE e.type = '0x25929e7f29e0a30eb4e692952ba1b5b65a3a4d65ab5f2a32e1ba3edcb587f26d::pool::Swap'
        AND e.transaction_module = 'flowx_clmm'
),

deepbook_swaps AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        event_index,
        'DeepBook' AS platform,
        event_address AS platform_address,
        NULL AS pool_address,
        parsed_json:amount_in::NUMBER AS amount_in_raw,
        parsed_json:amount_out::NUMBER AS amount_out_raw,
        NULL AS a_to_b,
        parsed_json:fee_amount_protocol::NUMBER AS fee_amount_raw,
        parsed_json:partner::STRING AS partner_address,
        parsed_json:fee_amount_partner::NUMBER AS referral_amount_raw,
        1 AS steps,
        parsed_json:coin_in:name::STRING AS token_in_type,
        parsed_json:coin_out:name::STRING AS token_out_type,
        parsed_json:sender::STRING AS trader_address,
        transaction_module,
        modified_timestamp
    FROM core_events
    WHERE type = '0xe8f996ea6ff38c557c253d3b93cfe2ebf393816487266786371aa4532a9229f2::settle::Swap'
),

momentum_swaps AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        event_index,
        'Momentum' AS platform,
        event_address AS platform_address,
        parsed_json:pool::STRING AS pool_address,
        parsed_json:amount_in::NUMBER AS amount_in_raw,
        parsed_json:amount_out::NUMBER AS amount_out_raw,
        parsed_json:a2b::BOOLEAN AS a_to_b,
        NULL AS fee_amount_raw,
        NULL AS partner_address,
        NULL AS referral_amount_raw,
        1 AS steps,
        -- Token types are in coin_a.name and coin_b.name fields, need 0x prefix for price matching
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
        transaction_module,
        modified_timestamp
    FROM core_events
    WHERE type = '0x0018f7bbbece22f4272ed2281b290f745e5aa69d870f599810a30b4eeffc1a5e::momentum::MomentumSwapEvent'
),

obric_swaps AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        event_index,
        'OBRIC' AS platform,
        event_address AS platform_address,
        parsed_json:pool_id::STRING AS pool_address,
        parsed_json:amount_in::NUMBER AS amount_in_raw,
        parsed_json:amount_out::NUMBER AS amount_out_raw,
        parsed_json:a2b::BOOLEAN AS a_to_b,
        NULL AS fee_amount_raw,
        NULL AS partner_address,
        NULL AS referral_amount_raw,
        1 AS steps,
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
        transaction_module,
        modified_timestamp
    FROM core_events
    WHERE type = '0x200e762fa2c49f3dc150813038fbf22fd4f894ac6f23ebe1085c62f2ef97f1ca::obric::ObricSwapEvent'
),

all_swaps AS (
    SELECT * FROM cetus_swaps
    UNION ALL
    SELECT * FROM turbos_swaps
    UNION ALL
    SELECT * FROM bluefin_swaps
    UNION ALL
    SELECT * FROM aftermath_amm_swaps
    UNION ALL
    SELECT * FROM flowx_swaps
    UNION ALL
    SELECT * FROM deepbook_swaps
    UNION ALL
    SELECT * FROM momentum_swaps
    UNION ALL
    SELECT * FROM obric_swaps
)

SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    event_index,
    platform,
    platform_address,
    pool_address,
    amount_in_raw,
    amount_out_raw,
    a_to_b,
    fee_amount_raw,
    partner_address,
    referral_amount_raw,
    steps,
    token_in_type,
    token_out_type,
    trader_address,
    transaction_module,
    {{ dbt_utils.generate_surrogate_key(['tx_digest', 'platform_address', 'trader_address', 'token_in_type', 'token_out_type', 'amount_in_raw', 'amount_out_raw']) }} AS dex_swaps_id,
    SYSDATE() AS inserted_timestamp,
    modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    all_swaps