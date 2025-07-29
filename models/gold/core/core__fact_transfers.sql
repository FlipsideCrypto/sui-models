{{ config(
    materialized = 'incremental',
    unique_key = ['tx_digest','balance_change_index'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::DATE"],
    merge_exclude_columns = ["inserted_timestamp"],
    cluster_by = ['block_timestamp::DATE','modified_timestamp::DATE'],
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION ON EQUALITY(tx_digest, sender, receiver, coin_type);",
    tags = ['core']
) }}

SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    tx_succeeded,
    sender,
    receiver,
    balance_change_index,
    coin_type,
    amount,
    {{ dbt_utils.generate_surrogate_key(
        ['tx_digest','balance_change_index']
    ) }} AS fact_transfers_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    {{ ref(
        'silver__transfers'
    ) }}
WHERE
    amount is not null

{% if is_incremental() %}
AND modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}