{{ config(
    materialized='table',
    tags=['gold_layer', 'mart']
) }}

-- This Data Mart provides an annual summary of spending for each agency from each fund.
-- It's ideal for high-level budgetary review and cross-agency comparisons.

with transactions as (
    select * from {{ ref('fct_transactions') }}
),

agencies as (
    select * from {{ ref('dim_agencies') }}
),

funds as (
    select * from {{ ref('dim_funds') }}
)

select
    transactions.fiscal_year,
    agencies.agency_business_key as agency_id,
    agencies.agency_name,
    funds.fund_business_key as fund_code,
        funds.fund_name as fund_name,

    -- Consistent KPI logic, aggregated annually.
    sum(case when transactions.amount >= 0 then transactions.amount else 0 end) as total_revenue,
    sum(case when transactions.amount < 0 then transactions.amount else 0 end) as total_expenses,
    
    sum(transactions.amount) as net_amount,
    count(*) as transaction_count

from transactions
left join agencies on transactions.agency_sk = agencies.agency_sk
left join funds on transactions.fund_sk = funds.fund_sk

where
    agencies.agency_sk is not null
    and funds.fund_sk is not null

group by
    transactions.fiscal_year,
    agencies.agency_business_key,
    agencies.agency_name,
    funds.fund_business_key,
        funds.fund_name