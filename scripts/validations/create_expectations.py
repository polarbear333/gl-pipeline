import great_expectations as gx
from great_expectations.core.expectation_configuration import ExpectationConfiguration
from loguru import logger
import os


DATASOURCE_NAME = "silver_layer_source"
SUITE_NAME = "silver_ledger_suite"
DATA_DIR = "data/silver"  

def create_and_save_suite():
    """
    Defines a Great Expectations suite programmatically and saves it to disk.
    This is a one-time setup script.
    """
    logger.info("--- Creating Great Expectations Suite ---")
    
    context = gx.get_context()

    # Check if datasource already exists
    try:
        datasource = context.get_datasource(DATASOURCE_NAME)
        logger.info(f"Datasource '{DATASOURCE_NAME}' already exists. Re-using.")
    except ValueError:
        # Datasource doesn't exist, create it
        logger.info(f"Creating new datasource '{DATASOURCE_NAME}'...")
        
        # Create datasource configuration for pandas with filesystem
        datasource_config = {
            "name": DATASOURCE_NAME,
            "class_name": "Datasource",
            "module_name": "great_expectations.datasource",
            "execution_engine": {
                "class_name": "PandasExecutionEngine",
                "module_name": "great_expectations.execution_engine",
            },
            "data_connectors": {
                "default_inferred_data_connector_name": {
                    "class_name": "InferredAssetFilesystemDataConnector",
                    "base_directory": DATA_DIR,
                    "default_regex": {
                        "group_names": ["data_asset_name"],
                        "pattern": r"(.*)\.parquet"
                    },
                },
            },
        }
        
        # Add the datasource to context
        datasource = context.add_datasource(**datasource_config)
    
    logger.info(f"Creating Expectation Suite named '{SUITE_NAME}'...")
    
    # Try to get existing suite, or create new one
    try:
        suite = context.get_expectation_suite(expectation_suite_name=SUITE_NAME)
        logger.info(f"Suite '{SUITE_NAME}' already exists. Updating it.")
    except:
        suite = context.create_expectation_suite(expectation_suite_name=SUITE_NAME)
        logger.info(f"Created new suite '{SUITE_NAME}'.")
    
    # Clear existing expectations to start fresh
    suite.expectations = []
    
    # Column Existence
    suite.add_expectation(ExpectationConfiguration(
        expectation_type="expect_column_to_exist", 
        kwargs={"column": "ledger_sk"}
    ))
    suite.add_expectation(ExpectationConfiguration(
        expectation_type="expect_column_to_exist", 
        kwargs={"column": "amount"}
    ))
    suite.add_expectation(ExpectationConfiguration(
        expectation_type="expect_column_to_exist", 
        kwargs={"column": "fiscal_year"}
    ))
    suite.add_expectation(ExpectationConfiguration(
        expectation_type="expect_column_to_exist", 
        kwargs={"column": "ledger"}
    ))

    # Not Null Constraints
    suite.add_expectation(ExpectationConfiguration(
        expectation_type="expect_column_values_to_not_be_null", 
        kwargs={"column": "ledger_sk"}
    ))
    suite.add_expectation(ExpectationConfiguration(
        expectation_type="expect_column_values_to_not_be_null", 
        kwargs={"column": "amount"}
    ))
    

    # Uniqueness
    suite.add_expectation(ExpectationConfiguration(
        expectation_type="expect_column_values_to_be_unique", 
        kwargs={"column": "ledger_sk"}
    ))

    # Type and Value Set Constraints
    suite.add_expectation(ExpectationConfiguration(
        expectation_type="expect_column_values_to_be_in_set",
        kwargs={"column": "fiscal_year", "value_set": [2022, 2023, 2024, 2025, 2026]}
    ))
    suite.add_expectation(ExpectationConfiguration(
        expectation_type="expect_column_values_to_be_in_set",
        kwargs={"column": "ledger", "value_set": ["ACTUALS", "BUDGET", "ENCUMBRANCE", "APPROPRIATION"]}
    ))
    
    # Save the suite
    context.save_expectation_suite(expectation_suite=suite, expectation_suite_name=SUITE_NAME)
    logger.success(f"Suite '{SUITE_NAME}' created and saved successfully!")
    logger.info("You can now commit the new suite file found in `great_expectations/expectations/`")

if __name__ == "__main__":
    create_and_save_suite()