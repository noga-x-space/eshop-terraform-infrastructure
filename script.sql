DROP DATABASE IF EXISTS NogaShop;
CREATE DATABASE NogaShop;

SELECT
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    a.attname AS column_name,
    confrelid::regclass AS foreign_table_name,
    af.attname AS foreign_column_name
FROM
    pg_constraint AS c
    JOIN pg_attribute AS a ON a.attnum = ANY(c.conkey)
    JOIN pg_attribute AS af ON af.attnum = ANY(c.confkey)
WHERE
    c.contype = 'f';

CREATE SEQUENCE IF NOT EXISTS public.categories_category_id_seq;
CREATE SEQUENCE IF NOT EXISTS public.ratings_rating_id_seq;
CREATE SEQUENCE IF NOT EXISTS public.purchases_purchase_id_seq;
CREATE SEQUENCE IF NOT EXISTS public.purchasedetails_purchase_details_id_seq;

-- Table: public.categories

-- DROP TABLE IF EXISTS public.categories;

CREATE TABLE IF NOT EXISTS public.categories
(
    category_id integer NOT NULL DEFAULT nextval('categories_category_id_seq'::regclass),
    category character varying(255) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT categories_pkey PRIMARY KEY (category_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.categories
    OWNER to postgres;


-- Table: public.users

-- DROP TABLE IF EXISTS public.users;

CREATE TABLE IF NOT EXISTS public.users
(
    user_name character varying(30) COLLATE pg_catalog."default" NOT NULL,
    hashed_password character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT users_pkey PRIMARY KEY (user_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.users
    OWNER to postgres;

-- Table: public.products

-- DROP TABLE IF EXISTS public.products;

CREATE TABLE IF NOT EXISTS public.products
(
    product_name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    description character varying(255) COLLATE pg_catalog."default",
    price character varying(255) COLLATE pg_catalog."default",
    category character varying(255) COLLATE pg_catalog."default",
    quantity_in_stock integer NOT NULL,
    purchased_units integer NOT NULL DEFAULT 0,
    in_how_many_carts integer NOT NULL DEFAULT 0,
    different_users_purchased integer DEFAULT 0,
    same_users_purchased integer DEFAULT 0,
    date character varying(300) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_DATE,
    category_id integer,
    image bytea,
    CONSTRAINT products_pkey PRIMARY KEY (product_name),
    CONSTRAINT fk_category_id FOREIGN KEY (category_id)
        REFERENCES public.categories (category_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.products
    OWNER to postgres;

-- Table: public.ratings

-- DROP TABLE IF EXISTS public.ratings;

CREATE TABLE IF NOT EXISTS public.ratings
(
    rating_id integer NOT NULL DEFAULT nextval('ratings_rating_id_seq'::regclass),
    product_name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    user_name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    rating numeric(3,1) NOT NULL,
    CONSTRAINT ratings_pkey PRIMARY KEY (rating_id),
    CONSTRAINT unique_rating UNIQUE (product_name, user_name),
    CONSTRAINT ratings_product_name_fkey FOREIGN KEY (product_name)
        REFERENCES public.products (product_name) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT ratings_user_name_fkey FOREIGN KEY (user_name)
        REFERENCES public.users (user_name) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT ratings_rating_check CHECK (rating >= 1::numeric AND rating <= 5::numeric)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.ratings
    OWNER to postgres;

-- Table: public.purchases

-- DROP TABLE IF EXISTS public.purchases;

CREATE TABLE IF NOT EXISTS public.purchases
(
    purchase_id integer NOT NULL DEFAULT nextval('purchases_purchase_id_seq'::regclass),
    user_name character varying(255) COLLATE pg_catalog."default",
    purchase_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT purchases_pkey PRIMARY KEY (purchase_id),
    CONSTRAINT purchases_user_name_fkey FOREIGN KEY (user_name)
        REFERENCES public.users (user_name) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.purchases
    OWNER to postgres;

-- Table: public.purchasedetails

-- DROP TABLE IF EXISTS public.purchasedetails;

CREATE TABLE IF NOT EXISTS public.purchasedetails
(
    purchase_details_id integer NOT NULL DEFAULT nextval('purchasedetails_purchase_details_id_seq'::regclass),
    purchase_id integer NOT NULL,
    user_name character varying(255) COLLATE pg_catalog."default",
    product_name character varying(255) COLLATE pg_catalog."default",
    quantity integer NOT NULL,
    category_id integer,
    CONSTRAINT purchasedetails_pkey PRIMARY KEY (purchase_details_id),
    CONSTRAINT fk_category_id FOREIGN KEY (category_id)
        REFERENCES public.categories (category_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT purchasedetails_product_name_fkey FOREIGN KEY (product_name)
        REFERENCES public.products (product_name) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT purchasedetails_purchase_id_fkey FOREIGN KEY (purchase_id)
        REFERENCES public.purchases (purchase_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT purchasedetails_user_name_fkey FOREIGN KEY (user_name)
        REFERENCES public.users (user_name) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.purchasedetails
    OWNER to postgres;

-- Table: public.carts

-- DROP TABLE IF EXISTS public.carts;

CREATE TABLE IF NOT EXISTS public.carts
(
    cart_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    user_name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT carts_pkey PRIMARY KEY (cart_id),
    CONSTRAINT fk_user_name FOREIGN KEY (user_name)
        REFERENCES public.users (user_name) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.carts
    OWNER to postgres;

-- Table: public.cartdetails

-- DROP TABLE IF EXISTS public.cartdetails;

CREATE TABLE IF NOT EXISTS public.cartdetails
(
    cart_details_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    cart_id integer NOT NULL,
    product_name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    quantity integer NOT NULL DEFAULT 0,
    user_name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    category_id integer,
    CONSTRAINT cartdetails_pkey PRIMARY KEY (cart_details_id),
    CONSTRAINT fk_cart_id FOREIGN KEY (cart_id)
        REFERENCES public.carts (cart_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_category_id FOREIGN KEY (category_id)
        REFERENCES public.categories (category_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_product_name FOREIGN KEY (product_name)
        REFERENCES public.products (product_name) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_user_name FOREIGN KEY (user_name)
        REFERENCES public.users (user_name) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT cartdetails_quantity_check CHECK (quantity >= 0)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.cartdetails
    OWNER to postgres;
