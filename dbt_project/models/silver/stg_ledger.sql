{{ config(
    materialized='table',
    tags=['silver_layer'],
    post_hook="COPY (SELECT * FROM {{ this }}) TO 'data/silver/stg_ledger.parquet' (FORMAT PARQUET)"
) }}

with source as (
    select * from read_csv_auto(
        '{{ var("raw_data_path") }}/ledger_fy*.csv',
        union_by_name=true,
        filename=true,
        ignore_errors=true,
        sample_size=-1
    )
),

renamed as (
    select
        NULLIF(coalesce(trim(AGENCYNBR), trim(OPERATING_UNIT)), '')   as agency_nbr,
        coalesce(trim(AGENCYNAME), trim(OPERUNITDESCR)) as agency_name,
        NULLIF(trim(LEDGER),'')             as ledger,
        NULLIF(trim(cast(FISCAL_YEAR as string)),'')          as fiscal_year_raw,
        NULLIF(trim(cast(ACCOUNTING_PERIOD as string)),'')    as accounting_period_raw,
        NULLIF(cast(FUND_CODE as string),'')            as fund_code,
        trim(FUNDDESCR)            as fund_descr,
        trim(CLASS_FLD)            as class_fld,
        trim(CLASSDESCR)           as class_descr,
        NULLIF(trim(cast(DEPTID as string)),'')               as dept_id,
        trim(DEPTDESCR)            as dept_descr,
        NULLIF(cast(ACCOUNT as string),'')              as account,
        trim(ACCTDESCR)            as acct_descr,
        trim(OPERATING_UNIT)       as operating_unit,
        trim(OPERUNITDESCR)        as oper_unit_descr,
        trim(PRODUCT)              as product,
        trim(PRODUCTDESCR)         as product_descr,
        trim(PROGRAM_CODE)         as program_code,
        trim(PGMDESCR)             as pgm_descr,
        trim(cast(BUDGET_REF as string))           as budget_ref,
        trim(CHARTFIELD1)          as chartfield1,
        trim(CF1DESCR)             as cf1_descr,
        trim(CHARTFIELD2)          as chartfield2,
        trim(CF2DESCR)             as cf2_descr,
        trim(PROJECT_ID)           as project_id,
        trim(PROJDESCR)            as proj_descr,
        cast(POSTED_TOTAL_AMT as decimal(18,2)) as posted_total_amt_raw,
        trim(ACTIVITY)             as activity,
        trim(ACTVDESCR)            as actv_descr,
        trim(RESTYPE)              as res_type,
        trim(RESDESCR)             as res_descr,
        trim(RCAT)                 as rcat,
        trim(RCATDESCR)            as rcat_descr,
        trim(RSUBCAT)              as rsubcat,
        trim(RSUBCATDESCR)         as rsubcat_descr,
        NULLIF(trim(ROWID),'')                as row_id,
        filename as source_path
    from source
),

casted_and_derived as (
    select
        agency_nbr,
        agency_name,
        ledger,
        try_cast(try_cast(fiscal_year_raw as double) as integer) as fiscal_year,
        try_cast(try_cast(accounting_period_raw as double) as integer) as accounting_period,
        fund_code,
        fund_descr,
        class_fld,
        class_descr,
        dept_id,
        dept_descr,
        account,
        acct_descr,
        operating_unit,
        oper_unit_descr,
        product,
        product_descr,
        program_code,
        pgm_descr,
        budget_ref,
        chartfield1,
        cf1_descr,
        chartfield2,
        cf2_descr,
        project_id,
        proj_descr,
        posted_total_amt_raw as amount,
        activity,
        actv_descr,
        res_type,
        res_descr,
        rcat,
        rcat_descr,
        rsubcat,
        rsubcat_descr,
        row_id,
        source_path
    from renamed
),

quality_filtered as (
    select * from casted_and_derived
    where
        agency_nbr is not null
        and ledger is not null
        and fiscal_year is not null
        and accounting_period is not null
        and fund_code is not null
        and dept_id is not null
        and account is not null
        and row_id is not null
),

final as (
    select
    {{ dbt_utils.generate_surrogate_key([
            'agency_nbr',
            'ledger',
            'fiscal_year',
            'accounting_period',
            'fund_code',
            'dept_id',
            'account',
            'project_id',
            'row_id',
            'source_path'
        ]) }} as ledger_sk,
        *
    from quality_filtered
)

select * from final

