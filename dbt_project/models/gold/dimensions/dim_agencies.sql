{{ config(
    materialized='table',
    tags=['gold_layer', 'dimension']
) }}

with ledger_base as (
    select distinct
        agency_nbr,
        agency_name
    from {{ ref('stg_ledger') }}
    where agency_nbr is not null and agency_name is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['agency_nbr']) }} as agency_sk, -- Surrogate Key
    agency_nbr as agency_business_key, -- Natural/Business Key
    agency_name
from ledger_base