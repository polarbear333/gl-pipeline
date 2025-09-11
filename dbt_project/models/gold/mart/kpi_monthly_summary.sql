{{ config(
    materialized='table',
    tags=['gold_layer', 'mart']
) }}

with transactions as (
    select * from {{ ref('fct_transactions') }}
),

dim_departments as (
    select * from {{ ref('dim_departments') }}
)

select
    transactions.fiscal_year,
    transactions.accounting_period as month,
    dim_departments.department_name,

    sum(case when transactions.amount > 0 then transactions.amount else 0 end) as total_revenue,
    sum(case when transactions.amount < 0 then transactions.amount else 0 end) as total_expenses,
    sum(transactions.amount) as net_amount,
    count(*) as transaction_count

from transactions
left join dim_departments on transactions.department_sk = dim_departments.department_sk
group by 1, 2, 3