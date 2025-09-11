# src/validation/expectations.py
from great_expectations.validator.validator import Validator

def build_gold_kpi_expectations(validator: Validator):
    """
    Adds all expectations for the gold `kpi_monthly_summary` mart to a given Validator.
    This function is the single source of truth for this data asset's quality contract.

    Args:
        validator: A Great Expectations Validator object.
    """
    # Column existence
    validator.expect_column_to_exist("fiscal_year")
    validator.expect_column_to_exist("month")
    validator.expect_column_to_exist("department_name")
    validator.expect_column_to_exist("total_revenue")
    validator.expect_column_to_exist("total_expenses")
    validator.expect_column_to_exist("net_amount")
    validator.expect_column_to_exist("transaction_count")

    # Not nulls on keys and critical measures
    validator.expect_column_values_to_not_be_null("fiscal_year")
    validator.expect_column_values_to_not_be_null("month")
    validator.expect_column_values_to_not_be_null("net_amount")

    # Value sets and ranges
    validator.expect_column_values_to_be_in_set(
        "month", value_set=list(range(1, 13))
    )
    # Realistic bounds to catch extreme outliers
    validator.expect_column_min_to_be_between("total_expenses", min_value=-50_000_000_000.0)
    validator.expect_column_max_to_be_between("total_revenue", max_value=50_000_000_000.0)
    
    # Critical Business Logic Check (from our dbt test)
    # This ensures the KPI math is correct.
    validator.expect_select_column_values_to_be_equal_to_other_column(
        column_A="net_amount",
        column_B="total_revenue_plus_expenses" # A temporary column we create
    )