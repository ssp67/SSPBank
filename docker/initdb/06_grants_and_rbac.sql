-- Grant privileges to roles

-- bank_admin gets full access
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bank_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bank_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO bank_admin;

-- teller can read accounts and manage transactions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO teller;
GRANT INSERT, UPDATE ON transactions TO teller;
GRANT SELECT ON view_account_balances TO teller;

-- auditor read-only
GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor;

-- app_user typical limited privileges
GRANT SELECT ON view_account_balances, view_recent_transactions TO app_user;
GRANT EXECUTE ON FUNCTION get_account_statement(BIGINT, TIMESTAMPTZ, TIMESTAMPTZ) TO app_user;

-- Ensure future objects also grant privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO auditor;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT INSERT, UPDATE ON TABLES TO teller;
