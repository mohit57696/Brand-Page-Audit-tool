# Audit Tool

Product specification auditing with a React dashboard and Python backend.
Each specification is checked only against its own Excel row's column H source URL.
Missing or unusable source evidence is marked for review.

This repository contains source code and deployment configuration. Hosting is not
configured. API keys, private spreadsheets, audit history, and caches are excluded.

## Run locally on Windows

1. Install Python 3.14 and Node.js 22 LTS.
2. Clone or download and extract this repository, then double-click `Setup.bat`.
3. Copy `centralized_data.xlsx`, `mcat_data.zip`, and `mcat_specifications.xlsx`
   from the separate colleague handoff ZIP into `input/`.
4. Configure your own API key in `backend/.env`.
5. Double-click `start.bat` and open http://localhost:8000.

`Setup.bat` installs Python dependencies and builds the dashboard. Keep the server
window open while using the app. The numeric identifier is in the Variant ID column;
the SID column contains product codes. Save Excel changes and rescan in the app.

## Deployment and validation

See [PRODUCTION.md](PRODUCTION.md) for Docker, login, input files, and persistent
storage. GitHub Actions builds the dashboard and container and runs the offline
audit and access-control tests. The production container requires login credentials.

---

# Local Specification Audit Dashboard

An autonomous, local **Product Specification Audit & Quality Assurance System** built for Windows.

The dashboard inspects final technical product specifications against manufacturer
datasheets/PDFs and official Product Detail Pages (PDP) using a two-stage,
evidence-backed audit with **Google Gemini Multimodal AI**, **PyMuPDF**, and **SQLite**.

## Evidence-backed audit architecture

The audit no longer asks one model response to both extract and judge the source.

1. **Source extraction:** Gemini builds an exact-model fact ledger with verbatim
   quotations, PDF page numbers, full ranges/options/qualifiers, and variant scope.
2. **Deterministic source validation:** the backend checks every quotation against
   the supplied PDF page text or PDP extraction and stops on ambiguous model matching.
3. **Final mapping audit:** a second Gemini pass compares the immutable final
   specification list only with the validated fact ledger.
4. **Deterministic result validation:** the backend rejects changed input values,
   count/order/sequence/tier changes, unknown evidence IDs, unsupported categories,
   missing corrections, and inconsistent verdict/severity combinations. Counts and
   Pass/Fail status are recalculated by the backend.

Canonical categories are: Missing or recall error; Wrong or precision error;
Partial capture; Wrong mapping; Formatting or unit error; Duplicate error;
Unsupported or cross-model value; and Wrong specification-question error.

---

## Key Principles & Design
- **No Upload Buttons on Frontend**: The Excel file and MCAT data are read directly from the project filesystem (`input/`). The dashboard automatically scans and indexes them on startup.
- **Single or Batch SID Workflow**: Enter one SID or a comma-separated list (for example, `465702, 465747`). The backend resolves each SID and runs valid SIDs sequentially.
- **No Pre-Audit Results**: Verdicts (**Correct / Incorrect**), Dispositions, Severities, and Remarks are **never guessed or displayed before the LLM executes**.
- **12-Point Strict JSON Validation**: The backend enforces that the LLM response preserves the exact count and sequence of specifications without adding, removing, or reordering any items.
- **SQLite History & Excel Export**: Every completed audit is persisted in SQLite with full JSON. A batch can be exported as one workbook with a summary and one 19-column detail sheet per completed SID.

---

## 1. Project Directory Structure

```
Audit project/
├── input/
│   ├── centralized_data.xlsx    # Place your main catalog spreadsheet here
│   └── mcat_data.zip            # Place your MCAT ZIP archive here
│
├── data/
│   ├── extracted_mcat/          # Auto-extracted MCAT data
│   ├── downloaded_pdfs/         # Deterministically cached PDF downloads
│   ├── audit_outputs/           # Saved raw responses & validation logs
│   └── database/
│       └── audit_history.db     # SQLite database for audit history
│
├── config/
│   ├── audit_prompt.txt         # Dynamically reloaded LLM audit rules & instructions
│   └── column_mapping.json      # Flexible Excel column aliases
│
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI application entry point & SPA hosting
│   │   ├── config.py            # Paths and environment variable loading
│   │   ├── api/                 # System, Variant, Audit, and History API endpoints
│   │   ├── services/            # Excel, ZIP, MCAT, PDF, PDP, LLM, DB, and Audit services
│   │   ├── schemas/             # Pydantic data models
│   │   └── utils/               # 12-point validator and 18-column Excel exporter
│   ├── .env                     # Your local Gemini API key (never committed)
│   ├── .env.example             # Template environment file
│   ├── requirements.txt         # Python dependencies
│   └── run.py                   # Backend server runner
│
├── frontend/                    # React 18 + TypeScript + Vite Dashboard
│   ├── src/                     # UI components, timeline modal, detail panel, tabs
│   ├── package.json             # NPM dependencies
│   └── dist/                    # Pre-built production dashboard
│
├── scripts/
│   ├── generate_sample_data.py  # Populates test Excel, test ZIP, and sample PDF
│   └── test_backend.py          # Automated backend integration test suite
│
├── run_backend.bat              # One-click Windows launcher for Backend
├── run_frontend.bat             # One-click Windows launcher for Frontend Dev Server
├── start.bat                    # One-click Windows launcher for Both
└── README.md                    # This documentation
```

---

## 2. Quick Setup Instructions

### Prerequisites
- **Python 3.10+** (tested on Python 3.14)
- **Node.js 18+** & **npm**

### Step 1: Install Python Dependencies
```bash
python -m pip install -r backend/requirements.txt
```

### Step 2: Configure Gemini API Key
Edit `backend/.env` (or copy from `backend/.env.example`):
```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
GEMINI_MODEL=gemini-3.1-pro-preview
AUDIT_SOURCE_PRECEDENCE=PDF,PDP
ENABLE_INCORRECT_VERIFIER=true
LLM_RATE_LIMIT_MAX_RETRIES=4
LLM_RATE_LIMIT_BASE_DELAY_SECONDS=10
LLM_RATE_LIMIT_MAX_DELAY_SECONDS=60
HOST=127.0.0.1
PORT=8000
DEBUG=True
```
*(You can also configure or update your Gemini API key directly from the dashboard UI via the **Config** tab).*

When the LLM gateway returns HTTP 429 or a temporary 5xx response, the backend
automatically retries with bounded exponential backoff. A successfully validated
PDF/PDP source ledger is cached in `data/source_ledger_cache/`, so later retries
do not resend every PDF page unless **force refresh** is requested or an input,
model, or extraction prompt changes.

### Step 3: Input Files
Place your files in the `input/` folder:
- `input/centralized_data.xlsx`
- `input/mcat_data.zip`

*(Optional: To quickly test the pipeline with built-in realistic industrial motor data before using proprietary files, run `python scripts/generate_sample_data.py`).*

---

## 3. Running the Application

### Option A: One-Click Windows Launcher
Double-click:
```
start.bat
```
This starts the backend on **`http://localhost:8000`** and the Vite dev server on **`http://localhost:5173`**.

### Option B: Unified Single-Server Mode
The backend automatically serves the compiled React dashboard directly!
```bash
python backend/run.py
```
Open **`http://localhost:8000`** in your browser.

### Option C: Development Mode
Terminal 1 (Backend):
```bash
python backend/run.py
```
Terminal 2 (Frontend with Hot Module Replacement):
```bash
cd frontend
npm.cmd run dev
```
Open **`http://localhost:5173`** in your browser.

---

## 4. End-to-End User Flow

1. **Dashboard Startup**:
   - The dashboard automatically detects `input/centralized_data.xlsx` and `input/mcat_data.zip`.
   - Status indicators show `Loaded` or `Not Found`.
2. **SID Lookup**:
   - Enter one SID or comma-separated SIDs (e.g. `465702, 465747`) and click **[ Load SIDs ]**.
   - The backend resolves:
     - Variant ID & MCAT ID
     - Standard Product Name & Variant Name
     - PDF URL & PDP URL (with clickable links to verify)
     - Standard Product Specifications with sequence preservation
     - MCAT K/C classification (Tier: `★ K/C` vs `Regular`)
   - *Note: No audit verdicts are shown at this stage.*
3. **Run Audit**:
   - For one SID, click **[ Run Audit ]**. For multiple SIDs, click **[ Run Batch ]**.
   - Batch audits run one by one in the entered order. A failed SID is recorded and the next SID continues automatically.
   - A live 14-step timeline modal appears showing progress in real time:
     1. Variant data loaded
     2. MCAT K/C data loaded
     3. PDP URL resolved
     4. PDF URL resolved
     5. Downloading PDF
     6. PDF downloaded
     7. Extracting PDF (PyMuPDF full page extraction)
     8. Fetching PDP (structured specs & feature parsing)
     9. Preparing audit input (multimodal payload)
     10. Sending data to LLM
     11. LLM auditing specifications
     12. Validating LLM JSON (12 strict integrity rules)
     13. Audit completed (saved to SQLite database)
     14. Displaying result
4. **Audit Results View**:
   - **Summary Cards**: Total Specifications, Correct count, Incorrect count, Overall Status (`Pass` / `Fail`).
   - **Specification Results Table**:
     - `# | Specification | Standard Product Value | Expected Value | Tier | Verdict | Disposition | Severity | Remarks`
     - Prominent badges: **Correct** (green) vs **Incorrect** (red with High/Medium/Low severity).
5. **Specification Detail Panel**:
   - Click any specification row to open the detailed evidence panel:
     - Exact PDF page number and verbatim document excerpt.
     - PDP evidence citation.
     - Error type and reasoning.
6. **Source Tabs**:
   - **Standard Product**: Original specifications list.
   - **PDF Document**: PDF link + interactive page-by-page text viewer.
   - **PDP Content**: Extracted key-value tables and text.
   - **Validated JSON Output**: Raw formatted JSON result.
7. **Export & Re-run**:
   - For one audit, click **[ Export Excel ]** to download the existing 19-column workbook.
   - For a batch, click **[ Export Combined Excel ]** to download one workbook containing `Summary` plus a separate `SID_<id>` sheet for every completed SID. Failed SIDs and their reasons remain in `Summary`.
   - Click **[ Re-run Audit ]** to perform a fresh audit.
8. **Audit History**:
   - Click **Audit History** tab to view all past audits saved in SQLite.
   - Search by Variant ID, MCAT ID, or Product Name.
   - Click **Open** to reload any previous audit.

---

## 5. Automated Verification Tests

Run the backend test suite:
```bash
python scripts/test_backend.py
```
This tests:
1. `ZipService`: Archive unpacking and extraction tracking.
2. `MCATService`: K/C vs Regular specification classification.
3. `ExcelService`: Loading, flexible column mapping, and sequence order preservation.
4. `VariantService`: Metadata resolution and tier association.
5. `PDFService`: PyMuPDF page-wise text extraction.
6. `Validator`: Strict 12-point integrity validation (rejecting order mismatches and count changes).
7. `DatabaseService`: SQLite audit persistence and history query.
8. `ExcelExporter`: Styled 18-column Excel report generation.

---

## 6. Configurable Options
- **Column Mapping**: Customize Excel column aliases in `config/column_mapping.json`.
- **Audit Rules Prompt**: Modify audit guidelines in `config/audit_prompt.txt` (changes take effect dynamically on next audit without restarting the server).


## Per-specification source authority
Each catalog specification is audited only against the URL in column H of its own
`input/centralized_data.xlsx` row. Hyperlink targets in H are supported. Main product
PDF/PDP links are reference links and are not audit fallbacks. Sources are fetched
once per distinct URL; extraction and quotation validation stay isolated by URL.
Missing, unavailable, or unsupported row evidence requires review. MCAT rows added
automatically have no column H source and require review until supplied in Excel.
Existing history is unchanged; rerun an audit to apply this policy.

Verify this policy locally with `python scripts/test_row_sources.py`.
