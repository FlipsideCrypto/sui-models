{{ config (
    materialized = "incremental",
    unique_key = ['block_timestamp::DATE','tx_digest','event_index'],
    cluster_by = ['block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gold','non_core']
) }}

WITH base AS (

    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        tx_sender,
        event_index,
        source_chain,
        destination_chain,
        amount AS amount_unadj,
        source_address,
        destination_address,
        coin_type,
        bridge_address,
        all_bridges_id,
        inserted_timestamp,
        modified_timestamp,
        _INVOCATION_ID,
        direction,
        platform
    FROM
        {{ ref('silver_bridge__all_bridges') }}

{% if is_incremental() %}
WHERE
    modified_timestamp >= (
        SELECT
            COALESCE(MAX(modified_timestamp), '1970-01-01' :: TIMESTAMP) AS modified_timestamp
        FROM
            {{ this }})
        {% endif %}
    )
SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    tx_sender,
    event_index,
    bridge_address,
    platform,
    platform AS protocol,
    'v1' AS protocol_version,
    direction,
    CASE
        source_chain
        WHEN 0 THEN 'sui'
        WHEN 10 THEN 'ethereum'
    END AS source_chain,
    CASE
        destination_chain
        WHEN 0 THEN 'sui'
        WHEN 10 THEN 'ethereum'
    END AS destination_chain,
    source_address AS sender,
    destination_address AS receiver,
    coin_type,
    b.symbol AS symbol,
    amount_unadj,
    amount_unadj / pow(
        10,
        b.decimals
    ) AS amount,
    (amount / pow(10, b.decimals)) * C.price AS amount_usd,
    COALESCE(
        C.token_is_verified,
        FALSE
    ) AS token_is_verified,
    all_bridges_id AS ez_bridge_activity_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    base A
    LEFT JOIN {{ ref('core__dim_tokens') }}
    b USING(coin_type)
    LEFT JOIN {{ ref('price__ez_prices_hourly') }} C
    ON A.coin_type = C.token_address
    AND DATE_TRUNC(
        'hour',
        block_timestamp
    ) = C.hour
