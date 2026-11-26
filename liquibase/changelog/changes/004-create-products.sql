--liquibase formatted sql

--changeset apurva:004-create-products
CREATE TABLE products (
    product_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku         VARCHAR(50)   NOT NULL UNIQUE,
    name        VARCHAR(200)  NOT NULL,
    price       NUMERIC(12,2) NOT NULL
);
--rollback DROP TABLE products;
