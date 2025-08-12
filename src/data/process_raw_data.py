import pandas as pd
import typer
from loguru import logger
from typing_extensions import Annotated

from src.config.settings import settings

app = typer.Typer()

@app.command()
def main(
    output_format: Annotated[str, typer.Option(help="Output format: 'parquet' or 'csv'")] = "parquet"
):
    logger.info("--- Initiating Raw Data Processing and Merging ---")
    
    raw_files = list(settings.RAW_DATA_DIR.glob("*.csv"))
    if not raw_files:
        logger.error("No raw CSV files found to process. Did the 'ingest' stage run?")
        raise typer.Exit(code=1)

    logger.info(f"Found {len(raw_files)} CSV files to merge.")
    
    df_list = []
    for file in raw_files:
        try:
            # Assuming all CSVs have a similar structure.
            # `low_memory=False` is often needed for mixed-type columns in large CSVs.
            df = pd.read_csv(file, low_memory=False)
            df_list.append(df)
        except Exception as e:
            logger.error(f"Could not read {file}: {e}")
            continue

    if not df_list:
        logger.error("No dataframes were successfully loaded. Aborting.")
        raise typer.Exit(code=1)

    full_df = pd.concat(df_list, ignore_index=True)
    logger.success(f"Successfully merged all files. Total rows: {len(full_df)}")

    # --- This is where future cleaning/transformation would go ---
    # Example: full_df['Amount'] = pd.to_numeric(full_df['Amount'])
    # Example: full_df['Date'] = pd.to_datetime(full_df['Date'])
    # -----------------------------------------------------------

    settings.PROCESSED_DATA_DIR.mkdir(parents=True, exist_ok=True)
    if output_format == "parquet":
        output_path = settings.PROCESSED_DATA_DIR / settings.PROCESSED_DATA_FILE
        full_df.to_parquet(output_path, index=False)
    else:
        output_path = (settings.PROCESSED_DATA_DIR / settings.PROCESSED_DATA_FILE).with_suffix(".csv")
        full_df.to_csv(output_path, index=False)

    logger.success(f"Saved processed data to '{output_path}'.")
    logger.info("--- Raw Data Processing Complete ---")

if __name__ == "__main__":
    app()