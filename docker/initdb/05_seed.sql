-- Seed data applied at DB bootstrap

-- Branch
INSERT INTO branches (name, address, city, province, postal_code, country)
VALUES ('Main Branch','123 Main St','Toronto','ON','M5H 4E1','CA');

-- Employee
INSERT INTO employees (branch_id, first_name, last_name, role, email) VALUES (1,'Alice','Smith','teller','alice.smith@example.com');

-- Segments
INSERT INTO segments (code, name, description) VALUES
('RETAIL','Retail','Standard retail customers'),
('HV','HighValue','High value customers'),
('PW','PrivateWealth','Private wealth customers')
ON CONFLICT DO NOTHING;

-- Personal customers
INSERT INTO personal_customers (first_name, last_name, dob, email, phone, country, segment_id) VALUES
('John','Doe','1980-02-15','john.doe@example.com','+15551234','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Jane','Roe','1990-07-20','jane.roe@example.com','+15559876','CA',(SELECT id FROM segments WHERE code='HV'));

INSERT INTO parties (party_type, personal_customer_id)
SELECT 'personal', id
FROM personal_customers
WHERE email IN ('john.doe@example.com','jane.roe@example.com')
ON CONFLICT DO NOTHING;

-- Addresses
INSERT INTO personal_addresses (customer_id, type, civic_number, street_name, street_type, city, province, postal_code, country, effective_from)
SELECT id, 'home', '456', 'Elm', 'St', 'Toronto', 'ON', 'M5V 3K1', 'CA', now()::date FROM personal_customers WHERE email='john.doe@example.com';

INSERT INTO personal_addresses (customer_id, type, civic_number, street_name, street_type, city, province, postal_code, country, effective_from)
SELECT id, 'home', '789', 'Oak', 'Ave', 'Vancouver', 'BC', 'V6B 1A1', 'CA', now()::date FROM personal_customers WHERE email='jane.roe@example.com';

-- Identifications
INSERT INTO personal_identifications (customer_id, id_type, id_value, issued_by, issued_at)
SELECT id, 'SIN', '123-456-789', 'Service Canada', '2000-01-01' FROM personal_customers WHERE email='john.doe@example.com';

INSERT INTO personal_identifications (customer_id, id_type, id_value, issued_by, issued_at)
SELECT id, 'SIN', '987-654-321', 'Service Canada', '2005-05-05' FROM personal_customers WHERE email='jane.roe@example.com';

-- Education and employment
INSERT INTO education (customer_id, institution_name, degree, field, start_date, end_date)
SELECT id, 'University of Toronto', 'BSc', 'Economics', '1998-09-01', '2002-06-01' FROM personal_customers WHERE email='john.doe@example.com';

INSERT INTO employment (customer_id, employer_name, title, start_date, income)
SELECT id, 'Acme Corp', 'Analyst', '2010-01-01', 85000 FROM personal_customers WHERE email='john.doe@example.com';

-- Accounts
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
VALUES
('ACCT0000001', 1, 'CHEQUING', 'CAD', 1000.00),
('ACCT0000002', 1, 'SAVINGS', 'CAD', 500.00)
ON CONFLICT (account_number) DO NOTHING;

INSERT INTO bank_accounts (account_id, bank_account_type)
SELECT id, CASE WHEN type_id = 'CHEQUING' THEN 'chequing' ELSE 'savings' END
FROM accounts
WHERE account_number IN ('ACCT0000001','ACCT0000002')
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers c ON c.email IN ('john.doe@example.com','jane.roe@example.com')
JOIN parties p ON p.personal_customer_id = c.id
WHERE (a.account_number = 'ACCT0000001' AND c.email = 'john.doe@example.com')
   OR (a.account_number = 'ACCT0000002' AND c.email = 'jane.roe@example.com')
ON CONFLICT DO NOTHING;

-- Mortgage account for John
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCTM00001', 1, 'MORTGAGE', 'CAD', 250000.00
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCTM00001');

INSERT INTO mortgages (account_id, principal, interest_rate, start_date, end_date, status)
SELECT id, 250000.00, 0.0399, '2020-01-01', '2045-01-01', 'active'
FROM accounts
WHERE account_number='ACCTM00001'
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers c ON c.email='john.doe@example.com'
JOIN parties p ON p.personal_customer_id = c.id
WHERE a.account_number='ACCTM00001'
ON CONFLICT DO NOTHING;

-- PLC account for Jane
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCTP00001', 1, 'PLC', 'CAD', 0.00
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCTP00001');

INSERT INTO plc_accounts (account_id, credit_limit, interest_rate, status)
SELECT id, 15000.00, 0.0799, 'active'
FROM accounts
WHERE account_number='ACCTP00001'
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers c ON c.email='jane.roe@example.com'
JOIN parties p ON p.personal_customer_id = c.id
WHERE a.account_number='ACCTP00001'
ON CONFLICT DO NOTHING;

-- Investment accounts and holdings
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCTI00001', 1, 'INVESTMENT', 'CAD', 20000.00
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCTI00001');

INSERT INTO investment_accounts (account_id, registration_type, name, created_at)
SELECT id, 'RRSP', 'John Doe RRSP', now()
FROM accounts
WHERE account_number='ACCTI00001'
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers c ON c.email='john.doe@example.com'
JOIN parties p ON p.personal_customer_id = c.id
WHERE a.account_number='ACCTI00001'
ON CONFLICT DO NOTHING;

INSERT INTO gic_inv (investment_account_id, principal, interest_rate, term_months, maturity_date)
SELECT a.id, 5000.00, 0.0350, 12, '2026-01-01'
FROM accounts a
WHERE a.account_number='ACCTI00001'
ON CONFLICT DO NOTHING;

INSERT INTO mutual_fund_inv (investment_account_id, fund_name, units, nav, currency)
SELECT a.id, 'Global Equity Fund', 120.000000, 22.50, 'CAD'
FROM accounts a
WHERE a.account_number='ACCTI00001'
ON CONFLICT DO NOTHING;

INSERT INTO equity_inv (investment_account_id, symbol, shares, avg_price, currency)
SELECT a.id, 'RY', 50.000000, 98.25, 'CAD'
FROM accounts a
WHERE a.account_number='ACCTI00001'
ON CONFLICT DO NOTHING;

INSERT INTO investment_savings_inv (investment_account_id, balance, interest_rate, currency)
SELECT a.id, 3000.00, 0.0150, 'CAD'
FROM accounts a
WHERE a.account_number='ACCTI00001'
ON CONFLICT DO NOTHING;

INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCTI00002', 1, 'INVESTMENT', 'CAD', 12000.00
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCTI00002');

INSERT INTO investment_accounts (account_id, registration_type, name, created_at)
SELECT id, 'TFSA', 'Jane Roe TFSA', now()
FROM accounts
WHERE account_number='ACCTI00002'
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers c ON c.email='jane.roe@example.com'
JOIN parties p ON p.personal_customer_id = c.id
WHERE a.account_number='ACCTI00002'
ON CONFLICT DO NOTHING;

INSERT INTO equity_inv (investment_account_id, symbol, shares, avg_price, currency)
SELECT a.id, 'SHOP', 10.000000, 62.10, 'CAD'
FROM accounts a
WHERE a.account_number='ACCTI00002'
ON CONFLICT DO NOTHING;

-- Transactions
INSERT INTO transactions (to_account_id, amount, type, status, description, initiated_by_customer_id)
SELECT a.id, 250.00, 'deposit', 'posted', 'ATM deposit', c.id
FROM accounts a
JOIN personal_customers c ON c.email = 'john.doe@example.com'
WHERE a.account_number = 'ACCT0000001';

INSERT INTO transactions (from_account_id, to_account_id, amount, type, status, description, initiated_by_customer_id)
SELECT a_from.id, a_to.id, 120.00, 'transfer', 'posted', 'Rent payment', c.id
FROM accounts a_from
JOIN accounts a_to ON a_to.account_number = 'ACCT0000002'
JOIN personal_customers c ON c.email = 'john.doe@example.com'
WHERE a_from.account_number = 'ACCT0000001';

-- Cards
INSERT INTO cards (card_number, account_id, card_type, interest_rate, expiry_date)
SELECT '4111-1111-1111-1111', a.id, 'debit', 0.0000, '2028-12-31'
FROM accounts a
WHERE a.account_number = 'ACCT0000001'
ON CONFLICT (account_id) DO NOTHING;

INSERT INTO card_transactions (card_id, merchant, amount, currency, status)
SELECT a.id, 'Coffee Shop', 4.50, 'USD', 'settled'
FROM accounts a
WHERE a.account_number = 'ACCT0000001';

-- Product catalogue seed
INSERT INTO product_categories (id, name, description) VALUES
('CREDIT_CARDS','Credit Cards','Personal and business credit card products'),
('CHEQUING','Chequing','Chequing accounts'),
('SAVINGS','Savings','Savings accounts'),
('GIC','GIC','Guaranteed Investment Certificates'),
('MUTUAL_FUNDS','Mutual Funds','Mutual fund investment products'),
('LOANS','Loans','Personal and unsecured loans'),
('PLC','PLC','Personal Line of Credit'),
('MORTGAGES','Mortgages','Residential mortgage products'),
('INSURANCE','Insurance','Life and property insurance products'),
('EQUITY','Equity','Equity investment products'),
('INVESTMENT_SAVINGS','InvestmentSavings','Investment savings products');

-- (Same product insert list as the sample_data.sql)
INSERT INTO product_catalogue (category_id, product_code, name, description, price, interest_rate)
VALUES
((SELECT id FROM product_categories WHERE name='Credit Cards'),'CC-001','CashBack Classic','1.5% cash back on groceries',0,0.1999),
((SELECT id FROM product_categories WHERE name='Credit Cards'),'CC-002','Travel Elite','Priority travel benefits and lounge access',0,0.2199),
((SELECT id FROM product_categories WHERE name='Credit Cards'),'CC-003','Student Starter','Low APR for students',0,0.1199),
((SELECT id FROM product_categories WHERE name='Credit Cards'),'CC-004','Business Pro','Business rewards and reporting',0,0.2099),
((SELECT id FROM product_categories WHERE name='Credit Cards'),'CC-005','LowRate','Low interest rate credit card',0,0.0999);

-- Chequing
INSERT INTO product_catalogue (category_id, product_code, name, description, price)
VALUES
((SELECT id FROM product_categories WHERE name='Chequing'),'BA-001','Everyday Checking','No monthly fee everyday account',0),
((SELECT id FROM product_categories WHERE name='Chequing'),'BA-003','Student Account','Accounts tailored for students',0),
((SELECT id FROM product_categories WHERE name='Chequing'),'BA-004','Joint Checking','Joint account for two or more',0),
((SELECT id FROM product_categories WHERE name='Chequing'),'BA-005','Business Checking','Account for small business owners',0);

-- Savings
INSERT INTO product_catalogue (category_id, product_code, name, description, price)
VALUES
((SELECT id FROM product_categories WHERE name='Savings'),'BA-002','Premium Savings','High-interest savings with ATM rebate',0);

INSERT INTO product_catalogue (category_id, product_code, name, description, price, interest_rate, term_months)
VALUES
((SELECT id FROM product_categories WHERE name='GIC'),'GIC-001','1 Year GIC','1-year GIC with fixed return',0,0.0350,12),
((SELECT id FROM product_categories WHERE name='GIC'),'GIC-002','2 Year GIC','2-year GIC with higher rate',0,0.0400,24),
((SELECT id FROM product_categories WHERE name='GIC'),'GIC-003','5 Year GIC','Long-term GIC with top rate',0,0.0500,60),
((SELECT id FROM product_categories WHERE name='GIC'),'GIC-004','Registered GIC','RRSP eligible GIC',0,0.0425,36),
((SELECT id FROM product_categories WHERE name='GIC'),'GIC-005','Non-redeemable GIC','Fixed term, no early withdrawal',0,0.0450,48);

INSERT INTO product_catalogue (category_id, product_code, name, description, price)
VALUES
((SELECT id FROM product_categories WHERE name='Mutual Funds'),'MF-001','Global Equity Fund','Diversified global equities',0),
((SELECT id FROM product_categories WHERE name='Mutual Funds'),'MF-002','Bond Income Fund','Conservative income focused',0),
((SELECT id FROM product_categories WHERE name='Mutual Funds'),'MF-003','Balanced Growth Fund','Mix of stocks and bonds',0),
((SELECT id FROM product_categories WHERE name='Mutual Funds'),'MF-004','Index Tracker','Low-cost index fund',0),
((SELECT id FROM product_categories WHERE name='Mutual Funds'),'MF-005','ESG Fund','Environmental and social governance focused',0);

INSERT INTO product_catalogue (category_id, product_code, name, description, price, interest_rate, term_months)
VALUES
((SELECT id FROM product_categories WHERE name='Loans'),'LN-001','Personal Loan 36m','Unsecured personal loan 3 years',0,0.0850,36),
((SELECT id FROM product_categories WHERE name='Loans'),'LN-002','Personal Loan 60m','Unsecured personal loan 5 years',0,0.0950,60),
((SELECT id FROM product_categories WHERE name='Loans'),'LN-003','Auto Loan','Financing for vehicle purchases',0,0.0499,60),
((SELECT id FROM product_categories WHERE name='Loans'),'LN-004','Debt Consolidation','Loan to consolidate debts',0,0.0799,48),
((SELECT id FROM product_categories WHERE name='Loans'),'LN-005','Education Loan','Loans for post-secondary education',0,0.0399,120);

INSERT INTO product_catalogue (category_id, product_code, name, description, price, interest_rate)
VALUES
((SELECT id FROM product_categories WHERE name='PLC'),'PLC-001','PLC Standard','Personal line of credit with variable rate',0,0.0599),
((SELECT id FROM product_categories WHERE name='PLC'),'PLC-002','PLC Premium','Higher limit with lower rate',0,0.0499),
((SELECT id FROM product_categories WHERE name='PLC'),'PLC-003','PLC Student','Small limit for students',0,0.0799),
((SELECT id FROM product_categories WHERE name='PLC'),'PLC-004','PLC Secured','Secured against savings',0,0.0399),
((SELECT id FROM product_categories WHERE name='PLC'),'PLC-005','PLC Business','PLC for sole-proprietors',0,0.0699);

INSERT INTO product_catalogue (category_id, product_code, name, description, price, interest_rate, term_months)
VALUES
((SELECT id FROM product_categories WHERE name='Mortgages'),'MTG-001','Fixed 5-year','5-year fixed rate mortgage',0,0.0399,60),
((SELECT id FROM product_categories WHERE name='Mortgages'),'MTG-002','Variable Rate','Variable rate mortgage',0,0.0299,60),
((SELECT id FROM product_categories WHERE name='Mortgages'),'MTG-003','Open Mortgage','Flexible repayment open mortgage',0,0.0499,60),
((SELECT id FROM product_categories WHERE name='Mortgages'),'MTG-004','High-Ratio','Mortgage with CMHC insurance',0,0.0350,60),
((SELECT id FROM product_categories WHERE name='Mortgages'),'MTG-005','Refinance Mortgage','Refinance and consolidate',0,0.0449,60);

INSERT INTO product_catalogue (category_id, product_code, name, description, price)
VALUES
((SELECT id FROM product_categories WHERE name='Insurance'),'IN-001','Term Life 20yr','20-year term life insurance',0),
((SELECT id FROM product_categories WHERE name='Insurance'),'IN-002','Home Insurance Basic','Standard home insurance',0),
((SELECT id FROM product_categories WHERE name='Insurance'),'IN-003','Auto Insurance','Car insurance product',0),
((SELECT id FROM product_categories WHERE name='Insurance'),'IN-004','Critical Illness','Lump sum on diagnosis',0),
((SELECT id FROM product_categories WHERE name='Insurance'),'IN-005','Travel Insurance','Short-term travel coverage',0);

-- Equity
INSERT INTO product_catalogue (category_id, product_code, name, description, price)
VALUES
((SELECT id FROM product_categories WHERE name='Equity'),'INV-001','ETF Income','Exchange-traded fund for income',0),
((SELECT id FROM product_categories WHERE name='Equity'),'INV-003','Segregated Fund','Insurance-backed investment',0),
((SELECT id FROM product_categories WHERE name='Equity'),'INV-005','High Yield Note','Structured product with yield',0);

-- Investment Savings
INSERT INTO product_catalogue (category_id, product_code, name, description, price)
VALUES
((SELECT id FROM product_categories WHERE name='InvestmentSavings'),'INV-002','Robo Advisor','Managed portfolio service',0),
((SELECT id FROM product_categories WHERE name='InvestmentSavings'),'INV-004','Managed Account','Advisor-managed account',0);

-- Ensure example accounts exist (use fixed account numbers) and map owners
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCT0000001', 1, 'CHEQUING', 'CAD', 1000.00
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCT0000001');

INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCT0000002', 1, 'SAVINGS', 'CAD', 500.00
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCT0000002');

INSERT INTO parties (party_type, personal_customer_id)
SELECT 'personal', id
FROM personal_customers
WHERE email IN ('john.doe@example.com','jane.roe@example.com')
ON CONFLICT DO NOTHING;

INSERT INTO bank_accounts (account_id, bank_account_type)
SELECT id, CASE WHEN type_id = 'CHEQUING' THEN 'chequing' ELSE 'savings' END
FROM accounts
WHERE account_number IN ('ACCT0000001','ACCT0000002')
ON CONFLICT DO NOTHING;

-- Map owners (idempotent)
INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers c ON c.email='john.doe@example.com'
JOIN parties p ON p.personal_customer_id = c.id
WHERE a.account_number='ACCT0000001'
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers c ON c.email='jane.roe@example.com'
JOIN parties p ON p.personal_customer_id = c.id
WHERE a.account_number='ACCT0000002'
ON CONFLICT DO NOTHING;

-- Bulk sample customers and related data (idempotent)
INSERT INTO personal_customers (first_name, last_name, dob, email, phone, country, segment_id)
VALUES
('Liam','Smith','1975-04-02','liam.smith@example.com','+14165550010','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Olivia','Brown','1988-11-12','olivia.brown@example.com','+14165550011','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Noah','Johnson','1990-01-21','noah.johnson@example.com','+16045550012','CA',(SELECT id FROM segments WHERE code='HV')),
('Emma','Wilson','1982-06-09','emma.wilson@example.com','+16045550013','CA',(SELECT id FROM segments WHERE code='HV')),
('Oliver','Taylor','1995-03-15','oliver.taylor@example.com','+17875550014','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Ava','Anderson','1978-09-30','ava.anderson@example.com','+7805550015','CA',(SELECT id FROM segments WHERE code='PW')),
('William','Thomas','1984-12-05','william.thomas@example.com','+14165550016','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Sophia','Jackson','1992-07-22','sophia.jackson@example.com','+14035550017','CA',(SELECT id FROM segments WHERE code='HV')),
('Benjamin','White','1987-02-10','benjamin.white@example.com','+14165550018','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Isabella','Harris','1991-05-18','isabella.harris@example.com','+14165550019','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Elijah','Martin','1983-08-14','elijah.martin@example.com','+14165550020','CA',(SELECT id FROM segments WHERE code='HV')),
('Mia','Thompson','1996-10-02','mia.thompson@example.com','+14035550021','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('James','Garcia','1979-01-27','james.garcia@example.com','+14165550022','CA',(SELECT id FROM segments WHERE code='PW')),
('Charlotte','Martinez','1986-04-11','charlotte.martinez@example.com','+16045550023','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Lucas','Robinson','1993-09-03','lucas.robinson@example.com','+14165550024','CA',(SELECT id FROM segments WHERE code='HV')),
('Amelia','Clark','1981-02-28','amelia.clark@example.com','+14165550025','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Henry','Rodriguez','1976-12-19','henry.rodriguez@example.com','+14165550026','CA',(SELECT id FROM segments WHERE code='PW')),
('Evelyn','Lewis','1994-06-06','evelyn.lewis@example.com','+17875550027','CA',(SELECT id FROM segments WHERE code='RETAIL'))
ON CONFLICT (email) DO NOTHING;

INSERT INTO parties (party_type, personal_customer_id)
SELECT 'personal', id
FROM personal_customers
WHERE email IN (
  'liam.smith@example.com','olivia.brown@example.com','noah.johnson@example.com','emma.wilson@example.com',
  'oliver.taylor@example.com','ava.anderson@example.com','william.thomas@example.com','sophia.jackson@example.com',
  'benjamin.white@example.com','isabella.harris@example.com','elijah.martin@example.com','mia.thompson@example.com',
  'james.garcia@example.com','charlotte.martinez@example.com','lucas.robinson@example.com','amelia.clark@example.com',
  'henry.rodriguez@example.com','evelyn.lewis@example.com'
)
ON CONFLICT DO NOTHING;

-- Addresses (per Canada Post parts)
INSERT INTO personal_addresses (customer_id, type, civic_number, street_name, street_type, city, province, postal_code, country, effective_from)
SELECT id, 'home', '12', 'King', 'St', 'Toronto', 'ON', 'M5H 1A1', 'CA', now()::date FROM personal_customers WHERE email='liam.smith@example.com' AND NOT EXISTS (SELECT 1 FROM personal_addresses pa WHERE pa.customer_id = personal_customers.id AND pa.postal_code='M5H 1A1');

INSERT INTO personal_addresses (customer_id, type, civic_number, street_name, street_type, city, province, postal_code, country, effective_from)
SELECT id, 'home', '34', 'Queen', 'St', 'Toronto', 'ON', 'M5V 2B6', 'CA', now()::date FROM personal_customers WHERE email='olivia.brown@example.com' AND NOT EXISTS (SELECT 1 FROM personal_addresses pa WHERE pa.customer_id = personal_customers.id AND pa.postal_code='M5V 2B6');

INSERT INTO personal_addresses (customer_id, type, civic_number, street_name, street_type, city, province, postal_code, country, effective_from)
SELECT id, 'home', '56', 'Granville', 'St', 'Vancouver', 'BC', 'V6C 1T1', 'CA', now()::date FROM personal_customers WHERE email='oliver.taylor@example.com' AND NOT EXISTS (SELECT 1 FROM personal_addresses pa WHERE pa.customer_id = personal_customers.id AND pa.postal_code='V6C 1T1');

-- Identifications
INSERT INTO personal_identifications (customer_id, id_type, id_value, issued_by, issued_at)
SELECT id, 'SIN', '100-200-300', 'Service Canada', '2001-02-03' FROM personal_customers WHERE email='liam.smith@example.com' AND NOT EXISTS (SELECT 1 FROM personal_identifications pi WHERE pi.customer_id = personal_customers.id AND pi.id_type='SIN');

INSERT INTO personal_identifications (customer_id, id_type, id_value, issued_by, issued_at)
SELECT id, 'SIN', '200-300-400', 'Service Canada', '2002-03-04' FROM personal_customers WHERE email='olivia.brown@example.com' AND NOT EXISTS (SELECT 1 FROM personal_identifications pi WHERE pi.customer_id = personal_customers.id AND pi.id_type='SIN');

-- Education & Employment (sample)
INSERT INTO education (customer_id, institution_name, degree, field, start_date, end_date)
SELECT id, 'McGill University', 'BA', 'Political Science', '1995-09-01', '1999-06-01' FROM personal_customers WHERE email='noah.johnson@example.com' AND NOT EXISTS (SELECT 1 FROM education e WHERE e.customer_id = personal_customers.id AND e.institution_name='McGill University');

INSERT INTO employment (customer_id, employer_name, title, start_date, income)
SELECT id, 'Maple Financial', 'Manager', '2015-06-01', 120000 FROM personal_customers WHERE email='emma.wilson@example.com' AND NOT EXISTS (SELECT 1 FROM employment em WHERE em.customer_id = personal_customers.id AND em.employer_name='Maple Financial');

-- Accounts and ownerships (create accounts and map owners, including joint accounts)
-- Individual accounts
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCT0000101', 1, 'CHEQUING', 'CAD', 2500.00 WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCT0000101');

INSERT INTO bank_accounts (account_id, bank_account_type)
SELECT id, 'chequing' FROM accounts WHERE account_number='ACCT0000101'
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers pc ON pc.email='liam.smith@example.com'
JOIN parties p ON p.personal_customer_id = pc.id
WHERE a.account_number='ACCT0000101'
ON CONFLICT DO NOTHING;

INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCT0000102', 1, 'SAVINGS', 'CAD', 5000.00 WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCT0000102');
INSERT INTO bank_accounts (account_id, bank_account_type)
SELECT id, 'savings' FROM accounts WHERE account_number='ACCT0000102'
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers pc ON pc.email='olivia.brown@example.com'
JOIN parties p ON p.personal_customer_id = pc.id
WHERE a.account_number='ACCT0000102'
ON CONFLICT DO NOTHING;

-- Joint account between Noah and Emma
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCT0000110', 1, 'CHEQUING', 'CAD', 10000.00 WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCT0000110');
INSERT INTO bank_accounts (account_id, bank_account_type)
SELECT id, 'chequing' FROM accounts WHERE account_number='ACCT0000110'
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 50
FROM accounts a
JOIN personal_customers pc ON pc.email IN ('noah.johnson@example.com','emma.wilson@example.com')
JOIN parties p ON p.personal_customer_id = pc.id
WHERE a.account_number='ACCT0000110'
ON CONFLICT DO NOTHING;

-- More accounts for others
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCT0000120', 1, 'CHEQUING', 'CAD', 1500.00 WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCT0000120');
INSERT INTO bank_accounts (account_id, bank_account_type)
SELECT id, 'chequing' FROM accounts WHERE account_number='ACCT0000120'
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers pc ON pc.email='oliver.taylor@example.com'
JOIN parties p ON p.personal_customer_id = pc.id
WHERE a.account_number='ACCT0000120'
ON CONFLICT DO NOTHING;

INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCT0000130', 1, 'SAVINGS', 'CAD', 8000.00 WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCT0000130');
INSERT INTO bank_accounts (account_id, bank_account_type)
SELECT id, 'savings' FROM accounts WHERE account_number='ACCT0000130'
ON CONFLICT DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN personal_customers pc ON pc.email='ava.anderson@example.com'
JOIN parties p ON p.personal_customer_id = pc.id
WHERE a.account_number='ACCT0000130'
ON CONFLICT DO NOTHING;

-- Sample transactions to exercise triggers
INSERT INTO transactions (from_account_id, to_account_id, amount, type, status, description)
SELECT (SELECT id FROM accounts WHERE account_number='ACCT0000101'), (SELECT id FROM accounts WHERE account_number='ACCT0000102'), 200.00, 'transfer', 'posted', 'Gift' WHERE NOT EXISTS (SELECT 1 FROM transactions t WHERE t.description='Gift' AND t.amount=200.00);

-- Add a few more authorized users for joint households
INSERT INTO party_account_reln (party_id, account_id, role)
SELECT p.id, a.id, 'authorized-user'
FROM accounts a
JOIN personal_customers pc ON pc.email IN ('william.thomas@example.com','sophia.jackson@example.com')
JOIN parties p ON p.personal_customer_id = pc.id
WHERE a.account_number='ACCT0000130'
ON CONFLICT DO NOTHING;

-- Seed companies for non-personal customers
INSERT INTO companies (name, registration_number, tax_id, business_structure_code, naics_code, country)
VALUES
('Harbour Logistics','HL-REG-100','TAX-HL-100','CORP','48411','CA'),
('Greenfields Farming Ltd','GF-REG-200','TAX-GF-200','LTD','111130','CA')
ON CONFLICT (registration_number) DO NOTHING;

INSERT INTO parties (party_type, company_id)
SELECT 'company', id
FROM companies
WHERE registration_number IN ('HL-REG-100','GF-REG-200')
ON CONFLICT DO NOTHING;

-- Ensure branches have Canadian address parts and a transit code (idempotent)
UPDATE branches SET civic_number='200', street_name='King', street_type='St', city='Toronto', province='ON', postal_code='M5H 4E1', branch_transit='20001' WHERE branch_transit IS NULL OR branch_transit='';

-- HR roles (idempotent)
INSERT INTO hr_roles (code, name, description)
VALUES
('DEV','Developer','Software development'),
('BRANCH_MANAGER','Branch Manager','Responsible for branch operations'),
('TELLER','Teller','Branch teller - front-line cash and service'),
('FA','Financial Advisor','Advisory and sales'),
('CSR','Customer Service Representative','Customer service and account support'),
('MA','Mortgage Advisor','Mortgage sales and servicing'),
('BACKOFFICE','Back Office','Back-office operations'),
('TB','Teller Back','Cash operations support'),
('CEO','Chief Executive Officer','Executive leadership'),
('VP','Vice President','Executive management')
ON CONFLICT (code) DO NOTHING;

-- Seed employees as personal_customers and employee entries
INSERT INTO personal_customers (first_name, last_name, dob, email, phone, country, segment_id)
VALUES
('Ethan','Branch','1990-03-03','ethan.branch@ssbank.example.com','+14165550997','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Grace','Ops','1985-07-07','grace.ops@ssbank.example.com','+14165550996','CA',(SELECT id FROM segments WHERE code='RETAIL'))
ON CONFLICT (email) DO NOTHING;

INSERT INTO parties (party_type, personal_customer_id)
SELECT 'personal', id
FROM personal_customers
WHERE email IN ('ethan.branch@ssbank.example.com','grace.ops@ssbank.example.com')
ON CONFLICT DO NOTHING;

INSERT INTO employees (personal_customer_id, employee_number, hr_role_id, branch_id, hired_at)
SELECT pc.id, 'EMP0003', hr.id, b.id, '2019-01-15'
FROM personal_customers pc JOIN hr_roles hr ON hr.code='TELLER' JOIN branches b ON b.name ILIKE '%Main%' WHERE pc.email='ethan.branch@ssbank.example.com'
ON CONFLICT (employee_number) DO NOTHING;

INSERT INTO employees (personal_customer_id, employee_number, hr_role_id, branch_id, hired_at)
SELECT pc.id, 'EMP0004', hr.id, b.id, '2017-05-10'
FROM personal_customers pc JOIN hr_roles hr ON hr.code='BACKOFFICE' JOIN branches b ON b.name ILIKE '%Main%' WHERE pc.email='grace.ops@ssbank.example.com'
ON CONFLICT (employee_number) DO NOTHING;

-- Bulk generation (mirror): 50 personal customers, 10 companies, accounts, joint accounts, and transactions
WITH nums AS (SELECT generate_series(1,50) AS n)
INSERT INTO personal_customers (first_name, last_name, dob, email, phone, country, segment_id)
SELECT
	format('BulkFirst%02d', n),
	format('BulkLast%02d', n),
	(date '1970-01-01' + (n * 400) * INTERVAL '1 day')::date,
	format('bulk.cust%03d@example.com', n),
	format('+1416%07d', 6000000 + n),
	'CA',
	(SELECT id FROM segments ORDER BY id LIMIT 1 OFFSET ((n-1) % (SELECT COUNT(*) FROM segments)))
FROM nums
ON CONFLICT (email) DO NOTHING;

INSERT INTO parties (party_type, personal_customer_id)
SELECT 'personal', id
FROM personal_customers
WHERE email LIKE 'bulk.cust%'
ON CONFLICT DO NOTHING;

INSERT INTO companies (name, registration_number, tax_id, business_structure_code, naics_code, country)
SELECT format('BulkCo %02d', n), format('BULK-REG-%03d', n), format('BULK-TAX-%03d', n), 'CORP', '54161', 'CA' FROM generate_series(1,10) n
ON CONFLICT (registration_number) DO NOTHING;

INSERT INTO parties (party_type, company_id)
SELECT 'company', id
FROM companies
WHERE registration_number LIKE 'BULK-REG-%'
ON CONFLICT DO NOTHING;

-- Create one account per new personal customer and link them
WITH new_cust AS (
	SELECT id, email, ROW_NUMBER() OVER (ORDER BY id) as rn FROM personal_customers WHERE email LIKE 'bulk.cust%'
)
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT format('ACCT%07s', 300000 + rn), (SELECT id FROM branches ORDER BY id LIMIT 1),
       CASE WHEN (rn % 2) = 0 THEN 'CHEQUING' ELSE 'SAVINGS' END,
       'CAD', (round((random()*10000)::numeric,2))
FROM new_cust
ON CONFLICT (account_number) DO NOTHING;

INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, a.id, 'owner', 100
FROM accounts a
JOIN new_cust nc ON a.account_number = format('ACCT%07s', 300000 + nc.rn)
JOIN parties p ON p.personal_customer_id = nc.id
ON CONFLICT DO NOTHING;

INSERT INTO bank_accounts (account_id, bank_account_type)
SELECT a.id, CASE WHEN a.type_id = 'CHEQUING' THEN 'chequing' ELSE 'savings' END
FROM accounts a
JOIN new_cust nc ON a.account_number = format('ACCT%07s', 300000 + nc.rn)
ON CONFLICT DO NOTHING;

-- Joint accounts
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT format('ACCT%07s', 400000 + rn), (SELECT id FROM branches ORDER BY id LIMIT 1), 'CHEQUING', 'CAD', 5000.00 FROM generate_series(1,10) rn
ON CONFLICT (account_number) DO NOTHING;

-- Link joint owners by pairing sequential bulk customers
WITH bulk_cust AS (
	SELECT id, row_number() OVER (ORDER BY id) AS rn
	FROM personal_customers
	WHERE email LIKE 'bulk.cust%'
),
joint_accounts AS (
	SELECT id, row_number() OVER (ORDER BY account_number) AS rn
	FROM accounts
	WHERE account_number LIKE 'ACCT004%'
),
pairs AS (
	SELECT ja.id AS account_id,
	       bc1.id AS cust1,
	       bc2.id AS cust2
	FROM joint_accounts ja
	JOIN bulk_cust bc1 ON bc1.rn = ((ja.rn - 1) * 2) % (SELECT COUNT(*) FROM bulk_cust) + 1
	JOIN bulk_cust bc2 ON bc2.rn = ((ja.rn - 1) * 2 + 1) % (SELECT COUNT(*) FROM bulk_cust) + 1
)
INSERT INTO party_account_reln (party_id, account_id, role, ownership_percent)
SELECT p.id, pr.account_id, 'owner', 50
FROM pairs pr
JOIN parties p ON p.personal_customer_id IN (pr.cust1, pr.cust2)
ON CONFLICT DO NOTHING;

INSERT INTO bank_accounts (account_id, bank_account_type)
SELECT id, 'chequing'
FROM accounts
WHERE account_number LIKE 'ACCT004%'
ON CONFLICT DO NOTHING;

-- Transactions batch (guarded by marker)
DO $$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM transactions WHERE description = 'BULK_SEED_BATCH_20251215') THEN
		INSERT INTO transactions (from_account_id, to_account_id, amount, type, status, description, created_at)
		SELECT a_from.id, a_to.id, round((random()*1000)::numeric,2), 'transfer', 'posted', 'BULK_SEED_BATCH_20251215', now() - (n || ' days')::interval
		FROM (SELECT id FROM accounts ORDER BY id LIMIT 100) a_from
		CROSS JOIN LATERAL (SELECT id FROM accounts WHERE id <> a_from.id ORDER BY random() LIMIT 1) a_to
		CROSS JOIN generate_series(1,2) n;
	END IF;
END$$;

