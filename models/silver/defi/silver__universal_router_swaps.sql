-- depends_on: {{ ref('core__fact_events') }}
{{ config (
    materialized = "incremental",
    unique_key = ["tx_digest", "event_index"],
    cluster_by = ['modified_timestamp::DATE','block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['scheduled_non_core']
) }}

WITH core_events AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        tx_sender,
        event_index,
        type,
        event_address,
        event_module,
        event_resource,
        transaction_module,
        parsed_json,
        modified_timestamp
    FROM
        {{ ref('core__fact_events') }}
    WHERE
{% if is_incremental() %}
        modified_timestamp >= (
            SELECT
                COALESCE(MAX(modified_timestamp), '1900-01-01'::TIMESTAMP) AS modified_timestamp
            FROM
                {{ this }}
        )
        AND
{% endif %}
        type = '0xc263060d3cbb4155057f0010f92f63ca56d5121c298d01f7a33607342ec299b0::universal_router::Swap'
        -- limit to 30 days for dev
        AND block_timestamp >= sysdate() - interval '30 days'
)

SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    event_index,
    'Universal Router' AS platform,
    event_address AS platform_address,
    parsed_json:pool_id::STRING AS pool_address,
    parsed_json:amount_in::NUMBER AS amount_in_raw,
    parsed_json:amount_out::NUMBER AS amount_out_raw,
    parsed_json:a2b::BOOLEAN AS a_to_b,
    NULL AS fee_amount_raw,
    parsed_json:partner::STRING AS partner_address,
    NULL AS referral_amount_raw,
    1 AS steps,
    parsed_json:coin_in:name::STRING AS token_in_type,
    parsed_json:coin_out:name::STRING AS token_out_type,
    parsed_json:swapper::STRING AS trader_address,
    transaction_module,
    {{ dbt_utils.generate_surrogate_key(['tx_digest', 'event_address', 'trader_address', 'token_in_type', 'token_out_type', 'amount_in_raw', 'amount_out_raw']) }} AS universal_router_swaps_id,
    SYSDATE() AS inserted_timestamp,
    modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    core_events