{{ config (
    materialized = "view",
    post_hook = fsc_utils.if_data_call_function_v2(
        func = 'streamline.udf_bulk_rest_api_v2',
        target = "{{this.schema}}.{{this.identifier}}",
        params ={ "external_table" :"checkpoints",
        "sql_limit" :"3000000",
        "producer_batch_size" :"200000",
        "worker_batch_size" :"50000",
        "async_concurrent_requests" :"25",
        "sql_source" :"{{this.identifier}}",
        "order_by_column": "checkpoint_number DESC" }
    ),
    tags = ['streamline_realtime']
) }}

WITH checks AS (

    SELECT
        checkpoint_number
    FROM
        {{ ref("streamline__checkpoints") }}
    EXCEPT
    SELECT
        checkpoint_number
    FROM
        {{ ref("streamline__checkpoints_complete") }}
)
SELECT
    checkpoint_number,
    ROUND(
        checkpoint_number,
        -4
    ) :: INT AS partition_key,
    {{ target.database }}.live.udf_api(
        'POST',
        '{Service}/{Authentication}',
        OBJECT_CONSTRUCT(
            'Content-Type',
            'application/json'
        ),
        OBJECT_CONSTRUCT(
            'jsonrpc',
            '2.0',
            'id',
            checkpoint_number,
            'method',
            'sui_getCheckpoint',
            'params',
            ARRAY_CONSTRUCT(
                checkpoint_number :: STRING
            )
        ),
        'Vault/prod/sui/quicknode/mainnet'
    ) AS request
FROM
    checks
