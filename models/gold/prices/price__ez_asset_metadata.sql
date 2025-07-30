{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    merge_exclude_columns = ["inserted_timestamp"],
    unique_key = 'ez_asset_metadata_id',
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION ON EQUALITY(token_address, symbol)",
    tags = ['gold_prices','core']
) }}

SELECT
    token_address,
    asset_id,
    symbol,
    NAME,
    decimals,
    blockchain,
    CASE
        WHEN token_address = '0x2::sui::SUI' THEN TRUE
        ELSE FALSE
    END AS is_native,
    is_deprecated,
    COALESCE(
        is_verified,
        FALSE
    ) AS token_is_verified,
    {{ dbt_utils.generate_surrogate_key(['complete_token_asset_metadata_id']) }} AS ez_asset_metadata_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    {{ ref('silver__complete_token_asset_metadata') }}

{% if is_incremental() %}
WHERE
    modified_timestamp > (
        SELECT
            COALESCE(MAX(modified_timestamp), '1970-01-01' :: TIMESTAMP) AS modified_timestamp
        FROM
            {{ this }})
        {% endif %}
