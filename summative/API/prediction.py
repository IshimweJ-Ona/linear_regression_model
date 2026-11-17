"""FastAPI service for SkillBridge youth monthly cash earnings predictions."""

from pathlib import Path
from threading import Lock
from typing import Annotated, Literal
import io
import os

import joblib
import pandas as pd
from fastapi import Body, FastAPI, File, HTTPException, Request, UploadFile
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, field_validator
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

# Resolve model and baseline dataset paths relative to summative/API.
BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "best_model.pkl"
TRAINING_DATA_PATH = BASE_DIR / "training_data.csv"

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

# Prevent race conditions when /retrain swaps active_model during /predict requests.
model_lock = Lock()
active_model = joblib.load(MODEL_PATH)
# Keep single-row inference single-threaded to avoid process-spawning overhead on Render.
if hasattr(active_model.named_steps.get("model"), "n_jobs"):
    active_model.named_steps["model"].n_jobs = 1

training_df = pd.read_csv(TRAINING_DATA_PATH) if TRAINING_DATA_PATH.is_file() else None
model_version = "1.0.0"


def predict_monthly_income(row_df: pd.DataFrame, model=None) -> float:
    """Load the saved pipeline (or reuse active in-memory pipeline) to predict one row."""
    estimator = model if model is not None else joblib.load(MODEL_PATH)
    return float(estimator.predict(row_df)[0])


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


class YouthEarningsInput(BaseModel):
    """JSON input schema enforcing data types, ranges, and valid categories."""

    age: int = Field(..., ge=NUMERIC_BOUNDS["age"][0], le=NUMERIC_BOUNDS["age"][1], description="Worker age in years (18-35)")
    years_schooling: int = Field(..., ge=NUMERIC_BOUNDS["years_schooling"][0], le=NUMERIC_BOUNDS["years_schooling"][1], description="Completed years of schooling (0-22)")
    experience_years: int = Field(..., ge=NUMERIC_BOUNDS["experience_years"][0], le=NUMERIC_BOUNDS["experience_years"][1], description="Total work experience in years (0-25)")
    weekly_hours: Annotated[float, Field(ge=NUMERIC_BOUNDS["weekly_hours"][0], le=NUMERIC_BOUNDS["weekly_hours"][1], allow_inf_nan=False, description="Usual weekly working hours (1-100)")]
    household_size: int = Field(..., ge=NUMERIC_BOUNDS["household_size"][0], le=NUMERIC_BOUNDS["household_size"][1], description="Household size in persons (1-25)")

    sex: Literal["Male", "Female"]
    province: Literal["Kigali city", "Northern Province", "Southern Province", "Eastern Province", "Western Province"]
    urban_rural: Literal["Urban", "Rural"]
    education_track: Literal["No level completed", "Completed general", "Completed TVET"]
    internet_use: Literal["Yes", "No"]
    sector: Literal["Agriculture", "Industry", "Services"]
    occupation_group: Literal[
        "Managers",
        "Professionals",
        "Technicians and associate professionals",
        "Clerical support workers",
        "Service and sales workers",
        "Skilled agricultural, forestry and fishery workers",
        "Craft and related trades workers",
        "Plant and machine operators and assemblers",
        "Elementary occupations",
    ]
    contract_basis: Literal["Written contract", "Oral agreement"]

    @field_validator(*NUMERIC_COLUMNS, mode="before")
    @classmethod
    def reject_string_or_bool_for_numbers(cls, value):
        """Prevent Pydantic lax coercion of strings or booleans into numbers."""
        if isinstance(value, (bool, str)):
            raise ValueError("Must be a JSON number, not a string or boolean.")
        return value


class PredictionResponse(BaseModel):
    """Structured JSON prediction output for Flutter and Swagger UI."""

    predicted_monthly_income_k_rwf: float
    predicted_monthly_income_rwf: int
    currency: str
    model_version: str


class RetrainResponse(BaseModel):
    """Structured JSON summary returned after CSV retraining."""

    message: str
    original_rows: int
    new_rows_added: int
    total_rows_used: int
    validation_test_mse: float | None
    validation_test_r2: float | None
    model_version: str


class HealthResponse(BaseModel):
    status: str
    model_version: str
    docs_url: str


SWAGGER_PREDICT_EXAMPLES = {
    "valid_tvet_worker": {
        "summary": "Valid input (Kigali TVET technician)",
        "value": {
            "age": 25,
            "years_schooling": 16,
            "experience_years": 3,
            "weekly_hours": 45.0,
            "household_size": 3,
            "sex": "Male",
            "province": "Kigali city",
            "urban_rural": "Urban",
            "education_track": "Completed TVET",
            "internet_use": "Yes",
            "sector": "Services",
            "occupation_group": "Technicians and associate professionals",
            "contract_basis": "Written contract",
        },
    },
    "wrong_type_age": {
        "summary": "Invalid test: wrong data type (age as text)",
        "value": {
            "age": "twenty-five",
            "years_schooling": 12,
            "experience_years": 2,
            "weekly_hours": 40.0,
            "household_size": 4,
            "sex": "Female",
            "province": "Kigali city",
            "urban_rural": "Urban",
            "education_track": "Completed general",
            "internet_use": "Yes",
            "sector": "Services",
            "occupation_group": "Service and sales workers",
            "contract_basis": "Written contract",
        },
    },
    "out_of_range_age": {
        "summary": "Invalid test: out-of-range age (age=15)",
        "value": {
            "age": 15,
            "years_schooling": 9,
            "experience_years": 1,
            "weekly_hours": 40.0,
            "household_size": 4,
            "sex": "Male",
            "province": "Eastern Province",
            "urban_rural": "Rural",
            "education_track": "Completed general",
            "internet_use": "No",
            "sector": "Agriculture",
            "occupation_group": "Elementary occupations",
            "contract_basis": "Oral agreement",
        },
    },
}

app = FastAPI(
    title="SkillBridge Youth Monthly Earnings API",
    description=(
        "Predicts expected monthly cash earnings (in thousands of RWF and RWF) for Rwandan youth "
        "aged 18-35 using a RandomForestRegressor pipeline trained on the NISR Rwanda Labour Force Survey 2022."
    ),
    version="1.0.0",
)

# Explicit CORS policy (no '*' wildcard on origins, methods, or headers):
# - Allowed: Known browser origins (Render URL + local debug servers), credentials, GET/POST/OPTIONS,
#   and standard JSON/authorization headers.
# - Restricted: Untrusted third-party websites cannot make credentialed cross-origin requests, and
#   unused methods (PUT, DELETE, PATCH) are blocked.
# - Why: Browsers enforce CORS to prevent unauthorized websites from calling this API, while native
#   Flutter mobile apps (Android/iOS) are not browsers and are unaffected by CORS.

allowed_origins = [
    "https://skillbridge-earnings-api.onrender.com",
    "http://localhost:3000",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
]
render_url = os.getenv("RENDER_EXTERNAL_URL")
if render_url and render_url.rstrip("/") not in allowed_origins:
    allowed_origins.append(render_url.rstrip("/"))

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Accept", "Authorization"],
)


@app.exception_handler(RequestValidationError)
def validation_exception_handler(_request: Request, exc: RequestValidationError):
    """Return a clean JSON error message alongside detailed field validation errors."""
    messages = [
        f"{'.'.join(str(part) for part in err['loc'] if part != 'body')}: {err['msg']}"
        for err in exc.errors()
    ]
    return JSONResponse(
        status_code=422,
        content={
            "error": "Validation Error",
            "message": "; ".join(messages),
            "detail": jsonable_encoder(exc.errors()),
        },
    )


@app.get("/", response_model=HealthResponse, tags=["Health"])
def health_check():
    """Verify the service is awake and show the currently active model version."""
    return HealthResponse(status="ok", model_version=model_version, docs_url="/docs")


@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
def predict(payload: Annotated[YouthEarningsInput, Body(openapi_examples=SWAGGER_PREDICT_EXAMPLES)]):
    """Validate input JSON and return predicted monthly cash earnings in k RWF and RWF."""
    row_df = pd.DataFrame([payload.model_dump()], columns=FEATURE_COLUMNS)
    with model_lock:
        pred_k = predict_monthly_income(row_df, model=active_model)
        current_version = model_version

    return PredictionResponse(
        predicted_monthly_income_k_rwf=round(pred_k, 2),
        predicted_monthly_income_rwf=int(round(pred_k * 1000)),
        currency="RWF",
        model_version=current_version,
    )


@app.post("/retrain", response_model=RetrainResponse, tags=["Retraining"])
def retrain(file: UploadFile = File(..., description="CSV with the 13 feature columns plus monthly_income_k_rwf")):
    """Upload new labeled youth worker rows (.csv), refit RandomForest on original + new data, and activate it."""
    global active_model, training_df, model_version

    new_df = parse_and_validate_csv(file)

    with model_lock:
        base_rows = len(training_df) if training_df is not None else 0
        combined_df = pd.concat([training_df, new_df], ignore_index=True) if training_df is not None else new_df

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
        joblib.dump(updated_pipeline, MODEL_PATH)

        active_model = updated_pipeline
        training_df = combined_df
        model_version = f"retrained (+{len(new_df)} rows, total={len(combined_df)})"

    return RetrainResponse(
        message="Model retrained successfully and is now active for /predict.",
        original_rows=base_rows,
        new_rows_added=len(new_df),
        total_rows_used=len(combined_df),
        validation_test_mse=val_mse,
        validation_test_r2=val_r2,
        model_version=model_version,
    )