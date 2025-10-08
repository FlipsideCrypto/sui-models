{{ config (
    materialized = "table"
) }}

WITH parsed_checkpoint_data AS (
    SELECT 
        -- Parse the VALUE JSON column
        PARSE_JSON(VALUE) as value_json,
        PARSE_JSON(DATA) as data_json,
        EPOCH
    FROM sui_dev.bronze.checkpoints_backfill
)

,

transformed_checkpoints AS (
    SELECT
        -- Extract checkpoint number (sequence_number in new format)
        value_json:sequence_number::NUMBER as CHECKPOINT_NUMBER,
        
        -- Convert timestamp_ms to proper timestamp format
        TO_TIMESTAMP(value_json:timestamp_ms::NUMBER / 1000) as BLOCK_TIMESTAMP,
        
        -- Create partition key (round down checkpoint to nearest 1000)
        FLOOR(value_json:sequence_number::NUMBER / 1000) * 1000 as PARTITION_KEY,
        
        -- Reconstruct the CHECKPOINT_JSON in the existing format
        OBJECT_CONSTRUCT(
            'checkpointCommitments', ARRAY_CONSTRUCT(),
            'digest', value_json:checkpoint_digest::STRING,
            'epoch', value_json:epoch::STRING,
            'epochRollingGasCostSummary', OBJECT_CONSTRUCT(
                'computationCost', value_json:computation_cost::STRING,
                'nonRefundableStorageFee', value_json:non_refundable_storage_fee::STRING,
                'storageCost', value_json:storage_cost::STRING,
                'storageRebate', value_json:storage_rebate::STRING
            ),
            'networkTotalTransactions', value_json:network_total_transaction::STRING,
            'previousDigest', value_json:previous_checkpoint_digest::STRING,
            'sequenceNumber', value_json:sequence_number::STRING,
            'timestampMs', value_json:timestamp_ms::STRING,
            -- Note: transactions array is not available in new format, using empty array
            -- In production, you may need to join with transaction data to populate this
            'transactions', ARRAY_CONSTRUCT(),
            'validatorSignature', value_json:validator_signature::STRING
        ) as CHECKPOINT_JSON,
        
        -- Set timestamps
        CURRENT_TIMESTAMP() as _INSERTED_TIMESTAMP,
        
        -- Generate surrogate key similar to existing format
        HASH(value_json:checkpoint_digest::STRING) as CHECKPOINTS_ID,
        
        CURRENT_TIMESTAMP() as INSERTED_TIMESTAMP,
        CURRENT_TIMESTAMP() as MODIFIED_TIMESTAMP
        
    FROM parsed_checkpoint_data
)

SELECT 
    CHECKPOINT_NUMBER,
    BLOCK_TIMESTAMP,
    PARTITION_KEY,
    CHECKPOINT_JSON,
    _INSERTED_TIMESTAMP,
    CHECKPOINTS_ID,
    INSERTED_TIMESTAMP,
    MODIFIED_TIMESTAMP
FROM transformed_checkpoints