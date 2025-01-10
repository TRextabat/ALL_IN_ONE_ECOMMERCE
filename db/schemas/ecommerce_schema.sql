-- Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enums
DROP TYPE IF EXISTS delivery_status_enum CASCADE;
CREATE TYPE delivery_status_enum AS ENUM ('Pending', 'InTransit', 'Delivered');

DROP TYPE IF EXISTS order_status_enum CASCADE;
CREATE TYPE order_status_enum AS ENUM ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled');

DROP TYPE IF EXISTS visibility_enum CASCADE;
CREATE TYPE visibility_enum AS ENUM ('Public', 'Private');

DROP TYPE IF EXISTS customer_type_enum CASCADE;
CREATE TYPE customer_type_enum AS ENUM ('Regular', 'Premium');

DROP TYPE IF EXISTS address_type_enum CASCADE;
CREATE TYPE address_type_enum AS ENUM ('DeliveryPoint', 'Other');

DROP TYPE IF EXISTS question_status_enum CASCADE;
CREATE TYPE question_status_enum AS ENUM ('Pending', 'Answered');

DROP TYPE IF EXISTS logistic_type_enum CASCADE;
CREATE TYPE logistic_type_enum AS ENUM ('MOSA_JET', 'OTHER');

DROP TYPE IF EXISTS return_status_enum CASCADE;
CREATE TYPE return_status_enum AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'RETURNED');

-- USER Table
DROP TABLE IF EXISTS "USER" CASCADE;
CREATE TABLE "USER" (
    UserID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    PhoneNumber VARCHAR(15) UNIQUE NOT NULL,
    HashedPassword VARCHAR(255) NOT NULL,
    Email VARCHAR(150) UNIQUE NOT NULL,
    MembershipDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_email_format CHECK (Email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- CUSTOMER Table
DROP TABLE IF EXISTS CUSTOMER CASCADE;
CREATE TABLE CUSTOMER (
    UserID UUID PRIMARY KEY REFERENCES "USER"(UserID) ON DELETE CASCADE,
    CustomerType customer_type_enum NOT NULL
);

-- PREMIUM Table
DROP TABLE IF EXISTS PREMIUM CASCADE;

CREATE TABLE PREMIUM (
    UserID UUID PRIMARY KEY REFERENCES CUSTOMER(UserID) ON DELETE CASCADE,
    PremiumStartDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PremiumEndDate TIMESTAMP NOT NULL,
    MembershipPlan VARCHAR(100) NOT NULL,
    CONSTRAINT chk_premium_dates CHECK (PremiumStartDate < PremiumEndDate)
);


-- ADMIN Table
DROP TABLE IF EXISTS ADMIN CASCADE;
CREATE TABLE ADMIN (
    UserID UUID PRIMARY KEY REFERENCES "USER"(UserID) ON DELETE CASCADE,
    Role VARCHAR(50) NOT NULL,
    LastLogin TIMESTAMP
);

-- PAYMENT_METHOD Table
DROP TABLE IF EXISTS PAYMENT_METHOD CASCADE;

CREATE TABLE PAYMENT_METHOD (
    PaymentID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    InstallmentCount INT CHECK (InstallmentCount >= 0),
    InstallmentAmount FLOAT CHECK (InstallmentAmount >= 0),
    InstallmentRate FLOAT CHECK (InstallmentRate >= 0),
    CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UserID UUID REFERENCES CUSTOMER(UserID) ON DELETE CASCADE
);

-- BANK_CARD Table
DROP TABLE IF EXISTS BANK_CARD CASCADE;

CREATE TABLE BANK_CARD (
    PaymentID UUID PRIMARY KEY REFERENCES PAYMENT_METHOD(PaymentID) ON DELETE CASCADE,
    CardLastFourDigits VARCHAR(4) NOT NULL,
    ExpiryDate DATE NOT NULL,
    CVV VARCHAR(3) NOT NULL,
    CardHolderName VARCHAR(100) NOT NULL,
    PaymentType VARCHAR(50) NOT NULL
);


-- SHOP Table
DROP TABLE IF EXISTS SHOP CASCADE;
CREATE TABLE SHOP (
    RegistrationNumber UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ShopDescription TEXT,
    ShopRate FLOAT CHECK (ShopRate BETWEEN 0 AND 5),
    ShopName VARCHAR(150) NOT NULL UNIQUE,
    CreationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ShopPhone VARCHAR(15)
);

-- SELLER Table
DROP TABLE IF EXISTS SELLER CASCADE;
CREATE TABLE SELLER (
    UserID UUID PRIMARY KEY REFERENCES "USER"(UserID) ON DELETE CASCADE,
    ShopID UUID REFERENCES SHOP(RegistrationNumber) ON DELETE SET NULL,
    SellerRate FLOAT CHECK (SellerRate BETWEEN 0 AND 5)
);

-- ADDRESS Table
DROP TABLE IF EXISTS ADDRESS CASCADE;
CREATE TABLE ADDRESS (
    AddressID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ZipCode VARCHAR(10),
    Neighbourhood VARCHAR(100),
    Province VARCHAR(100),
    City VARCHAR(100),
    Country VARCHAR(100),
    Flat VARCHAR(50),
    Apartment VARCHAR(50),
    AddressType address_type_enum,
    UserID UUID REFERENCES CUSTOMER(UserID) ON DELETE CASCADE
);

-- PRODUCT Table
DROP TABLE IF EXISTS PRODUCT CASCADE;
CREATE TABLE PRODUCT (
    ProductID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ProductName VARCHAR(150) NOT NULL,
    Brand VARCHAR(100),
    SKU VARCHAR(100) UNIQUE NOT NULL,
    ShortDescription VARCHAR(255),
    Description TEXT,
    IsApproved BOOLEAN DEFAULT FALSE,
    Status VARCHAR(50),
    Rating FLOAT CHECK (Rating BETWEEN 0 AND 5),
    DateAdded TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TaxClass VARCHAR(50),
    BarCode VARCHAR(50),
    BasePrice FLOAT NOT NULL CHECK (BasePrice >= 0)
);

-- CATEGORY Table
DROP TABLE IF EXISTS CATEGORY CASCADE;
CREATE TABLE CATEGORY (
    CategoryID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    CategoryName VARCHAR(100),
    MediaID UUID
);

-- SUBCATEGORY Table
DROP TABLE IF EXISTS SUBCATEGORY CASCADE;
CREATE TABLE SUBCATEGORY (
    ParentCategoryID UUID REFERENCES CATEGORY(CategoryID) ON DELETE CASCADE,
    ChildCategoryID UUID REFERENCES CATEGORY(CategoryID) ON DELETE CASCADE,
    PRIMARY KEY (ParentCategoryID, ChildCategoryID)
);

-- PRODUCT_CATEGORY Table
DROP TABLE IF EXISTS PRODUCT_CATEGORY CASCADE;
CREATE TABLE PRODUCT_CATEGORY (
    ProductID UUID REFERENCES PRODUCT(ProductID) ON DELETE CASCADE,
    CategoryID UUID REFERENCES CATEGORY(CategoryID) ON DELETE CASCADE,
    PRIMARY KEY (ProductID, CategoryID)
);

-- PRODUCT_OPTION Table
DROP TABLE IF EXISTS PRODUCT_OPTION CASCADE;
CREATE TABLE PRODUCT_OPTION (
    OptionID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    OptionName VARCHAR(100),
    IsMandatory BOOLEAN DEFAULT FALSE
);

-- OPTION_VALUE Table
DROP TABLE IF EXISTS OPTION_VALUE CASCADE;
CREATE TABLE OPTION_VALUE (
    OptionValueID UUID DEFAULT uuid_generate_v4(),
    OptionID UUID REFERENCES PRODUCT_OPTION(OptionID) ON DELETE CASCADE,
    DimensionImpact FLOAT,
    WeightImpact FLOAT,
    AdditionalPrice FLOAT CHECK (AdditionalPrice >= 0),
    PRIMARY KEY (OptionValueID, OptionID)
);

-- PRODUCT_VARIATION Table
DROP TABLE IF EXISTS PRODUCT_VARIATION CASCADE;
CREATE TABLE PRODUCT_VARIATION (
    VariationID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    Status VARCHAR(50),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    StockLevel INT CHECK (StockLevel >= 0),
    Weight FLOAT CHECK (Weight >= 0),
    OptionCombination VARCHAR(255),
    Price FLOAT CHECK (Price >= 0)
);

-- PRODUCT_HAS_OPTION Table
DROP TABLE IF EXISTS PRODUCT_HAS_OPTION CASCADE;
CREATE TABLE PRODUCT_HAS_OPTION (
    ProductID UUID REFERENCES PRODUCT(ProductID) ON DELETE CASCADE,
    OptionID UUID REFERENCES PRODUCT_OPTION(OptionID) ON DELETE CASCADE,
    PRIMARY KEY (ProductID, OptionID)
);

-- COMBINATION Table
DROP TABLE IF EXISTS COMBINATION CASCADE;

CREATE TABLE COMBINATION (
    VariationID UUID REFERENCES PRODUCT_VARIATION(VariationID) ON DELETE CASCADE,
    OptionValueID UUID NOT NULL,
    OptionID UUID NOT NULL,
    PRIMARY KEY (VariationID, OptionValueID, OptionID),
    FOREIGN KEY (OptionValueID, OptionID) REFERENCES OPTION_VALUE(OptionValueID, OptionID) ON DELETE CASCADE
);


-- SKU_MANAGEMENT Table
DROP TABLE IF EXISTS SKU_MANAGEMENT CASCADE;
CREATE TABLE SKU_MANAGEMENT (
    SKU VARCHAR(12) PRIMARY KEY,
    SupplierName VARCHAR(255) NOT NULL,
    RestockDate TIMESTAMP NOT NULL,
    StockLevel INT CHECK (StockLevel >= 0),
    RestockThreshold INT CHECK (RestockThreshold >= 0),
    VariationID UUID REFERENCES PRODUCT_VARIATION(VariationID) ON DELETE CASCADE
);

-- SHOP_SELLS_PRODUCT Table
DROP TABLE IF EXISTS SHOP_SELLS_PRODUCT CASCADE;

CREATE TABLE SHOP_SELLS_PRODUCT (
    RegistrationNumber UUID REFERENCES SHOP(RegistrationNumber) ON DELETE CASCADE,
    ProductID UUID REFERENCES PRODUCT(ProductID) ON DELETE CASCADE,
    StockLevel INT CHECK (StockLevel >= 0),
    Price FLOAT CHECK (Price >= 0),
    PRIMARY KEY (RegistrationNumber, ProductID)
);

-- CART Table
DROP TABLE IF EXISTS CART CASCADE;
CREATE TABLE CART (
    CartID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    UserID UUID REFERENCES CUSTOMER(UserID) ON DELETE CASCADE,
    CartStatus VARCHAR(50),
    CreateDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdateDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TotalPrice FLOAT CHECK (TotalPrice >= 0)
);


DROP TABLE IF EXISTS CART_ITEM CASCADE;

CREATE TABLE CART_ITEM (
    CartItemID UUID UNIQUE DEFAULT uuid_generate_v4(),
    UserID UUID REFERENCES CUSTOMER(UserID) ON DELETE CASCADE,
    CartID UUID REFERENCES CART(CartID) ON DELETE CASCADE,
    ProductID UUID REFERENCES PRODUCT(ProductID) ON DELETE CASCADE,
    Quantity INT CHECK (Quantity > 0),
    FinalPrice FLOAT CHECK (FinalPrice >= 0),
    PRIMARY KEY (CartItemID, UserID, ProductID)
);


-- LIST Table
DROP TABLE IF EXISTS LIST CASCADE;
CREATE TABLE LIST (
    ListID UUID UNIQUE DEFAULT uuid_generate_v4(),
    UserID UUID REFERENCES CUSTOMER(UserID) ON DELETE CASCADE,
    ListName VARCHAR(100),
    ListType VARCHAR(50),
    Visibility visibility_enum NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ListID, UserID)
);

-- LIST_CONTAINS Table
DROP TABLE IF EXISTS LIST_CONTAINS CASCADE;
CREATE TABLE LIST_CONTAINS (
    ListID UUID REFERENCES LIST(ListID) ON DELETE CASCADE,
    ProductID UUID REFERENCES PRODUCT(ProductID) ON DELETE CASCADE,
    PRIMARY KEY (ListID, ProductID)
);

-- LIKE_PRODUCT Table
DROP TABLE IF EXISTS LIKE_PRODUCT CASCADE;
CREATE TABLE LIKE_PRODUCT (
    UserID UUID REFERENCES CUSTOMER(UserID) ON DELETE CASCADE,
    ProductID UUID REFERENCES PRODUCT(ProductID) ON DELETE CASCADE,
    PRIMARY KEY (UserID, ProductID)
);

-- QUESTION Table
DROP TABLE IF EXISTS QUESTION CASCADE;
CREATE TABLE QUESTION (
    QuestionNumber UUID UNIQUE DEFAULT uuid_generate_v4(),
    ProductID UUID REFERENCES PRODUCT(ProductID) ON DELETE CASCADE,
    CustomerID UUID REFERENCES CUSTOMER(UserID) ON DELETE CASCADE,
    SellerID UUID REFERENCES SELLER(UserID) ON DELETE CASCADE,
    QuestionText TEXT NOT NULL,
    AnswerText TEXT,
    QuestionStatus question_status_enum NOT NULL,
    QuestionDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    AnswerDate TIMESTAMP,
    PRIMARY KEY (QuestionNumber, CustomerID)
);

-- ORDER Table
DROP TABLE IF EXISTS "ORDER" CASCADE;

CREATE TABLE "ORDER" (
    OrderNo UUID DEFAULT uuid_generate_v4(),
    CartItemID UUID NOT NULL,
    UserID UUID NOT NULL,
    ProductID UUID NOT NULL,
    DateTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TotalPrice FLOAT CHECK (TotalPrice >= 0),
    PaymentID UUID REFERENCES PAYMENT_METHOD(PaymentID) ON DELETE CASCADE,
    OrderStatus order_status_enum NOT NULL,
    PRIMARY KEY (OrderNo, CartItemID, UserID, ProductID)
);


DROP TABLE IF EXISTS ORDER_ITEM CASCADE;

CREATE TABLE ORDER_ITEM (
    OrderItemID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    OrderNo UUID NOT NULL,
    CartItemID UUID NOT NULL,
    UserID UUID NOT NULL,
    ProductID UUID NOT NULL,
    Quantity INT CHECK (Quantity > 0),
    Price FLOAT CHECK (Price >= 0),
    OrderStatus order_status_enum NOT NULL,
    UNIQUE (OrderItemID, OrderNo, CartItemID, UserID, ProductID),
    FOREIGN KEY (OrderNo, CartItemID, UserID, ProductID) REFERENCES "ORDER"(OrderNo, CartItemID, UserID, ProductID) ON DELETE CASCADE
);



-- REVIEW Table
DROP TABLE IF EXISTS REVIEW CASCADE;

CREATE TABLE REVIEW (
    ReviewID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    OrderItemID UUID NOT NULL,
    OrderNo UUID NOT NULL,
    CartItemID UUID NOT NULL,
    UserID UUID NOT NULL,
    ProductID UUID NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comment TEXT,
    ReviewDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Response TEXT,
    ResponseDate TIMESTAMP,
    ShopID UUID REFERENCES SHOP(RegistrationNumber) ON DELETE SET NULL,
    FOREIGN KEY (OrderItemID, OrderNo, CartItemID, UserID, ProductID) REFERENCES ORDER_ITEM(OrderItemID, OrderNo, CartItemID, UserID, ProductID) ON DELETE CASCADE
);


-- LOGISTIC Table
DROP TABLE IF EXISTS LOGISTIC CASCADE;
CREATE TABLE LOGISTIC (
    LogisticID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    TrackingNumber VARCHAR(100) UNIQUE,
    DeliveryStatus delivery_status_enum NOT NULL,
    ShippingDate TIMESTAMP,
    DeliveryDate TIMESTAMP,
    LogisticType logistic_type_enum NOT NULL,
    Recipient VARCHAR(100),
    LogisticPrice FLOAT CHECK (LogisticPrice >= 0),
    AddressID UUID REFERENCES ADDRESS(AddressID) ON DELETE SET NULL
);

DROP TABLE IF EXISTS RETURN CASCADE;

CREATE TABLE RETURN (
    ReturnID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    OrderItemID UUID REFERENCES ORDER_ITEM(OrderItemID) ON DELETE CASCADE,
    ReturnDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ReturnStatus return_status_enum NOT NULL,
    ReturnReason TEXT NOT NULL
);


-- DISCOUNT Table
DROP TABLE IF EXISTS DISCOUNT CASCADE;
CREATE TABLE DISCOUNT (
    DiscountID UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    Rate FLOAT CHECK (Rate BETWEEN 0 AND 100),
    DiscountLimit FLOAT CHECK (DiscountLimit >= 0),
    Status BOOLEAN NOT NULL,
    CouponFlag BOOLEAN DEFAULT FALSE,
    PercentageFlag BOOLEAN DEFAULT FALSE,
    FixedAmountFlag BOOLEAN DEFAULT FALSE
);

-- DISCOUNT_APPLIED_PRODUCT Table
DROP TABLE IF EXISTS DISCOUNT_APPLIED_PRODUCT CASCADE;
CREATE TABLE DISCOUNT_APPLIED_PRODUCT (
    DiscountID UUID REFERENCES DISCOUNT(DiscountID) ON DELETE CASCADE,
    ProductID UUID REFERENCES PRODUCT(ProductID) ON DELETE CASCADE,
    PRIMARY KEY (DiscountID, ProductID)
);
