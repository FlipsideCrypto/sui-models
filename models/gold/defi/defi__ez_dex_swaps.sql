{{ config (
    materialized = "incremental",
    unique_key = "dex_swaps_id",
    cluster_by = ['modified_timestamp::DATE','block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION ON EQUALITY(tx_digest, event_index, trader_address, platform_address);",
    tags = ['gold','defi']
) }}

WITH base_swaps AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        event_index,
        swap_index,
        event_module,
        platform_address,
        pool_address,
        amount_in_raw,
        amount_out_raw,
        a_to_b,
        fee_amount_raw,
        partner_address,
        steps,
        token_in_type,
        token_out_type,
        trader_address,
        dex_swaps_id,
        modified_timestamp
    FROM {{ ref('silver__dex_swaps') }}
    WHERE 1=1
{% if is_incremental() %}
        AND modified_timestamp >= (
            SELECT COALESCE(MAX(modified_timestamp), '1900-01-01'::TIMESTAMP)
            FROM {{ this }}
        )
{% endif %}
),

token_prices_in AS (
    SELECT 
        bs.*,
        -- Extract token address from full type for price/token joining
        SPLIT(bs.token_in_type, '::')[0] as token_in_address,
        SPLIT(bs.token_out_type, '::')[0] as token_out_address,
        
        -- Price data for token_in with SUI native handling
        COALESCE(
            p_in_std.price, 
            p_in_native.price, 
            p_in_long.price
        ) as token_in_price,
        
        -- Decimals prioritizing dim_tokens first, then price data, then default
        COALESCE(
            dim_in.decimals,
            p_in_std.decimals, 
            p_in_native.decimals, 
            p_in_long.decimals,
            9  -- All Sui tokens use 9 decimals (including USDC/USDT on Sui)
        ) as token_in_decimals,
        
        COALESCE(dim_in.symbol, p_in_std.symbol, p_in_native.symbol, p_in_long.symbol) as token_in_symbol,
        COALESCE(dim_in.name, p_in_std.name, p_in_native.name, p_in_long.name) as token_in_name
        
    FROM base_swaps bs
    
    -- Join with dim_tokens for token metadata
    LEFT JOIN {{ ref('core__dim_tokens') }} dim_in
        ON lower(bs.token_in_type) = lower(dim_in.coin_type)
    
    -- Standard token address join
    LEFT JOIN crosschain.price.ez_prices_hourly p_in_std 
        ON LOWER(SPLIT(bs.token_in_type, '::')[0]) = LOWER(p_in_std.token_address)
        AND p_in_std.blockchain = 'sui'
        AND p_in_std.hour = DATE_TRUNC('hour', bs.block_timestamp)
        
    -- Native SUI join (for 0x2 addresses)
    LEFT JOIN crosschain.price.ez_prices_hourly p_in_native
        ON SPLIT(bs.token_in_type, '::')[0] = '0x2'
        AND p_in_native.blockchain = 'sui'
        AND p_in_native.is_native = true
        AND p_in_native.hour = DATE_TRUNC('hour', bs.block_timestamp)
        
    -- Long-form SUI address join (0x2 -> 0x000...002)
    LEFT JOIN crosschain.price.ez_prices_hourly p_in_long
        ON SPLIT(bs.token_in_type, '::')[0] = '0x2'
        AND p_in_long.token_address = '0x0000000000000000000000000000000000000000000000000000000000000002'
        AND p_in_long.blockchain = 'sui'
        AND p_in_long.hour = DATE_TRUNC('hour', bs.block_timestamp)
),

with_all_prices AS (
    SELECT 
        tpi.*,
        
        -- Price data for token_out with SUI native handling
        COALESCE(
            p_out_std.price, 
            p_out_native.price, 
            p_out_long.price
        ) as token_out_price,
        
        -- Decimals prioritizing dim_tokens first, then price data, then default
        COALESCE(
            dim_out.decimals,
            p_out_std.decimals, 
            p_out_native.decimals, 
            p_out_long.decimals,
            9  -- All Sui tokens use 9 decimals (including USDC/USDT on Sui)
        ) as token_out_decimals,
        
        COALESCE(dim_out.symbol, p_out_std.symbol, p_out_native.symbol, p_out_long.symbol) as token_out_symbol,
        COALESCE(dim_out.name, p_out_std.name, p_out_native.name, p_out_long.name) as token_out_name
        
    FROM token_prices_in tpi
    
    -- Join with dim_tokens for token metadata  
    LEFT JOIN {{ ref('core__dim_tokens') }} dim_out
        ON lower(tpi.token_out_type) = lower(dim_out.coin_type)
    
    -- Standard token address join
    LEFT JOIN crosschain.price.ez_prices_hourly p_out_std 
        ON LOWER(tpi.token_out_address) = LOWER(p_out_std.token_address)
        AND p_out_std.blockchain = 'sui'
        AND p_out_std.hour = DATE_TRUNC('hour', tpi.block_timestamp)
        
    -- Native SUI join (for 0x2 addresses)
    LEFT JOIN crosschain.price.ez_prices_hourly p_out_native
        ON tpi.token_out_address = '0x2'
        AND p_out_native.blockchain = 'sui'
        AND p_out_native.is_native = true
        AND p_out_native.hour = DATE_TRUNC('hour', tpi.block_timestamp)
        
    -- Long-form SUI address join (0x2 -> 0x000...002)
    LEFT JOIN crosschain.price.ez_prices_hourly p_out_long
        ON tpi.token_out_address = '0x2'
        AND p_out_long.token_address = '0x0000000000000000000000000000000000000000000000000000000000000002'
        AND p_out_long.blockchain = 'sui'
        AND p_out_long.hour = DATE_TRUNC('hour', tpi.block_timestamp)
),

with_labels AS (
    SELECT 
        wap.*,
        
        -- Platform/contract labels
        l_platform.address_name as platform_address_label,
        l_platform.project_name as platform_project_name,
        
        -- Pool labels  
        l_pool.address_name as pool_address_label,
        l_pool.project_name as pool_project_name
        
    FROM with_all_prices wap
    
    -- Platform address labels
    LEFT JOIN crosschain.core.dim_labels l_platform
        ON LOWER(wap.platform_address) = LOWER(l_platform.address)
        AND l_platform.blockchain = 'sui'
        AND l_platform.label_type IN ('dex', 'defi')
        
    -- Pool address labels
    LEFT JOIN crosschain.core.dim_labels l_pool
        ON LOWER(wap.pool_address) = LOWER(l_pool.address)
        AND l_pool.blockchain = 'sui'
        AND l_pool.label_subtype = 'pool'
)

SELECT
    -- Core identifiers
    checkpoint_number,
    block_timestamp,
    tx_digest,
    event_index,
    swap_index,
    
    -- Platform information
    platform_address,
    COALESCE(platform_project_name, pool_project_name, event_module) as platform_name,
    pool_address,
    COALESCE(pool_address_label, pool_address) as pool_name,
    
    -- Swap details
    amount_in_raw,
    amount_out_raw,
    a_to_b,
    fee_amount_raw,
    partner_address,
    steps,
    
    -- Token information
    token_in_type,
    token_in_address,
    token_in_symbol,
    token_in_name,
    token_out_type,
    token_out_address,
    token_out_symbol,
    token_out_name,
    
    -- Adjusted amounts (divide by decimals)
    amount_in_raw / POW(10, token_in_decimals) as amount_in,
    amount_out_raw / POW(10, token_out_decimals) as amount_out,
    CASE 
        WHEN fee_amount_raw IS NOT NULL AND fee_amount_raw > 0 
        THEN fee_amount_raw / POW(10, token_in_decimals)
        ELSE NULL 
    END as fee_amount,
    
    -- Price information
    token_in_price,
    token_out_price,
    token_in_decimals,
    token_out_decimals,
    
    -- USD volumes
    CASE 
        WHEN token_in_price IS NOT NULL 
        THEN (amount_in_raw / POW(10, token_in_decimals)) * token_in_price
        ELSE NULL 
    END as amount_in_usd,
    
    CASE 
        WHEN token_out_price IS NOT NULL 
        THEN (amount_out_raw / POW(10, token_out_decimals)) * token_out_price
        ELSE NULL 
    END as amount_out_usd,
    
    -- Average the two sides when both prices available, otherwise use whichever is available
    CASE 
        WHEN token_in_price IS NOT NULL AND token_out_price IS NOT NULL 
        THEN ((amount_in_raw / POW(10, token_in_decimals)) * token_in_price + 
              (amount_out_raw / POW(10, token_out_decimals)) * token_out_price) / 2
        WHEN token_in_price IS NOT NULL 
        THEN (amount_in_raw / POW(10, token_in_decimals)) * token_in_price
        WHEN token_out_price IS NOT NULL 
        THEN (amount_out_raw / POW(10, token_out_decimals)) * token_out_price
        ELSE NULL 
    END as swap_volume_usd,
    
    -- Trader information
    trader_address,
    
    -- Metadata
    dex_swaps_id,
    SYSDATE() AS inserted_timestamp,
    modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
    
FROM with_labels