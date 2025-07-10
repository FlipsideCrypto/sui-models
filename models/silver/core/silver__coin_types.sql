-- depends_on: {{ ref('bronze__transactions') }}
{{ config (
    materialized = "incremental",
    unique_key = "coin_type",
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['silver','core']
) }}

WITH coins AS (

    SELECT
        DISTINCT coin_type
    FROM
        {{ ref('core__fact_balance_changes') }}

{% if is_incremental() %}
WHERE
    modified_timestamp >= (
        SELECT
            MAX(modified_timestamp)
        FROM
            {{ this }}
    )
{% endif %}
)
SELECT
    coin_type,
    {{ dbt_utils.generate_surrogate_key(['coin_type']) }} AS coin_types_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    coins
