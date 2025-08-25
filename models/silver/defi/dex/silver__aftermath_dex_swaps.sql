-- depends_on: {{ ref('core__fact_events') }}
{{ config (
    materialized = "incremental",
    unique_key = "dex_swaps_id",
    cluster_by = ['modified_timestamp::DATE','block_timestamp::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "block_timestamp::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['non_core']
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
        package_id,
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
        -- Only include Aftermath module swaps
        transaction_module = 'aftermath'
        AND event_resource IN (
                'SwapEvent',
                'SwapEventV2'
        )
),

swaps AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        tx_digest,
        tx_sender,
        event_index,
        type,
        event_module,
        event_resource,
        package_id,
        transaction_module,
        event_address AS platform_address,
        parsed_json:pool_id::STRING AS pool_address,
        parsed_json:a2b::BOOLEAN AS a_to_b,
        COALESCE(
            parsed_json:amount_in::NUMBER,
            parsed_json:amounts_in[0]::NUMBER
        ) AS amount_in_raw,
        COALESCE(
            parsed_json:from:name::STRING,
            parsed_json:types_in[0]::STRING
        ) AS token_in_type,
        COALESCE(
            parsed_json:amount_out::NUMBER,
            parsed_json:amounts_out[0]::NUMBER
        ) AS amount_out_raw,
        COALESCE(
            parsed_json:target:name::STRING,
            parsed_json:types_out[0]::STRING
        ) AS token_out_type,
        NULL AS fee_amount_raw,
        COALESCE(
            parsed_json:referrer::STRING,
            parsed_json:partner::STRING
        ) AS partner_address,
        1 AS steps,
        tx_sender AS trader_address,
        modified_timestamp,
        parsed_json
    FROM
        core_events
)

SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    event_index,
    type,
    event_module,
    package_id,
    transaction_module,
    event_resource,
    platform_address,
    trader_address,
    pool_address,
    amount_in_raw,
    IFF(
        LEFT(token_in_type, 2) = '0x',
        token_in_type,
        '0x' || token_in_type
    ) AS token_in_type,
    amount_out_raw,
    IFF(
        LEFT(token_out_type, 2) = '0x',
        token_out_type,
        '0x' || token_out_type
    ) AS token_out_type,
    a_to_b,
    fee_amount_raw,
    partner_address,
    steps,
    parsed_json,
    {{ dbt_utils.generate_surrogate_key(['tx_digest', 'event_index']) }} AS dex_swaps_id,
    SYSDATE() AS inserted_timestamp,
    modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    swaps
