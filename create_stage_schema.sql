USE DATABASE CHINOOK_DB;
CREATE SCHEMA IF NOT EXISTS STAGE;

-- CUSTOMER
CREATE OR REPLACE TABLE STAGE.CUSTOMER (
    CustomerId INT,
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    Company VARCHAR(100),
    Address VARCHAR(255),
    City VARCHAR(100),
    State VARCHAR(100),
    Country VARCHAR(100),
    PostalCode VARCHAR(20),
    Phone VARCHAR(20),
    Fax VARCHAR(20),
    Email VARCHAR(100),
    SupportRepId INT
);

-- ARTIST
CREATE OR REPLACE TABLE STAGE.ARTIST (
    ArtistId INT,
    Name VARCHAR(100)
);

-- ALBUM
CREATE OR REPLACE TABLE STAGE.ALBUM (
    AlbumId INT,
    Title VARCHAR(200),
    ArtistId INT
);

-- INVOICE
CREATE OR REPLACE TABLE STAGE.INVOICE (
    InvoiceId INT,
    CustomerId INT,
    InvoiceDate TIMESTAMP_NTZ,
    BillingAddress VARCHAR(255),
    BillingCity VARCHAR(100),
    BillingState VARCHAR(100),
    BillingCountry VARCHAR(100),
    BillingPostalCode VARCHAR(20),
    Total NUMBER(10,2)
);
