{{ config(materialized='table', tags=['gold_layer', 'mart']) }}

with fund_agency_year as (
    select distinct
        fund_sk,
        agency_sk,
        fiscal_year
    from {{ ref('fct_transactions') }}
),

all_periods as (
    select * from unnest(generate_series(1, 12)) as t(accounting_period)
)

select
    fund_agency_year.fiscal_year,
    fund_agency_year.fund_sk,
    fund_agency_year.agency_sk,
    all_periods.accounting_period
from fund_agency_year
cross join all_periods