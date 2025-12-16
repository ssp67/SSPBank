-- Quick verification queries for bulk seed data
-- Run against the bank database to sanity check the new bulk data

-- 1) Total personal customers
SELECT count(*) AS personal_customers_total FROM personal_customers;

-- 2) List of sample emails we added (example domain)
SELECT email, first_name, last_name FROM personal_customers
WHERE email LIKE '%@example.com'
ORDER BY email;

-- 3) Account counts
SELECT count(*) AS account_count FROM accounts;

-- 4) Accounts and their owners (useful to spot joint accounts)
SELECT a.account_number, string_agg(pc.email, ', ') AS owners
FROM accounts a
JOIN account_owners ao ON ao.account_id = a.id
JOIN personal_customers pc ON pc.id = ao.customer_id
GROUP BY a.account_number
ORDER BY a.account_number;

-- 5) Recent transactions (sample)
SELECT id, amount, type, status, description, created_at FROM transactions ORDER BY created_at DESC LIMIT 20;
