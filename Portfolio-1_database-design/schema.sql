
CREATE TABLE customers (
    customer_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE addresses (
    address_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    street       VARCHAR(150) NOT NULL,
    city         VARCHAR(80)  NOT NULL,
    state        VARCHAR(80),
    country      VARCHAR(80)  NOT NULL,
    postal_code  VARCHAR(20),
    is_default   BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE categories (
    category_id        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name               VARCHAR(80) NOT NULL UNIQUE,
    parent_category_id INT REFERENCES categories(category_id) ON DELETE SET NULL
);

CREATE TABLE products (
    product_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id    INT NOT NULL REFERENCES categories(category_id),
    sku            VARCHAR(40)  NOT NULL UNIQUE,
    name           VARCHAR(150) NOT NULL,
    description    TEXT,
    price          NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id         INT NOT NULL REFERENCES customers(customer_id),
    shipping_address_id INT NOT NULL REFERENCES addresses(address_id),
    order_date          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status              VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','PAID','SHIPPED','DELIVERED','CANCELLED')),
    total_amount        NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0)
);

CREATE TABLE order_items (
    order_id   INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id),
    quantity   INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE payments (
    payment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id   INT NOT NULL REFERENCES orders(order_id),
    method     VARCHAR(20) NOT NULL
        CHECK (method IN ('CARD','BANK_TRANSFER','WALLET','CASH_ON_DELIVERY')),
    amount     NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    status     VARCHAR(15) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','SUCCESSFUL','FAILED','REFUNDED')),
    paid_at    TIMESTAMP
);

CREATE TABLE deliveries (
    delivery_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id        INT NOT NULL UNIQUE REFERENCES orders(order_id),
    courier         VARCHAR(80),
    tracking_number VARCHAR(50) UNIQUE,
    status          VARCHAR(20) NOT NULL DEFAULT 'PROCESSING'
        CHECK (status IN ('PROCESSING','IN_TRANSIT','DELIVERED','FAILED')),
    shipped_at      TIMESTAMP,
    delivered_at    TIMESTAMP,
    CHECK (delivered_at IS NULL OR shipped_at IS NULL OR delivered_at >= shipped_at)
);
