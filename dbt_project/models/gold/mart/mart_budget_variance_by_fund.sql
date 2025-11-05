{{ config(materialized='table', tags=['gold_layer', 'mart']) }}

with actuals as (
    select
        fiscal_year,
        fund_sk,
        sum(amount) as actual_amount
    from {{ ref('fct_transactions') }}
    where ledger = 'ACTUALS' 
    group by 1, 2
),

budgets as (
    select
        fiscal_year,
        fund_sk,
        sum(amount) as budgeted_amount
    from {{ ref('fct_transactions') }}
    where ledger = 'BUDGET' 
    group by 1, 2
)

select
    actuals.fiscal_year,
    actuals.fund_sk,
    coalesce(actuals.actual_amount, 0) as actual_amount,
    coalesce(budgets.budgeted_amount, 0) as budgeted_amount,
    (coalesce(budgets.budgeted_amount, 0) - coalesce(actuals.actual_amount, 0)) as budget_variance
from actuals
full outer join budgets on actuals.fiscal_year = budgets.fiscal_year and actuals.fund_sk = budgets.fund_sk