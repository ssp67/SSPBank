Bank DB Schema

Files:
- schema/bank_schema.sql: main DDL
- schema/triggers.sql: trigger functions to post transactions and enforce overdraft checks
- seed/sample_data.sql: example rows to exercise the schema

Quick start (Postgres locally):

1) Create a database and run the schema:

```bash
createdb bankdb
psql -d bankdb -f schema/bank_schema.sql
psql -d bankdb -f schema/triggers.sql
psql -d bankdb -f seed/sample_data.sql
```

2) Using Docker Compose (recommended for local dev):

```powershell
# Start DB using docker-compose
docker compose up -d

# Wait a few seconds, then verify
./scripts/verify.ps1

# Or use the helper to start/stop/verify/seed:
./scripts/db_helper.ps1 start
./scripts/db_helper.ps1 verify
./scripts/db_helper.ps1 seed
./scripts/db_helper.ps1 stop
```

Credentials (for local dev):
- bank_admin: adminpass
- teller: tellerpass
- auditor: auditorpass
- app_user: apppass

Notes:
- This schema is PostgreSQL-oriented and uses `uuid-ossp`.
- Triggers update account balances when transaction `status` is set to `posted`.
- Audit triggers log row snapshots into `audit_logs`.
- Reports provided as views and a helper function: `get_account_statement`.
- RBAC is basic; refine role privileges to follow least privilege guidelines in production.

Notes:
- This schema is PostgreSQL-oriented and uses `uuid-ossp`.
- Triggers update account balances when transaction `status` is set to `posted`.
- Review the trigger logic before using it in production; add audit and idempotency rules as needed.
