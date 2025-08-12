import dvc.api
import pandas as pd
import mlflow
import typer
from loguru import logger
from ydata_profiling import ProfileReport

from src.config.settings import settings

app = typer.Typer()

@app.command()
def main(
    profile_title: str = "Processed General Ledger Data Profile",
    output_file: str = "processed_data_profile.html"
):
    """
    Profiles the processed and merged data and logs the report to MLflow.
    """
    logger.info("--- Initiating Processed Data Profiling ---")
    mlflow.set_tracking_uri(settings.MLFLOW_TRACKING_URI)
    mlflow.set_experiment(settings.MLFLOW_EXPERIMENT_NAME)

    with mlflow.start_run(run_name="Processed Data Profiling") as run:
        processed_path = settings.PROCESSED_DATA_DIR / settings.PROCESSED_DATA_FILE
        logger.info(f"MLflow run started (ID: {run.info.run_id}).")
        mlflow.log_param("data_path", str(processed_path))

        try:
            logger.info(f"Loading processed data from: {processed_path}")
            df = pd.read_parquet(processed_path)
            
            mlflow.log_metric("num_rows_processed", df.shape[0])
            mlflow.log_metric("num_cols_processed", df.shape[1])

            logger.info("Generating data profile with ydata-profiling...")
            profile = ProfileReport(df, title=profile_title, minimal=True) 
            profile.to_file(output_file)
            logger.success(f"Profile report saved to '{output_file}'.")

            mlflow.log_artifact(output_file)
            logger.info(f"Logged '{output_file}' as an artifact to MLflow.")

        except Exception as e:
            logger.error(f"An error occurred during profiling: {e}")
            mlflow.set_tag("status", "failed")
            raise typer.Exit(code=1)
        
        mlflow.set_tag("status", "success")
        logger.info("--- Processed Data Profiling Complete ---")

if __name__ == "__main__":
    app()