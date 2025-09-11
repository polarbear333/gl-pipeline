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
    
    # Example columns - expand based on actual data exploration
    department_name: Series[pa.String] = pa.Field(nullable=True)
    vendor_name: Series[pa.String] = pa.Field(nullable=True)
    transaction_description: Series[pa.String] = pa.Field(nullable=True)
    fund_code: Series[pa.String] = pa.Field(nullable=True, coerce=True) # coerce will cast things like 123 to "123"
    
    # We can add more columns and checks here as we understand the data better.
    # For example, date columns, category codes, etc.

    class Config:
        """Pandera schema configuration."""
        coerce = True  # Attempt to cast columns to the correct type
        strict = "filter"  # Drop columns not defined in the schema
        multiindex_name = "ledger_entry" # A name for the index in validation reports