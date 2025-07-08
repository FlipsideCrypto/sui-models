{{ config (
    materialized = "view",
    tags = ['streamline_view']
) }}

SELECT
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
            'sui_getLatestCheckpointSequenceNumber',
            'params',
            ARRAY_CONSTRUCT()
        ),
        'Vault/prod/sui/quicknode/mainnet'
    ) :data: "result" :: INT AS checkpoint_number
