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
filtered as (
    SELECT 
        fbc.checkpoint_number,
        fbc.block_timestamp,
        fbc.tx_digest,
        fbc.tx_succeeded,
        case 
            when fbc.amount < 0 
            and fbc.address_owner IS NOT NULL 
            and fbc.address_owner <> fbc.tx_sender 
            then fbc.address_owner 
            else fbc.tx_sender end as sender,
        coalesce(fbc.address_owner, fbc.object_owner) as receiver,
        fbc.balance_change_index,
        fbc.coin_type,
        fbc.amount
    FROM 
        {{ ref('core__fact_balance_changes') }} fbc
    JOIN
        allowed_tx at 
        ON fbc.tx_digest = at.tx_digest
    WHERE
        fbc.tx_sender != coalesce(fbc.address_owner, fbc.object_owner)
        AND NOT (balance_change_index = 0 AND amount < 0) -- remove mints, self-splits, proofs, flash loans
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