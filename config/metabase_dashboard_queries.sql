-- =============================================================================
-- METABASE DASHBOARD QUERIES FOR FINANCIAL MONITORING SYSTEM
-- =============================================================================
-- Database: DuckDB (dbt_project.duckdb)
-- Schema: main
-- Generated: 2025-11-02
-- 
-- This file contains SQL queries optimized for creating Metabase dashboards
-- to visualize financial data from the Oklahoma state ledger system.
-- =============================================================================

-- =============================================================================
-- DASHBOARD 1: EXECUTIVE SUMMARY
-- =============================================================================

-- Query 1.1: Total Revenue vs Expenses by Fiscal Year
-- Purpose: High-level overview of financial performance
-- Visualization: Bar chart (grouped)
SELECT 
    fiscal_year,
    SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as total_revenue,
    ABS(SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END)) as total_expenses,
    SUM(amount) as net_amount
FROM main.fct_transactions
GROUP BY fiscal_year
ORDER BY fiscal_year;

-- Query 1.2: Monthly Trend - Current Fiscal Year
-- Purpose: Show monthly financial trends for the current year
-- Visualization: Line chart
-- Parameters: [[fiscal_year]] (default: 2024)
SELECT 
    accounting_period as month,
    SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as revenue,
    ABS(SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END)) as expenses,
    SUM(amount) as net_amount
FROM main.fct_transactions
WHERE fiscal_year = {{fiscal_year}}
    AND accounting_period > 0  
GROUP BY accounting_period
ORDER BY accounting_period;

-- Query 1.3: Top 10 Agencies by Total Spending
-- Purpose: Identify largest spending agencies
-- Visualization: Horizontal bar chart
-- Parameters: [[fiscal_year]]
SELECT 
    a.agency_name,
    ABS(SUM(CASE WHEN f.amount < 0 THEN f.amount ELSE 0 END)) as total_spending,
    COUNT(*) as transaction_count
FROM main.fct_transactions f
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
WHERE f.fiscal_year = {{fiscal_year}}
GROUP BY a.agency_name
ORDER BY total_spending DESC
LIMIT 10;

-- Query 1.4: Current Month KPI Summary
-- Purpose: Key metrics for dashboard header
-- Visualization: Number/KPI cards
-- Parameters: [[fiscal_year]], [[month]]
SELECT 
    SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as current_month_revenue,
    ABS(SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END)) as current_month_expenses,
    SUM(amount) as current_month_net,
    COUNT(*) as total_transactions,
    COUNT(DISTINCT agency_sk) as active_agencies
FROM main.fct_transactions
WHERE fiscal_year = {{fiscal_year}}
    AND accounting_period = {{month}};


-- =============================================================================
-- DASHBOARD 2: AGENCY ANALYSIS
-- =============================================================================

-- Query 2.1: Agency Spending Breakdown by Fund
-- Purpose: Show how each agency allocates spending across funds
-- Visualization: Stacked bar chart
-- Parameters: [[fiscal_year]], [[agency_name]] (optional filter)
SELECT 
    a.agency_name,
    fn.fund_name,
    ABS(SUM(CASE WHEN f.amount < 0 THEN f.amount ELSE 0 END)) as spending
FROM main.fct_transactions f
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
JOIN main.dim_funds fn ON f.fund_sk = fn.fund_sk
WHERE f.fiscal_year = {{fiscal_year}}
    AND f.amount < 0  -- Only expenses
    {% if agency_name %}
    AND a.agency_name = {{agency_name}}
    {% endif %}
GROUP BY a.agency_name, fn.fund_name
HAVING spending > 0
ORDER BY a.agency_name, spending DESC;

-- Query 2.2: Agency Monthly Spending Trend
-- Purpose: Track spending patterns over time for an agency
-- Visualization: Line chart
-- Parameters: [[agency_name]], [[fiscal_year]]
SELECT 
    f.accounting_period as month,
    ABS(SUM(CASE WHEN f.amount < 0 THEN f.amount ELSE 0 END)) as monthly_spending,
    COUNT(*) as transaction_count
FROM main.fct_transactions f
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
WHERE a.agency_name = {{agency_name}}
    AND f.fiscal_year = {{fiscal_year}}
    AND f.accounting_period > 0
GROUP BY f.accounting_period
ORDER BY f.accounting_period;

-- Query 2.3: Top Expense Categories by Agency
-- Purpose: Break down spending by account type
-- Visualization: Pie chart or horizontal bar
-- Parameters: [[agency_name]], [[fiscal_year]]
SELECT 
    ac.account_name,
    ABS(SUM(f.amount)) as spending,
    COUNT(*) as transaction_count,
    ROUND(ABS(SUM(f.amount)) * 100.0 / SUM(ABS(SUM(f.amount))) OVER (), 2) as percentage
FROM main.fct_transactions f
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
JOIN main.dim_accounts ac ON f.account_sk = ac.account_sk
WHERE a.agency_name = {{agency_name}}
    AND f.fiscal_year = {{fiscal_year}}
    AND f.amount < 0
GROUP BY ac.account_name
ORDER BY spending DESC
LIMIT 15;

-- Query 2.4: Agency Comparison Table
-- Purpose: Compare multiple agencies side by side
-- Visualization: Table
-- Parameters: [[fiscal_year]]
SELECT 
    a.agency_name,
    SUM(CASE WHEN f.amount > 0 THEN f.amount ELSE 0 END) as total_revenue,
    ABS(SUM(CASE WHEN f.amount < 0 THEN f.amount ELSE 0 END)) as total_expenses,
    SUM(f.amount) as net_amount,
    COUNT(*) as transactions,
    COUNT(DISTINCT f.department_sk) as departments_count,
    AVG(ABS(f.amount)) as avg_transaction_size
FROM main.fct_transactions f
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
WHERE f.fiscal_year = {{fiscal_year}}
GROUP BY a.agency_name
ORDER BY total_expenses DESC;


-- =============================================================================
-- DASHBOARD 3: FUND MANAGEMENT
-- =============================================================================

-- Query 3.1: Fund Balance Overview
-- Purpose: Show current balance and activity for each fund
-- Visualization: Table with conditional formatting
-- Parameters: [[fiscal_year]]
SELECT 
    fn.fund_name,
    SUM(CASE WHEN f.amount > 0 THEN f.amount ELSE 0 END) as total_revenue,
    ABS(SUM(CASE WHEN f.amount < 0 THEN f.amount ELSE 0 END)) as total_expenses,
    SUM(f.amount) as net_balance,
    COUNT(*) as transaction_count,
    COUNT(DISTINCT f.agency_sk) as agencies_using_fund
FROM main.fct_transactions f
JOIN main.dim_funds fn ON f.fund_sk = fn.fund_sk
WHERE f.fiscal_year = {{fiscal_year}}
GROUP BY fn.fund_name
ORDER BY ABS(SUM(f.amount)) DESC;

-- Query 3.2: Fund Activity Over Time
-- Purpose: Track fund balances month by month
-- Visualization: Area chart (stacked)
-- Parameters: [[fiscal_year]]
SELECT 
    f.accounting_period as month,
    fn.fund_name,
    SUM(f.amount) as net_amount
FROM main.fct_transactions f
JOIN main.dim_funds fn ON f.fund_sk = fn.fund_sk
WHERE f.fiscal_year = {{fiscal_year}}
    AND f.accounting_period > 0
GROUP BY f.accounting_period, fn.fund_name
ORDER BY f.accounting_period, fn.fund_name;

-- Query 3.3: Budget Variance Analysis
-- Purpose: Compare actual vs budgeted amounts
-- Visualization: Bar chart with variance indicator
-- Parameters: [[fiscal_year]]
SELECT 
    fn.fund_name,
    v.actual_amount,
    v.budgeted_amount,
    v.budget_variance,
    CASE 
        WHEN v.budgeted_amount != 0 THEN 
            ROUND((v.budget_variance / ABS(v.budgeted_amount)) * 100, 2)
        ELSE NULL 
    END as variance_percentage,
    CASE
        WHEN v.budget_variance > 0 THEN 'Over Budget'
        WHEN v.budget_variance < 0 THEN 'Under Budget'
        ELSE 'On Budget'
    END as variance_status
FROM main.mart_budget_variance_by_fund v
JOIN main.dim_funds fn ON v.fund_sk = fn.fund_sk
WHERE v.fiscal_year = {{fiscal_year}}
ORDER BY ABS(v.budget_variance) DESC;

-- Query 3.4: Fund Utilization by Agency
-- Purpose: See which agencies use which funds
-- Visualization: Heatmap or pivot table
-- Parameters: [[fiscal_year]], [[fund_name]] (optional)
SELECT 
    a.agency_name,
    fn.fund_name,
    ABS(SUM(f.amount)) as total_amount,
    COUNT(*) as transaction_count
FROM main.fct_transactions f
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
JOIN main.dim_funds fn ON f.fund_sk = fn.fund_sk
WHERE f.fiscal_year = {{fiscal_year}}
    {% if fund_name %}
    AND fn.fund_name = {{fund_name}}
    {% endif %}
GROUP BY a.agency_name, fn.fund_name
HAVING total_amount > 10000  -- Filter out small amounts
ORDER BY total_amount DESC
LIMIT 50;


-- =============================================================================
-- DASHBOARD 4: DEPARTMENT PERFORMANCE
-- =============================================================================

-- Query 4.1: Department Spending Summary
-- Purpose: Overview of all departments
-- Visualization: Table with sorting and filtering
-- Parameters: [[fiscal_year]]
SELECT 
    d.department_name,
    a.agency_name,
    SUM(CASE WHEN f.amount > 0 THEN f.amount ELSE 0 END) as revenue,
    ABS(SUM(CASE WHEN f.amount < 0 THEN f.amount ELSE 0 END)) as expenses,
    SUM(f.amount) as net_amount,
    COUNT(*) as transactions
FROM main.fct_transactions f
JOIN main.dim_departments d ON f.department_sk = d.department_sk
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
WHERE f.fiscal_year = {{fiscal_year}}
GROUP BY d.department_name, a.agency_name
ORDER BY expenses DESC
LIMIT 100;

-- Query 4.2: Department Monthly Variance
-- Purpose: Identify departments with unusual spending patterns
-- Visualization: Line chart with variance bands
-- Parameters: [[fiscal_year]]
SELECT 
    d.department_name,
    v.month,
    v.variance_vs_prior_month,
    m.total_monthly_amount
FROM main.int_variance_features v
JOIN main.dim_departments d ON v.department_sk = d.department_sk
JOIN main.int_department_spend_monthly m 
    ON v.department_sk = m.department_sk 
    AND v.fiscal_year = m.fiscal_year 
    AND v.month = m.month
WHERE v.fiscal_year = {{fiscal_year}}
    AND ABS(v.variance_vs_prior_month) > 100000  -- Significant variances only
ORDER BY ABS(v.variance_vs_prior_month) DESC
LIMIT 50;

-- Query 4.3: Top Growing Departments
-- Purpose: Identify departments with biggest YoY growth
-- Visualization: Bar chart
-- Parameters: [[current_year]], [[prior_year]]
WITH current_year AS (
    SELECT 
        d.department_name,
        ABS(SUM(f.amount)) as current_spending
    FROM main.fct_transactions f
    JOIN main.dim_departments d ON f.department_sk = d.department_sk
    WHERE f.fiscal_year = {{current_year}}
    GROUP BY d.department_name
),
prior_year AS (
    SELECT 
        d.department_name,
        ABS(SUM(f.amount)) as prior_spending
    FROM main.fct_transactions f
    JOIN main.dim_departments d ON f.department_sk = d.department_sk
    WHERE f.fiscal_year = {{prior_year}}
    GROUP BY d.department_name
)
SELECT 
    cy.department_name,
    cy.current_spending,
    COALESCE(py.prior_spending, 0) as prior_spending,
    cy.current_spending - COALESCE(py.prior_spending, 0) as spending_change,
    CASE 
        WHEN COALESCE(py.prior_spending, 0) > 0 THEN
            ROUND(((cy.current_spending - py.prior_spending) / py.prior_spending) * 100, 2)
        ELSE NULL
    END as growth_percentage
FROM current_year cy
LEFT JOIN prior_year py ON cy.department_name = py.department_name
WHERE cy.current_spending > 50000  -- Filter small departments
ORDER BY spending_change DESC
LIMIT 20;


-- =============================================================================
-- DASHBOARD 5: TRANSACTION DEEP DIVE
-- =============================================================================

-- Query 5.1: Transaction Volume by Ledger Type
-- Purpose: Compare ACTUALS vs BUDGET transactions
-- Visualization: Pie chart
-- Parameters: [[fiscal_year]]
SELECT 
    ledger,
    COUNT(*) as transaction_count,
    SUM(ABS(amount)) as total_amount,
    AVG(ABS(amount)) as avg_amount
FROM main.fct_transactions
WHERE fiscal_year = {{fiscal_year}}
GROUP BY ledger;

-- Query 5.2: Large Transactions Report
-- Purpose: Identify significant individual transactions
-- Visualization: Table
-- Parameters: [[fiscal_year]], [[min_amount]]
SELECT 
    a.agency_name,
    d.department_name,
    ac.account_name,
    fn.fund_name,
    f.amount,
    f.accounting_period as month,
    f.ledger,
    f.project_id
FROM main.fct_transactions f
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
JOIN main.dim_departments d ON f.department_sk = d.department_sk
JOIN main.dim_accounts ac ON f.account_sk = ac.account_sk
JOIN main.dim_funds fn ON f.fund_sk = fn.fund_sk
WHERE f.fiscal_year = {{fiscal_year}}
    AND ABS(f.amount) > {{min_amount}}
ORDER BY ABS(f.amount) DESC
LIMIT 100;

-- Query 5.3: Transaction Count by Month and Agency
-- Purpose: Activity heatmap
-- Visualization: Heatmap
-- Parameters: [[fiscal_year]]
SELECT 
    a.agency_name,
    f.accounting_period as month,
    COUNT(*) as transaction_count,
    SUM(ABS(f.amount)) as total_amount
FROM main.fct_transactions f
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
WHERE f.fiscal_year = {{fiscal_year}}
    AND f.accounting_period > 0
GROUP BY a.agency_name, f.accounting_period
ORDER BY a.agency_name, f.accounting_period;

-- Query 5.4: Account Distribution
-- Purpose: See most commonly used account types
-- Visualization: Bar chart
-- Parameters: [[fiscal_year]]
SELECT 
    ac.account_name,
    COUNT(*) as usage_count,
    SUM(ABS(f.amount)) as total_amount,
    COUNT(DISTINCT f.agency_sk) as agencies_using,
    COUNT(DISTINCT f.department_sk) as departments_using
FROM main.fct_transactions f
JOIN main.dim_accounts ac ON f.account_sk = ac.account_sk
WHERE f.fiscal_year = {{fiscal_year}}
GROUP BY ac.account_name
ORDER BY usage_count DESC
LIMIT 30;


-- =============================================================================
-- DASHBOARD 6: MONTHLY KPI DASHBOARD
-- =============================================================================

-- Query 6.1: Monthly Summary - All Metrics
-- Purpose: Comprehensive monthly view using pre-aggregated data
-- Visualization: Table with sparklines
-- Parameters: [[fiscal_year]]
SELECT 
    month,
    department_name,
    total_revenue,
    total_expenses,
    net_amount,
    transaction_count,
    ROUND(total_revenue + total_expenses, 2) as total_activity,
    CASE 
        WHEN total_expenses != 0 THEN 
            ROUND((total_revenue / ABS(total_expenses)) * 100, 2)
        ELSE NULL 
    END as revenue_expense_ratio
FROM main.kpi_monthly_summary
WHERE fiscal_year = {{fiscal_year}}
    AND month = {{month}}
ORDER BY ABS(net_amount) DESC
LIMIT 50;

-- Query 6.2: Year-to-Date Cumulative
-- Purpose: Show cumulative amounts through the year
-- Visualization: Area chart
-- Parameters: [[fiscal_year]]
SELECT 
    month,
    SUM(total_revenue) OVER (ORDER BY month) as ytd_revenue,
    SUM(total_expenses) OVER (ORDER BY month) as ytd_expenses,
    SUM(net_amount) OVER (ORDER BY month) as ytd_net
FROM (
    SELECT 
        month,
        SUM(total_revenue) as total_revenue,
        SUM(total_expenses) as total_expenses,
        SUM(net_amount) as net_amount
    FROM main.kpi_monthly_summary
    WHERE fiscal_year = {{fiscal_year}}
        AND month > 0
    GROUP BY month
) monthly_totals
ORDER BY month;

-- Query 6.3: Department Performance Ranking
-- Purpose: Rank departments by key metrics
-- Visualization: Table with rank indicators
-- Parameters: [[fiscal_year]], [[month]]
SELECT 
    department_name,
    total_revenue,
    total_expenses,
    net_amount,
    transaction_count,
    RANK() OVER (ORDER BY ABS(total_expenses) DESC) as expense_rank,
    RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank,
    RANK() OVER (ORDER BY transaction_count DESC) as activity_rank
FROM main.kpi_monthly_summary
WHERE fiscal_year = {{fiscal_year}}
    AND month = {{month}}
ORDER BY ABS(net_amount) DESC
LIMIT 30;


-- =============================================================================
-- DASHBOARD 7: DATA QUALITY & COMPLETENESS
-- =============================================================================

-- Query 7.1: Missing Dimension Check
-- Purpose: Identify transactions with missing dimension references
-- Visualization: Table with alert indicators
-- Parameters: [[fiscal_year]]
SELECT 
    'Missing Agency' as issue_type,
    COUNT(*) as affected_transactions,
    SUM(ABS(amount)) as total_amount
FROM main.fct_transactions
WHERE fiscal_year = {{fiscal_year}}
    AND agency_sk IS NULL

UNION ALL

SELECT 
    'Missing Fund' as issue_type,
    COUNT(*) as affected_transactions,
    SUM(ABS(amount)) as total_amount
FROM main.fct_transactions
WHERE fiscal_year = {{fiscal_year}}
    AND fund_sk IS NULL

UNION ALL

SELECT 
    'Missing Department' as issue_type,
    COUNT(*) as affected_transactions,
    SUM(ABS(amount)) as total_amount
FROM main.fct_transactions
WHERE fiscal_year = {{fiscal_year}}
    AND department_sk IS NULL

UNION ALL

SELECT 
    'Missing Account' as issue_type,
    COUNT(*) as affected_transactions,
    SUM(ABS(amount)) as total_amount
FROM main.fct_transactions
WHERE fiscal_year = {{fiscal_year}}
    AND account_sk IS NULL;

-- Query 7.2: Period Completeness
-- Purpose: Ensure all expected periods have data
-- Visualization: Table with status indicators
-- Parameters: [[fiscal_year]]
SELECT 
    t.accounting_period,
    t.fiscal_month_name,
    COUNT(DISTINCT f.agency_sk) as agencies_with_data,
    COUNT(*) as transaction_count,
    SUM(ABS(f.amount)) as total_amount,
    CASE 
        WHEN COUNT(*) > 0 THEN 'Complete'
        ELSE 'Missing'
    END as status
FROM main.dim_time t
LEFT JOIN main.fct_transactions f 
    ON t.time_business_key = f.fiscal_year 
    AND t.accounting_period = f.accounting_period
WHERE t.time_business_key = {{fiscal_year}}
GROUP BY t.accounting_period, t.fiscal_month_name
ORDER BY t.accounting_period;

-- Query 7.3: Duplicate Transaction Detection
-- Purpose: Find potential duplicate entries
-- Visualization: Table
-- Parameters: [[fiscal_year]]
SELECT 
    agency_sk,
    fund_sk,
    department_sk,
    account_sk,
    amount,
    fiscal_year,
    accounting_period,
    COUNT(*) as duplicate_count
FROM main.fct_transactions
WHERE fiscal_year = {{fiscal_year}}
GROUP BY 
    agency_sk, fund_sk, department_sk, account_sk,
    amount, fiscal_year, accounting_period
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, ABS(amount) DESC
LIMIT 100;

-- Query 7.4: Record Count by Source
-- Purpose: Track data volume from different sources
-- Visualization: Bar chart
SELECT 
    CASE 
        WHEN source_path LIKE '%qtr1%' THEN 'Q1'
        WHEN source_path LIKE '%qtr2%' THEN 'Q2'
        WHEN source_path LIKE '%qtr3%' THEN 'Q3'
        WHEN source_path LIKE '%qtr4%' THEN 'Q4'
        ELSE 'Unknown'
    END as quarter,
    fiscal_year,
    COUNT(*) as record_count,
    SUM(ABS(amount)) as total_amount
FROM main.stg_ledger
GROUP BY quarter, fiscal_year
ORDER BY fiscal_year, quarter;


-- =============================================================================
-- DASHBOARD 8: ADVANCED ANALYTICS
-- =============================================================================

-- Query 8.1: Spending Concentration (Top N%)
-- Purpose: Analyze spending concentration (e.g., 80/20 rule)
-- Visualization: Line chart showing cumulative percentage
-- Parameters: [[fiscal_year]]
WITH agency_totals AS (
    SELECT 
        a.agency_name,
        ABS(SUM(f.amount)) as total_spending
    FROM main.fct_transactions f
    JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
    WHERE f.fiscal_year = {{fiscal_year}}
        AND f.amount < 0
    GROUP BY a.agency_name
),
ranked_agencies AS (
    SELECT 
        agency_name,
        total_spending,
        SUM(total_spending) OVER () as grand_total,
        SUM(total_spending) OVER (ORDER BY total_spending DESC) as cumulative_spending,
        ROW_NUMBER() OVER (ORDER BY total_spending DESC) as rank
    FROM agency_totals
)
SELECT 
    agency_name,
    total_spending,
    ROUND((cumulative_spending / grand_total) * 100, 2) as cumulative_percentage,
    rank
FROM ranked_agencies
ORDER BY rank;

-- Query 8.2: Seasonality Analysis
-- Purpose: Identify seasonal spending patterns
-- Visualization: Line chart with multiple years
SELECT 
    f.accounting_period as month,
    f.fiscal_year,
    ABS(SUM(CASE WHEN f.amount < 0 THEN f.amount ELSE 0 END)) as spending
FROM main.fct_transactions f
WHERE f.accounting_period > 0
    AND f.fiscal_year IN ({{year1}}, {{year2}}, {{year3}})
GROUP BY f.accounting_period, f.fiscal_year
ORDER BY f.accounting_period, f.fiscal_year;

-- Query 8.3: Cross-Fund Analysis
-- Purpose: See agencies that use multiple funds
-- Visualization: Pivot table or network diagram
-- Parameters: [[fiscal_year]]
SELECT 
    a.agency_name,
    COUNT(DISTINCT f.fund_sk) as funds_used,
    STRING_AGG(DISTINCT fn.fund_name, ', ') as fund_list,
    SUM(ABS(f.amount)) as total_amount
FROM main.fct_transactions f
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
JOIN main.dim_funds fn ON f.fund_sk = fn.fund_sk
WHERE f.fiscal_year = {{fiscal_year}}
GROUP BY a.agency_name
HAVING COUNT(DISTINCT f.fund_sk) > 1
ORDER BY funds_used DESC, total_amount DESC
LIMIT 30;

-- Query 8.4: Efficiency Metrics
-- Purpose: Calculate cost per transaction by agency
-- Visualization: Scatter plot
-- Parameters: [[fiscal_year]]
SELECT 
    a.agency_name,
    COUNT(*) as transaction_count,
    ABS(SUM(f.amount)) as total_amount,
    ROUND(ABS(SUM(f.amount)) / COUNT(*), 2) as avg_transaction_value,
    COUNT(DISTINCT f.department_sk) as department_count,
    ROUND(ABS(SUM(f.amount)) / COUNT(DISTINCT f.department_sk), 2) as spending_per_department
FROM main.fct_transactions f
JOIN main.dim_agencies a ON f.agency_sk = a.agency_sk
WHERE f.fiscal_year = {{fiscal_year}}
GROUP BY a.agency_name
HAVING transaction_count > 100  -- Filter out small agencies
ORDER BY avg_transaction_value DESC;


-- =============================================================================
-- USEFUL FILTER QUERIES FOR DROPDOWNS
-- =============================================================================

-- Get list of fiscal years
SELECT DISTINCT fiscal_year
FROM main.fct_transactions
ORDER BY fiscal_year DESC;

-- Get list of agencies
SELECT DISTINCT agency_name
FROM main.dim_agencies
ORDER BY agency_name;

-- Get list of funds
SELECT DISTINCT fund_name
FROM main.dim_funds
ORDER BY fund_name;

-- Get list of departments
SELECT DISTINCT department_name
FROM main.dim_departments
ORDER BY department_name;

-- Get list of months for a fiscal year
SELECT DISTINCT 
    accounting_period,
    fiscal_month_name
FROM main.dim_time
WHERE time_business_key = {{fiscal_year}}
ORDER BY accounting_period;


-- =============================================================================
-- NOTES ON METABASE IMPLEMENTATION
-- =============================================================================
-- 
-- Parameter Syntax:
-- - Use {{parameter_name}} for required parameters
-- - Use {% if parameter_name %} ... {% endif %} for optional filters
-- - Set default values in Metabase UI
-- 
-- Recommended Dashboard Structure:
-- 1. Executive Summary (Queries 1.1-1.4) - High-level overview
-- 2. Agency Analysis (Queries 2.1-2.4) - Drill-down by agency
-- 3. Fund Management (Queries 3.1-3.4) - Financial tracking
-- 4. Department Performance (Queries 4.1-4.3) - Operational insights
-- 5. Transaction Details (Queries 5.1-5.4) - Transaction-level analysis
-- 6. Monthly KPIs (Queries 6.1-6.3) - Regular monitoring
-- 7. Data Quality (Queries 7.1-7.4) - Data integrity checks
-- 8. Advanced Analytics (Queries 8.1-8.4) - Deep insights
-- 
-- Performance Tips:
-- - Most queries use pre-aggregated tables (mart_* and int_* tables)
-- - Add date filters to all queries to limit data scanned
-- - Use LIMIT clauses for large result sets
-- - Consider creating materialized views for frequently used queries
-- 
-- Visualization Recommendations:
-- - Time series data → Line or area charts
-- - Comparisons → Bar charts (vertical or horizontal)
-- - Proportions → Pie or donut charts
-- - Rankings → Tables with conditional formatting
-- - Distributions → Histograms or box plots
-- - Correlations → Scatter plots
-- - Hierarchies → Treemaps or sunburst charts
-- =============================================================================
