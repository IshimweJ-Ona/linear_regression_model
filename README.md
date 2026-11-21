# SkillBridge — Youth Monthly Cash Earnings Prediction

## 1. Mission & Problem
SkillBridge addresses Rwanda's youth skills-to-employment gap by validating practical degree and TVET skills and matching verified youth talent (ages 18–35) to fair-paying jobs.
Because young job seekers often lack transparent wage benchmarks and risk accepting underpaying informal offers, this project predicts expected monthly cash earnings (`monthly_income_k_rwf`) from a worker's education, TVET track, experience, sector, occupation, and contract type.
Youth job seekers, SkillBridge career advisors, and employers use these predictions to benchmark fair monthly compensation and see the earnings impact of TVET credentials, digital access, and formal written contracts.

## 2. Dataset Description & Source
- **Dataset:** Rwanda Labour Force Survey 2022 (`RW_LFS2022.dta`), published by the **National Institute of Statistics of Rwanda (NISR)**.
- **Source Link:** [NISR Rwanda Labour Force Survey 2022 (Microdata Catalog #104)](https://microdata.statistics.gov.rw/index.php/catalog/104)
- **Scope & Features:** From `70,424` raw survey records (`239` columns), the data is filtered to `7,231` employed youth aged `18–35` earning `1–500k RWF/month` (capping the top ~1.1% extreme outliers above `500,000 RWF`). Each record includes **13 input features** — `5` numeric (`age`, `years_schooling`, `experience_years`, `weekly_hours`, `household_size`) and `8` categorical (`sex`, `province`, `urban_rural`, `education_track`, `internet_use`, `sector`, `occupation_group`, `contract_basis`) — and the continuous target `monthly_income_k_rwf`.

## 3. Public API & Swagger UI
- **Swagger UI (Interactive API Docs):** [https://skillbridge-earnings-api.onrender.com/docs](https://skillbridge-earnings-api.onrender.com/docs)
- **Base API URL:** `https://skillbridge-earnings-api.onrender.com`
- **Available Endpoints:**
  - `GET /` — Health check and active `model_version`
  - `POST /predict` — Validates the 13 worker inputs with Pydantic and returns predicted monthly earnings in `k RWF` and `RWF`
  - `POST /retrain` — Accepts an uploaded `.csv` file with the 14 schema columns, merges it with `training_data.csv`, refits the `RandomForestRegressor` pipeline, and immediately serves the updated model

> **Note:** Render's free tier spins down after 15 minutes of inactivity and may take up to ~60 seconds to wake up on the first request. Open `/docs` or `/` shortly before testing.

## 4. Video Demo
- **YouTube Demo Link:** `[Add your YouTube video demo link here before submitting](https://youtu.be/YOUR_VIDEO_ID)`

## 5. Step-by-Step Instructions to Run the Mobile App

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.13.7`)
- Android Studio with an Android Emulator (or a physical Android/iOS device with USB debugging enabled; iOS requires macOS + Xcode)
- Active internet connection on the emulator/device so the app can reach the Render API

### Setup & Run Steps
1. **Clone the repository:**
   ```bash
   git clone https://github.com/IshimweJ-Ona/linear_regression_model.git
   cd linear_regression_model
   ```

2. **Navigate to the Flutter app directory:**
   ```bash
   cd summative/FlutterApp
   ```

3. **Install Dart/Flutter packages:**
   ```bash
   flutter pub get
   ```

4. **Verify the API base URL (optional):**
   Open `lib/services/earnings_api_service.dart` and confirm `kApiBaseUrl` points to your live Render service (no trailing slash):
   ```dart
   const String kApiBaseUrl = 'https://skillbridge-earnings-api.onrender.com';
   ```

5. **Confirm an Android/iOS emulator or physical mobile device is connected:**
   ```bash
   flutter devices
   ```
   *(If no emulator is running, launch one via Android Studio Device Manager or `flutter emulators --launch <emulator_id>`.)*

6. **Run the mobile app (not web):**
   ```bash
   flutter run
   ```
   To target a specific device from `flutter devices`:
   ```bash
   flutter run -d <device_id>
   ```

7. **Run automated widget & validation tests (optional):**
   ```bash
   flutter test
   ```

---

## Local Backend & Notebook Setup (For Facilitator / Local Testing)

### Run the FastAPI Service Locally (with `uv`)
1. Navigate to `summative/API/`:
   ```bash
   cd summative/API
   uv sync
   ```
2. Start the FastAPI server:
   ```bash
   uv run uvicorn prediction:app --host 0.0.0.0 --port 8000 --reload
   ```
3. Open `http://127.0.0.1:8000/docs` in your browser to test `/predict` and `/retrain`.

*(Render deployment settings: Root Directory = `summative/API`, Build Command = `pip install -r requirements.txt`, Start Command = `uvicorn prediction:app --host 0.0.0.0 --port $PORT`.)*

### Run the Notebook
1. From `summative/`, launch JupyterLab:
   ```bash
   uv run jupyter lab linear_regression/multivariate.ipynb
   ```
2. Run all cells from top to bottom. The notebook reads `linear_regression/data/RW_LFS2022.dta` and saves `best_model.pkl` and `training_data.csv` into `summative/API/`.
