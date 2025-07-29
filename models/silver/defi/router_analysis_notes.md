# DEX Router Analysis Notes

## Problem Statement
Universal router contracts on Sui create transactions with >2 token types, making token parsing ambiguous for dex swap models. Router transactions orchestrate complex multi-hop swaps across different protocols.

## Router vs Direct Swap Patterns

Based on analysis of 3-day transaction data, each DEX protocol has distinct router usage patterns:

### **Cetus** 
- Direct swaps: `transaction_module = 'cetus'` (331,336 events)
- Router swaps: Various modules including:
  - `'router'` (147,071 events)
  - `'swap_router'` (24,168 events) 
  - `'pool_script_v2'` (25,965 events)
- **Recommendation**: Filter to `transaction_module = 'cetus'` for direct swaps only

### **Turbos**
- Direct swaps: `transaction_module = 'turbos'` (74,925 events)
- Router swaps:
  - `'swap_router'` (47,184 events)
  - `'router'` (14,247 events)
- **Recommendation**: Filter to `transaction_module = 'turbos'` for direct swaps only

### **FlowX** ✅
- Direct swaps: `transaction_module = 'flowx_clmm'` (56,747 events)
- Router swaps: `'swap_router'` (15,680 events), `'router'` (6,303 events)
- **Status**: Already correctly filtered to `flowx_clmm` in current model

### **Aftermath**
- Only router swaps: `transaction_module = 'router'` (65,999 events)
- **Recommendation**: Keep as-is (no direct swap module available)

### **Bluefin** ✅
- Only direct swaps: `transaction_module = 'bluefin'` (238,066 events)
- **Status**: No router patterns detected

### **Momentum** ✅  
- Only direct swaps: `transaction_module = 'momentum'` (101,503 events)
- **Status**: No router patterns detected

### **Universal Router**
- Router-only protocol: `transaction_module = 'universal_router'` (29,784 events)
- **Recommendation**: Remove from silver__dex_swaps entirely (already planned)

## Example Router Transaction
Transaction `HCBEk7jHxAV2uK89FkSKjU7v7ebTSsTrZ3hYU1C3ot3R` demonstrates the multi-token issue:
- Router orchestrates USDC → STSUI → SUI swap
- Contains 3 token types in transaction payload
- Events show calls to both router and underlying DEX modules

## Implementation Plan
1. Remove `universal_router_swaps` CTE entirely
2. Add `transaction_module` filters for Cetus and Turbos 
3. Keep Aftermath, Bluefin, Momentum, and FlowX as-is
4. Update event type filter to remove Universal Router events

## Date: 2025-07-29
## Analysis Period: 3-day lookback from 2025-07-26