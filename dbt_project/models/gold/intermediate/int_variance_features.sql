{{ config(
    materialized='table',  
    tags=['gold_layer']
) }}

select
    department_sk,
    fiscal_year,
    month,
    (
        total_monthly_amount - lag(total_monthly_amount, 1, 0) over (
            partition by department_sk 
            order by fiscal_year, month
        )
    ) as variance_vs_prior_month
from {{ ref('int_department_spend_monthly') }}