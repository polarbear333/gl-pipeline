import boto3
from botocore.client import Config
from botocore.exceptions import ClientError
from pathlib import Path
from loguru import logger

from src.config.settings import Settings

class StorageClient:
    def __init__(self, settings: Settings):
        logger.info("Initializing StorageClient...")
        try:
            self.client = boto3.client(
                "s3",
                endpoint_url=settings.R2_ENDPOINT_URL,
                aws_access_key_id=settings.R2_ACCESS_KEY_ID,
                aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
                config=Config(s3={'addressing_style': 'path'}),
                region_name="auto",
            )
            self.bucket_name = settings.R2_BUCKET_NAME
            logger.success("StorageClient initialized successfully.")
        except Exception as e:
            logger.error(f"Failed to initialize Boto3 client: {e}")
            raise

    def upload_file(self, local_path: Path, remote_key: str) -> bool:
        logger.info(f"Uploading '{local_path}' to '{self.bucket_name}/{remote_key}'...")
        try:
            self.client.upload_file(str(local_path), self.bucket_name, remote_key)
            logger.success("Upload successful.")
            return True
        except ClientError as e:
            logger.error(f"Failed to upload file: {e}")
            return False

    def file_exists(self, remote_key: str) -> bool:
        try:
            self.client.head_object(Bucket=self.bucket_name, Key=remote_key)
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                return False
            else:
                logger.error(f"Error checking file existence: {e}")
                raise