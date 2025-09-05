-- depends_on: {{ ref('core__fact_events') }}
{{ config (
    materialized = "incremental",
    unique_key = "suilend_borrows_id",
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
        AND event_resource = 'BorrowEvent'
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
    parsed_json :coin_type :name :: STRING AS coin_type,
    parsed_json :lending_market_id :: STRING AS lending_market_id,
    parsed_json :liquidity_amount :: bigint AS liquidity_amount,
    parsed_json :obligation_id :: STRING AS obligation_id,
    parsed_json :origination_fee_amount :: INT AS origination_fee_amount,
    parsed_json :reserve_id :: STRING AS reserve_id,
    {{ dbt_utils.generate_surrogate_key(['tx_digest', 'event_index']) }} AS suilend_borrows_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    suilend_events
