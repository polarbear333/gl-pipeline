{{ config(
    materialized='table',
    tags=['gold_layer', 'dimension']
) }}

with ledger_base as (
    select distinct
        account,
        acct_descr as account_name
    from {{ ref('stg_ledger') }}
    where account is not null and acct_descr is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['account']) }} as account_sk, -- Surrogate Key
    account as account_business_key, -- Natural/Business Key
    account_name
from ledger_base