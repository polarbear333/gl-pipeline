{{ config(materialized='table', tags=['gold_layer', 'mart']) }}

-- This model creates a scaffold of all expected reporting periods for each
-- fund/agency combination that has any activity within a given fiscal year.

with fund_agency_year as (
    -- First, find every unique combination of fund, agency, and year that exists in the data.
    select distinct
        fund_sk,
        agency_sk,
        fiscal_year
    from {{ ref('fct_transactions') }}
),

all_periods as (
    -- Generate a series of numbers from 1 to 12 representing the accounting periods.
    select * from unnest(generate_series(1, 12)) as t(accounting_period)
)

-- Cross join to create the complete set of expected rows.
select
    fund_agency_year.fiscal_year,
    fund_agency_year.fund_sk,
    fund_agency_year.agency_sk,
    all_periods.accounting_period
from fund_agency_year
cross join all_periods