-- This test fails if there are any fund/agency/year combinations that
-- are missing data for one or more of the 12 accounting periods.

with scaffold as (
    select * from {{ ref('mart_completeness_scaffold') }}
),

actual_data as (
    select distinct
        fiscal_year,
        fund_sk,
        agency_sk,
        accounting_period
    from {{ ref('fct_transactions') }}
),

-- Find all the expected rows from the scaffold that are NOT present in the actual data.
missing_periods as (
    select * from scaffold
    except
    select * from actual_data
)

-- If this query returns any rows, the test will fail.
select * from missing_periods