{{ config(
    materialized = 'view',
    tags = ['silver','core']
) }}

SELECT
    HOUR,
    p.token_address,
    asset_id,
    symbol,
    NAME,
    decimals,
    price,
    blockchain,
    blockchain_name,
    blockchain_id,
    is_imputed,
    is_deprecated,
    is_verified,
    provider,
    source,
    _inserted_timestamp,
    inserted_timestamp,
    modified_timestamp,
    {{ dbt_utils.generate_surrogate_key(['complete_token_prices_id']) }} AS complete_token_prices_id,
    '{{ invocation_id }}' AS _invocation_id
FROM
    {{ ref(
        'bronze__complete_token_prices'
    ) }}
    p
