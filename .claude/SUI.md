# SUI.md – Technical & Data-Model Reference

## 1  Blockchain Summary

**Name** – Sui
**Consensus** – Mysticeti BFT delegated-PoS with DAG-based parallel execution (sub-second finality)[^1]
**Ecosystem / VM** – *Sui Move VM* (Move language, object-centric)[^1]
**Design Intent** – High-throughput L1 for gaming, DeFi \& real-time apps[^2]
**Genesis** – 3 May 2023, block 0
**Current Network** – ~0.24 s block time, peak 297 k TPS demo, 2 .1 B txs processed (2024)[^2]
**Native / Gas Token** – SUI (10 B cap; gas, staking, governance)
**Explorers** – suiexplorer.com, suivision.xyz
**Public RPC** – `https://fullnode.mainnet.sui.io:443` (plus QuickNode, Ankr)
**Docs / SDKs** – docs.sui.io, `@mysten/sui.js`, *SuiKit* (Swift)
**Governance** – On-chain token voting (SIP process) via validators \& Sui Foundation
**Economics** – Fixed 10 B supply, fee-funded validator rewards, storage-fund deflation
**Architecture** – L1; horizontal scaling via object-parallelism; no external DA layer
**Interoperability** – Bridges: Wormhole, Circle CCTP (ETH, SOL, EVM chains)[^2]

## 2  DeFi Landscape (July 2025)

* DeFiLlama ranks Sui \#9 by TVL (~\$2.25 B)[^3].
* **61 DEX protocols; 20 hold >\$10 M TVL**.
* Shared Liquidity: **DeepBook** CLOB acts as public good; Cetus CLMM engine reused by multiple DEXes.
* Top DEX TVL snapshot


| Protocol | TVL | Notes |
| :-- | :-- | :-- |
| Suilend | \$752 M | Lending + swap routing |
| NAVI | \$685 M | Lending + AMM |
| Bluefin | \$210 M | CLOB + AMM hybrid |
| Haedal | \$209 M | Liquid staking |
| Cetus | \$105 M | Concentrated-liq AMM |


## 3  Core Data-Models (Flipside *gold.core* schema)[^4]

| Table | Grain / PK | Purpose \& Key Columns (abridged) | Typical Use Cases |
| :-- | :-- | :-- | :-- |
| **core__dim_tokens** | `coin_type` (surrogate `dim_tokens_id`) | One row per fungible token; `symbol`, `decimals`, `description`, `icon_url`, `object_id`. | Token reference joins, labeling balances \& swaps. |
| **core__fact_checkpoints** | `checkpoint_number` | 1 row per checkpoint; `block_timestamp`, `epoch`, `checkpoint_digest`, `network_total_transactions`, `tx_count`, raw `transactions_array`. | Chain-level time-series, throughput \& epoch analytics. |
| **core__fact_transaction_blocks** | `tx_digest` | Aggregate tx-level metrics: sender, kind, fee (`tx_fee`), gas cost breakdown, success flag, dependency list. | Gas-usage, fee-economics, wallet activity, mempool dependency graphs. |
| **core__fact_transactions** | (`tx_digest`,`payload_index`) | Explodes *transaction* array → one record per payload element; captures `payload_type` \& raw `payload_details`. | Fine-grained tx composition analysis, contract call counts. |
| **core__fact_transaction_inputs** | (`tx_digest`,`input_index`) | Explodes *inputs* array; fields include `object_id`, `version`, `type`, mutability, shared-object version. | Object-dependency tracing; shared-object concurrency studies. |
| **core__fact_balance_changes** | (`tx_digest`,`balance_change_index`) | Normalised coin balance deltas: `coin_type`, `amount`, `owner`, sender \& status. | Token flow, DEX swap accounting, wallet PnL. |
| **core__fact_changes** | (`tx_digest`,`change_index`) | Object-level state changes: `object_id`, `object_type`, `version`, `previous_version`, new owner, digest. | NFT lifecycle, object provenance, state-diff analytics. |
| **core__fact_events** | (`tx_digest`,`event_index`) | All emitted Move events with parsed JSON; splits full `type` into `event_address`, `module`, `resource`. | Generic event feed, custom protocol indexing, DEX swap model (see below). |

### Column Map (selected)

```
core__fact_events
  checkpoint_number  block_timestamp  tx_digest  tx_kind  tx_sender
  message_version    tx_succeeded     event_index
  type               event_address    event_module  event_resource
  package_id         transaction_module  sender
  parsed_json (VARIANT)               inserted_timestamp
```

*(Other tables follow similar timestamp \& surrogate-key pattern.)*

## 4  Building `sui.defi.ez_dex_swaps`
## 🔍 Phase 1: Discovery

### Contract & Event Discovery (REQUIRED)
For each account:
- Use `web.search` or developer APIs to:
  - Identify all deployed contracts
  - Extract contract names and source code if available
  - Determine which event(s) signal a *mint*

📌 **Discovery period is required**: The LLM **must investigate the onchain behavior** of each contract to determine what qualifies as a mint. There is no uniform event across contracts.



Recommended pipeline:

```
WITH swaps AS (
  SELECT  fe.block_timestamp,
          fe.tx_digest,
          split_part(fe.type,'::',1) AS protocol_pkg,
          fe.parsed_json:value:"amount_in"::number   AS amount_in_raw,
          fe.parsed_json:value:"amount_out"::number  AS amount_out_raw,
          bc.coin_type  AS token_in,
          lead(bc.coin_type) over (part) AS token_out
  FROM core.fact_events fe
  JOIN core.fact_balance_changes bc 
        ON fe.tx_digest = bc.tx_digest
  WHERE fe.type ILIKE '%SwapEvent'
)
SELECT  block_timestamp, tx_digest, protocol_pkg   AS platform,
        token_in, token_out,
        amount_in_raw / pow(10,di.decimals) AS amount_in,
        amount_out_raw/ pow(10,do.decimals) AS amount_out
FROM swaps
JOIN core.dim_tokens di ON token_in = di.coin_type
JOIN core.dim_tokens do ON token_out = do.coin_type;
```

Add USD pricing via hourly price table; persist to `gold.defi.ez_dex_swaps`.

## 5  Governance \& Economic Context

The Sui Foundation coordinates grants \& SIP voting; validator-weighted consensus executes upgrades. The fixed-supply model combined with a **storage-fund rebate** makes long-term token velocity deflationary[^2].

*This file distills the latest technical facts, DeFi positioning, and Flipside **gold.core** data-model descriptions needed for rapid analytics development on Sui.*

<div style="text-align: center">⁂</div>

[^1]: https://github.com/MystenLabs/sui

[^2]: https://blog.sui.io/reimagining-bitcoins-role-in-sui-defi/

[^3]: https://flipsidecrypto.xyz/Specter/sui-chain-tvl-breakdown-9uNOUh

[^4]: https://github.com/FlipsideCrypto/sui-models/tree/main/models/gold/core

[^5]: https://github.com/FlipsideCrypto

[^6]: https://www.binance.com/en/square/post/20526573591226

[^7]: https://docs.flipsidecrypto.xyz/data/flipside-data/contribute-to-our-data/contribute-to-flipside-data/model-standards

[^8]: https://github.com/FlipsideCrypto/sql_models

[^9]: https://github.com/FlipsideCrypto/solana-models

[^10]: https://mirror.xyz/0x65C134078BB64Ac69ec66B2A8843fd1ADA54B496/_sOLnSDEjuQTcFV_OiI07m21MSR0QGoF96LRHm5hb78

[^11]: https://popsql.com/blog/dbt-models

[^12]: https://github.com/FlipsideCrypto/core-models

[^13]: https://www.linkedin.com/posts/flipside-crypto_data-ingestion-with-dbt-snowflake-activity-7094753867002716160-pHpq

[^14]: https://github.com/FlipsideCrypto/crosschain-models

[^15]: https://docs.flipsidecrypto.xyz/data/flipside-data/data-models

[^16]: https://stackoverflow.com/questions/75389236/dbt-select-from-model-itself-how-to-transform-this-query

[^17]: https://pypi.org/project/flipside/

[^18]: https://arxiv.org/html/2503.09165v1

[^19]: https://dev.to/pizofreude/study-notes-431-build-the-first-dbt-models-2nl3

[^20]: https://docs.sui.io/guides/developer/coin/in-game-token

[^21]: https://sui.io

[^22]: https://github.com/FlipsideCrypto/sui-models/blob/main/models/gold/core/core__dim_tokens.sql

[^23]: https://github.com/FlipsideCrypto/sui-models/blob/main/models/gold/core/core__fact_balance_changes.sql

[^24]: https://github.com/FlipsideCrypto/sui-models/blob/main/models/gold/core/core__fact_changes.sql

[^25]: https://github.com/FlipsideCrypto/sui-models/blob/main/models/gold/core/core__fact_checkpoints.sql

[^26]: https://github.com/FlipsideCrypto/sui-models/blob/main/models/gold/core/core__fact_events.sql

[^27]: https://github.com/FlipsideCrypto/sui-models/blob/main/models/gold/core/core__fact_transaction_blocks.sql

[^28]: https://github.com/FlipsideCrypto/sui-models/blob/main/models/gold/core/core__fact_transaction_inputs.sql

[^29]: https://github.com/FlipsideCrypto/sui-models/blob/main/models/gold/core/core__fact_transactions.sql

