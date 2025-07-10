{{ config (
    materialized = "view",
    post_hook = fsc_utils.if_data_call_function_v2(
        func = 'streamline.udf_bulk_rest_api_v2',
        target = "{{this.schema}}.{{this.identifier}}",
        params ={ "external_table" :"transactions",
        "sql_limit" :"50000",
        "producer_batch_size" :"50000",
        "worker_batch_size" :"25000",
        "sql_source" :"{{this.identifier}}",
        'exploded_key': '["result"]',
        "order_by_column": "checkpoint_number" }
    ),
    tags = ['streamline_realtime']
) }}

WITH {# last_3_days AS (

SELECT
    sequence_number
FROM
    {{ ref("_sequence_lookback") }}
),
#}
txs AS (
    SELECT
        A.tx_digest,
        A.tx_index,
        A.checkpoint_number,
        A.block_timestamp
    FROM
        {{ ref("streamline__transactions") }} A
        LEFT JOIN {{ ref("streamline__transactions_complete") }}
        b
        ON A.tx_digest = b.tx_digest
        AND A.block_timestamp :: DATE = b.block_timestamp :: DATE
    WHERE
        b.tx_digest IS NULL {# AND sequence_number >= (
    SELECT
        sequence_number
    FROM
        last_3_days
) #}
),
tx_grouped AS (
    SELECT
        checkpoint_number,
        block_timestamp,
        FLOOR(
            tx_index / 50
        ) grp,
        ARRAY_AGG(
            tx_digest
        ) AS tx_param,
        COUNT(1) AS tx_count_in_request
    FROM
        txs
    GROUP BY
        checkpoint_number,
        block_timestamp,
        grp
)
SELECT
    checkpoint_number,
    tx_count_in_request,
    to_char(
        block_timestamp,
        'YYYY_MM_DD_HH_MI_SS_FF3'
    ) AS block_timestamp,
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
            'sui_multiGetTransactionBlocks',
            'params',
            ARRAY_CONSTRUCT(
                tx_param,
                OBJECT_CONSTRUCT(
                    'showInput',
                    TRUE,
                    'showRawInput',
                    FALSE,
                    'showEffects',
                    TRUE,
                    'showEvents',
                    TRUE,
                    'showRawEffects',
                    FALSE,
                    'showObjectChanges',
                    TRUE,
                    'showBalanceChanges',
                    TRUE
                )
            )
        ),
        'Vault/prod/sui/quicknode/mainnet'
    ) AS request
FROM
    tx_grouped
