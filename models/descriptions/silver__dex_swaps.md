{% docs silver__dex_swaps %}
## Description
This table consolidates decentralized exchange (DEX) swap events from multiple Sui blockchain protocols into a standardized format. It captures token swaps across seven major DEX platforms: Cetus, Turbos, Bluefin, Aftermath AMM, FlowX, DeepBook, and Momentum. The model extracts swap events from blockchain events, normalizes the data structure across different protocols, and provides consistent fields for DeFi analytics. Each swap event includes token amounts, fees, pool information, and trader details where available.

## Key Use Cases
- Cross-protocol DeFi volume analysis and comparison
- Token flow tracking and liquidity analysis
- DEX performance benchmarking and market share analysis
- Trader behavior analysis and wallet tracking
- Fee revenue analysis across different protocols
- Token pair popularity and trading volume trends
- Protocol-specific analytics and optimization insights

## Important Relationships
- Sources events from `gold.core.fact_events` filtered by specific DEX event types
- Enriches data with transaction details from `gold.core.fact_transactions`
- Can be joined with `gold.core.dim_tokens` for token metadata and pricing
- Supports downstream analytics in DeFi-specific curated models
- Provides foundation for cross-protocol DeFi dashboards and reports

## Commonly-used Fields
- `platform`: Essential for protocol-specific analysis and filtering
- `amount_in_raw` and `amount_out_raw`: Core fields for volume calculations and swap analysis
- `token_in_type` and `token_out_type`: Critical for token pair analysis and pricing
- `tx_digest` and `event_index`: Primary keys for linking to transaction details
- `block_timestamp`: Key field for time-series analysis and trend detection
- `pool_address`: Important for liquidity pool analysis and pool-specific metrics
- `trader_address`: Essential for wallet tracking and user behavior analysis
{% enddocs %}



{% docs platform %}
The name of the decentralized exchange platform where the swap occurred. Currently supports seven major Sui DEX protocols: Cetus, Turbos, Bluefin, Aftermath AMM, FlowX, DeepBook, and Momentum. This field enables protocol-specific analysis, performance comparison, and market share calculations across different DeFi platforms.
{% enddocs %}

{% docs platform_address %}
The smart contract address of the DEX platform that facilitated this swap. This represents the deployed contract address for the specific DEX protocol on the Sui blockchain. Useful for contract verification, security analysis, and linking to platform-specific metadata and configurations.
{% enddocs %}

{% docs pool_address %}
The address of the liquidity pool involved in the swap. For protocols that use AMM (Automated Market Maker) pools, this identifies the specific pool contract. May be NULL for order book-based protocols like DeepBook or centralized limit order protocols. Essential for pool-specific analytics and liquidity analysis.
{% enddocs %}

{% docs amount_in_raw %}
The raw amount of tokens being swapped in (input amount) before any decimal adjustments. This represents the exact on-chain token amount as it appears in the swap event. Preserves precision for accurate calculations and is essential for volume analysis, price impact calculations, and swap size distribution analysis.
{% enddocs %}

{% docs amount_out_raw %}
The raw amount of tokens being swapped out (output amount) before any decimal adjustments. This represents the exact on-chain token amount that the user receives from the swap. Critical for calculating swap rates, slippage analysis, and understanding the actual token amounts exchanged in each swap.
{% enddocs %}

{% docs a_to_b %}
A boolean flag indicating the direction of the swap within the pool. When TRUE, the swap goes from token A to token B; when FALSE, it goes from token B to token A. This field is protocol-specific and may be NULL for some DEX platforms. Important for understanding swap direction and pool token ordering conventions.
{% enddocs %}

{% docs fee_amount_raw %}
The raw amount of fees charged for the swap transaction. This includes protocol fees, liquidity provider fees, and any other transaction costs. May be 0 for protocols that don't charge explicit fees or when fees are embedded in the swap amounts. Essential for fee revenue analysis and total cost of trading calculations.
{% enddocs %}

{% docs partner_address %}
The address of a partner or affiliate that facilitated the swap (if applicable). Used primarily by Cetus for their partner program where swaps can be routed through partner contracts. May be NULL for most protocols. Useful for tracking partner performance and affiliate program analytics.
{% enddocs %}

{% docs referral_amount_raw %}
The raw amount of referral rewards or commissions generated from this swap. Used by Cetus to track referral program payouts. May be 0 for protocols without referral programs or when no referral was used. Important for referral program analytics and partner performance tracking.
{% enddocs %}

{% docs steps %}
The number of steps or hops required to complete the swap. For simple swaps, this is typically 1. For complex swaps involving multiple pools or routing through multiple protocols, this indicates the number of intermediate steps. Essential for understanding swap complexity and routing efficiency across different protocols.
{% enddocs %}

{% docs token_in_type %}
The full type identifier of the token being swapped in (input token). This follows Sui's Move type format (e.g., "0x2::sui::SUI" for the native SUI token). Essential for token identification, pricing lookups, and token-specific analytics. Used for calculating USD values and token pair analysis.
{% enddocs %}

{% docs token_out_type %}
The full type identifier of the token being swapped out (output token). This follows Sui's Move type format and represents the token that the user receives from the swap. Critical for token pair analysis, swap rate calculations, and understanding token flow patterns across the DeFi ecosystem.
{% enddocs %}

{% docs trader_address %}
The address of the wallet or account that initiated the swap. May be NULL for some protocols that don't explicitly track the trader address in their events. Essential for user behavior analysis, wallet tracking, and understanding individual trader patterns and preferences across different DEX platforms.
{% enddocs %}

{% docs dex_swaps_id %}
A unique surrogate key generated from the combination of tx_digest and event_index. This provides a stable, unique identifier for each swap event that can be used as a primary key for downstream analytics and data modeling. Ensures data integrity and prevents duplicate processing.
{% enddocs %}



{% docs _invocation_id %}
A unique identifier for the dbt run that created or updated this record. This field is used for data lineage tracking and debugging purposes. Helps identify which specific dbt execution was responsible for processing each record and enables traceability back to the source code and configuration used.
{% enddocs %} 