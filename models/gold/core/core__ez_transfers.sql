{{ config(
    materialized = 'incremental',
    unique_key = ['tx_digest','balance_change_index'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::DATE"],
    merge_exclude_columns = ["inserted_timestamp"],
    cluster_by = ['block_timestamp::DATE'],
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION ON EQUALITY(tx_digest, tx_sender, sender, receiver, coin_type, symbol);",
    tags = ['core']
) }}

SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    balance_change_index,
    tx_succeeded,
    tx_sender,
    sender,
    receiver,
    ft.coin_type,
    COALESCE(
        dt.symbol,
        eph.symbol
    ) AS symbol,
    amount_raw,
    CASE
        WHEN COALESCE(
            dt.decimals,
            0
        ) <> 0 THEN amount_raw / power(
            10,
            dt.decimals
        )
    END AS amount,
    ROUND(
        amount * eph.price,
        2
    ) AS amount_usd,
    COALESCE(
        eph.token_is_verified,
        FALSE
    ) AS token_is_verified,
    {{ dbt_utils.generate_surrogate_key(
        ['tx_digest','balance_change_index']
    ) }} AS ez_transfers_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    {{ ref('silver__transfers') }}
    ft
    LEFT JOIN {{ ref('core__dim_tokens') }}
    dt
    ON ft.coin_type = dt.coin_type
    LEFT JOIN {{ ref('price__ez_prices_hourly') }}
    eph
    ON ft.coin_type = eph.token_address
    AND DATE_TRUNC(
        'HOUR',
        ft.block_timestamp
    ) = eph.hour
WHERE
    amount IS NOT NULL

{% if is_incremental() %}
AND ft.modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}
