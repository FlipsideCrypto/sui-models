-- depends_on: {{ ref('core__fact_events') }}
{{ config (
    materialized = "incremental",
    unique_key = "dex_swaps_id",
    cluster_by = ['modified_timestamp::DATE','block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['scheduled_non_core']
) }}

-- TODO: use front matter IF EXECUTE block to set blockdate for table scans due to ongoing backfill

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
        package_id,
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
            event_resource ILIKE '%swap%'
            -- Haedal
            OR event_resource ILIKE '%buy%'
            OR event_resource ILIKE '%sell%'
            OR event_resource IN (
                'Swap',
                'OrderFilled',
                'TradeEvent'
            )
        )
        -- edge cases that are not swaps
        AND event_resource NOT IN (
            'RepayFlashSwapEvent'
        )
        AND event_resource NOT ILIKE '%bondingcurve%'

        -- limit to 30 days for dev
        AND block_timestamp >= sysdate() - interval '30 days'
),
core_transactions AS (
    SELECT
        tx_digest,
        payload_index,
        payload_details:function::string as function,
        payload_details:module::string as module,
        payload_details:package::string as package,
        payload_details:type_arguments::ARRAY as type_arguments,
        payload_details,
        row_number() over (partition by tx_digest, package, module order by payload_index) as package_index
    FROM
        {{ ref('core__fact_transactions') }}
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
    date_trunc('day', block_timestamp) >= (SELECT MIN(date_trunc('day', block_timestamp)) FROM core_events)
    AND tx_digest IN (SELECT DISTINCT tx_digest FROM core_events)
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
        package_id,
        transaction_module,
        ROW_NUMBER() OVER (PARTITION BY tx_digest, package_id, transaction_module ORDER BY event_index) AS package_index,
        event_address AS platform_address,
        COALESCE(
            parsed_json:pool::STRING, 
            parsed_json:pool_address::STRING, 
            parsed_json:pool_id::STRING
        ) AS pool_address,

        -- Handle different direction field patterns
        COALESCE(
            parsed_json:a2b::BOOLEAN,
            parsed_json:a_to_b::BOOLEAN,
            parsed_json:atob::BOOLEAN,
            parsed_json:x_for_y::BOOLEAN,
            parsed_json:event:a2b::BOOLEAN
        ) AS a_to_b,

        -- Token In - handle different event patterns
        COALESCE(
            IFF(a_to_b,
                COALESCE(
                    parsed_json:amount_in::NUMBER,
                    parsed_json:amount_a::NUMBER,
                    parsed_json:amount_x::NUMBER,
                    parsed_json:event:amount_in::NUMBER,
                    parsed_json:coin_in_amount::NUMBER
                ),
                COALESCE(
                    parsed_json:amount_in::NUMBER,
                    parsed_json:amount_b::NUMBER,
                    parsed_json:amount_y::NUMBER,
                    parsed_json:event:amount_in::NUMBER,
                    parsed_json:coin_in_amount::NUMBER
                )
            ),
            -- Haedal-style events
            parsed_json:pay_quote::NUMBER,
            parsed_json:pay_base::NUMBER
        ) AS amount_in_raw,
        IFF(a_to_b,
            COALESCE(
                parsed_json:coin_a:name::STRING,
                parsed_json:coin_in:name::STRING,
                parsed_json:coin_in::STRING,
                parsed_json:type_in::STRING,
                parsed_json:event:coin_in::STRING,
                parsed_json:coin_in_type:name::STRING
            ),
            COALESCE(
                parsed_json:coin_b:name::STRING,
                parsed_json:coin_in:name::STRING,
                parsed_json:coin_in::STRING,
                parsed_json:type_in::STRING,
                parsed_json:event:coin_in::STRING,
                parsed_json:coin_in_type:name::STRING
            )
        ) AS token_in_type,
        -- Token Out - handle different event patterns
        COALESCE(
            IFF(a_to_b,
                COALESCE(
                    parsed_json:amount_out::NUMBER,
                    parsed_json:amount_b::NUMBER,
                    parsed_json:amount_y::NUMBER,
                    parsed_json:event:amount_out::NUMBER,
                    parsed_json:coin_out_amount::NUMBER
                ),
                COALESCE(
                    parsed_json:amount_out::NUMBER,
                    parsed_json:amount_a::NUMBER,
                    parsed_json:amount_x::NUMBER,
                    parsed_json:event:amount_out::NUMBER,
                    parsed_json:coin_out_amount::NUMBER
                )
            ),
            -- Haedal-style events
            parsed_json:receive_base::NUMBER,
            parsed_json:receive_quote::NUMBER
        ) AS amount_out_raw,
        IFF(a_to_b,
            COALESCE(
                parsed_json:coin_b:name::STRING,
                parsed_json:coin_out:name::STRING,
                parsed_json:coin_out::STRING,
                parsed_json:type_out::STRING,
                parsed_json:event:coin_out::STRING,
                parsed_json:coin_out_type:name::STRING
            ),
            COALESCE(
                parsed_json:coin_a:name::STRING,
                parsed_json:coin_out:name::STRING,
                parsed_json:coin_out::STRING,
                parsed_json:type_out::STRING,
                parsed_json:event:coin_out::STRING,
                parsed_json:coin_out_type:name::STRING
            )
        ) AS token_out_type,

        COALESCE(
            parsed_json:fee_amount::NUMBER,
            parsed_json:protocol_fee_amount::NUMBER,
            parsed_json:protocol_fee::NUMBER
        ) AS fee_amount_raw,

        COALESCE(
            parsed_json:partner_id::STRING,
            parsed_json:partner::STRING
        ) AS partner_address,
        COALESCE(parsed_json:steps::NUMBER, 1) AS steps,

        tx_sender AS trader_address,
        modified_timestamp,
        parsed_json
    FROM core_events
),

append_transaction_data AS (
    SELECT
        s.checkpoint_number,
        s.block_timestamp,
        s.tx_digest,
        s.event_index,
        s.type,
        s.event_module,
        s.package_id,
        s.package_index,
        s.transaction_module,
        s.event_resource,
        s.platform_address,
        s.trader_address,
        s.pool_address,
        s.amount_in_raw,
        COALESCE(
            s.token_in_type,
            IFF(a_to_b,
                t.type_arguments[0] :: STRING,
                t.type_arguments[1] :: STRING
            ),
            -- For Haedal BuyBaseTokenEvent: paying quote token (index 1)
            CASE 
                WHEN s.event_resource = 'BuyBaseTokenEvent' THEN t.type_arguments[1] :: STRING
                WHEN s.event_resource = 'SellQuoteTokenEvent' THEN t.type_arguments[0] :: STRING
            END
        ) AS token_in_type,
        s.amount_out_raw,
        COALESCE(
            s.token_out_type,
            IFF(a_to_b,
                t.type_arguments[1] :: STRING,
                t.type_arguments[0] :: STRING
            ),
            -- For Haedal BuyBaseTokenEvent: receiving base token (index 0)
            CASE 
                WHEN s.event_resource = 'BuyBaseTokenEvent' THEN t.type_arguments[0] :: STRING
                WHEN s.event_resource = 'SellQuoteTokenEvent' THEN t.type_arguments[1] :: STRING
            END
        ) AS token_out_type,
        s.a_to_b,
        s.fee_amount_raw,
        s.partner_address,
        s.steps,
        s.parsed_json,
        s.modified_timestamp
    FROM
        swaps s
        LEFT JOIN core_transactions t
            ON s.tx_digest = t.tx_digest
            AND s.package_id = t.package
            AND s.transaction_module = t.module
            AND s.package_index = t.package_index
)
SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    event_index,
    type,
    event_module,
    package_id,
    transaction_module,
    event_resource,
    platform_address,
    trader_address,
    pool_address,
    amount_in_raw,
    IFF(
        LEFT(token_in_type, 2) = '0x',
        token_in_type,
        '0x' || token_in_type
    ) AS token_in_type,
    amount_out_raw,
    IFF(
        LEFT(token_out_type, 2) = '0x',
        token_out_type,
        '0x' || token_out_type
    ) AS token_out_type,
    a_to_b,
    fee_amount_raw,
    partner_address,
    steps,
    ROW_NUMBER() OVER (PARTITION BY tx_digest ORDER BY event_index) AS swap_index,
    package_index,
    parsed_json,
    {{ dbt_utils.generate_surrogate_key(['tx_digest', 'trader_address', 'token_in_type', 'token_out_type', 'amount_in_raw', 'amount_out_raw']) }} AS dex_swaps_id,
    SYSDATE() AS inserted_timestamp,
    modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    append_transaction_data

qualify row_number() over (
    partition by tx_digest, token_in_type, token_out_type, amount_in_raw, amount_out_raw
    order by token_in_type IS NOT NULL DESC, token_out_type IS NOT NULL DESC
    ) = 1
