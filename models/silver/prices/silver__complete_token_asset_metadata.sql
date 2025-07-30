{{ config(
    materialized = 'view',
    tags = ['silver','core']
) }}

SELECT
    A.token_address,
    asset_id,
    symbol,
    NAME,
    decimals,
    blockchain,
    blockchain_name,
    blockchain_id,
    is_deprecated,
    is_verified,
    provider,
    source,
    _inserted_timestamp,
    inserted_timestamp,
    modified_timestamp,
    {{ dbt_utils.generate_surrogate_key(['complete_token_asset_metadata_id']) }} AS complete_token_asset_metadata_id,
    '{{ invocation_id }}' AS _invocation_id
FROM
    {{ ref(
        'bronze__complete_token_asset_metadata'
    ) }} A

{% if is_incremental() %}
WHERE
    modified_timestamp >= (
        SELECT
            MAX(
                modified_timestamp
            )
        FROM
            {{ this }}
    )
{% endif %}
