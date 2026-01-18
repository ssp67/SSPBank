# Bank Schema ERD (Mermaid)

```mermaid
erDiagram
    SEGMENTS {
        SMALLSERIAL id PK
        TEXT code
        TEXT name
    }

    PERSONAL_CUSTOMERS {
        BIGSERIAL id PK
        TEXT first_name
        TEXT last_name
        DATE dob
        TEXT email
        TEXT phone
        SMALLINT segment_id FK
    }

    PERSONAL_IDENTIFICATIONS {
        BIGSERIAL id PK
        BIGINT customer_id FK
        TEXT id_type
        TEXT id_value
    }

    PERSONAL_ADDRESSES {
        BIGSERIAL id PK
        BIGINT customer_id FK
        TEXT civic_number
        TEXT street_name
        TEXT street_type
        TEXT city
        CHAR(2) province FK
        TEXT postal_code
    }

    EDUCATION {
        BIGSERIAL id PK
        BIGINT customer_id FK
        TEXT institution_name
        TEXT degree
        TEXT field
    }

    EMPLOYMENT {
        BIGSERIAL id PK
        BIGINT customer_id FK
        TEXT employer_name
        TEXT title
        NUM income
    }

    PROVINCES {
        CHAR(2) code PK
        TEXT name
    }

    COMPANIES {
        BIGSERIAL id PK
        TEXT name
        TEXT registration_number
        TEXT tax_id
        TEXT business_structure_code
        TEXT naics_code
    }

    PARTIES {
        BIGSERIAL id PK
        TEXT party_type
        BIGINT personal_customer_id FK
        BIGINT company_id FK
    }

    BRANCHES {
        BIGSERIAL id PK
        TEXT name
        TEXT address
        TEXT civic_number
        TEXT street_name
        TEXT street_type
        TEXT city
        CHAR(2) province FK
        TEXT postal_code
        TEXT branch_transit
    }

    HR_ROLES {
        SERIAL id PK
        TEXT code
        TEXT name
    }

    EMPLOYEES {
        BIGSERIAL id PK
        BIGINT personal_customer_id FK
        TEXT employee_number
        INT hr_role_id FK
        BIGINT branch_id FK
        TEXT first_name
        TEXT last_name
        TEXT role
        TEXT email
    }

    ACCOUNT_TYPES {
        TEXT id PK
        TEXT name
        TEXT description
    }

    ACCOUNTS {
        BIGSERIAL id PK
        TEXT account_number
        BIGINT branch_id FK
        TEXT type_id FK
        CHAR(3) currency
        NUM balance
        TEXT status
        TIMESTAMP opened_at
        TIMESTAMP closed_at
    }

    PARTY_ACCOUNT_RELN {
        BIGINT party_id FK
        BIGINT account_id FK
        TEXT role
        NUM ownership_percent
    }

    BANK_ACCOUNTS {
        BIGINT account_id PK, FK
        TEXT bank_account_type
        NUM overdraft_limit
        NUM interest_rate
    }

    MORTGAGES {
        BIGINT account_id PK, FK
        NUM principal
        NUM interest_rate
        DATE start_date
        DATE end_date
        TEXT status
    }

    PLC_ACCOUNTS {
        BIGINT account_id PK, FK
        NUM credit_limit
        NUM interest_rate
        TEXT status
    }

    INVESTMENT_ACCOUNTS {
        BIGINT account_id PK, FK
        TEXT registration_type
        TEXT name
        TIMESTAMP created_at
    }

    TRANSACTIONS {
        BIGSERIAL id PK
        UUID tx_uuid
        BIGINT from_account_id FK
        BIGINT to_account_id FK
        NUM amount
        CHAR(3) currency
        TEXT type
        TEXT status
        BIGINT initiated_by_employee_id FK
        BIGINT initiated_by_customer_id FK
        TIMESTAMP created_at
        TIMESTAMP posted_at
    }

    LOANS {
        BIGINT account_id PK, FK
        NUM principal
        NUM balance
        NUM interest_rate
        DATE start_date
        DATE end_date
        TEXT status
    }

    GIC_INV {
        BIGSERIAL id PK
        BIGINT investment_account_id FK
        NUM principal
        NUM interest_rate
        INT term_months
        DATE maturity_date
    }

    MUTUAL_FUND_INV {
        BIGSERIAL id PK
        BIGINT investment_account_id FK
        TEXT fund_name
        NUM units
        NUM nav
        CHAR(3) currency
    }

    EQUITY_INV {
        BIGSERIAL id PK
        BIGINT investment_account_id FK
        TEXT symbol
        NUM shares
        NUM avg_price
        CHAR(3) currency
    }

    INVESTMENT_SAVINGS_INV {
        BIGSERIAL id PK
        BIGINT investment_account_id FK
        NUM balance
        NUM interest_rate
        CHAR(3) currency
    }
    CARDS {
        TEXT card_number
        BIGINT account_id PK, FK
        TEXT card_type
        TEXT status
        NUM interest_rate
        DATE expiry_date
        TIMESTAMP created_at
    }

    CARD_TRANSACTIONS {
        BIGSERIAL id PK
        BIGINT card_id FK
        TEXT merchant
        NUM amount
        CHAR(3) currency
        TEXT status
        TIMESTAMP txn_time
    }

    AUDIT_LOGS {
        BIGSERIAL id PK
        TEXT who
        TEXT action
        TEXT table_name
        TEXT row_id
        JSONB details
        TIMESTAMP created_at
    }

    SEGMENTS ||--o{ PERSONAL_CUSTOMERS : segments
    PERSONAL_CUSTOMERS ||--o{ PERSONAL_IDENTIFICATIONS : has_ids
    PERSONAL_CUSTOMERS ||--o{ PERSONAL_ADDRESSES : has_addresses
    PERSONAL_CUSTOMERS ||--o{ EDUCATION : has_education
    PERSONAL_CUSTOMERS ||--o{ EMPLOYMENT : has_employment
    PROVINCES ||--o{ PERSONAL_ADDRESSES : in_province
    PROVINCES ||--o{ BRANCHES : in_province
    PERSONAL_CUSTOMERS ||--o{ PARTIES : as_person
    COMPANIES ||--o{ PARTIES : as_company
    BRANCHES ||--o{ ACCOUNTS : hosts
    BRANCHES ||--o{ EMPLOYEES : employs
    HR_ROLES ||--o{ EMPLOYEES : assigns
    PERSONAL_CUSTOMERS ||--o{ EMPLOYEES : linked_person
    ACCOUNT_TYPES ||--o{ ACCOUNTS : defines
    PARTIES ||--o{ PARTY_ACCOUNT_RELN : relates
    ACCOUNTS ||--o{ PARTY_ACCOUNT_RELN : relates
    ACCOUNTS ||--o| BANK_ACCOUNTS : subtype
    ACCOUNTS ||--o| MORTGAGES : subtype
    ACCOUNTS ||--o| PLC_ACCOUNTS : subtype
    ACCOUNTS ||--o| INVESTMENT_ACCOUNTS : subtype
    ACCOUNTS ||--o{ TRANSACTIONS : "from_account"
    ACCOUNTS ||--o{ TRANSACTIONS : "to_account"
    EMPLOYEES ||--o{ TRANSACTIONS : initiates
    PERSONAL_CUSTOMERS ||--o{ TRANSACTIONS : initiates
    ACCOUNTS ||--o| LOANS : subtype
    ACCOUNTS ||--o| CARDS : subtype
    CARDS ||--o{ CARD_TRANSACTIONS : has_transactions
    INVESTMENT_ACCOUNTS ||--o{ GIC_INV : has
    INVESTMENT_ACCOUNTS ||--o{ MUTUAL_FUND_INV : has
    INVESTMENT_ACCOUNTS ||--o{ EQUITY_INV : has
    INVESTMENT_ACCOUNTS ||--o{ INVESTMENT_SAVINGS_INV : has

    %% Audit logs are generic records tied to table names
    AUDIT_LOGS }o--|| PERSONAL_CUSTOMERS : audits
    AUDIT_LOGS }o--|| ACCOUNTS : audits
    AUDIT_LOGS }o--|| TRANSACTIONS : audits

    PRODUCT_CATEGORIES {
        TEXT id PK
        TEXT name
        TEXT description
    }

    PRODUCT_CATALOGUE {
        BIGSERIAL id PK
        TEXT category_id FK
        TEXT product_code
        TEXT name
        TEXT description
        CHAR(3) currency
        NUM price
        NUM interest_rate
        INT term_months
        TEXT status
        TIMESTAMP created_at
    }

    PRODUCT_CATEGORIES ||--o{ PRODUCT_CATALOGUE : contains
```

Notes:

- Render this with a Mermaid-capable renderer (e.g., VS Code Mermaid Preview or GitHub Markdown).
- The diagram shows primary keys (PK) and foreign keys (FK) and cardinality hints.
