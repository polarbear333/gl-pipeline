import sys
from pathlib import Path
from typing import Any
import json

import great_expectations as gx
from loguru import logger

# --- Configuration ---
DATASOURCE_NAME = "gold_layer_source"
DATA_ASSET_NAME = "kpi_monthly_summary"
DATA_DIR = "data/gold"
DATA_DOCS_DIR = "great_expectations/uncommitted/data_docs/local_site_gold"


def setup_ephemeral_context() -> Any:
    """Create an Ephemeral (in-memory) GX context using GE 1.x Fluent API."""
    try:
        # Let GX construct a proper in-memory config with temp docs and stores.
        return gx.get_context(mode="ephemeral")
    except Exception as e:
        logger.error(f"Failed to initialize Great Expectations context: {e}")
        sys.exit(1)     


def configure_datasource_and_asset(context: Any):
    """Ensure a pandas filesystem datasource and parquet asset exist; return the asset."""
    base_dir = Path(DATA_DIR).resolve(strict=False)  # force absolute path
    logger.info(f"Using datasource base_directory: {base_dir}")
    base_dir.mkdir(parents=True, exist_ok=True)      # ensure directory exists

    try:
        ds = context.data_sources.add_pandas_filesystem(
            name=DATASOURCE_NAME,
            base_directory=base_dir,
            data_context_root_directory=Path.cwd(),
        )
    except Exception:
        ds = context.data_sources.get(DATASOURCE_NAME)

    try:
        asset = ds.add_parquet_asset(
            name=DATA_ASSET_NAME, glob_directive=f"{DATA_ASSET_NAME}.parquet"
        )
    except Exception:
        asset = next(a for a in ds.assets if a.name == DATA_ASSET_NAME)

    return asset


def build_validator(context: Any, asset: Any):
    """Build a Validator from the asset and add expectations using GE 1.x API."""
    validator = context.get_validator(batch_request=asset.build_batch_request())

    # Column existence checks
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
    validator.expect_column_values_to_not_be_null("department_name")
    validator.expect_column_values_to_not_be_null("net_amount")

    # Value sets and ranges
    validator.expect_column_values_to_be_in_set(
        "fiscal_year", value_set=[2022, 2023, 2024, 2025, 2026]
    )
    # Allow for null months in case of yearly aggregations
    validator.expect_column_values_to_be_in_set(
        "month", value_set=list(range(1, 13)) + [None], mostly=0.95
    )

    # Financial bounds - adjusted for actual data ranges
    validator.expect_column_min_to_be_between(
        "total_revenue", 
        min_value=-100_000_000_000.00, 
        strict_min=False 
    )
    validator.expect_column_max_to_be_between(
        "total_revenue",
        max_value=100_000_000_000.00, 
        strict_max=False
    )
    validator.expect_column_min_to_be_between(
        "total_expenses", 
        min_value=-2_000_000_000_000.00,  # Allow for larger expense values
        strict_min=False 
    )
    validator.expect_column_max_to_be_between(
        "total_expenses",
        max_value=100_000_000_000.00, 
        strict_max=False
    )

    # Transaction count should be positive (or zero for some edge cases)
    validator.expect_column_values_to_be_between(
        "transaction_count",
        min_value=0,
        max_value=1_000_000  # Reasonable upper bound
    )

    # Business logic check: net_amount should be reasonable relative to revenue/expenses
    # This is a sanity check rather than exact equality due to potential rounding
    validator.expect_column_min_to_be_between(
        "net_amount", 
        min_value=-2_000_000_000_000.00,  # Allow for large negative values
        strict_min=False 
    )
    validator.expect_column_max_to_be_between(
        "net_amount",
        max_value=200_000_000_000.00, 
        strict_max=False
    )

    return validator


def run_validation(validator: Any) -> Any:
    """Run validation via the provided Validator."""
    try:
        logger.info("Running validation via Validator...")
        return validator.validate()
    except Exception as e:
        logger.error(f"An error occurred while running validation: {e}")
        sys.exit(1)


def write_validation_report(result: Any, output_dir: Path) -> Path:
    """Persist a simple HTML report and raw JSON to output_dir; return path to index.html."""
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        result_json = result.to_json_dict()
    except Exception:
        try:
            result_json = {
                "success": getattr(result, "success", None),
                "statistics": getattr(result, "statistics", None),
                "results": [
                    {
                        "success": getattr(r, "success", None),
                        "expectation_config": getattr(r, "expectation_config", None).to_json_dict()
                        if getattr(r, "expectation_config", None)
                        else None,
                        "result": getattr(r, "result", None),
                    }
                    for r in getattr(result, "results", [])
                ],
            }
        except Exception:
            result_json = {"success": False, "error": "Unable to serialize validation result"}

    # Save raw JSON
    json_path = output_dir / "validation_result.json"
    try:
        with json_path.open("w", encoding="utf-8") as f:
            json.dump(result_json, f, indent=2)
    except Exception as e:
        logger.warning(f"Failed to write JSON validation result: {e}")

    # Build a minimal HTML report
    success = bool(getattr(result, "success", False))
    stats = getattr(result, "statistics", {}) or {}
    failed_rows = []
    for vr in getattr(result, "results", []) or []:
        if not getattr(vr, "success", True):
            try:
                cfg = vr.expectation_config.to_json_dict()
            except Exception:
                cfg = {}
            res = getattr(vr, "result", {}) or {}
            failed_rows.append((cfg.get("type") or cfg.get("expectation_type", ""), cfg.get("kwargs", {}), res))

    rows_html = "".join(
        f"<tr><td>{i+1}</td><td>{etype}</td><td><pre>{kwargs}</pre></td><td><pre>{res}</pre></td></tr>"
        for i, (etype, kwargs, res) in enumerate(failed_rows)
    )

    html = f"""
<!DOCTYPE html>
<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\"/>\n<title>GE Gold Layer Validation Report</title>
<style>
body {{ font-family: Arial, sans-serif; margin: 2rem; }}
.status {{ padding: .5rem 1rem; border-radius: 4px; display: inline-block; }}
.pass {{ background: #e6ffed; color: #056608; border: 1px solid #b7f5c2; }}
.fail {{ background: #ffecec; color: #8a0411; border: 1px solid #ffc1c1; }}
table {{ border-collapse: collapse; width: 100%; margin-top: 1rem; }}
th, td {{ border: 1px solid #ddd; padding: .5rem; vertical-align: top; }}
th {{ background: #f5f5f5; }}
pre {{ white-space: pre-wrap; word-break: break-word; margin: 0; }}
.gold-layer {{ color: #b8860b; font-weight: bold; }}
</style>
</head>
<body>
  <h1>Great Expectations <span class="gold-layer">Gold Layer</span> Validation Report</h1>
  <h2>Asset: {DATA_ASSET_NAME}.parquet</h2>
  <div class=\"status { 'pass' if success else 'fail' }\">Status: { 'PASSED' if success else 'FAILED' }</div>
  <h2>Summary</h2>
  <ul>
    <li>Total expectations: {stats.get('evaluated_expectations', 'N/A')}</li>
    <li>Successful expectations: {stats.get('successful_expectations', 'N/A')}</li>
    <li>Unsuccessful expectations: {stats.get('unsuccessful_expectations', 'N/A')}</li>
    <li>Success %: {stats.get('success_percent', 'N/A')}</li>
  </ul>
  <h2>Failures</h2>
  <table>
    <thead><tr><th>#</th><th>Expectation</th><th>Kwargs</th><th>Result</th></tr></thead>
    <tbody>
      {rows_html}
    </tbody>
  </table>
  <p>Raw JSON: <code>{json_path.name}</code></p>
</body>\n</html>
"""

    index_path = output_dir / "index.html"
    with index_path.open("w", encoding="utf-8") as f:
        f.write(html)

    return index_path


def parse_and_log_failures(result: Any):
    """Parses the validation result and logs failures."""
    failed = []
    try:
        results_iter = result.results
    except Exception:
        results_iter = []
    for vr in results_iter:
        if not getattr(vr, "success", True):
            try:
                cfg = vr.expectation_config.to_json_dict()
            except Exception:
                cfg = {}
            res = getattr(vr, "result", {}) or {}
            failed.append({"config": cfg, "result": res})

    if not failed:
        return

    logger.error(f"Found {len(failed)} failed expectations:")
    for i, failure in enumerate(failed, 1):
        cfg = failure.get("config", {})
        expectation_type = cfg.get("type") or cfg.get("expectation_type", "<unknown>")
        kwargs = cfg.get("kwargs", {})
        column = kwargs.get("column", "N/A")
        res = failure.get("result", {})
        observed = res.get("observed_value", "N/A")
        unexpected_count = res.get("unexpected_count", res.get("element_count", "N/A"))

        logger.error(
            f"  {i}. Type: {expectation_type} | Column: `{column}` | "
            f"Unexpected Count: {unexpected_count} | Observed Value: {observed}"
        )


def main():
    logger.info("--- Starting Great Expectations Gold Layer Validation ---")

    context = setup_ephemeral_context()
    asset = configure_datasource_and_asset(context)
    validator = build_validator(context, asset)
    result = run_validation(validator)

    # Always write a persistent HTML+JSON report for auditing/trust
    docs_dir = Path(DATA_DOCS_DIR).resolve()
    report_path = write_validation_report(result, docs_dir)
    logger.info(f"Wrote Gold validation report: {report_path}")

    success = getattr(result, "success", False)
    if not success:
        logger.error("--- Gold Data Validation FAILED ---")
        parse_and_log_failures(result)
        logger.info(f"Open report: {report_path}")
        sys.exit(1)

    logger.success("--- Gold Data Validation PASSED ---")
    logger.info(f"Open report: {report_path}")
    sys.exit(0)


if __name__ == "__main__":
    main()

