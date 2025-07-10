{{ config (
    materialized = 'incremental',
    unique_key = "coin_type",
    merge_exclude_columns = ["inserted_timestamp"],
    full_refresh = false,
    tags = ['silver','core']
) }}

WITH coins AS (

    SELECT
        coin_type
    FROM
        {{ ref('silver__coin_types') }}

{% if is_incremental() %}
EXCEPT
SELECT
    coin_type
FROM
    {{ this }}
WHERE
    decimals IS NOT NULL --rerun if decimals is null and inserted_timestamp is within the last 7 days (if the token still doesnt have decimals after 7 day then we will stop trying)
    OR (
        decimals IS NULL
        AND inserted_timestamp < CURRENT_DATE -7
    )
{% endif %}
LIMIT
    100
), lq AS (
    SELECT
        coin_type,
        {{ target.database }}.live.udf_api(
            'POST',
            '{Service}/{Authentication}',
            OBJECT_CONSTRUCT(
                'Content-Type',
                'application/json',
                'fsc-quantum-state',
                'livequery'
            ),
            OBJECT_CONSTRUCT(
                'jsonrpc',
                '2.0',
                'id',
                1,
                'method',
                'suix_getCoinMetadata',
                'params',
                ARRAY_CONSTRUCT(
                    coin_type
                )
            ),
            'Vault/prod/sui/quicknode/mainnet'
        ) :data: "result" AS DATA
    FROM
        coins
)
SELECT
    coin_type,
    DATA :decimals :: INT AS decimals,
    DATA :description :: STRING AS description,
    DATA :iconUrl :: STRING AS icon_url,
    DATA :name :: STRING AS NAME,
    DATA :symbol :: STRING AS symbol,
    DATA :id :: STRING AS id,
    {{ dbt_utils.generate_surrogate_key(['coin_type']) }} AS coin_metadata_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    lq
