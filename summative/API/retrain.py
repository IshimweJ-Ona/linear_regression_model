"""Retraining module and FastAPI router for the SkillBridge youth earnings model."""

from dataclasses import dataclass, field
from pathlib import Path
from threading import Lock
from typing import Any
import io

import joblib
import pandas as pd
from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

NUMERIC_BOUNDS = {
    "age": (18, 35),
    "years_schooling": (0, 22),
    "experience_years": (0, 25),
    "weekly_hours": (1.0, 100.0),
    "household_size": (1, 25),
}
NUMERIC_COLUMNS = list(NUMERIC_BOUNDS.keys())
CATEGORICAL_COLUMNS = [
    "sex",
    "province",
    "urban_rural",
    "education_track",
    "internet_use",
    "sector",
    "occupation_group",
    "contract_basis",
]
FEATURE_COLUMNS = NUMERIC_COLUMNS + CATEGORICAL_COLUMNS
TARGET_COLUMN = "monthly_income_k_rwf"
REQUIRED_CSV_COLUMNS = FEATURE_COLUMNS + [TARGET_COLUMN]


@dataclass
class ModelStore:
    """Thread-safe holder for the live prediction pipeline and training dataset."""

    model_path: Path
    active_model: Any
    training_df: pd.DataFrame | None
    model_version: str = "1.0.0"
    lock: Lock = field(default_factory=Lock)


class RetrainResponse(BaseModel):
    """Structured JSON summary returned after CSV retraining."""

    message: str
    original_rows: int
    new_rows_added: int
    total_rows_used: int
    validation_test_mse: float | None
    validation_test_r2: float | None
    model_version: str


def build_pipeline() -> Pipeline:
    """Build the same preprocessing + RandomForestRegressor pipeline used in the notebook."""
    preprocessor = ColumnTransformer([
        ("num", Pipeline([("imputer", SimpleImputer(strategy="median")), ("scaler", StandardScaler())]), NUMERIC_COLUMNS),
        ("cat", Pipeline([("imputer", SimpleImputer(strategy="most_frequent")), ("ohe", OneHotEncoder(handle_unknown="ignore", sparse_output=False))]), CATEGORICAL_COLUMNS),
    ])
    return Pipeline([
        ("preprocessor", preprocessor),
        ("model", RandomForestRegressor(n_estimators=200, max_depth=12, min_samples_leaf=5, random_state=42, n_jobs=1)),
    ])


def parse_and_validate_csv(file: UploadFile) -> pd.DataFrame:
    """Read an uploaded CSV and verify schema, complete rows, and realistic numeric ranges."""
    if not file.filename or not file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a valid .csv file.")

    try:
        new_df = pd.read_csv(io.BytesIO(file.file.read()))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Could not parse CSV file: {exc}") from exc

    missing_cols = [col for col in REQUIRED_CSV_COLUMNS if col not in new_df.columns]
    if missing_cols:
        raise HTTPException(status_code=422, detail=f"CSV is missing required columns: {missing_cols}")

    cleaned = new_df[REQUIRED_CSV_COLUMNS].copy()
    for col in NUMERIC_COLUMNS + [TARGET_COLUMN]:
        cleaned[col] = pd.to_numeric(cleaned[col], errors="coerce")
    cleaned = cleaned.dropna().reset_index(drop=True)

    if cleaned.empty:
        raise HTTPException(status_code=422, detail="Uploaded CSV contains no valid complete rows.")

    in_range = cleaned[TARGET_COLUMN].gt(0) & cleaned[TARGET_COLUMN].le(500)
    for col, (low, high) in NUMERIC_BOUNDS.items():
        in_range &= cleaned[col].between(low, high)

    if not in_range.all():
        raise HTTPException(status_code=422, detail="Uploaded CSV contains out-of-range numeric values.")

    return cleaned


def retrain_model(store: ModelStore, new_df: pd.DataFrame) -> RetrainResponse:
    """Refit the RandomForest pipeline on baseline + new rows and activate it atomically."""
    with store.lock:
        base_rows = len(store.training_df) if store.training_df is not None else 0
        combined_df = pd.concat([store.training_df, new_df], ignore_index=True) if store.training_df is not None else new_df

        X_all, y_all = combined_df[FEATURE_COLUMNS], combined_df[TARGET_COLUMN]
        val_mse, val_r2 = None, None
        if len(combined_df) >= 20:
            X_tr, X_te, y_tr, y_te = train_test_split(X_all, y_all, test_size=0.2, random_state=42)
            eval_pipe = build_pipeline()
            eval_pipe.fit(X_tr, y_tr)
            y_pred = eval_pipe.predict(X_te)
            val_mse = round(float(mean_squared_error(y_te, y_pred)), 2)
            val_r2 = round(float(r2_score(y_te, y_pred)), 4)

        updated_pipeline = build_pipeline()
        updated_pipeline.fit(X_all, y_all)
        joblib.dump(updated_pipeline, store.model_path)

        store.active_model = updated_pipeline
        store.training_df = combined_df
        store.model_version = f"retrained (+{len(new_df)} rows, total={len(combined_df)})"
        new_version = store.model_version

    return RetrainResponse(
        message="Model retrained successfully and is now active for /predict.",
        original_rows=base_rows,
        new_rows_added=len(new_df),
        total_rows_used=len(combined_df),
        validation_test_mse=val_mse,
        validation_test_r2=val_r2,
        model_version=new_version,
    )


def create_retrain_router(store: ModelStore) -> APIRouter:
    """Create the FastAPI router exposing the POST /retrain CSV upload endpoint."""
    router = APIRouter()

    @router.post("/retrain", response_model=RetrainResponse, tags=["Retraining"])
    def retrain(file: UploadFile = File(..., description="CSV with the 13 feature columns plus monthly_income_k_rwf")):
        """Upload new labeled youth worker rows (.csv), refit RandomForest on original + new data, and activate it."""
        new_df = parse_and_validate_csv(file)
        return retrain_model(store, new_df)

    return router
