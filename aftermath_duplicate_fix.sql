-- Query to handle Aftermath duplicate events by detecting module patterns
WITH aftermath_events AS (
    SELECT 
        *,
        -- Detect Aftermath duplicate pattern: events module followed by aftermath module
        CASE 
            WHEN package_id = '0x8ae871505a80d8bf6bf9c05906cda6edfeea460c85bebe2e26a4313f5e67874a'
                AND pool_address IS NOT NULL
                AND event_module = 'aftermath'
                AND LAG(event_module) OVER (PARTITION BY tx_digest ORDER BY event_index) = 'events'
                AND LAG(pool_address) OVER (PARTITION BY tx_digest ORDER BY event_index) = pool_address
                AND LAG(event_index) OVER (PARTITION BY tx_digest ORDER BY event_index) = event_index - 1
                AND LAG(amount_out_raw) OVER (PARTITION BY tx_digest ORDER BY event_index) = amount_out_raw
                -- Check if amount_in differs by ~0.05% (Aftermath fee)
                AND ABS(LAG(amount_in_raw) OVER (PARTITION BY tx_digest ORDER BY event_index) - amount_in_raw) / NULLIF(amount_in_raw, 0) BETWEEN 0.0004 AND 0.0006
            THEN TRUE
            ELSE FALSE
        END AS is_aftermath_duplicate,
        
        -- Detect Kriya AMM duplicate pattern: spot_dex module followed by kriya_amm module
        CASE 
            WHEN package_id = '0x8ae871505a80d8bf6bf9c05906cda6edfeea460c85bebe2e26a4313f5e67874a'
                AND pool_address IS NOT NULL
                AND event_module = 'kriya_amm'
                AND LAG(event_module) OVER (PARTITION BY tx_digest ORDER BY event_index) = 'spot_dex'
                AND LAG(pool_address) OVER (PARTITION BY tx_digest ORDER BY event_index) = pool_address
                AND LAG(event_index) OVER (PARTITION BY tx_digest ORDER BY event_index) = event_index - 1
                AND LAG(amount_out_raw) OVER (PARTITION BY tx_digest ORDER BY event_index) = amount_out_raw
                -- Check if amount_in differs by ~0.063% (Kriya fee)
                AND ABS(LAG(amount_in_raw) OVER (PARTITION BY tx_digest ORDER BY event_index) - amount_in_raw) / NULLIF(amount_in_raw, 0) BETWEEN 0.0005 AND 0.0008
            THEN TRUE
            ELSE FALSE
        END AS is_kriya_duplicate,
        
        -- Get previous event's key fields for grouping
        LAG(amount_in_raw) OVER (PARTITION BY tx_digest ORDER BY event_index) AS prev_amount_in,
        LAG(event_module) OVER (PARTITION BY tx_digest ORDER BY event_index) AS prev_event_module
    FROM swaps
),
swaps_with_groups AS (
    SELECT 
        *,
        -- Create base group key - for duplicates, use the normalized amounts
        CASE 
            WHEN is_aftermath_duplicate OR is_kriya_duplicate THEN
                -- For duplicates, group them together by using the larger amount_in (actual amount)
                CONCAT(
                    pool_address, 
                    '|', 
                    GREATEST(COALESCE(amount_in_raw::STRING, '0'), COALESCE(prev_amount_in::STRING, '0')), 
                    '|', 
                    COALESCE(amount_out_raw::STRING, '0')
                )
            WHEN pool_address IS NOT NULL THEN
                CONCAT(pool_address, '|', COALESCE(amount_in_raw::STRING, '0'), '|', COALESCE(amount_out_raw::STRING, '0'))
            ELSE
                CONCAT(package_id, '|', transaction_module, '|', COALESCE(amount_in_raw::STRING, '0'), '|', COALESCE(amount_out_raw::STRING, '0'))
        END AS base_group_key
    FROM aftermath_events
)
-- Continue with the rest of the grouping logic...