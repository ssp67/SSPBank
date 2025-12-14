-- Seed data applied at DB bootstrap

-- Branch
INSERT INTO branches (name, address, city, state, zip, country) VALUES ('Main Branch','123 Main St','Metropolis','NY','10001','US');

-- Employee
INSERT INTO employees (branch_id, first_name, last_name, role, email) VALUES (1,'Alice','Smith','teller','alice.smith@example.com');

-- Customers
INSERT INTO customers (first_name, last_name, dob, email, phone, address) VALUES
('John','Doe','1980-02-15','john.doe@example.com','+15551234','456 Elm St'),
('Jane','Roe','1990-07-20','jane.roe@example.com','+15559876','789 Oak Ave');

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
