{{ config(
    materialized='view', 
) }}

select
    -- Keys
    tx.agency_sk,
    tx.fund_sk,
    tx.department_sk,
    tx.account_sk,

    -- Descriptive Fields
    agencies.agency_name,
    funds.fund_name,
    deps.department_name,
    accts.account_name,

    -- Facts and Dates
    tx.amount,
    tx.fiscal_year,
    tx.accounting_period as month

from {{ ref('fct_transactions') }} tx
left join {{ ref('dim_agencies') }} agencies on tx.agency_sk = agencies.agency_sk
left join {{ ref('dim_funds') }} funds on tx.fund_sk = funds.fund_sk
left join {{ ref('dim_departments') }} deps on tx.department_sk = deps.department_sk
left join {{ ref('dim_accounts') }} accts on tx.account_sk = accts.account_sk