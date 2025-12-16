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

-- 6) HR roles and employees
SELECT code, name, description FROM hr_roles ORDER BY code;

SELECT e.employee_number, pc.email AS employee_email, hr.code AS role_code, e.hired_at, e.active
FROM employees e
LEFT JOIN personal_customers pc ON pc.id = e.personal_customer_id
LEFT JOIN hr_roles hr ON hr.id = e.hr_role_id
ORDER BY e.employee_number LIMIT 50;

-- 7) Companies (non-personal customers)
SELECT id, name, registration_number, tax_id, country FROM companies ORDER BY name;

-- 8) Branch address parts and transit codes
SELECT id, name, civic_number, street_name, street_type, city, province, postal_code, branch_transit FROM branches ORDER BY name;

-- 9) Bulk counts
SELECT COUNT(*) FILTER (WHERE email LIKE 'bulk.cust%') AS bulk_customers FROM personal_customers;
SELECT COUNT(*) FILTER (WHERE registration_number LIKE 'BULK-REG-%') AS bulk_companies FROM companies;
SELECT COUNT(*) FILTER (WHERE account_number LIKE 'ACCT003%') AS bulk_customer_accounts FROM accounts;
SELECT COUNT(*) FILTER (WHERE description='BULK_SEED_BATCH_20251215') AS bulk_transactions FROM transactions;
