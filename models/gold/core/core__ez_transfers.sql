{{ config(
    materialized = 'incremental',
    unique_key = ['tx_digest','balance_change_index'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::DATE"],
    merge_exclude_columns = ["inserted_timestamp"],
    cluster_by = ['block_timestamp::DATE','modified_timestamp::DATE'],
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION ON EQUALITY(tx_digest, sender, receiver, coin_type, symbol);",
    tags = ['core']
) }}

SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    balance_change_index,
    tx_succeeded,
    sender,
    receiver,
    ft.coin_type,
    symbol,
    amount,
    ROUND(NULLIFZERO(DIV0NULL(amount, POWER(10, dt.decimals))), 3) as amount_normalized,
    {{ dbt_utils.generate_surrogate_key(
        ['tx_digest','balance_change_index']
    ) }} AS ez_transfers_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    {{ ref('core__fact_transfers') }} ft
LEFT JOIN
    {{ ref('core__dim_tokens') }} dt 
    ON ft.coin_type = dt.coin_type
{% if is_incremental() %}
WHERE ft.modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}