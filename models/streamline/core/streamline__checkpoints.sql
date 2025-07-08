{{ config (
    materialized = "view",
    tags = ['streamline_view']
) }}

SELECT
    _id AS checkpoint_number
FROM
    {{ source(
        'crosschain_silver',
        'number_sequence'
    ) }}
WHERE
    _id >= 96605300
    AND _id <= (
        SELECT
            MAX(checkpoint_number)
        FROM
            {{ ref('streamline__chainhead') }}
    )
