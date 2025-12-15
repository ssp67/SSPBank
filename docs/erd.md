# Bank Schema ERD (Mermaid)

```mermaid
erDiagram
    CUSTOMERS {
        BIGSERIAL id PK
        TEXT first_name
        TEXT last_name
        DATE dob
        TEXT email
    }

    BRANCHES {
        BIGSERIAL id PK
        TEXT name
        TEXT address
        TEXT city
    }

    EMPLOYEES {
        BIGSERIAL id PK
        BIGINT branch_id FK
        TEXT first_name
        TEXT last_name
        TEXT role
    }

    ACCOUNT_TYPES {
        SMALLINT id PK
        TEXT name
        NUM interest_rate
    }

    ACCOUNTS {
        BIGSERIAL id PK
        TEXT account_number
        BIGINT branch_id FK
        SMALLINT type_id FK
        NUM balance
        NUM overdraft_limit
    }

    ACCOUNT_OWNERS {
        BIGINT account_id FK
        BIGINT customer_id FK
        BOOL is_primary
        NUM ownership_percent
    }

    TRANSACTIONS {
        BIGSERIAL id PK
        UUID tx_uuid
        BIGINT from_account_id FK
        BIGINT to_account_id FK
        NUM amount
        TEXT type
        TEXT status
        TIMESTAMP created_at
    }

    LOANS {
        BIGSERIAL id PK
        BIGINT account_id FK
        NUM principal
        NUM balance
    }

    CARDS {
        BIGSERIAL id PK
        TEXT card_number
        BIGINT account_id FK
        TEXT card_type
    }

    CARD_TRANSACTIONS {
        BIGSERIAL id PK
        BIGINT card_id FK
        NUM amount
        TIMESTAMP txn_time
    }

    AUDIT_LOGS {
        BIGSERIAL id PK
        TEXT who
        TEXT action
        TEXT table_name
        JSONB details
        TIMESTAMP created_at
    }

    CUSTOMERS ||--o{ ACCOUNT_OWNERS : owns
    ACCOUNTS ||--o{ ACCOUNT_OWNERS : has_owners
    BRANCHES ||--o{ ACCOUNTS : hosts
    ACCOUNT_TYPES ||--o{ ACCOUNTS : defines
    ACCOUNTS ||--o{ TRANSACTIONS : "from_account"
    ACCOUNTS ||--o{ TRANSACTIONS : "to_account"
    ACCOUNTS ||--o{ LOANS : has
    ACCOUNTS ||--o{ CARDS : has
    CARDS ||--o{ CARD_TRANSACTIONS : "has transactions"
    BRANCHES ||--o{ EMPLOYEES : employs
    EMPLOYEES ||--o{ TRANSACTIONS : initiates
    CUSTOMERS ||--o{ TRANSACTIONS : initiates

    %% Audit logs are generic records tied to table names
    AUDIT_LOGS }o--|| CUSTOMERS : "audits"
    AUDIT_LOGS }o--|| ACCOUNTS : "audits"
    AUDIT_LOGS }o--|| TRANSACTIONS : "audits"

    PRODUCT_CATEGORIES {
        SMALLSERIAL id PK
        TEXT name
    }

    PRODUCT_CATALOGUE {
        BIGSERIAL id PK
        SMALLINT category_id FK
        TEXT product_code
        TEXT name
        NUM price
        NUM interest_rate
        INT term_months
    }

    PRODUCT_CATEGORIES ||--o{ PRODUCT_CATALOGUE : contains
    PRODUCT_CATALOGUE }o--|| ACCOUNTS : "can be linked (optional)"
```

Notes:
- Render this with a Mermaid-capable renderer (e.g., VS Code Mermaid Preview or GitHub Markdown).
- The diagram shows primary keys (PK) and foreign keys (FK) and cardinality hints.
