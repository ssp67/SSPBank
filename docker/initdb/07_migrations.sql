-- Migration: HR roles, companies, branch address parts, and employee linking
-- This file is idempotent and safe to run multiple times

-- 1) HR Roles table
CREATE TABLE IF NOT EXISTS hr_roles (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2) Employees table (link to personal_customers). If an employees table already exists, alter it to add personal_customer_id and hr_role_id
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'employees') THEN
        CREATE TABLE employees (
            id BIGSERIAL PRIMARY KEY,
            personal_customer_id BIGINT REFERENCES personal_customers(id) ON DELETE SET NULL,
            employee_number TEXT UNIQUE,
            hr_role_id INTEGER REFERENCES hr_roles(id),
            branch_id BIGINT REFERENCES branches(id),
            first_name TEXT,
            last_name TEXT,
            role TEXT,
            email TEXT UNIQUE,
            hired_at DATE,
            active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMPTZ DEFAULT now()
        );
    ELSE
        ALTER TABLE employees
        ADD COLUMN IF NOT EXISTS personal_customer_id BIGINT REFERENCES personal_customers(id) ON DELETE SET NULL;
        ALTER TABLE employees ADD COLUMN IF NOT EXISTS employee_number TEXT UNIQUE;
        ALTER TABLE employees ADD COLUMN IF NOT EXISTS hr_role_id INTEGER REFERENCES hr_roles(id);
        ALTER TABLE employees ADD COLUMN IF NOT EXISTS first_name TEXT;
        ALTER TABLE employees ADD COLUMN IF NOT EXISTS last_name TEXT;
        ALTER TABLE employees ADD COLUMN IF NOT EXISTS role TEXT;
        ALTER TABLE employees ADD COLUMN IF NOT EXISTS email TEXT UNIQUE;
        ALTER TABLE employees ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();
    END IF;
END$$;

-- 3) Companies (non-personal_customers)
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

ALTER TABLE companies
    ADD COLUMN IF NOT EXISTS business_structure_code TEXT,
    ADD COLUMN IF NOT EXISTS naics_code TEXT;

-- 4) Branch address parts and transit column
ALTER TABLE branches
    ADD COLUMN IF NOT EXISTS civic_number TEXT,
    ADD COLUMN IF NOT EXISTS street_name TEXT,
    ADD COLUMN IF NOT EXISTS street_type TEXT,
    ADD COLUMN IF NOT EXISTS city TEXT,
    ADD COLUMN IF NOT EXISTS province CHAR(2),
    ADD COLUMN IF NOT EXISTS postal_code TEXT,
    ADD COLUMN IF NOT EXISTS branch_transit TEXT;

-- 5) Seed basic HR roles (idempotent)
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

-- 6) Seed sample companies
INSERT INTO companies (name, registration_number, tax_id, country)
VALUES
('Acme Corp','ACME-REG-0001','TAX-0001','CA'),
('Northern Supplies Inc','NOR-REG-0002','TAX-0002','CA')
ON CONFLICT (registration_number) DO NOTHING;

-- 7) Create a couple of employee personal_customers and employees entries (idempotent)
-- Add personal_customers rows for staff (if not already present)
INSERT INTO personal_customers (first_name, last_name, dob, email, phone, country, segment_id)
VALUES
('Staff','Teller','1990-01-01','staff.teller@ssbank.example.com','+14165550999','CA',(SELECT id FROM segments WHERE code='RETAIL')),
('Mary','Manager','1980-05-15','mary.manager@ssbank.example.com','+14165550998','CA',(SELECT id FROM segments WHERE code='PW'))
ON CONFLICT (email) DO NOTHING;

-- Add employees entries linked to those personal_customers
INSERT INTO employees (personal_customer_id, employee_number, hr_role_id, branch_id, hired_at)
SELECT pc.id, 'EMP0001', hr.id, b.id, '2018-07-01'
FROM personal_customers pc JOIN hr_roles hr ON hr.code='TELLER' JOIN branches b ON b.name ILIKE '%Main%' WHERE pc.email='staff.teller@ssbank.example.com'
ON CONFLICT (employee_number) DO NOTHING;

INSERT INTO employees (personal_customer_id, employee_number, hr_role_id, branch_id, hired_at)
SELECT pc.id, 'EMP0002', hr.id, b.id, '2016-09-15'
FROM personal_customers pc JOIN hr_roles hr ON hr.code='BRANCH_MANAGER' JOIN branches b ON b.name ILIKE '%Main%' WHERE pc.email='mary.manager@ssbank.example.com'
ON CONFLICT (employee_number) DO NOTHING;

-- 8) Ensure branch address parts have sample data where missing (idempotent update)
UPDATE branches SET civic_number = '100', street_name='Bay', street_type='St', city='Toronto', province='ON', postal_code='M5J 2N1', branch_transit='10001' WHERE civic_number IS NULL OR civic_number='';
