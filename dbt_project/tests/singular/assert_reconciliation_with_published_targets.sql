-- This test compares key financial aggregates from our `fct_transactions` model
-- against the externally provided targets in the `published_financial_targets` seed.

with calculated_aggregates as (
    select
        'total_revenue' as metric_name,
        fiscal_year,
        sum(amount) as calculated_value
    from {{ ref('fct_transactions') }}
    where amount >= 0
    group by 1, 2

    union all

    select
        'total_expenses' as metric_name,
        fiscal_year,
        sum(amount) as calculated_value
    from {{ ref('fct_transactions') }}
    where amount < 0
    group by 1, 2
),

-- The `ref()` function on a seed file makes it a queryable table.
published_targets as (
    select * from {{ ref('published_financial_targets') }}
),

final as (
    select
        calculated.metric_name,
        calculated.fiscal_year,
        calculated.calculated_value,
        published.expected_value_usd
    from calculated_aggregates calculated
    join published_targets published
        on calculated.metric_name = published.metric_name
        and calculated.fiscal_year = published.fiscal_year
    -- Use a tolerance for floating point comparisons
    where abs(calculated.calculated_value - published.expected_value_usd) > 0.01
)

-- If this query returns any rows (i.e., any mismatches), the test fails.
select * from final