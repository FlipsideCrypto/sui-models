{{ config(
    materialized = 'incremental',
    unique_key = ['tx_digest','balance_change_index'],
    incremental_strategy = 'merge',
    merge_exclude_columns = ['inserted_timestamp'],
    cluster_by = ['block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    tags = ['core','transfers']
) }}

WITH 
allowed_tx AS (
    SELECT
        tx_digest
    FROM 
        {{ ref('core__fact_transactions') }}
    WHERE
        (payload_type IN ('TransferObjects','SplitCoins','MergeCoins'))
        OR 
        (payload_type = 'MoveCall' AND payload_details :package = '0x0000000000000000000000000000000000000000000000000000000000000002')
    {% if is_incremental() %}
        AND modified_timestamp >= (SELECT COALESCE(MAX(modified_timestamp),'1970-01-01') FROM {{ this }})
    {% endif %}
),
-- Identify true mints from balance changes (self-transfers with no positive balance change)
mint_indicators AS (
    SELECT 
        tx_digest,
        COUNT(*) as total_balance_changes,
        COUNT(CASE WHEN amount > 0 THEN 1 END) as positive_changes,
        COUNT(CASE WHEN amount < 0 THEN 1 END) as negative_changes
    FROM {{ ref('core__fact_balance_changes') }}
    WHERE tx_succeeded
    GROUP BY tx_digest
),
filtered as (
    SELECT 
        fbc.checkpoint_number,
        fbc.block_timestamp,
        fbc.tx_digest,
        fbc.tx_succeeded,
        CASE 
            WHEN fbc.amount < 0 THEN 
                COALESCE(fbc.address_owner, fbc.object_owner)
            ELSE 
                fbc.tx_sender
        END as sender,
        CASE 
            WHEN fbc.amount > 0 THEN 
                COALESCE(fbc.address_owner, fbc.object_owner)
            ELSE 
                CASE 
                    WHEN COALESCE(fbc.address_owner, fbc.object_owner) != fbc.tx_sender 
                    THEN fbc.tx_sender
                    ELSE COALESCE(fbc.address_owner, fbc.object_owner)
                END
        END as receiver,
        fbc.balance_change_index,
        fbc.coin_type,
        fbc.amount
    FROM 
        {{ ref('core__fact_balance_changes') }} fbc
    JOIN
        allowed_tx at 
        ON fbc.tx_digest = at.tx_digest
    LEFT JOIN
        mint_indicators mi
        ON fbc.tx_digest = mi.tx_digest
    WHERE
        fbc.tx_succeeded
        AND NOT (
            fbc.balance_change_index = 0 
            AND fbc.amount < 0 
            AND COALESCE(fbc.address_owner, fbc.object_owner) = fbc.tx_sender
            AND mi.total_balance_changes = 1  -- Only one balance change (self-transfer)
            AND mi.positive_changes = 0       -- No positive changes
            AND mi.negative_changes = 1       -- Only negative change
        )
    {% if is_incremental() %}
        AND fbc.modified_timestamp >= (SELECT COALESCE(MAX(modified_timestamp),'1970-01-01') FROM {{ this }})
    {% endif %}
)
SELECT DISTINCT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    tx_succeeded,
    sender,
    receiver,
    balance_change_index,
    coin_type,
    amount,
    {{ dbt_utils.generate_surrogate_key(['tx_digest','balance_change_index']) }} AS transfers_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    filtered