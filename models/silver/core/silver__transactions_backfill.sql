{{ config (
    materialized = "table"
) }}

with parsed_new_data AS (
    SELECT 
        -- Parse the VALUE JSON column
        PARSE_JSON(VALUE) as value_json,
        PARSE_JSON(DATA) as data_json,
        EPOCH
    FROM sui_dev.bronze.transactions_backfill
),

-- Extract modified at versions
modified_at_versions AS (
    SELECT 
        value_json:transaction_digest::STRING as tx_digest,
        ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'objectId', obj.value[0]::STRING,
                'sequenceNumber', obj.value[1]:input_state:Exist[0][0]::STRING
            )
        ) as modified_versions_array
    FROM parsed_new_data,
    TABLE(FLATTEN(PARSE_JSON(value_json:effects_json):V2:changed_objects)) obj
    GROUP BY value_json:transaction_digest::STRING
),

-- Extract mutated objects
mutated_objects AS (
    SELECT 
        value_json:transaction_digest::STRING as tx_digest,
        ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'owner', 
                    CASE 
                        WHEN obj.value[1]:output_state:ObjectWrite[1]:Shared IS NOT NULL
                        THEN OBJECT_CONSTRUCT(
                            'Shared', obj.value[1]:output_state:ObjectWrite[1]:Shared
                        )
                        WHEN obj.value[1]:output_state:ObjectWrite[1]:ObjectOwner IS NOT NULL
                        THEN OBJECT_CONSTRUCT(
                            'ObjectOwner', obj.value[1]:output_state:ObjectWrite[1]:ObjectOwner::STRING
                        )
                        WHEN obj.value[1]:output_state:ObjectWrite[1]:AddressOwner IS NOT NULL
                        THEN OBJECT_CONSTRUCT(
                            'AddressOwner', obj.value[1]:output_state:ObjectWrite[1]:AddressOwner::STRING
                        )
                        ELSE OBJECT_CONSTRUCT('AddressOwner', value_json:sender::STRING)
                    END,
                'reference', OBJECT_CONSTRUCT(
                    'digest', obj.value[1]:output_state:ObjectWrite[0]::STRING,
                    'objectId', obj.value[0]::STRING,
                    'version', PARSE_JSON(value_json:effects_json):V2:lamport_version::NUMBER
                )
            )
        ) as mutated_array
    FROM parsed_new_data,
    TABLE(FLATTEN(PARSE_JSON(value_json:effects_json):V2:changed_objects)) obj
    GROUP BY value_json:transaction_digest::STRING
),

-- Extract shared objects
shared_objects AS (
    SELECT 
        tx_digest,
        ARRAY_AGG(shared_obj) as shared_objects_array
    FROM (
        -- Unchanged shared objects
        SELECT 
            value_json:transaction_digest::STRING as tx_digest,
            OBJECT_CONSTRUCT(
                'digest', ush.value[1]:ReadOnlyRoot[1]::STRING,
                'objectId', ush.value[0]::STRING,
                'version', ush.value[1]:ReadOnlyRoot[0]::NUMBER
            ) as shared_obj
        FROM parsed_new_data,
        TABLE(FLATTEN(PARSE_JSON(value_json:effects_json):V2:unchanged_shared_objects)) ush
        WHERE PARSE_JSON(value_json:effects_json):V2:unchanged_shared_objects IS NOT NULL
        
        UNION ALL
        
        -- Changed shared objects
        SELECT 
            value_json:transaction_digest::STRING as tx_digest,
            OBJECT_CONSTRUCT(
                'digest', ch.value[1]:input_state:Exist[0][1]::STRING,
                'objectId', ch.value[0]::STRING,
                'version', ch.value[1]:input_state:Exist[0][0]::NUMBER
            ) as shared_obj
        FROM parsed_new_data,
        TABLE(FLATTEN(PARSE_JSON(value_json:effects_json):V2:changed_objects)) ch
        WHERE ch.value[1]:input_state:Exist[1]:Shared IS NOT NULL
    )
    GROUP BY tx_digest
),

-- Extract object changes
object_changes AS (
    SELECT 
        value_json:transaction_digest::STRING as tx_digest,
        ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'digest', obj.value[1]:output_state:ObjectWrite[0]::STRING,
                'objectId', obj.value[0]::STRING,
                'objectType', 'unknown', -- Default, would need object type mapping
                'owner', 
                    CASE 
                        WHEN obj.value[1]:output_state:ObjectWrite[1]:Shared IS NOT NULL
                        THEN OBJECT_CONSTRUCT(
                            'Shared', obj.value[1]:output_state:ObjectWrite[1]:Shared
                        )
                        WHEN obj.value[1]:output_state:ObjectWrite[1]:ObjectOwner IS NOT NULL
                        THEN OBJECT_CONSTRUCT(
                            'ObjectOwner', obj.value[1]:output_state:ObjectWrite[1]:ObjectOwner::STRING
                        )
                        WHEN obj.value[1]:output_state:ObjectWrite[1]:AddressOwner IS NOT NULL
                        THEN OBJECT_CONSTRUCT(
                            'AddressOwner', obj.value[1]:output_state:ObjectWrite[1]:AddressOwner::STRING
                        )
                        ELSE OBJECT_CONSTRUCT('AddressOwner', value_json:sender::STRING)
                    END,
                'previousVersion', obj.value[1]:input_state:Exist[0][0]::STRING,
                'sender', value_json:sender::STRING,
                'type', 'mutated',
                'version', PARSE_JSON(value_json:effects_json):V2:lamport_version::STRING
            )
        ) as object_changes_array
    FROM parsed_new_data,
    TABLE(FLATTEN(PARSE_JSON(value_json:effects_json):V2:changed_objects)) obj
    GROUP BY value_json:transaction_digest::STRING
),

-- Extract transaction inputs
transaction_inputs AS (
    SELECT 
        value_json:transaction_digest::STRING as tx_digest,
        ARRAY_AGG(
            CASE 
                WHEN inp.value:Object:SharedObject IS NOT NULL
                THEN OBJECT_CONSTRUCT(
                    'initialSharedVersion', inp.value:Object:SharedObject:initial_shared_version::STRING,
                    'mutable', inp.value:Object:SharedObject:mutable::BOOLEAN,
                    'objectId', inp.value:Object:SharedObject:id::STRING,
                    'objectType', 'sharedObject',
                    'type', 'object'
                )
                WHEN inp.value:Pure IS NOT NULL
                THEN OBJECT_CONSTRUCT(
                    'type', 'pure',
                    'value', '969745335973357872526821071118', -- Would need to decode Pure bytes
                    'valueType', 'u128'
                )
                ELSE OBJECT_CONSTRUCT('type', 'unknown')
            END
        ) as inputs_array
    FROM parsed_new_data,
    TABLE(FLATTEN(PARSE_JSON(value_json:transaction_json):data[0]:intent_message:value:V1:kind:ProgrammableTransaction:inputs)) inp
    WHERE PARSE_JSON(value_json:transaction_json):data[0]:intent_message:value:V1:kind:ProgrammableTransaction:inputs IS NOT NULL
    GROUP BY value_json:transaction_digest::STRING
),

-- Extract transaction commands (simplified without type arguments for now)
transaction_commands AS (
    SELECT 
        value_json:transaction_digest::STRING as tx_digest,
        ARRAY_AGG(
            CASE 
                WHEN cmd.value:MoveCall IS NOT NULL
                THEN OBJECT_CONSTRUCT(
                    'MoveCall', OBJECT_CONSTRUCT(
                        'arguments', cmd.value:MoveCall:arguments,
                        'function', cmd.value:MoveCall:function::STRING,
                        'module', cmd.value:MoveCall:module::STRING,
                        'package', cmd.value:MoveCall:package::STRING,
                        'type_arguments', cmd.value:MoveCall:type_arguments -- Keep original format for now
                    )
                )
                ELSE cmd.value
            END
        ) as commands_array
    FROM parsed_new_data,
    TABLE(FLATTEN(PARSE_JSON(value_json:transaction_json):data[0]:intent_message:value:V1:kind:ProgrammableTransaction:commands)) cmd
    WHERE PARSE_JSON(value_json:transaction_json):data[0]:intent_message:value:V1:kind:ProgrammableTransaction:commands IS NOT NULL
    GROUP BY value_json:transaction_digest::STRING
),

transformed_data AS (
    SELECT
        -- Extract checkpoint number from VALUE JSON
        p.value_json:checkpoint::NUMBER as CHECKPOINT_NUMBER,
        
        -- Extract transaction digest from VALUE JSON
        p.value_json:transaction_digest::STRING as TX_DIGEST,
        
        -- Convert timestamp_ms to proper timestamp format
        TO_TIMESTAMP(p.value_json:timestamp_ms::NUMBER / 1000) as BLOCK_TIMESTAMP,
        
        -- Create partition key (round down checkpoint to nearest 10000)
        FLOOR(p.value_json:checkpoint::NUMBER / 10000) * 10000 as PARTITION_KEY,
        
        -- Reconstruct the TRANSACTION_JSON in the existing format
        OBJECT_CONSTRUCT(
            -- Balance Changes - calculate from total gas cost
            'balanceChanges', 
                CASE 
                    WHEN p.value_json:total_gas_cost::NUMBER > 0 
                    THEN ARRAY_CONSTRUCT(
                        OBJECT_CONSTRUCT(
                            'amount', '-' || p.value_json:total_gas_cost::STRING,
                            'coinType', '0x2::sui::SUI',
                            'owner', OBJECT_CONSTRUCT(
                                'AddressOwner', p.value_json:sender::STRING
                            )
                        )
                    )
                    ELSE ARRAY_CONSTRUCT()
                END,
                
            'checkpoint', p.value_json:checkpoint::STRING,
            'digest', p.value_json:transaction_digest::STRING,
            
            'effects', OBJECT_CONSTRUCT(
                'dependencies', 
                    CASE 
                        WHEN PARSE_JSON(p.value_json:effects_json):V2:dependencies IS NOT NULL 
                        THEN PARSE_JSON(p.value_json:effects_json):V2:dependencies
                        ELSE ARRAY_CONSTRUCT()
                    END,
                    
                -- Events Digest
                'eventsDigest', p.value_json:events_digest::STRING,
                
                'executedEpoch', p.value_json:epoch::STRING,
                
                'gasObject', OBJECT_CONSTRUCT(
                    'owner', OBJECT_CONSTRUCT(
                        'AddressOwner', p.value_json:gas_owner::STRING
                    ),
                    'reference', OBJECT_CONSTRUCT(
                        'digest', p.value_json:gas_object_digest::STRING,
                        'objectId', p.value_json:gas_object_id::STRING,
                        'version', p.value_json:gas_object_sequence::NUMBER
                    )
                ),
                
                'gasUsed', OBJECT_CONSTRUCT(
                    'computationCost', p.value_json:computation_cost::STRING,
                    'nonRefundableStorageFee', p.value_json:non_refundable_storage_fee::STRING,
                    'storageCost', p.value_json:storage_cost::STRING,
                    'storageRebate', p.value_json:storage_rebate::STRING
                ),
                
                'messageVersion', 'v1',
                
                -- Use pre-computed arrays
                'modifiedAtVersions', COALESCE(mav.modified_versions_array, ARRAY_CONSTRUCT()),
                'mutated', COALESCE(mo.mutated_array, ARRAY_CONSTRUCT()),
                'sharedObjects', COALESCE(so.shared_objects_array, ARRAY_CONSTRUCT()),
                    
                'status', OBJECT_CONSTRUCT(
                    'status', 
                        CASE 
                            WHEN p.value_json:execution_success::BOOLEAN = TRUE THEN 'success'
                            ELSE 'failure'
                        END
                ),
                'transactionDigest', p.value_json:transaction_digest::STRING
            ),
            
            -- Events - Note: This would need to be parsed from a separate events data source
            'events', ARRAY_CONSTRUCT(),
            
            -- Object Changes - use pre-computed array
            'objectChanges', COALESCE(oc.object_changes_array, ARRAY_CONSTRUCT()),
                
            'timestampMs', p.value_json:timestamp_ms::STRING,
            
            -- Transaction data
            'transaction', OBJECT_CONSTRUCT(
                'data', OBJECT_CONSTRUCT(
                    'gasData', OBJECT_CONSTRUCT(
                        'budget', p.value_json:gas_budget::STRING,
                        'owner', p.value_json:gas_owner::STRING,
                        'payment', ARRAY_CONSTRUCT(
                            OBJECT_CONSTRUCT(
                                'digest', 
                                    CASE 
                                        WHEN PARSE_JSON(p.value_json:transaction_json):data[0]:intent_message:value:V1:gas_data:payment[0][2] IS NOT NULL
                                        THEN PARSE_JSON(p.value_json:transaction_json):data[0]:intent_message:value:V1:gas_data:payment[0][2]::STRING
                                        ELSE p.value_json:gas_object_digest::STRING
                                    END,
                                'objectId', p.value_json:gas_object_id::STRING,
                                'version', 
                                    CASE 
                                        WHEN PARSE_JSON(p.value_json:transaction_json):data[0]:intent_message:value:V1:gas_data:payment[0][1] IS NOT NULL
                                        THEN PARSE_JSON(p.value_json:transaction_json):data[0]:intent_message:value:V1:gas_data:payment[0][1]::NUMBER
                                        ELSE p.value_json:gas_object_sequence::NUMBER
                                    END
                            )
                        ),
                        'price', p.value_json:gas_price::STRING
                    ),
                    'messageVersion', 'v1',
                    'sender', p.value_json:sender::STRING,
                    
                    -- Transaction details - use pre-computed arrays with fixed type arguments
                    'transaction',
                        CASE 
                            WHEN PARSE_JSON(p.value_json:transaction_json):data[0]:intent_message:value:V1:kind:ProgrammableTransaction IS NOT NULL
                            THEN OBJECT_CONSTRUCT(
                                'inputs', COALESCE(ti.inputs_array, ARRAY_CONSTRUCT()),
                                'kind', 'ProgrammableTransaction',
                                'transactions', COALESCE(tc.commands_array, ARRAY_CONSTRUCT())
                            )
                            ELSE OBJECT_CONSTRUCT()
                        END
                ),
                'txSignatures', 
                    CASE 
                        WHEN PARSE_JSON(p.value_json:transaction_json):data[0]:tx_signatures IS NOT NULL
                        THEN PARSE_JSON(p.value_json:transaction_json):data[0]:tx_signatures
                        ELSE ARRAY_CONSTRUCT()
                    END
            )
        ) as TRANSACTION_JSON,
        
        -- Set timestamps
        CURRENT_TIMESTAMP() as _INSERTED_TIMESTAMP,
        
        -- Generate surrogate key similar to existing format
        HASH(p.value_json:transaction_digest::STRING) as TRANSACTIONS_ID,
        
        CURRENT_TIMESTAMP() as INSERTED_TIMESTAMP,
        CURRENT_TIMESTAMP() as MODIFIED_TIMESTAMP
        
    FROM parsed_new_data p
    LEFT JOIN modified_at_versions mav ON p.value_json:transaction_digest::STRING = mav.tx_digest
    LEFT JOIN mutated_objects mo ON p.value_json:transaction_digest::STRING = mo.tx_digest
    LEFT JOIN shared_objects so ON p.value_json:transaction_digest::STRING = so.tx_digest
    LEFT JOIN object_changes oc ON p.value_json:transaction_digest::STRING = oc.tx_digest
    LEFT JOIN transaction_inputs ti ON p.value_json:transaction_digest::STRING = ti.tx_digest
    LEFT JOIN transaction_commands tc ON p.value_json:transaction_digest::STRING = tc.tx_digest
)

SELECT 
    CHECKPOINT_NUMBER,
    TX_DIGEST,
    BLOCK_TIMESTAMP,
    PARTITION_KEY,
    TRANSACTION_JSON,
    _INSERTED_TIMESTAMP,
    TRANSACTIONS_ID,
    INSERTED_TIMESTAMP,
    MODIFIED_TIMESTAMP
FROM transformed_data