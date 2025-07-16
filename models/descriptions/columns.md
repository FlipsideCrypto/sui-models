{% docs checkpoint_number %}
The checkpoint sequence number when the transaction was finalized. Checkpoints are units of finality in Sui that contain an ordered list of executed transactions. Sequential number starting from 0 (genesis checkpoint). Represents the finality milestone for the transaction - once included in a checkpoint, the transaction is guaranteed to be permanently recorded and cannot be reverted.
{% enddocs %}

{% docs block_timestamp %}
The timestamp when the checkpoint containing this transaction was agreed upon by consensus. Unix timestamp with millisecond precision representing the network-agreed time when the transaction was finalized. Used for time-based analytics, temporal ordering, and trend analysis.
{% enddocs %}

{% docs tx_digest %}
A 32-byte cryptographic hash that uniquely identifies the transaction contents. Base58 encoded hash serving as the primary key for transaction identification and retrieval. Provides cryptographic proof of transaction integrity and enables transaction lookup across the network.
{% enddocs %}

{% docs tx_kind %}
Specifies the type of transaction and its execution structure. Two primary types: Programmable Transaction Blocks (PTBs) for user-submitted transactions containing up to 1,024 commands, and System Transactions for validator-only network operations. Determines transaction processing path and available operations.
{% enddocs %}

{% docs tx_sender %}
The 32-byte Sui address that initiated and signed the transaction. Hexadecimal address with 0x prefix that identifies the account responsible for the transaction and gas payment. Essential for user activity tracking, authorization analysis, and wallet analytics.
{% enddocs %}

{% docs message_version %}
The version of the transaction data structure format, enabling protocol evolution. Currently uses TransactionDataV1 structure. Ensures backward compatibility and enables protocol upgrades without breaking existing transaction formats.
{% enddocs %}

{% docs tx_succeeded %}
Boolean indicator of transaction execution success. Values: Success (transaction completed successfully) or Error (transaction failed with error details). Primary indicator for transaction outcome analysis, success rate tracking, and error monitoring.
{% enddocs %}

{% docs tx_fee %}
Complete gas cost for transaction execution in SUI tokens. Calculated as (computation_cost + storage_cost - storage_rebate) / 10^9. Represents the economic cost of transaction execution, essential for cost analysis, fee optimization, and economic modeling.
{% enddocs %}

{% docs tx_error %}
Detailed error information when transaction execution fails. Human-readable error messages with error codes providing diagnostic information for failed transactions. Enables debugging, error pattern analysis, and application improvement.
{% enddocs %}

{% docs tx_dependencies %}
Set of transaction digests that this transaction depends upon for object versions. Array of Base58-encoded transaction digests establishing transaction ordering and causality. Important for understanding transaction flow and dependency chains.
{% enddocs %}

{% docs gas_used_computation_cost %}
The total cost in MIST units for computational resources consumed during transaction execution. Calculated as computation_units * gas_price. Represents the validator's computational work cost, used for analyzing transaction complexity and computational efficiency.
{% enddocs %}

{% docs gas_used_non_refundable_storage_fee %}
The portion of storage fees that cannot be reclaimed when data is deleted. Calculated as storage_units * storage_price * 0.01 (1% of total storage fees). Ensures storage fund sustainability by maintaining baseline capitalization.
{% enddocs %}

{% docs gas_used_storage_cost %}
The total cost in MIST units for storing data on-chain in perpetuity. Calculated as storage_units * storage_price where storage_units = bytes_stored * 100. Users pay upfront for perpetual storage costs.
{% enddocs %}

{% docs gas_used_storage_rebate %}
The refund amount in MIST units when previously stored data is deleted. Calculated as original_storage_fee * 0.99 (99% refund). Incentivizes data cleanup and efficient storage usage.
{% enddocs %}

{% docs gas_price %}
The user-submitted price per computation unit in MIST units. Structure: reference_gas_price + tip (optional). Determines transaction priority and total cost, essential for fee market analysis and cost optimization.
{% enddocs %}

{% docs gas_budget %}
The maximum amount in MIST units that a user is willing to pay for transaction execution. Limits: Minimum 2,000 MIST, Maximum 50,000,000,000 MIST. Provides cost protection for users and is critical for transaction planning.
{% enddocs %}

{% docs gas_owner %}
The Sui address responsible for paying gas fees. Enables sponsored transactions where a third party pays gas fees. Important for tracking payment models and gasless user experiences.
{% enddocs %}

{% docs balance_change_index %}
Index ordering balance changes within a transaction. Sequential integer starting from 0 tracking balance modification sequence. Important for accurate financial analysis and reconciliation.
{% enddocs %}

{% docs coin_type %}
Type identifier for coins/tokens using Move's type system. Format: {package}::{module}::{struct}. Example: 0x2::sui::SUI for native SUI token. Identifies token types in multi-asset ecosystem, essential for DeFi analytics.
{% enddocs %}

{% docs amount %}
Token quantity in smallest unit (MIST for SUI). Integer format where 1 SUI = 1,000,000,000 MIST. Represents precise token amounts, critical for financial calculations and balance tracking.
{% enddocs %}

{% docs owner %}
Ownership information for objects/balances. Enum with variants: Address, Shared, or Immutable. Determines object/coin accessibility, important for wallet analytics and ownership distribution studies.
{% enddocs %}

{% docs change_index %}
Sequential index ordering state changes within a transaction. Zero-based sequential numbering ordering object modifications within transactions. Critical for maintaining transaction atomicity in analytics.
{% enddocs %}

{% docs type %}
Categorization of object state modifications or event types. Enum values: created, modified, deleted, wrapped, unwrapped for changes. Tracks object lifecycle events, essential for understanding state transitions.
{% enddocs %}

{% docs sender %}
Transaction sender address in the context of events and changes. 32-byte Sui address representing transaction signing authority. Important for authorization tracking and security analysis.
{% enddocs %}

{% docs digest %}
A 32-byte cryptographic hash of object contents using SHA-256. Hexadecimal string representation enabling content verification and integrity checking. Important for detecting unauthorized modifications.
{% enddocs %}

{% docs object_id %}
A 32-byte globally unique identifier for objects in Sui's storage system. Hexadecimal string serving as primary key for object identification and tracking. Essential for asset provenance and ownership history.
{% enddocs %}

{% docs object_type %}
The Move type that governs the object's structure and behavior. Format: package_address::module_name::struct_name<type_parameters>. Enables type-based object classification and filtering.
{% enddocs %}

{% docs version %}
An 8-byte unsigned integer that increments with every transaction modifying the object. Tracks object mutation frequency and enables version-based conflict resolution. Starting value: 1 for newly created objects.
{% enddocs %}

{% docs previous_version %}
References the immediately preceding version of the object. Value: current_version - 1 (0 for initial creation). Creates immutable audit trail and enables historical state reconstruction.
{% enddocs %}

{% docs object_owner %}
Indicates how the object can be accessed and who has control. Types: Address-owned, Shared (requires consensus), Immutable (publicly accessible), Object-owned. Determines access patterns and transaction requirements.
{% enddocs %}

{% docs epoch %}
Temporal partition lasting ~24 hours with fixed validator set and protocol configuration. Sequence number starting at 0 defining network operational periods. Critical for tracking validator changes and protocol upgrades.
{% enddocs %}

{% docs checkpoint_digest %}
32-byte cryptographic hash uniquely identifying checkpoint contents. Base58-encoded hash enabling checkpoint verification and integrity checking. Essential for network security and state synchronization.
{% enddocs %}

{% docs previous_digest %}
Hash of the previous checkpoint, creating blockchain continuity. Base58-encoded hash maintaining blockchain integrity through cryptographic chaining. Critical for history verification and chain analysis.
{% enddocs %}

{% docs network_total_transactions %}
Cumulative count of all transactions processed by the network. Monotonically increasing integer serving as key metric for network growth and adoption. Essential for throughput analysis and scaling assessments.
{% enddocs %}

{% docs validator_signature %}
Aggregated BLS signatures from validator quorum (>2/3). Base64-encoded BLS aggregated signature with bitmap providing Byzantine fault-tolerant consensus proof. Critical for security analysis and validator participation tracking.
{% enddocs %}

{% docs tx_count %}
Total number of transactions included in the checkpoint. Integer count defining checkpoint size and transaction throughput. Important for network performance analysis and capacity planning.
{% enddocs %}

{% docs transactions_array %}
Array of transaction digests included in the checkpoint. Array of Base58-encoded transaction hashes defining checkpoint composition. Essential for transaction finality tracking and checkpoint analysis.
{% enddocs %}

{% docs event_index %}
Zero-based sequential index ordering events within a transaction. Sequential numbering starting from 0 providing deterministic event ordering. Essential for event sequence reconstruction and analytics.
{% enddocs %}

{% docs event_address %}
The Sui address that triggered the event emission. 32-byte Sui address identifying event origin for filtering and access control. Important for user activity tracking and security auditing.
{% enddocs %}

{% docs event_module %}
The name of the Move module that emitted the event. String identifier categorizing events by functional module. Enables module-specific event filtering and analysis.
{% enddocs %}

{% docs event_resource %}
The fully qualified type signature of the event struct. Format: <package_id>::<module>::<struct_name><type_parameters>. Enables type-safe event deserialization and schema tracking.
{% enddocs %}

{% docs package_id %}
The unique identifier of the Move package containing the event module. 32-byte object ID linking events to deployed smart contracts. Essential for package-level analytics and deployment tracking.
{% enddocs %}

{% docs transaction_module %}
The module executed in the transaction that emitted the event. String identifier linking events to transaction context. Important for understanding transaction flow and module interactions.
{% enddocs %}

{% docs parsed_json %}
JSON representation of the event data. JSON object with structure varying by event type. Provides structured event data for analytics, essential for event-driven applications and real-time monitoring.
{% enddocs %}

{% docs input_index %}
References inputs within programmable transaction block. Sequential integer for input array access linking commands to their inputs. Important for understanding transaction dependencies and resource usage patterns.
{% enddocs %}

{% docs value %}
The actual data content of the object or input value. Variable-sized byte array encoded using Binary Canonical Serialization (BCS). Contains the actual object/input data for content analysis.
{% enddocs %}

{% docs value_type %}
Specifies the Move type of the object's value content or input value type. Fully qualified type name with generics enabling type-safe deserialization and schema evolution tracking.
{% enddocs %}

{% docs initial_shared_version %}
Records the version at which an object was first shared. Nullable u64 (None for non-shared objects). Determines consensus requirements and helps analyze shared object contention patterns.
{% enddocs %}

{% docs mutable %}
Boolean flag indicating whether the object can be modified. Values: true (mutable) or false (immutable). Affects performance characteristics and access patterns - immutable objects enable caching and parallel access.
{% enddocs %}

{% docs payload_index %}
Position of payload within programmable transaction block. Sequential integer starting from 0 ordering transaction commands. Essential for understanding complex transaction flows.
{% enddocs %}

{% docs payload_type %}
Type of command in programmable transaction block. Values: MoveCall, TransferObjects, SplitCoins, etc. Categorizes transaction operations, critical for analyzing dApp interaction patterns.
{% enddocs %}

{% docs payload_details %}
Detailed information about specific payload command. Structured data varying by payload type containing complete command specification. Essential for deep transaction analysis and smart contract interaction tracking.
{% enddocs %}

{% docs inserted_timestamp %}
Timestamp when the record was inserted into the database. System-generated timestamp for data lineage and ETL tracking. Used for monitoring data freshness and processing delays.
{% enddocs %}

{% docs modified_timestamp %}
Timestamp when the record was last modified. System-generated timestamp for change tracking and data versioning. Important for incremental processing and data consistency verification.
{% enddocs %}

{% docs fact_checkpoints_id %}
Surrogate key for the checkpoint fact table. Generated unique identifier for database relationships and indexing. Primary key enabling efficient queries and joins across checkpoint data.
{% enddocs %}

{% docs fact_events_id %}
Surrogate key for the events fact table. Generated unique identifier combining transaction digest and event index. Primary key for event tracking and analytics workflows.
{% enddocs %}

{% docs fact_transaction_balance_changes_id %}
Surrogate key for the balance changes fact table. Generated unique identifier combining transaction digest and balance change index. Primary key for financial analysis and balance tracking.
{% enddocs %}

{% docs fact_changes_id %}
Surrogate key for the object changes fact table. Generated unique identifier combining transaction digest and change index. Primary key for object lifecycle analysis and state tracking.
{% enddocs %}

{% docs fact_transaction_blocks_id %}
Surrogate key for the transaction blocks fact table. Generated unique identifier based on transaction digest. Primary key for transaction-level analysis and performance monitoring.
{% enddocs %}

{% docs fact_transaction_inputs_id %}
Surrogate key for the transaction inputs fact table. Generated unique identifier combining transaction digest and input index. Primary key for transaction dependency analysis and input tracking.
{% enddocs %}

{% docs fact_transactions_id %}
Surrogate key for the transactions fact table. Generated unique identifier combining transaction digest and payload index. Primary key for transaction payload analysis and command tracking.
{% enddocs %}

{% docs dim_tokens_id %}
Surrogate key for the tokens dimension table. Generated unique identifier for token metadata. Primary key enabling efficient token lookups and joins across fact tables.
{% enddocs %}

{% docs coin_types_id %}
Surrogate key for coin types. Generated unique identifier for coin type classification. Used for indexing and joining coin type information across analytics queries.
{% enddocs %}

{% docs decimals %}
Number of decimal places for the token. Integer value defining token precision (e.g., 9 for SUI meaning 1 SUI = 1,000,000,000 MIST). Essential for accurate token amount calculations and display formatting.
{% enddocs %}

{% docs symbol %}
Token symbol identifier. Short string representation of the token (e.g., "SUI", "USDC"). Used for user-friendly token identification and display in applications.
{% enddocs %}

{% docs name %}
Full descriptive name of the token. Human-readable string providing complete token identification. Used for detailed token information and user interfaces.
{% enddocs %}

{% docs description %}
Detailed description of the token's purpose and functionality. Text field providing comprehensive token information including use cases, features, and technical details.
{% enddocs %}

{% docs icon_url %}
URL pointing to the token's icon image. Web URL for token visual representation used in wallets and applications. Enables consistent token branding across the ecosystem.
{% enddocs %}

{% docs id %}
Unique identifier for the token metadata. System-generated identifier linking token metadata to on-chain token types. Used for metadata management and token registry operations.
{% enddocs %}