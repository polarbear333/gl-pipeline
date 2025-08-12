import typer
from loguru import logger
from typing_extensions import Annotated

from src.config.settings import settings
from src.data.ingestion import DataIngestor

app = typer.Typer()

@app.command()
def main(
    concurrent: Annotated[bool, typer.Option(
        help="Run downloads in parallel using threads."
    )] = True,
    max_workers: Annotated[int, typer.Option(
        help="Max number of concurrent download threads."
    )] = settings.MAX_CONCURRENT_DOWNLOADS,
):
    logger.info("--- Initiating Raw Data Ingestion ---")
    try:
        ingestor = DataIngestor(settings=settings)
        
        if concurrent:
            logger.info(f"Starting concurrent download with up to {max_workers} workers.")
            ingestor.run(max_concurrent_downloads=max_workers)
        else:
            logger.info("Starting sequential download.")
            ingestor.run(max_concurrent_downloads=1)
            
        logger.info("--- Raw Data Ingestion Complete ---")
    except Exception as e:
        logger.error(f"An unhandled error occurred during ingestion: {e}")
        raise typer.Exit(code=1)

if __name__ == "__main__":
    app()