-- Main schema (subset copied from schema/bank_schema.sql). This file is executed by the container at DB bootstrap.

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Customer segments
CREATE TABLE segments (
    id SMALLSERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT
);

-- Personal customers (renamed from `customers`)
CREATE TABLE personal_customers (
    id BIGSERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    dob DATE,
    email TEXT UNIQUE,
    phone TEXT,
    country TEXT DEFAULT 'CA',
    segment_id SMALLINT REFERENCES segments(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    status TEXT DEFAULT 'active'
);

-- Customer identifications
CREATE TABLE personal_identifications (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES personal_customers(id) ON DELETE CASCADE,
    id_type TEXT NOT NULL,
    id_value TEXT NOT NULL,
    issued_by TEXT,
    issued_at DATE,
    expires_at DATE,
    metadata JSONB
);

-- Provinces (Canadian provinces/territories)
CREATE TABLE provinces (
    code CHAR(2) PRIMARY KEY,
    name TEXT NOT NULL
);

INSERT INTO provinces (code, name) VALUES
('AB','Alberta'),('BC','British Columbia'),('MB','Manitoba'),('NB','New Brunswick'),('NL','Newfoundland and Labrador'),('NS','Nova Scotia'),('ON','Ontario'),('PE','Prince Edward Island'),('QC','Quebec'),('SK','Saskatchewan'),('NT','Northwest Territories'),('NU','Nunavut'),('YT','Yukon')
ON CONFLICT DO NOTHING;

-- Customer addresses
CREATE TABLE personal_addresses (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES personal_customers(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    unit TEXT,
    civic_number TEXT,
    street_name TEXT,
    street_type TEXT,
    city TEXT,
    province CHAR(2) REFERENCES provinces(code),
    postal_code TEXT,
    country TEXT DEFAULT 'CA',
    effective_from DATE,
    effective_to DATE
);

-- Education history
CREATE TABLE education (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES personal_customers(id) ON DELETE CASCADE,
    institution_name TEXT NOT NULL,
    degree TEXT,
    field TEXT,
    start_date DATE,
    end_date DATE,
    notes TEXT
);

-- Employment history
CREATE TABLE employment (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES personal_customers(id) ON DELETE CASCADE,
    employer_name TEXT NOT NULL,
    title TEXT,
    start_date DATE,
    end_date DATE,
    income NUMERIC(18,2),
    notes TEXT
);

-- Companies (business customers)
CREATE TABLE IF NOT EXISTS companies (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    registration_number TEXT UNIQUE,
    tax_id TEXT,
    business_structure_code TEXT,
    naics_code TEXT,
    country TEXT DEFAULT 'CA',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Parties (either personal or company)
CREATE TABLE parties (
    id BIGSERIAL PRIMARY KEY,
    party_type TEXT NOT NULL CHECK (party_type IN ('personal','company')),
    personal_customer_id BIGINT UNIQUE REFERENCES personal_customers(id) ON DELETE CASCADE,
    company_id BIGINT UNIQUE REFERENCES companies(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    CHECK (
        (personal_customer_id IS NOT NULL AND company_id IS NULL) OR
        (personal_customer_id IS NULL AND company_id IS NOT NULL)
    )
);

-- Branches
CREATE TABLE branches (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    civic_number TEXT,
    street_name TEXT,
    street_type TEXT,
    city TEXT,
    province CHAR(2) REFERENCES provinces(code),
    postal_code TEXT,
    country TEXT DEFAULT 'CA',
    branch_transit TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- HR roles
CREATE TABLE hr_roles (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Employees
CREATE TABLE employees (
    id BIGSERIAL PRIMARY KEY,
    personal_customer_id BIGINT REFERENCES personal_customers(id) ON DELETE SET NULL,
    employee_number TEXT UNIQUE,
    hr_role_id INTEGER REFERENCES hr_roles(id),
    branch_id BIGINT REFERENCES branches(id) ON DELETE SET NULL,
    first_name TEXT,
    last_name TEXT,
    role TEXT,
    email TEXT UNIQUE,
    hired_at DATE,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Account types
CREATE TABLE account_types (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT
);

INSERT INTO account_types (id, name, description)
VALUES
('CHEQUING','Chequing','Standard chequing account'),
('SAVINGS','Savings','Interest-bearing savings'),
('MORTGAGE','Mortgage','Mortgage account'),
('PLC','Personal Line of Credit','Personal line of credit'),
('INVESTMENT','Investment','Investment account');

-- Accounts
CREATE TABLE accounts (
    id BIGSERIAL PRIMARY KEY,
    account_number TEXT UNIQUE NOT NULL,
    branch_id BIGINT REFERENCES branches(id),
    type_id TEXT NOT NULL REFERENCES account_types(id),
    currency CHAR(3) DEFAULT 'CAD',
    balance NUMERIC(18,2) DEFAULT 0 NOT NULL,
    status TEXT DEFAULT 'open',
    opened_at TIMESTAMPTZ DEFAULT now(),
    closed_at TIMESTAMPTZ
);

CREATE INDEX idx_accounts_account_number ON accounts(account_number);

-- Party-account relationships (many-to-many between accounts and parties)
CREATE TABLE party_account_reln (
    party_id BIGINT NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    ownership_percent NUMERIC(5,2),
    PRIMARY KEY (party_id, account_id),
    CHECK (role <> 'owner' OR ownership_percent IS NOT NULL)
);

CREATE INDEX idx_party_account_reln_party ON party_account_reln(party_id);
CREATE INDEX idx_party_account_reln_account ON party_account_reln(account_id);

-- Account subtypes
CREATE TABLE bank_accounts (
    account_id BIGINT PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    bank_account_type TEXT NOT NULL CHECK (bank_account_type IN ('chequing','savings')),
    overdraft_limit NUMERIC(18,2) DEFAULT 0,
    interest_rate NUMERIC(6,4) DEFAULT 0
);

CREATE TABLE mortgages (
    account_id BIGINT PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    principal NUMERIC(18,2) NOT NULL,
    interest_rate NUMERIC(6,4) NOT NULL,
    start_date DATE,
    end_date DATE,
    status TEXT DEFAULT 'active'
);

CREATE TABLE plc_accounts (
    account_id BIGINT PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    credit_limit NUMERIC(18,2) NOT NULL,
    interest_rate NUMERIC(6,4) NOT NULL,
    status TEXT DEFAULT 'active'
);


-- Transactions
CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    tx_uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    from_account_id BIGINT REFERENCES accounts(id) ON DELETE SET NULL,
    to_account_id BIGINT REFERENCES accounts(id) ON DELETE SET NULL,
    amount NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) DEFAULT 'CAD',
    type TEXT NOT NULL, -- deposit, withdrawal, transfer, payment, fee, interest, reversal
    status TEXT NOT NULL DEFAULT 'pending', -- pending, posted, reversed, failed
    description TEXT,
    metadata JSONB,
    initiated_by_employee_id BIGINT REFERENCES employees(id),
    initiated_by_customer_id BIGINT REFERENCES personal_customers(id),
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
    account_id BIGINT PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    principal NUMERIC(18,2) NOT NULL,
    balance NUMERIC(18,2) NOT NULL,
    interest_rate NUMERIC(6,4) NOT NULL,
    start_date DATE,
    end_date DATE,
    status TEXT DEFAULT 'active'
);

CREATE TABLE investment_accounts (
    account_id BIGINT PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    registration_type TEXT NOT NULL,
    name TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE gic_inv (
    id BIGSERIAL PRIMARY KEY,
    investment_account_id BIGINT NOT NULL REFERENCES investment_accounts(account_id) ON DELETE CASCADE,
    principal NUMERIC(18,2) NOT NULL,
    interest_rate NUMERIC(6,4) NOT NULL,
    term_months INT,
    maturity_date DATE
);

CREATE TABLE mutual_fund_inv (
    id BIGSERIAL PRIMARY KEY,
    investment_account_id BIGINT NOT NULL REFERENCES investment_accounts(account_id) ON DELETE CASCADE,
    fund_name TEXT NOT NULL,
    units NUMERIC(18,6) NOT NULL,
    nav NUMERIC(18,6),
    currency CHAR(3) DEFAULT 'CAD'
);

CREATE TABLE equity_inv (
    id BIGSERIAL PRIMARY KEY,
    investment_account_id BIGINT NOT NULL REFERENCES investment_accounts(account_id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    shares NUMERIC(18,6) NOT NULL,
    avg_price NUMERIC(18,6),
    currency CHAR(3) DEFAULT 'CAD'
);

CREATE TABLE investment_savings_inv (
    id BIGSERIAL PRIMARY KEY,
    investment_account_id BIGINT NOT NULL REFERENCES investment_accounts(account_id) ON DELETE CASCADE,
    balance NUMERIC(18,2) NOT NULL,
    interest_rate NUMERIC(6,4),
    currency CHAR(3) DEFAULT 'CAD'
);
-- Cards
CREATE TABLE cards (
    card_number TEXT NOT NULL UNIQUE,
    account_id BIGINT PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    card_type TEXT, -- debit, credit
    status TEXT DEFAULT 'active',
    interest_rate NUMERIC(6,4) DEFAULT 0,
    expiry_date DATE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Card transactions (POS)
CREATE TABLE card_transactions (
    id BIGSERIAL PRIMARY KEY,
    card_id BIGINT REFERENCES cards(account_id) ON DELETE CASCADE,
    merchant TEXT,
    amount NUMERIC(18,2) NOT NULL,
    currency CHAR(3) DEFAULT 'CAD',
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

-- Product catalogue (categories + products)
CREATE TABLE product_categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE product_catalogue (
    id BIGSERIAL PRIMARY KEY,
    category_id TEXT NOT NULL REFERENCES product_categories(id) ON DELETE RESTRICT,
    product_code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    currency CHAR(3) DEFAULT 'CAD',
    price NUMERIC(18,2) DEFAULT 0,
    interest_rate NUMERIC(6,4),
    term_months INT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Helper function to generate account numbers
CREATE OR REPLACE FUNCTION generate_account_number() RETURNS TEXT AS $$
DECLARE
  seq BIGINT;
BEGIN
  SELECT nextval('accounts_id_seq') INTO seq;
  RETURN to_char(now(),'YY') || lpad(seq::text,10,'0');
END;
$$ LANGUAGE plpgsql;

-- Trigger to set account_number
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
