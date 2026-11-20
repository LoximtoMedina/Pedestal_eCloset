/* ============================================================================
   PEDESTAL - Base de datos (SQL Server)
   Modelo B2C omnicanal: ERP de tiendas + tienda virtual + closet (base).

   Convenciones:
   - Nombres de tablas y columnas en inglés; comentarios en español.
   - PK = Id (IDENTITY). FK = <Tabla>_Id.
   - Dinero = DECIMAL(18,2). Texto = NVARCHAR. Fechas con hora = DATETIME2.
   - RegistrationDate = fecha de creación; UpdatedAt la llena el backend.
   - Active = borrado lógico (no se eliminan filas con historial).
   - Ejecutar UNA sola vez sobre una base nueva (los datos iniciales no son idempotentes).
   ============================================================================ */

SET NOCOUNT ON;
GO

IF DB_ID(N'Pedestal') IS NULL
    CREATE DATABASE Pedestal;
GO

USE Pedestal;
GO

/* ============================================================================
   1. PERSONAS, PROVEEDORES, CONTACTO
   ============================================================================ */

-- Person: tabla base de toda persona natural (cliente, usuario web, empleado, proveedor natural).
CREATE TABLE dbo.Person (
    Id               INT IDENTITY(1,1) NOT NULL,
    DocumentId       NVARCHAR(30)  NULL,                -- documento de identidad (único si existe)
    FirstName        NVARCHAR(45)  NOT NULL,
    MiddleName       NVARCHAR(45)  NULL,
    FirstSurname     NVARCHAR(45)  NOT NULL,
    SecondSurname    NVARCHAR(45)  NULL,
    Email            NVARCHAR(100) NULL,                -- único si existe
    RegistrationDate DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2     NULL,
    Active           BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_Person PRIMARY KEY (Id),
    CONSTRAINT CK_Person_Email CHECK (Email IS NULL OR Email LIKE '%_@_%._%')
);
GO

-- LegalEntity: persona jurídica (empresa). Antes llamada ArtificialPerson.
CREATE TABLE dbo.LegalEntity (
    Id               INT IDENTITY(1,1) NOT NULL,
    BusinessName     NVARCHAR(100) NOT NULL,            -- razón social
    TradeName        NVARCHAR(100) NULL,                -- nombre comercial
    TaxId            NVARCHAR(30)  NULL,                -- RTN / identificación fiscal
    Email            NVARCHAR(100) NULL,
    RegistrationDate DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2     NULL,
    Active           BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_LegalEntity PRIMARY KEY (Id)
);
GO

-- Phones: teléfonos de una persona natural O de una empresa (exactamente uno de los dos).
CREATE TABLE dbo.Phones (
    Id               INT IDENTITY(1,1) NOT NULL,
    Phone            NVARCHAR(20) NOT NULL,
    Person_Id        INT NULL,
    LegalEntity_Id   INT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Phones PRIMARY KEY (Id),
    CONSTRAINT FK_Phones_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
    CONSTRAINT FK_Phones_LegalEntity FOREIGN KEY (LegalEntity_Id) REFERENCES dbo.LegalEntity (Id),
    CONSTRAINT CK_Phones_Owner CHECK (
        (Person_Id IS NOT NULL AND LegalEntity_Id IS NULL) OR
        (Person_Id IS NULL AND LegalEntity_Id IS NOT NULL))
);
GO

-- Directions: direcciones de personas o empresas. Sirven también como direcciones de envío.
CREATE TABLE dbo.Directions (
    Id               INT IDENTITY(1,1) NOT NULL,
    Direction        NVARCHAR(200) NOT NULL,
    City             NVARCHAR(60)  NULL,
    DirectionType    NVARCHAR(10)  NOT NULL DEFAULT 'HOME',
    IsDefault        BIT           NOT NULL DEFAULT 0,  -- dirección de envío predeterminada
    Person_Id        INT NULL,
    LegalEntity_Id   INT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Directions PRIMARY KEY (Id),
    CONSTRAINT FK_Directions_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
    CONSTRAINT FK_Directions_LegalEntity FOREIGN KEY (LegalEntity_Id) REFERENCES dbo.LegalEntity (Id),
    CONSTRAINT CK_Directions_Type CHECK (DirectionType IN ('HOME','WORK','SHIPPING','OTHER')),
    CONSTRAINT CK_Directions_Owner CHECK (
        (Person_Id IS NOT NULL AND LegalEntity_Id IS NULL) OR
        (Person_Id IS NULL AND LegalEntity_Id IS NOT NULL))
);
GO

-- Supplier: proveedor, persona natural (N) o jurídica (J); solo una de las dos referencias.
CREATE TABLE dbo.Supplier (
    Id               INT IDENTITY(1,1) NOT NULL,
    SupplierType     CHAR(1) NOT NULL,
    Person_Id        INT NULL,
    LegalEntity_Id   INT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2 NULL,
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Supplier PRIMARY KEY (Id),
    CONSTRAINT FK_Supplier_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
    CONSTRAINT FK_Supplier_LegalEntity FOREIGN KEY (LegalEntity_Id) REFERENCES dbo.LegalEntity (Id),
    CONSTRAINT CK_Supplier_Type CHECK (
        (SupplierType = 'N' AND Person_Id IS NOT NULL AND LegalEntity_Id IS NULL) OR
        (SupplierType = 'J' AND LegalEntity_Id IS NOT NULL AND Person_Id IS NULL))
);
GO

/* ============================================================================
   2. SEGURIDAD: CUENTAS, ROLES Y PERMISOS
   ============================================================================ */

-- Role: rol del sistema. ScopeType define hasta dónde llega su alcance de datos.
--   SELF = solo lo propio, STORE = su tienda, AREA = las tiendas de su área, GLOBAL = todo.
CREATE TABLE dbo.Role (
    Id          INT IDENTITY(1,1) NOT NULL,
    Name        NVARCHAR(45)  NOT NULL,
    Description NVARCHAR(200) NULL,
    ScopeType   NVARCHAR(10)  NOT NULL,
    Active      BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Role PRIMARY KEY (Id),
    CONSTRAINT UQ_Role_Name UNIQUE (Name),
    CONSTRAINT CK_Role_Scope CHECK (ScopeType IN ('SELF','STORE','AREA','GLOBAL'))
);
GO

-- Permission: acción posible sobre un módulo (ej. sales.create).
CREATE TABLE dbo.Permission (
    Id          INT IDENTITY(1,1) NOT NULL,
    Code        NVARCHAR(60) NOT NULL,
    Module      NVARCHAR(30) NOT NULL,
    ActionType  NVARCHAR(10) NOT NULL,
    CONSTRAINT PK_Permission PRIMARY KEY (Id),
    CONSTRAINT UQ_Permission_Code UNIQUE (Code),
    CONSTRAINT CK_Permission_Action CHECK (ActionType IN ('create','read','update','delete'))
);
GO

-- RolePermission: permisos que tiene cada rol (N:M).
CREATE TABLE dbo.RolePermission (
    Role_Id       INT NOT NULL,
    Permission_Id INT NOT NULL,
    CONSTRAINT PK_RolePermission PRIMARY KEY (Role_Id, Permission_Id),
    CONSTRAINT FK_RolePermission_Role FOREIGN KEY (Role_Id) REFERENCES dbo.Role (Id) ON DELETE CASCADE,
    CONSTRAINT FK_RolePermission_Permission FOREIGN KEY (Permission_Id) REFERENCES dbo.Permission (Id) ON DELETE CASCADE
);
GO

-- Account: credenciales de inicio de sesión. Una persona tiene como máximo una cuenta.
-- El rol efectivo sale de: [User] activo => Customer, y PositionHistorial activo => Position.Role_Id.
CREATE TABLE dbo.Account (
    Id               INT IDENTITY(1,1) NOT NULL,
    Person_Id        INT NOT NULL,
    Username         NVARCHAR(60)  NOT NULL,
    PasswordHash     NVARCHAR(255) NOT NULL,            -- NUNCA la contraseña en texto plano
    IsLocked         BIT NOT NULL DEFAULT 0,
    FailedAttempts   INT NOT NULL DEFAULT 0,
    LastLoginDate    DATETIME2 NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2 NULL,
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Account PRIMARY KEY (Id),
    CONSTRAINT UQ_Account_Person UNIQUE (Person_Id),
    CONSTRAINT UQ_Account_Username UNIQUE (Username),
    CONSTRAINT FK_Account_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
    CONSTRAINT CK_Account_Failed CHECK (FailedAttempts >= 0)
);
GO

-- AuditLog: quién cambió qué y cuándo. Lo escribe el backend en cada INSERT/UPDATE/DELETE.
CREATE TABLE dbo.AuditLog (
    Id          BIGINT IDENTITY(1,1) NOT NULL,
    Account_Id  INT NULL,                               -- NULL si la acción fue del sistema
    TableName   NVARCHAR(60) NOT NULL,
    RecordId    NVARCHAR(50) NOT NULL,
    ActionType  NVARCHAR(10) NOT NULL,
    OldValues   NVARCHAR(MAX) NULL,                     -- JSON con valores anteriores
    NewValues   NVARCHAR(MAX) NULL,                     -- JSON con valores nuevos
    AuditDate   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_AuditLog PRIMARY KEY (Id),
    CONSTRAINT FK_AuditLog_Account FOREIGN KEY (Account_Id) REFERENCES dbo.Account (Id),
    CONSTRAINT CK_AuditLog_Action CHECK (ActionType IN ('INSERT','UPDATE','DELETE','LOGIN'))
);
GO

-- [User]: perfil de tienda virtual. Todo User es Person; no toda Person es User.
-- (USER es palabra reservada en T-SQL: siempre escribir dbo.[User]).
CREATE TABLE dbo.[User] (
    Id               INT IDENTITY(1,1) NOT NULL,
    Person_Id        INT NOT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2 NULL,
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_User PRIMARY KEY (Id),
    CONSTRAINT UQ_User_Person UNIQUE (Person_Id),
    CONSTRAINT FK_User_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id)
);
GO

/* ============================================================================
   3. ORGANIZACIÓN: ÁREAS, TIENDAS, CARGOS, EMPLEADOS
   ============================================================================ */

-- WorkArea: sector que agrupa varias tiendas y tiene un jefe de área.
CREATE TABLE dbo.WorkArea (
    Id               INT IDENTITY(1,1) NOT NULL,
    Name             NVARCHAR(45)  NOT NULL,
    Description      NVARCHAR(200) NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2 NULL,
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_WorkArea PRIMARY KEY (Id),
    CONSTRAINT UQ_WorkArea_Name UNIQUE (Name)
);
GO

-- Store: tienda. StoreType distingue sucursal física, bodega y tienda virtual.
-- Toda tienda pertenece a un área (la tienda virtual también, ej. área "Central").
CREATE TABLE dbo.Store (
    Id               INT IDENTITY(1,1) NOT NULL,
    Name             NVARCHAR(60)  NOT NULL,
    Direction        NVARCHAR(200) NULL,
    StoreType        NVARCHAR(10)  NOT NULL DEFAULT 'PHYSICAL',
    WorkArea_Id      INT NOT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2 NULL,
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Store PRIMARY KEY (Id),
    CONSTRAINT UQ_Store_Name UNIQUE (Name),
    CONSTRAINT FK_Store_WorkArea FOREIGN KEY (WorkArea_Id) REFERENCES dbo.WorkArea (Id),
    CONSTRAINT CK_Store_Type CHECK (StoreType IN ('PHYSICAL','WAREHOUSE','VIRTUAL'))
);
GO

-- Position: cargo. Cada cargo lleva un rol, así el permiso sale del puesto activo.
CREATE TABLE dbo.Position (
    Id               INT IDENTITY(1,1) NOT NULL,
    Name             NVARCHAR(45)  NOT NULL,
    Description      NVARCHAR(200) NULL,
    Role_Id          INT NOT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Position PRIMARY KEY (Id),
    CONSTRAINT UQ_Position_Name UNIQUE (Name),
    CONSTRAINT FK_Position_Role FOREIGN KEY (Role_Id) REFERENCES dbo.Role (Id)
);
GO

-- Employee: empleado (siempre es una Person). Salary = salario vigente.
CREATE TABLE dbo.Employee (
    Id               INT IDENTITY(1,1) NOT NULL,
    Person_Id        INT NOT NULL,
    HireDate         DATE NOT NULL DEFAULT CAST(SYSUTCDATETIME() AS DATE),
    Salary           DECIMAL(18,2) NOT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2 NULL,
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Employee PRIMARY KEY (Id),
    CONSTRAINT UQ_Employee_Person UNIQUE (Person_Id),
    CONSTRAINT FK_Employee_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
    CONSTRAINT CK_Employee_Salary CHECK (Salary >= 0)
);
GO

-- PositionHistorial: historial laboral. LastDate NULL = asignación vigente.
--   Cajero/Supervisor: Store_Id obligatorio. Jefe de área: WorkArea_Id (Store_Id puede ser NULL).
--   Salary guarda el salario de ese período (así no se pierde el historial al subir sueldos).
CREATE TABLE dbo.PositionHistorial (
    Id          INT IDENTITY(1,1) NOT NULL,
    Employee_Id INT NOT NULL,
    Position_Id INT NOT NULL,
    Store_Id    INT NULL,
    WorkArea_Id INT NULL,
    FirstDate   DATE NOT NULL,
    LastDate    DATE NULL,
    Salary      DECIMAL(18,2) NOT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active      BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_PositionHistorial PRIMARY KEY (Id),
    CONSTRAINT FK_PositionHistorial_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
    CONSTRAINT FK_PositionHistorial_Position FOREIGN KEY (Position_Id) REFERENCES dbo.Position (Id),
    CONSTRAINT FK_PositionHistorial_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
    CONSTRAINT FK_PositionHistorial_WorkArea FOREIGN KEY (WorkArea_Id) REFERENCES dbo.WorkArea (Id),
    CONSTRAINT CK_PositionHistorial_Dates CHECK (LastDate IS NULL OR LastDate >= FirstDate),
    CONSTRAINT CK_PositionHistorial_Scope CHECK (Store_Id IS NOT NULL OR WorkArea_Id IS NOT NULL),
    CONSTRAINT CK_PositionHistorial_Salary CHECK (Salary >= 0)
);
GO

-- Payroll: planilla pagada a un empleado en un período (egreso de la tienda).
CREATE TABLE dbo.Payroll (
    Id               INT IDENTITY(1,1) NOT NULL,
    Employee_Id      INT NOT NULL,
    Store_Id         INT NOT NULL,                      -- tienda que absorbe el gasto
    PeriodStart      DATE NOT NULL,
    PeriodEnd        DATE NOT NULL,
    GrossAmount      DECIMAL(18,2) NOT NULL,            -- costo para la empresa
    Deductions       DECIMAL(18,2) NOT NULL DEFAULT 0,
    NetAmount        AS (GrossAmount - Deductions) PERSISTED,
    PaidDate         DATE NULL,                         -- NULL = aún no pagada
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Payroll PRIMARY KEY (Id),
    CONSTRAINT UQ_Payroll_Period UNIQUE (Employee_Id, PeriodStart, PeriodEnd),
    CONSTRAINT FK_Payroll_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
    CONSTRAINT FK_Payroll_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
    CONSTRAINT CK_Payroll_Period CHECK (PeriodEnd >= PeriodStart),
    CONSTRAINT CK_Payroll_Amounts CHECK (GrossAmount >= 0 AND Deductions >= 0 AND Deductions <= GrossAmount)
);
GO
/* ============================================================================
   4. CATÁLOGO: TIPOS, PRENDAS Y VARIANTES (TALLA + COLOR)
   ============================================================================ */

-- ClotheType: categoría de prenda (camisas, pantalones...).
CREATE TABLE dbo.ClotheType (
    Id               INT IDENTITY(1,1) NOT NULL,
    Name             NVARCHAR(45)  NOT NULL,
    Description      NVARCHAR(200) NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ClotheType PRIMARY KEY (Id),
    CONSTRAINT UQ_ClotheType_Name UNIQUE (Name)
);
GO

-- Clothe: modelo de prenda (ej. "Camisa Oxford"). El stock NO se guarda aquí sino en sus variantes.
-- ImageBase64: imagen para catálogo/probador. No incluirla en consultas de listados.
CREATE TABLE dbo.Clothe (
    Id               INT IDENTITY(1,1) NOT NULL,
    Name             NVARCHAR(60)  NOT NULL,
    ClotheType_Id    INT NOT NULL,
    Brand            NVARCHAR(45)  NULL,
    Description      NVARCHAR(500) NULL,
    BasePrice        DECIMAL(18,2) NOT NULL,
    ImageBase64      VARCHAR(MAX)  NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2 NULL,
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Clothe PRIMARY KEY (Id),
    CONSTRAINT FK_Clothe_ClotheType FOREIGN KEY (ClotheType_Id) REFERENCES dbo.ClotheType (Id),
    CONSTRAINT CK_Clothe_Price CHECK (BasePrice >= 0)
);
GO

-- Size: catálogo de tallas (SortOrder permite mostrarlas en orden XS, S, M...).
CREATE TABLE dbo.Size (
    Id        INT IDENTITY(1,1) NOT NULL,
    Name      NVARCHAR(10) NOT NULL,
    SortOrder INT NOT NULL DEFAULT 0,
    Active    BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Size PRIMARY KEY (Id),
    CONSTRAINT UQ_Size_Name UNIQUE (Name)
);
GO

-- Color: catálogo de colores.
CREATE TABLE dbo.Color (
    Id      INT IDENTITY(1,1) NOT NULL,
    Name    NVARCHAR(30) NOT NULL,
    HexCode CHAR(7) NULL,                               -- ej. #FF0000
    Active  BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Color PRIMARY KEY (Id),
    CONSTRAINT UQ_Color_Name UNIQUE (Name),
    CONSTRAINT CK_Color_Hex CHECK (HexCode IS NULL OR HexCode LIKE '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')
);
GO

-- ClotheVariant: unidad real de venta e inventario = prenda + talla + color.
-- Facturas, carrito, compras, cubículos y movimientos apuntan a esta tabla.
CREATE TABLE dbo.ClotheVariant (
    Id               INT IDENTITY(1,1) NOT NULL,
    Clothe_Id        INT NOT NULL,
    Size_Id          INT NOT NULL,
    Color_Id         INT NOT NULL,
    Sku              NVARCHAR(40) NOT NULL,             -- código único de la variante
    PriceOverride    DECIMAL(18,2) NULL,                -- NULL = usa Clothe.BasePrice
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2 NULL,
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ClotheVariant PRIMARY KEY (Id),
    CONSTRAINT UQ_ClotheVariant_Sku UNIQUE (Sku),
    CONSTRAINT UQ_ClotheVariant_Combo UNIQUE (Clothe_Id, Size_Id, Color_Id),
    CONSTRAINT FK_ClotheVariant_Clothe FOREIGN KEY (Clothe_Id) REFERENCES dbo.Clothe (Id),
    CONSTRAINT FK_ClotheVariant_Size FOREIGN KEY (Size_Id) REFERENCES dbo.Size (Id),
    CONSTRAINT FK_ClotheVariant_Color FOREIGN KEY (Color_Id) REFERENCES dbo.Color (Id),
    CONSTRAINT CK_ClotheVariant_Price CHECK (PriceOverride IS NULL OR PriceOverride >= 0)
);
GO

/* ============================================================================
   5. ALMACÉN: RACKS, CUBÍCULOS Y STOCK
   ============================================================================ */

-- Rack: estante dentro de una tienda.
CREATE TABLE dbo.Rack (
    Id               INT IDENTITY(1,1) NOT NULL,
    Store_Id         INT NOT NULL,
    RackNumber       NVARCHAR(45) NOT NULL,
    Name             NVARCHAR(45) NULL,
    Description      NVARCHAR(200) NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Rack PRIMARY KEY (Id),
    CONSTRAINT UQ_Rack_Number UNIQUE (Store_Id, RackNumber),
    CONSTRAINT FK_Rack_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id)
);
GO

-- Cubicle: casilla dentro de un rack.
CREATE TABLE dbo.Cubicle (
    Id               INT IDENTITY(1,1) NOT NULL,
    Rack_Id          INT NOT NULL,
    CubicleNumber    NVARCHAR(45) NOT NULL,
    Name             NVARCHAR(45) NULL,
    Description      NVARCHAR(200) NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Cubicle PRIMARY KEY (Id),
    CONSTRAINT UQ_Cubicle_Number UNIQUE (Rack_Id, CubicleNumber),
    CONSTRAINT FK_Cubicle_Rack FOREIGN KEY (Rack_Id) REFERENCES dbo.Rack (Id)
);
GO

-- ClothesInCubicle: FUENTE DE VERDAD del stock. Cuántas unidades de cada variante hay en cada cubículo.
-- El stock de una tienda = suma de sus cubículos (ver vw_StoreStock).
CREATE TABLE dbo.ClothesInCubicle (
    Cubicle_Id       INT NOT NULL,
    ClotheVariant_Id INT NOT NULL,
    Quantity         INT NOT NULL DEFAULT 0,
    UpdatedAt        DATETIME2 NULL,
    CONSTRAINT PK_ClothesInCubicle PRIMARY KEY (Cubicle_Id, ClotheVariant_Id),
    CONSTRAINT FK_ClothesInCubicle_Cubicle FOREIGN KEY (Cubicle_Id) REFERENCES dbo.Cubicle (Id),
    CONSTRAINT FK_ClothesInCubicle_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
    CONSTRAINT CK_ClothesInCubicle_Qty CHECK (Quantity >= 0)
);
GO

/* ============================================================================
   6. COMPRAS Y ABASTECIMIENTO
   ============================================================================ */

-- PurchaseOrder: orden de compra a un proveedor para una tienda. Cuenta como egreso al estar RECEIVED.
CREATE TABLE dbo.PurchaseOrder (
    Id               INT IDENTITY(1,1) NOT NULL,
    OrderNumber      NVARCHAR(30) NOT NULL,
    Supplier_Id      INT NOT NULL,
    Store_Id         INT NOT NULL,                      -- tienda que recibe y paga
    Employee_Id      INT NULL,                          -- empleado que la creó
    OrderDate        DATE NOT NULL DEFAULT CAST(SYSUTCDATETIME() AS DATE),
    ReceivedDate     DATE NULL,
    Status           NVARCHAR(10) NOT NULL DEFAULT 'DRAFT',
    Total            DECIMAL(18,2) NOT NULL DEFAULT 0,  -- suma de los detalles (la calcula el backend)
    Notes            NVARCHAR(300) NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2 NULL,
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_PurchaseOrder PRIMARY KEY (Id),
    CONSTRAINT UQ_PurchaseOrder_Number UNIQUE (OrderNumber),
    CONSTRAINT FK_PurchaseOrder_Supplier FOREIGN KEY (Supplier_Id) REFERENCES dbo.Supplier (Id),
    CONSTRAINT FK_PurchaseOrder_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
    CONSTRAINT FK_PurchaseOrder_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
    CONSTRAINT CK_PurchaseOrder_Status CHECK (Status IN ('DRAFT','SENT','RECEIVED','CANCELLED')),
    CONSTRAINT CK_PurchaseOrder_Total CHECK (Total >= 0),
    CONSTRAINT CK_PurchaseOrder_Received CHECK (Status <> 'RECEIVED' OR ReceivedDate IS NOT NULL)
);
GO

-- PurchaseOrderDetail: líneas de la orden (variante, cantidad y costo unitario).
CREATE TABLE dbo.PurchaseOrderDetail (
    Id               INT IDENTITY(1,1) NOT NULL,
    PurchaseOrder_Id INT NOT NULL,
    ClotheVariant_Id INT NOT NULL,
    Quantity         INT NOT NULL,
    UnitCost         DECIMAL(18,2) NOT NULL,
    SubTotal         AS (Quantity * UnitCost) PERSISTED,
    CONSTRAINT PK_PurchaseOrderDetail PRIMARY KEY (Id),
    CONSTRAINT UQ_PurchaseOrderDetail_Line UNIQUE (PurchaseOrder_Id, ClotheVariant_Id),
    CONSTRAINT FK_PurchaseOrderDetail_Order FOREIGN KEY (PurchaseOrder_Id) REFERENCES dbo.PurchaseOrder (Id),
    CONSTRAINT FK_PurchaseOrderDetail_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
    CONSTRAINT CK_PurchaseOrderDetail_Qty CHECK (Quantity > 0),
    CONSTRAINT CK_PurchaseOrderDetail_Cost CHECK (UnitCost >= 0)
);
GO

-- Batch: lote recibido de una línea de orden. Stock = unidades del lote que aún no se han vendido/movido.
-- (Informativo: el stock real por ubicación está en ClothesInCubicle.)
CREATE TABLE dbo.Batch (
    Id                      INT IDENTITY(1,1) NOT NULL,
    BatchNumber             NVARCHAR(45) NOT NULL,
    PurchaseOrderDetail_Id  INT NOT NULL,
    Quantity                INT NOT NULL,               -- unidades recibidas
    Stock                   INT NOT NULL,               -- unidades restantes del lote
    ElaborationDate         DATE NULL,
    RegistrationDate        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active                  BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Batch PRIMARY KEY (Id),
    CONSTRAINT UQ_Batch_Number UNIQUE (BatchNumber),
    CONSTRAINT FK_Batch_OrderDetail FOREIGN KEY (PurchaseOrderDetail_Id) REFERENCES dbo.PurchaseOrderDetail (Id),
    CONSTRAINT CK_Batch_Qty CHECK (Quantity > 0 AND Stock >= 0 AND Stock <= Quantity)
);
GO
/* ============================================================================
   7. IMPUESTOS, DESCUENTOS, CUPONES Y MÉTODOS DE PAGO
   ============================================================================ */

-- Taxes: impuestos configurables (ej. ISV).
CREATE TABLE dbo.Taxes (
    Id               INT IDENTITY(1,1) NOT NULL,
    Name             NVARCHAR(45) NOT NULL,
    Percentage       DECIMAL(5,2) NOT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Taxes PRIMARY KEY (Id),
    CONSTRAINT UQ_Taxes_Name UNIQUE (Name),
    CONSTRAINT CK_Taxes_Pct CHECK (Percentage BETWEEN 0 AND 100)
);
GO

-- Discounts: descuento por temporada/producto con vigencia.
CREATE TABLE dbo.Discounts (
    Id               INT IDENTITY(1,1) NOT NULL,
    Name             NVARCHAR(60) NOT NULL,
    StartDate        DATETIME2 NOT NULL,
    FinishDate       DATETIME2 NOT NULL,
    Percentage       DECIMAL(5,2) NOT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Discounts PRIMARY KEY (Id),
    CONSTRAINT CK_Discounts_Pct CHECK (Percentage > 0 AND Percentage <= 100),
    CONSTRAINT CK_Discounts_Dates CHECK (FinishDate >= StartDate)
);
GO

-- DiscountTarget: a qué se aplica un descuento: una prenda O un tipo de prenda (exactamente uno).
CREATE TABLE dbo.DiscountTarget (
    Id            INT IDENTITY(1,1) NOT NULL,
    Discount_Id   INT NOT NULL,
    Clothe_Id     INT NULL,
    ClotheType_Id INT NULL,
    CONSTRAINT PK_DiscountTarget PRIMARY KEY (Id),
    CONSTRAINT FK_DiscountTarget_Discount FOREIGN KEY (Discount_Id) REFERENCES dbo.Discounts (Id),
    CONSTRAINT FK_DiscountTarget_Clothe FOREIGN KEY (Clothe_Id) REFERENCES dbo.Clothe (Id),
    CONSTRAINT FK_DiscountTarget_Type FOREIGN KEY (ClotheType_Id) REFERENCES dbo.ClotheType (Id),
    CONSTRAINT CK_DiscountTarget_One CHECK (
        (Clothe_Id IS NOT NULL AND ClotheType_Id IS NULL) OR
        (Clothe_Id IS NULL AND ClotheType_Id IS NOT NULL))
);
GO

-- Coupons: cupón promocional por factura. 'P' = porcentaje, 'A' = monto fijo.
-- Validación: vigencia, MaxUses (conteo en Bill_has_Coupons) y MinPurchaseAmount.
CREATE TABLE dbo.Coupons (
    Id                INT IDENTITY(1,1) NOT NULL,
    Name              NVARCHAR(60) NOT NULL,
    Code              NVARCHAR(30) NOT NULL,
    DiscountKind      CHAR(1) NOT NULL,
    Percentage        DECIMAL(5,2) NULL,
    Amount            DECIMAL(18,2) NULL,
    StartDate         DATETIME2 NOT NULL,
    FinishDate        DATETIME2 NOT NULL,
    MaxUses           INT NULL,                         -- NULL = ilimitado
    MinPurchaseAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    RegistrationDate  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active            BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Coupons PRIMARY KEY (Id),
    CONSTRAINT UQ_Coupons_Code UNIQUE (Code),
    CONSTRAINT CK_Coupons_Kind CHECK (
        (DiscountKind = 'P' AND Percentage > 0 AND Percentage <= 100 AND Amount IS NULL) OR
        (DiscountKind = 'A' AND Amount > 0 AND Percentage IS NULL)),
    CONSTRAINT CK_Coupons_Dates CHECK (FinishDate >= StartDate),
    CONSTRAINT CK_Coupons_Limits CHECK ((MaxUses IS NULL OR MaxUses > 0) AND MinPurchaseAmount >= 0)
);
GO

-- PaymentMethod: efectivo, tarjeta de débito, tarjeta de crédito...
CREATE TABLE dbo.PaymentMethod (
    Id               INT IDENTITY(1,1) NOT NULL,
    Name             NVARCHAR(45) NOT NULL,
    RequiresCard     BIT NOT NULL DEFAULT 0,
    AllowedInStore   BIT NOT NULL DEFAULT 1,
    AllowedOnline    BIT NOT NULL DEFAULT 0,
    ApplyDiscounts   BIT NOT NULL DEFAULT 1,            -- si este método permite descuentos/cupones
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_PaymentMethod PRIMARY KEY (Id),
    CONSTRAINT UQ_PaymentMethod_Name UNIQUE (Name)
);
GO

-- PaymentCard: tarjetas del usuario web. Pago SIMULADO: nunca se guarda número completo ni CVV.
CREATE TABLE dbo.PaymentCard (
    Id               INT IDENTITY(1,1) NOT NULL,
    User_Id          INT NOT NULL,
    HolderName       NVARCHAR(60) NOT NULL,
    Brand            NVARCHAR(30) NOT NULL,
    CardType         NVARCHAR(6)  NOT NULL,
    Last4            CHAR(4) NOT NULL,                  -- solo los últimos 4 dígitos
    ExpirationDate   DATE NOT NULL,
    IsDefault        BIT NOT NULL DEFAULT 0,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_PaymentCard PRIMARY KEY (Id),
    CONSTRAINT FK_PaymentCard_User FOREIGN KEY (User_Id) REFERENCES dbo.[User] (Id),
    CONSTRAINT CK_PaymentCard_Type CHECK (CardType IN ('DEBIT','CREDIT')),
    CONSTRAINT CK_PaymentCard_Last4 CHECK (Last4 LIKE '[0-9][0-9][0-9][0-9]')
);
GO

/* ============================================================================
   8. FACTURACIÓN UNIFICADA (FÍSICA Y VIRTUAL)
   ============================================================================ */

-- Bill: factura. Cliente = Person (con o sin cuenta web). Store_Id = tienda que vende/despacha.
-- Channel: INSTORE exige cajero (Employee_Id); ONLINE no lleva cajero.
-- Los totales los calcula el backend dentro de una transacción.
CREATE TABLE dbo.Bill (
    Id                    INT IDENTITY(1,1) NOT NULL,
    BillCode              NVARCHAR(30) NOT NULL,
    Person_Id             INT NOT NULL,
    Store_Id              INT NOT NULL,
    Employee_Id           INT NULL,
    Channel               NVARCHAR(7)  NOT NULL,
    Status                NVARCHAR(10) NOT NULL DEFAULT 'PENDING',
    ShippingDirection_Id  INT NULL,
    SubTotal              DECIMAL(18,2) NOT NULL DEFAULT 0,
    DiscountTotal         DECIMAL(18,2) NOT NULL DEFAULT 0,
    CouponTotal           DECIMAL(18,2) NOT NULL DEFAULT 0,
    TaxTotal              DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total                 DECIMAL(18,2) NOT NULL DEFAULT 0,
    RegistrationDate      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt             DATETIME2 NULL,
    Active                BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Bill PRIMARY KEY (Id),
    CONSTRAINT UQ_Bill_Code UNIQUE (BillCode),
    CONSTRAINT FK_Bill_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
    CONSTRAINT FK_Bill_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
    CONSTRAINT FK_Bill_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
    CONSTRAINT FK_Bill_Direction FOREIGN KEY (ShippingDirection_Id) REFERENCES dbo.Directions (Id),
    CONSTRAINT CK_Bill_Channel CHECK (Channel IN ('INSTORE','ONLINE')),
    CONSTRAINT CK_Bill_Status CHECK (Status IN ('PENDING','PAID','SHIPPED','DELIVERED','CANCELLED')),
    CONSTRAINT CK_Bill_Cashier CHECK (
        (Channel = 'INSTORE' AND Employee_Id IS NOT NULL) OR
        (Channel = 'ONLINE'  AND Employee_Id IS NULL)),
    CONSTRAINT CK_Bill_Amounts CHECK (SubTotal >= 0 AND DiscountTotal >= 0 AND CouponTotal >= 0 AND TaxTotal >= 0 AND Total >= 0)
);
GO

-- BillDetails: líneas de la factura (una variante por línea). SubTotal y Total se calculan solos.
CREATE TABLE dbo.BillDetails (
    Id               INT IDENTITY(1,1) NOT NULL,
    Bill_Id          INT NOT NULL,
    ClotheVariant_Id INT NOT NULL,
    Quantity         INT NOT NULL,
    UnitPrice        DECIMAL(18,2) NOT NULL,            -- precio al momento de la venta
    DiscountAmount   DECIMAL(18,2) NOT NULL DEFAULT 0,
    TaxAmount        DECIMAL(18,2) NOT NULL DEFAULT 0,
    SubTotal         AS (Quantity * UnitPrice) PERSISTED,
    Total            AS (Quantity * UnitPrice - DiscountAmount + TaxAmount) PERSISTED,
    CONSTRAINT PK_BillDetails PRIMARY KEY (Id),
    CONSTRAINT UQ_BillDetails_Line UNIQUE (Bill_Id, ClotheVariant_Id),
    CONSTRAINT FK_BillDetails_Bill FOREIGN KEY (Bill_Id) REFERENCES dbo.Bill (Id),
    CONSTRAINT FK_BillDetails_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
    CONSTRAINT CK_BillDetails_Qty CHECK (Quantity > 0),
    CONSTRAINT CK_BillDetails_Amounts CHECK (UnitPrice >= 0 AND DiscountAmount >= 0 AND TaxAmount >= 0)
);
GO

-- AppliedTaxes: impuestos aplicados a una línea (guarda el % vigente en ese momento).
CREATE TABLE dbo.AppliedTaxes (
    BillDetails_Id INT NOT NULL,
    Taxes_Id       INT NOT NULL,
    Percentage     DECIMAL(5,2) NOT NULL,
    Amount         DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_AppliedTaxes PRIMARY KEY (BillDetails_Id, Taxes_Id),
    CONSTRAINT FK_AppliedTaxes_Detail FOREIGN KEY (BillDetails_Id) REFERENCES dbo.BillDetails (Id),
    CONSTRAINT FK_AppliedTaxes_Tax FOREIGN KEY (Taxes_Id) REFERENCES dbo.Taxes (Id),
    CONSTRAINT CK_AppliedTaxes_Amounts CHECK (Percentage BETWEEN 0 AND 100 AND Amount >= 0)
);
GO

-- AppliedDiscounts: descuentos aplicados a una línea (guarda el % vigente en ese momento).
CREATE TABLE dbo.AppliedDiscounts (
    BillDetails_Id INT NOT NULL,
    Discounts_Id   INT NOT NULL,
    Percentage     DECIMAL(5,2) NOT NULL,
    Amount         DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_AppliedDiscounts PRIMARY KEY (BillDetails_Id, Discounts_Id),
    CONSTRAINT FK_AppliedDiscounts_Detail FOREIGN KEY (BillDetails_Id) REFERENCES dbo.BillDetails (Id),
    CONSTRAINT FK_AppliedDiscounts_Discount FOREIGN KEY (Discounts_Id) REFERENCES dbo.Discounts (Id),
    CONSTRAINT CK_AppliedDiscounts_Amounts CHECK (Percentage BETWEEN 0 AND 100 AND Amount >= 0)
);
GO

-- Bill_has_Coupons: cupones usados en una factura.
CREATE TABLE dbo.Bill_has_Coupons (
    Bill_Id       INT NOT NULL,
    Coupons_Id    INT NOT NULL,
    AppliedAmount DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_Bill_has_Coupons PRIMARY KEY (Bill_Id, Coupons_Id),
    CONSTRAINT FK_BillCoupons_Bill FOREIGN KEY (Bill_Id) REFERENCES dbo.Bill (Id),
    CONSTRAINT FK_BillCoupons_Coupon FOREIGN KEY (Coupons_Id) REFERENCES dbo.Coupons (Id),
    CONSTRAINT CK_BillCoupons_Amount CHECK (AppliedAmount >= 0)
);
GO

-- Bill_has_PaymentMethod: pagos de una factura. Permite pagos mixtos (ej. 60% tarjeta + 40% efectivo).
-- Regla de negocio (backend): la suma de PaidAmount = Bill.Total; online = 100% tarjeta.
CREATE TABLE dbo.Bill_has_PaymentMethod (
    Id                INT IDENTITY(1,1) NOT NULL,
    Bill_Id           INT NOT NULL,
    PaymentMethod_Id  INT NOT NULL,
    PaymentCard_Id    INT NULL,                         -- tarjeta usada (si el método la requiere)
    PaidAmount        DECIMAL(18,2) NOT NULL,
    PaymentReference  NVARCHAR(60) NULL,                -- código de la transacción simulada
    RegistrationDate  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Bill_has_PaymentMethod PRIMARY KEY (Id),
    CONSTRAINT FK_BillPayment_Bill FOREIGN KEY (Bill_Id) REFERENCES dbo.Bill (Id),
    CONSTRAINT FK_BillPayment_Method FOREIGN KEY (PaymentMethod_Id) REFERENCES dbo.PaymentMethod (Id),
    CONSTRAINT FK_BillPayment_Card FOREIGN KEY (PaymentCard_Id) REFERENCES dbo.PaymentCard (Id),
    CONSTRAINT CK_BillPayment_Amount CHECK (PaidAmount > 0)
);
GO

-- StockMovement: historial de movimientos de stock (entradas, salidas, traslados, ajustes).
-- Se define aquí porque una salida puede venir de una línea de factura (BillDetails_Id).
CREATE TABLE dbo.StockMovement (
    Id               INT IDENTITY(1,1) NOT NULL,
    MovementType     NVARCHAR(8) NOT NULL,
    ClotheVariant_Id INT NOT NULL,
    Quantity         INT NOT NULL,
    Batch_Id         INT NULL,
    BillDetails_Id   INT NULL,                          -- si la salida fue por una venta
    FromStore_Id     INT NULL,
    FromCubicle_Id   INT NULL,
    ToStore_Id       INT NULL,
    ToCubicle_Id     INT NULL,
    Reason           NVARCHAR(200) NULL,
    Employee_Id      INT NULL,                          -- quién lo registró (NULL = sistema/venta online)
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_StockMovement PRIMARY KEY (Id),
    CONSTRAINT FK_StockMovement_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
    CONSTRAINT FK_StockMovement_Batch FOREIGN KEY (Batch_Id) REFERENCES dbo.Batch (Id),
    CONSTRAINT FK_StockMovement_BillDetails FOREIGN KEY (BillDetails_Id) REFERENCES dbo.BillDetails (Id),
    CONSTRAINT FK_StockMovement_FromStore FOREIGN KEY (FromStore_Id) REFERENCES dbo.Store (Id),
    CONSTRAINT FK_StockMovement_FromCubicle FOREIGN KEY (FromCubicle_Id) REFERENCES dbo.Cubicle (Id),
    CONSTRAINT FK_StockMovement_ToStore FOREIGN KEY (ToStore_Id) REFERENCES dbo.Store (Id),
    CONSTRAINT FK_StockMovement_ToCubicle FOREIGN KEY (ToCubicle_Id) REFERENCES dbo.Cubicle (Id),
    CONSTRAINT FK_StockMovement_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
    CONSTRAINT CK_StockMovement_Qty CHECK (Quantity > 0),
    CONSTRAINT CK_StockMovement_Type CHECK (MovementType IN ('IN','OUT','TRANSFER','ADJUST')),
    -- Cada tipo exige origen/destino coherentes
    CONSTRAINT CK_StockMovement_Stores CHECK (
        (MovementType = 'IN'       AND ToStore_Id IS NOT NULL AND FromStore_Id IS NULL) OR
        (MovementType = 'OUT'      AND FromStore_Id IS NOT NULL AND ToStore_Id IS NULL) OR
        (MovementType = 'TRANSFER' AND FromStore_Id IS NOT NULL AND ToStore_Id IS NOT NULL) OR
        (MovementType = 'ADJUST'   AND (FromStore_Id IS NOT NULL OR ToStore_Id IS NOT NULL)))
);
GO

/* ============================================================================
   9. TIENDA VIRTUAL: CARRITO
   ============================================================================ */

-- Cart: carrito del usuario web. Solo puede haber un carrito ACTIVE por usuario (índice único filtrado).
CREATE TABLE dbo.Cart (
    Id               INT IDENTITY(1,1) NOT NULL,
    User_Id          INT NOT NULL,
    Status           NVARCHAR(10) NOT NULL DEFAULT 'ACTIVE',
    Bill_Id          INT NULL,                          -- factura generada al confirmar la compra
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2 NULL,
    CONSTRAINT PK_Cart PRIMARY KEY (Id),
    CONSTRAINT FK_Cart_User FOREIGN KEY (User_Id) REFERENCES dbo.[User] (Id),
    CONSTRAINT FK_Cart_Bill FOREIGN KEY (Bill_Id) REFERENCES dbo.Bill (Id),
    CONSTRAINT CK_Cart_Status CHECK (Status IN ('ACTIVE','CONVERTED','ABANDONED'))
);
GO

-- CartDetail: variantes dentro del carrito.
CREATE TABLE dbo.CartDetail (
    Id               INT IDENTITY(1,1) NOT NULL,
    Cart_Id          INT NOT NULL,
    ClotheVariant_Id INT NOT NULL,
    Quantity         INT NOT NULL,
    AddedDate        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CartDetail PRIMARY KEY (Id),
    CONSTRAINT UQ_CartDetail_Line UNIQUE (Cart_Id, ClotheVariant_Id),
    CONSTRAINT FK_CartDetail_Cart FOREIGN KEY (Cart_Id) REFERENCES dbo.Cart (Id) ON DELETE CASCADE,
    CONSTRAINT FK_CartDetail_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
    CONSTRAINT CK_CartDetail_Qty CHECK (Quantity > 0)
);
GO

/* ============================================================================
   10. GASTOS OPERATIVOS POR TIENDA
   ============================================================================ */

-- ExpenseCategory: en qué se gasta (luz, agua, alquiler, papelería...).
CREATE TABLE dbo.ExpenseCategory (
    Id          INT IDENTITY(1,1) NOT NULL,
    Name        NVARCHAR(60)  NOT NULL,
    Description NVARCHAR(200) NULL,
    Active      BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ExpenseCategory PRIMARY KEY (Id),
    CONSTRAINT UQ_ExpenseCategory_Name UNIQUE (Name)
);
GO

-- Expense: gasto operativo de una tienda (no incluye compras de mercadería ni planillas, que tienen su tabla).
CREATE TABLE dbo.Expense (
    Id                  INT IDENTITY(1,1) NOT NULL,
    Store_Id            INT NOT NULL,
    ExpenseCategory_Id  INT NOT NULL,
    Amount              DECIMAL(18,2) NOT NULL,
    ExpenseDate         DATE NOT NULL,
    Description         NVARCHAR(200) NULL,
    Employee_Id         INT NULL,                       -- quién lo registró
    RegistrationDate    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active              BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Expense PRIMARY KEY (Id),
    CONSTRAINT FK_Expense_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
    CONSTRAINT FK_Expense_Category FOREIGN KEY (ExpenseCategory_Id) REFERENCES dbo.ExpenseCategory (Id),
    CONSTRAINT FK_Expense_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
    CONSTRAINT CK_Expense_Amount CHECK (Amount > 0)
);
GO

/* ============================================================================
   11. CLOSET VIRTUAL (BASE - SE COMPLETA DESPUÉS)
   Pendiente: UserModelPose (poses del modelo), OutfitSchedule (calendario)
   y vistas de analítica (porcentaje de uso por prenda).
   ============================================================================ */

-- UserClothes: guardarropa del usuario. PURCHASED = viene de una compra (variante); UPLOADED = prenda propia.
CREATE TABLE dbo.UserClothes (
    Id               INT IDENTITY(1,1) NOT NULL,
    User_Id          INT NOT NULL,
    ClotheVariant_Id INT NULL,
    ClotheType_Id    INT NOT NULL,
    Name             NVARCHAR(60) NOT NULL,
    Origin           NVARCHAR(9)  NOT NULL,
    ImageBase64      VARCHAR(MAX) NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_UserClothes PRIMARY KEY (Id),
    CONSTRAINT FK_UserClothes_User FOREIGN KEY (User_Id) REFERENCES dbo.[User] (Id),
    CONSTRAINT FK_UserClothes_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
    CONSTRAINT FK_UserClothes_Type FOREIGN KEY (ClotheType_Id) REFERENCES dbo.ClotheType (Id),
    CONSTRAINT CK_UserClothes_Origin CHECK (
        (Origin = 'PURCHASED' AND ClotheVariant_Id IS NOT NULL) OR
        (Origin = 'UPLOADED'  AND ClotheVariant_Id IS NULL))
);
GO

-- Outfit: combinación de prendas armada por un usuario.
CREATE TABLE dbo.Outfit (
    Id               INT IDENTITY(1,1) NOT NULL,
    User_Id          INT NOT NULL,
    Name             NVARCHAR(60)  NOT NULL,
    Description      NVARCHAR(200) NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Active           BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Outfit PRIMARY KEY (Id),
    CONSTRAINT FK_Outfit_User FOREIGN KEY (User_Id) REFERENCES dbo.[User] (Id)
);
GO

-- Outfit_has_UserClothes: una prenda puede estar en varios outfits y un outfit tiene varias prendas (N:M).
CREATE TABLE dbo.Outfit_has_UserClothes (
    Outfit_Id      INT NOT NULL,
    UserClothes_Id INT NOT NULL,
    CONSTRAINT PK_Outfit_has_UserClothes PRIMARY KEY (Outfit_Id, UserClothes_Id),
    CONSTRAINT FK_OutfitClothes_Outfit FOREIGN KEY (Outfit_Id) REFERENCES dbo.Outfit (Id) ON DELETE CASCADE,
    CONSTRAINT FK_OutfitClothes_Clothes FOREIGN KEY (UserClothes_Id) REFERENCES dbo.UserClothes (Id)
);
GO
/* ============================================================================
   12. ÍNDICES
   (Las claves UNIQUE ya crean su propio índice; aquí van los filtrados y los de consulta frecuente.)
   ============================================================================ */

-- Únicos filtrados: permiten varios NULL pero no duplicados.
CREATE UNIQUE INDEX UX_Person_DocumentId ON dbo.Person (DocumentId) WHERE DocumentId IS NOT NULL;
CREATE UNIQUE INDEX UX_Person_Email      ON dbo.Person (Email)      WHERE Email IS NOT NULL;
CREATE UNIQUE INDEX UX_LegalEntity_TaxId ON dbo.LegalEntity (TaxId) WHERE TaxId IS NOT NULL;
GO

-- Un empleado solo puede tener UNA asignación vigente (LastDate NULL).
CREATE UNIQUE INDEX UX_PositionHistorial_Current ON dbo.PositionHistorial (Employee_Id) WHERE LastDate IS NULL;
-- Un usuario solo puede tener UN carrito activo.
CREATE UNIQUE INDEX UX_Cart_ActivePerUser ON dbo.Cart (User_Id) WHERE Status = 'ACTIVE';
GO

-- Contacto y seguridad
CREATE INDEX IX_Phones_Person        ON dbo.Phones (Person_Id);
CREATE INDEX IX_Phones_LegalEntity   ON dbo.Phones (LegalEntity_Id);
CREATE INDEX IX_Directions_Person    ON dbo.Directions (Person_Id);
CREATE INDEX IX_AuditLog_Record      ON dbo.AuditLog (TableName, RecordId);
CREATE INDEX IX_AuditLog_Account     ON dbo.AuditLog (Account_Id);
CREATE INDEX IX_AuditLog_Date        ON dbo.AuditLog (AuditDate);

-- Organización
CREATE INDEX IX_Store_WorkArea            ON dbo.Store (WorkArea_Id);
CREATE INDEX IX_PositionHistorial_Employee ON dbo.PositionHistorial (Employee_Id);
CREATE INDEX IX_PositionHistorial_Store    ON dbo.PositionHistorial (Store_Id);
CREATE INDEX IX_PositionHistorial_Area     ON dbo.PositionHistorial (WorkArea_Id);
CREATE INDEX IX_Payroll_Store_Period       ON dbo.Payroll (Store_Id, PeriodEnd);

-- Catálogo e inventario
CREATE INDEX IX_Clothe_Type               ON dbo.Clothe (ClotheType_Id);
CREATE INDEX IX_ClothesInCubicle_Variant  ON dbo.ClothesInCubicle (ClotheVariant_Id);
CREATE INDEX IX_StockMovement_Variant     ON dbo.StockMovement (ClotheVariant_Id);
CREATE INDEX IX_StockMovement_FromStore   ON dbo.StockMovement (FromStore_Id);
CREATE INDEX IX_StockMovement_ToStore     ON dbo.StockMovement (ToStore_Id);

-- Compras
CREATE INDEX IX_PurchaseOrder_Store       ON dbo.PurchaseOrder (Store_Id, ReceivedDate);
CREATE INDEX IX_PurchaseOrder_Supplier    ON dbo.PurchaseOrder (Supplier_Id);
CREATE INDEX IX_Batch_OrderDetail         ON dbo.Batch (PurchaseOrderDetail_Id);

-- Facturación (consultas de balance por tienda y fecha)
CREATE INDEX IX_Bill_Store_Date           ON dbo.Bill (Store_Id, RegistrationDate) INCLUDE (Status, Total);
CREATE INDEX IX_Bill_Person               ON dbo.Bill (Person_Id);
CREATE INDEX IX_Bill_Employee             ON dbo.Bill (Employee_Id);
CREATE INDEX IX_BillDetails_Variant       ON dbo.BillDetails (ClotheVariant_Id);
CREATE INDEX IX_BillPayment_Bill          ON dbo.Bill_has_PaymentMethod (Bill_Id);
CREATE INDEX IX_PaymentCard_User          ON dbo.PaymentCard (User_Id);
CREATE INDEX IX_DiscountTarget_Discount   ON dbo.DiscountTarget (Discount_Id);

-- Gastos y closet
CREATE INDEX IX_Expense_Store_Date        ON dbo.Expense (Store_Id, ExpenseDate);
CREATE INDEX IX_UserClothes_User          ON dbo.UserClothes (User_Id);
CREATE INDEX IX_Outfit_User               ON dbo.Outfit (User_Id);
GO

/* ============================================================================
   13. VISTAS: STOCK Y BALANCES
   Ingresos = facturas PAID/SHIPPED/DELIVERED.
   Egresos  = órdenes de compra RECEIVED + gastos operativos + planillas pagadas.
   ============================================================================ */

-- Stock total por tienda y variante (suma de todos sus cubículos).
CREATE VIEW dbo.vw_StoreStock AS
SELECT r.Store_Id, cic.ClotheVariant_Id, SUM(cic.Quantity) AS Quantity
FROM dbo.ClothesInCubicle cic
JOIN dbo.Cubicle cu ON cu.Id = cic.Cubicle_Id
JOIN dbo.Rack r     ON r.Id = cu.Rack_Id
GROUP BY r.Store_Id, cic.ClotheVariant_Id;
GO

-- Ingresos mensuales por tienda.
CREATE VIEW dbo.vw_StoreIncome AS
SELECT b.Store_Id,
       DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1) AS PeriodMonth,
       SUM(b.Total) AS Income
FROM dbo.Bill b
WHERE b.Active = 1 AND b.Status IN ('PAID','SHIPPED','DELIVERED')
GROUP BY b.Store_Id, DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1);
GO

-- Detalle de egresos por tienda y origen (para saber "en qué" se gastó).
CREATE VIEW dbo.vw_StoreExpenses AS
SELECT po.Store_Id, po.ReceivedDate AS ExpenseDate, N'PURCHASE' AS Source,
       CAST(N'Orden ' + po.OrderNumber AS NVARCHAR(100)) AS Detail, po.Total AS Amount
FROM dbo.PurchaseOrder po
WHERE po.Active = 1 AND po.Status = 'RECEIVED'
UNION ALL
SELECT e.Store_Id, e.ExpenseDate, N'OPERATING', CAST(ec.Name AS NVARCHAR(100)), e.Amount
FROM dbo.Expense e
JOIN dbo.ExpenseCategory ec ON ec.Id = e.ExpenseCategory_Id
WHERE e.Active = 1
UNION ALL
SELECT p.Store_Id, p.PaidDate, N'PAYROLL', CAST(N'Planilla empleado ' + CAST(p.Employee_Id AS NVARCHAR(10)) AS NVARCHAR(100)), p.GrossAmount
FROM dbo.Payroll p
WHERE p.Active = 1 AND p.PaidDate IS NOT NULL;
GO

-- Balance mensual por tienda: ingresos, egresos y utilidad.
CREATE VIEW dbo.vw_StoreBalance AS
WITH inc AS (
    SELECT Store_Id, PeriodMonth, Income FROM dbo.vw_StoreIncome
),
ex AS (
    SELECT Store_Id,
           DATEFROMPARTS(YEAR(ExpenseDate), MONTH(ExpenseDate), 1) AS PeriodMonth,
           SUM(Amount) AS Expenses
    FROM dbo.vw_StoreExpenses
    GROUP BY Store_Id, DATEFROMPARTS(YEAR(ExpenseDate), MONTH(ExpenseDate), 1)
)
SELECT COALESCE(i.Store_Id, e.Store_Id)       AS Store_Id,
       COALESCE(i.PeriodMonth, e.PeriodMonth) AS PeriodMonth,
       ISNULL(i.Income, 0)                    AS Income,
       ISNULL(e.Expenses, 0)                  AS Expenses,
       ISNULL(i.Income, 0) - ISNULL(e.Expenses, 0) AS Profit
FROM inc i
FULL OUTER JOIN ex e ON e.Store_Id = i.Store_Id AND e.PeriodMonth = i.PeriodMonth;
GO

-- Balance mensual consolidado por área (para los jefes de área).
CREATE VIEW dbo.vw_AreaBalance AS
SELECT s.WorkArea_Id, sb.PeriodMonth,
       SUM(sb.Income) AS Income, SUM(sb.Expenses) AS Expenses, SUM(sb.Profit) AS Profit
FROM dbo.vw_StoreBalance sb
JOIN dbo.Store s ON s.Id = sb.Store_Id
GROUP BY s.WorkArea_Id, sb.PeriodMonth;
GO

/* ============================================================================
   14. DATOS INICIALES
   ============================================================================ */

-- Roles (alcance de datos). Admin existe para administrar áreas, roles y configuración global.
INSERT INTO dbo.Role (Name, Description, ScopeType) VALUES
 (N'Customer',    N'Cliente con cuenta web: solo ve lo propio',               'SELF'),
 (N'Cashier',     N'Cajero: factura y consulta inventario de su tienda',      'STORE'),
 (N'Supervisor',  N'Supervisor: control completo de su tienda',               'STORE'),
 (N'AreaManager', N'Jefe de área: gestiona y compara todas las tiendas de su área', 'AREA'),
 (N'Admin',       N'Administrador del sistema',                               'GLOBAL');
GO

-- Permisos: todas las combinaciones módulo x acción.
INSERT INTO dbo.Permission (Code, Module, ActionType)
SELECT m.Module + N'.' + a.ActionType, m.Module, a.ActionType
FROM (VALUES (N'person'),(N'catalog'),(N'inventory'),(N'purchase'),(N'sales'),
             (N'promotion'),(N'hr'),(N'finance'),(N'store'),(N'security'),(N'closet')) AS m(Module)
CROSS JOIN (VALUES (N'create'),(N'read'),(N'update'),(N'delete')) AS a(ActionType);
GO

-- Admin: todos los permisos.
INSERT INTO dbo.RolePermission (Role_Id, Permission_Id)
SELECT r.Id, p.Id FROM dbo.Role r CROSS JOIN dbo.Permission p WHERE r.Name = N'Admin';

-- Jefe de área: todo menos seguridad.
INSERT INTO dbo.RolePermission (Role_Id, Permission_Id)
SELECT r.Id, p.Id FROM dbo.Role r CROSS JOIN dbo.Permission p
WHERE r.Name = N'AreaManager' AND p.Module <> N'security';

-- Supervisor: todo menos seguridad y crear/eliminar tiendas.
INSERT INTO dbo.RolePermission (Role_Id, Permission_Id)
SELECT r.Id, p.Id FROM dbo.Role r CROSS JOIN dbo.Permission p
WHERE r.Name = N'Supervisor' AND p.Module <> N'security'
  AND p.Code NOT IN (N'store.create', N'store.delete');

-- Cajero: vender, consultar inventario/catálogo/promociones y gestionar clientes.
INSERT INTO dbo.RolePermission (Role_Id, Permission_Id)
SELECT r.Id, p.Id FROM dbo.Role r JOIN dbo.Permission p ON p.Code IN
 (N'catalog.read', N'inventory.read', N'promotion.read',
  N'sales.create', N'sales.read',
  N'person.create', N'person.read', N'person.update')
WHERE r.Name = N'Cashier';

-- Cliente web: catálogo, comprar, ver su perfil/facturas y manejar su closet.
INSERT INTO dbo.RolePermission (Role_Id, Permission_Id)
SELECT r.Id, p.Id FROM dbo.Role r JOIN dbo.Permission p ON p.Code IN
 (N'catalog.read', N'sales.create', N'sales.read',
  N'person.read', N'person.update',
  N'closet.create', N'closet.read', N'closet.update', N'closet.delete')
WHERE r.Name = N'Customer';
GO

-- Cargos (cada uno con su rol).
INSERT INTO dbo.Position (Name, Description, Role_Id)
SELECT v.Name, v.Description, r.Id
FROM (VALUES
 (N'Cashier',          N'Cajero de tienda',      N'Cashier'),
 (N'Store Supervisor', N'Supervisor de tienda',  N'Supervisor'),
 (N'Area Manager',     N'Jefe de área o sector', N'AreaManager')) AS v(Name, Description, RoleName)
JOIN dbo.Role r ON r.Name = v.RoleName;
GO

-- Métodos de pago.
INSERT INTO dbo.PaymentMethod (Name, RequiresCard, AllowedInStore, AllowedOnline, ApplyDiscounts) VALUES
 (N'Efectivo',           0, 1, 0, 1),
 (N'Tarjeta de débito',  1, 1, 1, 1),
 (N'Tarjeta de crédito', 1, 1, 1, 1);

-- Impuesto (ISV Honduras 15%; ajustar según el caso del proyecto).
INSERT INTO dbo.Taxes (Name, Percentage) VALUES (N'ISV', 15.00);

-- Categorías de gasto operativo.
INSERT INTO dbo.ExpenseCategory (Name) VALUES
 (N'Energía eléctrica'), (N'Agua'), (N'Alquiler'), (N'Internet y teléfono'),
 (N'Papelería y suministros'), (N'Mantenimiento'), (N'Publicidad'), (N'Otros');

-- Tipos de prenda.
INSERT INTO dbo.ClotheType (Name) VALUES
 (N'Camisas'), (N'Pantalones'), (N'Vestidos'), (N'Chaquetas'), (N'Calzado'), (N'Accesorios');

-- Tallas.
INSERT INTO dbo.Size (Name, SortOrder) VALUES
 (N'XS',1), (N'S',2), (N'M',3), (N'L',4), (N'XL',5), (N'XXL',6), (N'Única',7);

-- Colores.
INSERT INTO dbo.Color (Name, HexCode) VALUES
 (N'Negro','#000000'), (N'Blanco','#FFFFFF'), (N'Gris','#808080'), (N'Azul','#1F4E9C'),
 (N'Rojo','#C62828'), (N'Verde','#2E7D32'), (N'Beige','#D9C7A3');
GO
