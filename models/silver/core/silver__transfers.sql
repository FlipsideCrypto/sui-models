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
    {% if is_incremental() %}
    WHERE 
        modified_timestamp >= (SELECT COALESCE(MAX(modified_timestamp),'1970-01-01') FROM {{ this }})
    {% endif %}
    GROUP BY 
        tx_digest
    HAVING SUM(
        CASE
            WHEN payload_type IN ('TransferObjects','SplitCoins','MergeCoins') THEN 0
            WHEN payload_type = 'MoveCall' AND payload_details :package
                = '0x0000000000000000000000000000000000000000000000000000000000000002'
            THEN 0
            ELSE 1
        END
    ) = 0
),

coin_only_tx AS (
    SELECT
        tx_digest
    FROM 
        {{ ref('core__fact_changes') }}
    WHERE 
        tx_digest IN (SELECT tx_digest FROM allowed_tx)
    {% if is_incremental() %}
        AND modified_timestamp >= (SELECT COALESCE(MAX(modified_timestamp),'1970-01-01') FROM {{ this }})
    {% endif %}
    GROUP BY 
        tx_digest
    HAVING MAX(
        CASE WHEN object_type ILIKE '0x2::coin::Coin%' THEN 0 ELSE 1 END
    ) = 0
)
SELECT 
    fbc.checkpoint_number,
    fbc.block_timestamp,
    fbc.tx_digest,
    fbc.tx_succeeded,
    fbc.tx_sender as sender,
    fbc.owner as receiver,
    fbc.balance_change_index,
    dt.symbol,
    dt.decimals,
    fbc.amount as amount_raw,
    fbc.amount / POWER(10, dt.decimals) as amount_normalized,
    {{ dbt_utils.generate_surrogate_key(['tx_digest','balance_change_index']) }} AS transfers_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM 
    {{ ref('core__fact_balance_changes') }} fbc
JOIN 
    {{ ref('core__dim_tokens') }} dt ON fbc.coin_type = dt.coin_type
WHERE 
    fbc.tx_digest IN (SELECT tx_digest FROM coin_only_tx)
    AND fbc.tx_sender != fbc.owner
    {% if is_incremental() %}
        AND fbc.modified_timestamp >= (SELECT COALESCE(MAX(modified_timestamp),'1970-01-01') FROM {{ this }})
        AND dt.modified_timestamp >= (SELECT COALESCE(MAX(modified_timestamp),'1970-01-01') FROM {{ this }})
    {% endif %}