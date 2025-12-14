-- PostgreSQL bank schema (typical banking model)
-- Run with: psql -f schema/bank_schema.sql

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Customers
CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    dob DATE,
    email TEXT UNIQUE,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    status TEXT DEFAULT 'active'
);

-- Branches
CREATE TABLE branches (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    country TEXT DEFAULT 'US',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Employees
CREATE TABLE employees (
    id BIGSERIAL PRIMARY KEY,
    branch_id BIGINT REFERENCES branches(id) ON DELETE SET NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    role TEXT,
    email TEXT UNIQUE,
    hired_at DATE,
    active BOOLEAN DEFAULT true
);

-- Account types
CREATE TABLE account_types (
    id SMALLINT PRIMARY KEY,
    name TEXT NOT NULL,
    interest_rate NUMERIC(6,4) DEFAULT 0,
    description TEXT
);

INSERT INTO account_types (id, name, interest_rate, description)
VALUES (1,'checking',0,'Standard checking account'), (2,'savings',0.01,'Interest-bearing savings');

-- Accounts
CREATE TABLE accounts (
    id BIGSERIAL PRIMARY KEY,
    account_number TEXT UNIQUE NOT NULL,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    branch_id BIGINT REFERENCES branches(id),
    type_id SMALLINT NOT NULL REFERENCES account_types(id),
    currency CHAR(3) DEFAULT 'USD',
    balance NUMERIC(18,2) DEFAULT 0 NOT NULL,
    overdraft_limit NUMERIC(18,2) DEFAULT 0,
    status TEXT DEFAULT 'open',
    opened_at TIMESTAMPTZ DEFAULT now(),
    closed_at TIMESTAMPTZ
);

CREATE INDEX idx_accounts_customer ON accounts(customer_id);
CREATE INDEX idx_accounts_account_number ON accounts(account_number);

-- Transactions
CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    tx_uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    from_account_id BIGINT REFERENCES accounts(id) ON DELETE SET NULL,
    to_account_id BIGINT REFERENCES accounts(id) ON DELETE SET NULL,
    amount NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) DEFAULT 'USD',
    type TEXT NOT NULL, -- deposit, withdrawal, transfer, payment, fee, interest, reversal
    status TEXT NOT NULL DEFAULT 'pending', -- pending, posted, reversed, failed
    description TEXT,
    metadata JSONB,
    initiated_by_employee_id BIGINT REFERENCES employees(id),
    initiated_by_customer_id BIGINT REFERENCES customers(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    posted_at TIMESTAMPTZ,
    from_balance_before NUMERIC(18,2),
    from_balance_after NUMERIC(18,2),
    to_balance_before NUMERIC(18,2),
    to_balance_after NUMERIC(18,2)
);

CREATE INDEX idx_tx_from_account ON transactions(from_account_id);
CREATE INDEX idx_tx_to_account ON transactions(to_account_id);
CREATE INDEX idx_tx_created_at ON transactions(created_at DESC);

-- Loans
CREATE TABLE loans (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT REFERENCES accounts(id) ON DELETE CASCADE,
    principal NUMERIC(18,2) NOT NULL,
    balance NUMERIC(18,2) NOT NULL,
    interest_rate NUMERIC(6,4) NOT NULL,
    start_date DATE,
    end_date DATE,
    status TEXT DEFAULT 'active'
);

-- Cards
CREATE TABLE cards (
    id BIGSERIAL PRIMARY KEY,
    card_number TEXT NOT NULL UNIQUE,
    account_id BIGINT REFERENCES accounts(id) ON DELETE CASCADE,
    card_type TEXT, -- debit, credit
    status TEXT DEFAULT 'active',
    expiry_date DATE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Card transactions (POS)
CREATE TABLE card_transactions (
    id BIGSERIAL PRIMARY KEY,
    card_id BIGINT REFERENCES cards(id) ON DELETE CASCADE,
    merchant TEXT,
    amount NUMERIC(18,2) NOT NULL,
    currency CHAR(3) DEFAULT 'USD',
    txn_time TIMESTAMPTZ DEFAULT now(),
    status TEXT DEFAULT 'authorized'
);

-- Audit logs
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    who TEXT,
    action TEXT,
    table_name TEXT,
    row_id TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Simple helper function to generate account numbers
CREATE OR REPLACE FUNCTION generate_account_number() RETURNS TEXT AS $$
DECLARE
  seq BIGINT;
BEGIN
  SELECT nextval('accounts_id_seq') INTO seq;
  RETURN to_char(now(),'YY') || lpad(seq::text,10,'0');
END;
$$ LANGUAGE plpgsql;

-- Use trigger to set account_number if not provided
CREATE OR REPLACE FUNCTION trg_set_account_number() RETURNS trigger AS $$
BEGIN
  IF NEW.account_number IS NULL THEN
    NEW.account_number := generate_account_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_account_number BEFORE INSERT ON accounts
FOR EACH ROW EXECUTE FUNCTION trg_set_account_number();

-- Make sure balances and transactions are posted consistently via triggers (see triggers.sql for implementation)
