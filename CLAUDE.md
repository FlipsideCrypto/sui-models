# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# dbt Documentation Standards for Claude Code x Flipside Crypto

**MOST IMPORTANT RULES**:
1. Every model MUST have a .yml file with standardized structure
2. Every gold-level table description MUST have markdown documentation with the 4 standard sections
3. SQL models must be materialized as incremental with efficient incremental predicates and filters.
4. Every model must include: inserted_timestamp, modified_timestamp, unique _id field, and the dbt _invocation_id

## Project Overview

This guide standardizes dbt model documentation across all blockchain ecosystems at Flipside. The documentation must support LLM-driven analytics workflows while maintaining human readability for blockchain data analysis.

**Main technologies**: dbt, Snowflake, Markdown, YAML, Jinja templating

## Base dbt CLI Commands

```bash
# Generate dbt documentation
dbt docs generate

# Serve documentation locally
dbt docs serve

# Test models
dbt test [-s] [dbt_model_name]

# Run a dbt model - note explicitly select models to run instead of running everything
dbt run [-s] [dbt_model_name]
dbt run [-s] [path/to/dbt/models]
dbt run [-s] [tag:dbt_model_tag]
```

## Data Modeling with dbt

### dbt Model Structure
- Models are connected through ref() and source() functions
- Data flows from source -> bronze -> silver -> gold layers
- Each model has upstream dependencies and downstream consumers
- Column-level lineage is maintained through transformations
- Parse ref() and source() calls to identify direct dependencies
- Track column transformations from upstream models
- Consider impact on downstream consumers
- Preserve business logic across transformations

### Model Naming and Organization
- Follow naming patterns: bronze__, silver__, core__, fact_, dim__, ez__, where a double underscore indicates a break between a model schema and object name. I.e. core__fact_blocks equates to <database>.core.fact_blocks.
- Organize by directory structure: bronze/, silver/, gold/, etc.
- Upstream models appear on the LEFT side of the DAG
- Current model is the focal point
- Downstream models appear on the RIGHT side of the DAG

### Modeling Standards
- Use snake_case for all objects
- Prioritize incremental processing always
- Follow source/bronze/silver/gold layering
- Document chain-specific assumptions
- Include incremental predicates to improve performance
- For gold layer models, include search optimization following Snowflake's recommended best practices
- Cluster models on appropriate fields

## Documentation Architecture

### 1. YML File Structure
Follow this exact structure for every dbt model:

```yaml
version: 2

models:
  - name: [model_name]
    description: "{{ doc('table_name') }}"
    tests:
      - [appropriate_tests_for_the_model]

    columns:
      - name: [COLUMN_NAME_IN_UPPERCASE]
        description: "{{ doc('column_name')}}"
        tests:
          - [appropriate_tests_for_the_column]
```

#### YAML Standards
- Column names MUST BE CAPITALIZED
- Use `{{ doc('reference') }}` for all descriptions
- Include appropriate tests for all models and columns
- Reference valid markdown files in `models/descriptions/`


### 2. Table Documentation (THE 4 STANDARD SECTIONS)

**IMPORTANT**: Every table description MUST include these sections in this order:

#### Description (the "what")
- What the model maps from the blockchain
- Data scope and coverage  
- Transformations and business logic applied
- **DO NOT** explain dbt model lineage

#### Key Use Cases
- Specific analytical scenarios and applications
- Examples of when this table would be used
- Real-world analysis patterns

#### Important Relationships
- How this table connects to OTHER GOLD LEVEL models
- Convert model names: `core__fact_blocks.sql` = `core.fact_blocks`
- Document ez_ tables sourcing from fact_ tables

#### Commonly-used Fields
- Fields most important for analytics
- Focus on fields that aid in blockchain analytics

#### Markdown Patterns
- Start with clear definitions
- Provide context about field purpose
- Include examples for complex concepts
- Explain relationships to other fields
- Use consistent terminology throughout project

### 3. Column Documentation Standards

**Each column description MUST include**:
- Clear definition of what the field represents
- Data type and format expectations
- Business context and use cases
- Examples for blockchain-specific concepts
- Relationships to other fields
- Important caveats or limitations

**For blockchain data**:
- Reference official protocol documentation
- Explain blockchain concepts (gas, consensus, etc.)
- Provide network-specific examples
- **NEVER** fabricate technical details like decimal places


**Blockchain Documentation Approach**:
- Research official protocol documentation first
- Explain network-specific concepts and conventions
- Provide analytical use case examples
- Focus on LLM-readable context
- Consider DeFi, NFT, and governance scenarios

## Sui-Specific Development Context

### Architecture & Data Pipeline
- **Profile**: `sui` targeting Snowflake database `sui_DEV` (dev) or `SUI` (prod)
- **Data layers**: bronze (raw) → silver (parsed) → gold (analytics-ready)
- **Real-time ingestion**: Streamline processes for live blockchain data
- **APIs**: AWS Lambda integration for Sui RPC calls (dev/prod environments)

### Required Model Configuration
Every model must use this pattern:
```sql
{{ config (
    materialized = "incremental",
    unique_key = ["field1", "field2"], 
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gold','core']
) }}
```

### Incremental Processing Pattern
All models require proper incremental predicates:
```sql
{% if is_incremental() %}
  WHERE modified_timestamp >= (
    SELECT MAX(modified_timestamp) 
    FROM {{ this }}
  )
{% endif %}
```

### Sui Blockchain Specifics
- **Object-centric model**: Unlike account-based chains, Sui uses objects with ownership
- **Checkpoints**: Consensus milestones containing batches of transactions
- **Move smart contracts**: Resource-oriented programming with explicit ownership
- **32-byte addresses**: Unique addressing system with hex format
- **High throughput**: Parallel execution enabling high transaction volume

### Testing & Quality Assurance
- All models include recency tests: `WHERE modified_timestamp::DATE > dateadd(hour, -36, sysdate())`
- Unique key constraints on dimension tables
- Data freshness monitoring via `TEST_HOURS_THRESHOLD` variable
- Comprehensive column-level testing for gold layer models

### Environment Configuration
Development uses environment-specific API integrations:
- **Dev**: `AWS_SUI_API_STG_V2` with staging endpoints
- **Prod**: `AWS_SUI_API_PROD_V2` with production endpoints
- **Snowflake tagging**: Automatic metadata application on model runs
- **Custom macros**: `create_sps()`, `create_udfs()`, query tagging

### Performance Optimization
- **Snowflake warehouse**: Optimized for analytical workloads
- **Incremental materialization**: Efficient updates using modified timestamps
- **Cluster keys**: Applied to high-volume fact tables
- **Query tagging**: Automatic monitoring and optimization via dbt_snowflake_query_tags

### Documentation Standards
Follow Flipside's 4-section table documentation structure in `models/descriptions/`:
1. **Description**: What the model represents
2. **Key Use Cases**: Analytical applications
3. **Important Relationships**: Connections to other gold models  
4. **Commonly-used Fields**: Key fields for analysis

Column documentation must include examples for Sui-specific concepts (objects, checkpoints, Move contracts).