{% docs core__dim_tokens %}
Dimension table providing authoritative metadata for all fungible and non-fungible tokens on the Sui blockchain. Includes decimals, symbols, names, descriptions, and icon URLs sourced from on-chain metadata and Move package definitions. Serves as the canonical reference for token identification, decimal normalization, and UI display across analytics workflows. Data is sourced from bronze_api__coin_metadata and cross-referenced with on-chain Move modules, covering both native SUI and custom tokens. Essential for accurate balance calculations, token flow analysis, and user-facing applications. Supports lineage tracing from raw on-chain metadata to analytics-ready token attributes.
{% enddocs %}

{% docs core__fact_balance_changes %}
Fact table recording every token and coin balance change event on the Sui blockchain at the finest granularity. Each row represents a single balance delta (positive or negative) for a specific owner, coin type, and transaction, capturing the full flow of assets across wallets and contracts. Includes object IDs, transaction context, and ownership metadata, supporting precise tracking of token movements, portfolio changes, and treasury operations. Enables reconstruction of wallet balances, detection of large transfers, and analysis of token velocity. Data is derived from transaction execution effects and object state transitions, following Sui's explicit ownership and versioning model.
{% enddocs %}

{% docs core__fact_changes %}
Fact table capturing all object state transitions on the Sui blockchain, including creation, mutation, deletion, wrapping, and unwrapping of objects. Each record documents the full lifecycle of Sui objects (NFTs, coins, packages, etc.) as they are manipulated by transactions. Includes object IDs, versions, types, and ownership changes, enabling forensic analysis, compliance reporting, and application behavior tracing. Supports lineage analysis by linking object changes to specific transactions, epochs, and owners. Critical for understanding Sui's object-centric data model and for tracking resource flows, upgrades, and state mutations across the network.
{% enddocs %}

{% docs core__fact_checkpoints %}
Fact table representing all finalized checkpoints on the Sui blockchain, which serve as consensus points bundling multiple transactions for finality and recovery. Each checkpoint aggregates metadata such as checkpoint sequence number, timestamp, transaction count, validator signatures, and epoch information. Checkpoints are produced via the Mysticeti consensus mechanism approximately every 250ms, providing the backbone for time series analysis (TPS, latency, validator participation). This table is essential for measuring network throughput, tracking validator performance, and ensuring data integrity. Supports analytics on epoch transitions, validator set changes, and network health.
{% enddocs %}

{% docs core__fact_events %}
Fact table logging all events emitted by Move smart contracts and system operations during transaction execution on Sui. Each event is a structured data emission containing contract-specific or protocol-level information, including event type, JSON payload, emitting module, and transaction context. Enables deep dApp analytics, protocol monitoring, and behavioral analysis by exposing granular details of on-chain activity. Events are indexed by transaction and checkpoint, supporting real-time monitoring, anomaly detection, and business intelligence use cases. Essential for understanding contract interactions, user engagement, and protocol-level trends in the Sui ecosystem.
{% enddocs %}

{% docs core__fact_transaction_blocks %}
Fact table providing detailed metadata for every transaction block executed on the Sui blockchain. Includes transaction hash, sender, success status, gas usage, fee breakdowns, error codes, and dependency tracking. Serves as the primary source for transaction-level analytics, fee optimization, and network performance monitoring. Supports lineage tracing from transaction inputs to execution outcomes, including gas smashing, storage fee rebates, and error diagnostics. Critical for understanding Sui's transaction model, user behavior, and application performance at scale.
{% enddocs %}

{% docs core__fact_transaction_inputs %}
Fact table enumerating all inputs consumed by transactions on the Sui blockchain, including owned objects, shared objects, pure values, and input types. Each record details the object ID, version, mutability, and ownership at the time of transaction execution. Enables dependency analysis, resource utilization tracking, and validation of transaction atomicity. Supports analytics on input complexity, shared object usage, and transaction parallelism. Essential for understanding how Sui's object-centric model enables parallel execution and for tracing the full dependency graph of complex transactions.
{% enddocs %}

{% docs core__fact_transactions %}
Fact table decomposing every transaction on the Sui blockchain into its constituent commands and payloads. Each row represents a single command (e.g., Move call, transfer, split, merge) within a programmable transaction block, capturing execution order, command type, and argument details. Enables granular analysis of smart contract interactions, dApp usage patterns, and transaction complexity. Supports lineage tracing from high-level user actions to low-level on-chain effects, including Move function calls and resource transfers. Critical for protocol analytics, developer adoption tracking, and understanding composability in the Sui ecosystem.
{% enddocs %}