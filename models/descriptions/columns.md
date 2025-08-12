{% docs checkpoint_number %}
The sequential number of the checkpoint in which this record was finalized on the Sui blockchain. Checkpoints are consensus milestones that bundle and finalize multiple transactions, providing the primary unit of finality and recovery in Sui. Starts at 0 (genesis checkpoint) and increments by one for each new checkpoint. Used for time series analysis, transaction ordering, and measuring network throughput. Once a transaction is included in a checkpoint, it is permanently recorded and cannot be reverted. This dataset only includes checkpoints greater than or equal to 96605300. Example: 96605301.
{% enddocs %}

{% docs block_timestamp %}
The network-agreed timestamp (in milliseconds since Unix epoch) when the checkpoint containing this record was finalized by Sui consensus. Represents the authoritative time of transaction finality, as determined by validator signatures. Used for temporal analytics, trend analysis, and aligning on-chain activity with real-world time. Example: '2024-06-01 12:34:56.789'.
{% enddocs %}

{% docs tx_digest %}
A 32-byte cryptographic hash (Base58-encoded) uniquely identifying the transaction's contents and structure. Serves as the primary key for transaction lookup, integrity verification, and cross-model joins. Enables cryptographic proof of transaction inclusion and supports lineage tracing across all Sui analytics. Example: '6Qk8...9Xz'.
{% enddocs %}

{% docs tx_kind %}
The type of transaction executed. Values include 'Programmable Transaction Block' (PTB) for user-submitted transactions (up to 1,024 commands) and 'System Transaction' for validator/network operations. Determines execution path, available operations, and analytics grouping. Example: 'ProgrammableTransactionBlock'.
{% enddocs %}

{% docs tx_sender %}
The 32-byte Sui address (hex with 0x prefix) that initiated and signed the transaction. Identifies the account responsible for the transaction and gas payment. Used for user activity tracking, wallet analytics, and authorization analysis. Example: '0xabc123...'.
{% enddocs %}

{% docs message_version %}
The version of the transaction data structure, supporting protocol evolution and backward compatibility. Currently uses 'TransactionDataV1'. Ensures analytics remain robust across protocol upgrades. Example: '1'.
{% enddocs %}

{% docs tx_succeeded %}
Boolean flag indicating transaction execution outcome. true = success, false = error. Used for outcome analysis, error monitoring, and success rate tracking. Example: true.
{% enddocs %}

{% docs tx_fee %}
Total gas fee paid for transaction execution, denominated in SUI tokens. Calculated as (computation_cost + storage_cost - storage_rebate) / 1e9. Used for economic modeling, fee optimization, and cost analysis. Example: 0.00123 (SUI).
{% enddocs %}

{% docs tx_error %}
Error message and code if the transaction failed. Human-readable string with error details for diagnostics, debugging, and error pattern analysis. Example: 'MoveAbort: InsufficientBalance'.
{% enddocs %}

{% docs tx_dependencies %}
Array of transaction digests that this transaction depends on for object versions. Establishes transaction ordering and causality, supporting dependency analysis and complex flow tracing. Example: ['6Qk8...9Xz', '7Yl2...3Ab'].
{% enddocs %}

{% docs gas_used_computation_cost %}
Total computation cost in MIST units (1 SUI = 1e9 MIST) for executing the transaction. Calculated as computation_units * gas_price. Used for analyzing transaction complexity and validator workload. Example: 1000000.
{% enddocs %}

{% docs gas_used_non_refundable_storage_fee %}
Portion of storage fees (in MIST) that cannot be reclaimed, ensuring storage fund sustainability. Calculated as storage_units * storage_price * 0.01. Used for economic modeling and storage fund analysis. Example: 10000.
{% enddocs %}

{% docs gas_used_storage_cost %}
Total cost (in MIST) for storing data on-chain. Calculated as storage_units * storage_price. Users pay this upfront for perpetual storage. Used for storage analytics and cost modeling. Example: 500000.
{% enddocs %}

{% docs gas_used_storage_rebate %}
Refund amount (in MIST) when previously stored data is deleted. Calculated as original_storage_fee * 0.99. Incentivizes data cleanup and efficient storage usage. Example: 495000.
{% enddocs %}

{% docs gas_price %}
User-submitted price per computation unit (in MIST). Structure: reference_gas_price + optional tip. Determines transaction priority and total cost. Used for fee market analysis and optimization. Example: 1000.
{% enddocs %}

{% docs gas_budget %}
Maximum amount (in MIST) user is willing to pay for transaction execution. Protects users from excessive fees. Minimum: 2,000 MIST, Maximum: 50,000,000,000 MIST. Used for transaction planning and cost control. Example: 1000000.
{% enddocs %}

{% docs gas_owner %}
Sui address responsible for paying gas fees. Enables sponsored transactions (third-party gas payment). Used for payment model analytics and gasless UX studies. Example: '0xabc123...'.
{% enddocs %}

{% docs balance_change_index %}
Zero-based index ordering balance changes within a transaction. Tracks the sequence of balance modifications for accurate financial analysis and reconciliation. Example: 0.
{% enddocs %}

{% docs coin_type %}
Fully qualified Move type identifier for coins/tokens. Format: {package}::{module}::{struct}. Example: '0x2::sui::SUI' for native SUI token. Essential for DeFi analytics, token classification, and cross-asset analysis.
{% enddocs %}

{% docs amount %}
Token quantity in the smallest unit (MIST for SUI). Integer value; 1 SUI = 1,000,000,000 MIST. Used for precise financial calculations, balance tracking, and token flow analysis. Example: 1000000000.
{% enddocs %}

{% docs amount_raw %}
Token quantity in the smallest unit (MIST for SUI). Integer value; 1 SUI = 1,000,000,000 MIST. Used for precise financial calculations, balance tracking, and token flow analysis. Example: 1000000000.
{% enddocs %}

{% docs owner %}
Ownership information for objects or balances. Enum: Address (user), Shared (requires consensus), Immutable (cannot change). Determines accessibility and is critical for wallet analytics, ownership distribution, and access control studies. Example: 'Address'.
{% enddocs %}

{% docs change_index %}
Zero-based sequential index ordering object state changes within a transaction. Ensures atomicity and correct ordering for analytics and lineage tracing. Example: 2.
{% enddocs %}

{% docs type %}
Type/category of object state modification or event. Enum: created, modified, deleted, wrapped, unwrapped (for changes); event type string (for events). Used for lifecycle analysis and state transition tracking. Example: 'created'.
{% enddocs %}

{% docs sender %}
Sui address (32-byte hex) representing the transaction or event sender. Used for authorization, security analysis, and user activity tracking. Example: '0xabc123...'.
{% enddocs %}

{% docs receiver %}
Sui address (32-byte hex) representing the transaction or event receiver. Used for tracking destination addresses, transfer flows, and recipient analytics. In transfer contexts, this is the address receiving tokens or assets. Example: '0xdef456...'.
{% enddocs %}

{% docs ez_transfers_id %}
Surrogate key for the enhanced transfers table. Generated unique identifier by combining transaction digest and balance change index, ensuring each transfer event enriched with token metadata is uniquely addressable. Used as the primary key for user-friendly transfer analytics, dashboard queries, and cross-model joins. In Sui, this supports transfer analysis with normalized amounts and token symbols, enabling easy identification and comparison of token movements.
{% enddocs %}

{% docs fact_transfers_id %}
Surrogate key for the core fact transfers table. Generated unique identifier by combining transaction digest and balance change index, ensuring each transfer event is uniquely addressable. Used as the primary key for transfer tracking, analytics workflows, and cross-model joins. In Sui, this supports precise transfer analysis, portfolio tracking, and compliance reporting by enabling unique identification of each token movement between addresses.
{% enddocs %}

{% docs digest %}
32-byte cryptographic hash (hex) of object contents, using SHA-256. Used for content verification, integrity checking, and unauthorized modification detection. Example: 'a1b2c3...'.
{% enddocs %}

{% docs object_id %}
Globally unique 32-byte identifier for Sui objects. Hex string, primary key for object tracking, provenance, and asset history. Example: '0x1234abcd...'.
{% enddocs %}

{% docs object_type %}
Move type signature governing the object's structure and behavior. Format: {package}::{module}::{struct}<type_parameters>. Enables type-based classification and filtering. Example: '0x2::coin::Coin<0x2::sui::SUI>'.
{% enddocs %}

{% docs version %}
8-byte unsigned integer incremented with every object modification. Tracks mutation frequency and supports version-based conflict resolution. Initial value: 1. Example: 5.
{% enddocs %}

{% docs previous_version %}
Version number immediately preceding the current object version. Enables historical state reconstruction and audit trails. Value: current_version - 1 (0 for initial creation). Example: 4.
{% enddocs %}

{% docs object_owner %}
Indicates how the object is owned and accessed. Types: Address-owned, Shared (consensus), Immutable (public), Object-owned. Determines access patterns and transaction requirements. Example: 'Shared'.
{% enddocs %}

{% docs epoch %}
Epoch number (integer) representing a fixed period (~24h) with a stable validator set and protocol configuration. Used for tracking validator changes, protocol upgrades, and time-based partitioning. Example: 42.
{% enddocs %}

{% docs checkpoint_digest %}
32-byte cryptographic hash (Base58) uniquely identifying checkpoint contents. Used for checkpoint verification, integrity checking, and chain continuity. Example: '6Qk8...9Xz'.
{% enddocs %}

{% docs previous_digest %}
Hash of the previous checkpoint, maintaining blockchain continuity. Used for history verification and chain analysis. Example: '5Jk7...8Yz'.
{% enddocs %}

{% docs network_total_transactions %}
Cumulative count of all transactions processed by the network up to this checkpoint. Monotonically increasing integer, key metric for network growth, adoption, and throughput analysis. Example: 10000000.
{% enddocs %}

{% docs validator_signature %}
Aggregated BLS signature (Base64) from validator quorum (>2/3) for checkpoint finality. Provides Byzantine fault-tolerant consensus proof. Used for security analysis and validator participation tracking. Example: 'MEUCIQ...'.
{% enddocs %}

{% docs tx_count %}
Total number of transactions included in the checkpoint. Used for measuring checkpoint size, throughput, and network performance. Example: 250.
{% enddocs %}

{% docs transactions_array %}
Array of transaction digests included in the checkpoint. Used for transaction finality tracking, checkpoint analysis, and reconstructing checkpoint composition. Example: ['6Qk8...9Xz', '7Yl2...3Ab'].
{% enddocs %}

{% docs event_index %}
Zero-based index ordering events within a transaction. Ensures deterministic event ordering for sequence reconstruction and analytics. Example: 1.
{% enddocs %}

{% docs event_address %}
Sui address (32-byte hex) that triggered the event emission. Used for filtering, access control, and user activity analytics. Example: '0xabc123...'.
{% enddocs %}

{% docs event_module %}
Name of the Move module that emitted the event. Used for module-specific event filtering and analytics. Example: 'coin'.
{% enddocs %}

{% docs event_resource %}
Fully qualified type signature of the event struct. Format: {package_id}::{module}::{struct_name}<type_parameters>. Enables type-safe event deserialization and schema tracking. Example: '0x2::coin::TransferEvent<0x2::sui::SUI>'.
{% enddocs %}

{% docs package_id %}
Unique identifier (object ID) of the Move package containing the event module. Used for package-level analytics, deployment tracking, and contract lineage. Example: '0x2'.
{% enddocs %}

{% docs transaction_module %}
Name of the module executed in the transaction that emitted the event. Links events to transaction context for flow analysis. Example: 'pay_sui'.
{% enddocs %}

{% docs parsed_json %}
JSON object representing the event data, with structure varying by event type. Provides structured, machine-readable event data for analytics, dApp monitoring, and real-time applications. Example: {"amount": "1000000", "recipient": "0xabc..."}.
{% enddocs %}

{% docs input_index %}
Zero-based index referencing inputs within a programmable transaction block. Links commands to their inputs for dependency and resource usage analysis. Example: 0.
{% enddocs %}

{% docs value %}
Actual data content of the object or input value, encoded using Binary Canonical Serialization (BCS). Used for content analysis, debugging, and advanced analytics. Example: '0x010203...'.
{% enddocs %}

{% docs value_type %}
Move type of the object's value content or input value type. Fully qualified type name with generics, supporting type-safe deserialization and schema evolution. Example: '0x2::coin::Coin<0x2::sui::SUI>'.
{% enddocs %}

{% docs initial_shared_version %}
Version number at which an object was first shared. Nullable u64 (None for non-shared objects). Determines consensus requirements and helps analyze shared object contention. Example: 3.
{% enddocs %}

{% docs mutable %}
Boolean flag indicating if the object can be modified. true = mutable, false = immutable. Affects performance, access patterns, and caching. Example: true.
{% enddocs %}

{% docs payload_index %}
Zero-based index of the payload within a programmable transaction block. Orders transaction commands for flow analysis. Example: 0.
{% enddocs %}

{% docs payload_type %}
Type of command in a programmable transaction block. Values: MoveCall, TransferObjects, SplitCoins, etc. Used for dApp interaction and protocol analytics. Example: 'MoveCall'.
{% enddocs %}

{% docs payload_details %}
Structured details about the specific payload command. Varies by payload type; includes all arguments and context. Used for deep transaction and smart contract analytics. Example: {"function": "transfer", "args": ["0xabc...", 1000]}.
{% enddocs %}

{% docs inserted_timestamp %}
Timestamp when the record was inserted into the analytics database. System-generated by the ETL pipeline, typically in TIMESTAMP_NTZ format. Used for data lineage, ETL monitoring, and freshness checks. In Sui analytics, this field is essential for tracking data ingestion latency, validating pipeline health, and supporting incremental model builds. Example: '2024-06-01 12:34:56.789'.
{% enddocs %}

{% docs modified_timestamp %}
Timestamp when the record was last modified in the analytics database. System-generated for change tracking, data versioning, and consistency verification. In Sui, this supports incremental processing, late-arriving data correction, and auditability of analytics workflows. Used to monitor data staleness and trigger downstream updates. Example: '2024-06-01 12:34:56.789'.
{% enddocs %}

{% docs fact_checkpoints_id %}
Surrogate key for the checkpoint fact table. Generated unique identifier for each checkpoint record, typically constructed from the checkpoint number or digest. Ensures row-level uniqueness and supports efficient joins, indexing, and lineage tracing across all checkpoint-related analytics. In Sui, this enables fast correlation of checkpoint metadata with transactions, validator signatures, and epoch transitions. Essential for time series analysis, network health monitoring, and data integrity verification.
{% enddocs %}

{% docs fact_events_id %}
Surrogate key for the events fact table. Generated unique identifier combining transaction digest and event index, ensuring each event emission is uniquely addressable. Used as the primary key for event tracking, analytics workflows, and cross-model joins. In Sui, this supports granular dApp analytics, protocol monitoring, and event-driven application logic by enabling precise event referencing and lineage analysis.
{% enddocs %}

{% docs fact_transaction_balance_changes_id %}
Surrogate key for the balance changes fact table. Generated unique identifier by combining transaction digest and balance change index, guaranteeing uniqueness for each balance change event. Critical for financial analysis, reconciliation, and tracking token flows at the most granular level. In Sui, this enables accurate wallet balance reconstruction, detection of large transfers, and portfolio analytics across all addresses and token types.
{% enddocs %}

{% docs fact_changes_id %}
Surrogate key for the object changes fact table. Generated unique identifier by combining transaction digest and change index, ensuring each object state transition is uniquely tracked. Supports object lifecycle analysis, state tracking, and forensic investigations. In Sui, this is essential for tracing the full history of NFTs, coins, and other on-chain objects, supporting compliance, provenance, and application behavior analytics.
{% enddocs %}

{% docs fact_transaction_blocks_id %}
Surrogate key for the transaction blocks fact table. Generated unique identifier based on transaction digest, providing a one-to-one mapping to each transaction block. Enables efficient transaction-level analysis, performance monitoring, and lineage tracing from transaction inputs to execution outcomes. In Sui, this is critical for understanding transaction dependencies, gas usage, and execution results at scale.
{% enddocs %}

{% docs fact_transaction_inputs_id %}
Surrogate key for the transaction inputs fact table. Generated unique identifier by combining transaction digest and input index, ensuring each input to a transaction is uniquely addressable. Supports dependency analysis, resource utilization tracking, and validation of transaction atomicity. In Sui, this enables detailed tracing of input objects, shared object usage, and parallel execution patterns.
{% enddocs %}

{% docs fact_transactions_id %}
Surrogate key for the transactions fact table. Generated unique identifier by combining transaction digest and payload index, uniquely identifying each command or payload within a programmable transaction block. Essential for command-level analytics, smart contract interaction tracking, and composability analysis in Sui's multi-command transaction model.
{% enddocs %}

{% docs dim_tokens_id %}
Surrogate key for the tokens dimension table. Generated unique identifier for each token metadata record, typically derived from the coin type or on-chain metadata. Enables efficient token lookups, joins across fact tables, and lineage tracing from raw on-chain data to analytics-ready attributes. In Sui, this is critical for accurate token identification, decimal normalization, and cross-model analytics involving token flows and balances.
{% enddocs %}

{% docs ez_bridge_activity_id %}
Surrogate key for the events table. Generated unique identifier combining transaction digest and event index, ensuring each event emission is uniquely addressable. Used as the primary key for event tracking, analytics workflows, and cross-model joins. In Sui, this supports granular dApp analytics, protocol monitoring, and event-driven application logic by enabling precise event referencing and lineage analysis.
{% enddocs %}

{% docs coin_types_id %}
Surrogate key for coin types. Generated unique identifier for each coin type, supporting classification, indexing, and efficient joins across analytics queries. In Sui, this enables fast aggregation and filtering by token type, supporting DeFi analytics, token velocity studies, and ecosystem-wide token usage analysis.
{% enddocs %}

{% docs decimals %}
Number of decimal places for the token. Integer value defining token precision (e.g., 9 for SUI means 1 SUI = 1,000,000,000 MIST). Essential for accurate token amount calculations, display formatting, and cross-token analytics. Example: 9.
{% enddocs %}

{% docs symbol %}
Short string symbol for the token (e.g., 'SUI', 'USDC'). Used for user-friendly token identification, UI display, and analytics grouping. Example: 'SUI'.
{% enddocs %}

{% docs name %}
Full descriptive name of the token. Human-readable string for complete token identification, used in interfaces and analytics. Example: 'Sui Token'.
{% enddocs %}

{% docs description %}
Detailed description of the token's purpose, features, and technical details. Used for documentation, analytics, and user interfaces. Example: 'Native token of the Sui blockchain, used for gas and staking.'
{% enddocs %}

{% docs icon_url %}
Web URL pointing to the token's icon image. Used for visual representation in wallets, dApps, and analytics dashboards. Example: 'https://assets.sui.io/icons/sui.svg'.
{% enddocs %}

{% docs id %}
Unique identifier for the token metadata record, linking metadata to on-chain token types. Used for metadata management, registry operations, and analytics joins. Example: 'tokenmeta_123'.
{% enddocs %}

{% docs address_owner %}
The 32-byte Sui address (hex with 0x prefix) that owns this object when it has address-based ownership. Address-owned objects are controlled by a specific account and can only be accessed by their owner, providing exclusive control and enabling efficient parallel processing since they don't require consensus. Used for wallet analytics, ownership tracking, and transaction authorization analysis. When null, the object has a different ownership type (shared, immutable, or object-owned). Example: '0xabc123...'.
{% enddocs %}

{% docs shared_owner %}
Variant data structure indicating this object has shared ownership, meaning it's accessible to everyone on the network and requires consensus validation for modifications. Shared objects enable coordination between multiple addresses but incur higher transaction costs due to consensus requirements. Used for marketplaces, escrows, AMMs, and other multi-user scenarios. Contains metadata about the shared object's initial version and access permissions. When null, the object has address-based, immutable, or object-based ownership. Example: {"initial_shared_version": 123}.
{% enddocs %}

{% docs modules %}
Comma-separated list of Move module names contained within the package. Modules define the package's functionality and can be called by transactions to execute smart contract logic. Each module has a unique name within its package and contains functions, structs, and resources. Used for analyzing package composition, tracking module usage patterns, and understanding smart contract functionality. Example: 'coin,transfer,governance'.
{% enddocs %}

{% docs amount_normalized %}
Decimal-adjusted token amount calculated by dividing the raw amount by 10^decimals. Provides human-readable token quantities that can be directly compared across different token types. Essential for financial analysis, balance calculations, and user-facing applications where raw blockchain amounts need to be converted to meaningful values. Example: if amount is 1000000000 and decimals is 9, amount_normalized would be 1.0.
{% enddocs %}

{% docs token_is_verified %}
Boolean flag indicating whether the token or price record is verified by Flipside's crosschain curation process. Verified tokens are prioritized for analytics and are considered reliable for most use cases. Unverified tokens may be incomplete, deprecated, or experimental.
{% enddocs %} 



{% docs prices_ez_asset_metadata_table_doc %}

A convenience table holding prioritized asset metadata and other relevant details pertaining to each token_address and native asset. This data set is highly curated and contains metadata for one unique asset per blockchain.

{% enddocs %}


{% docs prices_ez_prices_hourly_table_doc %}

A convenience table for determining token prices by address and blockchain, and native asset prices by symbol and blockchain. This data set is highly curated and contains metadata for one price per hour per unique asset and blockchain.

{% enddocs %}

{% docs prices_provider %}

The provider or source of the data.

{% enddocs %}

{% docs prices_asset_id %}

The unique identifier representing the asset.

{% enddocs %}

{% docs prices_name %}

The name of asset.

{% enddocs %}

{% docs prices_symbol %}

The symbol of asset.

{% enddocs %}

{% docs prices_token_address %}

The specific address representing the asset on a specific platform. This will be NULL if referring to a native asset.

{% enddocs %}

{% docs prices_blockchain %}

The Blockchain, Network, or Platform for this asset.

{% enddocs %}

{% docs prices_blockchain_id %}

The unique identifier of the Blockchain, Network, or Platform for this asset.

{% enddocs %}

{% docs prices_decimals %}

The number of decimals for the asset. May be NULL.

{% enddocs %}

{% docs prices_is_native %}

A flag indicating assets native to the respective blockchain.

{% enddocs %}

{% docs prices_is_deprecated %}

A flag indicating if the asset is deprecated or no longer supported by the provider.

{% enddocs %}

{% docs prices_id_deprecation %}

Deprecating soon! Please use the `asset_id` column instead.

{% enddocs %}

{% docs prices_decimals_deprecation %}

Deprecating soon! Please use the decimals column in `ez_asset_metadata` or join in `dim_contracts` instead.

{% enddocs %}

{% docs prices_hour %}

Hour that the price was recorded at.

{% enddocs %}

{% docs prices_price %}

Closing price of the recorded hour in USD.

{% enddocs %}

{% docs prices_is_imputed %}

A flag indicating if the price was imputed, or derived, from the last arriving record. This is generally used for tokens with low-liquidity or inconsistent reporting.

{% enddocs %}

{% docs prices_open %}

Opening price of the recorded hour in USD.

{% enddocs %}

{% docs prices_high %}

Highest price of the recorded hour in USD

{% enddocs %}

{% docs prices_low %}

Lowest price of the recorded hour in USD

{% enddocs %}

{% docs prices_close %}

Closing price of the recorded hour in USD

{% enddocs %}


{% docs amount_usd %}

USD value of the amount at transaction time.

Example: 1000.50

{% enddocs %}


{% enddocs %}

{% docs ez_bridge_activity_platform %}

The protocol or application facilitating the cross-chain bridge transfer.

Example: 'wormhole'

{% enddocs %}

{% docs ez_bridge_activity_protocol %}

The protocol or application facilitating the cross-chain bridge transfer.

Example: 'wormhole'

{% enddocs %}

{% docs ez_bridge_activity_protocol_version %}

The version of  protocol or application facilitating the cross-chain bridge transfer.

Example: 'v1'

{% enddocs %}

{% docs ez_bridge_activity_direction %}

The directions of the cross-chain bridge transfer.

Example: 'inbound'

{% enddocs %}

{% docs ez_bridge_activity_sender %}

The Sui address that directly sent tokens to the bridge contract.

Example: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890'

{% enddocs %}

{% docs ez_bridge_activity_receiver %}

The address designated to receive tokens on the destination chain (or on the source chain, for intermediate steps).

Example: '0x9876543210987654321098765432109876543210987654321098765432109876'

{% enddocs %}


{% docs ez_bridge_activity_destination_chain %}

The target blockchain network for the bridged assets.

Example: 'ethereum'

{% enddocs %}

{% docs ez_bridge_activity_source_chain %}

The originating blockchain network for the bridged assets.

Example: 'ethereum'

{% enddocs %}

{% docs ez_bridge_activity_bridge_address %}

The Sui object or package address handling the bridge operation.

Example: '0x26efee2b51c911237888e5dc6702868abca3c7ac12c53f76ef8eba0697695e3d'

{% enddocs %}

{% docs ez_bridge_activity_coin_type %}

The coin type or token identifier for the asset being bridged on Sui.

Example: '0x2::sui::SUI'

{% enddocs %}

{% docs ez_bridge_activity_token_symbol %}

The symbol identifier for the bridged token.

Example: 'SUI'

{% enddocs %}

{% docs ez_bridge_activity_amount_unadj %}

The raw token amount without decimal adjustment.

Example: 1000000000

{% enddocs %}

{% docs ez_bridge_activity_amount %}

The decimal-adjusted amount of tokens bridged.

Example: 1.0

{% enddocs %}

{% docs ez_bridge_activity_amount_usd %}

The hourly close USD value of bridged tokens at the time of the transaction.

Example: 1000.50

{% enddocs %}

{% docs ez_bridge_activity_token_is_verified %}

Whether the token is verified by the Flipside team.

Example: true

{% enddocs %}

{% docs platform_address %}
The smart contract address of the DEX platform that facilitated this swap. This represents the deployed contract address for the specific DEX protocol on the Sui blockchain. Used for contract verification, security analysis, and linking to platform-specific metadata and configurations. Essential for protocol-specific analysis and filtering across different DeFi platforms.
{% enddocs %}

{% docs pool_address %}
The address of the liquidity pool involved in the swap. For protocols that use AMM (Automated Market Maker) pools, this identifies the specific pool contract. May be NULL for order book-based protocols like DeepBook or centralized limit order protocols. Essential for pool-specific analytics, liquidity analysis, and understanding which pools are most active for different token pairs.
{% enddocs %}

{% docs amount_in_raw %}
The raw amount of tokens being swapped in (input amount) before any decimal adjustments. This represents the exact on-chain token amount as it appears in the swap event. Preserves precision for accurate calculations and is essential for volume analysis, price impact calculations, and swap size distribution analysis. Critical for calculating swap rates and understanding the actual token amounts exchanged in each swap.
{% enddocs %}

{% docs amount_out_raw %}
The raw amount of tokens being swapped out (output amount) before any decimal adjustments. This represents the exact on-chain token amount that the user receives from the swap. Critical for calculating swap rates, slippage analysis, and understanding the actual token amounts exchanged in each swap. Essential for volume analysis and swap size distribution analysis.
{% enddocs %}

{% docs a_to_b %}
A boolean flag indicating the direction of the swap within the pool. When TRUE, the swap goes from token A to token B; when FALSE, it goes from token B to token A. This field is protocol-specific and may be NULL for some DEX platforms. Important for understanding swap direction and pool token ordering conventions. Follows each protocol's specific pool token ordering conventions.
{% enddocs %}

{% docs fee_amount_raw %}
The raw amount of fees charged for the swap transaction. This includes protocol fees, liquidity provider fees, and any other transaction costs. May be 0 for protocols that don't charge explicit fees or when fees are embedded in the swap amounts. Essential for fee revenue analysis and total cost of trading calculations. For some protocols like Aftermath, this may be NULL as fees are handled differently.
{% enddocs %}

{% docs partner_address %}
The address of a partner or affiliate that facilitated the swap (if applicable). Used primarily by Cetus for their partner program where swaps can be routed through partner contracts. May be NULL for most protocols or when no partner was involved. Useful for tracking partner performance and affiliate program analytics within the DEX ecosystem.
{% enddocs %}

{% docs steps %}
The number of steps or hops required to complete the swap. For simple swaps, this is typically 1. For complex swaps involving multiple pools or routing through multiple protocols, this indicates the number of intermediate steps. Essential for understanding swap complexity and routing efficiency across different protocols. Critical for analyzing multi-hop swaps and routing optimization.
{% enddocs %}

{% docs token_in_type %}
The full type identifier of the token being swapped in (input token). This follows Sui's Move type format (e.g., "0x2::sui::SUI" for the native SUI token). Essential for token identification, pricing lookups, and token-specific analytics. Used for calculating USD values and token pair analysis. Some models ensure proper formatting by adding '0x' prefix if missing.
{% enddocs %}

{% docs token_out_type %}
The full type identifier of the token being swapped out (output token). This follows Sui's Move type format and represents the token that the user receives from the swap. Critical for token pair analysis, swap rate calculations, and understanding token flow patterns across the DeFi ecosystem. Some models ensure proper formatting by adding '0x' prefix if missing.
{% enddocs %}

{% docs trader_address %}
The address of the wallet or account that initiated the swap. May be NULL for some protocols that don't explicitly track the trader address in their events. Essential for user behavior analysis, wallet tracking, and understanding individual trader patterns and preferences across different DEX platforms. For some protocols like Aftermath, this is extracted from the transaction sender.
{% enddocs %}

{% docs dex_swaps_id %}
A unique surrogate key generated from the combination of transaction identifiers and swap details. For the general DEX table, this combines tx_digest and event_index. For protocol-specific tables like Aftermath, this may include additional fields like trader_address, token_in_type, token_out_type, amount_in_raw, and amount_out_raw. This provides a stable, unique identifier for each swap event that can be used as a primary key for downstream analytics and data modeling. Ensures data integrity and prevents duplicate processing.
{% enddocs %}

{% docs platform %}
The name of the decentralized exchange platform where the swap occurred. Currently supports seven major Sui DEX protocols: Cetus, Turbos, Bluefin, Aftermath AMM, FlowX, DeepBook, and Momentum. This field enables protocol-specific analysis, performance comparison, and market share calculations across different DeFi platforms. Essential for filtering and grouping swap data by protocol.
{% enddocs %}

{% docs referral_amount_raw %}
The raw amount of referral rewards or commissions generated from this swap. Used by Cetus for their referral program to track referral program payouts. May be 0 for protocols without referral programs or when no referral was used. Important for referral program analytics and partner performance tracking. Essential for understanding the economic incentives and reward structures within DeFi protocols.
{% enddocs %}

{% docs _invocation_id %}
A unique identifier for the dbt run that created or updated this record. This field is used for data lineage tracking and debugging purposes. Helps identify which specific dbt execution was responsible for processing each record and enables traceability back to the source code and configuration used. Essential for ETL monitoring, data quality tracking, and troubleshooting pipeline issues.
{% enddocs %}

{% docs platform_name %}
The human-readable name of the DEX platform, derived from address labeling or defaulting to the platform address if no label exists. This field provides user-friendly platform identification for analytics, reporting, and dashboard displays. Examples include "Cetus AMM", "Turbos Finance", "Bluefin", etc. Essential for protocol-specific analysis and cross-platform comparisons.
{% enddocs %}

{% docs platform_project_name %}
The project or company name associated with the DEX platform, extracted from address labeling data. This field provides organizational context for the platform, enabling corporate-level analysis and relationship mapping. May be NULL for platforms without established project labels. Useful for understanding platform ownership, partnerships, and ecosystem relationships.
{% enddocs %}

{% docs pool_name %}
The human-readable name of the liquidity pool involved in the swap, derived from address labeling or defaulting to the pool address if no label exists. This field provides user-friendly pool identification for analytics and reporting. Examples might include "SUI-USDC Pool", "ETH-USDT Pool", etc. Essential for pool-specific analysis and liquidity concentration studies.
{% enddocs %}

{% docs pool_project_name %}
The project or protocol name associated with the liquidity pool, extracted from address labeling data. This field provides organizational context for the pool, enabling analysis of which protocols are providing liquidity for specific token pairs. May be NULL for pools without established project labels. Useful for understanding liquidity provider relationships and protocol partnerships.
{% enddocs %}

{% docs amount_in %}
The decimal-adjusted amount of tokens being swapped in (input amount), calculated by dividing the raw amount by the token's decimal places. This field provides human-readable token amounts for analysis and reporting. For example, if amount_in_raw is 1000000000 and token_in_decimals is 9, then amount_in would be 1.0. Essential for user-friendly volume analysis and token flow calculations.
{% enddocs %}

{% docs amount_out %}
The decimal-adjusted amount of tokens being swapped out (output amount), calculated by dividing the raw amount by the token's decimal places. This field provides human-readable token amounts for analysis and reporting. For example, if amount_out_raw is 500000000 and token_out_decimals is 6, then amount_out would be 500.0. Critical for calculating swap rates and understanding actual token exchange ratios.
{% enddocs %}

{% docs fee_amount %}
The decimal-adjusted amount of fees charged for the swap transaction, calculated by dividing the raw fee amount by the input token's decimal places. This field provides human-readable fee amounts for cost analysis and reporting. May be NULL when no fees are charged or when fee information is not available. Essential for fee revenue analysis and total cost of trading calculations.
{% enddocs %}

{% docs token_in_address %}
The extracted token address from the full token type identifier, representing the contract address of the input token. This field is derived by splitting the token_in_type on '::' and taking the first component. For native SUI tokens, this will be '0x2'. Essential for token identification, pricing lookups, and cross-model joins with token metadata tables.
{% enddocs %}

{% docs token_in_symbol %}
The trading symbol for the input token, such as 'SUI', 'USDC', 'USDT', etc. This field is populated from token price data and provides user-friendly token identification for analytics and reporting. May be NULL for tokens without established price data. Essential for token pair analysis and trading pattern identification.
{% enddocs %}

{% docs token_in_name %}
The full descriptive name of the input token, such as 'Sui Token', 'USD Coin', 'Tether USD', etc. This field is populated from token price data and provides complete token identification for analytics and reporting. May be NULL for tokens without established price data. Useful for comprehensive token analysis and user interface displays.
{% enddocs %}

{% docs token_out_address %}
The extracted token address from the full token type identifier, representing the contract address of the output token. This field is derived by splitting the token_out_type on '::' and taking the first component. For native SUI tokens, this will be '0x2'. Essential for token identification, pricing lookups, and cross-model joins with token metadata tables.
{% enddocs %}

{% docs token_out_symbol %}
The trading symbol for the output token, such as 'SUI', 'USDC', 'USDT', etc. This field is populated from token price data and provides user-friendly token identification for analytics and reporting. May be NULL for tokens without established price data. Essential for token pair analysis and trading pattern identification.
{% enddocs %}

{% docs token_out_name %}
The full descriptive name of the output token, such as 'Sui Token', 'USD Coin', 'Tether USD', etc. This field is populated from token price data and provides complete token identification for analytics and reporting. May be NULL for tokens without established price data. Useful for comprehensive token analysis and user interface displays.
{% enddocs %}

{% docs token_in_price %}
The USD price of the input token at the time of the swap, sourced from hourly price data. This field enables USD-denominated volume calculations and financial analysis. May be NULL for tokens without available price data. Essential for calculating amount_in_usd and swap_volume_usd fields.
{% enddocs %}

{% docs token_out_price %}
The USD price of the output token at the time of the swap, sourced from hourly price data. This field enables USD-denominated volume calculations and financial analysis. May be NULL for tokens without available price data. Essential for calculating amount_out_usd and swap_volume_usd fields.
{% enddocs %}

{% docs token_in_decimals %}
The number of decimal places for the input token, used for converting raw amounts to human-readable values. This field is sourced from token price data or defaults to common values (6 for USDC/USDT, 9 for others). Essential for accurate amount_in calculations and token precision handling.
{% enddocs %}

{% docs token_out_decimals %}
The number of decimal places for the output token, used for converting raw amounts to human-readable values. This field is sourced from token price data or defaults to common values (6 for USDC/USDT, 9 for others). Essential for accurate amount_out calculations and token precision handling.
{% enddocs %}

{% docs amount_in_usd %}
The USD value of the input token amount, calculated as amount_in * token_in_price. This field provides USD-denominated volume metrics for financial analysis and reporting. May be NULL when token_in_price is not available. Essential for cross-protocol volume comparisons and financial reporting.
{% enddocs %}

{% docs amount_out_usd %}
The USD value of the output token amount, calculated as amount_out * token_out_price. This field provides USD-denominated volume metrics for financial analysis and reporting. May be NULL when token_out_price is not available. Essential for cross-protocol volume comparisons and financial reporting.
{% enddocs %}

{% docs swap_volume_usd %}
The USD volume of the swap, calculated as the average of amount_in_usd and amount_out_usd when both prices are available, or using whichever price is available when only one is present. This field provides the primary metric for volume analysis and cross-protocol comparisons. May be NULL when no price data is available. Essential for DeFi volume analytics and market analysis.
{% enddocs %}

{% docs trader_name %}
The human-readable name of the trader, derived from address labeling or defaulting to the trader address if no label exists. This field provides user-friendly trader identification for analytics and reporting. May include wallet names, exchange addresses, or other labeled entities. Essential for trader behavior analysis and wallet tracking.
{% enddocs %}

{% docs trader_project_name %}
The project or organization name associated with the trader address, extracted from address labeling data. This field provides organizational context for the trader, enabling analysis of institutional vs. retail trading patterns. May be NULL for individual traders without established project labels. Useful for understanding trading behavior by entity type.
{% enddocs %}