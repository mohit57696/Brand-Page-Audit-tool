# Production deployment

GitHub stores source code and runs CI. This Python application also needs a container host or server; GitHub Pages cannot run its backend.

## GitHub repository

Use a private repository for this internal tool. Git ignores API credentials, input spreadsheets, audit history, downloads, dependencies, and generated frontend bundles. Copy production data separately; do not upload it through GitHub.

## Container server setup

1. Clone the repository on a server with Docker and Docker Compose.
2. Create `input/` and copy `centralized_data.xlsx`, `mcat_data.zip`, and `mcat_specifications.xlsx` from the supplied handoff ZIP into it.
3. Copy `production.env.example` to `.env.production`. Set a strong `AUDIT_ADMIN_USERNAME` and `AUDIT_ADMIN_PASSWORD`, and the provider API key. Credentials are managed on the server; the production dashboard cannot change them.
4. Run `docker compose up -d --build`.
5. Route your domain to port 8000 through your hosting provider's HTTPS reverse proxy. The supplied Compose file binds port 8000 to server loopback; it is not exposed publicly by itself. Use HTTPS before sending login credentials over a network. On managed container hosting, use its private container port 8000 and persistent disk at `/app/data`.
6. Open the HTTPS URL and sign in using the configured username/password. Confirm the source-file counts, load a known SID, then run a sample audit.

`GET /healthz` is a public liveness endpoint with no product data. Dashboard, APIs, documentation, exports, and audit history require authentication in production. Startup fails if production login credentials are missing. Local Windows use remains unchanged unless production authentication is enabled.

## Storage and operation

`/app/input` holds the supplied spreadsheets and MCAT ZIP and must be mounted separately from the image. `/app/data` is persistent: it contains SQLite audit history, extracted MCAT data, evidence downloads, and source-ledger caches. Back up both locations. Do not use multiple Uvicorn workers or replicas with this application's in-memory audit service and SQLite storage. Long audits stream over SSE; configure your HTTPS proxy's request timeout for long requests and disable response buffering.

After editing Excel, save it and rescan in the app or restart the container. Preserve each spec's designated source in column H. Update code with `git pull` and `docker compose up -d --build`; the data volume persists. Do not run `docker compose down -v` unless intentionally deleting audit data.

## Validation

CI builds the frontend and container and runs the offline row-source, precision, source-loading, deployment-access, and gateway tests. No API credentials or production spreadsheets are needed for those checks.

A Docker runtime is not installed in the preparation workspace, so the image has not yet been built or run here. The private source repository is mohit57696/audit-tool on GitHub. Production hosting, domain setup, and a live audit still need to be completed against the selected hosting account.
