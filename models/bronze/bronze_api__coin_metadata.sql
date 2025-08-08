{{ config (
    materialized = 'incremental',
    unique_key = "coin_type",
    merge_exclude_columns = ["inserted_timestamp"],
    full_refresh = false,
    tags = ['silver']
) }}

WITH coins AS (

    SELECT
        A.coin_type,
        x
    FROM
        (
            SELECT
                A.coin_type,
                COUNT(1) x
            FROM
                {{ ref('core__fact_balance_changes') }} A
            GROUP BY
                1
        ) A

{% if is_incremental() %}
LEFT JOIN (
    SELECT
        coin_type
    FROM
        {{ this }}
    WHERE
        decimals IS NOT NULL --rerun if decimals is null and inserted_timestamp is within the last 7 days (if the token still doesnt have decimals after 7 day then we will stop trying)
        OR (
            decimals IS NULL
            AND inserted_timestamp > CURRENT_DATE -7
            AND modified_timestamp :: DATE < CURRENT_DATE -2
        )
) b
ON A.coin_type = b.coin_type
WHERE
    b.coin_type IS NULL
{% endif %}
ORDER BY
    x DESC
LIMIT
    10
), lq AS (
    SELECT
        coin_type,
        {{ target.database }}.live.udf_api(
            'POST',
            {# '{Service}/{Authentication}', #}
            'https://sui-mainnet-endpoint.blockvision.org/',
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
            ) {# ,
            'Vault/prod/sui/quicknode/mainnet' #}
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
    DATA :id :: STRING AS object_id,
    {{ dbt_utils.generate_surrogate_key(['coin_type']) }} AS coin_metadata_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    lq
