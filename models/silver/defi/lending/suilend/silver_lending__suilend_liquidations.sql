-- depends_on: {{ ref('core__fact_events') }}
{{ config (
    materialized = "incremental",
    unique_key = "suilend_liquidations_id",
    cluster_by = ['modified_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['silver','defi','lending','non_core']
) }}

WITH suilend_events AS (

    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        tx_sender,
        event_index,
        TYPE,
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
        tx_succeeded
        AND event_resource = 'LiquidateEvent'
        AND event_address = '0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf'

{% if is_incremental() %}
AND modified_timestamp >= (
    SELECT
        COALESCE(MAX(modified_timestamp), '1900-01-01' :: TIMESTAMP) AS modified_timestamp
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
    TYPE,
    event_module,
    event_resource,
    package_id,
    transaction_module,
    parsed_json :lending_market_id :: STRING AS lending_market_id,
    parsed_json :liquidator_bonus_amount :: bigint AS liquidator_bonus_amount,
    parsed_json :obligation_id :: STRING AS obligation_id,
    parsed_json :protocol_fee_amount :: bigint AS protocol_fee_amount,
    parsed_json :repay_amount :: bigint AS repay_amount,
    parsed_json :repay_coin_type :name :: STRING AS repay_coin_type,
    parsed_json :repay_reserve_id :: STRING AS repay_reserve_id,
    parsed_json :withdraw_amount :: bigint AS withdraw_amount,
    parsed_json :withdraw_coin_type :name :: STRING AS withdraw_coin_type,
    parsed_json :withdraw_reserve_id :: STRING AS withdraw_reserve_id,
    {{ dbt_utils.generate_surrogate_key(['tx_digest', 'event_index']) }} AS suilend_liquidations_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    suilend_events
