--liquibase formatted sql

--changeset poc:001-create-customers
--comment: Customers table
CREATE TABLE customers (
    customer_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email        VARCHAR(255) NOT NULL UNIQUE,
    full_name    VARCHAR(200) NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);
--rollback DROP TABLE customers;
