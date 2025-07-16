{% docs core__dim_tokens %}
Dimension table containing comprehensive token metadata for all coins and tokens on the Sui blockchain. This model provides enriched token information including decimals, symbols, names, descriptions, and icon URLs sourced from on-chain metadata. The table serves as the primary reference for token details used across all analytics workflows and fact tables. Data is sourced from the bronze_api__coin_metadata model and includes both native SUI tokens and custom tokens deployed on the network. Essential for token identification, decimal adjustment calculations, and user interface display formatting.
{% enddocs %}

{% docs core__fact_balance_changes %}
Fact table capturing all balance changes for tokens and coins on the Sui blockchain. Each record represents a balance change event within a transaction, including the amount changed, coin type, and owner information. This table is essential for tracking token movements, wallet balances, and transaction impacts across the network. Data includes both positive and negative balance changes, enabling comprehensive financial analysis and reconciliation. The table supports portfolio tracking, treasury management, and token flow analysis across all addresses and token types in the Sui ecosystem.
{% enddocs %}

{% docs core__fact_changes %}
Fact table documenting all object changes that occur within transactions on the Sui blockchain. This includes created, modified, deleted, wrapped, and unwrapped objects, providing a complete audit trail of object state changes. Essential for tracking object lifecycle, ownership transfers, and state mutations across the network. The table captures the full spectrum of object modifications including version changes, ownership transfers, and type transformations. Critical for compliance reporting, forensic analysis, and understanding application behavior patterns in the Sui object model.
{% enddocs %}

{% docs core__fact_checkpoints %}
Fact table containing information about checkpoints in the Sui blockchain. Each checkpoint represents a consensus point that bundles multiple transactions together, serving as the primary unit of finality in Sui. This table includes checkpoint metadata, transaction counts, validator signatures, and epoch information essential for network analysis and data integrity verification. Checkpoints are formed approximately every 250ms through the Mysticeti consensus mechanism. The table is fundamental for understanding network throughput, validator participation, and transaction finality across the Sui blockchain.
{% enddocs %}

{% docs core__fact_events %}
Fact table capturing all events emitted by transactions on the Sui blockchain. Events represent structured data emissions from smart contracts and system operations, providing detailed insights into application-specific activities. This table includes event metadata, parsed JSON data, and categorization essential for dApp analytics and protocol monitoring. Events are emitted by Move modules during transaction execution and contain rich contextual information about contract interactions. The table supports real-time monitoring, business intelligence, and protocol analytics across the entire Sui ecosystem.
{% enddocs %}

{% docs core__fact_transaction_blocks %}
Fact table providing comprehensive transaction-level information for all transactions on the Sui blockchain. This table serves as the primary source for transaction metadata, including success status, gas usage, fees, and error information. Essential for transaction analysis, fee optimization, and network performance monitoring. The table includes detailed gas breakdowns, dependency tracking, and execution outcomes. Critical for understanding network economics, user behavior patterns, and application performance across the Sui blockchain infrastructure.
{% enddocs %}

{% docs core__fact_transaction_inputs %}
Fact table documenting all inputs used by transactions on the Sui blockchain. This includes objects, pure values, and shared objects that transactions reference or consume during execution. Essential for understanding transaction dependencies, object usage patterns, and input validation across the network. The table captures input types, versions, mutability flags, and ownership information. Important for analyzing transaction complexity, resource utilization, and dependency chains in complex multi-step transactions and smart contract interactions.
{% enddocs %}

{% docs core__fact_transactions %}
Fact table capturing the detailed payload structure of all transactions on the Sui blockchain. This table breaks down transaction commands into individual components, providing granular visibility into Move function calls, transfers, and other transaction operations. Essential for understanding transaction composition and smart contract interactions. The table includes payload types, command details, and execution order information. Critical for analyzing dApp usage patterns, protocol interactions, and transaction complexity across the Sui ecosystem.
{% enddocs %}