import requests
import hashlib
import json
from pathlib import Path
from datetime import datetime, timezone
from loguru import logger
from src.config.settings import Settings
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Dict, Any
from tqdm import tqdm

class DataIngestor:
    """
    Handles the concurrent download and validation of multiple raw data files.
    """
    def __init__(self, settings: Settings):
        self.settings = settings

    def _calculate_sha256(self, file_path: Path) -> str:
        """Calculates the SHA256 checksum of a file."""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()

    def _validate_existing_file(self, local_path: Path, metadata_path: Path) -> bool:
        """Validates an existing file against its metadata. Returns True if valid and should be skipped."""
        if not local_path.exists() or not metadata_path.exists():
            return False
        
        try:
            with open(metadata_path, 'r') as f:
                metadata = json.load(f)
            
            if local_path.stat().st_size != metadata.get('file_size_bytes'):
                logger.warning(f"Size mismatch for {local_path.name}. Re-downloading.")
                return False
            
            if self._calculate_sha256(local_path) == metadata.get('sha256_checksum'):
                return True 
            else:
                logger.warning(f"Checksum mismatch for {local_path.name}. Re-downloading.")
                return False
                
        except Exception as e:
            logger.warning(f"Could not validate {local_path.name}, re-downloading: {e}")
            return False

    def _download_and_process_file(self, data_file: Dict[str, Any], pbar: tqdm) -> Dict[str, Any]:
        """
        Worker function: downloads, creates metadata, and handles errors for a single file.
        This single method replaces the need for _download_with_progress and _create_metadata.
        """
        url = data_file["url"]
        filename = data_file["filename"]
        local_path = self.settings.RAW_DATA_DIR / filename
        metadata_path = self.settings.RAW_DATA_DIR / f"{filename}.metadata.json"
        
        result = {"filename": filename, "success": False, "skipped": False}
        
        try:
            if self._validate_existing_file(local_path, metadata_path):
                result["skipped"] = True
                result["success"] = True
                return result

            response = requests.get(url, stream=True, timeout=(30, 300), headers={'User-Agent': 'DataIngestor/1.0'})
            response.raise_for_status()

            with open(local_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            
            checksum = self._calculate_sha256(local_path)
            metadata = {
                "source_url": url,
                "filename": filename,
                "download_timestamp_utc": datetime.now(timezone.utc).isoformat(),
                "sha256_checksum": checksum,
                "file_size_bytes": local_path.stat().st_size,
            }
            with open(metadata_path, "w") as f:
                json.dump(metadata, f, indent=4)
            
            result["success"] = True
        except Exception as e:
            logger.error(f"Failed processing {filename}: {e}")
            if local_path.exists():
                local_path.unlink(missing_ok=True)
        finally:
            pbar.update(1)
            return result


    def run(self, max_concurrent_downloads: int = 5) -> None:
        """Runs the ingestion process with concurrent downloads and a tqdm progress bar."""
        logger.info("Starting data ingestion process...")
        self.settings.RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)
        
        files_to_process = self.settings.DATA_FILES
        total_files = len(files_to_process)
        
        results = []
        with tqdm(total=total_files, desc="Downloading Raw Data", unit="file") as pbar:
            with ThreadPoolExecutor(max_workers=max_concurrent_downloads) as executor:
                future_to_file = {
                    executor.submit(self._download_and_process_file, data_file, pbar): data_file
                    for data_file in files_to_process
                }
                
                for future in as_completed(future_to_file):
                    results.append(future.result())

        successful = sum(1 for r in results if r["success"] and not r["skipped"])
        skipped = sum(1 for r in results if r["skipped"])
        failed = total_files - successful - skipped
        
        logger.info(f"Ingestion finished. Successful: {successful}, Skipped: {skipped}, Failed: {failed}")
        if failed > 0:
            failed_files = [r["filename"] for r in results if not r["success"] and not r["skipped"]]
            logger.warning(f"Failed to download: {', '.join(failed_files)}")