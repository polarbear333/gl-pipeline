{{ config(
    materialized='table',
    tags=['gold_layer', 'dimension']
) }}

with ledger_base as (
    select distinct
        fund_code,
        fund_descr as fund_name
    from {{ ref('stg_ledger') }}
    where fund_code is not null and fund_descr is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['fund_code']) }} as fund_sk, -- Surrogate Key
    fund_code as fund_business_key, -- Natural/Business Key
    fund_name
from ledger_base