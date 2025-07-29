{% docs defi__ez_dex_swaps %}
## Description
This table provides a comprehensive view of decentralized exchange (DEX) swap activity across the Sui blockchain ecosystem, enriched with token pricing, metadata, and user labels. It consolidates swap events from seven major DEX protocols (Cetus, Turbos, Bluefin, Aftermath AMM, FlowX, DeepBook, and Momentum) into a standardized format with USD valuations, token metadata, and enhanced labeling. The model transforms raw swap data by adding price information, decimal-adjusted amounts, USD volume calculations, and human-readable labels for platforms, pools, and traders. This enables cross-protocol DeFi analytics, volume comparisons, and comprehensive trading pattern analysis.

## Key Use Cases
- Cross-protocol DeFi volume analysis and market share comparison
- Token pair trading volume and liquidity analysis
- DEX performance benchmarking and protocol adoption tracking
- Trader behavior analysis and wallet clustering
- USD-denominated volume metrics and financial reporting
- Token flow tracking and cross-protocol arbitrage detection
- Fee revenue analysis and protocol economics modeling
- Real-time DeFi dashboard development and monitoring

## Important Relationships
- Sources data from `sui.silver.dex_swaps` for base swap events
- Enriches with token pricing from `crosschain.price.ez_prices_hourly` for USD calculations
- Joins with `crosschain.core.dim_labels` for platform, pool, and trader labeling
- Supports downstream DeFi analytics and cross-protocol dashboards
- Provides foundation for token flow analysis and market microstructure studies

## Commonly-used Fields
- `platform` and `platform_name`: Essential for protocol-specific analysis and filtering
- `amount_in_usd` and `amount_out_usd`: Critical for volume analysis and financial reporting
- `swap_volume_usd`: Primary field for cross-protocol volume comparisons and market analysis
- `token_in_symbol` and `token_out_symbol`: Key for token pair analysis and trading pattern identification
- `block_timestamp`: Primary field for time-series analysis and trend detection
- `trader_address` and `trader_name`: Essential for wallet tracking and user behavior analysis
- `pool_address` and `pool_name`: Important for liquidity pool analysis and pool-specific metrics
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