-- Reporting views and helper functions

CREATE VIEW view_account_balances AS
SELECT a.id, a.account_number, a.balance, a.currency, a.status, a.opened_at
FROM accounts a;

CREATE VIEW view_customer_balances AS
SELECT c.id AS customer_id, c.first_name, c.last_name, SUM(a.balance) as total_balance
FROM personal_customers c
LEFT JOIN account_owners ao ON ao.customer_id = c.id
LEFT JOIN accounts a ON a.id = ao.account_id
GROUP BY c.id, c.first_name, c.last_name;

CREATE VIEW view_recent_transactions AS
SELECT t.* FROM transactions t ORDER BY t.created_at DESC LIMIT 100;

CREATE OR REPLACE FUNCTION get_account_statement(p_account_id BIGINT, p_from TIMESTAMPTZ, p_to TIMESTAMPTZ)
RETURNS TABLE(id BIGINT, tx_uuid UUID, amount NUMERIC, type TEXT, status TEXT, created_at TIMESTAMPTZ, posted_at TIMESTAMPTZ, description TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT id, tx_uuid, amount, type, status, created_at, posted_at, description
  FROM transactions
  WHERE (from_account_id = p_account_id OR to_account_id = p_account_id)
    AND created_at BETWEEN p_from AND p_to
  ORDER BY created_at;
END;
$$ LANGUAGE plpgsql;
