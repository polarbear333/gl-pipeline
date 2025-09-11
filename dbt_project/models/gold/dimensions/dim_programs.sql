{{ config(
    materialized='table',
    tags=['gold_layer', 'dimension']
) }}

with ledger_base as (
    select distinct
        program_code
    from {{ ref('stg_ledger') }}
    where program_code is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['program_code']) }} as program_sk, -- Surrogate Key
    program_code as program_business_key -- Natural/Business Key
from ledger_base