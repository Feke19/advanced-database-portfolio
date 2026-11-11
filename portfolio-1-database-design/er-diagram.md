# CashFlow ER Diagram

erDiagram
    CUSTOMERS ||--o{ ADDRESSES : has
    CUSTOMERS ||--o{ ORDERS : places
    ADDRESSES ||--o{ ORDERS : "ships to"
    CATEGORIES ||--o{ PRODUCTS : contains
    CATEGORIES ||--o{ CATEGORIES : "parent of"
    ORDERS ||--|{ ORDER_ITEMS : includes
    PRODUCTS ||--o{ ORDER_ITEMS : "appears in"
    ORDERS ||--o{ PAYMENTS : "paid by"
    ORDERS ||--o| DELIVERIES : "fulfilled by"

    CUSTOMERS {
        int customer_id PK
        string first_name
        string last_name
        string email UK
        string phone
        string password_hash
        timestamp created_at
    }
    ADDRESSES {
        int address_id PK
        int customer_id FK
        string street
        string city
        string state
        string country
        string postal_code
        boolean is_default
    }
    CATEGORIES {
        int category_id PK
        string name UK
        int parent_category_id FK
    }
    PRODUCTS {
        int product_id PK
        int category_id FK
        string sku UK
        string name
        text description
        decimal price
        int stock_quantity
        timestamp created_at
    }
    ORDERS {
        int order_id PK
        int customer_id FK
        int shipping_address_id FK
        timestamp order_date
        string status
        decimal total_amount
    }
    ORDER_ITEMS {
        int order_id PK, FK
        int product_id PK, FK
        int quantity
        decimal unit_price
    }
    PAYMENTS {
        int payment_id PK
        int order_id FK
        string method
        decimal amount
        string status
        timestamp paid_at
    }
    DELIVERIES {
        int delivery_id PK
        int order_id FK, UK
        string courier
        string tracking_number UK
        string status
        timestamp shipped_at
        timestamp delivered_at
    }
