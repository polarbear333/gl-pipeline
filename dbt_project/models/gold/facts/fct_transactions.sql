{{ config(
    materialized='table',
    tags=['gold_layer', 'fact']
) }}


with ledger_base as (
    select
        -- Business keys we will use to join to our dimension tables
        agency_nbr,
    ledger,
        fund_code,
        dept_id,
        account,
        
        -- Degenerate dimensions (IDs we want to keep on the fact table for reference)
        project_id,
        budget_ref,

        -- The primary numeric measure (the "fact")
        amount,
        
        -- Date-related fields that behave like facts
        fiscal_year,
        accounting_period
        
    from {{ ref('stg_ledger') }}
),

-- Import each dimension table, selecting only the surrogate key and business key.
dim_agencies as (
    select agency_sk, agency_business_key from {{ ref('dim_agencies') }}
),

dim_funds as (
    select fund_sk, fund_business_key from {{ ref('dim_funds') }}
),

dim_departments as (
    select department_sk, department_business_key from {{ ref('dim_departments') }}
),

dim_accounts as (
    select account_sk, account_business_key, account_name from {{ ref('dim_accounts') }}
)

-- Final SELECT statement to join everything together
select
    -- Foreign Keys that link this fact table to the dimension tables
    dim_agencies.agency_sk,
    dim_funds.fund_sk,
    dim_departments.department_sk,
    dim_accounts.account_sk,
    dim_accounts.account_name,
    
    -- Preserve ledger on the fact for downstream filtering/partitioning
    ledger_base.ledger,
    
    -- Degenerate Dimensions
    ledger_base.project_id,
    ledger_base.budget_ref,

    -- The Facts
    ledger_base.amount,
    ledger_base.fiscal_year,
    ledger_base.accounting_period

from ledger_base
-- Use LEFT JOINs to ensure we never lose a transaction, even if its
-- corresponding dimension entry is missing (which would indicate a data quality issue).
left join dim_agencies
    on ledger_base.agency_nbr = dim_agencies.agency_business_key

left join dim_funds
    on ledger_base.fund_code = dim_funds.fund_business_key
    
left join dim_departments
    on ledger_base.dept_id = dim_departments.department_business_key
    
left join dim_accounts
    on ledger_base.account = dim_accounts.account_business_key