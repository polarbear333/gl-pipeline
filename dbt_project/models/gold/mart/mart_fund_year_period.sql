{{ config(
    materialized='table',
    tags=['gold_layer', 'mart']
) }}

-- This Data Mart aggregates financial data to a monthly level for each fund,
-- enabling time-series analysis of specific funding pools.

with transactions as (
    select * from {{ ref('fct_transactions') }}
),

funds as (
    select * from {{ ref('dim_funds') }}
)

select
    transactions.fiscal_year,
    transactions.accounting_period as month,
    funds.fund_business_key as fund_code,
    funds.fund_name as fund_name,

    -- We use the exact same, consistent KPI logic as our other marts.
    sum(case when transactions.amount >= 0 then transactions.amount else 0 end) as total_revenue,
    sum(case when transactions.amount < 0 then transactions.amount else 0 end) as total_expenses,
    
    sum(transactions.amount) as net_amount,
    count(*) as transaction_count

from transactions
left join funds on transactions.fund_sk = funds.fund_sk

where
    funds.fund_sk is not null

group by
    transactions.fiscal_year,
    transactions.accounting_period,
    funds.fund_business_key,
    funds.fund_name