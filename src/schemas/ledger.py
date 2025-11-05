import pandera as pa
from pandera.typing import Series

class LedgerSchema(pa.SchemaModel):
    amount: Series[pa.Float] = pa.Field(
        nullable=False, description="Transaction amount; can be positive or negative."
    )
    fiscal_year: Series[pa.Int] = pa.Field(
        ge=2000, le=2050, description="The fiscal year of the transaction."
    )
    quarter: Series[pa.Int] = pa.Field(
        ge=1, le=4, description="The fiscal quarter of the transaction."
    )
    

    department_name: Series[pa.String] = pa.Field(nullable=True)
    vendor_name: Series[pa.String] = pa.Field(nullable=True)
    transaction_description: Series[pa.String] = pa.Field(nullable=True)
    fund_code: Series[pa.String] = pa.Field(nullable=True, coerce=True) 
    
    class Config:
        """Pandera schema configuration."""
        coerce = True 
        strict = "filter"  
        multiindex_name = "ledger_entry" 