{{ config (
    materialized = "incremental",
    unique_key = "coin_type",
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gold','core']
) }}

SELECT
    coin_type,
    decimals,
    symbol,
    NAME,
    description,
    icon_url,
    id,
    {{ dbt_utils.generate_surrogate_key(['coin_type']) }} AS coin_types_id,
    {{ dbt_utils.generate_surrogate_key(['coin_type']) }} AS dim_tokens_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    {{ ref('bronze_api__coin_metadata') }}

{% if is_incremental() %}
WHERE
    modified_timestamp >= (
        SELECT
            MAX(modified_timestamp) AS modified_timestamp
        FROM
            {{ this }}
    )
{% endif %}
