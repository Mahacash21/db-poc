--liquibase formatted sql

--changeset poc:002-create-orders
--comment: Orders table, linked to customers
CREATE TABLE orders (
    order_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  BIGINT        NOT NULL REFERENCES customers (customer_id),
    order_total  NUMERIC(12,2) NOT NULL CHECK (order_total >= 0),
    status       VARCHAR(20)   NOT NULL DEFAULT 'NEW',
    ordered_at   TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX ix_orders_customer_id ON orders (customer_id);
--rollback DROP TABLE orders;
