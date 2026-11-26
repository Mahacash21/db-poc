--liquibase formatted sql

--changeset poc:003-seed-customers
--comment: Sample rows so there is something to query
INSERT INTO customers (email, full_name) VALUES
    ('ada@example.com',   'Ada Lovelace'),
    ('grace@example.com', 'Grace Hopper');
--rollback DELETE FROM customers WHERE email IN ('ada@example.com', 'grace@example.com');
