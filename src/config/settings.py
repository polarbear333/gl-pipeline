import os
from pathlib import Path
from typing import List, Dict
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROCESSED_DATA_DIR: Path = Path("data/processed") 
    PROCESSED_DATA_FILE: str = "general_ledger.parquet" 
    RAW_DATA_DIR: Path = Path("data/raw")
    DATA_FILES: List[Dict[str, str]] = [
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/6fe771bd-a705-4fce-b12f-d0a041ac5581/download/ledger_fy22_qtr1.csv",
            "filename": "ledger_fy22_qtr1.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/a1434f0b-9f3d-4726-b5a3-cef6ce61f7c9/download/ledger_fy22_qtr2.csv",
            "filename": "ledger_fy22_qtr2.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/c3e91ddc-70a4-4da5-ac39-50ab7a63ed01/download/ledger_fy22_qtr3.csv",
            "filename": "ledger_fy22_qtr3.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/9bbced1c-285b-4060-baa6-93d77159d03e/download/ledger_fy22_qtr4.csv",
            "filename": "ledger_fy22_qtr4.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/85c77eec-842b-4a3c-b6dd-176c9b296a0f/download/ledger_fy23_qtr1.csv",
            "filename": "ledger_fy23_qtr1.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/dc0f53a9-4b1e-4848-87b9-2f06cd6fc627/download/ledger_fy23_qtr2.csv",
            "filename": "ledger_fy23_qtr2.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/8d8a2b2f-7141-4b9f-8661-8ddba9d9a29a/download/ledger_fy23_qtr3.csv",
            "filename": "ledger_fy23_qtr3.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/553fa5c5-3143-4c54-83a2-cf36d02b7e67/download/ledger_fy23_qtr4.csv",
            "filename": "ledger_fy23_qtr4.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/2aa3deaa-859d-46ee-baa4-c2ef94a83ac5/download/ledger_fy24_qtr1.csv",
            "filename": "ledger_fy24_qtr1.csv"
        },

        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/90e09488-4a3d-4b33-b8e6-85c6358f28ac/download/ledger_fy24_qtr2.csv",
            "filename": "ledger_fy24_qtr2.csv"
        },

        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/5f09e519-28d7-4d1a-bf99-c55966b78b19/download/ledger_fy24_qtr3.csv",
            "filename": "ledger_fy24_qtr3.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/0c2a7e42-610e-4f1d-826f-f6b267fba68a/download/ledger_fy24_qtr4.csv",
            "filename": "ledger_fy24_qtr4.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/a8fa19ca-8265-41bf-a1f9-59c8993d72f8/download/ledger_fy25_qtr1.csv",
            "filename": "ledger_fy25_qtr1.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/b1b031e1-d26d-4f1f-8892-4fcec01031dc/download/ledger_fy25_qtr2.csv",
            "filename": "ledger_fy25_qtr2.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/67e2656c-acfe-431d-8667-ad8b24180ce5/download/ledger_fy25_qtr3.csv",
            "filename": "ledger_fy25_qtr3.csv"
        },
        {
            "url": "https://data.ok.gov/dataset/dd1ecf41-4abc-4886-ab0f-b84d7662d8d4/resource/72038a7c-ad10-4d67-82cd-4f26920727e1/download/ledger_fy25_qtr4.csv",
            "filename": "ledger_fy25_qtr4.csv"
        }
    ]

    CLOUDFLARE_R2_ACCESS_KEY_ID: str
    CLOUDFLARE_R2_ACCESS_KEY_ID: str
    CLOUDFLARE_R2_SECRET_ACCESS_KEY: str
    CLOUDFLARE_R2_BUCKET_NAME: str

    MLFLOW_TRACKING_URI: str = "http://127.0.0.1:5000"
    MLFLOW_EXPERIMENT_NAME: str = "Financial Monitoring System"

    MAX_CONCURRENT_DOWNLOADS: int = 5
    
    #pydantic model configuration
    model_config = SettingsConfigDict(
        env_file=".env", 
        env_file_encoding='utf-8', 
        extra='ignore'
    )
settings = Settings()