{{ config(
    materialized='table' 
) }}

select
    department_sk,
    fiscal_year,
    month,
    sum(amount) as total_monthly_amount
from {{ ref('int_transactions_joined_to_dims') }}
group by
    department_sk,
    fiscal_year,
    month