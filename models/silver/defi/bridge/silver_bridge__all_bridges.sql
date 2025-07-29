-- depends_on: {{ ref('bronze__checkpoints') }}
{{ config (
    materialized = "view",
    tags = ['silver','defi','non_core']
) }}

WITH all_bridges AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('silver_bridge__sui_bridge_outbound'),
            ref('silver_bridge__sui_bridge_inbound'),            
            ref('silver_bridge__wormhole_inbound'),
            ref('silver_bridge__wormhole_outbound'),             
        ] 
    ) }}
)
SELECT
    checkpoint_number,
    block_timestamp,
    tx_digest,
    tx_sender,
    event_index,
    source_chain,
    destination_chain,
    amount,
    source_address,
    destination_address,
    coin_type,
    bridge_address,
    COALESCE(
        sui_bridge_outbound_id,
        sui_bridge_inbound_id,
        wormhole_outbound_id,
        wormhole_inbound_id
    ) AS all_bridges_id,
    inserted_timestamp,
    modified_timestamp,
    _INVOCATION_ID,
    CASE
        WHEN _dbt_source_relation LIKE '%inbound%' THEN 'inbound'
        WHEN _dbt_source_relation LIKE '%outbound%' THEN 'outbound'
    END AS direction,
    REPLACE(
        REPLACE(
            REPLACE(
                SPLIT_PART(
                    _dbt_source_relation,
                    '.',
                    3
                ),
                '_inbound',
                ''
            ),
            '_outbound',
            ''
        ),
        '_',
        ' '
    ) AS platform
FROM
    all_bridges
