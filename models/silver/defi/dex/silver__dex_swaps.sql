-- depends_on: {{ ref('core__fact_events') }}
{{ config (
    materialized = "incremental",
    unique_key = "dex_swaps_id",
    cluster_by = ['modified_timestamp::DATE','block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['non_core']
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
            -- primary swap resources for this model use SwapEvent or PLATFORMSwapEvent
            -- Haedal-specific resources uses buy and sell
            event_resource ILIKE ANY ('%swapevent%', '%buy%', '%sell%')
            OR event_resource IN (
                'Swap',
                'OrderFilled',
                'TradeEvent',
                'SwapEvent'
            )
        )
        -- exclude modules that require special handling
        AND event_resource NOT IN (
            'RepayFlashSwapEvent',
            'ScallopSwapEvent',
            'OrderFilled',
            'OrderInfo'
        )
        AND transaction_module NOT IN (
            'aftermath', 
            'scallop',
            'fulfill_swap',
            'slippage'
        )
        AND transaction_module NOT ILIKE '%steamm%'

        -- exclude limit orders from base model
        AND event_module NOT IN ('settle')
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
        block_timestamp :: DATE >= (
            SELECT
                COALESCE(MAX(block_timestamp :: DATE), '1900-01-01'::DATE) AS block_timestamp
            FROM
                {{ this }}
        )
        AND
{% endif %}
    tx_digest IN (SELECT DISTINCT tx_digest FROM core_events)
    AND typeof(payload_details) != 'ARRAY'
    AND ARRAY_CONTAINS('type_arguments' :: VARIANT, OBJECT_KEYS(payload_details))
    AND function NOT ILIKE '%repay%'
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
            parsed_json:pool_id::STRING,
            parsed_json:event:pool::STRING,
            parsed_json:event:pool_address::STRING,
            parsed_json:event:pool_id::STRING
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
                    parsed_json:amounts_in[0]::NUMBER,
                    parsed_json:amount_a::NUMBER,
                    parsed_json:amount_x::NUMBER,
                    parsed_json:event:amount_in::NUMBER,
                    parsed_json:coin_in_amount::NUMBER
                ),
                COALESCE(
                    parsed_json:amount_in::NUMBER,
                    parsed_json:amounts_in[0]::NUMBER,
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
                parsed_json:coin_in_type:name::STRING,
                parsed_json:types_in[0]::STRING
            ),
            COALESCE(
                parsed_json:coin_b:name::STRING,
                parsed_json:coin_in:name::STRING,
                parsed_json:coin_in::STRING,
                parsed_json:type_in::STRING,
                parsed_json:event:coin_in::STRING,
                parsed_json:coin_in_type:name::STRING,
                parsed_json:types_in[0]::STRING
            )
        ) AS token_in_type,
        -- Token Out - handle different event patterns
        COALESCE(
            IFF(a_to_b,
                COALESCE(
                    parsed_json:amount_out::NUMBER,
                    parsed_json:amounts_out[0]::NUMBER,
                    parsed_json:amount_b::NUMBER,
                    parsed_json:amount_y::NUMBER,
                    parsed_json:event:amount_out::NUMBER,
                    parsed_json:coin_out_amount::NUMBER
                ),
                COALESCE(
                    parsed_json:amount_out::NUMBER,
                    parsed_json:amounts_out[0]::NUMBER,
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
                parsed_json:coin_out_type:name::STRING,
                parsed_json:types_out[0]::STRING
            ),
            COALESCE(
                parsed_json:coin_a:name::STRING,
                parsed_json:coin_out:name::STRING,
                parsed_json:coin_out::STRING,
                parsed_json:type_out::STRING,
                parsed_json:event:coin_out::STRING,
                parsed_json:coin_out_type:name::STRING,
                parsed_json:types_out[0]::STRING
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
    FROM
        core_events
),

-- group swap events to determine the swap_index within the transaction
-- several dexes will emit multiple swap events when the swap is routed
swaps_with_groups AS (
    SELECT
        *,
        -- Create base group key
        CASE 
            WHEN pool_address IS NOT NULL THEN
                CONCAT(pool_address, '|', COALESCE(amount_in_raw::STRING, '0'), '|', COALESCE(amount_out_raw::STRING, '0'))
            ELSE
                CONCAT(package_id, '|', transaction_module, '|', COALESCE(amount_in_raw::STRING, '0'), '|', COALESCE(amount_out_raw::STRING, '0'))
        END AS base_group_key,
        
        -- Find gaps in event_index sequence within the same base group
        LAG(event_index) OVER (
            PARTITION BY tx_digest,
                CASE 
                    WHEN pool_address IS NOT NULL THEN
                        CONCAT(pool_address, '|', COALESCE(amount_in_raw::STRING, '0'), '|', COALESCE(amount_out_raw::STRING, '0'))
                    ELSE
                        CONCAT(package_id, '|', transaction_module, '|', COALESCE(amount_in_raw::STRING, '0'), '|', COALESCE(amount_out_raw::STRING, '0'))
                END
            ORDER BY event_index
        ) AS prev_event_index
    FROM swaps
),

swaps_with_gap_detection AS (
    SELECT
        *,
        -- Detect if there's a significant gap (>3) between consecutive events with same base_group_key
        CASE 
            WHEN prev_event_index IS NULL THEN 0
            WHEN (event_index - prev_event_index) > 3 THEN 1
            ELSE 0
        END AS is_new_group,
        
        -- Create running sum to generate unique group identifiers
        SUM(
            CASE 
                WHEN prev_event_index IS NULL THEN 0
                WHEN (event_index - prev_event_index) > 3 THEN 1
                ELSE 0
            END
        ) OVER (
            PARTITION BY tx_digest, base_group_key 
            ORDER BY event_index 
            ROWS UNBOUNDED PRECEDING
        ) AS group_sequence
    FROM swaps_with_groups
),


swaps_with_final_groups AS (
    SELECT
        *,
        -- Create final group key that includes the sequence number for gap detection
        CONCAT(base_group_key, '|seq:', group_sequence::STRING) AS final_group_key,
        
        -- Get minimum event_index for each final group
        MIN(event_index) OVER (
            PARTITION BY tx_digest, CONCAT(base_group_key, '|seq:', group_sequence::STRING)
        ) AS group_min_event_index
    FROM swaps_with_gap_detection
),

swaps_with_index AS (
    SELECT
        *,
        -- Use DENSE_RANK to create swap_index based on group_min_event_index
        DENSE_RANK() OVER (
            PARTITION BY tx_digest 
            ORDER BY group_min_event_index
        ) as swap_index
    FROM swaps_with_final_groups
),

deduplicate_swaps AS (
    SELECT
        *
    FROM swaps_with_index

    qualify row_number() over (
        partition by tx_digest, swap_index
        order by token_in_type IS NOT NULL DESC, token_out_type IS NOT NULL DESC
    ) = 1
),

append_transaction_data AS (
    SELECT
        s.checkpoint_number,
        s.block_timestamp,
        s.tx_digest,
        s.event_index,
        s.swap_index,
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
            CASE
                WHEN t.function LIKE '%a_by_b%' OR t.function = 'swap_exact_input' THEN t.type_arguments[0]::STRING
                WHEN t.function LIKE '%b_by_a%' THEN t.type_arguments[1]::STRING
                WHEN t.function LIKE ANY ('%a_to_b%', '%a2b%', '%x_to_y%') THEN t.type_arguments[0]::STRING
                WHEN t.function LIKE ANY ('%b_to_a%', '%b2a%', '%y_to_x%') THEN t.type_arguments[1]::STRING
                WHEN s.a_to_b THEN t.type_arguments[0]::STRING
                ELSE t.type_arguments[1]::STRING
            END,
            -- For Haedal BuyBaseTokenEvent: paying quote token (index 1)
            CASE 
                WHEN s.event_resource = 'BuyBaseTokenEvent' THEN t.type_arguments[1] :: STRING
                WHEN s.event_resource = 'SellQuoteTokenEvent' THEN t.type_arguments[0] :: STRING
            END
        ) AS token_in_type,
        s.token_in_type IS NULL AS token_in_from_txs, -- TEMP
        s.amount_out_raw,
        COALESCE(
            s.token_out_type,
            CASE
                WHEN t.function LIKE '%a_by_b%' OR t.function = 'swap_exact_input' THEN t.type_arguments[1]::STRING
                WHEN t.function LIKE '%b_by_a%' THEN t.type_arguments[2]::STRING
                WHEN t.function LIKE ANY ('%a_to_b%', '%a2b%', '%x_to_y%') THEN t.type_arguments[1]::STRING
                WHEN t.function LIKE ANY ('%b_to_a%', '%b2a%', '%y_to_x%') THEN t.type_arguments[1]::STRING
                WHEN s.a_to_b THEN t.type_arguments[1]::STRING
                ELSE t.type_arguments[0]::STRING
            END,
            -- For Haedal BuyBaseTokenEvent: receiving base token (index 0)
            CASE 
                WHEN s.event_resource = 'BuyBaseTokenEvent' THEN t.type_arguments[0] :: STRING
                WHEN s.event_resource = 'SellQuoteTokenEvent' THEN t.type_arguments[1] :: STRING
            END
        ) AS token_out_type,
        s.token_out_type IS NULL AS token_out_from_txs, -- TEMP
        payload_details, -- TEMP
        s.a_to_b,
        s.fee_amount_raw,
        s.partner_address,
        s.steps,
        s.parsed_json,
        s.modified_timestamp
    FROM
        deduplicate_swaps s
        LEFT JOIN core_transactions t
            ON s.tx_digest = t.tx_digest
            AND s.package_id = t.package
            AND s.transaction_module = t.module
            AND s.package_index = t.package_index
            AND (s.token_in_type IS NULL OR s.token_out_type IS NULL)
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
    token_in_from_txs, -- TEMP
    token_out_from_txs, -- TEMP
    a_to_b,
    fee_amount_raw,
    partner_address,
    steps,
    swap_index,
    package_index,
    parsed_json, -- TEMP
    payload_details, -- TEMP
    {{ dbt_utils.generate_surrogate_key(['tx_digest', 'trader_address', 'token_in_type', 'token_out_type', 'amount_in_raw', 'amount_out_raw', 'swap_index']) }} AS dex_swaps_id,
    SYSDATE() AS inserted_timestamp,
    modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    append_transaction_data
