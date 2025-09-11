{{ config(
    materialized='table',
    tags=['gold_layer', 'dimension']
) }}

with ledger_base as (
    select distinct
        fiscal_year,
        accounting_period
    from {{ ref('stg_ledger') }}
    where fiscal_year is not null and accounting_period is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['fiscal_year', 'accounting_period']) }} as time_sk, -- Surrogate Key
    fiscal_year as time_business_key,
    accounting_period,

    case
        when accounting_period = 0 then 'Q1'
        when accounting_period between 1 and 3 then 'Q1'
        when accounting_period between 4 and 6 then 'Q2'
        when accounting_period between 7 and 9 then 'Q3'
        when accounting_period between 10 and 12 then 'Q4'
        else 'Unknown'
    end as fiscal_quarter,

    -- Month Name Mapping (Period 0 = Opening Balance)
    case accounting_period
        when 0 then 'Opening Balance'
        when 1 then 'January'
        when 2 then 'February'
        when 3 then 'March'
        when 4 then 'April'
        when 5 then 'May'
        when 6 then 'June'
        when 7 then 'July'
        when 8 then 'August'
        when 9 then 'September'
        when 10 then 'October'
        when 11 then 'November'
        when 12 then 'December'
        else 'Unknown'
    end as fiscal_month_name

from ledger_base
order by fiscal_year, accounting_period
