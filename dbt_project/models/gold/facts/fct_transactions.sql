{{ config(
    materialized='table',
    tags=['gold_layer', 'fact']
) }}


with ledger_base as (
    select
        agency_nbr,
    ledger,
        fund_code,
        dept_id,
        account,
        project_id,
        budget_ref,
        amount,
        fiscal_year,
        accounting_period
        
    from {{ ref('stg_ledger') }}
),

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

select
    dim_agencies.agency_sk,
    dim_funds.fund_sk,
    dim_departments.department_sk,
    dim_accounts.account_sk,
    dim_accounts.account_name,
    ledger_base.ledger,
    
    ledger_base.project_id,
    ledger_base.budget_ref,

    ledger_base.amount,
    ledger_base.fiscal_year,
    ledger_base.accounting_period

from ledger_base

left join dim_agencies
    on ledger_base.agency_nbr = dim_agencies.agency_business_key

left join dim_funds
    on ledger_base.fund_code = dim_funds.fund_business_key
    
left join dim_departments
    on ledger_base.dept_id = dim_departments.department_business_key
    
left join dim_accounts
    on ledger_base.account = dim_accounts.account_business_key