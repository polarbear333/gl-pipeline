{{ config(
    materialized='table',
    tags=['gold_layer', 'dimension']
) }}

with ledger_base as (
    select distinct
        dept_id,
        dept_descr as department_name
    from {{ ref('stg_ledger') }}
    where dept_id is not null and dept_descr is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['dept_id']) }} as department_sk, -- Surrogate Key
    dept_id as department_business_key, -- Natural/Business Key
    department_name
from ledger_base