-- Seed data applied at DB bootstrap

-- Branch
INSERT INTO branches (name, address, city, state, zip, country) VALUES ('Main Branch','123 Main St','Metropolis','NY','10001','US');

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
INSERT INTO accounts (account_number, customer_id, branch_id, type_id, currency, balance) VALUES
(NULL, 1, 1, 1, 'USD', 1000.00),
(NULL, 2, 1, 2, 'USD', 500.00);

-- Transactions
INSERT INTO transactions (to_account_id, amount, type, status, description, initiated_by_customer_id) VALUES (1, 250.00, 'deposit', 'posted', 'ATM deposit', 1);
INSERT INTO transactions (from_account_id, to_account_id, amount, type, status, description, initiated_by_customer_id) VALUES (1, 2, 120.00, 'transfer', 'posted', 'Rent payment', 1);

-- Cards
INSERT INTO cards (card_number, account_id, card_type, expiry_date) VALUES ('4111-1111-1111-1111', 1, 'debit', '2028-12-31');
INSERT INTO card_transactions (card_id, merchant, amount, currency, status) VALUES (1, 'Coffee Shop', 4.50, 'USD', 'settled');

-- Product catalogue seed
INSERT INTO product_categories (name, description) VALUES
('Credit Cards','Personal and business credit card products'),
('Bank Accounts','Checking and savings accounts'),
('GIC','Guaranteed Investment Certificates'),
('Mutual Funds','Mutual fund investment products'),
('Loans','Personal and unsecured loans'),
('PLC','Personal Line of Credit'),
('Mortgages','Residential mortgage products'),
('Insurance','Life and property insurance products'),
('Investments','Other investment products');

-- (Same product insert list as the sample_data.sql)
INSERT INTO product_catalogue (category_id, product_code, name, description, price, interest_rate)
VALUES
((SELECT id FROM product_categories WHERE name='Credit Cards'),'CC-001','CashBack Classic','1.5% cash back on groceries',0,0.1999),
((SELECT id FROM product_categories WHERE name='Credit Cards'),'CC-002','Travel Elite','Priority travel benefits and lounge access',0,0.2199),
((SELECT id FROM product_categories WHERE name='Credit Cards'),'CC-003','Student Starter','Low APR for students',0,0.1199),
((SELECT id FROM product_categories WHERE name='Credit Cards'),'CC-004','Business Pro','Business rewards and reporting',0,0.2099),
((SELECT id FROM product_categories WHERE name='Credit Cards'),'CC-005','LowRate','Low interest rate credit card',0,0.0999);

INSERT INTO product_catalogue (category_id, product_code, name, description, price)
VALUES
((SELECT id FROM product_categories WHERE name='Bank Accounts'),'BA-001','Everyday Checking','No monthly fee everyday account',0),
((SELECT id FROM product_categories WHERE name='Bank Accounts'),'BA-002','Premium Savings','High-interest savings with ATM rebate',0),
((SELECT id FROM product_categories WHERE name='Bank Accounts'),'BA-003','Student Account','Accounts tailored for students',0),
((SELECT id FROM product_categories WHERE name='Bank Accounts'),'BA-004','Joint Checking','Joint account for two or more',0),
((SELECT id FROM product_categories WHERE name='Bank Accounts'),'BA-005','Business Checking','Account for small business owners',0);

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

INSERT INTO product_catalogue (category_id, product_code, name, description, price)
VALUES
((SELECT id FROM product_categories WHERE name='Investments'),'INV-001','ETF Income','Exchange-traded fund for income',0),
((SELECT id FROM product_categories WHERE name='Investments'),'INV-002','Robo Advisor','Managed portfolio service',0),
((SELECT id FROM product_categories WHERE name='Investments'),'INV-003','Segregated Fund','Insurance-backed investment',0),
((SELECT id FROM product_categories WHERE name='Investments'),'INV-004','Managed Account','Advisor-managed account',0),
((SELECT id FROM product_categories WHERE name='Investments'),'INV-005','High Yield Note','Structured product with yield',0);

-- Ensure example accounts exist (use fixed account numbers) and map owners
INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCT0000001', 1, 1, 'CAD', 1000.00
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCT0000001');

INSERT INTO accounts (account_number, branch_id, type_id, currency, balance)
SELECT 'ACCT0000002', 1, 2, 'CAD', 500.00
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE account_number='ACCT0000002');

-- Map owners (idempotent)
INSERT INTO account_owners (account_id, customer_id, is_primary)
SELECT a.id, c.id, true
FROM accounts a JOIN customers c ON c.email='john.doe@example.com'
WHERE a.account_number='ACCT0000001'
ON CONFLICT DO NOTHING;

INSERT INTO account_owners (account_id, customer_id, is_primary)
SELECT a.id, c.id, true
FROM accounts a JOIN customers c ON c.email='jane.roe@example.com'
WHERE a.account_number='ACCT0000002'
ON CONFLICT DO NOTHING;
