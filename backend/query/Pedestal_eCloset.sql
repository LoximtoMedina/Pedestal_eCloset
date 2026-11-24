/* ============================================================================
   PEDESTAL - Script de base de datos (SQL Server)
   Modelo B2C omnicanal: ERP de tiendas + tienda virtual + closet (base).

   Orden del script (se puede ejecutar completo, incluso más de una vez):
     1. Crear la base de datos si no existe
     2. Usar la base de datos
     3. Crear las tablas si no existen (con sus índices)
     4. Crear los roles (roles de SQL Server y permisos sobre las tablas)
     5. Insertar los datos si no existen
     6. Crear las vistas (con los permisos sobre las vistas)

   Estándar de nombres:
   - Tablas y campos en inglés, PascalCase; comentarios en español.
   - Clave primaria: Id (IDENTITY). Clave foránea: <Tabla>_Id.
   - Constraints con nombre: PK_ (primaria), FK_ (foránea), UQ_ (único), CK_ (check), DF_ (default).
   - Índices: IX_ (normal) y UX_ (único). Vistas: vw_. Roles de SQL Server: role_pedestal_.
   - Dinero = DECIMAL(18,2). Texto = NVARCHAR. Fechas con hora = DATETIME2.
   - RegistrationDate = fecha de creación; UpdatedAt la llena el backend.
   - Active = borrado lógico (no se eliminan filas con historial).
   - Todos los campos indican NULL / NOT NULL y llevan comentario.
   ============================================================================ */

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- =============================
-- 1. Crear la base de datos si no existe
-- =============================
IF DB_ID(N'Pedestal_eCloset') IS NULL
BEGIN
    CREATE DATABASE Pedestal_eCloset;
END
GO

-- =============================
-- 2. Usar la base de datos
-- =============================
USE Pedestal_eCloset;
GO

-- =============================
-- 3. Crear las tablas si no existen
-- =============================

-- Gestión de entidades
-- Person: tabla base de toda persona natural (cliente, usuario web, empleado, proveedor natural).
IF OBJECT_ID(N'dbo.Person', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Person (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        DocumentId        NVARCHAR(30) NULL,                                                  -- Documento de identidad (único si existe)
        FirstName         NVARCHAR(45) NOT NULL,                                              -- Primer nombre
        MiddleName        NVARCHAR(45) NULL,                                                  -- Segundo nombre
        FirstSurname      NVARCHAR(45) NOT NULL,                                              -- Primer apellido
        SecondSurname     NVARCHAR(45) NULL,                                                  -- Segundo apellido
        Email             NVARCHAR(100) NULL,                                                 -- Correo (único si existe)
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Person_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_Person_Active DEFAULT 1,                 -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Person PRIMARY KEY (Id),
        CONSTRAINT CK_Person_Email CHECK (Email IS NULL OR Email LIKE '%_@_%._%')
    );
END
GO

-- LegalEntity: persona jurídica (empresa). Antes llamada ArtificialPerson.
IF OBJECT_ID(N'dbo.LegalEntity', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LegalEntity (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        BusinessName      NVARCHAR(100) NOT NULL,                                             -- Razón social
        TradeName         NVARCHAR(100) NULL,                                                 -- Nombre comercial
        TaxId             NVARCHAR(30) NULL,                                                  -- RTN / identificación fiscal (único si existe)
        Email             NVARCHAR(100) NULL,                                                 -- Correo de contacto
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_LegalEntity_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_LegalEntity_Active DEFAULT 1,            -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_LegalEntity PRIMARY KEY (Id)
    );
END
GO

-- Phones: teléfonos de una persona natural O de una empresa (exactamente uno de los dos).
IF OBJECT_ID(N'dbo.Phones', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Phones (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Phone             NVARCHAR(20) NOT NULL,                                              -- Número de teléfono
        Person_Id         INT NULL,                                                           -- Dueño persona natural (NULL si es empresa) → FK a Person.Id
        LegalEntity_Id    INT NULL,                                                           -- Dueño empresa (NULL si es persona) → FK a LegalEntity.Id
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Phones_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Phones_Active DEFAULT 1,                 -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Phones PRIMARY KEY (Id),
        CONSTRAINT FK_Phones_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
        CONSTRAINT FK_Phones_LegalEntity FOREIGN KEY (LegalEntity_Id) REFERENCES dbo.LegalEntity (Id),
        CONSTRAINT CK_Phones_Owner CHECK (
            (Person_Id IS NOT NULL AND LegalEntity_Id IS NULL) OR
            (Person_Id IS NULL AND LegalEntity_Id IS NOT NULL))
    );
END
GO

-- Directions: direcciones de personas o empresas. Sirven también como direcciones de envío.
IF OBJECT_ID(N'dbo.Directions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Directions (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Direction         NVARCHAR(200) NOT NULL,                                             -- Dirección completa
        City              NVARCHAR(60) NULL,                                                  -- Ciudad
        DirectionType     NVARCHAR(10) NOT NULL CONSTRAINT DF_Directions_DirectionType DEFAULT 'HOME', -- HOME / WORK / SHIPPING / OTHER
        IsDefault         BIT NOT NULL CONSTRAINT DF_Directions_IsDefault DEFAULT 0,          -- 1 = dirección de envío predeterminada
        Person_Id         INT NULL,                                                           -- Dueño persona natural (NULL si es empresa) → FK a Person.Id
        LegalEntity_Id    INT NULL,                                                           -- Dueño empresa (NULL si es persona) → FK a LegalEntity.Id
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Directions_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Directions_Active DEFAULT 1,             -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Directions PRIMARY KEY (Id),
        CONSTRAINT FK_Directions_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
        CONSTRAINT FK_Directions_LegalEntity FOREIGN KEY (LegalEntity_Id) REFERENCES dbo.LegalEntity (Id),
        CONSTRAINT CK_Directions_Type CHECK (DirectionType IN ('HOME','WORK','SHIPPING','OTHER')),
        CONSTRAINT CK_Directions_Owner CHECK (
            (Person_Id IS NOT NULL AND LegalEntity_Id IS NULL) OR
            (Person_Id IS NULL AND LegalEntity_Id IS NOT NULL))
    );
END
GO

-- Supplier: proveedor, persona natural (N) o jurídica (J); solo una de las dos referencias.
IF OBJECT_ID(N'dbo.Supplier', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Supplier (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        SupplierType      CHAR(1) NOT NULL,                                                   -- N = persona natural, J = persona jurídica
        Person_Id         INT NULL,                                                           -- Proveedor persona natural (solo si tipo N) → FK a Person.Id
        LegalEntity_Id    INT NULL,                                                           -- Proveedor empresa (solo si tipo J) → FK a LegalEntity.Id
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Supplier_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_Supplier_Active DEFAULT 1,               -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Supplier PRIMARY KEY (Id),
        CONSTRAINT FK_Supplier_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
        CONSTRAINT FK_Supplier_LegalEntity FOREIGN KEY (LegalEntity_Id) REFERENCES dbo.LegalEntity (Id),
        CONSTRAINT CK_Supplier_Type CHECK (
            (SupplierType = 'N' AND Person_Id IS NOT NULL AND LegalEntity_Id IS NULL) OR
            (SupplierType = 'J' AND LegalEntity_Id IS NOT NULL AND Person_Id IS NULL))
    );
END
GO

-- Gestión de seguridad
-- Role: rol GENÉRICO según el nivel del organigrama (no depende de cuántos cargos tenga la empresa).
-- HierarchyLevel: 1 = más alto (dueño) ... 5 = personal de tienda; 9 = cliente (externo a la jerarquía).
-- ScopeType: SELF = solo lo propio, STORE = su tienda, AREA = las tiendas de su área, GLOBAL = todo.
IF OBJECT_ID(N'dbo.Role', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Role (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(45) NOT NULL,                                              -- Nombre del rol genérico (único)
        Description       NVARCHAR(200) NULL,                                                 -- Qué puede hacer este rol
        HierarchyLevel    INT NOT NULL,                                                       -- 1 = más alto (dueño) … 5 = personal de tienda; 9 = cliente
        ScopeType         NVARCHAR(10) NOT NULL,                                              -- Alcance de datos: SELF / STORE / AREA / GLOBAL
        Active            BIT NOT NULL CONSTRAINT DF_Role_Active DEFAULT 1,                   -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Role PRIMARY KEY (Id),
        CONSTRAINT UQ_Role_Name UNIQUE (Name),
        CONSTRAINT CK_Role_Level CHECK (HierarchyLevel BETWEEN 1 AND 9),
        CONSTRAINT CK_Role_Scope CHECK (ScopeType IN ('SELF','STORE','AREA','GLOBAL'))
    );
END
GO

-- Permission: acción posible sobre un módulo (ej. sales.create).
IF OBJECT_ID(N'dbo.Permission', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Permission (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Code              NVARCHAR(60) NOT NULL,                                              -- Código único, ej. sales.create
        Module            NVARCHAR(30) NOT NULL,                                              -- Módulo del sistema
        ActionType        NVARCHAR(10) NOT NULL,                                              -- create / read / update / delete
        CONSTRAINT PK_Permission PRIMARY KEY (Id),
        CONSTRAINT UQ_Permission_Code UNIQUE (Code),
        CONSTRAINT CK_Permission_Action CHECK (ActionType IN ('create','read','update','delete'))
    );
END
GO

-- RolePermission: permisos que tiene cada rol (N:M).
IF OBJECT_ID(N'dbo.RolePermission', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RolePermission (
        Role_Id           INT NOT NULL,                                                       -- Rol → FK a Role.Id
        Permission_Id     INT NOT NULL,                                                       -- Permiso → FK a Permission.Id
        CONSTRAINT PK_RolePermission PRIMARY KEY (Role_Id, Permission_Id),
        CONSTRAINT FK_RolePermission_Role FOREIGN KEY (Role_Id) REFERENCES dbo.Role (Id) ON DELETE CASCADE,
        CONSTRAINT FK_RolePermission_Permission FOREIGN KEY (Permission_Id) REFERENCES dbo.Permission (Id) ON DELETE CASCADE
    );
END
GO

-- Account: credenciales de inicio de sesión. Una persona tiene como máximo una cuenta.
-- Los roles de la cuenta están en AccountRole (Customer al registrarse en la web; el del cargo al contratar).
IF OBJECT_ID(N'dbo.Account', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Account (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Person_Id         INT NOT NULL,                                                       -- Persona dueña de la cuenta (1:1) → FK a Person.Id
        Username          NVARCHAR(60) NOT NULL,                                              -- Nombre de usuario (único)
        PasswordHash      NVARCHAR(255) NOT NULL,                                             -- Hash de la contraseña (nunca texto plano)
        IsLocked          BIT NOT NULL CONSTRAINT DF_Account_IsLocked DEFAULT 0,              -- 1 = cuenta bloqueada
        FailedAttempts    INT NOT NULL CONSTRAINT DF_Account_FailedAttempts DEFAULT 0,        -- Intentos fallidos consecutivos
        LastLoginDate     DATETIME2 NULL,                                                     -- Último inicio de sesión
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Account_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_Account_Active DEFAULT 1,                -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Account PRIMARY KEY (Id),
        CONSTRAINT UQ_Account_Person UNIQUE (Person_Id),
        CONSTRAINT UQ_Account_Username UNIQUE (Username),
        CONSTRAINT FK_Account_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
        CONSTRAINT CK_Account_Failed CHECK (FailedAttempts >= 0)
    );
END
GO

-- AccountRole: roles asignados a una cuenta (N:M). Una persona puede ser Customer y Staff a la vez.
-- Al registrarse en la web el backend inserta el rol Customer; al contratar, el rol del cargo (Position.Role_Id).
IF OBJECT_ID(N'dbo.AccountRole', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AccountRole (
        Account_Id        INT NOT NULL,                                                       -- Cuenta → FK a Account.Id
        Role_Id           INT NOT NULL,                                                       -- Rol asignado a la cuenta → FK a Role.Id
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_AccountRole_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        CONSTRAINT PK_AccountRole PRIMARY KEY (Account_Id, Role_Id),
        CONSTRAINT FK_AccountRole_Account FOREIGN KEY (Account_Id) REFERENCES dbo.Account (Id),
        CONSTRAINT FK_AccountRole_Role FOREIGN KEY (Role_Id) REFERENCES dbo.Role (Id)
    );
END
GO

-- AuditLog: quién cambió qué y cuándo. Lo escribe el backend en cada INSERT/UPDATE/DELETE.
IF OBJECT_ID(N'dbo.AuditLog', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditLog (
        Id                BIGINT IDENTITY(1,1) NOT NULL,                                      -- Clave primaria autoincremental
        Account_Id        INT NULL,                                                           -- Quién hizo el cambio (NULL = sistema) → FK a Account.Id
        TableName         NVARCHAR(60) NOT NULL,                                              -- Tabla afectada
        RecordId          NVARCHAR(50) NOT NULL,                                              -- Id del registro afectado
        ActionType        NVARCHAR(10) NOT NULL,                                              -- INSERT / UPDATE / DELETE / LOGIN
        OldValues         NVARCHAR(MAX) NULL,                                                 -- JSON con los valores anteriores
        NewValues         NVARCHAR(MAX) NULL,                                                 -- JSON con los valores nuevos
        AuditDate         DATETIME2 NOT NULL CONSTRAINT DF_AuditLog_AuditDate DEFAULT SYSUTCDATETIME(), -- Fecha y hora del evento
        CONSTRAINT PK_AuditLog PRIMARY KEY (Id),
        CONSTRAINT FK_AuditLog_Account FOREIGN KEY (Account_Id) REFERENCES dbo.Account (Id),
        CONSTRAINT CK_AuditLog_Action CHECK (ActionType IN ('INSERT','UPDATE','DELETE','LOGIN'))
    );
END
GO

-- [User]: perfil de tienda virtual. Todo User es Person; no toda Person es User.
-- (USER es palabra reservada en T-SQL: siempre escribir dbo.[User]).
IF OBJECT_ID(N'dbo.[User]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[User] (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Person_Id         INT NOT NULL,                                                       -- Persona que tiene cuenta web (1:1) → FK a Person.Id
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_User_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_User_Active DEFAULT 1,                   -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_User PRIMARY KEY (Id),
        CONSTRAINT UQ_User_Person UNIQUE (Person_Id),
        CONSTRAINT FK_User_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id)
    );
END
GO

-- Gestión de organización
-- WorkArea: sector que agrupa varias tiendas y tiene un jefe de área.
IF OBJECT_ID(N'dbo.WorkArea', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.WorkArea (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(45) NOT NULL,                                              -- Nombre del área o sector (único)
        Description       NVARCHAR(200) NULL,                                                 -- Descripción del área
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_WorkArea_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_WorkArea_Active DEFAULT 1,               -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_WorkArea PRIMARY KEY (Id),
        CONSTRAINT UQ_WorkArea_Name UNIQUE (Name)
    );
END
GO

-- Store: tienda. StoreType distingue sucursal física, bodega y tienda virtual.
-- Toda tienda pertenece a un área (la tienda virtual también, ej. área "Central").
IF OBJECT_ID(N'dbo.Store', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Store (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(60) NOT NULL,                                              -- Nombre de la tienda (único)
        Direction         NVARCHAR(200) NULL,                                                 -- Dirección física
        StoreType         NVARCHAR(10) NOT NULL CONSTRAINT DF_Store_StoreType DEFAULT 'PHYSICAL', -- PHYSICAL / WAREHOUSE / VIRTUAL
        WorkArea_Id       INT NOT NULL,                                                       -- Área a la que pertenece → FK a WorkArea.Id
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Store_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_Store_Active DEFAULT 1,                  -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Store PRIMARY KEY (Id),
        CONSTRAINT UQ_Store_Name UNIQUE (Name),
        CONSTRAINT FK_Store_WorkArea FOREIGN KEY (WorkArea_Id) REFERENCES dbo.WorkArea (Id),
        CONSTRAINT CK_Store_Type CHECK (StoreType IN ('PHYSICAL','WAREHOUSE','VIRTUAL'))
    );
END
GO

-- Position: cargo. Cada cargo lleva un rol, así el permiso sale del puesto activo.
IF OBJECT_ID(N'dbo.Position', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Position (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(45) NOT NULL,                                              -- Nombre del cargo (único)
        Description       NVARCHAR(200) NULL,                                                 -- Descripción del cargo
        Role_Id           INT NOT NULL,                                                       -- Rol genérico que otorga este cargo → FK a Role.Id
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Position_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Position_Active DEFAULT 1,               -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Position PRIMARY KEY (Id),
        CONSTRAINT UQ_Position_Name UNIQUE (Name),
        CONSTRAINT FK_Position_Role FOREIGN KEY (Role_Id) REFERENCES dbo.Role (Id)
    );
END
GO

-- Employee: empleado (siempre es una Person). Salary = salario vigente.
IF OBJECT_ID(N'dbo.Employee', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Employee (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Person_Id         INT NOT NULL,                                                       -- Persona empleada (1:1) → FK a Person.Id
        HireDate          DATE NOT NULL CONSTRAINT DF_Employee_HireDate DEFAULT CAST(SYSUTCDATETIME() AS DATE), -- Fecha de contratación
        Salary            DECIMAL(18,2) NOT NULL,                                             -- Salario vigente
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Employee_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_Employee_Active DEFAULT 1,               -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Employee PRIMARY KEY (Id),
        CONSTRAINT UQ_Employee_Person UNIQUE (Person_Id),
        CONSTRAINT FK_Employee_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
        CONSTRAINT CK_Employee_Salary CHECK (Salary >= 0)
    );
END
GO

-- PositionHistorial: historial laboral. LastDate NULL = asignación vigente.
-- Cajero/Supervisor: Store_Id obligatorio. Jefe de área: WorkArea_Id (Store_Id puede ser NULL).
-- Salary guarda el salario de ese período (así no se pierde el historial al subir sueldos).
IF OBJECT_ID(N'dbo.PositionHistorial', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PositionHistorial (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Employee_Id       INT NOT NULL,                                                       -- Empleado → FK a Employee.Id
        Position_Id       INT NOT NULL,                                                       -- Cargo → FK a Position.Id
        Store_Id          INT NULL,                                                           -- Tienda asignada (NULL si es jefe de área) → FK a Store.Id
        WorkArea_Id       INT NULL,                                                           -- Área asignada (jefes de área) → FK a WorkArea.Id
        FirstDate         DATE NOT NULL,                                                      -- Inicio de la asignación
        LastDate          DATE NULL,                                                          -- Fin (NULL = asignación vigente)
        Salary            DECIMAL(18,2) NOT NULL,                                             -- Salario durante este período
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_PositionHistorial_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_PositionHistorial_Active DEFAULT 1,      -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_PositionHistorial PRIMARY KEY (Id),
        CONSTRAINT FK_PositionHistorial_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
        CONSTRAINT FK_PositionHistorial_Position FOREIGN KEY (Position_Id) REFERENCES dbo.Position (Id),
        CONSTRAINT FK_PositionHistorial_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
        CONSTRAINT FK_PositionHistorial_WorkArea FOREIGN KEY (WorkArea_Id) REFERENCES dbo.WorkArea (Id),
        CONSTRAINT CK_PositionHistorial_Dates CHECK (LastDate IS NULL OR LastDate >= FirstDate),
        CONSTRAINT CK_PositionHistorial_Scope CHECK (Store_Id IS NOT NULL OR WorkArea_Id IS NOT NULL),
        CONSTRAINT CK_PositionHistorial_Salary CHECK (Salary >= 0)
    );
END
GO

-- Payroll: planilla pagada a un empleado en un período (egreso de la tienda).
IF OBJECT_ID(N'dbo.Payroll', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payroll (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Employee_Id       INT NOT NULL,                                                       -- Empleado pagado → FK a Employee.Id
        Store_Id          INT NOT NULL,                                                       -- Tienda que absorbe el gasto → FK a Store.Id
        PeriodStart       DATE NOT NULL,                                                      -- Inicio del período
        PeriodEnd         DATE NOT NULL,                                                      -- Fin del período
        GrossAmount       DECIMAL(18,2) NOT NULL,                                             -- Costo total para la empresa
        Deductions        DECIMAL(18,2) NOT NULL CONSTRAINT DF_Payroll_Deductions DEFAULT 0,  -- Deducciones
        NetAmount         AS (GrossAmount - Deductions) PERSISTED,                            -- Calculada: GrossAmount − Deductions
        PaidDate          DATE NULL,                                                          -- Fecha de pago (NULL = pendiente)
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Payroll_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Payroll_Active DEFAULT 1,                -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Payroll PRIMARY KEY (Id),
        CONSTRAINT UQ_Payroll_Period UNIQUE (Employee_Id, PeriodStart, PeriodEnd),
        CONSTRAINT FK_Payroll_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
        CONSTRAINT FK_Payroll_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
        CONSTRAINT CK_Payroll_Period CHECK (PeriodEnd >= PeriodStart),
        CONSTRAINT CK_Payroll_Amounts CHECK (GrossAmount >= 0 AND Deductions >= 0 AND Deductions <= GrossAmount)
    );
END
GO

-- Gestión de catálogo
-- ClotheType: categoría de prenda (camisas, pantalones...).
IF OBJECT_ID(N'dbo.ClotheType', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ClotheType (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(45) NOT NULL,                                              -- Nombre del tipo (único)
        Description       NVARCHAR(200) NULL,                                                 -- Descripción del tipo
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_ClotheType_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_ClotheType_Active DEFAULT 1,             -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_ClotheType PRIMARY KEY (Id),
        CONSTRAINT UQ_ClotheType_Name UNIQUE (Name)
    );
END
GO

-- Clothe: modelo de prenda (ej. "Camisa Oxford"). El stock NO se guarda aquí sino en sus variantes.
-- ImageFileId: id del archivo en SharePoint (la imagen NO se guarda en la BD; la API 1 la pide a SharePoint).
IF OBJECT_ID(N'dbo.Clothe', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Clothe (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(60) NOT NULL,                                              -- Nombre del modelo de prenda
        ClotheType_Id     INT NOT NULL,                                                       -- Tipo de prenda → FK a ClotheType.Id
        Brand             NVARCHAR(45) NULL,                                                  -- Marca
        Description       NVARCHAR(500) NULL,                                                 -- Descripción
        BasePrice         DECIMAL(18,2) NOT NULL,                                             -- Precio base de venta
        ImageFileId       NVARCHAR(200) NULL,                                                 -- Id del archivo en SharePoint (no se guarda la imagen)
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Clothe_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_Clothe_Active DEFAULT 1,                 -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Clothe PRIMARY KEY (Id),
        CONSTRAINT FK_Clothe_ClotheType FOREIGN KEY (ClotheType_Id) REFERENCES dbo.ClotheType (Id),
        CONSTRAINT CK_Clothe_Price CHECK (BasePrice >= 0)
    );
END
GO

-- Size: catálogo de tallas (SortOrder permite mostrarlas en orden XS, S, M...).
IF OBJECT_ID(N'dbo.Size', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Size (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(10) NOT NULL,                                              -- Talla: XS, S, M… (única)
        SortOrder         INT NOT NULL CONSTRAINT DF_Size_SortOrder DEFAULT 0,                -- Orden de visualización
        Active            BIT NOT NULL CONSTRAINT DF_Size_Active DEFAULT 1,                   -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Size PRIMARY KEY (Id),
        CONSTRAINT UQ_Size_Name UNIQUE (Name)
    );
END
GO

-- Color: catálogo de colores.
IF OBJECT_ID(N'dbo.Color', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Color (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(30) NOT NULL,                                              -- Nombre del color (único)
        HexCode           CHAR(7) NULL,                                                       -- Código hexadecimal #RRGGBB
        Active            BIT NOT NULL CONSTRAINT DF_Color_Active DEFAULT 1,                  -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Color PRIMARY KEY (Id),
        CONSTRAINT UQ_Color_Name UNIQUE (Name),
        CONSTRAINT CK_Color_Hex CHECK (HexCode IS NULL OR HexCode LIKE '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')
    );
END
GO

-- ClotheVariant: unidad real de venta e inventario = prenda + talla + color.
-- Facturas, carrito, compras, cubículos y movimientos apuntan a esta tabla.
IF OBJECT_ID(N'dbo.ClotheVariant', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ClotheVariant (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Clothe_Id         INT NOT NULL,                                                       -- Modelo de prenda → FK a Clothe.Id
        Size_Id           INT NOT NULL,                                                       -- Talla → FK a Size.Id
        Color_Id          INT NOT NULL,                                                       -- Color → FK a Color.Id
        Sku               NVARCHAR(40) NOT NULL,                                              -- Código único de la variante
        PriceOverride     DECIMAL(18,2) NULL,                                                 -- Precio propio (NULL = usa BasePrice)
        MinStock          INT NOT NULL CONSTRAINT DF_ClotheVariant_MinStock DEFAULT 0,        -- Stock mínimo para la alerta de stock bajo
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_ClotheVariant_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_ClotheVariant_Active DEFAULT 1,          -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_ClotheVariant PRIMARY KEY (Id),
        CONSTRAINT UQ_ClotheVariant_Sku UNIQUE (Sku),
        CONSTRAINT UQ_ClotheVariant_Combo UNIQUE (Clothe_Id, Size_Id, Color_Id),
        CONSTRAINT FK_ClotheVariant_Clothe FOREIGN KEY (Clothe_Id) REFERENCES dbo.Clothe (Id),
        CONSTRAINT FK_ClotheVariant_Size FOREIGN KEY (Size_Id) REFERENCES dbo.Size (Id),
        CONSTRAINT FK_ClotheVariant_Color FOREIGN KEY (Color_Id) REFERENCES dbo.Color (Id),
        CONSTRAINT CK_ClotheVariant_Price CHECK (PriceOverride IS NULL OR PriceOverride >= 0),
        CONSTRAINT CK_ClotheVariant_MinStock CHECK (MinStock >= 0)
    );
END
GO

-- Gestión de almacén
-- Rack: estante dentro de una tienda. Zone distingue la bodega del piso de venta (POS).
IF OBJECT_ID(N'dbo.Rack', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Rack (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Store_Id          INT NOT NULL,                                                       -- Tienda → FK a Store.Id
        RackNumber        NVARCHAR(45) NOT NULL,                                              -- Código del rack (único por tienda)
        Zone              NVARCHAR(10) NOT NULL CONSTRAINT DF_Rack_Zone DEFAULT 'WAREHOUSE',  -- WAREHOUSE = bodega, POS = piso de venta
        Name              NVARCHAR(45) NULL,                                                  -- Nombre del rack
        Description       NVARCHAR(200) NULL,                                                 -- Descripción
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Rack_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Rack_Active DEFAULT 1,                   -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Rack PRIMARY KEY (Id),
        CONSTRAINT UQ_Rack_Number UNIQUE (Store_Id, RackNumber),
        CONSTRAINT FK_Rack_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
        CONSTRAINT CK_Rack_Zone CHECK (Zone IN ('WAREHOUSE','POS'))
    );
END
GO

-- Cubicle: casilla dentro de un rack.
IF OBJECT_ID(N'dbo.Cubicle', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Cubicle (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Rack_Id           INT NOT NULL,                                                       -- Rack → FK a Rack.Id
        CubicleNumber     NVARCHAR(45) NOT NULL,                                              -- Código del cubículo (único por rack)
        Name              NVARCHAR(45) NULL,                                                  -- Nombre del cubículo
        Description       NVARCHAR(200) NULL,                                                 -- Descripción
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Cubicle_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Cubicle_Active DEFAULT 1,                -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Cubicle PRIMARY KEY (Id),
        CONSTRAINT UQ_Cubicle_Number UNIQUE (Rack_Id, CubicleNumber),
        CONSTRAINT FK_Cubicle_Rack FOREIGN KEY (Rack_Id) REFERENCES dbo.Rack (Id)
    );
END
GO

-- ClothesInCubicle: FUENTE DE VERDAD del stock. Cuántas unidades de cada variante hay en cada cubículo.
-- El stock de una tienda = suma de sus cubículos (ver vw_StoreStock).
IF OBJECT_ID(N'dbo.ClothesInCubicle', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ClothesInCubicle (
        Cubicle_Id        INT NOT NULL,                                                       -- Cubículo → FK a Cubicle.Id
        ClotheVariant_Id  INT NOT NULL,                                                       -- Variante de prenda → FK a ClotheVariant.Id
        Quantity          INT NOT NULL CONSTRAINT DF_ClothesInCubicle_Quantity DEFAULT 0,     -- Unidades en el cubículo (stock real)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        CONSTRAINT PK_ClothesInCubicle PRIMARY KEY (Cubicle_Id, ClotheVariant_Id),
        CONSTRAINT FK_ClothesInCubicle_Cubicle FOREIGN KEY (Cubicle_Id) REFERENCES dbo.Cubicle (Id),
        CONSTRAINT FK_ClothesInCubicle_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
        CONSTRAINT CK_ClothesInCubicle_Qty CHECK (Quantity >= 0)
    );
END
GO

-- Gestión de compras
-- PurchaseOrder: orden de compra a un proveedor para una tienda. Cuenta como egreso al estar RECEIVED.
IF OBJECT_ID(N'dbo.PurchaseOrder', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PurchaseOrder (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        OrderNumber       NVARCHAR(30) NOT NULL,                                              -- Número de orden (único)
        Supplier_Id       INT NOT NULL,                                                       -- Proveedor → FK a Supplier.Id
        Store_Id          INT NOT NULL,                                                       -- Tienda que recibe y paga → FK a Store.Id
        Employee_Id       INT NULL,                                                           -- Empleado que la creó → FK a Employee.Id
        OrderDate         DATE NOT NULL CONSTRAINT DF_PurchaseOrder_OrderDate DEFAULT CAST(SYSUTCDATETIME() AS DATE), -- Fecha de la orden
        ReceivedDate      DATE NULL,                                                          -- Fecha de recepción (obligatoria si RECEIVED)
        Status            NVARCHAR(10) NOT NULL CONSTRAINT DF_PurchaseOrder_Status DEFAULT 'DRAFT', -- DRAFT / SENT / RECEIVED / CANCELLED
        Total             DECIMAL(18,2) NOT NULL CONSTRAINT DF_PurchaseOrder_Total DEFAULT 0, -- Suma de los detalles (la calcula el backend)
        Notes             NVARCHAR(300) NULL,                                                 -- Observaciones
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_PurchaseOrder_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_PurchaseOrder_Active DEFAULT 1,          -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_PurchaseOrder PRIMARY KEY (Id),
        CONSTRAINT UQ_PurchaseOrder_Number UNIQUE (OrderNumber),
        CONSTRAINT FK_PurchaseOrder_Supplier FOREIGN KEY (Supplier_Id) REFERENCES dbo.Supplier (Id),
        CONSTRAINT FK_PurchaseOrder_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
        CONSTRAINT FK_PurchaseOrder_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
        CONSTRAINT CK_PurchaseOrder_Status CHECK (Status IN ('DRAFT','SENT','RECEIVED','CANCELLED')),
        CONSTRAINT CK_PurchaseOrder_Total CHECK (Total >= 0),
        CONSTRAINT CK_PurchaseOrder_Received CHECK (Status <> 'RECEIVED' OR ReceivedDate IS NOT NULL)
    );
END
GO

-- PurchaseOrderDetail: líneas de la orden (variante, cantidad y costo unitario).
IF OBJECT_ID(N'dbo.PurchaseOrderDetail', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PurchaseOrderDetail (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        PurchaseOrder_Id  INT NOT NULL,                                                       -- Orden de compra → FK a PurchaseOrder.Id
        ClotheVariant_Id  INT NOT NULL,                                                       -- Variante comprada → FK a ClotheVariant.Id
        Quantity          INT NOT NULL,                                                       -- Unidades pedidas
        UnitCost          DECIMAL(18,2) NOT NULL,                                             -- Costo por unidad
        SubTotal          AS (Quantity * UnitCost) PERSISTED,                                 -- Calculada: Quantity × UnitCost
        CONSTRAINT PK_PurchaseOrderDetail PRIMARY KEY (Id),
        CONSTRAINT UQ_PurchaseOrderDetail_Line UNIQUE (PurchaseOrder_Id, ClotheVariant_Id),
        CONSTRAINT FK_PurchaseOrderDetail_Order FOREIGN KEY (PurchaseOrder_Id) REFERENCES dbo.PurchaseOrder (Id),
        CONSTRAINT FK_PurchaseOrderDetail_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
        CONSTRAINT CK_PurchaseOrderDetail_Qty CHECK (Quantity > 0),
        CONSTRAINT CK_PurchaseOrderDetail_Cost CHECK (UnitCost >= 0)
    );
END
GO

-- Batch: lote recibido de una línea de orden. Stock = unidades del lote que aún no se han vendido/movido.
-- (Informativo: el stock real por ubicación está en ClothesInCubicle.)
IF OBJECT_ID(N'dbo.Batch', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Batch (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        BatchNumber       NVARCHAR(45) NOT NULL,                                              -- Número de lote (único)
        PurchaseOrderDetail_Id INT NOT NULL,                                                   -- Línea de orden de la que viene → FK a PurchaseOrderDetail.Id
        Quantity          INT NOT NULL,                                                       -- Unidades recibidas
        Stock             INT NOT NULL,                                                       -- Unidades restantes del lote
        ElaborationDate   DATE NULL,                                                          -- Fecha de elaboración
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Batch_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Batch_Active DEFAULT 1,                  -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Batch PRIMARY KEY (Id),
        CONSTRAINT UQ_Batch_Number UNIQUE (BatchNumber),
        CONSTRAINT FK_Batch_OrderDetail FOREIGN KEY (PurchaseOrderDetail_Id) REFERENCES dbo.PurchaseOrderDetail (Id),
        CONSTRAINT CK_Batch_Qty CHECK (Quantity > 0 AND Stock >= 0 AND Stock <= Quantity)
    );
END
GO

-- Gestión de impuestos, descuentos, cupones y pagos
-- Taxes: impuestos configurables (ej. ISV).
IF OBJECT_ID(N'dbo.Taxes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Taxes (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(45) NOT NULL,                                              -- Nombre del impuesto (único)
        Percentage        DECIMAL(5,2) NOT NULL,                                              -- Porcentaje 0–100
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Taxes_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Taxes_Active DEFAULT 1,                  -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Taxes PRIMARY KEY (Id),
        CONSTRAINT UQ_Taxes_Name UNIQUE (Name),
        CONSTRAINT CK_Taxes_Pct CHECK (Percentage BETWEEN 0 AND 100)
    );
END
GO

-- Discounts: descuento por temporada/producto con vigencia.
IF OBJECT_ID(N'dbo.Discounts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Discounts (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(60) NOT NULL,                                              -- Nombre del descuento
        StartDate         DATETIME2 NOT NULL,                                                 -- Inicio de vigencia
        FinishDate        DATETIME2 NOT NULL,                                                 -- Fin de vigencia
        Percentage        DECIMAL(5,2) NOT NULL,                                              -- Porcentaje de descuento
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Discounts_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Discounts_Active DEFAULT 1,              -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Discounts PRIMARY KEY (Id),
        CONSTRAINT CK_Discounts_Pct CHECK (Percentage > 0 AND Percentage <= 100),
        CONSTRAINT CK_Discounts_Dates CHECK (FinishDate >= StartDate)
    );
END
GO

-- DiscountTarget: a qué se aplica un descuento: una prenda O un tipo de prenda (exactamente uno).
IF OBJECT_ID(N'dbo.DiscountTarget', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DiscountTarget (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Discount_Id       INT NOT NULL,                                                       -- Descuento → FK a Discounts.Id
        Clothe_Id         INT NULL,                                                           -- Prenda a la que aplica (o NULL) → FK a Clothe.Id
        ClotheType_Id     INT NULL,                                                           -- Tipo al que aplica (o NULL) → FK a ClotheType.Id
        CONSTRAINT PK_DiscountTarget PRIMARY KEY (Id),
        CONSTRAINT FK_DiscountTarget_Discount FOREIGN KEY (Discount_Id) REFERENCES dbo.Discounts (Id),
        CONSTRAINT FK_DiscountTarget_Clothe FOREIGN KEY (Clothe_Id) REFERENCES dbo.Clothe (Id),
        CONSTRAINT FK_DiscountTarget_Type FOREIGN KEY (ClotheType_Id) REFERENCES dbo.ClotheType (Id),
        CONSTRAINT CK_DiscountTarget_One CHECK (
            (Clothe_Id IS NOT NULL AND ClotheType_Id IS NULL) OR
            (Clothe_Id IS NULL AND ClotheType_Id IS NOT NULL))
    );
END
GO

-- Coupons: cupón promocional por factura. 'P' = porcentaje, 'A' = monto fijo.
-- Validación: vigencia, MaxUses (conteo en Bill_has_Coupons) y MinPurchaseAmount.
IF OBJECT_ID(N'dbo.Coupons', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Coupons (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(60) NOT NULL,                                              -- Nombre del cupón
        Code              NVARCHAR(30) NOT NULL,                                              -- Código del cupón (único)
        DiscountKind      CHAR(1) NOT NULL,                                                   -- P = porcentaje, A = monto fijo
        Percentage        DECIMAL(5,2) NULL,                                                  -- Solo si es P
        Amount            DECIMAL(18,2) NULL,                                                 -- Solo si es A
        StartDate         DATETIME2 NOT NULL,                                                 -- Inicio de vigencia
        FinishDate        DATETIME2 NOT NULL,                                                 -- Fin de vigencia
        MaxUses           INT NULL,                                                           -- Usos máximos (NULL = ilimitado)
        MinPurchaseAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_Coupons_MinPurchaseAmount DEFAULT 0, -- Compra mínima para usarlo
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Coupons_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Coupons_Active DEFAULT 1,                -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Coupons PRIMARY KEY (Id),
        CONSTRAINT UQ_Coupons_Code UNIQUE (Code),
        CONSTRAINT CK_Coupons_Kind CHECK (
            (DiscountKind = 'P' AND Percentage > 0 AND Percentage <= 100 AND Amount IS NULL) OR
            (DiscountKind = 'A' AND Amount > 0 AND Percentage IS NULL)),
        CONSTRAINT CK_Coupons_Dates CHECK (FinishDate >= StartDate),
        CONSTRAINT CK_Coupons_Limits CHECK ((MaxUses IS NULL OR MaxUses > 0) AND MinPurchaseAmount >= 0)
    );
END
GO

-- PaymentMethod: efectivo, tarjeta de débito, tarjeta de crédito...
IF OBJECT_ID(N'dbo.PaymentMethod', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PaymentMethod (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(45) NOT NULL,                                              -- Método de pago (único)
        RequiresCard      BIT NOT NULL CONSTRAINT DF_PaymentMethod_RequiresCard DEFAULT 0,    -- 1 = exige tarjeta
        AllowedInStore    BIT NOT NULL CONSTRAINT DF_PaymentMethod_AllowedInStore DEFAULT 1,  -- 1 = disponible en tienda física
        AllowedOnline     BIT NOT NULL CONSTRAINT DF_PaymentMethod_AllowedOnline DEFAULT 0,   -- 1 = disponible en línea
        ApplyDiscounts    BIT NOT NULL CONSTRAINT DF_PaymentMethod_ApplyDiscounts DEFAULT 1,  -- 1 = permite descuentos y cupones
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_PaymentMethod_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_PaymentMethod_Active DEFAULT 1,          -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_PaymentMethod PRIMARY KEY (Id),
        CONSTRAINT UQ_PaymentMethod_Name UNIQUE (Name)
    );
END
GO

-- PaymentCard: tarjetas del usuario web. Pago SIMULADO: nunca se guarda número completo ni CVV.
IF OBJECT_ID(N'dbo.PaymentCard', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PaymentCard (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        User_Id           INT NOT NULL,                                                       -- Usuario dueño de la tarjeta → FK a User.Id
        HolderName        NVARCHAR(60) NOT NULL,                                              -- Titular
        Brand             NVARCHAR(30) NOT NULL,                                              -- Marca (Visa, Mastercard…)
        CardType          NVARCHAR(6) NOT NULL,                                               -- DEBIT / CREDIT
        Last4             CHAR(4) NOT NULL,                                                   -- Últimos 4 dígitos (nunca el número completo ni CVV)
        ExpirationDate    DATE NOT NULL,                                                      -- Fecha de vencimiento
        IsDefault         BIT NOT NULL CONSTRAINT DF_PaymentCard_IsDefault DEFAULT 0,         -- 1 = tarjeta predeterminada
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_PaymentCard_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_PaymentCard_Active DEFAULT 1,            -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_PaymentCard PRIMARY KEY (Id),
        CONSTRAINT FK_PaymentCard_User FOREIGN KEY (User_Id) REFERENCES dbo.[User] (Id),
        CONSTRAINT CK_PaymentCard_Type CHECK (CardType IN ('DEBIT','CREDIT')),
        CONSTRAINT CK_PaymentCard_Last4 CHECK (Last4 LIKE '[0-9][0-9][0-9][0-9]')
    );
END
GO

-- Gestión de facturación y caja
-- CashRegister: caja (punto de venta) física de una tienda.
IF OBJECT_ID(N'dbo.CashRegister', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CashRegister (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Store_Id          INT NOT NULL,                                                       -- Tienda a la que pertenece → FK a Store.Id
        Name              NVARCHAR(45) NOT NULL,                                              -- Nombre de la caja (único por tienda)
        Description       NVARCHAR(100) NULL,                                                 -- Descripción de la caja
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_CashRegister_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_CashRegister_Active DEFAULT 1,           -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_CashRegister PRIMARY KEY (Id),
        CONSTRAINT UQ_CashRegister_Name UNIQUE (Store_Id, Name),
        CONSTRAINT FK_CashRegister_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id)
    );
END
GO

-- CashShift: turno de caja de un empleado (apertura y cierre). Toda venta en tienda se registra en un turno abierto.
IF OBJECT_ID(N'dbo.CashShift', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CashShift (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        CashRegister_Id   INT NOT NULL,                                                       -- Caja del turno → FK a CashRegister.Id
        Employee_Id       INT NOT NULL,                                                       -- Empleado que atiende la caja → FK a Employee.Id
        OpenedAt          DATETIME2 NOT NULL CONSTRAINT DF_CashShift_OpenedAt DEFAULT SYSUTCDATETIME(), -- Fecha y hora de apertura del turno
        ClosedAt          DATETIME2 NULL,                                                     -- Fecha y hora de cierre (NULL = turno abierto)
        OpeningAmount     DECIMAL(18,2) NOT NULL CONSTRAINT DF_CashShift_OpeningAmount DEFAULT 0, -- Efectivo con el que se abre la caja
        ClosingAmount     DECIMAL(18,2) NULL,                                                 -- Efectivo contado al cerrar (NULL = turno abierto)
        Status            NVARCHAR(6) NOT NULL CONSTRAINT DF_CashShift_Status DEFAULT 'OPEN', -- OPEN / CLOSED
        CONSTRAINT PK_CashShift PRIMARY KEY (Id),
        CONSTRAINT FK_CashShift_Register FOREIGN KEY (CashRegister_Id) REFERENCES dbo.CashRegister (Id),
        CONSTRAINT FK_CashShift_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
        CONSTRAINT CK_CashShift_Status CHECK (Status IN ('OPEN','CLOSED')),
        CONSTRAINT CK_CashShift_Closing CHECK (
            (Status = 'OPEN'   AND ClosedAt IS NULL AND ClosingAmount IS NULL) OR
            (Status = 'CLOSED' AND ClosedAt IS NOT NULL AND ClosingAmount IS NOT NULL AND ClosedAt >= OpenedAt)),
        CONSTRAINT CK_CashShift_Amounts CHECK (OpeningAmount >= 0 AND (ClosingAmount IS NULL OR ClosingAmount >= 0))
    );
END
GO

-- Bill: factura. Cliente = Person (con o sin cuenta web). Store_Id = tienda que vende/despacha.
-- Channel: INSTORE exige cajero (Employee_Id) y turno de caja (CashShift_Id); ONLINE no lleva ninguno.
-- El envío de una venta online se registra en Shipment.
-- Los totales los calcula el backend dentro de una transacción.
IF OBJECT_ID(N'dbo.Bill', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Bill (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        BillCode          NVARCHAR(30) NOT NULL,                                              -- Código de factura (único)
        Person_Id         INT NOT NULL,                                                       -- Cliente (con o sin cuenta web) → FK a Person.Id
        Store_Id          INT NOT NULL,                                                       -- Tienda que vende o despacha → FK a Store.Id
        Employee_Id       INT NULL,                                                           -- Cajero (NULL en ventas online) → FK a Employee.Id
        Channel           NVARCHAR(7) NOT NULL,                                               -- INSTORE / ONLINE
        Status            NVARCHAR(10) NOT NULL CONSTRAINT DF_Bill_Status DEFAULT 'PENDING',  -- PENDING / PAID / SHIPPED / DELIVERED / CANCELLED
        CashShift_Id      INT NULL,                                                           -- Turno de caja (solo ventas en tienda) → FK a CashShift.Id
        SubTotal          DECIMAL(18,2) NOT NULL CONSTRAINT DF_Bill_SubTotal DEFAULT 0,       -- Total antes de descuentos e impuestos
        DiscountTotal     DECIMAL(18,2) NOT NULL CONSTRAINT DF_Bill_DiscountTotal DEFAULT 0,  -- Total de descuentos de líneas
        CouponTotal       DECIMAL(18,2) NOT NULL CONSTRAINT DF_Bill_CouponTotal DEFAULT 0,    -- Total descontado por cupones
        TaxTotal          DECIMAL(18,2) NOT NULL CONSTRAINT DF_Bill_TaxTotal DEFAULT 0,       -- Total de impuestos
        ShippingTotal     DECIMAL(18,2) NOT NULL CONSTRAINT DF_Bill_ShippingTotal DEFAULT 0,  -- Costo de envío de la factura
        Total             DECIMAL(18,2) NOT NULL CONSTRAINT DF_Bill_Total DEFAULT 0,          -- Total a pagar
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Bill_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_Bill_Active DEFAULT 1,                   -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Bill PRIMARY KEY (Id),
        CONSTRAINT UQ_Bill_Code UNIQUE (BillCode),
        CONSTRAINT FK_Bill_Person FOREIGN KEY (Person_Id) REFERENCES dbo.Person (Id),
        CONSTRAINT FK_Bill_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
        CONSTRAINT FK_Bill_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
        CONSTRAINT FK_Bill_CashShift FOREIGN KEY (CashShift_Id) REFERENCES dbo.CashShift (Id),
        CONSTRAINT CK_Bill_Channel CHECK (Channel IN ('INSTORE','ONLINE')),
        CONSTRAINT CK_Bill_Status CHECK (Status IN ('PENDING','PAID','SHIPPED','DELIVERED','CANCELLED')),
        CONSTRAINT CK_Bill_Cashier CHECK (
            (Channel = 'INSTORE' AND Employee_Id IS NOT NULL AND CashShift_Id IS NOT NULL) OR
            (Channel = 'ONLINE'  AND Employee_Id IS NULL AND CashShift_Id IS NULL)),
        CONSTRAINT CK_Bill_Amounts CHECK (SubTotal >= 0 AND DiscountTotal >= 0 AND CouponTotal >= 0 AND TaxTotal >= 0 AND ShippingTotal >= 0 AND Total >= 0)
    );
END
GO

-- Shipment: envío de una factura online (uno por factura). La dirección sale de Directions.
IF OBJECT_ID(N'dbo.Shipment', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Shipment (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Bill_Id           INT NOT NULL,                                                       -- Factura enviada (relación 1:1) → FK a Bill.Id
        Direction_Id      INT NOT NULL,                                                       -- Dirección de entrega → FK a Directions.Id
        TrackingNumber    NVARCHAR(45) NULL,                                                  -- Número de guía
        Carrier           NVARCHAR(45) NULL,                                                  -- Transportista
        Status            NVARCHAR(10) NOT NULL CONSTRAINT DF_Shipment_Status DEFAULT 'PREPARING', -- PREPARING / SHIPPED / DELIVERED / RETURNED
        ShippingCost      DECIMAL(18,2) NOT NULL CONSTRAINT DF_Shipment_ShippingCost DEFAULT 0, -- Costo del envío
        ShippedDate       DATE NULL,                                                          -- Fecha de salida
        DeliveredDate     DATE NULL,                                                          -- Fecha de entrega
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Shipment_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        Active            BIT NOT NULL CONSTRAINT DF_Shipment_Active DEFAULT 1,               -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Shipment PRIMARY KEY (Id),
        CONSTRAINT UQ_Shipment_Bill UNIQUE (Bill_Id),
        CONSTRAINT FK_Shipment_Bill FOREIGN KEY (Bill_Id) REFERENCES dbo.Bill (Id),
        CONSTRAINT FK_Shipment_Direction FOREIGN KEY (Direction_Id) REFERENCES dbo.Directions (Id),
        CONSTRAINT CK_Shipment_Status CHECK (Status IN ('PREPARING','SHIPPED','DELIVERED','RETURNED')),
        CONSTRAINT CK_Shipment_Cost CHECK (ShippingCost >= 0),
        CONSTRAINT CK_Shipment_Dates CHECK (DeliveredDate IS NULL OR (ShippedDate IS NOT NULL AND DeliveredDate >= ShippedDate))
    );
END
GO

-- BillDetails: líneas de la factura (una variante por línea). SubTotal y Total se calculan solos.
IF OBJECT_ID(N'dbo.BillDetails', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BillDetails (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Bill_Id           INT NOT NULL,                                                       -- Factura → FK a Bill.Id
        ClotheVariant_Id  INT NOT NULL,                                                       -- Variante vendida → FK a ClotheVariant.Id
        Quantity          INT NOT NULL,                                                       -- Unidades vendidas
        UnitPrice         DECIMAL(18,2) NOT NULL,                                             -- Precio al momento de la venta
        DiscountAmount    DECIMAL(18,2) NOT NULL CONSTRAINT DF_BillDetails_DiscountAmount DEFAULT 0, -- Descuento de la línea
        TaxAmount         DECIMAL(18,2) NOT NULL CONSTRAINT DF_BillDetails_TaxAmount DEFAULT 0, -- Impuesto de la línea
        SubTotal          AS (Quantity * UnitPrice) PERSISTED,                                -- Calculada: Quantity × UnitPrice
        Total             AS (Quantity * UnitPrice - DiscountAmount + TaxAmount) PERSISTED,   -- Calculada: SubTotal − DiscountAmount + TaxAmount
        CONSTRAINT PK_BillDetails PRIMARY KEY (Id),
        CONSTRAINT UQ_BillDetails_Line UNIQUE (Bill_Id, ClotheVariant_Id),
        CONSTRAINT FK_BillDetails_Bill FOREIGN KEY (Bill_Id) REFERENCES dbo.Bill (Id),
        CONSTRAINT FK_BillDetails_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
        CONSTRAINT CK_BillDetails_Qty CHECK (Quantity > 0),
        CONSTRAINT CK_BillDetails_Amounts CHECK (UnitPrice >= 0 AND DiscountAmount >= 0 AND TaxAmount >= 0)
    );
END
GO

-- AppliedTaxes: impuestos aplicados a una línea (guarda el % vigente en ese momento).
IF OBJECT_ID(N'dbo.AppliedTaxes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AppliedTaxes (
        BillDetails_Id    INT NOT NULL,                                                       -- Línea de factura → FK a BillDetails.Id
        Taxes_Id          INT NOT NULL,                                                       -- Impuesto aplicado → FK a Taxes.Id
        Percentage        DECIMAL(5,2) NOT NULL,                                              -- % vigente al momento de la venta
        Amount            DECIMAL(18,2) NOT NULL,                                             -- Monto del impuesto
        CONSTRAINT PK_AppliedTaxes PRIMARY KEY (BillDetails_Id, Taxes_Id),
        CONSTRAINT FK_AppliedTaxes_Detail FOREIGN KEY (BillDetails_Id) REFERENCES dbo.BillDetails (Id),
        CONSTRAINT FK_AppliedTaxes_Tax FOREIGN KEY (Taxes_Id) REFERENCES dbo.Taxes (Id),
        CONSTRAINT CK_AppliedTaxes_Amounts CHECK (Percentage BETWEEN 0 AND 100 AND Amount >= 0)
    );
END
GO

-- AppliedDiscounts: descuentos aplicados a una línea (guarda el % vigente en ese momento).
IF OBJECT_ID(N'dbo.AppliedDiscounts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AppliedDiscounts (
        BillDetails_Id    INT NOT NULL,                                                       -- Línea de factura → FK a BillDetails.Id
        Discounts_Id      INT NOT NULL,                                                       -- Descuento aplicado → FK a Discounts.Id
        Percentage        DECIMAL(5,2) NOT NULL,                                              -- % vigente al momento de la venta
        Amount            DECIMAL(18,2) NOT NULL,                                             -- Monto descontado
        CONSTRAINT PK_AppliedDiscounts PRIMARY KEY (BillDetails_Id, Discounts_Id),
        CONSTRAINT FK_AppliedDiscounts_Detail FOREIGN KEY (BillDetails_Id) REFERENCES dbo.BillDetails (Id),
        CONSTRAINT FK_AppliedDiscounts_Discount FOREIGN KEY (Discounts_Id) REFERENCES dbo.Discounts (Id),
        CONSTRAINT CK_AppliedDiscounts_Amounts CHECK (Percentage BETWEEN 0 AND 100 AND Amount >= 0)
    );
END
GO

-- Bill_has_Coupons: cupones usados en una factura.
IF OBJECT_ID(N'dbo.Bill_has_Coupons', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Bill_has_Coupons (
        Bill_Id           INT NOT NULL,                                                       -- Factura → FK a Bill.Id
        Coupons_Id        INT NOT NULL,                                                       -- Cupón usado → FK a Coupons.Id
        AppliedAmount     DECIMAL(18,2) NOT NULL,                                             -- Monto descontado por el cupón
        CONSTRAINT PK_Bill_has_Coupons PRIMARY KEY (Bill_Id, Coupons_Id),
        CONSTRAINT FK_BillCoupons_Bill FOREIGN KEY (Bill_Id) REFERENCES dbo.Bill (Id),
        CONSTRAINT FK_BillCoupons_Coupon FOREIGN KEY (Coupons_Id) REFERENCES dbo.Coupons (Id),
        CONSTRAINT CK_BillCoupons_Amount CHECK (AppliedAmount >= 0)
    );
END
GO

-- Bill_has_PaymentMethod: pagos de una factura. Permite pagos mixtos (ej. 60% tarjeta + 40% efectivo).
-- Regla de negocio (backend): la suma de PaidAmount = Bill.Total; online = 100% tarjeta.
IF OBJECT_ID(N'dbo.Bill_has_PaymentMethod', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Bill_has_PaymentMethod (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Bill_Id           INT NOT NULL,                                                       -- Factura → FK a Bill.Id
        PaymentMethod_Id  INT NOT NULL,                                                       -- Método de pago → FK a PaymentMethod.Id
        PaymentCard_Id    INT NULL,                                                           -- Tarjeta usada (si el método la requiere) → FK a PaymentCard.Id
        PaidAmount        DECIMAL(18,2) NOT NULL,                                             -- Monto pagado con este método
        PaymentReference  NVARCHAR(60) NULL,                                                  -- Código de la transacción simulada
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Bill_has_PaymentMethod_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        CONSTRAINT PK_Bill_has_PaymentMethod PRIMARY KEY (Id),
        CONSTRAINT FK_BillPayment_Bill FOREIGN KEY (Bill_Id) REFERENCES dbo.Bill (Id),
        CONSTRAINT FK_BillPayment_Method FOREIGN KEY (PaymentMethod_Id) REFERENCES dbo.PaymentMethod (Id),
        CONSTRAINT FK_BillPayment_Card FOREIGN KEY (PaymentCard_Id) REFERENCES dbo.PaymentCard (Id),
        CONSTRAINT CK_BillPayment_Amount CHECK (PaidAmount > 0)
    );
END
GO

-- Gestión de almacén
-- StockMovement: historial de movimientos de stock (entradas, salidas, traslados, ajustes).
-- Se define aquí porque una salida puede venir de una línea de factura (BillDetails_Id).
IF OBJECT_ID(N'dbo.StockMovement', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.StockMovement (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        MovementType      NVARCHAR(8) NOT NULL,                                               -- IN / OUT / TRANSFER / ADJUST
        ClotheVariant_Id  INT NOT NULL,                                                       -- Variante movida → FK a ClotheVariant.Id
        Quantity          INT NOT NULL,                                                       -- Unidades movidas (> 0)
        Batch_Id          INT NULL,                                                           -- Lote (opcional) → FK a Batch.Id
        BillDetails_Id    INT NULL,                                                           -- Línea de factura si fue por una venta → FK a BillDetails.Id
        FromStore_Id      INT NULL,                                                           -- Tienda de origen → FK a Store.Id
        FromCubicle_Id    INT NULL,                                                           -- Cubículo de origen → FK a Cubicle.Id
        ToStore_Id        INT NULL,                                                           -- Tienda de destino → FK a Store.Id
        ToCubicle_Id      INT NULL,                                                           -- Cubículo de destino → FK a Cubicle.Id
        Reason            NVARCHAR(200) NULL,                                                 -- Motivo (ej. merma, ajuste)
        Employee_Id       INT NULL,                                                           -- Quién lo registró (NULL = sistema) → FK a Employee.Id
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_StockMovement_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_StockMovement_Active DEFAULT 1,          -- Borrado lógico: 1 = activo, 0 = inactivo
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
END
GO

-- Gestión de tienda virtual
-- Cart: carrito del usuario web. Solo puede haber un carrito ACTIVE por usuario (índice único filtrado).
IF OBJECT_ID(N'dbo.Cart', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Cart (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        User_Id           INT NOT NULL,                                                       -- Usuario dueño del carrito → FK a User.Id
        Status            NVARCHAR(10) NOT NULL CONSTRAINT DF_Cart_Status DEFAULT 'ACTIVE',   -- ACTIVE / CONVERTED / ABANDONED
        Bill_Id           INT NULL,                                                           -- Factura generada al comprar → FK a Bill.Id
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Cart_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        UpdatedAt         DATETIME2 NULL,                                                     -- Fecha de última modificación (la llena el backend)
        CONSTRAINT PK_Cart PRIMARY KEY (Id),
        CONSTRAINT FK_Cart_User FOREIGN KEY (User_Id) REFERENCES dbo.[User] (Id),
        CONSTRAINT FK_Cart_Bill FOREIGN KEY (Bill_Id) REFERENCES dbo.Bill (Id),
        CONSTRAINT CK_Cart_Status CHECK (Status IN ('ACTIVE','CONVERTED','ABANDONED'))
    );
END
GO

-- CartDetail: variantes dentro del carrito.
IF OBJECT_ID(N'dbo.CartDetail', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CartDetail (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Cart_Id           INT NOT NULL,                                                       -- Carrito → FK a Cart.Id
        ClotheVariant_Id  INT NOT NULL,                                                       -- Variante agregada → FK a ClotheVariant.Id
        Quantity          INT NOT NULL,                                                       -- Unidades
        AddedDate         DATETIME2 NOT NULL CONSTRAINT DF_CartDetail_AddedDate DEFAULT SYSUTCDATETIME(), -- Cuándo se agregó
        CONSTRAINT PK_CartDetail PRIMARY KEY (Id),
        CONSTRAINT UQ_CartDetail_Line UNIQUE (Cart_Id, ClotheVariant_Id),
        CONSTRAINT FK_CartDetail_Cart FOREIGN KEY (Cart_Id) REFERENCES dbo.Cart (Id) ON DELETE CASCADE,
        CONSTRAINT FK_CartDetail_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
        CONSTRAINT CK_CartDetail_Qty CHECK (Quantity > 0)
    );
END
GO

-- Gestión de gastos
-- ExpenseCategory: en qué se gasta (luz, agua, alquiler, papelería...).
IF OBJECT_ID(N'dbo.ExpenseCategory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ExpenseCategory (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Name              NVARCHAR(60) NOT NULL,                                              -- Categoría de gasto (única)
        Description       NVARCHAR(200) NULL,                                                 -- Descripción
        Active            BIT NOT NULL CONSTRAINT DF_ExpenseCategory_Active DEFAULT 1,        -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_ExpenseCategory PRIMARY KEY (Id),
        CONSTRAINT UQ_ExpenseCategory_Name UNIQUE (Name)
    );
END
GO

-- Expense: gasto operativo de una tienda (no incluye compras de mercadería ni planillas, que tienen su tabla).
IF OBJECT_ID(N'dbo.Expense', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Expense (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        Store_Id          INT NOT NULL,                                                       -- Tienda que paga → FK a Store.Id
        ExpenseCategory_Id INT NOT NULL,                                                       -- En qué se gastó → FK a ExpenseCategory.Id
        Amount            DECIMAL(18,2) NOT NULL,                                             -- Monto (> 0)
        ExpenseDate       DATE NOT NULL,                                                      -- Fecha del gasto
        Description       NVARCHAR(200) NULL,                                                 -- Detalle del gasto
        Employee_Id       INT NULL,                                                           -- Quién lo registró → FK a Employee.Id
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Expense_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Expense_Active DEFAULT 1,                -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Expense PRIMARY KEY (Id),
        CONSTRAINT FK_Expense_Store FOREIGN KEY (Store_Id) REFERENCES dbo.Store (Id),
        CONSTRAINT FK_Expense_Category FOREIGN KEY (ExpenseCategory_Id) REFERENCES dbo.ExpenseCategory (Id),
        CONSTRAINT FK_Expense_Employee FOREIGN KEY (Employee_Id) REFERENCES dbo.Employee (Id),
        CONSTRAINT CK_Expense_Amount CHECK (Amount > 0)
    );
END
GO

-- Gestión de closet virtual
-- UserClothes: guardarropa del usuario. PURCHASED = viene de una compra (variante); UPLOADED = prenda propia.
IF OBJECT_ID(N'dbo.UserClothes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserClothes (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        User_Id           INT NOT NULL,                                                       -- Usuario dueño de la prenda → FK a User.Id
        ClotheVariant_Id  INT NULL,                                                           -- Variante comprada (NULL si es prenda propia) → FK a ClotheVariant.Id
        ClotheType_Id     INT NOT NULL,                                                       -- Tipo de prenda → FK a ClotheType.Id
        Name              NVARCHAR(60) NOT NULL,                                              -- Nombre de la prenda
        Origin            NVARCHAR(9) NOT NULL,                                               -- PURCHASED / UPLOADED
        ImageFileId       NVARCHAR(200) NULL,                                                 -- Id del archivo en SharePoint
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_UserClothes_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_UserClothes_Active DEFAULT 1,            -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_UserClothes PRIMARY KEY (Id),
        CONSTRAINT FK_UserClothes_User FOREIGN KEY (User_Id) REFERENCES dbo.[User] (Id),
        CONSTRAINT FK_UserClothes_Variant FOREIGN KEY (ClotheVariant_Id) REFERENCES dbo.ClotheVariant (Id),
        CONSTRAINT FK_UserClothes_Type FOREIGN KEY (ClotheType_Id) REFERENCES dbo.ClotheType (Id),
        CONSTRAINT CK_UserClothes_Origin CHECK (
            (Origin = 'PURCHASED' AND ClotheVariant_Id IS NOT NULL) OR
            (Origin = 'UPLOADED'  AND ClotheVariant_Id IS NULL))
    );
END
GO

-- Outfit: combinación de prendas armada por un usuario.
IF OBJECT_ID(N'dbo.Outfit', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Outfit (
        Id                INT IDENTITY(1,1) NOT NULL,                                         -- Clave primaria autoincremental
        User_Id           INT NOT NULL,                                                       -- Usuario dueño del outfit → FK a User.Id
        Name              NVARCHAR(60) NOT NULL,                                              -- Nombre del outfit
        Description       NVARCHAR(200) NULL,                                                 -- Descripción
        RegistrationDate  DATETIME2 NOT NULL CONSTRAINT DF_Outfit_RegistrationDate DEFAULT SYSUTCDATETIME(), -- Fecha de creación del registro (UTC)
        Active            BIT NOT NULL CONSTRAINT DF_Outfit_Active DEFAULT 1,                 -- Borrado lógico: 1 = activo, 0 = inactivo
        CONSTRAINT PK_Outfit PRIMARY KEY (Id),
        CONSTRAINT FK_Outfit_User FOREIGN KEY (User_Id) REFERENCES dbo.[User] (Id)
    );
END
GO

-- Outfit_has_UserClothes: una prenda puede estar en varios outfits y un outfit tiene varias prendas (N:M).
IF OBJECT_ID(N'dbo.Outfit_has_UserClothes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Outfit_has_UserClothes (
        Outfit_Id         INT NOT NULL,                                                       -- Outfit → FK a Outfit.Id
        UserClothes_Id    INT NOT NULL,                                                       -- Prenda del closet → FK a UserClothes.Id
        CONSTRAINT PK_Outfit_has_UserClothes PRIMARY KEY (Outfit_Id, UserClothes_Id),
        CONSTRAINT FK_OutfitClothes_Outfit FOREIGN KEY (Outfit_Id) REFERENCES dbo.Outfit (Id) ON DELETE CASCADE,
        CONSTRAINT FK_OutfitClothes_Clothes FOREIGN KEY (UserClothes_Id) REFERENCES dbo.UserClothes (Id)
    );
END
GO

-- Índices (únicos filtrados y de consulta frecuente)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Person_DocumentId' AND object_id = OBJECT_ID(N'dbo.Person'))
    CREATE UNIQUE INDEX UX_Person_DocumentId ON dbo.Person (DocumentId) WHERE DocumentId IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Person_Email' AND object_id = OBJECT_ID(N'dbo.Person'))
    CREATE UNIQUE INDEX UX_Person_Email ON dbo.Person (Email)      WHERE Email IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_LegalEntity_TaxId' AND object_id = OBJECT_ID(N'dbo.LegalEntity'))
    CREATE UNIQUE INDEX UX_LegalEntity_TaxId ON dbo.LegalEntity (TaxId) WHERE TaxId IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_PositionHistorial_Current' AND object_id = OBJECT_ID(N'dbo.PositionHistorial'))
    CREATE UNIQUE INDEX UX_PositionHistorial_Current ON dbo.PositionHistorial (Employee_Id) WHERE LastDate IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Cart_ActivePerUser' AND object_id = OBJECT_ID(N'dbo.Cart'))
    CREATE UNIQUE INDEX UX_Cart_ActivePerUser ON dbo.Cart (User_Id) WHERE Status = 'ACTIVE';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Phones_Person' AND object_id = OBJECT_ID(N'dbo.Phones'))
    CREATE INDEX IX_Phones_Person ON dbo.Phones (Person_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Phones_LegalEntity' AND object_id = OBJECT_ID(N'dbo.Phones'))
    CREATE INDEX IX_Phones_LegalEntity ON dbo.Phones (LegalEntity_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Directions_Person' AND object_id = OBJECT_ID(N'dbo.Directions'))
    CREATE INDEX IX_Directions_Person ON dbo.Directions (Person_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLog_Record' AND object_id = OBJECT_ID(N'dbo.AuditLog'))
    CREATE INDEX IX_AuditLog_Record ON dbo.AuditLog (TableName, RecordId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLog_Account' AND object_id = OBJECT_ID(N'dbo.AuditLog'))
    CREATE INDEX IX_AuditLog_Account ON dbo.AuditLog (Account_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLog_Date' AND object_id = OBJECT_ID(N'dbo.AuditLog'))
    CREATE INDEX IX_AuditLog_Date ON dbo.AuditLog (AuditDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Store_WorkArea' AND object_id = OBJECT_ID(N'dbo.Store'))
    CREATE INDEX IX_Store_WorkArea ON dbo.Store (WorkArea_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PositionHistorial_Employee' AND object_id = OBJECT_ID(N'dbo.PositionHistorial'))
    CREATE INDEX IX_PositionHistorial_Employee ON dbo.PositionHistorial (Employee_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PositionHistorial_Store' AND object_id = OBJECT_ID(N'dbo.PositionHistorial'))
    CREATE INDEX IX_PositionHistorial_Store ON dbo.PositionHistorial (Store_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PositionHistorial_Area' AND object_id = OBJECT_ID(N'dbo.PositionHistorial'))
    CREATE INDEX IX_PositionHistorial_Area ON dbo.PositionHistorial (WorkArea_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Payroll_Store_Period' AND object_id = OBJECT_ID(N'dbo.Payroll'))
    CREATE INDEX IX_Payroll_Store_Period ON dbo.Payroll (Store_Id, PeriodEnd);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Clothe_Type' AND object_id = OBJECT_ID(N'dbo.Clothe'))
    CREATE INDEX IX_Clothe_Type ON dbo.Clothe (ClotheType_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ClothesInCubicle_Variant' AND object_id = OBJECT_ID(N'dbo.ClothesInCubicle'))
    CREATE INDEX IX_ClothesInCubicle_Variant ON dbo.ClothesInCubicle (ClotheVariant_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_StockMovement_Variant' AND object_id = OBJECT_ID(N'dbo.StockMovement'))
    CREATE INDEX IX_StockMovement_Variant ON dbo.StockMovement (ClotheVariant_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_StockMovement_FromStore' AND object_id = OBJECT_ID(N'dbo.StockMovement'))
    CREATE INDEX IX_StockMovement_FromStore ON dbo.StockMovement (FromStore_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_StockMovement_ToStore' AND object_id = OBJECT_ID(N'dbo.StockMovement'))
    CREATE INDEX IX_StockMovement_ToStore ON dbo.StockMovement (ToStore_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PurchaseOrder_Store' AND object_id = OBJECT_ID(N'dbo.PurchaseOrder'))
    CREATE INDEX IX_PurchaseOrder_Store ON dbo.PurchaseOrder (Store_Id, ReceivedDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PurchaseOrder_Supplier' AND object_id = OBJECT_ID(N'dbo.PurchaseOrder'))
    CREATE INDEX IX_PurchaseOrder_Supplier ON dbo.PurchaseOrder (Supplier_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Batch_OrderDetail' AND object_id = OBJECT_ID(N'dbo.Batch'))
    CREATE INDEX IX_Batch_OrderDetail ON dbo.Batch (PurchaseOrderDetail_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_CashShift_OpenPerRegister' AND object_id = OBJECT_ID(N'dbo.CashShift'))
    CREATE UNIQUE INDEX UX_CashShift_OpenPerRegister ON dbo.CashShift (CashRegister_Id) WHERE Status = 'OPEN';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_CashShift_OpenPerEmployee' AND object_id = OBJECT_ID(N'dbo.CashShift'))
    CREATE UNIQUE INDEX UX_CashShift_OpenPerEmployee ON dbo.CashShift (Employee_Id) WHERE Status = 'OPEN';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Bill_CashShift' AND object_id = OBJECT_ID(N'dbo.Bill'))
    CREATE INDEX IX_Bill_CashShift ON dbo.Bill (CashShift_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Bill_Store_Date' AND object_id = OBJECT_ID(N'dbo.Bill'))
    CREATE INDEX IX_Bill_Store_Date ON dbo.Bill (Store_Id, RegistrationDate) INCLUDE (Status, Total);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Bill_Person' AND object_id = OBJECT_ID(N'dbo.Bill'))
    CREATE INDEX IX_Bill_Person ON dbo.Bill (Person_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Bill_Employee' AND object_id = OBJECT_ID(N'dbo.Bill'))
    CREATE INDEX IX_Bill_Employee ON dbo.Bill (Employee_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BillDetails_Variant' AND object_id = OBJECT_ID(N'dbo.BillDetails'))
    CREATE INDEX IX_BillDetails_Variant ON dbo.BillDetails (ClotheVariant_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BillPayment_Bill' AND object_id = OBJECT_ID(N'dbo.Bill_has_PaymentMethod'))
    CREATE INDEX IX_BillPayment_Bill ON dbo.Bill_has_PaymentMethod (Bill_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PaymentCard_User' AND object_id = OBJECT_ID(N'dbo.PaymentCard'))
    CREATE INDEX IX_PaymentCard_User ON dbo.PaymentCard (User_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DiscountTarget_Discount' AND object_id = OBJECT_ID(N'dbo.DiscountTarget'))
    CREATE INDEX IX_DiscountTarget_Discount ON dbo.DiscountTarget (Discount_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Expense_Store_Date' AND object_id = OBJECT_ID(N'dbo.Expense'))
    CREATE INDEX IX_Expense_Store_Date ON dbo.Expense (Store_Id, ExpenseDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserClothes_User' AND object_id = OBJECT_ID(N'dbo.UserClothes'))
    CREATE INDEX IX_UserClothes_User ON dbo.UserClothes (User_Id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Outfit_User' AND object_id = OBJECT_ID(N'dbo.Outfit'))
    CREATE INDEX IX_Outfit_User ON dbo.Outfit (User_Id);
GO

-- =============================
-- 4. Crear los roles
-- =============================

-- Roles de SQL Server (son distintos de la tabla Role, que usa el backend para los usuarios de la aplicación).
-- Jerarquía: cada rol HEREDA los permisos del nivel de abajo (Staff < Supervisor < Área < Nacional < Admin).
-- El alcance por tienda/área (qué filas ve cada quien) lo aplica el backend con Store_Id / WorkArea_Id.
-- Eliminar filas de verdad (DELETE) solo lo puede el Admin; los demás desactivan con Active = 0.

IF DATABASE_PRINCIPAL_ID(N'role_pedestal_customer') IS NULL
    CREATE ROLE role_pedestal_customer;
IF DATABASE_PRINCIPAL_ID(N'role_pedestal_staff') IS NULL
    CREATE ROLE role_pedestal_staff;
IF DATABASE_PRINCIPAL_ID(N'role_pedestal_store_supervisor') IS NULL
    CREATE ROLE role_pedestal_store_supervisor;
IF DATABASE_PRINCIPAL_ID(N'role_pedestal_area_manager') IS NULL
    CREATE ROLE role_pedestal_area_manager;
IF DATABASE_PRINCIPAL_ID(N'role_pedestal_national_manager') IS NULL
    CREATE ROLE role_pedestal_national_manager;
IF DATABASE_PRINCIPAL_ID(N'role_pedestal_admin') IS NULL
    CREATE ROLE role_pedestal_admin;
GO

-- Herencia entre niveles (el rol de arriba es miembro del de abajo)
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members WHERE role_principal_id = DATABASE_PRINCIPAL_ID(N'role_pedestal_staff') AND member_principal_id = DATABASE_PRINCIPAL_ID(N'role_pedestal_store_supervisor'))
    ALTER ROLE role_pedestal_staff ADD MEMBER role_pedestal_store_supervisor;
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members WHERE role_principal_id = DATABASE_PRINCIPAL_ID(N'role_pedestal_store_supervisor') AND member_principal_id = DATABASE_PRINCIPAL_ID(N'role_pedestal_area_manager'))
    ALTER ROLE role_pedestal_store_supervisor ADD MEMBER role_pedestal_area_manager;
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members WHERE role_principal_id = DATABASE_PRINCIPAL_ID(N'role_pedestal_area_manager') AND member_principal_id = DATABASE_PRINCIPAL_ID(N'role_pedestal_national_manager'))
    ALTER ROLE role_pedestal_area_manager ADD MEMBER role_pedestal_national_manager;
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members WHERE role_principal_id = DATABASE_PRINCIPAL_ID(N'role_pedestal_national_manager') AND member_principal_id = DATABASE_PRINCIPAL_ID(N'role_pedestal_admin'))
    ALTER ROLE role_pedestal_national_manager ADD MEMBER role_pedestal_admin;
GO

-- Admin (dueño): acceso total a la base de datos, sin excepción.
DECLARE @grantAdmin NVARCHAR(200) = N'GRANT CONTROL ON DATABASE::' + QUOTENAME(DB_NAME()) + N' TO role_pedestal_admin;';
EXEC sys.sp_executesql @grantAdmin;
GO

-- Permisos de cada rol sobre las TABLAS (los permisos sobre las vistas están al final del paso 6)
CREATE TABLE #Grants (RoleName SYSNAME NOT NULL, PermissionName NVARCHAR(10) NOT NULL, ObjectName SYSNAME NOT NULL);
INSERT INTO #Grants (RoleName, PermissionName, ObjectName) VALUES
    (N'role_pedestal_customer', N'SELECT', N'ClotheType'),
    (N'role_pedestal_customer', N'SELECT', N'Clothe'),
    (N'role_pedestal_customer', N'SELECT', N'Size'),
    (N'role_pedestal_customer', N'SELECT', N'Color'),
    (N'role_pedestal_customer', N'SELECT', N'ClotheVariant'),
    (N'role_pedestal_customer', N'SELECT', N'Taxes'),
    (N'role_pedestal_customer', N'SELECT', N'Discounts'),
    (N'role_pedestal_customer', N'SELECT', N'DiscountTarget'),
    (N'role_pedestal_customer', N'SELECT', N'PaymentMethod'),
    (N'role_pedestal_customer', N'SELECT', N'User'),
    (N'role_pedestal_customer', N'SELECT', N'Person'),
    (N'role_pedestal_customer', N'SELECT', N'Phones'),
    (N'role_pedestal_customer', N'SELECT', N'Directions'),
    (N'role_pedestal_customer', N'SELECT', N'Bill'),
    (N'role_pedestal_customer', N'SELECT', N'BillDetails'),
    (N'role_pedestal_customer', N'SELECT', N'AppliedTaxes'),
    (N'role_pedestal_customer', N'SELECT', N'AppliedDiscounts'),
    (N'role_pedestal_customer', N'SELECT', N'Bill_has_Coupons'),
    (N'role_pedestal_customer', N'SELECT', N'Bill_has_PaymentMethod'),
    (N'role_pedestal_customer', N'SELECT', N'Cart'),
    (N'role_pedestal_customer', N'SELECT', N'CartDetail'),
    (N'role_pedestal_customer', N'SELECT', N'PaymentCard'),
    (N'role_pedestal_customer', N'SELECT', N'UserClothes'),
    (N'role_pedestal_customer', N'SELECT', N'Outfit'),
    (N'role_pedestal_customer', N'SELECT', N'Outfit_has_UserClothes'),
    (N'role_pedestal_customer', N'INSERT', N'Person'),
    (N'role_pedestal_customer', N'INSERT', N'Account'),
    (N'role_pedestal_customer', N'INSERT', N'User'),
    (N'role_pedestal_customer', N'INSERT', N'Phones'),
    (N'role_pedestal_customer', N'INSERT', N'Directions'),
    (N'role_pedestal_customer', N'INSERT', N'Cart'),
    (N'role_pedestal_customer', N'INSERT', N'CartDetail'),
    (N'role_pedestal_customer', N'INSERT', N'PaymentCard'),
    (N'role_pedestal_customer', N'INSERT', N'Bill'),
    (N'role_pedestal_customer', N'INSERT', N'BillDetails'),
    (N'role_pedestal_customer', N'INSERT', N'AppliedTaxes'),
    (N'role_pedestal_customer', N'INSERT', N'AppliedDiscounts'),
    (N'role_pedestal_customer', N'INSERT', N'Bill_has_Coupons'),
    (N'role_pedestal_customer', N'INSERT', N'Bill_has_PaymentMethod'),
    (N'role_pedestal_customer', N'INSERT', N'UserClothes'),
    (N'role_pedestal_customer', N'INSERT', N'Outfit'),
    (N'role_pedestal_customer', N'INSERT', N'Outfit_has_UserClothes'),
    (N'role_pedestal_customer', N'UPDATE', N'Person'),
    (N'role_pedestal_customer', N'UPDATE', N'Phones'),
    (N'role_pedestal_customer', N'UPDATE', N'Directions'),
    (N'role_pedestal_customer', N'UPDATE', N'Cart'),
    (N'role_pedestal_customer', N'UPDATE', N'CartDetail'),
    (N'role_pedestal_customer', N'UPDATE', N'PaymentCard'),
    (N'role_pedestal_customer', N'UPDATE', N'UserClothes'),
    (N'role_pedestal_customer', N'UPDATE', N'Outfit'),
    (N'role_pedestal_customer', N'DELETE', N'CartDetail'),
    (N'role_pedestal_customer', N'DELETE', N'Outfit_has_UserClothes'),
    (N'role_pedestal_staff', N'SELECT', N'ClotheType'),
    (N'role_pedestal_staff', N'SELECT', N'Clothe'),
    (N'role_pedestal_staff', N'SELECT', N'Size'),
    (N'role_pedestal_staff', N'SELECT', N'Color'),
    (N'role_pedestal_staff', N'SELECT', N'ClotheVariant'),
    (N'role_pedestal_staff', N'SELECT', N'Store'),
    (N'role_pedestal_staff', N'SELECT', N'Rack'),
    (N'role_pedestal_staff', N'SELECT', N'Cubicle'),
    (N'role_pedestal_staff', N'SELECT', N'ClothesInCubicle'),
    (N'role_pedestal_staff', N'SELECT', N'Taxes'),
    (N'role_pedestal_staff', N'SELECT', N'Discounts'),
    (N'role_pedestal_staff', N'SELECT', N'DiscountTarget'),
    (N'role_pedestal_staff', N'SELECT', N'Coupons'),
    (N'role_pedestal_staff', N'SELECT', N'PaymentMethod'),
    (N'role_pedestal_staff', N'SELECT', N'Person'),
    (N'role_pedestal_staff', N'SELECT', N'Phones'),
    (N'role_pedestal_staff', N'SELECT', N'Directions'),
    (N'role_pedestal_staff', N'SELECT', N'Bill'),
    (N'role_pedestal_staff', N'SELECT', N'BillDetails'),
    (N'role_pedestal_staff', N'SELECT', N'AppliedTaxes'),
    (N'role_pedestal_staff', N'SELECT', N'AppliedDiscounts'),
    (N'role_pedestal_staff', N'SELECT', N'Bill_has_Coupons'),
    (N'role_pedestal_staff', N'SELECT', N'Bill_has_PaymentMethod'),
    (N'role_pedestal_staff', N'INSERT', N'Person'),
    (N'role_pedestal_staff', N'INSERT', N'Phones'),
    (N'role_pedestal_staff', N'INSERT', N'Directions'),
    (N'role_pedestal_staff', N'INSERT', N'Bill'),
    (N'role_pedestal_staff', N'INSERT', N'BillDetails'),
    (N'role_pedestal_staff', N'INSERT', N'AppliedTaxes'),
    (N'role_pedestal_staff', N'INSERT', N'AppliedDiscounts'),
    (N'role_pedestal_staff', N'INSERT', N'Bill_has_Coupons'),
    (N'role_pedestal_staff', N'INSERT', N'Bill_has_PaymentMethod'),
    (N'role_pedestal_staff', N'INSERT', N'StockMovement'),
    (N'role_pedestal_staff', N'UPDATE', N'Person'),
    (N'role_pedestal_staff', N'UPDATE', N'Phones'),
    (N'role_pedestal_staff', N'UPDATE', N'Directions'),
    (N'role_pedestal_staff', N'UPDATE', N'ClothesInCubicle'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'StockMovement'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'Batch'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'PurchaseOrder'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'PurchaseOrderDetail'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'Supplier'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'LegalEntity'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'Expense'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'ExpenseCategory'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'Payroll'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'Employee'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'PositionHistorial'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'Position'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'WorkArea'),
    (N'role_pedestal_store_supervisor', N'INSERT', N'Rack'),
    (N'role_pedestal_store_supervisor', N'INSERT', N'Cubicle'),
    (N'role_pedestal_store_supervisor', N'INSERT', N'ClothesInCubicle'),
    (N'role_pedestal_store_supervisor', N'INSERT', N'Batch'),
    (N'role_pedestal_store_supervisor', N'INSERT', N'PurchaseOrder'),
    (N'role_pedestal_store_supervisor', N'INSERT', N'PurchaseOrderDetail'),
    (N'role_pedestal_store_supervisor', N'INSERT', N'Expense'),
    (N'role_pedestal_store_supervisor', N'UPDATE', N'Rack'),
    (N'role_pedestal_store_supervisor', N'UPDATE', N'Cubicle'),
    (N'role_pedestal_store_supervisor', N'UPDATE', N'Batch'),
    (N'role_pedestal_store_supervisor', N'UPDATE', N'PurchaseOrder'),
    (N'role_pedestal_store_supervisor', N'UPDATE', N'PurchaseOrderDetail'),
    (N'role_pedestal_store_supervisor', N'UPDATE', N'Expense'),
    (N'role_pedestal_store_supervisor', N'UPDATE', N'Bill'),
    (N'role_pedestal_store_supervisor', N'UPDATE', N'StockMovement'),
    (N'role_pedestal_area_manager', N'INSERT', N'Employee'),
    (N'role_pedestal_area_manager', N'INSERT', N'PositionHistorial'),
    (N'role_pedestal_area_manager', N'INSERT', N'Payroll'),
    (N'role_pedestal_area_manager', N'INSERT', N'Supplier'),
    (N'role_pedestal_area_manager', N'INSERT', N'LegalEntity'),
    (N'role_pedestal_area_manager', N'INSERT', N'ExpenseCategory'),
    (N'role_pedestal_area_manager', N'INSERT', N'Discounts'),
    (N'role_pedestal_area_manager', N'INSERT', N'DiscountTarget'),
    (N'role_pedestal_area_manager', N'INSERT', N'Coupons'),
    (N'role_pedestal_area_manager', N'UPDATE', N'Store'),
    (N'role_pedestal_area_manager', N'UPDATE', N'Employee'),
    (N'role_pedestal_area_manager', N'UPDATE', N'PositionHistorial'),
    (N'role_pedestal_area_manager', N'UPDATE', N'Payroll'),
    (N'role_pedestal_area_manager', N'UPDATE', N'Supplier'),
    (N'role_pedestal_area_manager', N'UPDATE', N'LegalEntity'),
    (N'role_pedestal_area_manager', N'UPDATE', N'ExpenseCategory'),
    (N'role_pedestal_area_manager', N'UPDATE', N'Discounts'),
    (N'role_pedestal_area_manager', N'UPDATE', N'DiscountTarget'),
    (N'role_pedestal_area_manager', N'UPDATE', N'Coupons'),
    (N'role_pedestal_national_manager', N'SELECT', N'Role'),
    (N'role_pedestal_national_manager', N'SELECT', N'Permission'),
    (N'role_pedestal_national_manager', N'SELECT', N'RolePermission'),
    (N'role_pedestal_national_manager', N'SELECT', N'AuditLog'),
    (N'role_pedestal_national_manager', N'INSERT', N'Store'),
    (N'role_pedestal_national_manager', N'INSERT', N'WorkArea'),
    (N'role_pedestal_national_manager', N'INSERT', N'Position'),
    (N'role_pedestal_national_manager', N'INSERT', N'Taxes'),
    (N'role_pedestal_national_manager', N'INSERT', N'PaymentMethod'),
    (N'role_pedestal_national_manager', N'INSERT', N'ClotheType'),
    (N'role_pedestal_national_manager', N'INSERT', N'Clothe'),
    (N'role_pedestal_national_manager', N'INSERT', N'Size'),
    (N'role_pedestal_national_manager', N'INSERT', N'Color'),
    (N'role_pedestal_national_manager', N'INSERT', N'ClotheVariant'),
    (N'role_pedestal_national_manager', N'UPDATE', N'WorkArea'),
    (N'role_pedestal_national_manager', N'UPDATE', N'Position'),
    (N'role_pedestal_national_manager', N'UPDATE', N'Taxes'),
    (N'role_pedestal_national_manager', N'UPDATE', N'PaymentMethod'),
    (N'role_pedestal_national_manager', N'UPDATE', N'ClotheType'),
    (N'role_pedestal_national_manager', N'UPDATE', N'Clothe'),
    (N'role_pedestal_national_manager', N'UPDATE', N'Size'),
    (N'role_pedestal_national_manager', N'UPDATE', N'Color'),
    (N'role_pedestal_national_manager', N'UPDATE', N'ClotheVariant'),
    (N'role_pedestal_staff', N'SELECT', N'CashRegister'),
    (N'role_pedestal_staff', N'SELECT', N'CashShift'),
    (N'role_pedestal_staff', N'INSERT', N'CashShift'),
    (N'role_pedestal_staff', N'UPDATE', N'CashShift'),
    (N'role_pedestal_staff', N'SELECT', N'Shipment'),
    (N'role_pedestal_customer', N'SELECT', N'Shipment'),
    (N'role_pedestal_store_supervisor', N'INSERT', N'CashRegister'),
    (N'role_pedestal_store_supervisor', N'UPDATE', N'CashRegister'),
    (N'role_pedestal_store_supervisor', N'INSERT', N'Shipment'),
    (N'role_pedestal_store_supervisor', N'UPDATE', N'Shipment'),
    (N'role_pedestal_national_manager', N'SELECT', N'AccountRole'),
    (N'role_pedestal_national_manager', N'INSERT', N'AccountRole'),
    (N'role_pedestal_national_manager', N'UPDATE', N'AccountRole');

DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'GRANT ' + PermissionName + N' ON dbo.' + QUOTENAME(ObjectName) + N' TO ' + QUOTENAME(RoleName) + N';' + NCHAR(10)
FROM #Grants;
EXEC sys.sp_executesql @sql;
DROP TABLE #Grants;
GO

-- =============================
-- 5. Insertar los datos si no existen
-- =============================

-- Datos de PRUEBA: catálogos con 15 registros o más y tablas de transacciones con 30 registros o más.
-- Cada bloque se ejecuta solo si su tabla está vacía. Las contraseñas (PasswordHash) y los ids de SharePoint
-- (ImageFileId) son valores de muestra: no son hashes reales ni archivos reales.
-- Role se mantiene en 6 filas porque son roles genéricos por nivel del organigrama.

-- Gestión de entidades
IF NOT EXISTS (SELECT 1 FROM dbo.Person)
BEGIN
    SET IDENTITY_INSERT dbo.Person ON;
    INSERT INTO dbo.Person (Id, DocumentId, FirstName, MiddleName, FirstSurname, SecondSurname, Email) VALUES
        (1, N'0002-1972-10001', N'Juan', NULL, N'Reyes', N'Núñez', N'juan.reyes1@pedestal.hn'),
        (2, N'0003-1979-10002', N'Jorge', NULL, N'Castillo', N'Bonilla', N'jorge.castillo2@pedestal.hn'),
        (3, N'0004-1986-10003', N'Wilmer', N'Nelson', N'Palma', N'Mejía', N'wilmer.palma3@pedestal.hn'),
        (4, N'0005-1993-10004', N'Fredy', NULL, N'Padilla', N'Cáceres', N'fredy.padilla4@pedestal.hn'),
        (5, N'0006-2000-10005', N'Rolando', NULL, N'Pérez', N'Hernández', N'rolando.perez5@pedestal.hn'),
        (6, N'0007-1967-10006', N'Samuel', N'Marcela', N'Zelaya', N'Aguilar', N'samuel.zelaya6@pedestal.hn'),
        (7, N'0008-1974-10007', N'Ana', NULL, N'Cáceres', N'Euceda', N'ana.caceres7@pedestal.hn'),
        (8, N'0009-1981-10008', N'Gloria', NULL, N'Lagos', N'Rodríguez', N'gloria.lagos8@pedestal.hn'),
        (9, N'0010-1988-10009', N'Fátima', N'Jorge', N'Rodríguez', N'Castillo', N'fatima.rodriguez9@pedestal.hn'),
        (10, N'0011-1995-10010', N'Rosa', NULL, N'Ramírez', N'Funes', N'rosa.ramirez10@pedestal.hn'),
        (11, N'0012-2002-10011', N'Claudia', NULL, N'Ordóñez', N'Flores', N'claudia.ordonez11@pedestal.hn'),
        (12, N'0013-1969-10012', N'Norma', N'Ana', N'Varela', N'Ordóñez', N'norma.varela12@pedestal.hn'),
        (13, N'0014-1976-10013', N'Keila', NULL, N'López', N'Padilla', N'keila.lopez13@pedestal.hn'),
        (14, N'0015-1983-10014', N'Luis', NULL, N'Mejía', N'Cruz', N'luis.mejia14@pedestal.hn'),
        (15, N'0016-1990-10015', N'Oscar', N'Norma', N'Rivera', N'Medina', N'oscar.rivera15@pedestal.hn'),
        (16, N'0017-1997-10016', N'Kevin', NULL, N'Euceda', N'López', N'kevin.euceda16@pedestal.hn'),
        (17, N'0018-2004-10017', N'Walter', NULL, N'Soto', N'Zelaya', N'walter.soto17@pedestal.hn'),
        (18, N'0001-1971-10018', N'Héctor', N'Walter', N'Flores', N'Midence', N'hector.flores18@pedestal.hn'),
        (19, N'0002-1978-10019', N'Edgardo', NULL, N'Mendoza', N'García', N'edgardo.mendoza19@pedestal.hn'),
        (20, N'0003-1985-10020', N'María', NULL, N'Medina', N'Rivera', N'maria.medina20@pedestal.hn'),
        (21, N'0004-1992-10021', N'Sandra', N'Daniela', N'Bonilla', N'Lagos', N'sandra.bonilla21@pedestal.hn'),
        (22, N'0005-1999-10022', N'Daniela', NULL, N'García', N'Reyes', N'daniela.garcia22@pedestal.hn'),
        (23, N'0006-1966-10023', N'Wendy', NULL, N'Aguilar', N'Banegas', N'wendy.aguilar23@pedestal.hn'),
        (24, N'0007-1973-10024', N'Patricia', N'Carlos', N'Banegas', N'Soto', N'patricia.banegas24@pedestal.hn'),
        (25, N'0008-1980-10025', N'Gabriela', NULL, N'Funes', N'Ramírez', N'gabriela.funes25@pedestal.hn'),
        (26, N'0009-1987-10026', N'Dilcia', NULL, N'Martínez', N'Palma', N'dilcia.martinez26@pedestal.hn'),
        (27, N'0010-1994-10027', N'Carlos', N'Nelson', N'Cruz', N'Martínez', N'carlos.cruz27@pedestal.hn'),
        (28, N'0011-2001-10028', N'Mario', NULL, N'Núñez', N'Mendoza', N'mario.nunez28@pedestal.hn'),
        (29, N'0012-1968-10029', N'Marvin', NULL, N'Midence', N'Varela', N'marvin.midence29@pedestal.hn'),
        (30, N'0013-1975-10030', N'Elvin', N'Marcela', N'Hernández', N'Pérez', N'elvin.hernandez30@pedestal.hn'),
        (31, N'0014-1982-10031', N'Denis', NULL, N'Reyes', N'Núñez', N'denis.reyes31@pedestal.hn'),
        (32, N'0015-1989-10032', N'Nelson', NULL, N'Castillo', N'Bonilla', N'nelson.castillo32@pedestal.hn'),
        (33, N'0016-1996-10033', N'Daniel', N'Jorge', N'Palma', N'Mejía', N'daniel.palma33@pedestal.hn'),
        (34, N'0017-2003-10034', N'Karla', NULL, N'Padilla', N'Cáceres', N'karla.padilla34@pedestal.hn'),
        (35, N'0018-1970-10035', N'Lourdes', NULL, N'Pérez', N'Hernández', N'lourdes.perez35@pedestal.hn'),
        (36, N'0001-1977-10036', N'Jessica', N'Ana', N'Zelaya', N'Aguilar', N'jessica.zelaya36@pedestal.hn'),
        (37, N'0002-1984-10037', N'Marcela', NULL, N'Cáceres', N'Euceda', N'marcela.caceres37@pedestal.hn'),
        (38, N'0003-1991-10038', N'Yesenia', NULL, N'Lagos', N'Rodríguez', N'yesenia.lagos38@pedestal.hn'),
        (39, N'0004-1998-10039', N'Elsa', N'Norma', N'Rodríguez', N'Castillo', N'elsa.rodriguez39@pedestal.hn'),
        (40, N'0005-1965-10040', N'José', NULL, N'Ramírez', N'Funes', N'jose.ramirez40@pedestal.hn'),
        (41, N'0006-1972-10041', N'Juan', NULL, N'Ordóñez', N'Flores', N'juan.ordonez41@pedestal.hn'),
        (42, N'0007-1979-10042', N'Jorge', N'Walter', N'Varela', N'Ordóñez', N'jorge.varela42@pedestal.hn'),
        (43, N'0008-1986-10043', N'Wilmer', NULL, N'López', N'Padilla', N'wilmer.lopez43@pedestal.hn'),
        (44, N'0009-1993-10044', N'Fredy', NULL, N'Mejía', N'Cruz', N'fredy.mejia44@pedestal.hn'),
        (45, N'0010-2000-10045', N'Rolando', N'Daniela', N'Rivera', N'Medina', N'rolando.rivera45@pedestal.hn'),
        (46, N'0011-1967-10046', N'Samuel', NULL, N'Euceda', N'López', N'samuel.euceda46@pedestal.hn'),
        (47, N'0012-1974-10047', N'Ana', NULL, N'Soto', N'Zelaya', N'ana.soto47@pedestal.hn'),
        (48, N'0013-1981-10048', N'Gloria', N'Carlos', N'Flores', N'Midence', N'gloria.flores48@pedestal.hn'),
        (49, N'0014-1988-10049', N'Fátima', NULL, N'Mendoza', N'García', N'fatima.mendoza49@pedestal.hn'),
        (50, N'0015-1995-10050', N'Rosa', NULL, N'Medina', N'Rivera', N'rosa.medina50@pedestal.hn'),
        (51, N'0016-2002-10051', N'Claudia', N'Nelson', N'Bonilla', N'Lagos', N'claudia.bonilla51@pedestal.hn'),
        (52, N'0017-1969-10052', N'Norma', NULL, N'García', N'Reyes', N'norma.garcia52@pedestal.hn'),
        (53, N'0018-1976-10053', N'Keila', NULL, N'Aguilar', N'Banegas', N'keila.aguilar53@pedestal.hn'),
        (54, N'0001-1983-10054', N'Luis', N'Marcela', N'Banegas', N'Soto', N'luis.banegas54@pedestal.hn'),
        (55, N'0002-1990-10055', N'Oscar', NULL, N'Funes', N'Ramírez', N'oscar.funes55@pedestal.hn'),
        (56, N'0003-1997-10056', N'Kevin', NULL, N'Martínez', N'Palma', N'kevin.martinez56@pedestal.hn'),
        (57, N'0004-2004-10057', N'Walter', N'Jorge', N'Cruz', N'Martínez', N'walter.cruz57@pedestal.hn'),
        (58, N'0005-1971-10058', N'Héctor', NULL, N'Núñez', N'Mendoza', N'hector.nunez58@pedestal.hn'),
        (59, N'0006-1978-10059', N'Edgardo', NULL, N'Midence', N'Varela', N'edgardo.midence59@pedestal.hn'),
        (60, N'0007-1985-10060', N'María', N'Ana', N'Hernández', N'Pérez', N'maria.hernandez60@pedestal.hn'),
        (61, N'0008-1992-10061', N'Sandra', NULL, N'Reyes', N'Núñez', N'sandra.reyes61@pedestal.hn'),
        (62, N'0009-1999-10062', N'Daniela', NULL, N'Castillo', N'Bonilla', N'daniela.castillo62@pedestal.hn'),
        (63, N'0010-1966-10063', N'Wendy', N'Norma', N'Palma', N'Mejía', N'wendy.palma63@pedestal.hn'),
        (64, N'0011-1973-10064', N'Patricia', NULL, N'Padilla', N'Cáceres', N'patricia.padilla64@pedestal.hn'),
        (65, N'0012-1980-10065', N'Gabriela', NULL, N'Pérez', N'Hernández', N'gabriela.perez65@pedestal.hn'),
        (66, N'0013-1987-10066', N'Dilcia', N'Walter', N'Zelaya', N'Aguilar', N'dilcia.zelaya66@pedestal.hn'),
        (67, N'0014-1994-10067', N'Carlos', NULL, N'Cáceres', N'Euceda', N'carlos.caceres67@pedestal.hn'),
        (68, N'0015-2001-10068', N'Mario', NULL, N'Lagos', N'Rodríguez', N'mario.lagos68@pedestal.hn'),
        (69, N'0016-1968-10069', N'Marvin', N'Daniela', N'Rodríguez', N'Castillo', N'marvin.rodriguez69@pedestal.hn'),
        (70, N'0017-1975-10070', N'Elvin', NULL, N'Ramírez', N'Funes', N'elvin.ramirez70@pedestal.hn'),
        (71, N'0018-1982-10071', N'Denis', NULL, N'Ordóñez', N'Flores', N'denis.ordonez71@pedestal.hn'),
        (72, N'0001-1989-10072', N'Nelson', N'Carlos', N'Varela', N'Ordóñez', N'nelson.varela72@pedestal.hn'),
        (73, N'0002-1996-10073', N'Daniel', NULL, N'López', N'Padilla', N'daniel.lopez73@pedestal.hn'),
        (74, N'0003-2003-10074', N'Karla', NULL, N'Mejía', N'Cruz', N'karla.mejia74@pedestal.hn'),
        (75, N'0004-1970-10075', N'Lourdes', N'Nelson', N'Rivera', N'Medina', N'lourdes.rivera75@yahoo.com'),
        (76, N'0005-1977-10076', N'Jessica', NULL, N'Euceda', N'López', N'jessica.euceda76@yahoo.com'),
        (77, N'0006-1984-10077', N'Marcela', NULL, N'Soto', N'Zelaya', N'marcela.soto77@gmail.com'),
        (78, N'0007-1991-10078', N'Yesenia', N'Marcela', N'Flores', N'Midence', N'yesenia.flores78@yahoo.com'),
        (79, N'0008-1998-10079', N'Elsa', NULL, N'Mendoza', N'García', N'elsa.mendoza79@outlook.com'),
        (80, N'0009-1965-10080', N'José', NULL, N'Medina', N'Rivera', N'jose.medina80@yahoo.com'),
        (81, N'0010-1972-10081', N'Juan', N'Jorge', N'Bonilla', N'Lagos', N'juan.bonilla81@yahoo.com'),
        (82, N'0011-1979-10082', N'Jorge', NULL, N'García', N'Reyes', N'jorge.garcia82@gmail.com'),
        (83, N'0012-1986-10083', N'Wilmer', NULL, N'Aguilar', N'Banegas', N'wilmer.aguilar83@gmail.com'),
        (84, N'0013-1993-10084', N'Fredy', N'Ana', N'Banegas', N'Soto', N'fredy.banegas84@yahoo.com'),
        (85, N'0014-2000-10085', N'Rolando', NULL, N'Funes', N'Ramírez', N'rolando.funes85@outlook.com'),
        (86, N'0015-1967-10086', N'Samuel', NULL, N'Martínez', N'Palma', N'samuel.martinez86@gmail.com'),
        (87, N'0016-1974-10087', N'Ana', N'Norma', N'Cruz', N'Martínez', N'ana.cruz87@gmail.com'),
        (88, N'0017-1981-10088', N'Gloria', NULL, N'Núñez', N'Mendoza', N'gloria.nunez88@outlook.com'),
        (89, N'0018-1988-10089', N'Fátima', NULL, N'Midence', N'Varela', N'fatima.midence89@outlook.com'),
        (90, N'0001-1995-10090', N'Rosa', N'Walter', N'Hernández', N'Pérez', N'rosa.hernandez90@yahoo.com'),
        (91, N'0002-2002-10091', N'Claudia', NULL, N'Reyes', N'Núñez', N'claudia.reyes91@outlook.com'),
        (92, N'0003-1969-10092', N'Norma', NULL, N'Castillo', N'Bonilla', N'norma.castillo92@gmail.com'),
        (93, N'0004-1976-10093', N'Keila', N'Daniela', N'Palma', N'Mejía', N'keila.palma93@yahoo.com'),
        (94, N'0005-1983-10094', N'Luis', NULL, N'Padilla', N'Cáceres', N'luis.padilla94@outlook.com'),
        (95, N'0006-1990-10095', N'Oscar', NULL, N'Pérez', N'Hernández', N'oscar.perez95@outlook.com'),
        (96, N'0007-1997-10096', N'Kevin', N'Carlos', N'Zelaya', N'Aguilar', N'kevin.zelaya96@outlook.com'),
        (97, N'0008-2004-10097', N'Walter', NULL, N'Cáceres', N'Euceda', N'walter.caceres97@yahoo.com'),
        (98, N'0009-1971-10098', N'Héctor', NULL, N'Lagos', N'Rodríguez', N'hector.lagos98@outlook.com'),
        (99, N'0010-1978-10099', N'Edgardo', N'Nelson', N'Rodríguez', N'Castillo', N'edgardo.rodriguez99@yahoo.com'),
        (100, N'0011-1985-10100', N'María', NULL, N'Ramírez', N'Funes', N'maria.ramirez100@yahoo.com'),
        (101, N'0012-1992-10101', N'Sandra', NULL, N'Ordóñez', N'Flores', N'sandra.ordonez101@yahoo.com'),
        (102, N'0013-1999-10102', N'Daniela', N'Marcela', N'Varela', N'Ordóñez', N'daniela.varela102@outlook.com'),
        (103, N'0014-1966-10103', N'Wendy', NULL, N'López', N'Padilla', N'wendy.lopez103@outlook.com'),
        (104, N'0015-1973-10104', N'Patricia', NULL, N'Mejía', N'Cruz', N'patricia.mejia104@outlook.com'),
        (105, N'0016-1980-10105', N'Gabriela', N'Jorge', N'Rivera', N'Medina', N'gabriela.rivera105@gmail.com'),
        (106, N'0017-1987-10106', N'Dilcia', NULL, N'Euceda', N'López', N'dilcia.euceda106@outlook.com'),
        (107, N'0018-1994-10107', N'Carlos', NULL, N'Soto', N'Zelaya', N'carlos.soto107@yahoo.com'),
        (108, N'0001-2001-10108', N'Mario', N'Ana', N'Flores', N'Midence', N'mario.flores108@outlook.com'),
        (109, N'0002-1968-10109', N'Marvin', NULL, N'Mendoza', N'García', N'marvin.mendoza109@yahoo.com'),
        (110, N'0003-1975-10110', N'Elvin', NULL, N'Medina', N'Rivera', N'elvin.medina110@yahoo.com'),
        (111, N'0004-1982-10111', N'Denis', N'Norma', N'Bonilla', N'Lagos', N'denis.bonilla111@outlook.com'),
        (112, N'0005-1989-10112', N'Nelson', NULL, N'García', N'Reyes', N'nelson.garcia112@yahoo.com'),
        (113, N'0006-1996-10113', N'Daniel', NULL, N'Aguilar', N'Banegas', N'daniel.aguilar113@gmail.com'),
        (114, N'0007-2003-10114', N'Karla', N'Walter', N'Banegas', N'Soto', N'karla.banegas114@yahoo.com'),
        (115, N'0008-1970-10115', N'Lourdes', NULL, N'Funes', N'Ramírez', N'lourdes.funes115@yahoo.com'),
        (116, N'0009-1977-10116', N'Jessica', NULL, N'Martínez', N'Palma', N'jessica.martinez116@outlook.com'),
        (117, N'0010-1984-10117', N'Marcela', N'Daniela', N'Cruz', N'Martínez', N'marcela.cruz117@yahoo.com');
    SET IDENTITY_INSERT dbo.Person OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.LegalEntity)
BEGIN
    SET IDENTITY_INSERT dbo.LegalEntity ON;
    INSERT INTO dbo.LegalEntity (Id, BusinessName, TradeName, TaxId, Email) VALUES
        (1, N'Textiles La Esperanza, S. de R.L.', N'Textiles La Esperanza', N'66820728642189', N'ventas@textileslaesperanz.hn'),
        (2, N'Confecciones del Valle, S. de R.L.', N'Confecciones del Valle', N'24276729873616', N'ventas@confeccionesdelval.hn'),
        (3, N'Distribuidora Moda Catracha, S. de R.L.', N'Distribuidora Moda Catracha', N'74438873442960', N'ventas@distribuidoramodac.hn'),
        (4, N'Importadora Fashion Plus, S. de R.L.', N'Importadora Fashion Plus', N'35680413362014', N'ventas@importadorafashion.hn'),
        (5, N'Calzado Bonanza, S. de R.L.', N'Calzado Bonanza', N'51848243222158', N'ventas@calzadobonanza.hn'),
        (6, N'Accesorios Estrella, S. de R.L.', N'Accesorios Estrella', N'65417600140604', N'ventas@accesoriosestrella.hn'),
        (7, N'Tejidos Maya, S. de R.L.', N'Tejidos Maya', N'35942739422151', N'ventas@tejidosmaya.hn'),
        (8, N'Industrias Textiles Sula, S. de R.L.', N'Industrias Textiles Sula', N'89798508402338', N'ventas@industriastextiles.hn'),
        (9, N'Moda Express Honduras, S. de R.L.', N'Moda Express Honduras', N'73407538587593', N'ventas@modaexpresshondura.hn'),
        (10, N'Distribuciones Montecristo, S. de R.L.', N'Distribuciones Montecristo', N'90539582485501', N'ventas@distribucionesmont.hn'),
        (11, N'Cuero y Estilo, S. de R.L.', N'Cuero y Estilo', N'57789472956386', N'ventas@cueroyestilo.hn'),
        (12, N'Ropa Deportiva Olimpo, S. de R.L.', N'Ropa Deportiva Olimpo', N'67175988723110', N'ventas@ropadeportivaolimp.hn'),
        (13, N'Lencería Delicia, S. de R.L.', N'Lencería Delicia', N'94033003925385', N'ventas@lenceriadelicia.hn'),
        (14, N'Telas y Diseños Copán, S. de R.L.', N'Telas y Diseños Copán', N'68275698193052', N'ventas@telasydisenoscopan.hn'),
        (15, N'Sombreros y Gorras Lenca, S. de R.L.', N'Sombreros y Gorras Lenca', N'12237322793682', N'ventas@sombrerosygorrasle.hn');
    SET IDENTITY_INSERT dbo.LegalEntity OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Phones)
BEGIN
    SET IDENTITY_INSERT dbo.Phones ON;
    INSERT INTO dbo.Phones (Id, Phone, Person_Id, LegalEntity_Id) VALUES
        (1, N'+504 9317-8104', 1, NULL),
        (2, N'+504 2242-5567', 2, NULL),
        (3, N'+504 9197-5608', 3, NULL),
        (4, N'+504 3489-4000', 4, NULL),
        (5, N'+504 9390-4424', 5, NULL),
        (6, N'+504 9818-4896', 6, NULL),
        (7, N'+504 2864-7594', 7, NULL),
        (8, N'+504 2287-3250', 8, NULL),
        (9, N'+504 9957-6254', 9, NULL),
        (10, N'+504 3219-8026', 10, NULL),
        (11, N'+504 8179-4653', 11, NULL),
        (12, N'+504 8188-2940', 12, NULL),
        (13, N'+504 9349-4529', 13, NULL),
        (14, N'+504 9322-6704', 14, NULL),
        (15, N'+504 2756-7676', 15, NULL),
        (16, N'+504 3335-8910', 16, NULL),
        (17, N'+504 8774-2129', 17, NULL),
        (18, N'+504 9764-7994', 18, NULL),
        (19, N'+504 8117-8701', 19, NULL),
        (20, N'+504 2437-4985', 20, NULL),
        (21, N'+504 9118-4415', 21, NULL),
        (22, N'+504 9342-7655', 22, NULL),
        (23, N'+504 3493-9561', 23, NULL),
        (24, N'+504 2715-1464', 24, NULL),
        (25, N'+504 3813-5888', 25, NULL),
        (26, N'+504 3153-7794', 26, NULL),
        (27, N'+504 3161-4275', 27, NULL),
        (28, N'+504 8107-6297', 28, NULL),
        (29, N'+504 8582-8920', 29, NULL),
        (30, N'+504 2105-4198', 30, NULL),
        (31, N'+504 9686-6736', 31, NULL),
        (32, N'+504 3872-8577', 32, NULL),
        (33, N'+504 9497-9946', 33, NULL),
        (34, N'+504 3902-7038', 34, NULL),
        (35, N'+504 9399-8856', 35, NULL),
        (36, N'+504 2146-8817', 36, NULL),
        (37, N'+504 2585-4799', 37, NULL),
        (38, N'+504 9722-1052', 38, NULL),
        (39, N'+504 9446-4372', 39, NULL),
        (40, N'+504 3142-4477', 40, NULL),
        (41, N'+504 3388-6239', 41, NULL),
        (42, N'+504 8914-8385', 42, NULL),
        (43, N'+504 8408-6154', 43, NULL),
        (44, N'+504 9428-9286', 44, NULL),
        (45, N'+504 8825-8936', 45, NULL),
        (46, N'+504 3482-2922', 46, NULL),
        (47, N'+504 3446-7987', 47, NULL),
        (48, N'+504 2806-4827', 48, NULL),
        (49, N'+504 3675-2513', 49, NULL),
        (50, N'+504 2624-7883', 50, NULL),
        (51, N'+504 2657-4697', 51, NULL),
        (52, N'+504 9875-9330', 52, NULL),
        (53, N'+504 8123-2908', 53, NULL),
        (54, N'+504 9763-1683', 54, NULL),
        (55, N'+504 3216-3024', 55, NULL),
        (56, N'+504 3354-6731', 56, NULL),
        (57, N'+504 3297-4333', 57, NULL),
        (58, N'+504 8704-8811', 58, NULL),
        (59, N'+504 8559-9853', 59, NULL),
        (60, N'+504 2397-3883', 60, NULL),
        (61, N'+504 2121-7644', 61, NULL),
        (62, N'+504 3893-6649', 62, NULL),
        (63, N'+504 9125-9273', 63, NULL),
        (64, N'+504 2111-7899', 64, NULL),
        (65, N'+504 2237-9958', 65, NULL),
        (66, N'+504 9836-5982', 66, NULL),
        (67, N'+504 9380-1296', 67, NULL),
        (68, N'+504 9147-3905', 68, NULL),
        (69, N'+504 2226-8450', 69, NULL),
        (70, N'+504 9420-5533', 70, NULL),
        (71, N'+504 2710-4429', 71, NULL),
        (72, N'+504 9571-4952', 72, NULL),
        (73, N'+504 3667-6478', 73, NULL),
        (74, N'+504 3375-6707', 74, NULL),
        (75, N'+504 8395-3319', 75, NULL),
        (76, N'+504 2239-4519', 76, NULL),
        (77, N'+504 2858-4838', 77, NULL),
        (78, N'+504 9575-5213', 78, NULL),
        (79, N'+504 8550-9894', 79, NULL),
        (80, N'+504 8103-4162', 80, NULL),
        (81, N'+504 8514-3860', 81, NULL),
        (82, N'+504 3384-3299', 82, NULL),
        (83, N'+504 3606-5841', 83, NULL),
        (84, N'+504 9868-8010', 84, NULL),
        (85, N'+504 9333-2101', 85, NULL),
        (86, N'+504 3236-8253', 86, NULL),
        (87, N'+504 2579-6809', 87, NULL),
        (88, N'+504 9167-3663', 88, NULL),
        (89, N'+504 8304-6721', 89, NULL),
        (90, N'+504 2963-7456', 90, NULL),
        (91, N'+504 9473-2025', 91, NULL),
        (92, N'+504 9414-9859', 92, NULL),
        (93, N'+504 8325-5160', 93, NULL),
        (94, N'+504 2196-1209', 94, NULL),
        (95, N'+504 3575-1430', 95, NULL),
        (96, N'+504 3595-2665', 96, NULL),
        (97, N'+504 8927-2508', 97, NULL),
        (98, N'+504 3809-8666', 98, NULL),
        (99, N'+504 8639-3518', 99, NULL),
        (100, N'+504 9601-1449', 100, NULL),
        (101, N'+504 2871-8800', 101, NULL),
        (102, N'+504 9929-1608', 102, NULL),
        (103, N'+504 9215-2917', 103, NULL),
        (104, N'+504 9479-7510', 104, NULL),
        (105, N'+504 2657-2458', 105, NULL),
        (106, N'+504 8146-1065', 106, NULL),
        (107, N'+504 8439-4215', 107, NULL),
        (108, N'+504 9877-6895', 108, NULL),
        (109, N'+504 3816-3514', 109, NULL),
        (110, N'+504 9224-3975', 110, NULL),
        (111, N'+504 3187-1376', 111, NULL),
        (112, N'+504 8557-4123', 112, NULL),
        (113, N'+504 3925-9570', 113, NULL),
        (114, N'+504 2958-3416', 114, NULL),
        (115, N'+504 2722-3175', 115, NULL),
        (116, N'+504 3168-4350', 116, NULL),
        (117, N'+504 2861-7474', 117, NULL),
        (118, N'+504 2223-5209', NULL, 1),
        (119, N'+504 2235-8911', NULL, 2),
        (120, N'+504 2227-1817', NULL, 3),
        (121, N'+504 2208-8206', NULL, 4),
        (122, N'+504 2281-4110', NULL, 5),
        (123, N'+504 2269-1297', NULL, 6),
        (124, N'+504 2240-4351', NULL, 7),
        (125, N'+504 2265-9615', NULL, 8),
        (126, N'+504 2222-8068', NULL, 9),
        (127, N'+504 2218-5417', NULL, 10),
        (128, N'+504 2259-3151', NULL, 11),
        (129, N'+504 2293-9806', NULL, 12),
        (130, N'+504 2277-2112', NULL, 13),
        (131, N'+504 2297-2168', NULL, 14),
        (132, N'+504 2237-7413', NULL, 15);
    SET IDENTITY_INSERT dbo.Phones OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Directions)
BEGIN
    SET IDENTITY_INSERT dbo.Directions ON;
    INSERT INTO dbo.Directions (Id, Direction, City, DirectionType, IsDefault, Person_Id, LegalEntity_Id) VALUES
        (1, N'Col. Cáceres, calle 5, casa #33', N'Comayagua', N'HOME', 0, 75, NULL),
        (2, N'Col. Martínez, calle 1, casa #6', N'Tegucigalpa', N'HOME', 0, 76, NULL),
        (3, N'Col. Aguilar, calle 26, casa #41', N'Santa Rosa de Copán', N'HOME', 0, 77, NULL),
        (4, N'Col. López, calle 18, casa #64', N'San Pedro Sula', N'HOME', 0, 78, NULL),
        (5, N'Col. Mejía, calle 25, casa #21', N'Comayagua', N'HOME', 0, 79, NULL),
        (6, N'Col. Bonilla, calle 16, casa #17', N'Juticalpa', N'HOME', 0, 80, NULL),
        (7, N'Col. Martínez, calle 10, casa #82', N'Tegucigalpa', N'HOME', 0, 81, NULL),
        (8, N'Col. Ordóñez, calle 18, casa #77', N'La Ceiba', N'HOME', 0, 82, NULL),
        (9, N'Col. Soto, calle 22, casa #43', N'Juticalpa', N'HOME', 0, 83, NULL),
        (10, N'Col. Midence, calle 10, casa #34', N'Santa Rosa de Copán', N'HOME', 0, 84, NULL),
        (11, N'Col. Banegas, calle 1, casa #86', N'Juticalpa', N'HOME', 0, 85, NULL),
        (12, N'Col. Euceda, calle 27, casa #92', N'Danlí', N'HOME', 0, 86, NULL),
        (13, N'Col. García, calle 27, casa #2', N'San Pedro Sula', N'HOME', 0, 87, NULL),
        (14, N'Col. Bonilla, calle 29, casa #34', N'Santa Rosa de Copán', N'HOME', 0, 88, NULL),
        (15, N'Col. Núñez, calle 8, casa #37', N'La Ceiba', N'HOME', 0, 89, NULL),
        (16, N'Col. Reyes, calle 19, casa #12', N'El Progreso', N'HOME', 0, 90, NULL),
        (17, N'Col. Lagos, calle 15, casa #48', N'Santa Rosa de Copán', N'HOME', 0, 91, NULL),
        (18, N'Col. Pérez, calle 15, casa #26', N'Choluteca', N'HOME', 0, 92, NULL),
        (19, N'Col. Pérez, calle 15, casa #39', N'Comayagua', N'HOME', 0, 93, NULL),
        (20, N'Col. Banegas, calle 8, casa #49', N'La Ceiba', N'HOME', 0, 94, NULL),
        (21, N'Col. Ramírez, calle 16, casa #94', N'Juticalpa', N'HOME', 0, 95, NULL),
        (22, N'Col. Martínez, calle 1, casa #99', N'Santa Rosa de Copán', N'HOME', 0, 96, NULL),
        (23, N'Col. Castillo, calle 2, casa #15', N'Juticalpa', N'HOME', 0, 97, NULL),
        (24, N'Col. Midence, calle 27, casa #60', N'Santa Rosa de Copán', N'HOME', 0, 98, NULL),
        (25, N'Col. Cáceres, calle 6, casa #17', N'Santa Rosa de Copán', N'HOME', 0, 99, NULL),
        (26, N'Col. Palma, calle 13, casa #40', N'Santa Rosa de Copán', N'HOME', 0, 100, NULL),
        (27, N'Col. Banegas, calle 25, casa #18', N'Danlí', N'HOME', 0, 101, NULL),
        (28, N'Col. Reyes, calle 6, casa #21', N'Comayagua', N'HOME', 0, 102, NULL),
        (29, N'Col. Reyes, calle 1, casa #44', N'Danlí', N'HOME', 0, 103, NULL),
        (30, N'Col. Medina, calle 25, casa #84', N'El Progreso', N'HOME', 0, 104, NULL),
        (31, N'Col. Hernández, calle 17, casa #18', N'Choluteca', N'HOME', 0, 105, NULL),
        (32, N'Col. Banegas, calle 24, casa #68', N'San Pedro Sula', N'HOME', 0, 106, NULL),
        (33, N'Col. García, calle 16, casa #93', N'La Ceiba', N'HOME', 0, 107, NULL),
        (34, N'Col. Aguilar, calle 27, casa #78', N'San Pedro Sula', N'HOME', 0, 108, NULL),
        (35, N'Col. López, calle 22, casa #10', N'San Pedro Sula', N'HOME', 0, 109, NULL),
        (36, N'Col. Cruz, calle 29, casa #1', N'Choluteca', N'HOME', 0, 110, NULL),
        (37, N'Col. Euceda, calle 30, casa #3', N'San Pedro Sula', N'HOME', 0, 111, NULL),
        (38, N'Col. Cáceres, calle 8, casa #19', N'Santa Rosa de Copán', N'HOME', 0, 112, NULL),
        (39, N'Col. López, calle 15, casa #41', N'San Pedro Sula', N'HOME', 0, 113, NULL),
        (40, N'Col. Rodríguez, calle 20, casa #80', N'Danlí', N'HOME', 0, 114, NULL),
        (41, N'Zona industrial, bodega 14', N'Roatán', N'WORK', 1, NULL, 1),
        (42, N'Zona industrial, bodega 3', N'Juticalpa', N'WORK', 1, NULL, 2),
        (43, N'Zona industrial, bodega 18', N'Santa Rosa de Copán', N'WORK', 1, NULL, 3),
        (44, N'Zona industrial, bodega 35', N'Choluteca', N'WORK', 1, NULL, 4),
        (45, N'Zona industrial, bodega 10', N'Tegucigalpa', N'WORK', 1, NULL, 5),
        (46, N'Zona industrial, bodega 20', N'San Pedro Sula', N'WORK', 1, NULL, 6),
        (47, N'Zona industrial, bodega 19', N'Roatán', N'WORK', 1, NULL, 7),
        (48, N'Zona industrial, bodega 39', N'Juticalpa', N'WORK', 1, NULL, 8),
        (49, N'Zona industrial, bodega 2', N'Santa Rosa de Copán', N'WORK', 1, NULL, 9),
        (50, N'Zona industrial, bodega 31', N'Santa Rosa de Copán', N'WORK', 1, NULL, 10),
        (51, N'Zona industrial, bodega 12', N'Juticalpa', N'WORK', 1, NULL, 11),
        (52, N'Zona industrial, bodega 34', N'Santa Rosa de Copán', N'WORK', 1, NULL, 12),
        (53, N'Zona industrial, bodega 13', N'El Progreso', N'WORK', 1, NULL, 13),
        (54, N'Zona industrial, bodega 11', N'Roatán', N'WORK', 1, NULL, 14),
        (55, N'Zona industrial, bodega 34', N'Comayagua', N'WORK', 1, NULL, 15),
        (56, N'Col. Mejía, calle 3, casa #3', N'Choluteca', N'HOME', 0, 18, NULL),
        (57, N'Col. Rodríguez, calle 4, casa #31', N'Roatán', N'HOME', 0, 19, NULL),
        (58, N'Col. Pérez, calle 24, casa #64', N'San Pedro Sula', N'HOME', 0, 46, NULL),
        (59, N'Col. López, calle 6, casa #91', N'El Progreso', N'SHIPPING', 1, 75, NULL),
        (60, N'Col. Rodríguez, calle 5, casa #81', N'La Ceiba', N'SHIPPING', 1, 76, NULL),
        (61, N'Col. Rodríguez, calle 13, casa #66', N'Juticalpa', N'SHIPPING', 1, 77, NULL),
        (62, N'Col. Mejía, calle 30, casa #64', N'Santa Rosa de Copán', N'SHIPPING', 1, 78, NULL),
        (63, N'Col. Castillo, calle 23, casa #78', N'El Progreso', N'SHIPPING', 1, 79, NULL),
        (64, N'Col. Aguilar, calle 4, casa #69', N'Danlí', N'SHIPPING', 1, 80, NULL),
        (65, N'Col. Rivera, calle 27, casa #33', N'Choluteca', N'SHIPPING', 1, 81, NULL),
        (66, N'Col. Varela, calle 21, casa #50', N'Danlí', N'SHIPPING', 1, 82, NULL),
        (67, N'Col. Lagos, calle 1, casa #7', N'Choluteca', N'SHIPPING', 1, 83, NULL),
        (68, N'Col. Castillo, calle 7, casa #89', N'Roatán', N'SHIPPING', 1, 84, NULL),
        (69, N'Col. Banegas, calle 29, casa #50', N'Choluteca', N'SHIPPING', 1, 85, NULL),
        (70, N'Col. Cáceres, calle 27, casa #64', N'San Pedro Sula', N'SHIPPING', 1, 86, NULL),
        (71, N'Col. Mendoza, calle 22, casa #96', N'Comayagua', N'SHIPPING', 1, 87, NULL),
        (72, N'Col. Martínez, calle 13, casa #86', N'Tegucigalpa', N'SHIPPING', 1, 88, NULL),
        (73, N'Col. Cáceres, calle 26, casa #29', N'San Pedro Sula', N'SHIPPING', 1, 89, NULL),
        (74, N'Col. Bonilla, calle 27, casa #99', N'Choluteca', N'SHIPPING', 1, 90, NULL),
        (75, N'Col. Núñez, calle 5, casa #75', N'La Ceiba', N'SHIPPING', 1, 91, NULL),
        (76, N'Col. Pérez, calle 20, casa #33', N'La Ceiba', N'SHIPPING', 1, 92, NULL),
        (77, N'Col. Mendoza, calle 24, casa #75', N'El Progreso', N'SHIPPING', 1, 93, NULL),
        (78, N'Col. Funes, calle 27, casa #20', N'La Ceiba', N'SHIPPING', 1, 94, NULL),
        (79, N'Col. Euceda, calle 28, casa #4', N'El Progreso', N'SHIPPING', 1, 95, NULL),
        (80, N'Col. García, calle 14, casa #11', N'Danlí', N'SHIPPING', 1, 96, NULL),
        (81, N'Col. Martínez, calle 18, casa #65', N'Comayagua', N'SHIPPING', 1, 97, NULL),
        (82, N'Col. Varela, calle 16, casa #25', N'Danlí', N'SHIPPING', 1, 98, NULL),
        (83, N'Col. Rodríguez, calle 22, casa #88', N'El Progreso', N'SHIPPING', 1, 99, NULL),
        (84, N'Col. Martínez, calle 25, casa #94', N'Tegucigalpa', N'SHIPPING', 1, 100, NULL),
        (85, N'Col. Castillo, calle 22, casa #89', N'Danlí', N'SHIPPING', 1, 101, NULL),
        (86, N'Col. Euceda, calle 1, casa #14', N'Choluteca', N'SHIPPING', 1, 102, NULL),
        (87, N'Col. Martínez, calle 20, casa #79', N'La Ceiba', N'SHIPPING', 1, 103, NULL),
        (88, N'Col. Ramírez, calle 19, casa #13', N'Juticalpa', N'SHIPPING', 1, 104, NULL),
        (89, N'Col. Ramírez, calle 29, casa #74', N'Choluteca', N'SHIPPING', 1, 105, NULL),
        (90, N'Col. Aguilar, calle 9, casa #78', N'Choluteca', N'SHIPPING', 1, 106, NULL),
        (91, N'Col. Zelaya, calle 29, casa #23', N'El Progreso', N'SHIPPING', 1, 18, NULL),
        (92, N'Col. Zelaya, calle 14, casa #98', N'Choluteca', N'SHIPPING', 1, 19, NULL),
        (93, N'Col. Midence, calle 2, casa #89', N'Choluteca', N'SHIPPING', 1, 46, NULL);
    SET IDENTITY_INSERT dbo.Directions OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Supplier)
BEGIN
    SET IDENTITY_INSERT dbo.Supplier ON;
    INSERT INTO dbo.Supplier (Id, SupplierType, Person_Id, LegalEntity_Id) VALUES
        (1, N'J', NULL, 1),
        (2, N'J', NULL, 2),
        (3, N'J', NULL, 3),
        (4, N'J', NULL, 4),
        (5, N'J', NULL, 5),
        (6, N'J', NULL, 6),
        (7, N'J', NULL, 7),
        (8, N'J', NULL, 8),
        (9, N'J', NULL, 9),
        (10, N'J', NULL, 10),
        (11, N'J', NULL, 11),
        (12, N'J', NULL, 12),
        (13, N'J', NULL, 13),
        (14, N'J', NULL, 14),
        (15, N'J', NULL, 15),
        (16, N'N', 115, NULL),
        (17, N'N', 116, NULL),
        (18, N'N', 117, NULL);
    SET IDENTITY_INSERT dbo.Supplier OFF;
END
GO

-- Gestión de seguridad
IF NOT EXISTS (SELECT 1 FROM dbo.Role)
BEGIN
    SET IDENTITY_INSERT dbo.Role ON;
    INSERT INTO dbo.Role (Id, Name, Description, HierarchyLevel, ScopeType) VALUES
        (1, N'Admin', N'Dueño de la empresa: acceso total sin excepción', 1, N'GLOBAL'),
        (2, N'NationalManager', N'Jefe de todas las áreas: ve y gestiona toda la empresa', 2, N'GLOBAL'),
        (3, N'AreaManager', N'Jefe de área: gestiona y compara las tiendas de su área', 3, N'AREA'),
        (4, N'StoreSupervisor', N'Supervisor: control operativo completo de su tienda', 4, N'STORE'),
        (5, N'Staff', N'Personal de tienda (caja, bodega, piso de venta)', 5, N'STORE'),
        (6, N'Customer', N'Cliente con cuenta web: solo ve y gestiona lo propio', 9, N'SELF');
    SET IDENTITY_INSERT dbo.Role OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Permission)
BEGIN
    SET IDENTITY_INSERT dbo.Permission ON;
    INSERT INTO dbo.Permission (Id, Code, Module, ActionType) VALUES
        (1, N'person.create', N'person', N'create'),
        (2, N'person.read', N'person', N'read'),
        (3, N'person.update', N'person', N'update'),
        (4, N'person.delete', N'person', N'delete'),
        (5, N'catalog.create', N'catalog', N'create'),
        (6, N'catalog.read', N'catalog', N'read'),
        (7, N'catalog.update', N'catalog', N'update'),
        (8, N'catalog.delete', N'catalog', N'delete'),
        (9, N'inventory.create', N'inventory', N'create'),
        (10, N'inventory.read', N'inventory', N'read'),
        (11, N'inventory.update', N'inventory', N'update'),
        (12, N'inventory.delete', N'inventory', N'delete'),
        (13, N'purchase.create', N'purchase', N'create'),
        (14, N'purchase.read', N'purchase', N'read'),
        (15, N'purchase.update', N'purchase', N'update'),
        (16, N'purchase.delete', N'purchase', N'delete'),
        (17, N'sales.create', N'sales', N'create'),
        (18, N'sales.read', N'sales', N'read'),
        (19, N'sales.update', N'sales', N'update'),
        (20, N'sales.delete', N'sales', N'delete'),
        (21, N'promotion.create', N'promotion', N'create'),
        (22, N'promotion.read', N'promotion', N'read'),
        (23, N'promotion.update', N'promotion', N'update'),
        (24, N'promotion.delete', N'promotion', N'delete'),
        (25, N'hr.create', N'hr', N'create'),
        (26, N'hr.read', N'hr', N'read'),
        (27, N'hr.update', N'hr', N'update'),
        (28, N'hr.delete', N'hr', N'delete'),
        (29, N'finance.create', N'finance', N'create'),
        (30, N'finance.read', N'finance', N'read'),
        (31, N'finance.update', N'finance', N'update'),
        (32, N'finance.delete', N'finance', N'delete'),
        (33, N'store.create', N'store', N'create'),
        (34, N'store.read', N'store', N'read'),
        (35, N'store.update', N'store', N'update'),
        (36, N'store.delete', N'store', N'delete'),
        (37, N'security.create', N'security', N'create'),
        (38, N'security.read', N'security', N'read'),
        (39, N'security.update', N'security', N'update'),
        (40, N'security.delete', N'security', N'delete'),
        (41, N'closet.create', N'closet', N'create'),
        (42, N'closet.read', N'closet', N'read'),
        (43, N'closet.update', N'closet', N'update'),
        (44, N'closet.delete', N'closet', N'delete');
    SET IDENTITY_INSERT dbo.Permission OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.RolePermission)
BEGIN
    INSERT INTO dbo.RolePermission (Role_Id, Permission_Id) VALUES
        (1, 1),
        (1, 2),
        (1, 3),
        (1, 4),
        (1, 5),
        (1, 6),
        (1, 7),
        (1, 8),
        (1, 9),
        (1, 10),
        (1, 11),
        (1, 12),
        (1, 13),
        (1, 14),
        (1, 15),
        (1, 16),
        (1, 17),
        (1, 18),
        (1, 19),
        (1, 20),
        (1, 21),
        (1, 22),
        (1, 23),
        (1, 24),
        (1, 25),
        (1, 26),
        (1, 27),
        (1, 28),
        (1, 29),
        (1, 30),
        (1, 31),
        (1, 32),
        (1, 33),
        (1, 34),
        (1, 35),
        (1, 36),
        (1, 37),
        (1, 38),
        (1, 39),
        (1, 40),
        (1, 41),
        (1, 42),
        (1, 43),
        (1, 44),
        (2, 1),
        (2, 2),
        (2, 3),
        (2, 5),
        (2, 6),
        (2, 7),
        (2, 9),
        (2, 10),
        (2, 11),
        (2, 13),
        (2, 14),
        (2, 15),
        (2, 17),
        (2, 18),
        (2, 19),
        (2, 21),
        (2, 22),
        (2, 23),
        (2, 25),
        (2, 26),
        (2, 27),
        (2, 29),
        (2, 30),
        (2, 31),
        (2, 33),
        (2, 34),
        (2, 35),
        (2, 38),
        (3, 1),
        (3, 2),
        (3, 3),
        (3, 6),
        (3, 9),
        (3, 10),
        (3, 11),
        (3, 13),
        (3, 14),
        (3, 15),
        (3, 17),
        (3, 18),
        (3, 19),
        (3, 21),
        (3, 22),
        (3, 23),
        (3, 25),
        (3, 26),
        (3, 27),
        (3, 29),
        (3, 30),
        (3, 31),
        (3, 34),
        (3, 35),
        (4, 1),
        (4, 2),
        (4, 3),
        (4, 6),
        (4, 9),
        (4, 10),
        (4, 11),
        (4, 13),
        (4, 14),
        (4, 15),
        (4, 17),
        (4, 18),
        (4, 19),
        (4, 22),
        (4, 26),
        (4, 29),
        (4, 30),
        (4, 31),
        (4, 34),
        (5, 1),
        (5, 2),
        (5, 3),
        (5, 6),
        (5, 10),
        (5, 17),
        (5, 18),
        (5, 22),
        (5, 34),
        (6, 6),
        (6, 17),
        (6, 18),
        (6, 2),
        (6, 3),
        (6, 41),
        (6, 42),
        (6, 43),
        (6, 44);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Account)
BEGIN
    SET IDENTITY_INSERT dbo.Account ON;
    INSERT INTO dbo.Account (Id, Person_Id, Username, PasswordHash, IsLocked, FailedAttempts, LastLoginDate) VALUES
        (1, 1, N'juan.reyes.001', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-08T08:02:28'),
        (2, 2, N'jorge.castillo.002', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-06T08:53:38'),
        (3, 3, N'wilmer.palma.003', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-19T06:04:41'),
        (4, 4, N'fredy.padilla.004', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-03T11:55:41'),
        (5, 5, N'rolando.perez.005', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-21T18:30:12'),
        (6, 6, N'samuel.zelaya.006', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-03T05:21:04'),
        (7, 7, N'ana.caceres.007', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-06T19:04:36'),
        (8, 8, N'gloria.lagos.008', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-06T19:21:44'),
        (9, 9, N'fatima.rodriguez.009', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-03T21:41:59'),
        (10, 10, N'rosa.ramirez.010', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-20T01:30:17'),
        (11, 11, N'claudia.ordonez.011', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-10T11:31:57'),
        (12, 12, N'norma.varela.012', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-02T08:39:35'),
        (13, 13, N'keila.lopez.013', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-04T04:38:17'),
        (14, 14, N'luis.mejia.014', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-09T18:51:41'),
        (15, 15, N'oscar.rivera.015', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-16T00:47:24'),
        (16, 16, N'kevin.euceda.016', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-20T01:15:45'),
        (17, 17, N'walter.soto.017', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-04T13:12:52'),
        (18, 18, N'hector.flores.018', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-07T02:57:46'),
        (19, 19, N'edgardo.mendoza.019', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-01T04:19:58'),
        (20, 20, N'maria.medina.020', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-15T05:41:13'),
        (21, 21, N'sandra.bonilla.021', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-06T09:19:41'),
        (22, 22, N'daniela.garcia.022', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-03T06:05:44'),
        (23, 23, N'wendy.aguilar.023', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-18T04:59:08'),
        (24, 24, N'patricia.banegas.024', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-17T09:35:06'),
        (25, 25, N'gabriela.funes.025', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-06T17:43:00'),
        (26, 26, N'dilcia.martinez.026', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-07T22:42:20'),
        (27, 27, N'carlos.cruz.027', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-16T11:05:22'),
        (28, 28, N'mario.nunez.028', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-08T01:40:34'),
        (29, 29, N'marvin.midence.029', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-14T06:46:23'),
        (30, 30, N'elvin.hernandez.030', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-11T13:17:08'),
        (31, 31, N'denis.reyes.031', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-16T11:16:59'),
        (32, 32, N'nelson.castillo.032', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-09T06:12:56'),
        (33, 33, N'daniel.palma.033', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-16T18:59:29'),
        (34, 34, N'karla.padilla.034', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-15T16:31:53'),
        (35, 35, N'lourdes.perez.035', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-05T08:27:46'),
        (36, 36, N'jessica.zelaya.036', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-03T18:53:53'),
        (37, 37, N'marcela.caceres.037', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-21T18:00:37'),
        (38, 38, N'yesenia.lagos.038', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-18T17:59:03'),
        (39, 39, N'elsa.rodriguez.039', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-07T00:41:47'),
        (40, 40, N'jose.ramirez.040', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-20T22:55:47'),
        (41, 41, N'juan.ordonez.041', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-08T00:56:39'),
        (42, 42, N'jorge.varela.042', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-01T06:42:59'),
        (43, 43, N'wilmer.lopez.043', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-02T01:07:36'),
        (44, 44, N'fredy.mejia.044', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-20T21:56:22'),
        (45, 45, N'rolando.rivera.045', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-18T21:20:14'),
        (46, 46, N'samuel.euceda.046', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-20T08:32:07'),
        (47, 47, N'ana.soto.047', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-09T14:18:27'),
        (48, 48, N'gloria.flores.048', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-21T17:42:26'),
        (49, 49, N'fatima.mendoza.049', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-06T22:37:08'),
        (50, 50, N'rosa.medina.050', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-15T01:38:25'),
        (51, 51, N'claudia.bonilla.051', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-03T19:26:43'),
        (52, 52, N'norma.garcia.052', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-18T20:42:28'),
        (53, 53, N'keila.aguilar.053', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-14T09:20:01'),
        (54, 54, N'luis.banegas.054', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-08T03:36:33'),
        (55, 55, N'oscar.funes.055', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-21T12:08:19'),
        (56, 56, N'kevin.martinez.056', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-16T05:37:36'),
        (57, 57, N'walter.cruz.057', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-17T11:28:12'),
        (58, 58, N'hector.nunez.058', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-02T16:28:53'),
        (59, 59, N'edgardo.midence.059', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-20T04:45:19'),
        (60, 60, N'maria.hernandez.060', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-14T05:15:33'),
        (61, 61, N'sandra.reyes.061', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-08T08:19:18'),
        (62, 62, N'daniela.castillo.062', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-08T23:26:42'),
        (63, 63, N'wendy.palma.063', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-06T10:27:37'),
        (64, 64, N'patricia.padilla.064', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-18T20:52:46'),
        (65, 65, N'gabriela.perez.065', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-16T22:53:03'),
        (66, 66, N'dilcia.zelaya.066', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-13T18:49:36'),
        (67, 67, N'carlos.caceres.067', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-05T11:50:15'),
        (68, 68, N'mario.lagos.068', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-04T19:52:06'),
        (69, 69, N'marvin.rodriguez.069', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-17T13:04:43'),
        (70, 70, N'elvin.ramirez.070', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-02T23:14:10'),
        (71, 71, N'denis.ordonez.071', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-15T23:48:10'),
        (72, 72, N'nelson.varela.072', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-09T12:40:25'),
        (73, 73, N'daniel.lopez.073', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-10T03:40:32'),
        (74, 74, N'karla.mejia.074', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-13T17:50:10'),
        (75, 75, N'cliente075', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-09T11:37:43'),
        (76, 76, N'cliente076', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-15T16:23:19'),
        (77, 77, N'cliente077', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-10-26T05:55:12'),
        (78, 78, N'cliente078', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-14T04:44:52'),
        (79, 79, N'cliente079', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-20T09:40:42'),
        (80, 80, N'cliente080', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-10-25T05:44:55'),
        (81, 81, N'cliente081', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-10-22T00:30:28'),
        (82, 82, N'cliente082', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-13T19:23:06'),
        (83, 83, N'cliente083', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-10-23T09:53:49'),
        (84, 84, N'cliente084', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-21T02:51:43'),
        (85, 85, N'cliente085', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-11T01:39:36'),
        (86, 86, N'cliente086', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-10-30T04:08:50'),
        (87, 87, N'cliente087', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-01T23:02:51'),
        (88, 88, N'cliente088', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-04T14:10:53'),
        (89, 89, N'cliente089', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-16T18:03:25'),
        (90, 90, N'cliente090', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-07T13:16:07'),
        (91, 91, N'cliente091', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-10-20T14:58:57'),
        (92, 92, N'cliente092', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-06T21:53:49'),
        (93, 93, N'cliente093', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-18T08:02:27'),
        (94, 94, N'cliente094', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-04T10:43:07'),
        (95, 95, N'cliente095', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-17T06:44:36'),
        (96, 96, N'cliente096', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-10-12T04:58:08'),
        (97, 97, N'cliente097', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-10-27T20:29:40'),
        (98, 98, N'cliente098', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-14T07:39:12'),
        (99, 99, N'cliente099', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-01T09:04:44'),
        (100, 100, N'cliente100', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 1, 5, '2026-10-10T18:54:06'),
        (101, 101, N'cliente101', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-19T08:20:46'),
        (102, 102, N'cliente102', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-01T19:33:04'),
        (103, 103, N'cliente103', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-03T18:10:06'),
        (104, 104, N'cliente104', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-01T22:08:19'),
        (105, 105, N'cliente105', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-10-12T14:37:27'),
        (106, 106, N'cliente106', N'$2a$11$MUESTRAdePruebaNoEsUnHashReal0123456789abcdefghijklmnopq', 0, 0, '2026-11-03T12:54:26');
    SET IDENTITY_INSERT dbo.Account OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.AccountRole)
BEGIN
    INSERT INTO dbo.AccountRole (Account_Id, Role_Id) VALUES
        (1, 1),
        (2, 2),
        (3, 3),
        (4, 3),
        (5, 3),
        (6, 3),
        (7, 3),
        (8, 3),
        (9, 3),
        (10, 3),
        (11, 3),
        (12, 3),
        (13, 3),
        (14, 3),
        (15, 3),
        (16, 3),
        (17, 3),
        (18, 4),
        (19, 4),
        (20, 4),
        (21, 4),
        (22, 4),
        (23, 4),
        (24, 4),
        (25, 4),
        (26, 4),
        (27, 4),
        (28, 4),
        (29, 4),
        (30, 4),
        (31, 4),
        (32, 4),
        (33, 4),
        (34, 4),
        (35, 4),
        (36, 4),
        (37, 4),
        (38, 4),
        (39, 4),
        (40, 4),
        (41, 4),
        (42, 4),
        (43, 4),
        (44, 4),
        (45, 4),
        (46, 5),
        (47, 5),
        (48, 5),
        (49, 5),
        (50, 5),
        (51, 5),
        (52, 5),
        (53, 5),
        (54, 5),
        (55, 5),
        (56, 5),
        (57, 5),
        (58, 5),
        (59, 5),
        (60, 5),
        (61, 5),
        (62, 5),
        (63, 5),
        (64, 5),
        (65, 5),
        (66, 5),
        (67, 5),
        (68, 5),
        (69, 5),
        (70, 5),
        (71, 5),
        (72, 5),
        (73, 5),
        (74, 5),
        (75, 6),
        (76, 6),
        (77, 6),
        (78, 6),
        (79, 6),
        (80, 6),
        (81, 6),
        (82, 6),
        (83, 6),
        (84, 6),
        (85, 6),
        (86, 6),
        (87, 6),
        (88, 6),
        (89, 6),
        (90, 6),
        (91, 6),
        (92, 6),
        (93, 6),
        (94, 6),
        (95, 6),
        (96, 6),
        (97, 6),
        (98, 6),
        (99, 6),
        (100, 6),
        (101, 6),
        (102, 6),
        (103, 6),
        (104, 6),
        (105, 6),
        (106, 6),
        (18, 6),
        (19, 6),
        (46, 6);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.AuditLog)
BEGIN
    SET IDENTITY_INSERT dbo.AuditLog ON;
    INSERT INTO dbo.AuditLog (Id, Account_Id, TableName, RecordId, ActionType, OldValues, NewValues, AuditDate) VALUES
        (1, 60, N'Bill', N'7', N'INSERT', NULL, N'{"BillCode":"FAC-000007","Status":"PAID"}', '2026-08-10T10:14:00'),
        (2, 57, N'Bill', N'11', N'INSERT', NULL, N'{"BillCode":"FAC-000011","Status":"PAID"}', '2026-06-08T07:45:25'),
        (3, 55, N'Bill', N'373', N'INSERT', NULL, N'{"BillCode":"FAC-000373","Status":"PAID"}', '2026-11-10T07:32:18'),
        (4, 74, N'ClotheVariant', N'155', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-09-03T12:28:43'),
        (5, 33, N'ClotheVariant', N'98', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-09-11T13:43:33'),
        (6, 23, N'Bill', N'13', N'INSERT', NULL, N'{"BillCode":"FAC-000013","Status":"PAID"}', '2026-09-27T04:24:54'),
        (7, 69, N'Bill', N'149', N'INSERT', NULL, N'{"BillCode":"FAC-000149","Status":"PAID"}', '2026-09-22T17:35:58'),
        (8, 2, N'ClotheVariant', N'21', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-10-10T03:15:06'),
        (9, 63, N'Bill', N'335', N'INSERT', NULL, N'{"BillCode":"FAC-000335","Status":"PAID"}', '2026-07-07T13:56:26'),
        (10, 89, N'Bill', N'69', N'INSERT', NULL, N'{"BillCode":"FAC-000069","Status":"PAID"}', '2026-07-31T11:20:15'),
        (11, 43, N'Account', N'43', N'LOGIN', NULL, NULL, '2026-07-09T01:43:02'),
        (12, 64, N'Bill', N'133', N'INSERT', NULL, N'{"BillCode":"FAC-000133","Status":"PAID"}', '2026-07-03T20:30:21'),
        (13, 95, N'ClotheVariant', N'37', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-06-18T12:29:39'),
        (14, 57, N'ClotheVariant', N'50', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-08-04T06:35:26'),
        (15, 29, N'ClotheVariant', N'61', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-08-06T01:36:45'),
        (16, 62, N'ClotheVariant', N'102', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-10-10T22:38:21'),
        (17, 85, N'Bill', N'20', N'INSERT', NULL, N'{"BillCode":"FAC-000020","Status":"PAID"}', '2026-07-02T09:41:54'),
        (18, 55, N'ClotheVariant', N'153', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-06-15T18:22:06'),
        (19, 29, N'ClotheVariant', N'54', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-11-04T18:02:06'),
        (20, 10, N'Account', N'10', N'LOGIN', NULL, NULL, '2026-10-13T20:31:40'),
        (21, 34, N'ClotheVariant', N'20', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-09-16T01:01:32'),
        (22, 5, N'ClotheVariant', N'2', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-09-24T13:46:03'),
        (23, 50, N'Bill', N'372', N'INSERT', NULL, N'{"BillCode":"FAC-000372","Status":"PAID"}', '2026-07-23T19:49:33'),
        (24, 94, N'ClotheVariant', N'130', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-08-29T03:21:16'),
        (25, 26, N'ClotheVariant', N'114', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-07-31T15:04:38'),
        (26, 77, N'ClotheVariant', N'107', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-09-15T23:42:48'),
        (27, 29, N'Bill', N'239', N'INSERT', NULL, N'{"BillCode":"FAC-000239","Status":"PAID"}', '2026-07-19T08:56:06'),
        (28, 61, N'ClotheVariant', N'137', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-11-05T10:59:07'),
        (29, 72, N'ClotheVariant', N'150', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-09-30T19:32:24'),
        (30, 76, N'Account', N'76', N'LOGIN', NULL, NULL, '2026-07-05T17:35:43'),
        (31, 78, N'ClotheVariant', N'114', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-11-08T00:52:15'),
        (32, 73, N'Bill', N'226', N'INSERT', NULL, N'{"BillCode":"FAC-000226","Status":"PAID"}', '2026-10-13T18:39:43'),
        (33, 20, N'ClotheVariant', N'101', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-11-16T18:38:07'),
        (34, 78, N'Account', N'78', N'LOGIN', NULL, NULL, '2026-11-12T13:35:44'),
        (35, 4, N'Account', N'4', N'LOGIN', NULL, NULL, '2026-10-28T14:58:49'),
        (36, 67, N'Bill', N'8', N'INSERT', NULL, N'{"BillCode":"FAC-000008","Status":"PAID"}', '2026-09-25T21:29:57'),
        (37, 97, N'Account', N'97', N'LOGIN', NULL, NULL, '2026-10-12T18:31:58'),
        (38, 12, N'Account', N'12', N'LOGIN', NULL, NULL, '2026-09-06T15:31:06'),
        (39, 2, N'Account', N'2', N'LOGIN', NULL, NULL, '2026-06-25T20:52:14'),
        (40, 101, N'Account', N'101', N'LOGIN', NULL, NULL, '2026-06-15T08:09:43'),
        (41, 75, N'ClotheVariant', N'132', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-08-17T20:50:07'),
        (42, 10, N'Account', N'10', N'LOGIN', NULL, NULL, '2026-06-11T07:23:59'),
        (43, 10, N'ClotheVariant', N'46', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-08-09T17:29:41'),
        (44, 52, N'Bill', N'371', N'INSERT', NULL, N'{"BillCode":"FAC-000371","Status":"PAID"}', '2026-07-05T20:53:53'),
        (45, 96, N'Bill', N'331', N'INSERT', NULL, N'{"BillCode":"FAC-000331","Status":"PAID"}', '2026-10-30T02:54:18'),
        (46, 12, N'ClotheVariant', N'137', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-11-15T16:22:16'),
        (47, 58, N'Account', N'58', N'LOGIN', NULL, NULL, '2026-09-07T08:51:43'),
        (48, 30, N'Bill', N'193', N'INSERT', NULL, N'{"BillCode":"FAC-000193","Status":"PAID"}', '2026-08-10T11:27:36'),
        (49, 24, N'Account', N'24', N'LOGIN', NULL, NULL, '2026-09-15T04:54:44'),
        (50, 23, N'Bill', N'276', N'INSERT', NULL, N'{"BillCode":"FAC-000276","Status":"PAID"}', '2026-09-24T17:18:51'),
        (51, 71, N'Account', N'71', N'LOGIN', NULL, NULL, '2026-09-28T01:51:39'),
        (52, 9, N'Account', N'9', N'LOGIN', NULL, NULL, '2026-06-19T05:04:07'),
        (53, 27, N'Account', N'27', N'LOGIN', NULL, NULL, '2026-06-01T03:14:58'),
        (54, 81, N'ClotheVariant', N'86', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-11-07T07:40:22'),
        (55, 50, N'ClotheVariant', N'135', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-07-31T04:04:32'),
        (56, 71, N'ClotheVariant', N'135', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-09-13T02:01:57'),
        (57, 93, N'ClotheVariant', N'81', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-08-24T12:49:53'),
        (58, 27, N'ClotheVariant', N'97', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-08-04T19:43:35'),
        (59, 81, N'Account', N'81', N'LOGIN', NULL, NULL, '2026-10-18T07:25:58'),
        (60, 42, N'ClotheVariant', N'71', N'UPDATE', N'{"MinStock":3}', N'{"MinStock":5}', '2026-08-06T07:00:33');
    SET IDENTITY_INSERT dbo.AuditLog OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[User])
BEGIN
    SET IDENTITY_INSERT dbo.[User] ON;
    INSERT INTO dbo.[User] (Id, Person_Id) VALUES
        (1, 75),
        (2, 76),
        (3, 77),
        (4, 78),
        (5, 79),
        (6, 80),
        (7, 81),
        (8, 82),
        (9, 83),
        (10, 84),
        (11, 85),
        (12, 86),
        (13, 87),
        (14, 88),
        (15, 89),
        (16, 90),
        (17, 91),
        (18, 92),
        (19, 93),
        (20, 94),
        (21, 95),
        (22, 96),
        (23, 97),
        (24, 98),
        (25, 99),
        (26, 100),
        (27, 101),
        (28, 102),
        (29, 103),
        (30, 104),
        (31, 105),
        (32, 106),
        (33, 18),
        (34, 19),
        (35, 46);
    SET IDENTITY_INSERT dbo.[User] OFF;
END
GO

-- Gestión de organización
IF NOT EXISTS (SELECT 1 FROM dbo.WorkArea)
BEGIN
    SET IDENTITY_INSERT dbo.WorkArea ON;
    INSERT INTO dbo.WorkArea (Id, Name, Description) VALUES
        (1, N'Central', N'Área comercial Central'),
        (2, N'Francisco Morazán Norte', N'Área comercial Francisco Morazán Norte'),
        (3, N'Francisco Morazán Sur', N'Área comercial Francisco Morazán Sur'),
        (4, N'Cortés', N'Área comercial Cortés'),
        (5, N'Atlántida', N'Área comercial Atlántida'),
        (6, N'Yoro', N'Área comercial Yoro'),
        (7, N'Olancho', N'Área comercial Olancho'),
        (8, N'Choluteca', N'Área comercial Choluteca'),
        (9, N'Comayagua', N'Área comercial Comayagua'),
        (10, N'Copán', N'Área comercial Copán'),
        (11, N'El Paraíso', N'Área comercial El Paraíso'),
        (12, N'Santa Bárbara', N'Área comercial Santa Bárbara'),
        (13, N'Lempira', N'Área comercial Lempira'),
        (14, N'Colón', N'Área comercial Colón'),
        (15, N'Islas de la Bahía', N'Área comercial Islas de la Bahía');
    SET IDENTITY_INSERT dbo.WorkArea OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Store)
BEGIN
    SET IDENTITY_INSERT dbo.Store ON;
    INSERT INTO dbo.Store (Id, Name, Direction, StoreType, WorkArea_Id) VALUES
        (1, N'Bodega Central', N'Barrio Centro, Bodega Central', N'WAREHOUSE', 1),
        (2, N'Tienda Virtual', N'Barrio Centro, Tienda Virtual', N'VIRTUAL', 1),
        (3, N'Pedestal Tegucigalpa Centro', N'Barrio Centro, Tegucigalpa Centro', N'PHYSICAL', 2),
        (4, N'Pedestal Tegucigalpa Palmira', N'Barrio Centro, Tegucigalpa Palmira', N'PHYSICAL', 2),
        (5, N'Pedestal Tegucigalpa Kennedy', N'Barrio Centro, Tegucigalpa Kennedy', N'PHYSICAL', 3),
        (6, N'Pedestal Tegucigalpa El Trapiche', N'Barrio Centro, Tegucigalpa El Trapiche', N'PHYSICAL', 3),
        (7, N'Pedestal San Pedro Sula Centro', N'Barrio Centro, San Pedro Sula Centro', N'PHYSICAL', 4),
        (8, N'Pedestal San Pedro Sula Mall', N'Barrio Centro, San Pedro Sula Mall', N'PHYSICAL', 4),
        (9, N'Pedestal La Ceiba Centro', N'Barrio Centro, La Ceiba Centro', N'PHYSICAL', 5),
        (10, N'Pedestal La Ceiba Paseo', N'Barrio Centro, La Ceiba Paseo', N'PHYSICAL', 5),
        (11, N'Pedestal El Progreso Centro', N'Barrio Centro, El Progreso Centro', N'PHYSICAL', 6),
        (12, N'Pedestal Yoro Centro', N'Barrio Centro, Yoro Centro', N'PHYSICAL', 6),
        (13, N'Pedestal Juticalpa Centro', N'Barrio Centro, Juticalpa Centro', N'PHYSICAL', 7),
        (14, N'Pedestal Catacamas Centro', N'Barrio Centro, Catacamas Centro', N'PHYSICAL', 7),
        (15, N'Pedestal Choluteca Centro', N'Barrio Centro, Choluteca Centro', N'PHYSICAL', 8),
        (16, N'Pedestal Choluteca Plaza', N'Barrio Centro, Choluteca Plaza', N'PHYSICAL', 8),
        (17, N'Pedestal Comayagua Centro', N'Barrio Centro, Comayagua Centro', N'PHYSICAL', 9),
        (18, N'Pedestal Siguatepeque Centro', N'Barrio Centro, Siguatepeque Centro', N'PHYSICAL', 9),
        (19, N'Pedestal Santa Rosa de Copán Centro', N'Barrio Centro, Santa Rosa de Copán Centro', N'PHYSICAL', 10),
        (20, N'Pedestal Copán Ruinas', N'Barrio Centro, Copán Ruinas', N'PHYSICAL', 10),
        (21, N'Pedestal Danlí Centro', N'Barrio Centro, Danlí Centro', N'PHYSICAL', 11),
        (22, N'Pedestal Danlí Plaza', N'Barrio Centro, Danlí Plaza', N'PHYSICAL', 11),
        (23, N'Pedestal Santa Bárbara Centro', N'Barrio Centro, Santa Bárbara Centro', N'PHYSICAL', 12),
        (24, N'Pedestal Quimistán Centro', N'Barrio Centro, Quimistán Centro', N'PHYSICAL', 12),
        (25, N'Pedestal Gracias Centro', N'Barrio Centro, Gracias Centro', N'PHYSICAL', 13),
        (26, N'Pedestal Gracias Plaza', N'Barrio Centro, Gracias Plaza', N'PHYSICAL', 13),
        (27, N'Pedestal Trujillo Centro', N'Barrio Centro, Trujillo Centro', N'PHYSICAL', 14),
        (28, N'Pedestal Tocoa Centro', N'Barrio Centro, Tocoa Centro', N'PHYSICAL', 14),
        (29, N'Pedestal Roatán Centro', N'Barrio Centro, Roatán Centro', N'PHYSICAL', 15),
        (30, N'Pedestal Roatán West End', N'Barrio Centro, Roatán West End', N'PHYSICAL', 15);
    SET IDENTITY_INSERT dbo.Store OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Position)
BEGIN
    SET IDENTITY_INSERT dbo.Position ON;
    INSERT INTO dbo.Position (Id, Name, Description, Role_Id) VALUES
        (1, N'Owner', N'Dueño de la empresa', 1),
        (2, N'National Manager', N'Jefe de todas las áreas', 2),
        (3, N'Operations Director', N'Director de operaciones', 2),
        (4, N'Area Manager', N'Jefe de área o sector', 3),
        (5, N'Regional Accountant', N'Contador regional', 3),
        (6, N'Regional Purchasing Agent', N'Agente de compras regional', 3),
        (7, N'Store Supervisor', N'Supervisor de tienda', 4),
        (8, N'Assistant Store Supervisor', N'Subsupervisor de tienda', 4),
        (9, N'Warehouse Supervisor', N'Supervisor de bodega', 4),
        (10, N'Cashier', N'Cajero de tienda', 5),
        (11, N'Sales Associate', N'Vendedor de piso', 5),
        (12, N'Warehouse Clerk', N'Encargado de bodega', 5),
        (13, N'Stock Clerk', N'Auxiliar de inventario', 5),
        (14, N'Customer Service Rep', N'Servicio al cliente', 5),
        (15, N'Visual Merchandiser', N'Encargado de exhibición', 5);
    SET IDENTITY_INSERT dbo.Position OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Employee)
BEGIN
    SET IDENTITY_INSERT dbo.Employee ON;
    INSERT INTO dbo.Employee (Id, Person_Id, HireDate, Salary) VALUES
        (1, 1, '2023-02-02', 150000.00),
        (2, 2, '2024-03-03', 90000.00),
        (3, 3, '2022-04-04', 45000.00),
        (4, 4, '2023-05-05', 45000.00),
        (5, 5, '2024-06-06', 45000.00),
        (6, 6, '2022-07-07', 45000.00),
        (7, 7, '2023-08-08', 45000.00),
        (8, 8, '2024-09-09', 45000.00),
        (9, 9, '2022-10-10', 45000.00),
        (10, 10, '2023-11-11', 45000.00),
        (11, 11, '2024-12-12', 45000.00),
        (12, 12, '2022-01-13', 45000.00),
        (13, 13, '2023-02-14', 45000.00),
        (14, 14, '2024-03-15', 45000.00),
        (15, 15, '2022-04-16', 45000.00),
        (16, 16, '2023-05-17', 45000.00),
        (17, 17, '2024-06-18', 45000.00),
        (18, 18, '2022-07-19', 21000.00),
        (19, 19, '2023-08-20', 21000.00),
        (20, 20, '2024-09-21', 23500.00),
        (21, 21, '2022-10-22', 21000.00),
        (22, 22, '2023-11-23', 22000.00),
        (23, 23, '2024-12-24', 25000.00),
        (24, 24, '2022-01-25', 25000.00),
        (25, 25, '2023-02-26', 23500.00),
        (26, 26, '2024-03-27', 21000.00),
        (27, 27, '2022-04-01', 23500.00),
        (28, 28, '2023-05-02', 22000.00),
        (29, 29, '2024-06-03', 22000.00),
        (30, 30, '2022-07-04', 22000.00),
        (31, 31, '2023-08-05', 22000.00),
        (32, 32, '2024-09-06', 22000.00),
        (33, 33, '2022-10-07', 22000.00),
        (34, 34, '2023-11-08', 22000.00),
        (35, 35, '2024-12-09', 25000.00),
        (36, 36, '2022-01-10', 22000.00),
        (37, 37, '2023-02-11', 21000.00),
        (38, 38, '2024-03-12', 23500.00),
        (39, 39, '2022-04-13', 22000.00),
        (40, 40, '2023-05-14', 22000.00),
        (41, 41, '2024-06-15', 22000.00),
        (42, 42, '2022-07-16', 23500.00),
        (43, 43, '2023-08-17', 25000.00),
        (44, 44, '2024-09-18', 23500.00),
        (45, 45, '2022-10-19', 21000.00),
        (46, 46, '2023-11-20', 11500.00),
        (47, 47, '2024-12-21', 12500.00),
        (48, 48, '2022-01-22', 12500.00),
        (49, 49, '2023-02-23', 13000.00),
        (50, 50, '2024-03-24', 12000.00),
        (51, 51, '2022-04-25', 13000.00),
        (52, 52, '2023-05-26', 12000.00),
        (53, 53, '2024-06-27', 12500.00),
        (54, 54, '2022-07-01', 12500.00),
        (55, 55, '2023-08-02', 12000.00),
        (56, 56, '2024-09-03', 12000.00),
        (57, 57, '2022-10-04', 13000.00),
        (58, 58, '2023-11-05', 12000.00),
        (59, 59, '2024-12-06', 12000.00),
        (60, 60, '2022-01-07', 12500.00),
        (61, 61, '2023-02-08', 13000.00),
        (62, 62, '2024-03-09', 12500.00),
        (63, 63, '2022-04-10', 12000.00),
        (64, 64, '2023-05-11', 12000.00),
        (65, 65, '2024-06-12', 13000.00),
        (66, 66, '2022-07-13', 13000.00),
        (67, 67, '2023-08-14', 13000.00),
        (68, 68, '2024-09-15', 11500.00),
        (69, 69, '2022-10-16', 12500.00),
        (70, 70, '2023-11-17', 11500.00),
        (71, 71, '2024-12-18', 13000.00),
        (72, 72, '2022-01-19', 12500.00),
        (73, 73, '2023-02-20', 13000.00),
        (74, 74, '2024-03-21', 11000.00);
    SET IDENTITY_INSERT dbo.Employee OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PositionHistorial)
BEGIN
    SET IDENTITY_INSERT dbo.PositionHistorial ON;
    INSERT INTO dbo.PositionHistorial (Id, Employee_Id, Position_Id, Store_Id, WorkArea_Id, FirstDate, LastDate, Salary) VALUES
        (1, 1, 1, NULL, 1, '2025-01-01', NULL, 150000.00),
        (2, 2, 2, NULL, 1, '2024-06-01', NULL, 90000.00),
        (3, 3, 4, NULL, 1, '2025-01-01', NULL, 45000.00),
        (4, 4, 4, NULL, 2, '2024-06-01', NULL, 45000.00),
        (5, 5, 4, NULL, 3, '2025-01-01', NULL, 45000.00),
        (6, 6, 4, NULL, 4, '2024-06-01', NULL, 45000.00),
        (7, 7, 4, NULL, 5, '2025-01-01', NULL, 45000.00),
        (8, 8, 4, NULL, 6, '2024-06-01', NULL, 45000.00),
        (9, 9, 4, NULL, 7, '2025-01-01', NULL, 45000.00),
        (10, 10, 4, NULL, 8, '2024-06-01', NULL, 45000.00),
        (11, 11, 4, NULL, 9, '2025-01-01', NULL, 45000.00),
        (12, 12, 4, NULL, 10, '2024-06-01', NULL, 45000.00),
        (13, 13, 4, NULL, 11, '2025-01-01', NULL, 45000.00),
        (14, 14, 4, NULL, 12, '2024-06-01', NULL, 45000.00),
        (15, 15, 4, NULL, 13, '2025-01-01', NULL, 45000.00),
        (16, 16, 4, NULL, 14, '2024-06-01', NULL, 45000.00),
        (17, 17, 4, NULL, 15, '2025-01-01', NULL, 45000.00),
        (18, 18, 10, 3, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (19, 18, 7, 3, NULL, '2025-01-01', NULL, 21000.00),
        (20, 19, 7, 4, NULL, '2025-01-01', NULL, 21000.00),
        (21, 20, 10, 5, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (22, 20, 7, 5, NULL, '2025-01-01', NULL, 23500.00),
        (23, 21, 7, 6, NULL, '2025-01-01', NULL, 21000.00),
        (24, 22, 10, 7, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (25, 22, 7, 7, NULL, '2025-01-01', NULL, 22000.00),
        (26, 23, 7, 8, NULL, '2025-01-01', NULL, 25000.00),
        (27, 24, 10, 9, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (28, 24, 7, 9, NULL, '2025-01-01', NULL, 25000.00),
        (29, 25, 7, 10, NULL, '2025-01-01', NULL, 23500.00),
        (30, 26, 10, 11, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (31, 26, 7, 11, NULL, '2025-01-01', NULL, 21000.00),
        (32, 27, 7, 12, NULL, '2025-01-01', NULL, 23500.00),
        (33, 28, 10, 13, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (34, 28, 7, 13, NULL, '2025-01-01', NULL, 22000.00),
        (35, 29, 7, 14, NULL, '2025-01-01', NULL, 22000.00),
        (36, 30, 10, 15, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (37, 30, 7, 15, NULL, '2025-01-01', NULL, 22000.00),
        (38, 31, 7, 16, NULL, '2025-01-01', NULL, 22000.00),
        (39, 32, 10, 17, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (40, 32, 7, 17, NULL, '2025-01-01', NULL, 22000.00),
        (41, 33, 7, 18, NULL, '2025-01-01', NULL, 22000.00),
        (42, 34, 10, 19, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (43, 34, 7, 19, NULL, '2025-01-01', NULL, 22000.00),
        (44, 35, 7, 20, NULL, '2025-01-01', NULL, 25000.00),
        (45, 36, 10, 21, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (46, 36, 7, 21, NULL, '2025-01-01', NULL, 22000.00),
        (47, 37, 7, 22, NULL, '2025-01-01', NULL, 21000.00),
        (48, 38, 10, 23, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (49, 38, 7, 23, NULL, '2025-01-01', NULL, 23500.00),
        (50, 39, 7, 24, NULL, '2025-01-01', NULL, 22000.00),
        (51, 40, 10, 25, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (52, 40, 7, 25, NULL, '2025-01-01', NULL, 22000.00),
        (53, 41, 7, 26, NULL, '2025-01-01', NULL, 22000.00),
        (54, 42, 10, 27, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (55, 42, 7, 27, NULL, '2025-01-01', NULL, 23500.00),
        (56, 43, 7, 28, NULL, '2025-01-01', NULL, 25000.00),
        (57, 44, 10, 29, NULL, '2022-03-01', '2024-12-31', 11000.00),
        (58, 44, 7, 29, NULL, '2025-01-01', NULL, 23500.00),
        (59, 45, 7, 30, NULL, '2025-01-01', NULL, 21000.00),
        (60, 46, 10, 3, NULL, '2024-06-01', NULL, 11500.00),
        (61, 47, 10, 4, NULL, '2025-01-01', NULL, 12500.00),
        (62, 48, 10, 5, NULL, '2024-06-01', NULL, 12500.00),
        (63, 49, 10, 6, NULL, '2025-01-01', NULL, 13000.00),
        (64, 50, 10, 7, NULL, '2024-06-01', NULL, 12000.00),
        (65, 51, 10, 8, NULL, '2025-01-01', NULL, 13000.00),
        (66, 52, 10, 9, NULL, '2024-06-01', NULL, 12000.00),
        (67, 53, 10, 10, NULL, '2025-01-01', NULL, 12500.00),
        (68, 54, 10, 11, NULL, '2024-06-01', NULL, 12500.00),
        (69, 55, 10, 12, NULL, '2025-01-01', NULL, 12000.00),
        (70, 56, 10, 13, NULL, '2024-06-01', NULL, 12000.00),
        (71, 57, 10, 14, NULL, '2025-01-01', NULL, 13000.00),
        (72, 58, 10, 15, NULL, '2024-06-01', NULL, 12000.00),
        (73, 59, 10, 16, NULL, '2025-01-01', NULL, 12000.00),
        (74, 60, 10, 17, NULL, '2024-06-01', NULL, 12500.00),
        (75, 61, 10, 18, NULL, '2025-01-01', NULL, 13000.00),
        (76, 62, 10, 19, NULL, '2024-06-01', NULL, 12500.00),
        (77, 63, 10, 20, NULL, '2025-01-01', NULL, 12000.00),
        (78, 64, 10, 21, NULL, '2024-06-01', NULL, 12000.00),
        (79, 65, 10, 22, NULL, '2025-01-01', NULL, 13000.00),
        (80, 66, 10, 23, NULL, '2024-06-01', NULL, 13000.00),
        (81, 67, 10, 24, NULL, '2025-01-01', NULL, 13000.00),
        (82, 68, 10, 25, NULL, '2024-06-01', NULL, 11500.00),
        (83, 69, 10, 26, NULL, '2025-01-01', NULL, 12500.00),
        (84, 70, 10, 27, NULL, '2024-06-01', NULL, 11500.00),
        (85, 71, 10, 28, NULL, '2025-01-01', NULL, 13000.00),
        (86, 72, 10, 29, NULL, '2024-06-01', NULL, 12500.00),
        (87, 73, 10, 30, NULL, '2025-01-01', NULL, 13000.00),
        (88, 74, 12, 1, NULL, '2024-06-01', NULL, 11000.00);
    SET IDENTITY_INSERT dbo.PositionHistorial OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Payroll)
BEGIN
    SET IDENTITY_INSERT dbo.Payroll ON;
    INSERT INTO dbo.Payroll (Id, Employee_Id, Store_Id, PeriodStart, PeriodEnd, GrossAmount, Deductions, PaidDate) VALUES
        (1, 1, 1, '2026-08-01', '2026-08-31', 150000.00, 14250.00, '2026-08-31'),
        (2, 2, 1, '2026-08-01', '2026-08-31', 90000.00, 8550.00, '2026-08-31'),
        (3, 3, 1, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (4, 4, 3, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (5, 5, 5, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (6, 6, 7, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (7, 7, 9, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (8, 8, 11, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (9, 9, 13, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (10, 10, 15, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (11, 11, 17, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (12, 12, 19, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (13, 13, 21, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (14, 14, 23, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (15, 15, 25, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (16, 16, 27, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (17, 17, 29, '2026-08-01', '2026-08-31', 45000.00, 4275.00, '2026-08-31'),
        (18, 18, 3, '2026-08-01', '2026-08-31', 21000.00, 1995.00, '2026-08-31'),
        (19, 19, 4, '2026-08-01', '2026-08-31', 21000.00, 1995.00, '2026-08-31'),
        (20, 20, 5, '2026-08-01', '2026-08-31', 23500.00, 2232.50, '2026-08-31'),
        (21, 21, 6, '2026-08-01', '2026-08-31', 21000.00, 1995.00, '2026-08-31'),
        (22, 22, 7, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (23, 23, 8, '2026-08-01', '2026-08-31', 25000.00, 2375.00, '2026-08-31'),
        (24, 24, 9, '2026-08-01', '2026-08-31', 25000.00, 2375.00, '2026-08-31'),
        (25, 25, 10, '2026-08-01', '2026-08-31', 23500.00, 2232.50, '2026-08-31'),
        (26, 26, 11, '2026-08-01', '2026-08-31', 21000.00, 1995.00, '2026-08-31'),
        (27, 27, 12, '2026-08-01', '2026-08-31', 23500.00, 2232.50, '2026-08-31'),
        (28, 28, 13, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (29, 29, 14, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (30, 30, 15, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (31, 31, 16, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (32, 32, 17, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (33, 33, 18, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (34, 34, 19, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (35, 35, 20, '2026-08-01', '2026-08-31', 25000.00, 2375.00, '2026-08-31'),
        (36, 36, 21, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (37, 37, 22, '2026-08-01', '2026-08-31', 21000.00, 1995.00, '2026-08-31'),
        (38, 38, 23, '2026-08-01', '2026-08-31', 23500.00, 2232.50, '2026-08-31'),
        (39, 39, 24, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (40, 40, 25, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (41, 41, 26, '2026-08-01', '2026-08-31', 22000.00, 2090.00, '2026-08-31'),
        (42, 42, 27, '2026-08-01', '2026-08-31', 23500.00, 2232.50, '2026-08-31'),
        (43, 43, 28, '2026-08-01', '2026-08-31', 25000.00, 2375.00, '2026-08-31'),
        (44, 44, 29, '2026-08-01', '2026-08-31', 23500.00, 2232.50, '2026-08-31'),
        (45, 45, 30, '2026-08-01', '2026-08-31', 21000.00, 1995.00, '2026-08-31'),
        (46, 46, 3, '2026-08-01', '2026-08-31', 11500.00, 1092.50, '2026-08-31'),
        (47, 47, 4, '2026-08-01', '2026-08-31', 12500.00, 1187.50, '2026-08-31'),
        (48, 48, 5, '2026-08-01', '2026-08-31', 12500.00, 1187.50, '2026-08-31'),
        (49, 49, 6, '2026-08-01', '2026-08-31', 13000.00, 1235.00, '2026-08-31'),
        (50, 50, 7, '2026-08-01', '2026-08-31', 12000.00, 1140.00, '2026-08-31'),
        (51, 51, 8, '2026-08-01', '2026-08-31', 13000.00, 1235.00, '2026-08-31'),
        (52, 52, 9, '2026-08-01', '2026-08-31', 12000.00, 1140.00, '2026-08-31'),
        (53, 53, 10, '2026-08-01', '2026-08-31', 12500.00, 1187.50, '2026-08-31'),
        (54, 54, 11, '2026-08-01', '2026-08-31', 12500.00, 1187.50, '2026-08-31'),
        (55, 55, 12, '2026-08-01', '2026-08-31', 12000.00, 1140.00, '2026-08-31'),
        (56, 56, 13, '2026-08-01', '2026-08-31', 12000.00, 1140.00, '2026-08-31'),
        (57, 57, 14, '2026-08-01', '2026-08-31', 13000.00, 1235.00, '2026-08-31'),
        (58, 58, 15, '2026-08-01', '2026-08-31', 12000.00, 1140.00, '2026-08-31'),
        (59, 59, 16, '2026-08-01', '2026-08-31', 12000.00, 1140.00, '2026-08-31'),
        (60, 60, 17, '2026-08-01', '2026-08-31', 12500.00, 1187.50, '2026-08-31'),
        (61, 61, 18, '2026-08-01', '2026-08-31', 13000.00, 1235.00, '2026-08-31'),
        (62, 62, 19, '2026-08-01', '2026-08-31', 12500.00, 1187.50, '2026-08-31'),
        (63, 63, 20, '2026-08-01', '2026-08-31', 12000.00, 1140.00, '2026-08-31'),
        (64, 64, 21, '2026-08-01', '2026-08-31', 12000.00, 1140.00, '2026-08-31'),
        (65, 65, 22, '2026-08-01', '2026-08-31', 13000.00, 1235.00, '2026-08-31'),
        (66, 66, 23, '2026-08-01', '2026-08-31', 13000.00, 1235.00, '2026-08-31'),
        (67, 67, 24, '2026-08-01', '2026-08-31', 13000.00, 1235.00, '2026-08-31'),
        (68, 68, 25, '2026-08-01', '2026-08-31', 11500.00, 1092.50, '2026-08-31'),
        (69, 69, 26, '2026-08-01', '2026-08-31', 12500.00, 1187.50, '2026-08-31'),
        (70, 70, 27, '2026-08-01', '2026-08-31', 11500.00, 1092.50, '2026-08-31'),
        (71, 71, 28, '2026-08-01', '2026-08-31', 13000.00, 1235.00, '2026-08-31'),
        (72, 72, 29, '2026-08-01', '2026-08-31', 12500.00, 1187.50, '2026-08-31'),
        (73, 73, 30, '2026-08-01', '2026-08-31', 13000.00, 1235.00, '2026-08-31'),
        (74, 74, 1, '2026-08-01', '2026-08-31', 11000.00, 1045.00, '2026-08-31'),
        (75, 1, 1, '2026-09-01', '2026-09-30', 150000.00, 14250.00, '2026-09-30'),
        (76, 2, 1, '2026-09-01', '2026-09-30', 90000.00, 8550.00, '2026-09-30'),
        (77, 3, 1, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (78, 4, 3, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (79, 5, 5, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (80, 6, 7, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (81, 7, 9, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (82, 8, 11, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (83, 9, 13, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (84, 10, 15, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (85, 11, 17, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (86, 12, 19, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (87, 13, 21, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (88, 14, 23, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (89, 15, 25, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (90, 16, 27, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (91, 17, 29, '2026-09-01', '2026-09-30', 45000.00, 4275.00, '2026-09-30'),
        (92, 18, 3, '2026-09-01', '2026-09-30', 21000.00, 1995.00, '2026-09-30'),
        (93, 19, 4, '2026-09-01', '2026-09-30', 21000.00, 1995.00, '2026-09-30'),
        (94, 20, 5, '2026-09-01', '2026-09-30', 23500.00, 2232.50, '2026-09-30'),
        (95, 21, 6, '2026-09-01', '2026-09-30', 21000.00, 1995.00, '2026-09-30'),
        (96, 22, 7, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (97, 23, 8, '2026-09-01', '2026-09-30', 25000.00, 2375.00, '2026-09-30'),
        (98, 24, 9, '2026-09-01', '2026-09-30', 25000.00, 2375.00, '2026-09-30'),
        (99, 25, 10, '2026-09-01', '2026-09-30', 23500.00, 2232.50, '2026-09-30'),
        (100, 26, 11, '2026-09-01', '2026-09-30', 21000.00, 1995.00, '2026-09-30'),
        (101, 27, 12, '2026-09-01', '2026-09-30', 23500.00, 2232.50, '2026-09-30'),
        (102, 28, 13, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (103, 29, 14, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (104, 30, 15, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (105, 31, 16, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (106, 32, 17, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (107, 33, 18, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (108, 34, 19, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (109, 35, 20, '2026-09-01', '2026-09-30', 25000.00, 2375.00, '2026-09-30'),
        (110, 36, 21, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (111, 37, 22, '2026-09-01', '2026-09-30', 21000.00, 1995.00, '2026-09-30'),
        (112, 38, 23, '2026-09-01', '2026-09-30', 23500.00, 2232.50, '2026-09-30'),
        (113, 39, 24, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (114, 40, 25, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (115, 41, 26, '2026-09-01', '2026-09-30', 22000.00, 2090.00, '2026-09-30'),
        (116, 42, 27, '2026-09-01', '2026-09-30', 23500.00, 2232.50, '2026-09-30'),
        (117, 43, 28, '2026-09-01', '2026-09-30', 25000.00, 2375.00, '2026-09-30'),
        (118, 44, 29, '2026-09-01', '2026-09-30', 23500.00, 2232.50, '2026-09-30'),
        (119, 45, 30, '2026-09-01', '2026-09-30', 21000.00, 1995.00, '2026-09-30'),
        (120, 46, 3, '2026-09-01', '2026-09-30', 11500.00, 1092.50, '2026-09-30'),
        (121, 47, 4, '2026-09-01', '2026-09-30', 12500.00, 1187.50, '2026-09-30'),
        (122, 48, 5, '2026-09-01', '2026-09-30', 12500.00, 1187.50, '2026-09-30'),
        (123, 49, 6, '2026-09-01', '2026-09-30', 13000.00, 1235.00, '2026-09-30'),
        (124, 50, 7, '2026-09-01', '2026-09-30', 12000.00, 1140.00, '2026-09-30'),
        (125, 51, 8, '2026-09-01', '2026-09-30', 13000.00, 1235.00, '2026-09-30'),
        (126, 52, 9, '2026-09-01', '2026-09-30', 12000.00, 1140.00, '2026-09-30'),
        (127, 53, 10, '2026-09-01', '2026-09-30', 12500.00, 1187.50, '2026-09-30'),
        (128, 54, 11, '2026-09-01', '2026-09-30', 12500.00, 1187.50, '2026-09-30'),
        (129, 55, 12, '2026-09-01', '2026-09-30', 12000.00, 1140.00, '2026-09-30'),
        (130, 56, 13, '2026-09-01', '2026-09-30', 12000.00, 1140.00, '2026-09-30'),
        (131, 57, 14, '2026-09-01', '2026-09-30', 13000.00, 1235.00, '2026-09-30'),
        (132, 58, 15, '2026-09-01', '2026-09-30', 12000.00, 1140.00, '2026-09-30'),
        (133, 59, 16, '2026-09-01', '2026-09-30', 12000.00, 1140.00, '2026-09-30'),
        (134, 60, 17, '2026-09-01', '2026-09-30', 12500.00, 1187.50, '2026-09-30'),
        (135, 61, 18, '2026-09-01', '2026-09-30', 13000.00, 1235.00, '2026-09-30'),
        (136, 62, 19, '2026-09-01', '2026-09-30', 12500.00, 1187.50, '2026-09-30'),
        (137, 63, 20, '2026-09-01', '2026-09-30', 12000.00, 1140.00, '2026-09-30'),
        (138, 64, 21, '2026-09-01', '2026-09-30', 12000.00, 1140.00, '2026-09-30'),
        (139, 65, 22, '2026-09-01', '2026-09-30', 13000.00, 1235.00, '2026-09-30'),
        (140, 66, 23, '2026-09-01', '2026-09-30', 13000.00, 1235.00, '2026-09-30'),
        (141, 67, 24, '2026-09-01', '2026-09-30', 13000.00, 1235.00, '2026-09-30'),
        (142, 68, 25, '2026-09-01', '2026-09-30', 11500.00, 1092.50, '2026-09-30'),
        (143, 69, 26, '2026-09-01', '2026-09-30', 12500.00, 1187.50, '2026-09-30'),
        (144, 70, 27, '2026-09-01', '2026-09-30', 11500.00, 1092.50, '2026-09-30'),
        (145, 71, 28, '2026-09-01', '2026-09-30', 13000.00, 1235.00, '2026-09-30'),
        (146, 72, 29, '2026-09-01', '2026-09-30', 12500.00, 1187.50, '2026-09-30'),
        (147, 73, 30, '2026-09-01', '2026-09-30', 13000.00, 1235.00, '2026-09-30'),
        (148, 74, 1, '2026-09-01', '2026-09-30', 11000.00, 1045.00, '2026-09-30'),
        (149, 1, 1, '2026-10-01', '2026-10-31', 150000.00, 14250.00, '2026-10-31'),
        (150, 2, 1, '2026-10-01', '2026-10-31', 90000.00, 8550.00, '2026-10-31'),
        (151, 3, 1, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (152, 4, 3, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (153, 5, 5, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (154, 6, 7, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (155, 7, 9, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (156, 8, 11, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (157, 9, 13, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (158, 10, 15, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (159, 11, 17, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (160, 12, 19, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (161, 13, 21, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (162, 14, 23, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (163, 15, 25, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (164, 16, 27, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (165, 17, 29, '2026-10-01', '2026-10-31', 45000.00, 4275.00, '2026-10-31'),
        (166, 18, 3, '2026-10-01', '2026-10-31', 21000.00, 1995.00, '2026-10-31'),
        (167, 19, 4, '2026-10-01', '2026-10-31', 21000.00, 1995.00, '2026-10-31'),
        (168, 20, 5, '2026-10-01', '2026-10-31', 23500.00, 2232.50, '2026-10-31'),
        (169, 21, 6, '2026-10-01', '2026-10-31', 21000.00, 1995.00, '2026-10-31'),
        (170, 22, 7, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (171, 23, 8, '2026-10-01', '2026-10-31', 25000.00, 2375.00, '2026-10-31'),
        (172, 24, 9, '2026-10-01', '2026-10-31', 25000.00, 2375.00, '2026-10-31'),
        (173, 25, 10, '2026-10-01', '2026-10-31', 23500.00, 2232.50, '2026-10-31'),
        (174, 26, 11, '2026-10-01', '2026-10-31', 21000.00, 1995.00, '2026-10-31'),
        (175, 27, 12, '2026-10-01', '2026-10-31', 23500.00, 2232.50, '2026-10-31'),
        (176, 28, 13, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (177, 29, 14, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (178, 30, 15, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (179, 31, 16, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (180, 32, 17, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (181, 33, 18, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (182, 34, 19, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (183, 35, 20, '2026-10-01', '2026-10-31', 25000.00, 2375.00, '2026-10-31'),
        (184, 36, 21, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (185, 37, 22, '2026-10-01', '2026-10-31', 21000.00, 1995.00, '2026-10-31'),
        (186, 38, 23, '2026-10-01', '2026-10-31', 23500.00, 2232.50, '2026-10-31'),
        (187, 39, 24, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (188, 40, 25, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (189, 41, 26, '2026-10-01', '2026-10-31', 22000.00, 2090.00, '2026-10-31'),
        (190, 42, 27, '2026-10-01', '2026-10-31', 23500.00, 2232.50, '2026-10-31'),
        (191, 43, 28, '2026-10-01', '2026-10-31', 25000.00, 2375.00, '2026-10-31'),
        (192, 44, 29, '2026-10-01', '2026-10-31', 23500.00, 2232.50, '2026-10-31'),
        (193, 45, 30, '2026-10-01', '2026-10-31', 21000.00, 1995.00, '2026-10-31'),
        (194, 46, 3, '2026-10-01', '2026-10-31', 11500.00, 1092.50, '2026-10-31'),
        (195, 47, 4, '2026-10-01', '2026-10-31', 12500.00, 1187.50, '2026-10-31'),
        (196, 48, 5, '2026-10-01', '2026-10-31', 12500.00, 1187.50, '2026-10-31'),
        (197, 49, 6, '2026-10-01', '2026-10-31', 13000.00, 1235.00, '2026-10-31'),
        (198, 50, 7, '2026-10-01', '2026-10-31', 12000.00, 1140.00, '2026-10-31'),
        (199, 51, 8, '2026-10-01', '2026-10-31', 13000.00, 1235.00, '2026-10-31'),
        (200, 52, 9, '2026-10-01', '2026-10-31', 12000.00, 1140.00, '2026-10-31'),
        (201, 53, 10, '2026-10-01', '2026-10-31', 12500.00, 1187.50, '2026-10-31'),
        (202, 54, 11, '2026-10-01', '2026-10-31', 12500.00, 1187.50, '2026-10-31'),
        (203, 55, 12, '2026-10-01', '2026-10-31', 12000.00, 1140.00, '2026-10-31'),
        (204, 56, 13, '2026-10-01', '2026-10-31', 12000.00, 1140.00, '2026-10-31'),
        (205, 57, 14, '2026-10-01', '2026-10-31', 13000.00, 1235.00, '2026-10-31'),
        (206, 58, 15, '2026-10-01', '2026-10-31', 12000.00, 1140.00, '2026-10-31'),
        (207, 59, 16, '2026-10-01', '2026-10-31', 12000.00, 1140.00, '2026-10-31'),
        (208, 60, 17, '2026-10-01', '2026-10-31', 12500.00, 1187.50, '2026-10-31'),
        (209, 61, 18, '2026-10-01', '2026-10-31', 13000.00, 1235.00, '2026-10-31'),
        (210, 62, 19, '2026-10-01', '2026-10-31', 12500.00, 1187.50, '2026-10-31'),
        (211, 63, 20, '2026-10-01', '2026-10-31', 12000.00, 1140.00, '2026-10-31'),
        (212, 64, 21, '2026-10-01', '2026-10-31', 12000.00, 1140.00, '2026-10-31'),
        (213, 65, 22, '2026-10-01', '2026-10-31', 13000.00, 1235.00, '2026-10-31'),
        (214, 66, 23, '2026-10-01', '2026-10-31', 13000.00, 1235.00, '2026-10-31'),
        (215, 67, 24, '2026-10-01', '2026-10-31', 13000.00, 1235.00, '2026-10-31'),
        (216, 68, 25, '2026-10-01', '2026-10-31', 11500.00, 1092.50, '2026-10-31'),
        (217, 69, 26, '2026-10-01', '2026-10-31', 12500.00, 1187.50, '2026-10-31'),
        (218, 70, 27, '2026-10-01', '2026-10-31', 11500.00, 1092.50, '2026-10-31'),
        (219, 71, 28, '2026-10-01', '2026-10-31', 13000.00, 1235.00, '2026-10-31'),
        (220, 72, 29, '2026-10-01', '2026-10-31', 12500.00, 1187.50, '2026-10-31'),
        (221, 73, 30, '2026-10-01', '2026-10-31', 13000.00, 1235.00, '2026-10-31'),
        (222, 74, 1, '2026-10-01', '2026-10-31', 11000.00, 1045.00, '2026-10-31');
    SET IDENTITY_INSERT dbo.Payroll OFF;
END
GO

-- Gestión de catálogo
IF NOT EXISTS (SELECT 1 FROM dbo.ClotheType)
BEGIN
    SET IDENTITY_INSERT dbo.ClotheType ON;
    INSERT INTO dbo.ClotheType (Id, Name, Description) VALUES
        (1, N'Camisas', N'Prendas de tipo camisas'),
        (2, N'Pantalones', N'Prendas de tipo pantalones'),
        (3, N'Vestidos', N'Prendas de tipo vestidos'),
        (4, N'Chaquetas', N'Prendas de tipo chaquetas'),
        (5, N'Calzado', N'Prendas de tipo calzado'),
        (6, N'Accesorios', N'Prendas de tipo accesorios'),
        (7, N'Faldas', N'Prendas de tipo faldas'),
        (8, N'Shorts', N'Prendas de tipo shorts'),
        (9, N'Sudaderas', N'Prendas de tipo sudaderas'),
        (10, N'Ropa interior', N'Prendas de tipo ropa interior'),
        (11, N'Ropa deportiva', N'Prendas de tipo ropa deportiva'),
        (12, N'Trajes de baño', N'Prendas de tipo trajes de baño'),
        (13, N'Abrigos', N'Prendas de tipo abrigos'),
        (14, N'Bufandas y gorros', N'Prendas de tipo bufandas y gorros'),
        (15, N'Bolsos', N'Prendas de tipo bolsos');
    SET IDENTITY_INSERT dbo.ClotheType OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Clothe)
BEGIN
    SET IDENTITY_INSERT dbo.Clothe ON;
    INSERT INTO dbo.Clothe (Id, Name, ClotheType_Id, Brand, Description, BasePrice, ImageFileId) VALUES
        (1, N'Camisa Oxford', 1, N'Urban Line', N'Camisa Oxford, colección 2026', 420.00, N'SP-MUESTRA-CLOTHE-0001'),
        (2, N'Camisa Lino Manga Larga', 1, N'Urban Line', N'Camisa Lino Manga Larga, colección 2026', 560.00, N'SP-MUESTRA-CLOTHE-0002'),
        (3, N'Camisa Polo Clásica', 1, N'Elegance', N'Camisa Polo Clásica, colección 2026', 380.00, N'SP-MUESTRA-CLOTHE-0003'),
        (4, N'Camisa Estampada', 1, N'Montaña', N'Camisa Estampada, colección 2026', 450.00, N'SP-MUESTRA-CLOTHE-0004'),
        (5, N'Jean Slim Fit', 2, N'Costa Azul', N'Jean Slim Fit, colección 2026', 780.00, N'SP-MUESTRA-CLOTHE-0005'),
        (6, N'Pantalón Chino', 2, N'Elegance', N'Pantalón Chino, colección 2026', 690.00, N'SP-MUESTRA-CLOTHE-0006'),
        (7, N'Jean Recto', 2, N'Montaña', N'Jean Recto, colección 2026', 720.00, N'SP-MUESTRA-CLOTHE-0007'),
        (8, N'Jean Mom Fit', 2, N'Costa Azul', N'Jean Mom Fit, colección 2026', 760.00, N'SP-MUESTRA-CLOTHE-0008'),
        (9, N'Vestido Floral Midi', 3, N'Elegance', N'Vestido Floral Midi, colección 2026', 890.00, N'SP-MUESTRA-CLOTHE-0009'),
        (10, N'Vestido Casual Verano', 3, N'Elegance', N'Vestido Casual Verano, colección 2026', 640.00, N'SP-MUESTRA-CLOTHE-0010'),
        (11, N'Vestido de Fiesta', 3, N'Montaña', N'Vestido de Fiesta, colección 2026', 1450.00, N'SP-MUESTRA-CLOTHE-0011'),
        (12, N'Vestido Largo Negro', 3, N'Elegance', N'Vestido Largo Negro, colección 2026', 1100.00, N'SP-MUESTRA-CLOTHE-0012'),
        (13, N'Chaqueta de Mezclilla', 4, N'Urban Line', N'Chaqueta de Mezclilla, colección 2026', 950.00, N'SP-MUESTRA-CLOTHE-0013'),
        (14, N'Chaqueta Bomber', 4, N'Pedestal', N'Chaqueta Bomber, colección 2026', 1250.00, N'SP-MUESTRA-CLOTHE-0014'),
        (15, N'Chaqueta Cuero Sintético', 4, N'Urban Line', N'Chaqueta Cuero Sintético, colección 2026', 1600.00, N'SP-MUESTRA-CLOTHE-0015'),
        (16, N'Tenis Urbanos', 5, N'Montaña', N'Tenis Urbanos, colección 2026', 1150.00, N'SP-MUESTRA-CLOTHE-0016'),
        (17, N'Zapato Casual Cuero', 5, N'Montaña', N'Zapato Casual Cuero, colección 2026', 1350.00, N'SP-MUESTRA-CLOTHE-0017'),
        (18, N'Sandalias de Playa', 5, N'Pedestal', N'Sandalias de Playa, colección 2026', 420.00, N'SP-MUESTRA-CLOTHE-0018'),
        (19, N'Zapatilla Deportiva', 5, N'Costa Azul', N'Zapatilla Deportiva, colección 2026', 1480.00, N'SP-MUESTRA-CLOTHE-0019'),
        (20, N'Cinturón de Cuero', 6, N'Urban Line', N'Cinturón de Cuero, colección 2026', 320.00, N'SP-MUESTRA-CLOTHE-0020'),
        (21, N'Gafas de Sol', 6, N'Urban Line', N'Gafas de Sol, colección 2026', 560.00, N'SP-MUESTRA-CLOTHE-0021'),
        (22, N'Reloj Casual', 6, N'Elegance', N'Reloj Casual, colección 2026', 980.00, N'SP-MUESTRA-CLOTHE-0022'),
        (23, N'Falda Plisada', 7, N'Montaña', N'Falda Plisada, colección 2026', 540.00, N'SP-MUESTRA-CLOTHE-0023'),
        (24, N'Falda Jean', 7, N'Urban Line', N'Falda Jean, colección 2026', 480.00, N'SP-MUESTRA-CLOTHE-0024'),
        (25, N'Short Deportivo', 8, N'Montaña', N'Short Deportivo, colección 2026', 290.00, N'SP-MUESTRA-CLOTHE-0025'),
        (26, N'Short Bermuda', 8, N'Montaña', N'Short Bermuda, colección 2026', 350.00, N'SP-MUESTRA-CLOTHE-0026'),
        (27, N'Sudadera con Capucha', 9, N'Costa Azul', N'Sudadera con Capucha, colección 2026', 680.00, N'SP-MUESTRA-CLOTHE-0027'),
        (28, N'Sudadera Cuello Redondo', 9, N'Costa Azul', N'Sudadera Cuello Redondo, colección 2026', 590.00, N'SP-MUESTRA-CLOTHE-0028'),
        (29, N'Pack Boxer 3 pzas', 10, N'Pedestal', N'Pack Boxer 3 pzas, colección 2026', 360.00, N'SP-MUESTRA-CLOTHE-0029'),
        (30, N'Pack Medias 5 pares', 10, N'Urban Line', N'Pack Medias 5 pares, colección 2026', 240.00, N'SP-MUESTRA-CLOTHE-0030'),
        (31, N'Licra Deportiva', 11, N'Elegance', N'Licra Deportiva, colección 2026', 430.00, N'SP-MUESTRA-CLOTHE-0031'),
        (32, N'Camiseta Dry Fit', 11, N'Costa Azul', N'Camiseta Dry Fit, colección 2026', 310.00, N'SP-MUESTRA-CLOTHE-0032'),
        (33, N'Traje de Baño Entero', 12, N'Costa Azul', N'Traje de Baño Entero, colección 2026', 520.00, N'SP-MUESTRA-CLOTHE-0033'),
        (34, N'Pantaloneta de Baño', 12, N'Costa Azul', N'Pantaloneta de Baño, colección 2026', 330.00, N'SP-MUESTRA-CLOTHE-0034'),
        (35, N'Abrigo Largo Lana', 13, N'Urban Line', N'Abrigo Largo Lana, colección 2026', 2100.00, N'SP-MUESTRA-CLOTHE-0035'),
        (36, N'Chaleco Acolchado', 13, N'Costa Azul', N'Chaleco Acolchado, colección 2026', 1350.00, N'SP-MUESTRA-CLOTHE-0036'),
        (37, N'Bufanda Tejida', 14, N'Pedestal', N'Bufanda Tejida, colección 2026', 210.00, N'SP-MUESTRA-CLOTHE-0037'),
        (38, N'Gorra Béisbol', 14, N'Costa Azul', N'Gorra Béisbol, colección 2026', 260.00, N'SP-MUESTRA-CLOTHE-0038'),
        (39, N'Mochila Urbana', 15, N'Pedestal', N'Mochila Urbana, colección 2026', 690.00, N'SP-MUESTRA-CLOTHE-0039'),
        (40, N'Bolso de Mano', 15, N'Montaña', N'Bolso de Mano, colección 2026', 820.00, N'SP-MUESTRA-CLOTHE-0040');
    SET IDENTITY_INSERT dbo.Clothe OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Size)
BEGIN
    SET IDENTITY_INSERT dbo.Size ON;
    INSERT INTO dbo.Size (Id, Name, SortOrder) VALUES
        (1, N'XXS', 1),
        (2, N'XS', 2),
        (3, N'S', 3),
        (4, N'M', 4),
        (5, N'L', 5),
        (6, N'XL', 6),
        (7, N'XXL', 7),
        (8, N'3XL', 8),
        (9, N'Única', 9),
        (10, N'28', 10),
        (11, N'30', 11),
        (12, N'32', 12),
        (13, N'34', 13),
        (14, N'36', 14),
        (15, N'38', 15),
        (16, N'40', 16),
        (17, N'42', 17);
    SET IDENTITY_INSERT dbo.Size OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Color)
BEGIN
    SET IDENTITY_INSERT dbo.Color ON;
    INSERT INTO dbo.Color (Id, Name, HexCode) VALUES
        (1, N'Negro', N'#000000'),
        (2, N'Blanco', N'#FFFFFF'),
        (3, N'Gris', N'#808080'),
        (4, N'Azul', N'#1F4E9C'),
        (5, N'Rojo', N'#C62828'),
        (6, N'Verde', N'#2E7D32'),
        (7, N'Beige', N'#D9C7A3'),
        (8, N'Amarillo', N'#F9C80E'),
        (9, N'Naranja', N'#F57C00'),
        (10, N'Morado', N'#6A1B9A'),
        (11, N'Rosado', N'#F48FB1'),
        (12, N'Café', N'#6D4C41'),
        (13, N'Celeste', N'#4FC3F7'),
        (14, N'Turquesa', N'#00ACC1'),
        (15, N'Vino', N'#7B1E3A'),
        (16, N'Mostaza', N'#C9A227');
    SET IDENTITY_INSERT dbo.Color OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ClotheVariant)
BEGIN
    SET IDENTITY_INSERT dbo.ClotheVariant ON;
    INSERT INTO dbo.ClotheVariant (Id, Clothe_Id, Size_Id, Color_Id, Sku, PriceOverride, MinStock) VALUES
        (1, 1, 4, 10, N'PED-001-M-10', NULL, 8),
        (2, 1, 3, 10, N'PED-001-S-10', NULL, 8),
        (3, 1, 6, 10, N'PED-001-XL-10', NULL, 4),
        (4, 1, 5, 10, N'PED-001-L-10', NULL, 8),
        (5, 2, 3, 15, N'PED-002-S-15', NULL, 8),
        (6, 2, 5, 14, N'PED-002-L-14', NULL, 6),
        (7, 2, 3, 14, N'PED-002-S-14', NULL, 5),
        (8, 2, 5, 15, N'PED-002-L-15', NULL, 8),
        (9, 3, 3, 1, N'PED-003-S-01', NULL, 6),
        (10, 3, 6, 1, N'PED-003-XL-01', 418.00, 4),
        (11, 3, 4, 1, N'PED-003-M-01', NULL, 3),
        (12, 3, 3, 8, N'PED-003-S-08', NULL, 4),
        (13, 3, 5, 1, N'PED-003-L-01', NULL, 8),
        (14, 4, 3, 16, N'PED-004-S-16', NULL, 7),
        (15, 4, 3, 15, N'PED-004-S-15', NULL, 8),
        (16, 4, 4, 15, N'PED-004-M-15', 495.00, 3),
        (17, 4, 6, 16, N'PED-004-XL-16', 495.00, 7),
        (18, 5, 15, 4, N'PED-005-38-04', 858.00, 8),
        (19, 5, 15, 8, N'PED-005-38-08', NULL, 7),
        (20, 5, 13, 4, N'PED-005-34-04', NULL, 3),
        (21, 5, 14, 8, N'PED-005-36-08', NULL, 8),
        (22, 5, 11, 4, N'PED-005-30-04', 858.00, 7),
        (23, 6, 10, 7, N'PED-006-28-07', 759.00, 5),
        (24, 6, 13, 16, N'PED-006-34-16', NULL, 5),
        (25, 6, 11, 16, N'PED-006-30-16', NULL, 4),
        (26, 6, 14, 16, N'PED-006-36-16', NULL, 6),
        (27, 7, 10, 9, N'PED-007-28-09', NULL, 5),
        (28, 7, 12, 9, N'PED-007-32-09', NULL, 7),
        (29, 7, 12, 7, N'PED-007-32-07', NULL, 4),
        (30, 7, 11, 9, N'PED-007-30-09', NULL, 3),
        (31, 7, 13, 7, N'PED-007-34-07', NULL, 6),
        (32, 8, 14, 14, N'PED-008-36-14', NULL, 5),
        (33, 8, 10, 14, N'PED-008-28-14', NULL, 7),
        (34, 8, 12, 9, N'PED-008-32-09', NULL, 8),
        (35, 8, 15, 14, N'PED-008-38-14', NULL, 4),
        (36, 9, 5, 15, N'PED-009-L-15', NULL, 3),
        (37, 9, 4, 15, N'PED-009-M-15', NULL, 4),
        (38, 9, 3, 9, N'PED-009-S-09', NULL, 3),
        (39, 9, 3, 15, N'PED-009-S-15', NULL, 7),
        (40, 10, 6, 1, N'PED-010-XL-01', NULL, 6),
        (41, 10, 5, 1, N'PED-010-L-01', NULL, 3),
        (42, 10, 3, 7, N'PED-010-S-07', NULL, 4),
        (43, 10, 3, 1, N'PED-010-S-01', 704.00, 7),
        (44, 11, 3, 7, N'PED-011-S-07', NULL, 6),
        (45, 11, 6, 12, N'PED-011-XL-12', NULL, 7),
        (46, 11, 4, 12, N'PED-011-M-12', 1595.00, 8),
        (47, 11, 6, 7, N'PED-011-XL-07', NULL, 4),
        (48, 12, 4, 3, N'PED-012-M-03', NULL, 6),
        (49, 12, 6, 12, N'PED-012-XL-12', NULL, 7),
        (50, 12, 5, 3, N'PED-012-L-03', 1210.00, 7),
        (51, 12, 4, 12, N'PED-012-M-12', NULL, 8),
        (52, 13, 3, 11, N'PED-013-S-11', NULL, 6),
        (53, 13, 3, 2, N'PED-013-S-02', NULL, 3),
        (54, 13, 4, 2, N'PED-013-M-02', NULL, 5),
        (55, 13, 6, 2, N'PED-013-XL-02', NULL, 8),
        (56, 13, 4, 11, N'PED-013-M-11', NULL, 3),
        (57, 14, 6, 16, N'PED-014-XL-16', NULL, 4),
        (58, 14, 3, 16, N'PED-014-S-16', NULL, 7),
        (59, 14, 4, 5, N'PED-014-M-05', NULL, 7),
        (60, 14, 4, 16, N'PED-014-M-16', NULL, 3),
        (61, 14, 3, 5, N'PED-014-S-05', NULL, 4),
        (62, 15, 4, 12, N'PED-015-M-12', NULL, 7),
        (63, 15, 5, 2, N'PED-015-L-02', NULL, 4),
        (64, 15, 3, 12, N'PED-015-S-12', NULL, 8),
        (65, 15, 6, 2, N'PED-015-XL-02', NULL, 8),
        (66, 16, 17, 14, N'PED-016-42-14', NULL, 8),
        (67, 16, 14, 11, N'PED-016-36-11', NULL, 4),
        (68, 16, 16, 11, N'PED-016-40-11', NULL, 7),
        (69, 16, 16, 14, N'PED-016-40-14', 1265.00, 7),
        (70, 17, 14, 16, N'PED-017-36-16', NULL, 4),
        (71, 17, 15, 12, N'PED-017-38-12', NULL, 8),
        (72, 17, 16, 16, N'PED-017-40-16', NULL, 6),
        (73, 17, 17, 16, N'PED-017-42-16', NULL, 7),
        (74, 18, 17, 12, N'PED-018-42-12', NULL, 4),
        (75, 18, 15, 12, N'PED-018-38-12', NULL, 8),
        (76, 18, 14, 16, N'PED-018-36-16', NULL, 8),
        (77, 18, 16, 16, N'PED-018-40-16', NULL, 8),
        (78, 18, 16, 12, N'PED-018-40-12', NULL, 4),
        (79, 19, 14, 5, N'PED-019-36-05', NULL, 3),
        (80, 19, 17, 7, N'PED-019-42-07', NULL, 6),
        (81, 19, 14, 7, N'PED-019-36-07', NULL, 6),
        (82, 19, 17, 5, N'PED-019-42-05', NULL, 5),
        (83, 19, 15, 5, N'PED-019-38-05', NULL, 6),
        (84, 20, 9, 9, N'PED-020-Única-09', 352.00, 4),
        (85, 20, 9, 13, N'PED-020-Única-13', NULL, 3),
        (86, 21, 9, 5, N'PED-021-Única-05', NULL, 5),
        (87, 21, 9, 14, N'PED-021-Única-14', NULL, 7),
        (88, 22, 9, 8, N'PED-022-Única-08', NULL, 7),
        (89, 22, 9, 5, N'PED-022-Única-05', NULL, 7),
        (90, 23, 6, 8, N'PED-023-XL-08', NULL, 8),
        (91, 23, 4, 10, N'PED-023-M-10', NULL, 7),
        (92, 23, 5, 8, N'PED-023-L-08', 594.00, 5),
        (93, 23, 4, 8, N'PED-023-M-08', NULL, 3),
        (94, 23, 3, 10, N'PED-023-S-10', NULL, 3),
        (95, 24, 6, 9, N'PED-024-XL-09', NULL, 5),
        (96, 24, 4, 5, N'PED-024-M-05', 528.00, 3),
        (97, 24, 3, 9, N'PED-024-S-09', NULL, 3),
        (98, 24, 5, 9, N'PED-024-L-09', NULL, 7),
        (99, 24, 6, 5, N'PED-024-XL-05', NULL, 6),
        (100, 25, 4, 7, N'PED-025-M-07', NULL, 8),
        (101, 25, 3, 1, N'PED-025-S-01', NULL, 7),
        (102, 25, 4, 1, N'PED-025-M-01', NULL, 8),
        (103, 25, 3, 7, N'PED-025-S-07', NULL, 4),
        (104, 25, 6, 7, N'PED-025-XL-07', NULL, 3),
        (105, 26, 4, 11, N'PED-026-M-11', 385.00, 5),
        (106, 26, 3, 16, N'PED-026-S-16', 385.00, 4),
        (107, 26, 4, 16, N'PED-026-M-16', NULL, 6),
        (108, 26, 6, 16, N'PED-026-XL-16', NULL, 8),
        (109, 26, 3, 11, N'PED-026-S-11', NULL, 8),
        (110, 27, 3, 8, N'PED-027-S-08', NULL, 3),
        (111, 27, 6, 8, N'PED-027-XL-08', NULL, 6),
        (112, 27, 4, 8, N'PED-027-M-08', NULL, 4),
        (113, 27, 5, 6, N'PED-027-L-06', NULL, 5),
        (114, 27, 6, 6, N'PED-027-XL-06', 748.00, 7),
        (115, 28, 3, 1, N'PED-028-S-01', NULL, 7),
        (116, 28, 5, 14, N'PED-028-L-14', NULL, 4),
        (117, 28, 4, 14, N'PED-028-M-14', NULL, 4),
        (118, 28, 4, 1, N'PED-028-M-01', NULL, 3),
        (119, 28, 3, 14, N'PED-028-S-14', NULL, 5),
        (120, 29, 6, 6, N'PED-029-XL-06', NULL, 8),
        (121, 29, 3, 7, N'PED-029-S-07', NULL, 7),
        (122, 29, 4, 6, N'PED-029-M-06', NULL, 4),
        (123, 29, 5, 7, N'PED-029-L-07', NULL, 4),
        (124, 30, 4, 14, N'PED-030-M-14', 264.00, 8),
        (125, 30, 5, 14, N'PED-030-L-14', NULL, 4),
        (126, 30, 5, 15, N'PED-030-L-15', NULL, 5),
        (127, 30, 3, 15, N'PED-030-S-15', NULL, 7),
        (128, 31, 4, 12, N'PED-031-M-12', 473.00, 4),
        (129, 31, 3, 7, N'PED-031-S-07', NULL, 4),
        (130, 31, 6, 7, N'PED-031-XL-07', NULL, 7),
        (131, 31, 6, 12, N'PED-031-XL-12', 473.00, 4),
        (132, 32, 3, 8, N'PED-032-S-08', 341.00, 4),
        (133, 32, 4, 10, N'PED-032-M-10', NULL, 3),
        (134, 32, 5, 10, N'PED-032-L-10', NULL, 4),
        (135, 32, 4, 8, N'PED-032-M-08', NULL, 3),
        (136, 33, 6, 14, N'PED-033-XL-14', 572.00, 4),
        (137, 33, 5, 6, N'PED-033-L-06', 572.00, 4),
        (138, 33, 4, 14, N'PED-033-M-14', 572.00, 8),
        (139, 33, 3, 14, N'PED-033-S-14', NULL, 6),
        (140, 33, 3, 6, N'PED-033-S-06', NULL, 6),
        (141, 34, 4, 4, N'PED-034-M-04', NULL, 7),
        (142, 34, 6, 2, N'PED-034-XL-02', NULL, 4),
        (143, 34, 5, 2, N'PED-034-L-02', NULL, 3),
        (144, 34, 4, 2, N'PED-034-M-02', 363.00, 7),
        (145, 35, 3, 3, N'PED-035-S-03', NULL, 5),
        (146, 35, 4, 7, N'PED-035-M-07', NULL, 8),
        (147, 35, 6, 3, N'PED-035-XL-03', NULL, 5),
        (148, 35, 3, 7, N'PED-035-S-07', NULL, 5),
        (149, 36, 5, 16, N'PED-036-L-16', NULL, 3),
        (150, 36, 6, 12, N'PED-036-XL-12', NULL, 8),
        (151, 36, 6, 16, N'PED-036-XL-16', 1485.00, 7),
        (152, 36, 3, 16, N'PED-036-S-16', NULL, 3),
        (153, 36, 4, 12, N'PED-036-M-12', NULL, 3),
        (154, 37, 9, 8, N'PED-037-Única-08', NULL, 6),
        (155, 37, 9, 3, N'PED-037-Única-03', NULL, 4),
        (156, 38, 9, 2, N'PED-038-Única-02', NULL, 6),
        (157, 38, 9, 11, N'PED-038-Única-11', NULL, 6),
        (158, 39, 9, 5, N'PED-039-Única-05', NULL, 3),
        (159, 39, 9, 16, N'PED-039-Única-16', NULL, 7),
        (160, 40, 9, 3, N'PED-040-Única-03', NULL, 3),
        (161, 40, 9, 10, N'PED-040-Única-10', NULL, 6);
    SET IDENTITY_INSERT dbo.ClotheVariant OFF;
END
GO

-- Gestión de almacén
IF NOT EXISTS (SELECT 1 FROM dbo.Rack)
BEGIN
    SET IDENTITY_INSERT dbo.Rack ON;
    INSERT INTO dbo.Rack (Id, Store_Id, RackNumber, Zone, Name, Description) VALUES
        (1, 1, N'R-01', N'WAREHOUSE', N'Bodega 1', N'Bodega 1 de Bodega Central'),
        (2, 1, N'R-02', N'WAREHOUSE', N'Bodega 2', N'Bodega 2 de Bodega Central'),
        (3, 1, N'R-03', N'WAREHOUSE', N'Bodega 3', N'Bodega 3 de Bodega Central'),
        (4, 1, N'R-04', N'WAREHOUSE', N'Bodega 4', N'Bodega 4 de Bodega Central'),
        (5, 2, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Tienda Virtual'),
        (6, 3, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Tegucigalpa Centro'),
        (7, 3, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Tegucigalpa Centro'),
        (8, 4, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Tegucigalpa Palmira'),
        (9, 4, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Tegucigalpa Palmira'),
        (10, 5, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Tegucigalpa Kennedy'),
        (11, 5, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Tegucigalpa Kennedy'),
        (12, 6, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Tegucigalpa El Trapiche'),
        (13, 6, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Tegucigalpa El Trapiche'),
        (14, 7, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal San Pedro Sula Centro'),
        (15, 7, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal San Pedro Sula Centro'),
        (16, 8, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal San Pedro Sula Mall'),
        (17, 8, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal San Pedro Sula Mall'),
        (18, 9, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal La Ceiba Centro'),
        (19, 9, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal La Ceiba Centro'),
        (20, 10, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal La Ceiba Paseo'),
        (21, 10, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal La Ceiba Paseo'),
        (22, 11, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal El Progreso Centro'),
        (23, 11, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal El Progreso Centro'),
        (24, 12, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Yoro Centro'),
        (25, 12, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Yoro Centro'),
        (26, 13, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Juticalpa Centro'),
        (27, 13, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Juticalpa Centro'),
        (28, 14, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Catacamas Centro'),
        (29, 14, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Catacamas Centro'),
        (30, 15, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Choluteca Centro'),
        (31, 15, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Choluteca Centro'),
        (32, 16, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Choluteca Plaza'),
        (33, 16, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Choluteca Plaza'),
        (34, 17, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Comayagua Centro'),
        (35, 17, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Comayagua Centro'),
        (36, 18, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Siguatepeque Centro'),
        (37, 18, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Siguatepeque Centro'),
        (38, 19, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Santa Rosa de Copán Centro'),
        (39, 19, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Santa Rosa de Copán Centro'),
        (40, 20, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Copán Ruinas'),
        (41, 20, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Copán Ruinas'),
        (42, 21, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Danlí Centro'),
        (43, 21, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Danlí Centro'),
        (44, 22, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Danlí Plaza'),
        (45, 22, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Danlí Plaza'),
        (46, 23, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Santa Bárbara Centro'),
        (47, 23, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Santa Bárbara Centro'),
        (48, 24, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Quimistán Centro'),
        (49, 24, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Quimistán Centro'),
        (50, 25, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Gracias Centro'),
        (51, 25, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Gracias Centro'),
        (52, 26, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Gracias Plaza'),
        (53, 26, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Gracias Plaza'),
        (54, 27, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Trujillo Centro'),
        (55, 27, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Trujillo Centro'),
        (56, 28, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Tocoa Centro'),
        (57, 28, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Tocoa Centro'),
        (58, 29, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Roatán Centro'),
        (59, 29, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Roatán Centro'),
        (60, 30, N'R-01', N'WAREHOUSE', N'Bodega', N'Bodega de Pedestal Roatán West End'),
        (61, 30, N'R-02', N'POS', N'Piso de venta', N'Piso de venta de Pedestal Roatán West End');
    SET IDENTITY_INSERT dbo.Rack OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Cubicle)
BEGIN
    SET IDENTITY_INSERT dbo.Cubicle ON;
    INSERT INTO dbo.Cubicle (Id, Rack_Id, CubicleNumber, Name, Description) VALUES
        (1, 1, N'C-01', N'Cubículo 1', NULL),
        (2, 1, N'C-02', N'Cubículo 2', NULL),
        (3, 2, N'C-01', N'Cubículo 1', NULL),
        (4, 2, N'C-02', N'Cubículo 2', NULL),
        (5, 3, N'C-01', N'Cubículo 1', NULL),
        (6, 3, N'C-02', N'Cubículo 2', NULL),
        (7, 4, N'C-01', N'Cubículo 1', NULL),
        (8, 4, N'C-02', N'Cubículo 2', NULL),
        (9, 5, N'C-01', N'Cubículo 1', NULL),
        (10, 5, N'C-02', N'Cubículo 2', NULL),
        (11, 6, N'C-01', N'Cubículo 1', NULL),
        (12, 6, N'C-02', N'Cubículo 2', NULL),
        (13, 7, N'C-01', N'Cubículo 1', NULL),
        (14, 7, N'C-02', N'Cubículo 2', NULL),
        (15, 8, N'C-01', N'Cubículo 1', NULL),
        (16, 8, N'C-02', N'Cubículo 2', NULL),
        (17, 9, N'C-01', N'Cubículo 1', NULL),
        (18, 9, N'C-02', N'Cubículo 2', NULL),
        (19, 10, N'C-01', N'Cubículo 1', NULL),
        (20, 10, N'C-02', N'Cubículo 2', NULL),
        (21, 11, N'C-01', N'Cubículo 1', NULL),
        (22, 11, N'C-02', N'Cubículo 2', NULL),
        (23, 12, N'C-01', N'Cubículo 1', NULL),
        (24, 12, N'C-02', N'Cubículo 2', NULL),
        (25, 13, N'C-01', N'Cubículo 1', NULL),
        (26, 13, N'C-02', N'Cubículo 2', NULL),
        (27, 14, N'C-01', N'Cubículo 1', NULL),
        (28, 14, N'C-02', N'Cubículo 2', NULL),
        (29, 15, N'C-01', N'Cubículo 1', NULL),
        (30, 15, N'C-02', N'Cubículo 2', NULL),
        (31, 16, N'C-01', N'Cubículo 1', NULL),
        (32, 16, N'C-02', N'Cubículo 2', NULL),
        (33, 17, N'C-01', N'Cubículo 1', NULL),
        (34, 17, N'C-02', N'Cubículo 2', NULL),
        (35, 18, N'C-01', N'Cubículo 1', NULL),
        (36, 18, N'C-02', N'Cubículo 2', NULL),
        (37, 19, N'C-01', N'Cubículo 1', NULL),
        (38, 19, N'C-02', N'Cubículo 2', NULL),
        (39, 20, N'C-01', N'Cubículo 1', NULL),
        (40, 20, N'C-02', N'Cubículo 2', NULL),
        (41, 21, N'C-01', N'Cubículo 1', NULL),
        (42, 21, N'C-02', N'Cubículo 2', NULL),
        (43, 22, N'C-01', N'Cubículo 1', NULL),
        (44, 22, N'C-02', N'Cubículo 2', NULL),
        (45, 23, N'C-01', N'Cubículo 1', NULL),
        (46, 23, N'C-02', N'Cubículo 2', NULL),
        (47, 24, N'C-01', N'Cubículo 1', NULL),
        (48, 24, N'C-02', N'Cubículo 2', NULL),
        (49, 25, N'C-01', N'Cubículo 1', NULL),
        (50, 25, N'C-02', N'Cubículo 2', NULL),
        (51, 26, N'C-01', N'Cubículo 1', NULL),
        (52, 26, N'C-02', N'Cubículo 2', NULL),
        (53, 27, N'C-01', N'Cubículo 1', NULL),
        (54, 27, N'C-02', N'Cubículo 2', NULL),
        (55, 28, N'C-01', N'Cubículo 1', NULL),
        (56, 28, N'C-02', N'Cubículo 2', NULL),
        (57, 29, N'C-01', N'Cubículo 1', NULL),
        (58, 29, N'C-02', N'Cubículo 2', NULL),
        (59, 30, N'C-01', N'Cubículo 1', NULL),
        (60, 30, N'C-02', N'Cubículo 2', NULL),
        (61, 31, N'C-01', N'Cubículo 1', NULL),
        (62, 31, N'C-02', N'Cubículo 2', NULL),
        (63, 32, N'C-01', N'Cubículo 1', NULL),
        (64, 32, N'C-02', N'Cubículo 2', NULL),
        (65, 33, N'C-01', N'Cubículo 1', NULL),
        (66, 33, N'C-02', N'Cubículo 2', NULL),
        (67, 34, N'C-01', N'Cubículo 1', NULL),
        (68, 34, N'C-02', N'Cubículo 2', NULL),
        (69, 35, N'C-01', N'Cubículo 1', NULL),
        (70, 35, N'C-02', N'Cubículo 2', NULL),
        (71, 36, N'C-01', N'Cubículo 1', NULL),
        (72, 36, N'C-02', N'Cubículo 2', NULL),
        (73, 37, N'C-01', N'Cubículo 1', NULL),
        (74, 37, N'C-02', N'Cubículo 2', NULL),
        (75, 38, N'C-01', N'Cubículo 1', NULL),
        (76, 38, N'C-02', N'Cubículo 2', NULL),
        (77, 39, N'C-01', N'Cubículo 1', NULL),
        (78, 39, N'C-02', N'Cubículo 2', NULL),
        (79, 40, N'C-01', N'Cubículo 1', NULL),
        (80, 40, N'C-02', N'Cubículo 2', NULL),
        (81, 41, N'C-01', N'Cubículo 1', NULL),
        (82, 41, N'C-02', N'Cubículo 2', NULL),
        (83, 42, N'C-01', N'Cubículo 1', NULL),
        (84, 42, N'C-02', N'Cubículo 2', NULL),
        (85, 43, N'C-01', N'Cubículo 1', NULL),
        (86, 43, N'C-02', N'Cubículo 2', NULL),
        (87, 44, N'C-01', N'Cubículo 1', NULL),
        (88, 44, N'C-02', N'Cubículo 2', NULL),
        (89, 45, N'C-01', N'Cubículo 1', NULL),
        (90, 45, N'C-02', N'Cubículo 2', NULL),
        (91, 46, N'C-01', N'Cubículo 1', NULL),
        (92, 46, N'C-02', N'Cubículo 2', NULL),
        (93, 47, N'C-01', N'Cubículo 1', NULL),
        (94, 47, N'C-02', N'Cubículo 2', NULL),
        (95, 48, N'C-01', N'Cubículo 1', NULL),
        (96, 48, N'C-02', N'Cubículo 2', NULL),
        (97, 49, N'C-01', N'Cubículo 1', NULL),
        (98, 49, N'C-02', N'Cubículo 2', NULL),
        (99, 50, N'C-01', N'Cubículo 1', NULL),
        (100, 50, N'C-02', N'Cubículo 2', NULL),
        (101, 51, N'C-01', N'Cubículo 1', NULL),
        (102, 51, N'C-02', N'Cubículo 2', NULL),
        (103, 52, N'C-01', N'Cubículo 1', NULL),
        (104, 52, N'C-02', N'Cubículo 2', NULL),
        (105, 53, N'C-01', N'Cubículo 1', NULL),
        (106, 53, N'C-02', N'Cubículo 2', NULL),
        (107, 54, N'C-01', N'Cubículo 1', NULL),
        (108, 54, N'C-02', N'Cubículo 2', NULL),
        (109, 55, N'C-01', N'Cubículo 1', NULL),
        (110, 55, N'C-02', N'Cubículo 2', NULL),
        (111, 56, N'C-01', N'Cubículo 1', NULL),
        (112, 56, N'C-02', N'Cubículo 2', NULL),
        (113, 57, N'C-01', N'Cubículo 1', NULL),
        (114, 57, N'C-02', N'Cubículo 2', NULL),
        (115, 58, N'C-01', N'Cubículo 1', NULL),
        (116, 58, N'C-02', N'Cubículo 2', NULL),
        (117, 59, N'C-01', N'Cubículo 1', NULL),
        (118, 59, N'C-02', N'Cubículo 2', NULL),
        (119, 60, N'C-01', N'Cubículo 1', NULL),
        (120, 60, N'C-02', N'Cubículo 2', NULL),
        (121, 61, N'C-01', N'Cubículo 1', NULL),
        (122, 61, N'C-02', N'Cubículo 2', NULL);
    SET IDENTITY_INSERT dbo.Cubicle OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ClothesInCubicle)
BEGIN
    INSERT INTO dbo.ClothesInCubicle (Cubicle_Id, ClotheVariant_Id, Quantity) VALUES
        (5, 140, 23),
        (3, 66, 32),
        (7, 86, 17),
        (7, 130, 25),
        (2, 94, 26),
        (3, 111, 29),
        (1, 10, 16),
        (6, 154, 10),
        (3, 120, 32),
        (5, 20, 5),
        (7, 58, 23),
        (7, 141, 24),
        (2, 33, 5),
        (7, 53, 39),
        (3, 67, 39),
        (1, 44, 11),
        (2, 116, 28),
        (6, 90, 6),
        (4, 51, 31),
        (6, 22, 8),
        (2, 25, 9),
        (7, 62, 29),
        (4, 30, 21),
        (5, 129, 17),
        (7, 150, 13),
        (4, 14, 15),
        (6, 27, 27),
        (5, 6, 35),
        (6, 136, 27),
        (1, 78, 30),
        (5, 7, 27),
        (5, 146, 23),
        (7, 71, 14),
        (4, 69, 14),
        (3, 65, 15),
        (4, 1, 24),
        (6, 132, 18),
        (8, 128, 10),
        (8, 23, 16),
        (5, 47, 17),
        (1, 89, 22),
        (4, 57, 12),
        (1, 98, 9),
        (5, 40, 38),
        (1, 49, 27),
        (1, 151, 40),
        (6, 54, 26),
        (1, 157, 15),
        (4, 114, 15),
        (1, 43, 35),
        (6, 16, 21),
        (7, 73, 4),
        (5, 159, 40),
        (7, 13, 31),
        (1, 50, 36),
        (7, 75, 14),
        (7, 81, 23),
        (7, 127, 19),
        (3, 96, 26),
        (3, 134, 24),
        (6, 160, 15),
        (8, 135, 40),
        (3, 107, 8),
        (5, 42, 31),
        (4, 63, 30),
        (1, 48, 28),
        (5, 11, 18),
        (6, 72, 3),
        (1, 56, 38),
        (7, 39, 4),
        (1, 145, 19),
        (7, 139, 18),
        (2, 35, 14),
        (3, 76, 9),
        (2, 74, 12),
        (8, 5, 34),
        (4, 28, 6),
        (5, 105, 3),
        (1, 45, 5),
        (3, 152, 7),
        (10, 101, 28),
        (9, 140, 27),
        (9, 69, 13),
        (10, 83, 36),
        (9, 136, 36),
        (10, 51, 23),
        (9, 8, 30),
        (10, 112, 38),
        (9, 79, 28),
        (9, 125, 38),
        (9, 63, 4),
        (9, 22, 11),
        (9, 42, 13),
        (10, 29, 34),
        (10, 30, 24),
        (10, 115, 18),
        (10, 124, 11),
        (10, 12, 15),
        (10, 77, 14),
        (10, 46, 37),
        (9, 38, 4),
        (9, 13, 26),
        (10, 10, 4),
        (9, 147, 14),
        (10, 113, 28),
        (10, 55, 32),
        (10, 85, 23),
        (10, 53, 26),
        (9, 54, 16),
        (10, 59, 40),
        (9, 66, 5),
        (9, 86, 36),
        (10, 76, 36),
        (9, 70, 24),
        (10, 98, 29),
        (9, 120, 18),
        (9, 108, 37),
        (9, 154, 40),
        (9, 116, 5),
        (9, 7, 16),
        (10, 126, 6),
        (9, 144, 29),
        (9, 155, 31),
        (9, 143, 36),
        (9, 41, 13),
        (9, 17, 37),
        (9, 4, 19),
        (10, 3, 16),
        (9, 52, 19),
        (9, 84, 7),
        (10, 74, 23),
        (9, 96, 17),
        (9, 48, 28),
        (9, 159, 7),
        (10, 68, 6),
        (10, 130, 28),
        (10, 97, 26),
        (9, 92, 33),
        (10, 156, 15),
        (10, 145, 7),
        (12, 73, 19),
        (11, 45, 6),
        (13, 1, 32),
        (14, 127, 3),
        (14, 38, 26),
        (12, 25, 18),
        (13, 19, 37),
        (12, 130, 18),
        (13, 154, 9),
        (11, 24, 29),
        (12, 161, 23),
        (13, 52, 36),
        (12, 6, 4),
        (13, 160, 22),
        (12, 132, 19),
        (17, 111, 40),
        (18, 22, 37),
        (17, 86, 12),
        (15, 151, 32),
        (18, 89, 35),
        (17, 59, 9),
        (16, 140, 10),
        (15, 93, 5),
        (15, 119, 30),
        (18, 38, 33),
        (15, 98, 25),
        (17, 92, 5),
        (15, 60, 26),
        (17, 45, 35),
        (16, 91, 4),
        (22, 125, 26),
        (19, 42, 15),
        (22, 76, 30),
        (22, 61, 36),
        (22, 14, 3),
        (19, 6, 18),
        (21, 52, 28),
        (22, 118, 10),
        (19, 18, 38),
        (22, 51, 25),
        (21, 90, 18),
        (20, 134, 6),
        (22, 132, 35),
        (20, 12, 4),
        (22, 156, 33),
        (24, 105, 4),
        (24, 75, 9),
        (23, 34, 37),
        (23, 125, 5),
        (24, 8, 6),
        (23, 143, 29),
        (25, 128, 25),
        (25, 145, 9),
        (25, 122, 6),
        (24, 47, 26),
        (24, 144, 26),
        (25, 77, 40),
        (25, 33, 28),
        (23, 76, 36),
        (24, 41, 12),
        (29, 15, 11),
        (28, 109, 24),
        (27, 20, 7),
        (28, 87, 8),
        (30, 148, 25),
        (27, 119, 16),
        (29, 117, 25),
        (27, 77, 23),
        (29, 62, 26),
        (27, 91, 8),
        (27, 46, 33),
        (30, 113, 29),
        (29, 129, 24),
        (30, 42, 17),
        (27, 106, 28),
        (33, 114, 3),
        (31, 74, 36),
        (32, 152, 4),
        (33, 50, 20),
        (33, 56, 33),
        (33, 1, 24),
        (34, 96, 19),
        (33, 40, 37),
        (34, 112, 19),
        (32, 26, 6),
        (32, 39, 35),
        (34, 82, 38),
        (34, 99, 10),
        (32, 20, 7),
        (33, 108, 21),
        (38, 155, 18),
        (38, 111, 33),
        (35, 48, 19),
        (36, 112, 9),
        (36, 4, 18),
        (36, 144, 19),
        (37, 16, 4),
        (36, 147, 12),
        (35, 104, 25),
        (36, 127, 35),
        (35, 6, 40),
        (37, 108, 31),
        (38, 28, 14),
        (35, 88, 7),
        (37, 146, 13),
        (41, 130, 25),
        (42, 83, 24),
        (41, 92, 4),
        (42, 95, 40),
        (39, 33, 26),
        (41, 139, 20),
        (42, 55, 21),
        (40, 118, 6),
        (39, 2, 33),
        (39, 63, 36),
        (41, 81, 5),
        (42, 158, 30),
        (42, 34, 23),
        (41, 141, 36),
        (41, 21, 24),
        (45, 151, 9),
        (46, 91, 12),
        (45, 107, 7),
        (45, 154, 32),
        (44, 28, 36),
        (45, 146, 17),
        (44, 104, 17),
        (46, 2, 13),
        (43, 118, 34),
        (45, 94, 17),
        (43, 82, 8),
        (45, 7, 40),
        (45, 152, 14),
        (44, 143, 21),
        (45, 139, 16),
        (48, 96, 20),
        (48, 155, 35),
        (47, 104, 20),
        (49, 119, 20),
        (50, 83, 10),
        (49, 74, 15),
        (49, 14, 10),
        (47, 87, 38),
        (48, 73, 38),
        (49, 129, 31),
        (48, 62, 39),
        (49, 38, 4),
        (50, 67, 37),
        (48, 147, 18),
        (49, 135, 39),
        (53, 151, 17),
        (52, 39, 7),
        (51, 11, 37),
        (54, 111, 32),
        (52, 41, 17),
        (54, 5, 20),
        (54, 102, 20),
        (53, 99, 30),
        (54, 8, 9),
        (54, 49, 9),
        (52, 138, 20),
        (52, 132, 21),
        (52, 13, 18),
        (52, 23, 24),
        (51, 51, 8),
        (58, 105, 12),
        (57, 111, 9),
        (56, 145, 14),
        (56, 161, 8),
        (55, 90, 14),
        (55, 94, 9),
        (55, 89, 17),
        (58, 60, 9),
        (57, 92, 23),
        (58, 80, 28),
        (56, 126, 14),
        (56, 88, 22),
        (58, 136, 29),
        (57, 152, 14),
        (58, 67, 3),
        (60, 51, 11),
        (62, 116, 33),
        (59, 161, 34),
        (61, 76, 17),
        (62, 73, 29),
        (61, 152, 17),
        (62, 129, 34),
        (60, 106, 21),
        (62, 99, 26),
        (59, 108, 26),
        (60, 17, 31),
        (61, 136, 16),
        (60, 107, 31),
        (60, 133, 30),
        (59, 131, 21),
        (63, 32, 28),
        (63, 77, 30),
        (65, 136, 15),
        (64, 155, 3),
        (63, 90, 14),
        (66, 48, 25),
        (65, 87, 17),
        (64, 144, 15),
        (66, 142, 8),
        (66, 28, 37),
        (65, 19, 28),
        (64, 131, 3),
        (66, 86, 37),
        (63, 58, 25),
        (63, 80, 5),
        (67, 98, 28),
        (70, 74, 31),
        (67, 30, 38),
        (69, 123, 38),
        (68, 159, 14),
        (70, 100, 18),
        (69, 17, 37),
        (68, 92, 8),
        (69, 36, 40),
        (67, 31, 22),
        (70, 94, 4),
        (70, 22, 29),
        (70, 157, 8),
        (69, 56, 6),
        (67, 3, 36),
        (72, 122, 40),
        (72, 142, 26),
        (74, 8, 39),
        (71, 141, 5),
        (72, 35, 15),
        (71, 143, 17),
        (74, 118, 38),
        (74, 10, 39),
        (74, 72, 8),
        (74, 25, 37),
        (71, 52, 9),
        (73, 80, 16),
        (72, 54, 15),
        (72, 29, 5),
        (71, 3, 33),
        (78, 79, 38),
        (78, 132, 29),
        (75, 54, 21),
        (78, 80, 26),
        (77, 84, 39),
        (77, 56, 14),
        (75, 83, 3),
        (78, 62, 3),
        (78, 98, 15),
        (78, 142, 39),
        (77, 124, 4),
        (75, 71, 6),
        (78, 46, 21),
        (77, 43, 40),
        (77, 127, 23),
        (82, 46, 33),
        (80, 47, 17),
        (80, 42, 4),
        (82, 111, 20),
        (82, 20, 6);
    INSERT INTO dbo.ClothesInCubicle (Cubicle_Id, ClotheVariant_Id, Quantity) VALUES
        (82, 59, 25),
        (80, 130, 19),
        (80, 112, 4),
        (81, 131, 14),
        (82, 63, 38),
        (82, 9, 9),
        (79, 57, 18),
        (79, 133, 21),
        (79, 153, 11),
        (80, 135, 3),
        (86, 55, 22),
        (84, 19, 4),
        (86, 145, 18),
        (85, 46, 4),
        (84, 155, 9),
        (83, 1, 24),
        (86, 108, 21),
        (86, 87, 17),
        (86, 159, 36),
        (84, 57, 35),
        (86, 154, 16),
        (85, 119, 14),
        (84, 41, 26),
        (86, 77, 25),
        (84, 44, 29),
        (89, 63, 28),
        (87, 127, 11),
        (87, 10, 37),
        (90, 48, 32),
        (90, 9, 3),
        (87, 93, 31),
        (88, 27, 29),
        (90, 89, 27),
        (88, 57, 19),
        (87, 142, 16),
        (87, 94, 6),
        (90, 79, 18),
        (89, 47, 25),
        (90, 38, 7),
        (90, 109, 23),
        (92, 107, 21),
        (92, 81, 30),
        (91, 126, 20),
        (94, 93, 30),
        (92, 10, 6),
        (94, 159, 36),
        (93, 129, 7),
        (94, 64, 17),
        (93, 131, 32),
        (92, 58, 7),
        (91, 48, 23),
        (92, 47, 19),
        (92, 113, 40),
        (94, 137, 7),
        (94, 63, 17),
        (96, 45, 32),
        (97, 123, 11),
        (96, 124, 10),
        (96, 47, 13),
        (96, 117, 27),
        (96, 133, 5),
        (97, 15, 13),
        (96, 129, 21),
        (98, 10, 25),
        (95, 130, 31),
        (95, 161, 34),
        (98, 3, 6),
        (97, 108, 4),
        (98, 61, 15),
        (95, 99, 37),
        (99, 119, 14),
        (100, 26, 18),
        (100, 142, 35),
        (101, 89, 35),
        (99, 47, 37),
        (99, 77, 33),
        (99, 138, 14),
        (99, 76, 8),
        (99, 32, 36),
        (102, 82, 32),
        (101, 87, 18),
        (100, 118, 33),
        (102, 63, 12),
        (101, 156, 9),
        (100, 67, 35),
        (103, 58, 40),
        (104, 51, 26),
        (104, 10, 9),
        (104, 92, 16),
        (104, 72, 11),
        (106, 127, 24),
        (106, 151, 16),
        (104, 156, 18),
        (103, 11, 31),
        (105, 87, 32),
        (106, 102, 10),
        (105, 110, 40),
        (106, 116, 32),
        (106, 1, 10),
        (104, 12, 12),
        (108, 42, 23),
        (109, 77, 18),
        (107, 7, 6),
        (109, 38, 20),
        (108, 61, 14),
        (108, 19, 27),
        (110, 9, 38),
        (108, 60, 40),
        (107, 128, 14),
        (107, 40, 40),
        (107, 45, 31),
        (108, 29, 16),
        (107, 39, 29),
        (109, 36, 34),
        (110, 142, 17),
        (112, 133, 18),
        (113, 134, 13),
        (113, 22, 38),
        (111, 65, 8),
        (114, 73, 21),
        (113, 42, 21),
        (114, 106, 19),
        (112, 89, 4),
        (111, 154, 10),
        (113, 127, 10),
        (113, 87, 27),
        (113, 90, 6),
        (113, 80, 36),
        (112, 35, 4),
        (113, 160, 26),
        (116, 19, 38),
        (117, 109, 18),
        (115, 15, 11),
        (118, 138, 36),
        (115, 130, 30),
        (118, 18, 17),
        (117, 145, 40),
        (118, 144, 8),
        (115, 10, 9),
        (116, 13, 27),
        (115, 101, 30),
        (118, 42, 37),
        (118, 67, 33),
        (118, 64, 6),
        (116, 77, 4),
        (119, 99, 29),
        (121, 30, 35),
        (121, 109, 19),
        (121, 12, 16),
        (120, 105, 26),
        (121, 106, 14),
        (122, 123, 9),
        (121, 21, 15),
        (121, 48, 21),
        (122, 18, 17),
        (119, 126, 24),
        (121, 93, 38),
        (120, 14, 30),
        (121, 47, 20),
        (122, 102, 18);
END
GO

-- Gestión de compras
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrder)
BEGIN
    SET IDENTITY_INSERT dbo.PurchaseOrder ON;
    INSERT INTO dbo.PurchaseOrder (Id, OrderNumber, Supplier_Id, Store_Id, Employee_Id, OrderDate, ReceivedDate, Status, Total, Notes, RegistrationDate) VALUES
        (1, N'OC-2026-0001', 4, 1, 74, '2026-09-06', '2026-09-09', N'RECEIVED', 60809.40, NULL, '2026-09-06T09:00:00'),
        (2, N'OC-2026-0002', 11, 1, 74, '2026-11-04', '2026-11-14', N'RECEIVED', 7984.00, NULL, '2026-11-04T09:00:00'),
        (3, N'OC-2026-0003', 10, 1, 74, '2026-07-10', '2026-07-13', N'RECEIVED', 49201.00, NULL, '2026-07-10T09:00:00'),
        (4, N'OC-2026-0004', 8, 1, 74, '2026-09-03', '2026-09-06', N'RECEIVED', 93396.00, NULL, '2026-09-03T09:00:00'),
        (5, N'OC-2026-0005', 16, 3, 18, '2026-08-19', '2026-08-26', N'RECEIVED', 47113.10, NULL, '2026-08-19T09:00:00'),
        (6, N'OC-2026-0006', 15, 4, 19, '2026-08-27', NULL, N'DRAFT', 54329.00, NULL, '2026-08-27T09:00:00'),
        (7, N'OC-2026-0007', 9, 5, 20, '2026-07-13', '2026-07-22', N'RECEIVED', 36631.80, NULL, '2026-07-13T09:00:00'),
        (8, N'OC-2026-0008', 12, 6, 21, '2026-08-29', NULL, N'DRAFT', 85525.70, NULL, '2026-08-29T09:00:00'),
        (9, N'OC-2026-0009', 6, 7, 22, '2026-09-26', '2026-10-02', N'RECEIVED', 49536.00, NULL, '2026-09-26T09:00:00'),
        (10, N'OC-2026-0010', 14, 8, 23, '2026-10-11', '2026-10-17', N'RECEIVED', 24708.00, NULL, '2026-10-11T09:00:00'),
        (11, N'OC-2026-0011', 5, 9, 24, '2026-08-07', '2026-08-10', N'RECEIVED', 14613.15, NULL, '2026-08-07T09:00:00'),
        (12, N'OC-2026-0012', 10, 10, 25, '2026-06-17', '2026-06-21', N'RECEIVED', 30269.00, NULL, '2026-06-17T09:00:00'),
        (13, N'OC-2026-0013', 1, 11, 26, '2026-06-20', '2026-06-23', N'RECEIVED', 26390.00, NULL, '2026-06-20T09:00:00'),
        (14, N'OC-2026-0014', 14, 12, 27, '2026-07-24', '2026-07-27', N'RECEIVED', 82890.00, NULL, '2026-07-24T09:00:00'),
        (15, N'OC-2026-0015', 11, 13, 28, '2026-06-06', '2026-06-12', N'RECEIVED', 68345.80, NULL, '2026-06-06T09:00:00'),
        (16, N'OC-2026-0016', 14, 14, 29, '2026-10-20', '2026-10-24', N'RECEIVED', 37956.00, NULL, '2026-10-20T09:00:00'),
        (17, N'OC-2026-0017', 1, 15, 30, '2026-10-05', '2026-10-08', N'RECEIVED', 63310.60, NULL, '2026-10-05T09:00:00'),
        (18, N'OC-2026-0018', 13, 16, 31, '2026-07-08', NULL, N'SENT', 64416.00, NULL, '2026-07-08T09:00:00'),
        (19, N'OC-2026-0019', 12, 17, 32, '2026-07-04', '2026-07-09', N'RECEIVED', 15008.40, NULL, '2026-07-04T09:00:00'),
        (20, N'OC-2026-0020', 18, 18, 33, '2026-11-03', NULL, N'DRAFT', 44555.50, NULL, '2026-11-03T09:00:00'),
        (21, N'OC-2026-0021', 1, 19, 34, '2026-09-27', '2026-09-30', N'RECEIVED', 99554.95, NULL, '2026-09-27T09:00:00'),
        (22, N'OC-2026-0022', 7, 20, 35, '2026-06-27', '2026-07-04', N'RECEIVED', 73694.40, NULL, '2026-06-27T09:00:00'),
        (23, N'OC-2026-0023', 18, 21, 36, '2026-09-19', '2026-09-22', N'RECEIVED', 51996.00, NULL, '2026-09-19T09:00:00'),
        (24, N'OC-2026-0024', 16, 22, 37, '2026-10-11', '2026-10-17', N'RECEIVED', 32500.00, NULL, '2026-10-11T09:00:00'),
        (25, N'OC-2026-0025', 11, 23, 38, '2026-10-07', '2026-10-17', N'RECEIVED', 47809.70, NULL, '2026-10-07T09:00:00'),
        (26, N'OC-2026-0026', 17, 24, 39, '2026-07-09', NULL, N'SENT', 34223.00, NULL, '2026-07-09T09:00:00'),
        (27, N'OC-2026-0027', 8, 25, 40, '2026-10-21', '2026-10-30', N'RECEIVED', 109516.50, NULL, '2026-10-21T09:00:00'),
        (28, N'OC-2026-0028', 10, 26, 41, '2026-10-16', '2026-10-25', N'RECEIVED', 87409.50, NULL, '2026-10-16T09:00:00'),
        (29, N'OC-2026-0029', 18, 27, 42, '2026-08-28', '2026-08-31', N'RECEIVED', 41068.50, NULL, '2026-08-28T09:00:00'),
        (30, N'OC-2026-0030', 7, 28, 43, '2026-08-30', '2026-09-02', N'RECEIVED', 58765.00, NULL, '2026-08-30T09:00:00'),
        (31, N'OC-2026-0031', 15, 29, 44, '2026-06-18', '2026-06-25', N'RECEIVED', 33626.00, NULL, '2026-06-18T09:00:00'),
        (32, N'OC-2026-0032', 14, 30, 45, '2026-07-01', '2026-07-10', N'RECEIVED', 24469.80, NULL, '2026-07-01T09:00:00'),
        (33, N'OC-2026-0033', 6, 3, 18, '2026-06-26', NULL, N'CANCELLED', 40852.50, NULL, '2026-06-26T09:00:00'),
        (34, N'OC-2026-0034', 16, 4, 19, '2026-09-28', '2026-10-08', N'RECEIVED', 76389.00, NULL, '2026-09-28T09:00:00'),
        (35, N'OC-2026-0035', 2, 5, 20, '2026-08-12', '2026-08-19', N'RECEIVED', 18038.00, NULL, '2026-08-12T09:00:00'),
        (36, N'OC-2026-0036', 10, 6, 21, '2026-06-15', '2026-06-18', N'RECEIVED', 18702.00, NULL, '2026-06-15T09:00:00'),
        (37, N'OC-2026-0037', 15, 7, 22, '2026-08-21', '2026-08-27', N'RECEIVED', 52074.00, NULL, '2026-08-21T09:00:00'),
        (38, N'OC-2026-0038', 7, 8, 23, '2026-08-23', NULL, N'SENT', 21677.00, NULL, '2026-08-23T09:00:00'),
        (39, N'OC-2026-0039', 6, 9, 24, '2026-08-10', '2026-08-15', N'RECEIVED', 19745.00, NULL, '2026-08-10T09:00:00'),
        (40, N'OC-2026-0040', 10, 10, 25, '2026-09-17', '2026-09-22', N'RECEIVED', 39694.50, NULL, '2026-09-17T09:00:00'),
        (41, N'OC-2026-0041', 11, 11, 26, '2026-09-16', '2026-09-19', N'RECEIVED', 26552.50, NULL, '2026-09-16T09:00:00'),
        (42, N'OC-2026-0042', 7, 12, 27, '2026-07-30', NULL, N'SENT', 67900.00, NULL, '2026-07-30T09:00:00'),
        (43, N'OC-2026-0043', 12, 13, 28, '2026-08-29', '2026-09-04', N'RECEIVED', 45887.60, NULL, '2026-08-29T09:00:00'),
        (44, N'OC-2026-0044', 14, 14, 29, '2026-09-21', '2026-10-01', N'RECEIVED', 104120.20, NULL, '2026-09-21T09:00:00'),
        (45, N'OC-2026-0045', 18, 15, 30, '2026-10-05', '2026-10-13', N'RECEIVED', 20304.00, NULL, '2026-10-05T09:00:00'),
        (46, N'OC-2026-0046', 6, 16, 31, '2026-10-15', '2026-10-19', N'RECEIVED', 56382.00, NULL, '2026-10-15T09:00:00'),
        (47, N'OC-2026-0047', 6, 17, 32, '2026-08-10', '2026-08-14', N'RECEIVED', 58761.00, NULL, '2026-08-10T09:00:00'),
        (48, N'OC-2026-0048', 18, 18, 33, '2026-06-08', '2026-06-16', N'RECEIVED', 40751.30, NULL, '2026-06-08T09:00:00'),
        (49, N'OC-2026-0049', 4, 19, 34, '2026-08-17', '2026-08-21', N'RECEIVED', 70086.00, NULL, '2026-08-17T09:00:00'),
        (50, N'OC-2026-0050', 10, 20, 35, '2026-07-05', '2026-07-08', N'RECEIVED', 47472.00, NULL, '2026-07-05T09:00:00'),
        (51, N'OC-2026-0051', 14, 21, 36, '2026-08-06', '2026-08-09', N'RECEIVED', 66048.00, NULL, '2026-08-06T09:00:00'),
        (52, N'OC-2026-0052', 6, 22, 37, '2026-08-04', NULL, N'DRAFT', 25253.00, NULL, '2026-08-04T09:00:00'),
        (53, N'OC-2026-0053', 1, 23, 38, '2026-11-01', '2026-11-07', N'RECEIVED', 77866.10, NULL, '2026-11-01T09:00:00'),
        (54, N'OC-2026-0054', 2, 24, 39, '2026-08-23', '2026-09-02', N'RECEIVED', 15904.50, NULL, '2026-08-23T09:00:00'),
        (55, N'OC-2026-0055', 1, 25, 40, '2026-07-01', '2026-07-06', N'RECEIVED', 71442.00, NULL, '2026-07-01T09:00:00'),
        (56, N'OC-2026-0056', 17, 26, 41, '2026-07-12', NULL, N'DRAFT', 35657.70, NULL, '2026-07-12T09:00:00'),
        (57, N'OC-2026-0057', 5, 27, 42, '2026-06-08', '2026-06-14', N'RECEIVED', 65361.50, NULL, '2026-06-08T09:00:00'),
        (58, N'OC-2026-0058', 6, 28, 43, '2026-06-27', NULL, N'DRAFT', 73180.00, NULL, '2026-06-27T09:00:00'),
        (59, N'OC-2026-0059', 11, 29, 44, '2026-08-25', '2026-08-30', N'RECEIVED', 27546.00, NULL, '2026-08-25T09:00:00'),
        (60, N'OC-2026-0060', 4, 30, 45, '2026-06-28', '2026-07-02', N'RECEIVED', 20652.00, NULL, '2026-06-28T09:00:00');
    SET IDENTITY_INSERT dbo.PurchaseOrder OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderDetail)
BEGIN
    SET IDENTITY_INSERT dbo.PurchaseOrderDetail ON;
    INSERT INTO dbo.PurchaseOrderDetail (Id, PurchaseOrder_Id, ClotheVariant_Id, Quantity, UnitCost) VALUES
        (1, 1, 53, 42, 617.50),
        (2, 1, 50, 38, 726.00),
        (3, 1, 96, 23, 316.80),
        (4, 2, 1, 23, 273.00),
        (5, 2, 135, 10, 170.50),
        (6, 3, 105, 20, 211.75),
        (7, 3, 74, 12, 273.00),
        (8, 3, 86, 22, 308.00),
        (9, 3, 69, 46, 759.00),
        (10, 4, 28, 24, 468.00),
        (11, 4, 30, 22, 432.00),
        (12, 4, 65, 45, 880.00),
        (13, 4, 54, 58, 570.00),
        (14, 5, 38, 55, 489.50),
        (15, 5, 132, 12, 187.55),
        (16, 5, 25, 40, 448.50),
        (17, 6, 151, 26, 816.75),
        (18, 6, 60, 13, 687.50),
        (19, 6, 119, 40, 354.00),
        (20, 6, 89, 17, 588.00),
        (21, 7, 90, 58, 324.00),
        (22, 7, 51, 23, 660.00),
        (23, 7, 132, 12, 221.65),
        (24, 8, 128, 26, 307.45),
        (25, 8, 75, 58, 231.00),
        (26, 8, 76, 59, 231.00),
        (27, 8, 145, 37, 1365.00),
        (28, 9, 46, 34, 957.00),
        (29, 9, 129, 16, 258.00),
        (30, 9, 15, 44, 292.50),
        (31, 10, 82, 27, 814.00),
        (32, 10, 74, 10, 273.00),
        (33, 11, 127, 54, 156.00),
        (34, 11, 144, 31, 199.65),
        (35, 12, 34, 32, 418.00),
        (36, 12, 55, 18, 522.50),
        (37, 12, 95, 24, 312.00),
        (38, 13, 7, 56, 364.00),
        (39, 13, 2, 26, 231.00),
        (40, 14, 83, 45, 962.00),
        (41, 14, 62, 45, 880.00),
        (42, 15, 5, 38, 364.00),
        (43, 15, 138, 11, 371.80),
        (44, 15, 111, 33, 408.00),
        (45, 15, 49, 56, 660.00),
        (46, 16, 145, 23, 1260.00),
        (47, 16, 90, 24, 297.00),
        (48, 16, 126, 14, 132.00),
        (49, 17, 133, 15, 170.50),
        (50, 17, 106, 26, 250.25),
        (51, 17, 131, 57, 283.80),
        (52, 17, 152, 47, 810.00),
        (53, 18, 48, 60, 715.00),
        (54, 18, 28, 22, 432.00),
        (55, 18, 77, 52, 231.00),
        (56, 19, 92, 31, 356.40),
        (57, 19, 98, 15, 264.00),
        (58, 20, 141, 60, 214.50),
        (59, 20, 25, 51, 379.50),
        (60, 20, 118, 38, 324.50),
        (61, 21, 80, 27, 888.00),
        (62, 21, 62, 55, 960.00),
        (63, 21, 98, 46, 288.00),
        (64, 21, 132, 43, 221.65),
        (65, 22, 47, 50, 942.50),
        (66, 22, 63, 26, 880.00),
        (67, 22, 131, 13, 283.80),
        (68, 23, 1, 15, 252.00),
        (69, 23, 145, 14, 1260.00),
        (70, 23, 159, 32, 448.50),
        (71, 23, 19, 32, 507.00),
        (72, 24, 63, 26, 880.00),
        (73, 24, 79, 10, 962.00),
        (74, 25, 48, 32, 605.00),
        (75, 25, 131, 38, 260.15),
        (76, 25, 113, 42, 442.00),
        (77, 26, 124, 15, 145.20),
        (78, 26, 45, 34, 942.50),
        (79, 27, 26, 39, 414.00),
        (80, 27, 47, 33, 942.50),
        (81, 27, 89, 47, 588.00),
        (82, 27, 82, 39, 888.00),
        (83, 28, 127, 19, 144.00),
        (84, 28, 151, 24, 816.75),
        (85, 28, 72, 53, 877.50),
        (86, 28, 87, 51, 364.00),
        (87, 29, 128, 55, 283.80),
        (88, 29, 38, 42, 489.50),
        (89, 29, 142, 27, 181.50),
        (90, 30, 65, 56, 960.00),
        (91, 30, 106, 20, 250.25),
        (92, 31, 10, 25, 229.90),
        (93, 31, 130, 33, 279.50),
        (94, 31, 138, 35, 314.60),
        (95, 31, 77, 28, 273.00),
        (96, 32, 21, 16, 468.00),
        (97, 32, 105, 49, 231.00),
        (98, 32, 18, 11, 514.80),
        (99, 33, 127, 13, 144.00),
        (100, 33, 25, 57, 448.50),
        (101, 33, 130, 48, 279.50),
        (102, 34, 140, 48, 286.00),
        (103, 34, 151, 33, 891.00),
        (104, 34, 93, 57, 324.00),
        (105, 34, 45, 17, 870.00),
        (106, 35, 51, 14, 605.00),
        (107, 35, 125, 39, 144.00),
        (108, 35, 12, 16, 247.00),
        (109, 36, 145, 10, 1260.00),
        (110, 36, 143, 12, 214.50),
        (111, 36, 75, 14, 252.00),
        (112, 37, 15, 40, 292.50),
        (113, 37, 77, 42, 231.00),
        (114, 37, 91, 51, 351.00),
        (115, 37, 129, 54, 236.50),
        (116, 38, 40, 46, 416.00),
        (117, 38, 1, 11, 231.00),
        (118, 39, 108, 10, 192.50),
        (119, 39, 48, 27, 660.00),
        (120, 40, 158, 46, 414.00),
        (121, 40, 141, 49, 214.50),
        (122, 40, 139, 30, 338.00),
        (123, 41, 28, 30, 468.00),
        (124, 41, 107, 55, 227.50),
        (125, 42, 67, 52, 632.50),
        (126, 42, 83, 25, 888.00),
        (127, 42, 155, 43, 126.00),
        (128, 42, 74, 32, 231.00),
        (129, 43, 132, 24, 221.65),
        (130, 43, 8, 41, 308.00),
        (131, 43, 5, 35, 308.00),
        (132, 43, 51, 24, 715.00),
        (133, 44, 161, 46, 451.00),
        (134, 44, 92, 26, 326.70),
        (135, 44, 145, 42, 1365.00),
        (136, 44, 94, 50, 351.00),
        (137, 45, 133, 24, 186.00),
        (138, 45, 99, 55, 288.00),
        (139, 46, 32, 15, 456.00),
        (140, 46, 48, 14, 660.00),
        (141, 46, 58, 45, 750.00),
        (142, 46, 77, 26, 252.00),
        (143, 47, 92, 30, 386.10),
        (144, 47, 56, 44, 617.50),
        (145, 47, 157, 40, 169.00),
        (146, 47, 159, 32, 414.00),
        (147, 48, 3, 15, 252.00),
        (148, 48, 8, 59, 364.00),
        (149, 48, 10, 27, 229.90),
        (150, 48, 122, 43, 216.00),
        (151, 49, 80, 28, 888.00),
        (152, 49, 142, 49, 198.00),
        (153, 49, 79, 40, 888.00),
        (154, 50, 131, 40, 283.80),
        (155, 50, 111, 24, 374.00),
        (156, 50, 20, 58, 468.00),
        (157, 51, 155, 48, 115.50),
        (158, 51, 119, 17, 324.50),
        (159, 51, 154, 25, 126.00),
        (160, 51, 46, 50, 1036.75),
        (161, 52, 127, 33, 144.00),
        (162, 52, 93, 33, 351.00),
        (163, 52, 89, 14, 637.00),
        (164, 53, 113, 42, 442.00),
        (165, 53, 48, 58, 715.00),
        (166, 53, 131, 58, 307.45),
        (167, 54, 15, 11, 292.50),
        (168, 54, 99, 29, 264.00),
        (169, 54, 129, 18, 279.50),
        (170, 55, 47, 57, 870.00),
        (171, 55, 156, 13, 156.00),
        (172, 55, 87, 59, 336.00),
        (173, 56, 92, 57, 386.10),
        (174, 56, 1, 50, 273.00),
        (175, 57, 38, 37, 489.50),
        (176, 57, 39, 59, 534.00),
        (177, 57, 42, 41, 384.00),
        (178, 58, 87, 10, 336.00),
        (179, 58, 73, 22, 810.00),
        (180, 58, 65, 50, 1040.00),
        (181, 59, 130, 60, 236.50),
        (182, 59, 77, 53, 252.00),
        (183, 60, 123, 48, 198.00),
        (184, 60, 93, 14, 324.00),
        (185, 60, 102, 38, 174.00);
    SET IDENTITY_INSERT dbo.PurchaseOrderDetail OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Batch)
BEGIN
    SET IDENTITY_INSERT dbo.Batch ON;
    INSERT INTO dbo.Batch (Id, BatchNumber, PurchaseOrderDetail_Id, Quantity, Stock, ElaborationDate) VALUES
        (1, N'LOT-00001', 1, 42, 25, '2026-08-11'),
        (2, N'LOT-00002', 2, 38, 23, '2026-08-12'),
        (3, N'LOT-00003', 3, 23, 10, '2026-08-15'),
        (4, N'LOT-00004', 4, 23, 17, '2026-10-17'),
        (5, N'LOT-00005', 5, 10, 6, '2026-10-22'),
        (6, N'LOT-00006', 6, 20, 16, '2026-06-28'),
        (7, N'LOT-00007', 7, 12, 12, '2026-06-12'),
        (8, N'LOT-00008', 8, 22, 22, '2026-06-18'),
        (9, N'LOT-00009', 9, 46, 28, '2026-06-27'),
        (10, N'LOT-00010', 10, 24, 23, '2026-08-21'),
        (11, N'LOT-00011', 11, 22, 2, '2026-08-18'),
        (12, N'LOT-00012', 12, 45, 0, '2026-08-07'),
        (13, N'LOT-00013', 13, 58, 30, '2026-08-17'),
        (14, N'LOT-00014', 14, 55, 28, '2026-07-21'),
        (15, N'LOT-00015', 15, 12, 11, '2026-08-02'),
        (16, N'LOT-00016', 16, 40, 30, '2026-08-05'),
        (17, N'LOT-00017', 21, 58, 54, '2026-06-25'),
        (18, N'LOT-00018', 22, 23, 5, '2026-06-30'),
        (19, N'LOT-00019', 23, 12, 9, '2026-06-30'),
        (20, N'LOT-00020', 28, 34, 21, '2026-09-04'),
        (21, N'LOT-00021', 29, 16, 1, '2026-09-10'),
        (22, N'LOT-00022', 30, 44, 30, '2026-09-14'),
        (23, N'LOT-00023', 31, 27, 11, '2026-09-14'),
        (24, N'LOT-00024', 32, 10, 1, '2026-09-26'),
        (25, N'LOT-00025', 33, 54, 50, '2026-07-18'),
        (26, N'LOT-00026', 34, 31, 26, '2026-07-19'),
        (27, N'LOT-00027', 35, 32, 10, '2026-05-28'),
        (28, N'LOT-00028', 36, 18, 10, '2026-05-27'),
        (29, N'LOT-00029', 37, 24, 8, '2026-06-05'),
        (30, N'LOT-00030', 38, 56, 54, '2026-05-27'),
        (31, N'LOT-00031', 39, 26, 23, '2026-05-24'),
        (32, N'LOT-00032', 40, 45, 25, '2026-07-05'),
        (33, N'LOT-00033', 41, 45, 31, '2026-06-27'),
        (34, N'LOT-00034', 42, 38, 35, '2026-05-07'),
        (35, N'LOT-00035', 43, 11, 8, '2026-05-25'),
        (36, N'LOT-00036', 44, 33, 5, '2026-05-14'),
        (37, N'LOT-00037', 45, 56, 9, '2026-05-09'),
        (38, N'LOT-00038', 46, 23, 8, '2026-09-20'),
        (39, N'LOT-00039', 47, 24, 7, '2026-09-25'),
        (40, N'LOT-00040', 48, 14, 14, '2026-09-30'),
        (41, N'LOT-00041', 49, 15, 6, '2026-09-19'),
        (42, N'LOT-00042', 50, 26, 4, '2026-09-09'),
        (43, N'LOT-00043', 51, 57, 36, '2026-09-05'),
        (44, N'LOT-00044', 52, 47, 14, '2026-09-22'),
        (45, N'LOT-00045', 56, 31, 20, '2026-06-23'),
        (46, N'LOT-00046', 57, 15, 11, '2026-06-07'),
        (47, N'LOT-00047', 61, 27, 3, '2026-09-17'),
        (48, N'LOT-00048', 62, 55, 19, '2026-09-11'),
        (49, N'LOT-00049', 63, 46, 1, '2026-08-30'),
        (50, N'LOT-00050', 64, 43, 15, '2026-08-28'),
        (51, N'LOT-00051', 65, 50, 38, '2026-06-09'),
        (52, N'LOT-00052', 66, 26, 14, '2026-05-28'),
        (53, N'LOT-00053', 67, 13, 13, '2026-06-13'),
        (54, N'LOT-00054', 68, 15, 11, '2026-09-04'),
        (55, N'LOT-00055', 69, 14, 5, '2026-08-24'),
        (56, N'LOT-00056', 70, 32, 27, '2026-09-02'),
        (57, N'LOT-00057', 71, 32, 23, '2026-09-09'),
        (58, N'LOT-00058', 72, 26, 17, '2026-09-27'),
        (59, N'LOT-00059', 73, 10, 3, '2026-09-15'),
        (60, N'LOT-00060', 74, 32, 26, '2026-09-08'),
        (61, N'LOT-00061', 75, 38, 19, '2026-09-07'),
        (62, N'LOT-00062', 76, 42, 24, '2026-09-18'),
        (63, N'LOT-00063', 79, 39, 32, '2026-10-11'),
        (64, N'LOT-00064', 80, 33, 24, '2026-10-08'),
        (65, N'LOT-00065', 81, 47, 31, '2026-09-23'),
        (66, N'LOT-00066', 82, 39, 2, '2026-10-05'),
        (67, N'LOT-00067', 83, 19, 0, '2026-09-27'),
        (68, N'LOT-00068', 84, 24, 13, '2026-09-18'),
        (69, N'LOT-00069', 85, 53, 33, '2026-09-16'),
        (70, N'LOT-00070', 86, 51, 40, '2026-09-25'),
        (71, N'LOT-00071', 87, 55, 8, '2026-08-10'),
        (72, N'LOT-00072', 88, 42, 31, '2026-08-12'),
        (73, N'LOT-00073', 89, 27, 17, '2026-08-05'),
        (74, N'LOT-00074', 90, 56, 1, '2026-08-16'),
        (75, N'LOT-00075', 91, 20, 12, '2026-08-18'),
        (76, N'LOT-00076', 92, 25, 15, '2026-05-20'),
        (77, N'LOT-00077', 93, 33, 8, '2026-05-21'),
        (78, N'LOT-00078', 94, 35, 22, '2026-05-20'),
        (79, N'LOT-00079', 95, 28, 14, '2026-05-27'),
        (80, N'LOT-00080', 96, 16, 10, '2026-06-09'),
        (81, N'LOT-00081', 97, 49, 19, '2026-06-11'),
        (82, N'LOT-00082', 98, 11, 9, '2026-06-21'),
        (83, N'LOT-00083', 102, 48, 8, '2026-09-12'),
        (84, N'LOT-00084', 103, 33, 23, '2026-08-31'),
        (85, N'LOT-00085', 104, 57, 28, '2026-09-05'),
        (86, N'LOT-00086', 105, 17, 10, '2026-08-29'),
        (87, N'LOT-00087', 106, 14, 3, '2026-08-02'),
        (88, N'LOT-00088', 107, 39, 11, '2026-07-20'),
        (89, N'LOT-00089', 108, 16, 11, '2026-07-21'),
        (90, N'LOT-00090', 109, 10, 7, '2026-05-29'),
        (91, N'LOT-00091', 110, 12, 0, '2026-05-18'),
        (92, N'LOT-00092', 111, 14, 1, '2026-05-30'),
        (93, N'LOT-00093', 112, 40, 28, '2026-07-25'),
        (94, N'LOT-00094', 113, 42, 22, '2026-08-09'),
        (95, N'LOT-00095', 114, 51, 29, '2026-08-09'),
        (96, N'LOT-00096', 115, 54, 1, '2026-07-25'),
        (97, N'LOT-00097', 118, 10, 7, '2026-07-20'),
        (98, N'LOT-00098', 119, 27, 14, '2026-07-29'),
        (99, N'LOT-00099', 120, 46, 24, '2026-08-21'),
        (100, N'LOT-00100', 121, 49, 9, '2026-08-29'),
        (101, N'LOT-00101', 122, 30, 1, '2026-08-23'),
        (102, N'LOT-00102', 123, 30, 22, '2026-08-19'),
        (103, N'LOT-00103', 124, 55, 42, '2026-08-28'),
        (104, N'LOT-00104', 129, 24, 17, '2026-08-05'),
        (105, N'LOT-00105', 130, 41, 35, '2026-08-19'),
        (106, N'LOT-00106', 131, 35, 7, '2026-07-30'),
        (107, N'LOT-00107', 132, 24, 7, '2026-08-14'),
        (108, N'LOT-00108', 133, 46, 14, '2026-09-09'),
        (109, N'LOT-00109', 134, 26, 20, '2026-09-11'),
        (110, N'LOT-00110', 135, 42, 17, '2026-09-07'),
        (111, N'LOT-00111', 136, 50, 29, '2026-09-03'),
        (112, N'LOT-00112', 137, 24, 9, '2026-09-25'),
        (113, N'LOT-00113', 138, 55, 38, '2026-09-07'),
        (114, N'LOT-00114', 139, 15, 9, '2026-09-30'),
        (115, N'LOT-00115', 140, 14, 7, '2026-09-29'),
        (116, N'LOT-00116', 141, 45, 24, '2026-10-03'),
        (117, N'LOT-00117', 142, 26, 13, '2026-10-03'),
        (118, N'LOT-00118', 143, 30, 4, '2026-07-17'),
        (119, N'LOT-00119', 144, 44, 18, '2026-07-21'),
        (120, N'LOT-00120', 145, 40, 3, '2026-07-31'),
        (121, N'LOT-00121', 146, 32, 7, '2026-07-19'),
        (122, N'LOT-00122', 147, 15, 10, '2026-05-12'),
        (123, N'LOT-00123', 148, 59, 23, '2026-05-15'),
        (124, N'LOT-00124', 149, 27, 9, '2026-05-21'),
        (125, N'LOT-00125', 150, 43, 39, '2026-05-16'),
        (126, N'LOT-00126', 151, 28, 13, '2026-08-05'),
        (127, N'LOT-00127', 152, 49, 15, '2026-07-20'),
        (128, N'LOT-00128', 153, 40, 11, '2026-07-31'),
        (129, N'LOT-00129', 154, 40, 38, '2026-06-18'),
        (130, N'LOT-00130', 155, 24, 18, '2026-06-12'),
        (131, N'LOT-00131', 156, 58, 45, '2026-06-17'),
        (132, N'LOT-00132', 157, 48, 5, '2026-07-18'),
        (133, N'LOT-00133', 158, 17, 0, '2026-07-09'),
        (134, N'LOT-00134', 159, 25, 20, '2026-07-25'),
        (135, N'LOT-00135', 160, 50, 16, '2026-07-09'),
        (136, N'LOT-00136', 164, 42, 4, '2026-10-18'),
        (137, N'LOT-00137', 165, 58, 49, '2026-10-12'),
        (138, N'LOT-00138', 166, 58, 2, '2026-10-06'),
        (139, N'LOT-00139', 167, 11, 1, '2026-08-10'),
        (140, N'LOT-00140', 168, 29, 22, '2026-08-13'),
        (141, N'LOT-00141', 169, 18, 5, '2026-08-03'),
        (142, N'LOT-00142', 170, 57, 0, '2026-06-13'),
        (143, N'LOT-00143', 171, 13, 6, '2026-06-09'),
        (144, N'LOT-00144', 172, 59, 22, '2026-06-19'),
        (145, N'LOT-00145', 175, 37, 35, '2026-05-17'),
        (146, N'LOT-00146', 176, 59, 31, '2026-05-14'),
        (147, N'LOT-00147', 177, 41, 21, '2026-05-17'),
        (148, N'LOT-00148', 181, 60, 30, '2026-08-14'),
        (149, N'LOT-00149', 182, 53, 43, '2026-08-11'),
        (150, N'LOT-00150', 183, 48, 25, '2026-06-08'),
        (151, N'LOT-00151', 184, 14, 0, '2026-06-07'),
        (152, N'LOT-00152', 185, 38, 3, '2026-05-31');
    SET IDENTITY_INSERT dbo.Batch OFF;
END
GO

-- Gestión de impuestos, descuentos, cupones y pagos
IF NOT EXISTS (SELECT 1 FROM dbo.Taxes)
BEGIN
    SET IDENTITY_INSERT dbo.Taxes ON;
    INSERT INTO dbo.Taxes (Id, Name, Percentage) VALUES
        (1, N'ISV 15%', 15.00),
        (2, N'ISV 18%', 18.00),
        (3, N'Exonerado 0%', 0.00),
        (4, N'ISV Reducido 7%', 7.00),
        (5, N'ISV Turístico 4%', 4.00),
        (6, N'Tasa Municipal 1%', 1.00),
        (7, N'Contribución Seguridad 0.5%', 0.50),
        (8, N'Impuesto Selectivo Lujo 10%', 10.00),
        (9, N'IVA Importación 12%', 12.00),
        (10, N'Zona Libre 0%', 0.00),
        (11, N'Tasa Turística Islas 4%', 4.00),
        (12, N'Impuesto Empaque 1%', 1.00),
        (13, N'Recargo Servicio 2%', 2.00),
        (14, N'Prendas de Lujo 12%', 12.00),
        (15, N'Contribución Social 1.5%', 1.50);
    SET IDENTITY_INSERT dbo.Taxes OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Discounts)
BEGIN
    SET IDENTITY_INSERT dbo.Discounts ON;
    INSERT INTO dbo.Discounts (Id, Name, StartDate, FinishDate, Percentage) VALUES
        (1, N'Rebajas de Verano 2026', '2026-06-01T00:00:00', '2026-08-31T23:59:59', 20.00),
        (2, N'Día del Padre', '2026-06-10T00:00:00', '2026-06-21T23:59:59', 15.00),
        (3, N'Regreso a Clases', '2026-07-15T00:00:00', '2026-08-15T23:59:59', 10.00),
        (4, N'Semana del Jean', '2026-09-01T00:00:00', '2026-09-14T23:59:59', 25.00),
        (5, N'Liquidación de Chaquetas', '2026-08-01T00:00:00', '2026-10-31T23:59:59', 30.00),
        (6, N'Fiestas Patrias', '2026-09-10T00:00:00', '2026-09-20T23:59:59', 15.00),
        (7, N'Oferta Calzado', '2026-06-01T00:00:00', '2026-11-30T23:59:59', 12.00),
        (8, N'Outlet de Accesorios', '2026-10-01T00:00:00', '2026-12-31T23:59:59', 35.00),
        (9, N'Black Friday 2026', '2026-11-20T00:00:00', '2026-11-30T23:59:59', 40.00),
        (10, N'Aniversario Pedestal', '2026-06-01T00:00:00', '2026-12-31T23:59:59', 18.00),
        (11, N'Feria Deportiva', '2026-09-15T00:00:00', '2026-10-15T23:59:59', 20.00),
        (12, N'Día de la Madre', '2026-06-01T00:00:00', '2026-06-15T23:59:59', 15.00),
        (13, N'Ropa Interior 2x1', '2026-07-01T00:00:00', '2026-11-30T23:59:59', 10.00),
        (14, N'Fin de Temporada', '2026-10-15T00:00:00', '2026-11-30T23:59:59', 22.00),
        (15, N'Navidad Anticipada', '2026-11-01T00:00:00', '2026-12-24T23:59:59', 12.00);
    SET IDENTITY_INSERT dbo.Discounts OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DiscountTarget)
BEGIN
    SET IDENTITY_INSERT dbo.DiscountTarget ON;
    INSERT INTO dbo.DiscountTarget (Id, Discount_Id, Clothe_Id, ClotheType_Id) VALUES
        (1, 1, NULL, 8),
        (2, 1, NULL, 12),
        (3, 2, NULL, 1),
        (4, 2, 3, NULL),
        (5, 3, NULL, 2),
        (6, 3, NULL, 5),
        (7, 4, 5, NULL),
        (8, 4, 7, NULL),
        (9, 5, NULL, 4),
        (10, 5, NULL, 13),
        (11, 6, NULL, 3),
        (12, 6, NULL, 7),
        (13, 7, NULL, 5),
        (14, 7, 16, NULL),
        (15, 8, NULL, 6),
        (16, 8, NULL, 14),
        (17, 9, NULL, 9),
        (18, 9, NULL, 4),
        (19, 10, NULL, 1),
        (20, 10, NULL, 3),
        (21, 11, NULL, 11),
        (22, 11, 25, NULL),
        (23, 12, NULL, 3),
        (24, 12, NULL, 15),
        (25, 13, NULL, 10),
        (26, 13, 29, NULL),
        (27, 14, NULL, 7),
        (28, 14, NULL, 8),
        (29, 15, NULL, 15),
        (30, 15, NULL, 9);
    SET IDENTITY_INSERT dbo.DiscountTarget OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Coupons)
BEGIN
    SET IDENTITY_INSERT dbo.Coupons ON;
    INSERT INTO dbo.Coupons (Id, Name, Code, DiscountKind, Percentage, Amount, StartDate, FinishDate, MaxUses, MinPurchaseAmount) VALUES
        (1, N'Bienvenida 10%', N'BIENVENIDO10', N'P', 10.00, NULL, '2026-06-01T00:00:00', '2026-12-31T23:59:59', NULL, 300.00),
        (2, N'Ahorra L100', N'AHORRA100', N'A', NULL, 100.00, '2026-06-01T00:00:00', '2026-12-31T23:59:59', NULL, 800.00),
        (3, N'Cliente Frecuente 8%', N'FRECUENTE8', N'P', 8.00, NULL, '2026-06-01T00:00:00', '2026-12-31T23:59:59', NULL, 0.00),
        (4, N'Verano 5%', N'VERANO5', N'P', 5.00, NULL, '2026-06-01T00:00:00', '2026-08-31T23:59:59', NULL, 200.00),
        (5, N'Padre Feliz L150', N'PADRE150', N'A', NULL, 150.00, '2026-06-10T00:00:00', '2026-06-21T23:59:59', 60, 1000.00),
        (6, N'Regreso a Clases 7%', N'CLASES7', N'P', 7.00, NULL, '2026-07-15T00:00:00', '2026-08-31T23:59:59', NULL, 400.00),
        (7, N'Patrias 12%', N'PATRIAS12', N'P', 12.00, NULL, '2026-09-10T00:00:00', '2026-09-20T23:59:59', 80, 500.00),
        (8, N'Octubre Rosa L80', N'ROSA80', N'A', NULL, 80.00, '2026-10-01T00:00:00', '2026-10-31T23:59:59', NULL, 600.00),
        (9, N'Compra Online 5%', N'ONLINE5', N'P', 5.00, NULL, '2026-06-01T00:00:00', '2026-12-31T23:59:59', NULL, 250.00),
        (10, N'Black Friday L300', N'BLACK300', N'A', NULL, 300.00, '2026-11-20T00:00:00', '2026-11-30T23:59:59', 100, 1500.00),
        (11, N'Amigos 6%', N'AMIGOS6', N'P', 6.00, NULL, '2026-07-01T00:00:00', '2026-11-30T23:59:59', NULL, 350.00),
        (12, N'Envío Gratis L60', N'ENVIO60', N'A', NULL, 60.00, '2026-06-01T00:00:00', '2026-12-31T23:59:59', NULL, 500.00),
        (13, N'VIP 15%', N'VIP15', N'P', 15.00, NULL, '2026-08-01T00:00:00', '2026-12-31T23:59:59', 40, 1200.00),
        (14, N'Cumpleaños L120', N'CUMPLE120', N'A', NULL, 120.00, '2026-06-01T00:00:00', '2026-12-31T23:59:59', NULL, 700.00),
        (15, N'Navidad 10%', N'NAVIDAD10', N'P', 10.00, NULL, '2026-11-01T00:00:00', '2026-12-24T23:59:59', NULL, 400.00);
    SET IDENTITY_INSERT dbo.Coupons OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PaymentMethod)
BEGIN
    SET IDENTITY_INSERT dbo.PaymentMethod ON;
    INSERT INTO dbo.PaymentMethod (Id, Name, RequiresCard, AllowedInStore, AllowedOnline, ApplyDiscounts) VALUES
        (1, N'Efectivo', 0, 1, 0, 1),
        (2, N'Tarjeta de débito', 1, 1, 1, 1),
        (3, N'Tarjeta de crédito', 1, 1, 1, 1),
        (4, N'Transferencia bancaria', 0, 1, 1, 1),
        (5, N'Cheque', 0, 1, 0, 1),
        (6, N'Vale de regalo', 0, 1, 0, 0),
        (7, N'Billetera digital', 0, 1, 1, 1),
        (8, N'Pago contra entrega', 0, 0, 1, 1),
        (9, N'Tarjeta prepago', 1, 1, 1, 1),
        (10, N'Crédito de tienda', 0, 1, 0, 0),
        (11, N'Pago en cuotas', 1, 1, 1, 0),
        (12, N'Tarjeta corporativa', 1, 1, 0, 1),
        (13, N'Depósito bancario', 0, 1, 1, 1),
        (14, N'Canje de puntos', 0, 1, 1, 0),
        (15, N'Pago mixto especial', 0, 1, 0, 1);
    SET IDENTITY_INSERT dbo.PaymentMethod OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PaymentCard)
BEGIN
    SET IDENTITY_INSERT dbo.PaymentCard ON;
    INSERT INTO dbo.PaymentCard (Id, User_Id, HolderName, Brand, CardType, Last4, ExpirationDate, IsDefault) VALUES
        (1, 1, N'LOURDES RIVERA', N'Visa', N'CREDIT', N'4946', '2031-08-28', 1),
        (2, 2, N'JESSICA EUCEDA', N'Visa', N'DEBIT', N'7865', '2027-10-28', 1),
        (3, 3, N'MARCELA SOTO', N'Visa', N'CREDIT', N'6205', '2029-01-28', 1),
        (4, 4, N'YESENIA FLORES', N'Visa', N'DEBIT', N'4873', '2031-03-28', 1),
        (5, 5, N'ELSA MENDOZA', N'Visa', N'CREDIT', N'6152', '2029-12-28', 1),
        (6, 6, N'JOSÉ MEDINA', N'Mastercard', N'DEBIT', N'2891', '2028-04-28', 1),
        (7, 6, N'JOSÉ MEDINA', N'Visa', N'CREDIT', N'0492', '2031-10-28', 0),
        (8, 7, N'JUAN BONILLA', N'Visa', N'CREDIT', N'3833', '2031-08-28', 1),
        (9, 8, N'JORGE GARCÍA', N'Mastercard', N'DEBIT', N'6304', '2031-01-28', 1),
        (10, 9, N'WILMER AGUILAR', N'Visa', N'CREDIT', N'8526', '2027-03-28', 1),
        (11, 10, N'FREDY BANEGAS', N'Visa', N'DEBIT', N'1405', '2031-10-28', 1),
        (12, 11, N'ROLANDO FUNES', N'Visa', N'CREDIT', N'1485', '2030-07-28', 1),
        (13, 12, N'SAMUEL MARTÍNEZ', N'Mastercard', N'DEBIT', N'1303', '2028-02-28', 1),
        (14, 12, N'SAMUEL MARTÍNEZ', N'Visa', N'CREDIT', N'4107', '2029-10-28', 0),
        (15, 13, N'ANA CRUZ', N'Visa', N'CREDIT', N'7877', '2031-01-28', 1),
        (16, 14, N'GLORIA NÚÑEZ', N'Visa', N'DEBIT', N'8743', '2031-07-28', 1),
        (17, 15, N'FÁTIMA MIDENCE', N'Visa', N'CREDIT', N'6411', '2029-02-28', 1),
        (18, 16, N'ROSA HERNÁNDEZ', N'Visa', N'DEBIT', N'5409', '2028-06-28', 1),
        (19, 17, N'CLAUDIA REYES', N'Visa', N'CREDIT', N'0689', '2027-11-28', 1),
        (20, 18, N'NORMA CASTILLO', N'Visa', N'DEBIT', N'8503', '2028-05-28', 1),
        (21, 18, N'NORMA CASTILLO', N'Mastercard', N'CREDIT', N'2671', '2030-02-28', 0),
        (22, 19, N'KEILA PALMA', N'Mastercard', N'CREDIT', N'5313', '2029-08-28', 1),
        (23, 20, N'LUIS PADILLA', N'Mastercard', N'DEBIT', N'1319', '2029-06-28', 1),
        (24, 21, N'OSCAR PÉREZ', N'Mastercard', N'CREDIT', N'4146', '2029-03-28', 1),
        (25, 22, N'KEVIN ZELAYA', N'Mastercard', N'DEBIT', N'9543', '2029-06-28', 1),
        (26, 23, N'WALTER CÁCERES', N'Mastercard', N'CREDIT', N'6240', '2031-07-28', 1),
        (27, 24, N'HÉCTOR LAGOS', N'Mastercard', N'DEBIT', N'4065', '2029-05-28', 1),
        (28, 24, N'HÉCTOR LAGOS', N'Mastercard', N'CREDIT', N'8670', '2031-02-28', 0),
        (29, 25, N'EDGARDO RODRÍGUEZ', N'Mastercard', N'CREDIT', N'0581', '2031-08-28', 1),
        (30, 26, N'MARÍA RAMÍREZ', N'Mastercard', N'DEBIT', N'3236', '2030-09-28', 1),
        (31, 27, N'SANDRA ORDÓÑEZ', N'Mastercard', N'CREDIT', N'1432', '2031-07-28', 1),
        (32, 28, N'DANIELA VARELA', N'Mastercard', N'DEBIT', N'0502', '2028-09-28', 1),
        (33, 29, N'WENDY LÓPEZ', N'Mastercard', N'CREDIT', N'0090', '2028-05-28', 1),
        (34, 30, N'PATRICIA MEJÍA', N'Mastercard', N'DEBIT', N'6484', '2030-01-28', 1),
        (35, 30, N'PATRICIA MEJÍA', N'Mastercard', N'CREDIT', N'7423', '2028-01-28', 0),
        (36, 31, N'GABRIELA RIVERA', N'Mastercard', N'CREDIT', N'4924', '2027-11-28', 1),
        (37, 32, N'DILCIA EUCEDA', N'Mastercard', N'DEBIT', N'6835', '2027-11-28', 1),
        (38, 33, N'HÉCTOR FLORES', N'Visa', N'CREDIT', N'0568', '2027-04-28', 1),
        (39, 34, N'EDGARDO MENDOZA', N'Visa', N'DEBIT', N'1522', '2029-11-28', 1),
        (40, 35, N'SAMUEL EUCEDA', N'Mastercard', N'CREDIT', N'3357', '2029-04-28', 1);
    SET IDENTITY_INSERT dbo.PaymentCard OFF;
END
GO

-- Gestión de facturación y caja
IF NOT EXISTS (SELECT 1 FROM dbo.CashRegister)
BEGIN
    SET IDENTITY_INSERT dbo.CashRegister ON;
    INSERT INTO dbo.CashRegister (Id, Store_Id, Name, Description) VALUES
        (1, 3, N'Caja 1', N'Caja 1 de Pedestal Tegucigalpa Centro'),
        (2, 3, N'Caja 2', N'Caja 2 de Pedestal Tegucigalpa Centro'),
        (3, 4, N'Caja 1', N'Caja 1 de Pedestal Tegucigalpa Palmira'),
        (4, 4, N'Caja 2', N'Caja 2 de Pedestal Tegucigalpa Palmira'),
        (5, 5, N'Caja 1', N'Caja 1 de Pedestal Tegucigalpa Kennedy'),
        (6, 5, N'Caja 2', N'Caja 2 de Pedestal Tegucigalpa Kennedy'),
        (7, 6, N'Caja 1', N'Caja 1 de Pedestal Tegucigalpa El Trapiche'),
        (8, 6, N'Caja 2', N'Caja 2 de Pedestal Tegucigalpa El Trapiche'),
        (9, 7, N'Caja 1', N'Caja 1 de Pedestal San Pedro Sula Centro'),
        (10, 7, N'Caja 2', N'Caja 2 de Pedestal San Pedro Sula Centro'),
        (11, 8, N'Caja 1', N'Caja 1 de Pedestal San Pedro Sula Mall'),
        (12, 8, N'Caja 2', N'Caja 2 de Pedestal San Pedro Sula Mall'),
        (13, 9, N'Caja 1', N'Caja 1 de Pedestal La Ceiba Centro'),
        (14, 9, N'Caja 2', N'Caja 2 de Pedestal La Ceiba Centro'),
        (15, 10, N'Caja 1', N'Caja 1 de Pedestal La Ceiba Paseo'),
        (16, 10, N'Caja 2', N'Caja 2 de Pedestal La Ceiba Paseo'),
        (17, 11, N'Caja 1', N'Caja 1 de Pedestal El Progreso Centro'),
        (18, 11, N'Caja 2', N'Caja 2 de Pedestal El Progreso Centro'),
        (19, 12, N'Caja 1', N'Caja 1 de Pedestal Yoro Centro'),
        (20, 12, N'Caja 2', N'Caja 2 de Pedestal Yoro Centro'),
        (21, 13, N'Caja 1', N'Caja 1 de Pedestal Juticalpa Centro'),
        (22, 13, N'Caja 2', N'Caja 2 de Pedestal Juticalpa Centro'),
        (23, 14, N'Caja 1', N'Caja 1 de Pedestal Catacamas Centro'),
        (24, 14, N'Caja 2', N'Caja 2 de Pedestal Catacamas Centro'),
        (25, 15, N'Caja 1', N'Caja 1 de Pedestal Choluteca Centro'),
        (26, 15, N'Caja 2', N'Caja 2 de Pedestal Choluteca Centro'),
        (27, 16, N'Caja 1', N'Caja 1 de Pedestal Choluteca Plaza'),
        (28, 16, N'Caja 2', N'Caja 2 de Pedestal Choluteca Plaza'),
        (29, 17, N'Caja 1', N'Caja 1 de Pedestal Comayagua Centro'),
        (30, 17, N'Caja 2', N'Caja 2 de Pedestal Comayagua Centro'),
        (31, 18, N'Caja 1', N'Caja 1 de Pedestal Siguatepeque Centro'),
        (32, 18, N'Caja 2', N'Caja 2 de Pedestal Siguatepeque Centro'),
        (33, 19, N'Caja 1', N'Caja 1 de Pedestal Santa Rosa de Copán Centro'),
        (34, 19, N'Caja 2', N'Caja 2 de Pedestal Santa Rosa de Copán Centro'),
        (35, 20, N'Caja 1', N'Caja 1 de Pedestal Copán Ruinas'),
        (36, 20, N'Caja 2', N'Caja 2 de Pedestal Copán Ruinas'),
        (37, 21, N'Caja 1', N'Caja 1 de Pedestal Danlí Centro'),
        (38, 21, N'Caja 2', N'Caja 2 de Pedestal Danlí Centro'),
        (39, 22, N'Caja 1', N'Caja 1 de Pedestal Danlí Plaza'),
        (40, 22, N'Caja 2', N'Caja 2 de Pedestal Danlí Plaza'),
        (41, 23, N'Caja 1', N'Caja 1 de Pedestal Santa Bárbara Centro'),
        (42, 23, N'Caja 2', N'Caja 2 de Pedestal Santa Bárbara Centro'),
        (43, 24, N'Caja 1', N'Caja 1 de Pedestal Quimistán Centro'),
        (44, 24, N'Caja 2', N'Caja 2 de Pedestal Quimistán Centro'),
        (45, 25, N'Caja 1', N'Caja 1 de Pedestal Gracias Centro'),
        (46, 25, N'Caja 2', N'Caja 2 de Pedestal Gracias Centro'),
        (47, 26, N'Caja 1', N'Caja 1 de Pedestal Gracias Plaza'),
        (48, 26, N'Caja 2', N'Caja 2 de Pedestal Gracias Plaza'),
        (49, 27, N'Caja 1', N'Caja 1 de Pedestal Trujillo Centro'),
        (50, 27, N'Caja 2', N'Caja 2 de Pedestal Trujillo Centro'),
        (51, 28, N'Caja 1', N'Caja 1 de Pedestal Tocoa Centro'),
        (52, 28, N'Caja 2', N'Caja 2 de Pedestal Tocoa Centro'),
        (53, 29, N'Caja 1', N'Caja 1 de Pedestal Roatán Centro'),
        (54, 29, N'Caja 2', N'Caja 2 de Pedestal Roatán Centro'),
        (55, 30, N'Caja 1', N'Caja 1 de Pedestal Roatán West End'),
        (56, 30, N'Caja 2', N'Caja 2 de Pedestal Roatán West End');
    SET IDENTITY_INSERT dbo.CashRegister OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.CashShift)
BEGIN
    SET IDENTITY_INSERT dbo.CashShift ON;
    INSERT INTO dbo.CashShift (Id, CashRegister_Id, Employee_Id, OpenedAt, ClosedAt, OpeningAmount, ClosingAmount, Status) VALUES
        (1, 1, 46, '2026-08-18T08:00:00', '2026-08-18T17:00:00', 1000.00, 15138.46, N'CLOSED'),
        (2, 2, 46, '2026-08-01T08:00:00', '2026-08-01T17:00:00', 1500.00, 13671.40, N'CLOSED'),
        (3, 1, 46, '2026-07-24T08:00:00', '2026-07-24T17:00:00', 2000.00, 2010.00, N'CLOSED'),
        (4, 1, 46, '2026-11-21T08:00:00', NULL, 1500.00, NULL, N'OPEN'),
        (5, 3, 47, '2026-09-17T08:00:00', '2026-09-17T17:00:00', 1000.00, 6784.60, N'CLOSED'),
        (6, 4, 47, '2026-10-18T08:00:00', '2026-10-18T17:00:00', 1500.00, 4674.44, N'CLOSED'),
        (7, 3, 47, '2026-07-31T08:00:00', '2026-07-31T17:00:00', 2000.00, 5033.70, N'CLOSED'),
        (8, 3, 47, '2026-11-21T08:00:00', NULL, 1500.00, NULL, N'OPEN'),
        (9, 5, 48, '2026-10-09T08:00:00', '2026-10-09T17:00:00', 1000.00, 4151.02, N'CLOSED'),
        (10, 6, 48, '2026-07-11T08:00:00', '2026-07-11T17:00:00', 1500.00, 5903.00, N'CLOSED'),
        (11, 5, 48, '2026-10-24T08:00:00', '2026-10-24T17:00:00', 2000.00, 9065.46, N'CLOSED'),
        (12, 5, 48, '2026-11-21T08:00:00', NULL, 1500.00, NULL, N'OPEN'),
        (13, 7, 49, '2026-07-02T08:00:00', '2026-07-02T17:00:00', 1000.00, 4631.30, N'CLOSED'),
        (14, 8, 49, '2026-08-17T08:00:00', '2026-08-17T17:00:00', 1500.00, 4844.92, N'CLOSED'),
        (15, 7, 49, '2026-10-04T08:00:00', '2026-10-04T17:00:00', 2000.00, 3867.25, N'CLOSED'),
        (16, 7, 49, '2026-11-21T08:00:00', NULL, 1500.00, NULL, N'OPEN'),
        (17, 9, 50, '2026-10-28T08:00:00', '2026-10-28T17:00:00', 1000.00, 2565.77, N'CLOSED'),
        (18, 10, 50, '2026-10-10T08:00:00', '2026-10-10T17:00:00', 1500.00, 3340.40, N'CLOSED'),
        (19, 9, 50, '2026-07-18T08:00:00', '2026-07-18T17:00:00', 2000.00, 7530.00, N'CLOSED'),
        (20, 9, 50, '2026-11-21T08:00:00', NULL, 1500.00, NULL, N'OPEN'),
        (21, 11, 51, '2026-11-14T08:00:00', '2026-11-14T17:00:00', 1000.00, 15171.59, N'CLOSED'),
        (22, 12, 51, '2026-08-20T08:00:00', '2026-08-20T17:00:00', 1500.00, 10083.83, N'CLOSED'),
        (23, 11, 51, '2026-10-12T08:00:00', '2026-10-12T17:00:00', 2000.00, 3166.03, N'CLOSED'),
        (24, 13, 52, '2026-10-14T08:00:00', '2026-10-14T17:00:00', 1000.00, 4111.90, N'CLOSED'),
        (25, 14, 52, '2026-09-28T08:00:00', '2026-09-28T17:00:00', 1500.00, 4169.95, N'CLOSED'),
        (26, 13, 52, '2026-06-18T08:00:00', '2026-06-18T17:00:00', 2000.00, 7876.38, N'CLOSED'),
        (27, 15, 53, '2026-09-20T08:00:00', '2026-09-20T17:00:00', 1000.00, 6622.60, N'CLOSED'),
        (28, 16, 53, '2026-08-03T08:00:00', '2026-08-03T17:00:00', 1500.00, 7750.50, N'CLOSED'),
        (29, 15, 53, '2026-10-08T08:00:00', '2026-10-08T17:00:00', 2000.00, 16463.09, N'CLOSED'),
        (30, 17, 54, '2026-09-09T08:00:00', '2026-09-09T17:00:00', 1000.00, 1000.00, N'CLOSED'),
        (31, 18, 54, '2026-08-16T08:00:00', '2026-08-16T17:00:00', 1500.00, 6887.22, N'CLOSED'),
        (32, 17, 54, '2026-09-07T08:00:00', '2026-09-07T17:00:00', 2000.00, 6299.62, N'CLOSED'),
        (33, 19, 55, '2026-09-04T08:00:00', '2026-09-04T17:00:00', 1000.00, 8017.78, N'CLOSED'),
        (34, 20, 55, '2026-07-03T08:00:00', '2026-07-03T17:00:00', 1500.00, 14473.89, N'CLOSED'),
        (35, 19, 55, '2026-10-08T08:00:00', '2026-10-08T17:00:00', 2000.00, 11087.00, N'CLOSED'),
        (36, 21, 56, '2026-09-15T08:00:00', '2026-09-15T17:00:00', 1000.00, 5119.19, N'CLOSED'),
        (37, 22, 56, '2026-06-26T08:00:00', '2026-06-26T17:00:00', 1500.00, 5802.29, N'CLOSED'),
        (38, 21, 56, '2026-08-17T08:00:00', '2026-08-17T17:00:00', 2000.00, 5066.38, N'CLOSED'),
        (39, 23, 57, '2026-06-04T08:00:00', '2026-06-04T17:00:00', 1000.00, 15216.00, N'CLOSED'),
        (40, 24, 57, '2026-07-20T08:00:00', '2026-07-20T17:00:00', 1500.00, 2627.00, N'CLOSED'),
        (41, 23, 57, '2026-10-03T08:00:00', '2026-10-03T17:00:00', 2000.00, 8867.50, N'CLOSED'),
        (42, 25, 58, '2026-07-05T08:00:00', '2026-07-05T17:00:00', 1000.00, 5696.60, N'CLOSED'),
        (43, 26, 58, '2026-06-04T08:00:00', '2026-06-04T17:00:00', 1500.00, 9068.49, N'CLOSED'),
        (44, 25, 58, '2026-06-10T08:00:00', '2026-06-10T17:00:00', 2000.00, 9577.08, N'CLOSED'),
        (45, 27, 59, '2026-07-29T08:00:00', '2026-07-29T17:00:00', 1000.00, 7150.20, N'CLOSED'),
        (46, 28, 59, '2026-10-30T08:00:00', '2026-10-30T17:00:00', 1500.00, 9875.47, N'CLOSED'),
        (47, 27, 59, '2026-10-21T08:00:00', '2026-10-21T17:00:00', 2000.00, 9499.06, N'CLOSED'),
        (48, 29, 60, '2026-08-27T08:00:00', '2026-08-27T17:00:00', 1000.00, 2156.20, N'CLOSED'),
        (49, 30, 60, '2026-06-29T08:00:00', '2026-06-29T17:00:00', 1500.00, 9282.30, N'CLOSED'),
        (50, 29, 60, '2026-09-12T08:00:00', '2026-09-12T17:00:00', 2000.00, 2010.00, N'CLOSED'),
        (51, 31, 61, '2026-09-25T08:00:00', '2026-09-25T17:00:00', 1000.00, 10134.12, N'CLOSED'),
        (52, 32, 61, '2026-06-23T08:00:00', '2026-06-23T17:00:00', 1500.00, 19600.70, N'CLOSED'),
        (53, 31, 61, '2026-07-10T08:00:00', '2026-07-10T17:00:00', 2000.00, 11071.66, N'CLOSED'),
        (54, 33, 62, '2026-11-01T08:00:00', '2026-11-01T17:00:00', 1000.00, 17760.18, N'CLOSED'),
        (55, 34, 62, '2026-08-21T08:00:00', '2026-08-21T17:00:00', 1500.00, 5081.95, N'CLOSED'),
        (56, 33, 62, '2026-07-31T08:00:00', '2026-07-31T17:00:00', 2000.00, 18423.38, N'CLOSED'),
        (57, 35, 63, '2026-11-03T08:00:00', '2026-11-03T17:00:00', 1000.00, 12034.48, N'CLOSED'),
        (58, 36, 63, '2026-10-24T08:00:00', '2026-10-24T17:00:00', 1500.00, 5429.20, N'CLOSED'),
        (59, 35, 63, '2026-08-26T08:00:00', '2026-08-26T17:00:00', 2000.00, 9825.75, N'CLOSED'),
        (60, 37, 64, '2026-07-22T08:00:00', '2026-07-22T17:00:00', 1000.00, 5921.50, N'CLOSED'),
        (61, 38, 64, '2026-09-23T08:00:00', '2026-09-23T17:00:00', 1500.00, 15589.76, N'CLOSED'),
        (62, 37, 64, '2026-06-16T08:00:00', '2026-06-16T17:00:00', 2000.00, 11976.50, N'CLOSED'),
        (63, 39, 65, '2026-09-07T08:00:00', '2026-09-07T17:00:00', 1000.00, 9208.50, N'CLOSED'),
        (64, 40, 65, '2026-07-13T08:00:00', '2026-07-13T17:00:00', 1500.00, 11815.04, N'CLOSED'),
        (65, 39, 65, '2026-11-06T08:00:00', '2026-11-06T17:00:00', 2000.00, 6756.24, N'CLOSED'),
        (66, 41, 66, '2026-06-23T08:00:00', '2026-06-23T17:00:00', 1000.00, 13969.95, N'CLOSED'),
        (67, 42, 66, '2026-08-20T08:00:00', '2026-08-20T17:00:00', 1500.00, 12682.60, N'CLOSED'),
        (68, 41, 66, '2026-09-30T08:00:00', '2026-09-30T17:00:00', 2000.00, 7636.30, N'CLOSED'),
        (69, 43, 67, '2026-06-06T08:00:00', '2026-06-06T17:00:00', 1000.00, 15242.80, N'CLOSED'),
        (70, 44, 67, '2026-08-11T08:00:00', '2026-08-11T17:00:00', 1500.00, 2665.71, N'CLOSED'),
        (71, 43, 67, '2026-09-30T08:00:00', '2026-09-30T17:00:00', 2000.00, 5625.60, N'CLOSED'),
        (72, 45, 68, '2026-06-21T08:00:00', '2026-06-21T17:00:00', 1000.00, 14951.34, N'CLOSED'),
        (73, 46, 68, '2026-11-14T08:00:00', '2026-11-14T17:00:00', 1500.00, 8570.51, N'CLOSED'),
        (74, 45, 68, '2026-06-13T08:00:00', '2026-06-13T17:00:00', 2000.00, 9582.80, N'CLOSED'),
        (75, 47, 69, '2026-11-12T08:00:00', '2026-11-12T17:00:00', 1000.00, 17495.39, N'CLOSED'),
        (76, 48, 69, '2026-09-08T08:00:00', '2026-09-08T17:00:00', 1500.00, 3191.60, N'CLOSED'),
        (77, 47, 69, '2026-08-28T08:00:00', '2026-08-28T17:00:00', 2000.00, 4348.32, N'CLOSED'),
        (78, 49, 70, '2026-07-17T08:00:00', '2026-07-17T17:00:00', 1000.00, 9605.22, N'CLOSED'),
        (79, 50, 70, '2026-10-31T08:00:00', '2026-10-31T17:00:00', 1500.00, 5636.52, N'CLOSED'),
        (80, 49, 70, '2026-11-03T08:00:00', '2026-11-03T17:00:00', 2000.00, 5229.89, N'CLOSED'),
        (81, 51, 71, '2026-07-23T08:00:00', '2026-07-23T17:00:00', 1000.00, 8307.21, N'CLOSED'),
        (82, 52, 71, '2026-09-25T08:00:00', '2026-09-25T17:00:00', 1500.00, 6474.00, N'CLOSED'),
        (83, 51, 71, '2026-06-01T08:00:00', '2026-06-01T17:00:00', 2000.00, 9359.66, N'CLOSED'),
        (84, 53, 72, '2026-06-10T08:00:00', '2026-06-10T17:00:00', 1000.00, 1000.00, N'CLOSED'),
        (85, 54, 72, '2026-08-24T08:00:00', '2026-08-24T17:00:00', 1500.00, 15028.67, N'CLOSED'),
        (86, 53, 72, '2026-06-13T08:00:00', '2026-06-13T17:00:00', 2000.00, 6434.10, N'CLOSED'),
        (87, 55, 73, '2026-07-24T08:00:00', '2026-07-24T17:00:00', 1000.00, 11257.01, N'CLOSED'),
        (88, 56, 73, '2026-06-29T08:00:00', '2026-06-29T17:00:00', 1500.00, 10631.02, N'CLOSED'),
        (89, 55, 73, '2026-07-08T08:00:00', '2026-07-08T17:00:00', 2000.00, 6912.30, N'CLOSED');
    SET IDENTITY_INSERT dbo.CashShift OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Bill)
BEGIN
    SET IDENTITY_INSERT dbo.Bill ON;
    INSERT INTO dbo.Bill (Id, BillCode, Person_Id, Store_Id, Employee_Id, CashShift_Id, Channel, Status, SubTotal, DiscountTotal, CouponTotal, TaxTotal, ShippingTotal, Total, RegistrationDate) VALUES
        (1, N'FAC-000001', 76, 28, 71, 83, N'INSTORE', N'PAID', 3000.00, 177.60, 0.00, 423.36, 0.00, 3245.76, '2026-06-01T08:55:55'),
        (2, N'FAC-000002', 113, 28, 71, 83, N'INSTORE', N'PAID', 480.00, 0.00, 0.00, 72.00, 0.00, 552.00, '2026-06-01T11:27:10'),
        (3, N'FAC-000003', 89, 28, 71, 83, N'INSTORE', N'PAID', 630.00, 0.00, 31.50, 94.50, 0.00, 693.00, '2026-06-01T11:49:31'),
        (4, N'FAC-000004', 82, 28, 71, 83, N'INSTORE', N'PAID', 4240.00, 0.00, 0.00, 636.00, 0.00, 4876.00, '2026-06-01T12:06:29'),
        (5, N'FAC-000005', 89, 28, 71, 83, N'INSTORE', N'PAID', 3194.00, 0.00, 0.00, 479.10, 0.00, 3673.10, '2026-06-01T13:04:13'),
        (6, N'FAC-000006', 96, 28, 71, 83, N'INSTORE', N'CANCELLED', 1635.00, 0.00, 0.00, 245.25, 0.00, 1880.25, '2026-06-01T13:25:01'),
        (7, N'FAC-000007', 75, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 1770.00, 312.00, 0.00, 218.70, 80.00, 1756.70, '2026-06-01T15:55:28'),
        (8, N'FAC-000008', 102, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3260.00, 324.00, 0.00, 440.40, 120.00, 3496.40, '2026-06-02T20:28:30'),
        (9, N'FAC-000009', 83, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 1430.00, 0.00, 0.00, 214.50, 80.00, 1724.50, '2026-06-02T21:52:24'),
        (10, N'FAC-000010', 78, 15, 58, 43, N'INSTORE', N'PAID', 4050.00, 0.00, 120.00, 607.50, 0.00, 4537.50, '2026-06-04T09:19:05'),
        (11, N'FAC-000011', 102, 14, 57, 39, N'INSTORE', N'PAID', 3540.00, 0.00, 0.00, 531.00, 0.00, 4071.00, '2026-06-04T09:53:56'),
        (12, N'FAC-000012', 110, 14, 57, 39, N'INSTORE', N'PAID', 4560.00, 0.00, 0.00, 684.00, 0.00, 5244.00, '2026-06-04T11:20:16'),
        (13, N'FAC-000013', 97, 15, 58, 43, N'INSTORE', N'PAID', 1155.00, 0.00, 100.00, 173.25, 0.00, 1228.25, '2026-06-04T12:08:41'),
        (14, N'FAC-000014', 78, 14, 57, 39, N'INSTORE', N'PAID', 3080.00, 0.00, 0.00, 462.00, 0.00, 3542.00, '2026-06-04T13:44:48'),
        (15, N'FAC-000015', 80, 14, 57, 39, N'INSTORE', N'PAID', 7910.00, 0.00, 0.00, 1186.50, 0.00, 9096.50, '2026-06-04T14:48:46'),
        (16, N'FAC-000016', 109, 15, 58, 43, N'INSTORE', N'PAID', 2080.00, 50.40, 0.00, 304.44, 0.00, 2334.04, '2026-06-04T15:18:10'),
        (17, N'FAC-000017', 105, 14, 57, 39, N'INSTORE', N'PAID', 1350.00, 0.00, 0.00, 202.50, 0.00, 1552.50, '2026-06-04T15:29:13'),
        (18, N'FAC-000018', 86, 15, 58, 43, N'INSTORE', N'PAID', 2800.00, 267.30, 0.00, 379.91, 0.00, 2912.61, '2026-06-04T15:39:11'),
        (19, N'FAC-000019', 88, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 960.00, 0.00, 0.00, 144.00, 80.00, 1184.00, '2026-06-06T10:43:21'),
        (20, N'FAC-000020', 75, 24, 67, 69, N'INSTORE', N'PAID', 2618.00, 327.00, 0.00, 343.65, 0.00, 2634.65, '2026-06-06T11:37:08'),
        (21, N'FAC-000021', 113, 24, 67, 69, N'INSTORE', N'PAID', 1610.00, 0.00, 0.00, 241.50, 0.00, 1851.50, '2026-06-06T12:02:54'),
        (22, N'FAC-000022', 101, 24, 67, 69, N'INSTORE', N'PAID', 2210.00, 70.00, 100.00, 321.00, 0.00, 2361.00, '2026-06-06T13:58:15'),
        (23, N'FAC-000023', 109, 24, 67, 69, N'INSTORE', N'PAID', 840.00, 0.00, 0.00, 126.00, 0.00, 966.00, '2026-06-06T14:12:52'),
        (24, N'FAC-000024', 111, 24, 67, 69, N'INSTORE', N'PAID', 2240.00, 0.00, 0.00, 336.00, 0.00, 2576.00, '2026-06-06T15:42:59'),
        (25, N'FAC-000025', 106, 24, 67, 69, N'INSTORE', N'PAID', 5990.00, 1029.00, 0.00, 744.15, 0.00, 5705.15, '2026-06-06T15:45:04'),
        (26, N'FAC-000026', 82, 29, 72, 84, N'INSTORE', N'PAID', 418.00, 0.00, 0.00, 62.70, 0.00, 480.70, '2026-06-10T09:24:51'),
        (27, N'FAC-000027', 104, 29, 72, 84, N'INSTORE', N'PAID', 640.00, 0.00, 0.00, 96.00, 0.00, 736.00, '2026-06-10T11:16:28'),
        (28, N'FAC-000028', 107, 15, 58, 44, N'INSTORE', N'PAID', 4756.00, 496.80, 150.00, 638.88, 0.00, 4748.08, '2026-06-10T13:15:03'),
        (29, N'FAC-000029', 107, 15, 58, 44, N'INSTORE', N'PAID', 1910.00, 210.00, 60.00, 255.00, 0.00, 1895.00, '2026-06-10T15:22:15'),
        (30, N'FAC-000030', 80, 15, 58, 44, N'INSTORE', N'PAID', 2460.00, 0.00, 0.00, 369.00, 0.00, 2829.00, '2026-06-10T15:53:04'),
        (31, N'FAC-000031', 112, 29, 72, 84, N'INSTORE', N'PAID', 640.00, 115.20, 0.00, 78.72, 0.00, 603.52, '2026-06-10T15:53:15'),
        (32, N'FAC-000032', 100, 15, 58, 44, N'INSTORE', N'PAID', 1260.00, 0.00, 0.00, 189.00, 0.00, 1449.00, '2026-06-10T15:54:21'),
        (33, N'FAC-000033', 97, 25, 68, 74, N'INSTORE', N'PAID', 6710.00, 138.00, 0.00, 985.80, 0.00, 7557.80, '2026-06-13T09:26:47'),
        (34, N'FAC-000034', 109, 29, 72, 86, N'INSTORE', N'PAID', 1940.00, 197.00, 0.00, 261.45, 0.00, 2004.45, '2026-06-13T10:43:01'),
        (35, N'FAC-000035', 81, 29, 72, 86, N'INSTORE', N'PAID', 1600.00, 0.00, 0.00, 240.00, 0.00, 1840.00, '2026-06-13T10:43:45'),
        (36, N'FAC-000036', 84, 25, 68, 74, N'INSTORE', N'PAID', 3370.00, 0.00, 0.00, 505.50, 0.00, 3875.50, '2026-06-13T11:09:05'),
        (37, N'FAC-000037', 100, 25, 68, 74, N'INSTORE', N'PAID', 1780.00, 0.00, 0.00, 267.00, 0.00, 2047.00, '2026-06-13T12:48:55'),
        (38, N'FAC-000038', 111, 29, 72, 86, N'INSTORE', N'PAID', 3834.00, 0.00, 0.00, 575.10, 0.00, 4409.10, '2026-06-13T14:12:31'),
        (39, N'FAC-000039', 104, 25, 68, 74, N'INSTORE', N'PAID', 5420.00, 522.00, 0.00, 734.70, 0.00, 5632.70, '2026-06-13T14:56:52'),
        (40, N'FAC-000040', 80, 29, 72, 86, N'INSTORE', N'PAID', 1050.00, 0.00, 0.00, 157.50, 0.00, 1207.50, '2026-06-13T15:59:24'),
        (41, N'FAC-000041', 90, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 1390.00, 0.00, 111.20, 208.50, 80.00, 1567.30, '2026-06-15T14:00:04'),
        (42, N'FAC-000042', 81, 21, 64, 62, N'INSTORE', N'PAID', 3480.00, 0.00, 0.00, 522.00, 0.00, 4002.00, '2026-06-16T10:17:52'),
        (43, N'FAC-000043', 100, 21, 64, 62, N'INSTORE', N'PAID', 4180.00, 0.00, 0.00, 627.00, 0.00, 4807.00, '2026-06-16T11:10:40'),
        (44, N'FAC-000044', 109, 21, 64, 62, N'INSTORE', N'PAID', 1260.00, 210.00, 0.00, 157.50, 0.00, 1207.50, '2026-06-16T12:10:28'),
        (45, N'FAC-000045', 106, 9, 52, 26, N'INSTORE', N'PAID', 2250.00, 0.00, 0.00, 337.50, 0.00, 2587.50, '2026-06-18T13:30:08'),
        (46, N'FAC-000046', 113, 9, 52, 26, N'INSTORE', N'PAID', 3969.00, 217.80, 0.00, 562.68, 0.00, 4313.88, '2026-06-18T13:49:31'),
        (47, N'FAC-000047', 105, 9, 52, 26, N'INSTORE', N'PAID', 4340.00, 594.00, 150.00, 561.90, 0.00, 4157.90, '2026-06-18T15:28:39'),
        (48, N'FAC-000048', 95, 2, NULL, NULL, N'ONLINE', N'SHIPPED', 960.00, 0.00, 0.00, 144.00, 80.00, 1184.00, '2026-06-19T00:49:50'),
        (49, N'FAC-000049', 82, 2, NULL, NULL, N'ONLINE', N'CANCELLED', 2980.00, 0.00, 0.00, 447.00, 0.00, 3427.00, '2026-06-19T18:02:10'),
        (50, N'FAC-000050', 114, 25, 68, 72, N'INSTORE', N'PAID', 4656.00, 343.20, 0.00, 646.92, 0.00, 4959.72, '2026-06-21T09:37:54'),
        (51, N'FAC-000051', 108, 25, 68, 72, N'INSTORE', N'PAID', 4380.00, 355.20, 0.00, 603.72, 0.00, 4628.52, '2026-06-21T09:38:12'),
        (52, N'FAC-000052', 111, 25, 68, 72, N'INSTORE', N'PAID', 4070.00, 276.00, 0.00, 569.10, 0.00, 4363.10, '2026-06-21T11:27:36'),
        (53, N'FAC-000053', 98, 25, 68, 72, N'INSTORE', N'CANCELLED', 420.00, 0.00, 0.00, 63.00, 0.00, 483.00, '2026-06-21T14:41:20'),
        (54, N'FAC-000054', 79, 23, 66, 66, N'INSTORE', N'PAID', 1626.00, 0.00, 0.00, 243.90, 0.00, 1869.90, '2026-06-23T09:46:55'),
        (55, N'FAC-000055', 76, 23, 66, 66, N'INSTORE', N'PAID', 3680.00, 0.00, 0.00, 552.00, 0.00, 4232.00, '2026-06-23T10:53:02'),
        (56, N'FAC-000056', 98, 23, 66, 66, N'INSTORE', N'PAID', 4492.00, 0.00, 0.00, 673.80, 0.00, 5165.80, '2026-06-23T11:24:05'),
        (57, N'FAC-000057', 99, 18, 61, 52, N'INSTORE', N'PAID', 2170.00, 0.00, 108.50, 325.50, 0.00, 2387.00, '2026-06-23T11:41:45'),
        (58, N'FAC-000058', 103, 18, 61, 52, N'INSTORE', N'PAID', 4590.00, 132.00, 0.00, 668.70, 0.00, 5126.70, '2026-06-23T11:57:12'),
        (59, N'FAC-000059', 113, 18, 61, 52, N'INSTORE', N'PAID', 5590.00, 0.00, 0.00, 838.50, 0.00, 6428.50, '2026-06-23T11:57:31'),
        (60, N'FAC-000060', 80, 18, 61, 52, N'INSTORE', N'PAID', 2520.00, 0.00, 100.00, 378.00, 0.00, 2798.00, '2026-06-23T12:37:07'),
        (61, N'FAC-000061', 102, 18, 61, 52, N'INSTORE', N'PAID', 7560.00, 486.00, 0.00, 1061.10, 0.00, 8135.10, '2026-06-23T13:39:23'),
        (62, N'FAC-000062', 94, 23, 66, 66, N'INSTORE', N'CANCELLED', 1480.00, 177.60, 0.00, 195.36, 0.00, 1497.76, '2026-06-23T13:57:05'),
        (63, N'FAC-000063', 83, 23, 66, 66, N'INSTORE', N'PAID', 4020.00, 0.00, 0.00, 603.00, 0.00, 4623.00, '2026-06-23T14:24:06'),
        (64, N'FAC-000064', 75, 18, 61, 52, N'INSTORE', N'PAID', 2870.00, 0.00, 0.00, 430.50, 0.00, 3300.50, '2026-06-23T14:54:38'),
        (65, N'FAC-000065', 94, 23, 66, 66, N'INSTORE', N'PAID', 3459.00, 0.00, 0.00, 518.85, 0.00, 3977.85, '2026-06-23T15:11:11'),
        (66, N'FAC-000066', 79, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3450.00, 0.00, 0.00, 517.50, 80.00, 4047.50, '2026-06-24T20:48:35'),
        (67, N'FAC-000067', 111, 13, 56, 37, N'INSTORE', N'PAID', 3156.00, 0.00, 0.00, 473.40, 0.00, 3629.40, '2026-06-26T08:53:30'),
        (68, N'FAC-000068', 103, 13, 56, 37, N'INSTORE', N'PAID', 3641.00, 0.00, 100.00, 546.15, 0.00, 4087.15, '2026-06-26T10:23:16'),
        (69, N'FAC-000069', 109, 13, 56, 37, N'INSTORE', N'PAID', 1600.00, 0.00, 0.00, 240.00, 0.00, 1840.00, '2026-06-26T11:34:48'),
        (70, N'FAC-000070', 85, 13, 56, 37, N'INSTORE', N'PAID', 2904.00, 230.40, 213.89, 401.04, 0.00, 2860.75, '2026-06-26T13:50:26'),
        (71, N'FAC-000071', 99, 2, NULL, NULL, N'ONLINE', N'SHIPPED', 4980.00, 471.20, 0.00, 676.32, 50.00, 5235.12, '2026-06-28T17:25:39'),
        (72, N'FAC-000072', 102, 30, 73, 88, N'INSTORE', N'PAID', 1800.00, 198.00, 0.00, 240.30, 0.00, 1842.30, '2026-06-29T09:32:44'),
        (73, N'FAC-000073', 78, 30, 73, 88, N'INSTORE', N'PAID', 5700.00, 270.00, 0.00, 814.50, 0.00, 6244.50, '2026-06-29T10:25:42'),
        (74, N'FAC-000074', 82, 17, 60, 49, N'INSTORE', N'PAID', 2145.00, 263.10, 0.00, 282.29, 0.00, 2164.19, '2026-06-29T10:47:24'),
        (75, N'FAC-000075', 106, 30, 73, 88, N'INSTORE', N'PAID', 2700.00, 205.20, 0.00, 374.22, 0.00, 2869.02, '2026-06-29T11:50:47'),
        (76, N'FAC-000076', 106, 30, 73, 88, N'INSTORE', N'PAID', 380.00, 0.00, 0.00, 57.00, 0.00, 437.00, '2026-06-29T12:24:34'),
        (77, N'FAC-000077', 87, 17, 60, 49, N'INSTORE', N'PAID', 3582.00, 0.00, 0.00, 537.30, 0.00, 4119.30, '2026-06-29T12:46:09'),
        (78, N'FAC-000078', 113, 17, 60, 49, N'INSTORE', N'PAID', 3330.00, 0.00, 166.50, 499.50, 0.00, 3663.00, '2026-06-29T13:37:54'),
        (79, N'FAC-000079', 106, 30, 73, 88, N'INSTORE', N'PAID', 240.00, 0.00, 0.00, 36.00, 0.00, 276.00, '2026-06-29T13:52:37'),
        (80, N'FAC-000080', 100, 30, 73, 88, N'INSTORE', N'PAID', 2574.00, 0.00, 0.00, 386.10, 0.00, 2960.10, '2026-06-29T14:31:22'),
        (81, N'FAC-000081', 84, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 2700.00, 220.00, 124.00, 372.00, 50.00, 2778.00, '2026-07-01T03:01:05'),
        (82, N'FAC-000082', 80, 6, 49, 13, N'INSTORE', N'PAID', 720.00, 72.00, 0.00, 97.20, 0.00, 745.20, '2026-07-02T11:27:15'),
        (83, N'FAC-000083', 84, 6, 49, 13, N'INSTORE', N'PAID', 2305.00, 77.00, 0.00, 334.20, 0.00, 2562.20, '2026-07-02T12:04:47'),
        (84, N'FAC-000084', 90, 6, 49, 13, N'INSTORE', N'PAID', 726.00, 0.00, 120.00, 108.90, 0.00, 714.90, '2026-07-02T13:13:18'),
        (85, N'FAC-000085', 109, 6, 49, 13, N'INSTORE', N'PAID', 2536.00, 0.00, 0.00, 380.40, 0.00, 2916.40, '2026-07-02T15:02:20'),
        (86, N'FAC-000086', 75, 6, 49, 13, N'INSTORE', N'PAID', 3385.00, 77.00, 0.00, 496.20, 0.00, 3804.20, '2026-07-02T15:39:57'),
        (87, N'FAC-000087', 75, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 6036.00, 544.80, 0.00, 823.68, 120.00, 6434.88, '2026-07-03T01:47:23'),
        (88, N'FAC-000088', 86, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 4410.00, 0.00, 0.00, 661.50, 80.00, 5151.50, '2026-07-03T10:07:55'),
        (89, N'FAC-000089', 90, 12, 55, 34, N'INSTORE', N'PAID', 3300.00, 480.60, 0.00, 422.91, 0.00, 3242.31, '2026-07-03T10:41:45'),
        (90, N'FAC-000090', 100, 12, 55, 34, N'INSTORE', N'PAID', 5990.00, 0.00, 0.00, 898.50, 0.00, 6888.50, '2026-07-03T13:36:27'),
        (91, N'FAC-000091', 100, 12, 55, 34, N'INSTORE', N'PAID', 3600.00, 0.00, 0.00, 540.00, 0.00, 4140.00, '2026-07-03T15:19:55'),
        (92, N'FAC-000092', 105, 15, 58, 42, N'INSTORE', N'PAID', 2630.00, 0.00, 0.00, 394.50, 0.00, 3024.50, '2026-07-05T09:20:25'),
        (93, N'FAC-000093', 102, 15, 58, 42, N'INSTORE', N'PAID', 990.00, 0.00, 0.00, 148.50, 0.00, 1138.50, '2026-07-05T11:26:02'),
        (94, N'FAC-000094', 80, 15, 58, 42, N'INSTORE', N'PAID', 1085.00, 217.00, 0.00, 130.20, 0.00, 998.20, '2026-07-05T11:55:21'),
        (95, N'FAC-000095', 109, 15, 58, 42, N'INSTORE', N'PAID', 960.00, 0.00, 0.00, 144.00, 0.00, 1104.00, '2026-07-05T14:02:26'),
        (96, N'FAC-000096', 110, 15, 58, 42, N'INSTORE', N'PAID', 473.00, 0.00, 0.00, 70.95, 0.00, 543.95, '2026-07-05T14:24:39'),
        (97, N'FAC-000097', 105, 15, 58, 42, N'INSTORE', N'PAID', 860.00, 0.00, 0.00, 129.00, 0.00, 989.00, '2026-07-05T14:29:10'),
        (98, N'FAC-000098', 102, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 4050.00, 486.00, 0.00, 534.60, 80.00, 4178.60, '2026-07-05T23:05:35'),
        (99, N'FAC-000099', 98, 2, NULL, NULL, N'ONLINE', N'PAID', 2960.00, 355.20, 0.00, 390.72, 50.00, 3045.52, '2026-07-05T23:31:27'),
        (100, N'FAC-000100', 104, 30, 73, 89, N'INSTORE', N'PAID', 3980.00, 0.00, 0.00, 597.00, 0.00, 4577.00, '2026-07-08T09:34:18'),
        (101, N'FAC-000101', 114, 30, 73, 89, N'INSTORE', N'PAID', 290.00, 0.00, 23.20, 43.50, 0.00, 310.30, '2026-07-08T10:40:09'),
        (102, N'FAC-000102', 97, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 840.00, 100.80, 0.00, 110.88, 50.00, 900.08, '2026-07-09T12:08:22'),
        (103, N'FAC-000103', 78, 18, 61, 53, N'INSTORE', N'PAID', 4050.00, 486.00, 0.00, 534.60, 0.00, 4098.60, '2026-07-10T09:49:11'),
        (104, N'FAC-000104', 101, 18, 61, 53, N'INSTORE', N'PAID', 4770.00, 501.60, 0.00, 640.26, 0.00, 4908.66, '2026-07-10T12:32:56'),
        (105, N'FAC-000105', 98, 18, 61, 53, N'INSTORE', N'PAID', 420.00, 75.60, 0.00, 51.66, 0.00, 396.06, '2026-07-10T14:58:25'),
        (106, N'FAC-000106', 83, 18, 61, 53, N'INSTORE', N'PAID', 3980.00, 0.00, 0.00, 597.00, 0.00, 4577.00, '2026-07-10T15:56:30'),
        (107, N'FAC-000107', 76, 5, 48, 10, N'INSTORE', N'PAID', 4230.00, 0.00, 0.00, 634.50, 0.00, 4864.50, '2026-07-11T10:38:26'),
        (108, N'FAC-000108', 94, 5, 48, 10, N'INSTORE', N'PAID', 3820.00, 0.00, 0.00, 573.00, 0.00, 4393.00, '2026-07-11T11:10:18'),
        (109, N'FAC-000109', 75, 22, 65, 64, N'INSTORE', N'PAID', 1590.00, 300.20, 0.00, 193.47, 0.00, 1483.27, '2026-07-13T10:07:26'),
        (110, N'FAC-000110', 75, 22, 65, 64, N'INSTORE', N'PAID', 7840.00, 160.20, 0.00, 1151.97, 0.00, 8831.77, '2026-07-13T10:14:03'),
        (111, N'FAC-000111', 75, 2, NULL, NULL, N'ONLINE', N'PENDING', 4108.00, 302.40, 380.56, 570.84, 0.00, 3995.88, '2026-07-14T03:19:56'),
        (112, N'FAC-000112', 106, 2, NULL, NULL, N'ONLINE', N'PAID', 1920.00, 0.00, 0.00, 288.00, 80.00, 2288.00, '2026-07-15T12:43:06'),
        (113, N'FAC-000113', 87, 27, 70, 78, N'INSTORE', N'PAID', 1610.00, 0.00, 0.00, 241.50, 0.00, 1851.50, '2026-07-17T08:38:36'),
        (114, N'FAC-000114', 94, 27, 70, 78, N'INSTORE', N'PAID', 3100.00, 285.60, 0.00, 422.16, 0.00, 3236.56, '2026-07-17T08:41:30'),
        (115, N'FAC-000115', 105, 27, 70, 78, N'INSTORE', N'PAID', 4870.00, 201.60, 0.00, 700.26, 0.00, 5368.66, '2026-07-17T12:20:13'),
        (116, N'FAC-000116', 113, 7, 50, 19, N'INSTORE', N'PAID', 4800.00, 0.00, 0.00, 720.00, 0.00, 5520.00, '2026-07-18T10:37:46'),
        (117, N'FAC-000117', 107, 7, 50, 19, N'INSTORE', N'PAID', 4070.00, 0.00, 0.00, 610.50, 0.00, 4680.50, '2026-07-18T11:22:28'),
        (118, N'FAC-000118', 98, 7, 50, 19, N'INSTORE', N'PAID', 3270.00, 156.00, 0.00, 467.10, 0.00, 3581.10, '2026-07-18T15:33:57'),
        (119, N'FAC-000119', 103, 7, 50, 19, N'INSTORE', N'PAID', 6045.00, 861.30, 0.00, 777.56, 0.00, 5961.26, '2026-07-18T15:55:19'),
        (120, N'FAC-000120', 18, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 2960.00, 296.00, 0.00, 399.60, 120.00, 3183.60, '2026-07-19T00:49:05'),
        (121, N'FAC-000121', 81, 2, NULL, NULL, N'ONLINE', N'SHIPPED', 2190.00, 312.00, 0.00, 281.70, 80.00, 2239.70, '2026-07-20T08:38:40'),
        (122, N'FAC-000122', 76, 14, 57, 40, N'INSTORE', N'PAID', 720.00, 72.00, 60.00, 97.20, 0.00, 685.20, '2026-07-20T10:43:02'),
        (123, N'FAC-000123', 78, 14, 57, 40, N'INSTORE', N'PAID', 980.00, 0.00, 0.00, 147.00, 0.00, 1127.00, '2026-07-20T13:23:54'),
        (124, N'FAC-000124', 88, 14, 57, 40, N'INSTORE', N'PAID', 3750.00, 0.00, 262.50, 562.50, 0.00, 4050.00, '2026-07-20T15:21:32'),
        (125, N'FAC-000125', 109, 21, 64, 60, N'INSTORE', N'PAID', 2630.00, 0.00, 60.00, 394.50, 0.00, 2964.50, '2026-07-22T09:59:34'),
        (126, N'FAC-000126', 77, 21, 64, 60, N'INSTORE', N'PAID', 1820.00, 140.00, 0.00, 252.00, 0.00, 1932.00, '2026-07-22T11:23:27'),
        (127, N'FAC-000127', 101, 21, 64, 60, N'INSTORE', N'PAID', 5475.00, 861.30, 0.00, 692.06, 0.00, 5305.76, '2026-07-22T11:44:44'),
        (128, N'FAC-000128', 114, 28, 71, 81, N'INSTORE', N'PAID', 4315.00, 148.00, 0.00, 625.05, 0.00, 4792.05, '2026-07-23T09:07:37'),
        (129, N'FAC-000129', 98, 28, 71, 81, N'INSTORE', N'PAID', 1840.00, 76.00, 0.00, 264.60, 0.00, 2028.60, '2026-07-23T10:30:23'),
        (130, N'FAC-000130', 97, 28, 71, 81, N'INSTORE', N'PAID', 1120.00, 0.00, 0.00, 168.00, 0.00, 1288.00, '2026-07-23T12:40:35'),
        (131, N'FAC-000131', 80, 2, NULL, NULL, N'ONLINE', N'SHIPPED', 1880.00, 0.00, 0.00, 282.00, 120.00, 2282.00, '2026-07-23T23:41:17'),
        (132, N'FAC-000132', 80, 30, 73, 87, N'INSTORE', N'PAID', 1730.00, 154.00, 0.00, 236.40, 0.00, 1812.40, '2026-07-24T10:19:45'),
        (133, N'FAC-000133', 81, 30, 73, 87, N'INSTORE', N'PAID', 7170.00, 783.00, 0.00, 958.05, 0.00, 7345.05, '2026-07-24T11:36:10'),
        (134, N'FAC-000134', 100, 3, 46, 3, N'INSTORE', N'PAID', 3130.00, 455.40, 0.00, 401.19, 0.00, 3075.79, '2026-07-24T12:00:10'),
        (135, N'FAC-000135', 82, 30, 73, 87, N'INSTORE', N'PAID', 3350.00, 522.00, 0.00, 424.20, 0.00, 3252.20, '2026-07-24T12:28:53'),
        (136, N'FAC-000136', 87, 30, 73, 87, N'INSTORE', N'PAID', 3330.00, 154.00, 0.00, 476.40, 0.00, 3652.40, '2026-07-24T13:20:52'),
        (137, N'FAC-000137', 108, 3, 46, 3, N'INSTORE', N'CANCELLED', 2540.00, 0.00, 0.00, 381.00, 0.00, 2921.00, '2026-07-24T14:08:19'),
        (138, N'FAC-000138', 78, 30, 73, 87, N'INSTORE', N'PAID', 5025.00, 841.00, 0.00, 627.60, 0.00, 4811.60, '2026-07-24T15:17:10'),
        (139, N'FAC-000139', 95, 2, NULL, NULL, N'ONLINE', N'PENDING', 1520.00, 0.00, 0.00, 228.00, 0.00, 1748.00, '2026-07-27T14:35:34'),
        (140, N'FAC-000140', 76, 16, 59, 45, N'INSTORE', N'PAID', 840.00, 0.00, 0.00, 126.00, 0.00, 966.00, '2026-07-29T08:52:56'),
        (141, N'FAC-000141', 82, 16, 59, 45, N'INSTORE', N'PAID', 4790.00, 282.00, 0.00, 676.20, 0.00, 5184.20, '2026-07-29T14:45:34'),
        (142, N'FAC-000142', 91, 2, NULL, NULL, N'ONLINE', N'SHIPPED', 1280.00, 230.40, 62.98, 157.44, 80.00, 1224.06, '2026-07-30T03:49:23'),
        (143, N'FAC-000143', 78, 19, 62, 56, N'INSTORE', N'PAID', 4016.00, 0.00, 401.60, 602.40, 0.00, 4216.80, '2026-07-31T08:47:36'),
        (144, N'FAC-000144', 112, 19, 62, 56, N'INSTORE', N'PAID', 5496.00, 444.00, 0.00, 757.80, 0.00, 5809.80, '2026-07-31T08:59:13'),
        (145, N'FAC-000145', 77, 19, 62, 56, N'INSTORE', N'PAID', 3542.00, 0.00, 0.00, 531.30, 0.00, 4073.30, '2026-07-31T09:16:57'),
        (146, N'FAC-000146', 83, 4, 47, 7, N'INSTORE', N'PAID', 2638.00, 0.00, 0.00, 395.70, 0.00, 3033.70, '2026-07-31T09:40:16'),
        (147, N'FAC-000147', 91, 19, 62, 56, N'INSTORE', N'PAID', 4440.00, 0.00, 0.00, 666.00, 0.00, 5106.00, '2026-07-31T14:57:00'),
        (148, N'FAC-000148', 101, 19, 62, 56, N'INSTORE', N'PAID', 3642.00, 79.20, 213.77, 534.42, 0.00, 3883.45, '2026-07-31T15:03:51'),
        (149, N'FAC-000149', 97, 4, 47, 7, N'INSTORE', N'PAID', 1780.00, 320.40, 0.00, 218.94, 0.00, 1678.54, '2026-07-31T15:21:37'),
        (150, N'FAC-000150', 111, 19, 62, 56, N'INSTORE', N'PAID', 4440.00, 0.00, 0.00, 666.00, 0.00, 5106.00, '2026-07-31T15:22:30'),
        (151, N'FAC-000151', 98, 3, 46, 2, N'INSTORE', N'PAID', 890.00, 160.20, 0.00, 109.47, 0.00, 839.27, '2026-08-01T08:31:14'),
        (152, N'FAC-000152', 95, 3, 46, 2, N'INSTORE', N'PAID', 1470.00, 226.80, 0.00, 186.48, 0.00, 1429.68, '2026-08-01T09:42:02'),
        (153, N'FAC-000153', 108, 3, 46, 2, N'INSTORE', N'PAID', 3980.00, 442.80, 0.00, 530.58, 0.00, 4067.78, '2026-08-01T11:14:22'),
        (154, N'FAC-000154', 105, 3, 46, 2, N'INSTORE', N'PAID', 4970.00, 207.00, 0.00, 714.45, 0.00, 5477.45, '2026-08-01T13:36:30'),
        (155, N'FAC-000155', 112, 3, 46, 2, N'INSTORE', N'PAID', 5880.00, 0.00, 0.00, 882.00, 0.00, 6762.00, '2026-08-01T15:19:10'),
        (156, N'FAC-000156', 111, 3, 46, 2, N'INSTORE', N'PAID', 4400.00, 0.00, 660.00, 660.00, 0.00, 4400.00, '2026-08-01T15:45:52'),
        (157, N'FAC-000157', 82, 10, 53, 28, N'INSTORE', N'CANCELLED', 3250.00, 0.00, 0.00, 487.50, 0.00, 3737.50, '2026-08-03T11:09:19'),
        (158, N'FAC-000158', 87, 10, 53, 28, N'INSTORE', N'PAID', 1440.00, 0.00, 0.00, 216.00, 0.00, 1656.00, '2026-08-03T11:54:44'),
        (159, N'FAC-000159', 96, 10, 53, 28, N'INSTORE', N'PAID', 3080.00, 0.00, 0.00, 462.00, 0.00, 3542.00, '2026-08-03T12:56:11'),
        (160, N'FAC-000160', 89, 10, 53, 28, N'INSTORE', N'PAID', 950.00, 0.00, 0.00, 142.50, 0.00, 1092.50, '2026-08-03T15:25:36'),
        (161, N'FAC-000161', 81, 10, 53, 28, N'INSTORE', N'PAID', 3670.00, 480.00, 159.50, 478.50, 0.00, 3509.00, '2026-08-03T15:49:14'),
        (162, N'FAC-000162', 91, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 840.00, 0.00, 0.00, 126.00, 120.00, 1086.00, '2026-08-07T10:36:36'),
        (163, N'FAC-000163', 95, 2, NULL, NULL, N'ONLINE', N'SHIPPED', 2510.00, 0.00, 0.00, 376.50, 50.00, 2936.50, '2026-08-07T21:18:55'),
        (164, N'FAC-000164', 82, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3012.00, 510.40, 0.00, 375.24, 50.00, 2926.84, '2026-08-09T02:35:08'),
        (165, N'FAC-000165', 91, 24, 67, 70, N'INSTORE', N'PAID', 310.00, 0.00, 0.00, 46.50, 0.00, 356.50, '2026-08-11T11:47:32'),
        (166, N'FAC-000166', 102, 24, 67, 70, N'INSTORE', N'PAID', 1570.00, 226.80, 0.00, 201.48, 0.00, 1544.68, '2026-08-11T15:28:42'),
        (167, N'FAC-000167', 94, 11, 54, 31, N'INSTORE', N'CANCELLED', 1080.00, 0.00, 0.00, 162.00, 0.00, 1242.00, '2026-08-16T09:03:08'),
        (168, N'FAC-000168', 95, 11, 54, 31, N'INSTORE', N'PAID', 3480.00, 355.20, 0.00, 468.72, 0.00, 3593.52, '2026-08-16T13:12:38'),
        (169, N'FAC-000169', 98, 11, 54, 31, N'INSTORE', N'PAID', 2220.00, 0.00, 0.00, 333.00, 0.00, 2553.00, '2026-08-16T14:49:25'),
        (170, N'FAC-000170', 107, 11, 54, 31, N'INSTORE', N'PAID', 520.00, 104.00, 0.00, 62.40, 0.00, 478.40, '2026-08-16T14:52:55'),
        (171, N'FAC-000171', 80, 11, 54, 31, N'INSTORE', N'PAID', 1320.00, 198.00, 0.00, 168.30, 0.00, 1290.30, '2026-08-16T15:37:53'),
        (172, N'FAC-000172', 105, 13, 56, 38, N'INSTORE', N'PAID', 682.00, 0.00, 0.00, 102.30, 0.00, 784.30, '2026-08-17T08:40:06'),
        (173, N'FAC-000173', 86, 6, 49, 14, N'INSTORE', N'PAID', 2760.00, 446.40, 0.00, 347.04, 0.00, 2660.64, '2026-08-17T08:44:14'),
        (174, N'FAC-000174', 98, 13, 56, 38, N'INSTORE', N'PAID', 4818.00, 594.00, 0.00, 633.60, 0.00, 4857.60, '2026-08-17T09:04:23'),
        (175, N'FAC-000175', 87, 13, 56, 38, N'INSTORE', N'PAID', 5270.00, 768.00, 0.00, 675.30, 0.00, 5177.30, '2026-08-17T11:03:51'),
        (176, N'FAC-000176', 75, 13, 56, 38, N'INSTORE', N'PAID', 1570.00, 160.20, 0.00, 211.47, 0.00, 1621.27, '2026-08-17T14:52:40'),
        (177, N'FAC-000177', 87, 6, 49, 14, N'INSTORE', N'PAID', 3295.00, 217.80, 153.86, 461.58, 0.00, 3384.92, '2026-08-17T15:02:00'),
        (178, N'FAC-000178', 76, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 1260.00, 0.00, 0.00, 189.00, 80.00, 1529.00, '2026-08-17T20:32:31'),
        (179, N'FAC-000179', 89, 3, 46, 1, N'INSTORE', N'PAID', 1990.00, 0.00, 99.50, 298.50, 0.00, 2189.00, '2026-08-18T09:56:51'),
        (180, N'FAC-000180', 89, 3, 46, 1, N'INSTORE', N'PAID', 4460.00, 0.00, 0.00, 669.00, 0.00, 5129.00, '2026-08-18T10:49:52'),
        (181, N'FAC-000181', 91, 3, 46, 1, N'INSTORE', N'PAID', 4050.00, 0.00, 607.50, 607.50, 0.00, 4050.00, '2026-08-18T14:04:48'),
        (182, N'FAC-000182', 104, 3, 46, 1, N'INSTORE', N'PAID', 420.00, 0.00, 0.00, 63.00, 0.00, 483.00, '2026-08-18T14:16:59'),
        (183, N'FAC-000183', 107, 3, 46, 1, N'INSTORE', N'PAID', 5370.00, 324.00, 0.00, 756.90, 0.00, 5802.90, '2026-08-18T14:36:11'),
        (184, N'FAC-000184', 105, 3, 46, 1, N'INSTORE', N'PAID', 1890.00, 75.60, 0.00, 272.16, 0.00, 2086.56, '2026-08-18T15:16:26'),
        (185, N'FAC-000185', 104, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 480.00, 0.00, 0.00, 72.00, 120.00, 672.00, '2026-08-18T23:12:30'),
        (186, N'FAC-000186', 79, 2, NULL, NULL, N'ONLINE', N'SHIPPED', 210.00, 0.00, 0.00, 31.50, 80.00, 321.50, '2026-08-19T02:45:19'),
        (187, N'FAC-000187', 79, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 4520.00, 0.00, 0.00, 678.00, 120.00, 5318.00, '2026-08-19T18:14:57'),
        (188, N'FAC-000188', 94, 23, 66, 67, N'INSTORE', N'PAID', 836.00, 0.00, 0.00, 125.40, 0.00, 961.40, '2026-08-20T11:00:10'),
        (189, N'FAC-000189', 75, 23, 66, 67, N'INSTORE', N'PAID', 3406.00, 198.00, 0.00, 481.20, 0.00, 3689.20, '2026-08-20T13:32:59'),
        (190, N'FAC-000190', 101, 23, 66, 67, N'INSTORE', N'PAID', 6160.00, 480.00, 0.00, 852.00, 0.00, 6532.00, '2026-08-20T13:39:02'),
        (191, N'FAC-000191', 94, 8, 51, 22, N'INSTORE', N'PAID', 700.00, 140.00, 0.00, 84.00, 0.00, 644.00, '2026-08-20T13:47:05'),
        (192, N'FAC-000192', 114, 23, 66, 67, N'INSTORE', N'PAID', 4320.00, 0.00, 345.60, 648.00, 0.00, 4622.40, '2026-08-20T13:47:45'),
        (193, N'FAC-000193', 76, 8, 51, 22, N'INSTORE', N'PAID', 6310.00, 1355.00, 0.00, 743.25, 0.00, 5698.25, '2026-08-20T14:46:17'),
        (194, N'FAC-000194', 98, 8, 51, 22, N'INSTORE', N'PAID', 2050.00, 100.80, 0.00, 292.38, 0.00, 2241.58, '2026-08-20T14:53:15'),
        (195, N'FAC-000195', 82, 19, 62, 55, N'INSTORE', N'PAID', 3510.00, 417.00, 0.00, 463.95, 0.00, 3556.95, '2026-08-21T11:30:07'),
        (196, N'FAC-000196', 80, 19, 62, 55, N'INSTORE', N'PAID', 2772.00, 380.16, 0.00, 358.78, 0.00, 2750.62, '2026-08-21T12:05:31'),
        (197, N'FAC-000197', 19, 2, NULL, NULL, N'ONLINE', N'PENDING', 1920.00, 259.20, 0.00, 249.12, 0.00, 1909.92, '2026-08-22T00:57:41'),
        (198, N'FAC-000198', 100, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3960.00, 0.00, 120.00, 594.00, 80.00, 4514.00, '2026-08-23T13:49:49'),
        (199, N'FAC-000199', 46, 2, NULL, NULL, N'ONLINE', N'PAID', 5950.00, 486.00, 0.00, 819.60, 80.00, 6363.60, '2026-08-23T15:33:29'),
        (200, N'FAC-000200', 105, 29, 72, 85, N'INSTORE', N'PAID', 1920.00, 345.60, 0.00, 236.16, 0.00, 1810.56, '2026-08-24T08:48:11'),
        (201, N'FAC-000201', 75, 29, 72, 85, N'INSTORE', N'PAID', 6554.00, 0.00, 0.00, 983.10, 0.00, 7537.10, '2026-08-24T11:47:49'),
        (202, N'FAC-000202', 80, 29, 72, 85, N'INSTORE', N'PAID', 3270.00, 205.20, 0.00, 459.72, 0.00, 3524.52, '2026-08-24T12:10:41'),
        (203, N'FAC-000203', 93, 29, 72, 85, N'INSTORE', N'PAID', 4344.00, 336.00, 0.00, 601.20, 0.00, 4609.20, '2026-08-24T12:39:59'),
        (204, N'FAC-000204', 81, 29, 72, 85, N'INSTORE', N'CANCELLED', 2136.00, 50.40, 0.00, 312.84, 0.00, 2398.44, '2026-08-24T13:29:25'),
        (205, N'FAC-000205', 86, 29, 72, 85, N'INSTORE', N'PAID', 1570.00, 174.00, 0.00, 209.40, 0.00, 1605.40, '2026-08-24T15:58:38'),
        (206, N'FAC-000206', 97, 2, NULL, NULL, N'ONLINE', N'CANCELLED', 4620.00, 0.00, 0.00, 693.00, 0.00, 5313.00, '2026-08-25T08:54:06'),
        (207, N'FAC-000207', 98, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 520.00, 0.00, 0.00, 78.00, 80.00, 678.00, '2026-08-26T08:54:42'),
        (208, N'FAC-000208', 81, 20, 63, 59, N'INSTORE', N'PAID', 9995.00, 2285.10, 0.00, 1156.49, 0.00, 8866.39, '2026-08-26T10:53:31'),
        (209, N'FAC-000209', 81, 20, 63, 59, N'INSTORE', N'PAID', 8020.00, 1215.00, 0.00, 1020.75, 0.00, 7825.75, '2026-08-26T12:07:30'),
        (210, N'FAC-000210', 76, 17, 60, 48, N'INSTORE', N'PAID', 1900.00, 0.00, 0.00, 285.00, 0.00, 2185.00, '2026-08-27T08:57:06'),
        (211, N'FAC-000211', 108, 17, 60, 48, N'INSTORE', N'PAID', 1780.00, 0.00, 120.00, 267.00, 0.00, 1927.00, '2026-08-27T13:20:01'),
        (212, N'FAC-000212', 100, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 720.00, 0.00, 0.00, 108.00, 120.00, 948.00, '2026-08-27T20:26:51'),
        (213, N'FAC-000213', 95, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 6564.00, 1916.40, 0.00, 697.14, 120.00, 5464.74, '2026-08-28T12:52:24'),
        (214, N'FAC-000214', 112, 26, 69, 77, N'INSTORE', N'PAID', 2294.00, 273.72, 0.00, 303.04, 0.00, 2323.32, '2026-08-28T12:52:47'),
        (215, N'FAC-000215', 103, 26, 69, 77, N'INSTORE', N'CANCELLED', 1660.00, 198.00, 0.00, 219.30, 0.00, 1681.30, '2026-08-28T13:41:46'),
        (216, N'FAC-000216', 84, 26, 69, 77, N'INSTORE', N'PAID', 1180.00, 0.00, 0.00, 177.00, 0.00, 1357.00, '2026-08-28T15:52:23'),
        (217, N'FAC-000217', 79, 2, NULL, NULL, N'ONLINE', N'PAID', 1350.00, 0.00, 0.00, 202.50, 120.00, 1672.50, '2026-09-02T21:37:02'),
        (218, N'FAC-000218', 79, 12, 55, 33, N'INSTORE', N'PAID', 3394.00, 0.00, 203.64, 509.10, 0.00, 3699.46, '2026-09-04T11:14:11'),
        (219, N'FAC-000219', 84, 12, 55, 33, N'INSTORE', N'PAID', 2100.00, 177.60, 288.36, 288.36, 0.00, 1922.40, '2026-09-04T11:30:10'),
        (220, N'FAC-000220', 81, 12, 55, 33, N'INSTORE', N'PAID', 5290.00, 960.00, 120.00, 649.50, 0.00, 4859.50, '2026-09-04T13:04:00'),
        (221, N'FAC-000221', 94, 12, 55, 33, N'INSTORE', N'PAID', 3200.00, 0.00, 320.00, 480.00, 0.00, 3360.00, '2026-09-04T13:59:54'),
        (222, N'FAC-000222', 97, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3776.00, 285.00, 0.00, 523.65, 50.00, 4064.65, '2026-09-06T23:05:05'),
        (223, N'FAC-000223', 94, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3740.00, 24.00, 0.00, 557.40, 120.00, 4393.40, '2026-09-07T04:47:01'),
        (224, N'FAC-000224', 79, 22, 65, 63, N'INSTORE', N'PAID', 1980.00, 0.00, 198.00, 297.00, 0.00, 2079.00, '2026-09-07T08:36:21'),
        (225, N'FAC-000225', 94, 22, 65, 63, N'INSTORE', N'PAID', 5180.00, 1194.00, 0.00, 597.90, 0.00, 4583.90, '2026-09-07T09:15:38'),
        (226, N'FAC-000226', 81, 11, 54, 32, N'INSTORE', N'PAID', 840.00, 151.20, 0.00, 103.32, 0.00, 792.12, '2026-09-07T09:16:54'),
        (227, N'FAC-000227', 91, 11, 54, 32, N'INSTORE', N'PAID', 3050.00, 0.00, 0.00, 457.50, 0.00, 3507.50, '2026-09-07T09:52:15'),
        (228, N'FAC-000228', 75, 11, 54, 32, N'INSTORE', N'PAID', 4060.00, 793.20, 0.00, 490.02, 0.00, 3756.82, '2026-09-07T09:56:54'),
        (229, N'FAC-000229', 98, 22, 65, 63, N'INSTORE', N'PAID', 5790.00, 1143.00, 0.00, 697.05, 0.00, 5344.05, '2026-09-07T11:14:07'),
        (230, N'FAC-000230', 95, 22, 65, 63, N'INSTORE', N'PAID', 980.00, 0.00, 0.00, 147.00, 0.00, 1127.00, '2026-09-07T12:51:00'),
        (231, N'FAC-000231', 86, 11, 54, 32, N'INSTORE', N'PAID', 5850.00, 532.80, 0.00, 797.58, 0.00, 6114.78, '2026-09-07T13:11:25'),
        (232, N'FAC-000232', 108, 22, 65, 63, N'INSTORE', N'PAID', 5330.00, 0.00, 0.00, 799.50, 0.00, 6129.50, '2026-09-07T13:51:27'),
        (233, N'FAC-000233', 103, 11, 54, 32, N'INSTORE', N'PAID', 4640.00, 405.00, 0.00, 635.25, 0.00, 4870.25, '2026-09-07T14:56:43'),
        (234, N'FAC-000234', 18, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 950.00, 0.00, 0.00, 142.50, 50.00, 1142.50, '2026-09-08T06:22:24'),
        (235, N'FAC-000235', 107, 26, 69, 76, N'INSTORE', N'PAID', 798.00, 68.40, 0.00, 109.44, 0.00, 839.04, '2026-09-08T08:47:21'),
        (236, N'FAC-000236', 96, 26, 69, 76, N'INSTORE', N'PAID', 1260.00, 226.80, 0.00, 154.98, 0.00, 1188.18, '2026-09-08T10:54:07'),
        (237, N'FAC-000237', 109, 26, 69, 76, N'INSTORE', N'PAID', 4060.00, 324.00, 120.00, 560.40, 0.00, 4176.40, '2026-09-08T12:22:17'),
        (238, N'FAC-000238', 102, 26, 69, 76, N'INSTORE', N'PAID', 2250.00, 0.00, 0.00, 337.50, 0.00, 2587.50, '2026-09-08T15:04:36'),
        (239, N'FAC-000239', 82, 11, 54, 30, N'INSTORE', N'PAID', 8220.00, 2041.20, 0.00, 926.82, 0.00, 7105.62, '2026-09-09T12:50:25'),
        (240, N'FAC-000240', 114, 11, 54, 30, N'INSTORE', N'CANCELLED', 2535.00, 445.50, 0.00, 313.43, 0.00, 2402.93, '2026-09-09T13:45:05'),
        (241, N'FAC-000241', 88, 2, NULL, NULL, N'ONLINE', N'SHIPPED', 952.00, 0.00, 0.00, 142.80, 80.00, 1174.80, '2026-09-12T03:28:49'),
        (242, N'FAC-000242', 109, 17, 60, 50, N'INSTORE', N'PAID', 870.00, 0.00, 0.00, 130.50, 0.00, 1000.50, '2026-09-12T08:43:48'),
        (243, N'FAC-000243', 102, 17, 60, 50, N'INSTORE', N'PAID', 690.00, 0.00, 0.00, 103.50, 0.00, 793.50, '2026-09-12T10:17:54'),
        (244, N'FAC-000244', 79, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 240.00, 0.00, 0.00, 36.00, 80.00, 356.00, '2026-09-12T13:55:46'),
        (245, N'FAC-000245', 103, 13, 56, 36, N'INSTORE', N'PAID', 1320.00, 0.00, 0.00, 198.00, 0.00, 1518.00, '2026-09-15T10:12:16'),
        (246, N'FAC-000246', 113, 13, 56, 36, N'INSTORE', N'PAID', 480.00, 0.00, 0.00, 72.00, 0.00, 552.00, '2026-09-15T13:45:39'),
        (247, N'FAC-000247', 99, 13, 56, 36, N'INSTORE', N'PAID', 3749.00, 647.10, 0.00, 465.29, 0.00, 3567.19, '2026-09-15T14:10:09'),
        (248, N'FAC-000248', 93, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3517.00, 570.00, 0.00, 442.05, 80.00, 3469.05, '2026-09-16T02:01:11'),
        (249, N'FAC-000249', 108, 4, 47, 5, N'INSTORE', N'PAID', 1520.00, 72.00, 0.00, 217.20, 0.00, 1665.20, '2026-09-17T10:10:27'),
        (250, N'FAC-000250', 107, 4, 47, 5, N'INSTORE', N'CANCELLED', 6415.00, 0.00, 0.00, 962.25, 0.00, 7377.25, '2026-09-17T11:41:36'),
        (251, N'FAC-000251', 78, 4, 47, 5, N'INSTORE', N'PAID', 4020.00, 894.00, 156.30, 468.90, 0.00, 3438.60, '2026-09-17T12:09:53'),
        (252, N'FAC-000252', 104, 4, 47, 5, N'INSTORE', N'PAID', 2040.00, 0.00, 0.00, 306.00, 0.00, 2346.00, '2026-09-17T12:18:24'),
        (253, N'FAC-000253', 108, 10, 53, 27, N'INSTORE', N'PAID', 2800.00, 258.00, 254.20, 381.30, 0.00, 2669.10, '2026-09-20T08:30:58'),
        (254, N'FAC-000254', 101, 10, 53, 27, N'INSTORE', N'PAID', 590.00, 0.00, 0.00, 88.50, 0.00, 678.50, '2026-09-20T08:35:09'),
        (255, N'FAC-000255', 113, 10, 53, 27, N'INSTORE', N'PAID', 1180.00, 0.00, 0.00, 177.00, 0.00, 1357.00, '2026-09-20T11:57:19'),
        (256, N'FAC-000256', 103, 10, 53, 27, N'INSTORE', N'PAID', 2822.00, 0.00, 0.00, 423.30, 0.00, 3245.30, '2026-09-20T13:05:18'),
        (257, N'FAC-000257', 76, 10, 53, 27, N'INSTORE', N'PAID', 3390.00, 0.00, 0.00, 508.50, 0.00, 3898.50, '2026-09-20T13:08:10'),
        (258, N'FAC-000258', 91, 21, 64, 61, N'INSTORE', N'PAID', 420.00, 0.00, 0.00, 63.00, 0.00, 483.00, '2026-09-23T08:44:16'),
        (259, N'FAC-000259', 105, 21, 64, 61, N'INSTORE', N'PAID', 5520.00, 1125.00, 0.00, 659.25, 0.00, 5054.25, '2026-09-23T09:14:59'),
        (260, N'FAC-000260', 82, 21, 64, 61, N'INSTORE', N'PAID', 6685.00, 226.80, 0.00, 968.73, 0.00, 7426.93, '2026-09-23T11:08:51'),
        (261, N'FAC-000261', 88, 21, 64, 61, N'INSTORE', N'PAID', 3450.00, 1035.00, 0.00, 362.25, 0.00, 2777.25, '2026-09-23T11:28:08'),
        (262, N'FAC-000262', 93, 21, 64, 61, N'INSTORE', N'PAID', 3160.00, 0.00, 60.00, 474.00, 0.00, 3574.00, '2026-09-23T11:44:19'),
        (263, N'FAC-000263', 97, 21, 64, 61, N'INSTORE', N'PAID', 1050.00, 0.00, 0.00, 157.50, 0.00, 1207.50, '2026-09-23T13:50:15'),
        (264, N'FAC-000264', 102, 2, NULL, NULL, N'ONLINE', N'CANCELLED', 3110.00, 580.80, 0.00, 379.38, 0.00, 2908.58, '2026-09-23T19:56:49'),
        (265, N'FAC-000265', 84, 2, NULL, NULL, N'ONLINE', N'CANCELLED', 8304.00, 1940.40, 0.00, 954.54, 0.00, 7318.14, '2026-09-24T15:06:16'),
        (266, N'FAC-000266', 108, 18, 61, 51, N'INSTORE', N'PAID', 360.00, 0.00, 0.00, 54.00, 0.00, 414.00, '2026-09-25T08:48:37'),
        (267, N'FAC-000267', 102, 28, 71, 82, N'INSTORE', N'PAID', 4210.00, 177.60, 0.00, 604.86, 0.00, 4637.26, '2026-09-25T11:00:13'),
        (268, N'FAC-000268', 89, 18, 61, 51, N'INSTORE', N'PAID', 4050.00, 0.00, 243.00, 607.50, 0.00, 4414.50, '2026-09-25T11:42:42'),
        (269, N'FAC-000269', 93, 28, 71, 82, N'INSTORE', N'PAID', 3880.00, 480.00, 0.00, 510.00, 0.00, 3910.00, '2026-09-25T14:24:59'),
        (270, N'FAC-000270', 106, 18, 61, 51, N'INSTORE', N'PAID', 3686.00, 150.48, 0.00, 530.33, 0.00, 4065.85, '2026-09-25T15:31:37'),
        (271, N'FAC-000271', 107, 28, 71, 82, N'INSTORE', N'PAID', 1600.00, 0.00, 0.00, 240.00, 0.00, 1840.00, '2026-09-25T15:44:50'),
        (272, N'FAC-000272', 98, 18, 61, 51, N'INSTORE', N'PAID', 330.00, 0.00, 0.00, 49.50, 0.00, 379.50, '2026-09-25T15:55:33'),
        (273, N'FAC-000273', 87, 18, 61, 51, N'INSTORE', N'PAID', 5820.00, 72.00, 0.00, 862.20, 0.00, 6610.20, '2026-09-25T15:58:09'),
        (274, N'FAC-000274', 89, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 1900.00, 570.00, 0.00, 199.50, 50.00, 1579.50, '2026-09-25T20:15:04'),
        (275, N'FAC-000275', 101, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3556.00, 0.00, 0.00, 533.40, 80.00, 4169.40, '2026-09-28T07:35:10'),
        (276, N'FAC-000276', 102, 9, 52, 25, N'INSTORE', N'PAID', 1809.00, 0.00, 0.00, 271.35, 0.00, 2080.35, '2026-09-28T10:30:09'),
        (277, N'FAC-000277', 99, 9, 52, 25, N'INSTORE', N'PAID', 7140.00, 226.80, 0.00, 1036.98, 0.00, 7950.18, '2026-09-28T10:38:01'),
        (278, N'FAC-000278', 94, 9, 52, 25, N'INSTORE', N'CANCELLED', 4325.00, 267.30, 0.00, 608.66, 0.00, 4666.36, '2026-09-28T11:48:13'),
        (279, N'FAC-000279', 102, 9, 52, 25, N'INSTORE', N'PAID', 726.00, 0.00, 60.00, 108.90, 0.00, 774.90, '2026-09-28T13:31:25'),
        (280, N'FAC-000280', 83, 9, 52, 25, N'INSTORE', N'CANCELLED', 1050.00, 151.20, 0.00, 134.82, 0.00, 1033.62, '2026-09-28T14:22:00'),
        (281, N'FAC-000281', 107, 9, 52, 25, N'INSTORE', N'PAID', 840.00, 0.00, 0.00, 126.00, 0.00, 966.00, '2026-09-28T15:56:11'),
        (282, N'FAC-000282', 113, 24, 67, 71, N'INSTORE', N'PAID', 1050.00, 0.00, 0.00, 157.50, 0.00, 1207.50, '2026-09-30T08:56:59'),
        (283, N'FAC-000283', 84, 23, 66, 68, N'INSTORE', N'PAID', 6160.00, 0.00, 0.00, 924.00, 0.00, 7084.00, '2026-09-30T10:30:48'),
        (284, N'FAC-000284', 97, 23, 66, 68, N'INSTORE', N'PAID', 3600.00, 750.00, 60.00, 427.50, 0.00, 3217.50, '2026-09-30T12:08:13'),
        (285, N'FAC-000285', 84, 24, 67, 71, N'INSTORE', N'PAID', 2304.00, 210.00, 0.00, 314.10, 0.00, 2408.10, '2026-09-30T13:03:08'),
        (286, N'FAC-000286', 76, 23, 66, 68, N'INSTORE', N'PAID', 2980.00, 0.00, 149.00, 447.00, 0.00, 3278.00, '2026-09-30T13:35:57'),
        (287, N'FAC-000287', 112, 23, 66, 68, N'INSTORE', N'PAID', 860.00, 172.00, 0.00, 103.20, 0.00, 791.20, '2026-09-30T14:47:10'),
        (288, N'FAC-000288', 97, 23, 66, 68, N'INSTORE', N'PAID', 1144.00, 0.00, 0.00, 171.60, 0.00, 1315.60, '2026-09-30T15:11:54'),
        (289, N'FAC-000289', 104, 23, 66, 68, N'INSTORE', N'PAID', 4214.00, 225.72, 239.30, 598.24, 0.00, 4347.22, '2026-09-30T15:24:01'),
        (290, N'FAC-000290', 95, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 6580.00, 0.00, 0.00, 987.00, 80.00, 7647.00, '2026-10-01T01:36:42'),
        (291, N'FAC-000291', 96, 14, 57, 41, N'INSTORE', N'PAID', 1155.00, 0.00, 0.00, 173.25, 0.00, 1328.25, '2026-10-03T11:58:12'),
        (292, N'FAC-000292', 84, 14, 57, 41, N'INSTORE', N'PAID', 3347.00, 0.00, 0.00, 502.05, 0.00, 3849.05, '2026-10-03T12:18:16'),
        (293, N'FAC-000293', 104, 14, 57, 41, N'INSTORE', N'PAID', 1065.00, 0.00, 80.00, 159.75, 0.00, 1144.75, '2026-10-03T14:22:04'),
        (294, N'FAC-000294', 75, 14, 57, 41, N'INSTORE', N'PAID', 5950.00, 0.00, 0.00, 892.50, 0.00, 6842.50, '2026-10-03T14:34:00'),
        (295, N'FAC-000295', 78, 6, 49, 15, N'INSTORE', N'PAID', 1615.00, 0.00, 0.00, 242.25, 0.00, 1857.25, '2026-10-04T12:46:59'),
        (296, N'FAC-000296', 83, 6, 49, 15, N'INSTORE', N'PAID', 5766.00, 1360.80, 0.00, 660.78, 0.00, 5065.98, '2026-10-04T13:01:02'),
        (297, N'FAC-000297', 96, 6, 49, 15, N'INSTORE', N'PAID', 2499.00, 50.40, 0.00, 367.29, 0.00, 2815.89, '2026-10-04T15:51:14'),
        (298, N'FAC-000298', 76, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 4200.00, 1260.00, 0.00, 441.00, 80.00, 3461.00, '2026-10-06T03:55:42'),
        (299, N'FAC-000299', 101, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 1720.00, 177.60, 0.00, 231.36, 120.00, 1893.76, '2026-10-07T15:09:46'),
        (300, N'FAC-000300', 81, 10, 53, 29, N'INSTORE', N'PAID', 2390.00, 285.00, 0.00, 315.75, 0.00, 2420.75, '2026-10-08T08:51:43'),
        (301, N'FAC-000301', 81, 12, 55, 35, N'INSTORE', N'PAID', 5620.00, 532.80, 0.00, 763.08, 0.00, 5850.28, '2026-10-08T09:03:46'),
        (302, N'FAC-000302', 76, 10, 53, 29, N'INSTORE', N'PAID', 5230.00, 0.00, 0.00, 784.50, 0.00, 6014.50, '2026-10-08T09:31:02'),
        (303, N'FAC-000303', 97, 12, 55, 35, N'INSTORE', N'PAID', 5870.00, 960.00, 0.00, 736.50, 0.00, 5646.50, '2026-10-08T10:51:45'),
        (304, N'FAC-000304', 91, 10, 53, 29, N'INSTORE', N'PAID', 5850.00, 608.40, 0.00, 786.24, 0.00, 6027.84, '2026-10-08T10:55:10'),
        (305, N'FAC-000305', 81, 12, 55, 35, N'INSTORE', N'PAID', 4740.00, 258.00, 0.00, 672.30, 0.00, 5154.30, '2026-10-08T12:51:56'),
        (306, N'FAC-000306', 77, 12, 55, 35, N'INSTORE', N'PAID', 2860.00, 472.00, 0.00, 358.20, 0.00, 2746.20, '2026-10-08T13:56:18'),
        (307, N'FAC-000307', 114, 10, 53, 29, N'INSTORE', N'PAID', 1990.00, 86.00, 0.00, 285.60, 0.00, 2189.60, '2026-10-08T14:07:35'),
        (308, N'FAC-000308', 92, 10, 53, 29, N'INSTORE', N'PAID', 1480.00, 177.60, 0.00, 195.36, 0.00, 1497.76, '2026-10-08T14:15:54'),
        (309, N'FAC-000309', 89, 12, 55, 35, N'INSTORE', N'CANCELLED', 5110.00, 1440.00, 0.00, 550.50, 0.00, 4220.50, '2026-10-08T15:21:04'),
        (310, N'FAC-000310', 94, 12, 55, 35, N'INSTORE', N'PAID', 5610.00, 676.00, 0.00, 740.10, 0.00, 5674.10, '2026-10-08T15:29:16'),
        (311, N'FAC-000311', 80, 5, 48, 9, N'INSTORE', N'PAID', 1140.00, 205.20, 0.00, 140.22, 0.00, 1075.02, '2026-10-09T11:16:46'),
        (312, N'FAC-000312', 111, 5, 48, 9, N'INSTORE', N'PAID', 260.00, 91.00, 0.00, 25.35, 0.00, 194.35, '2026-10-09T12:56:10'),
        (313, N'FAC-000313', 98, 2, NULL, NULL, N'ONLINE', N'SHIPPED', 8090.00, 100.80, 0.00, 1198.38, 80.00, 9267.58, '2026-10-09T14:13:51'),
        (314, N'FAC-000314', 114, 5, 48, 9, N'INSTORE', N'PAID', 1840.00, 0.00, 0.00, 276.00, 0.00, 2116.00, '2026-10-09T15:06:16'),
        (315, N'FAC-000315', 110, 5, 48, 9, N'INSTORE', N'PAID', 780.00, 273.00, 40.56, 76.05, 0.00, 542.49, '2026-10-09T15:21:16'),
        (316, N'FAC-000316', 106, 7, 50, 18, N'INSTORE', N'PAID', 680.00, 0.00, 0.00, 102.00, 0.00, 782.00, '2026-10-10T11:28:23'),
        (317, N'FAC-000317', 109, 7, 50, 18, N'INSTORE', N'PAID', 1720.00, 0.00, 137.60, 258.00, 0.00, 1840.40, '2026-10-10T11:49:39'),
        (318, N'FAC-000318', 112, 7, 50, 18, N'INSTORE', N'CANCELLED', 1770.00, 0.00, 0.00, 265.50, 0.00, 2035.50, '2026-10-10T15:48:14'),
        (319, N'FAC-000319', 106, 8, 51, 23, N'INSTORE', N'PAID', 2428.00, 0.00, 242.80, 364.20, 0.00, 2549.40, '2026-10-12T12:43:02'),
        (320, N'FAC-000320', 102, 8, 51, 23, N'INSTORE', N'PAID', 840.00, 0.00, 0.00, 126.00, 0.00, 966.00, '2026-10-12T14:46:05'),
        (321, N'FAC-000321', 95, 8, 51, 23, N'INSTORE', N'PAID', 3390.00, 0.00, 0.00, 508.50, 0.00, 3898.50, '2026-10-12T14:53:35'),
        (322, N'FAC-000322', 96, 8, 51, 23, N'INSTORE', N'PAID', 1210.00, 217.80, 0.00, 148.83, 0.00, 1141.03, '2026-10-12T15:39:19'),
        (323, N'FAC-000323', 95, 9, 52, 24, N'INSTORE', N'PAID', 3300.00, 594.00, 0.00, 405.90, 0.00, 3111.90, '2026-10-14T09:00:41'),
        (324, N'FAC-000324', 76, 9, 52, 24, N'INSTORE', N'PAID', 1089.00, 0.00, 100.00, 163.35, 0.00, 1152.35, '2026-10-14T15:45:24'),
        (325, N'FAC-000325', 75, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 1390.00, 220.50, 0.00, 175.43, 50.00, 1394.93, '2026-10-16T20:51:00'),
        (326, N'FAC-000326', 102, 4, 47, 6, N'INSTORE', N'PAID', 4670.00, 105.60, 0.00, 684.66, 0.00, 5249.06, '2026-10-18T09:09:09'),
        (327, N'FAC-000327', 101, 4, 47, 6, N'INSTORE', N'PAID', 4740.00, 1421.00, 0.00, 497.85, 0.00, 3816.85, '2026-10-18T10:19:17'),
        (328, N'FAC-000328', 103, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 990.00, 178.20, 0.00, 121.77, 80.00, 1013.57, '2026-10-18T12:08:17'),
        (329, N'FAC-000329', 110, 4, 47, 6, N'INSTORE', N'PAID', 3923.00, 820.50, 0.00, 465.38, 0.00, 3567.88, '2026-10-18T13:39:50'),
        (330, N'FAC-000330', 92, 2, NULL, NULL, N'ONLINE', N'PENDING', 1640.00, 36.00, 0.00, 240.60, 0.00, 1844.60, '2026-10-20T03:50:28'),
        (331, N'FAC-000331', 93, 16, 59, 47, N'INSTORE', N'PAID', 2556.00, 100.80, 0.00, 368.28, 0.00, 2823.48, '2026-10-21T09:13:31'),
        (332, N'FAC-000332', 104, 16, 59, 47, N'INSTORE', N'PAID', 560.00, 0.00, 56.00, 84.00, 0.00, 588.00, '2026-10-21T11:02:25'),
        (333, N'FAC-000333', 80, 16, 59, 47, N'INSTORE', N'PAID', 3402.00, 0.00, 0.00, 510.30, 0.00, 3912.30, '2026-10-21T12:21:31'),
        (334, N'FAC-000334', 102, 16, 59, 47, N'INSTORE', N'PAID', 2624.00, 0.00, 0.00, 393.60, 0.00, 3017.60, '2026-10-21T14:39:25'),
        (335, N'FAC-000335', 109, 16, 59, 47, N'INSTORE', N'PAID', 363.00, 0.00, 0.00, 54.45, 0.00, 417.45, '2026-10-21T14:44:10'),
        (336, N'FAC-000336', 87, 16, 59, 47, N'INSTORE', N'PAID', 2810.00, 0.00, 0.00, 421.50, 0.00, 3231.50, '2026-10-21T15:48:49'),
        (337, N'FAC-000337', 103, 2, NULL, NULL, N'ONLINE', N'PAID', 3780.00, 48.00, 0.00, 559.80, 50.00, 4341.80, '2026-10-23T06:24:30'),
        (338, N'FAC-000338', 105, 20, 63, 58, N'INSTORE', N'PAID', 4335.00, 548.10, 0.00, 568.04, 0.00, 4354.94, '2026-10-24T08:49:26'),
        (339, N'FAC-000339', 80, 5, 48, 11, N'INSTORE', N'PAID', 930.00, 0.00, 0.00, 139.50, 0.00, 1069.50, '2026-10-24T08:54:12'),
        (340, N'FAC-000340', 87, 20, 63, 58, N'INSTORE', N'PAID', 4785.00, 0.00, 0.00, 717.75, 0.00, 5502.75, '2026-10-24T09:10:17'),
        (341, N'FAC-000341', 107, 5, 48, 11, N'INSTORE', N'PAID', 3150.00, 945.00, 80.00, 330.75, 0.00, 2455.75, '2026-10-24T10:08:58'),
        (342, N'FAC-000342', 75, 20, 63, 58, N'INSTORE', N'PAID', 1350.00, 405.00, 100.00, 141.75, 0.00, 986.75, '2026-10-24T10:32:02'),
        (343, N'FAC-000343', 97, 5, 48, 11, N'INSTORE', N'PAID', 1730.00, 375.00, 0.00, 203.25, 0.00, 1558.25, '2026-10-24T10:41:19'),
        (344, N'FAC-000344', 78, 5, 48, 11, N'INSTORE', N'PAID', 1120.00, 0.00, 0.00, 168.00, 0.00, 1288.00, '2026-10-24T11:40:03'),
        (345, N'FAC-000345', 81, 20, 63, 58, N'INSTORE', N'PAID', 1403.00, 0.00, 0.00, 210.45, 0.00, 1613.45, '2026-10-24T12:25:11'),
        (346, N'FAC-000346', 86, 5, 48, 11, N'INSTORE', N'PAID', 590.00, 0.00, 0.00, 88.50, 0.00, 678.50, '2026-10-24T14:34:09'),
        (347, N'FAC-000347', 100, 5, 48, 11, N'INSTORE', N'PAID', 4180.00, 205.20, 0.00, 596.22, 0.00, 4571.02, '2026-10-24T15:13:08'),
        (348, N'FAC-000348', 109, 20, 63, 58, N'INSTORE', N'PAID', 5680.00, 0.00, 0.00, 852.00, 0.00, 6532.00, '2026-10-24T15:29:30'),
        (349, N'FAC-000349', 105, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 1140.00, 0.00, 0.00, 171.00, 80.00, 1391.00, '2026-10-24T18:26:25'),
        (350, N'FAC-000350', 84, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 980.00, 179.10, 0.00, 120.14, 80.00, 1001.04, '2026-10-25T23:42:25'),
        (351, N'FAC-000351', 98, 2, NULL, NULL, N'ONLINE', N'CANCELLED', 2360.00, 136.80, 0.00, 333.48, 0.00, 2556.68, '2026-10-27T11:15:26'),
        (352, N'FAC-000352', 75, 2, NULL, NULL, N'ONLINE', N'PENDING', 420.00, 50.40, 0.00, 55.44, 0.00, 425.04, '2026-10-27T19:16:02'),
        (353, N'FAC-000353', 86, 7, 50, 17, N'INSTORE', N'PAID', 4480.00, 960.00, 0.00, 528.00, 0.00, 4048.00, '2026-10-28T09:36:06'),
        (354, N'FAC-000354', 107, 7, 50, 17, N'INSTORE', N'PAID', 1610.00, 270.20, 0.00, 200.97, 0.00, 1540.77, '2026-10-28T13:41:36'),
        (355, N'FAC-000355', 75, 7, 50, 17, N'INSTORE', N'PAID', 4785.00, 861.30, 0.00, 588.56, 0.00, 4512.26, '2026-10-28T15:56:14'),
        (356, N'FAC-000356', 106, 16, 59, 46, N'INSTORE', N'CANCELLED', 560.00, 196.00, 0.00, 54.60, 0.00, 418.60, '2026-10-30T08:35:19'),
        (357, N'FAC-000357', 87, 16, 59, 46, N'INSTORE', N'PAID', 4820.00, 502.20, 0.00, 647.67, 0.00, 4965.47, '2026-10-30T10:45:17'),
        (358, N'FAC-000358', 110, 16, 59, 46, N'INSTORE', N'PAID', 3000.00, 0.00, 0.00, 450.00, 0.00, 3450.00, '2026-10-30T15:38:32'),
        (359, N'FAC-000359', 103, 16, 59, 46, N'INSTORE', N'PAID', 760.00, 0.00, 0.00, 114.00, 0.00, 874.00, '2026-10-30T15:58:57'),
        (360, N'FAC-000360', 109, 27, 70, 79, N'INSTORE', N'PAID', 6840.00, 0.00, 342.00, 1026.00, 0.00, 7524.00, '2026-10-31T08:37:14'),
        (361, N'FAC-000361', 76, 27, 70, 79, N'INSTORE', N'PAID', 3400.00, 375.00, 181.50, 453.75, 0.00, 3297.25, '2026-10-31T10:23:39'),
        (362, N'FAC-000362', 82, 2, NULL, NULL, N'ONLINE', N'PAID', 2740.00, 721.20, 0.00, 302.82, 50.00, 2371.62, '2026-10-31T10:34:53'),
        (363, N'FAC-000363', 100, 27, 70, 79, N'INSTORE', N'PAID', 890.00, 160.20, 0.00, 109.47, 0.00, 839.27, '2026-10-31T12:02:54'),
        (364, N'FAC-000364', 105, 27, 70, 79, N'INSTORE', N'PAID', 1780.00, 320.40, 116.77, 218.94, 0.00, 1561.77, '2026-10-31T14:41:12'),
        (365, N'FAC-000365', 98, 27, 70, 79, N'INSTORE', N'PAID', 1780.00, 320.40, 0.00, 218.94, 0.00, 1678.54, '2026-10-31T15:49:42'),
        (366, N'FAC-000366', 104, 19, 62, 54, N'INSTORE', N'PAID', 3371.00, 324.00, 0.00, 457.05, 0.00, 3504.05, '2026-11-01T13:27:31'),
        (367, N'FAC-000367', 106, 19, 62, 54, N'INSTORE', N'PAID', 4108.00, 570.40, 0.00, 530.64, 0.00, 4068.24, '2026-11-01T13:43:25'),
        (368, N'FAC-000368', 107, 19, 62, 54, N'INSTORE', N'PAID', 1920.00, 364.80, 0.00, 233.28, 0.00, 1788.48, '2026-11-01T13:46:52'),
        (369, N'FAC-000369', 103, 19, 62, 54, N'INSTORE', N'PAID', 1056.00, 369.60, 0.00, 102.96, 0.00, 789.36, '2026-11-01T14:13:00'),
        (370, N'FAC-000370', 96, 19, 62, 54, N'INSTORE', N'CANCELLED', 3030.00, 0.00, 0.00, 454.50, 0.00, 3484.50, '2026-11-01T15:34:38'),
        (371, N'FAC-000371', 84, 19, 62, 54, N'INSTORE', N'PAID', 12075.00, 1394.10, 60.00, 1602.14, 0.00, 12223.04, '2026-11-01T15:41:03'),
        (372, N'FAC-000372', 89, 27, 70, 80, N'INSTORE', N'PAID', 4220.00, 684.00, 0.00, 530.40, 0.00, 4066.40, '2026-11-03T08:47:01'),
        (373, N'FAC-000373', 83, 20, 63, 57, N'INSTORE', N'PAID', 3670.00, 230.40, 343.96, 515.94, 0.00, 3611.58, '2026-11-03T09:39:39'),
        (374, N'FAC-000374', 92, 20, 63, 57, N'INSTORE', N'PAID', 9840.00, 244.80, 0.00, 1439.28, 0.00, 11034.48, '2026-11-03T10:05:04'),
        (375, N'FAC-000375', 101, 2, NULL, NULL, N'ONLINE', N'PAID', 5660.00, 112.00, 0.00, 832.20, 50.00, 6430.20, '2026-11-03T10:15:02'),
        (376, N'FAC-000376', 101, 20, 63, 57, N'INSTORE', N'PAID', 1419.00, 0.00, 0.00, 212.85, 0.00, 1631.85, '2026-11-03T11:00:26'),
        (377, N'FAC-000377', 79, 27, 70, 80, N'INSTORE', N'CANCELLED', 4729.00, 480.60, 0.00, 637.26, 0.00, 4885.66, '2026-11-03T11:48:11'),
        (378, N'FAC-000378', 106, 27, 70, 80, N'INSTORE', N'PAID', 1920.00, 345.60, 0.00, 236.16, 0.00, 1810.56, '2026-11-03T11:50:13'),
        (379, N'FAC-000379', 101, 20, 63, 57, N'INSTORE', N'PAID', 1250.00, 0.00, 0.00, 187.50, 0.00, 1437.50, '2026-11-03T12:13:55'),
        (380, N'FAC-000380', 85, 20, 63, 57, N'INSTORE', N'PAID', 2880.00, 68.40, 0.00, 421.74, 0.00, 3233.34, '2026-11-03T12:18:15'),
        (381, N'FAC-000381', 114, 27, 70, 80, N'INSTORE', N'PAID', 3100.00, 136.80, 177.79, 444.48, 0.00, 3229.89, '2026-11-03T13:43:00'),
        (382, N'FAC-000382', 110, 27, 70, 80, N'INSTORE', N'PAID', 990.00, 0.00, 0.00, 148.50, 0.00, 1138.50, '2026-11-03T14:25:48'),
        (383, N'FAC-000383', 103, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 4440.00, 0.00, 0.00, 666.00, 80.00, 5186.00, '2026-11-04T09:35:59'),
        (384, N'FAC-000384', 77, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 4365.00, 0.00, 0.00, 654.75, 120.00, 5139.75, '2026-11-05T22:27:15'),
        (385, N'FAC-000385', 110, 22, 65, 65, N'INSTORE', N'PAID', 1250.00, 0.00, 0.00, 187.50, 0.00, 1437.50, '2026-11-06T10:01:11'),
        (386, N'FAC-000386', 101, 22, 65, 65, N'INSTORE', N'PAID', 836.00, 150.48, 68.55, 102.83, 0.00, 719.80, '2026-11-06T14:26:18'),
        (387, N'FAC-000387', 94, 22, 65, 65, N'INSTORE', N'PAID', 3488.00, 261.00, 0.00, 484.05, 0.00, 3711.05, '2026-11-06T14:36:00'),
        (388, N'FAC-000388', 87, 22, 65, 65, N'INSTORE', N'PAID', 1794.00, 225.72, 0.00, 235.24, 0.00, 1803.52, '2026-11-06T14:39:24'),
        (389, N'FAC-000389', 90, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3040.00, 499.60, 152.42, 381.06, 50.00, 2819.04, '2026-11-07T01:42:07'),
        (390, N'FAC-000390', 78, 2, NULL, NULL, N'ONLINE', N'PENDING', 860.00, 0.00, 0.00, 129.00, 0.00, 989.00, '2026-11-09T16:50:47'),
        (391, N'FAC-000391', 97, 26, 69, 75, N'INSTORE', N'PAID', 2970.00, 0.00, 0.00, 445.50, 0.00, 3415.50, '2026-11-12T09:11:41'),
        (392, N'FAC-000392', 83, 26, 69, 75, N'INSTORE', N'PAID', 2605.00, 0.00, 0.00, 390.75, 0.00, 2995.75, '2026-11-12T10:02:05'),
        (393, N'FAC-000393', 102, 26, 69, 75, N'INSTORE', N'PAID', 4330.00, 0.00, 0.00, 649.50, 0.00, 4979.50, '2026-11-12T11:58:40'),
        (394, N'FAC-000394', 104, 26, 69, 75, N'INSTORE', N'PAID', 4110.00, 205.20, 0.00, 585.72, 0.00, 4490.52, '2026-11-12T12:43:32'),
        (395, N'FAC-000395', 82, 26, 69, 75, N'INSTORE', N'PAID', 5450.00, 182.00, 0.00, 790.20, 0.00, 6058.20, '2026-11-12T14:33:33'),
        (396, N'FAC-000396', 111, 26, 69, 75, N'INSTORE', N'PAID', 2110.00, 0.00, 0.00, 316.50, 0.00, 2426.50, '2026-11-12T14:57:10'),
        (397, N'FAC-000397', 90, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 1980.00, 298.80, 60.00, 252.18, 80.00, 1953.38, '2026-11-13T11:13:22'),
        (398, N'FAC-000398', 81, 2, NULL, NULL, N'ONLINE', N'PAID', 260.00, 91.00, 0.00, 25.35, 80.00, 274.35, '2026-11-13T18:30:10'),
        (399, N'FAC-000399', 104, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3384.00, 614.40, 0.00, 415.44, 50.00, 3235.04, '2026-11-14T00:39:38'),
        (400, N'FAC-000400', 87, 8, 51, 21, N'INSTORE', N'PAID', 1210.00, 0.00, 0.00, 181.50, 0.00, 1391.50, '2026-11-14T08:50:19');
    INSERT INTO dbo.Bill (Id, BillCode, Person_Id, Store_Id, Employee_Id, CashShift_Id, Channel, Status, SubTotal, DiscountTotal, CouponTotal, TaxTotal, ShippingTotal, Total, RegistrationDate) VALUES
        (401, N'FAC-000401', 111, 25, 68, 73, N'INSTORE', N'PAID', 420.00, 0.00, 0.00, 63.00, 0.00, 483.00, '2026-11-14T08:50:37'),
        (402, N'FAC-000402', 109, 25, 68, 73, N'INSTORE', N'PAID', 2590.00, 0.00, 0.00, 388.50, 0.00, 2978.50, '2026-11-14T09:01:20'),
        (403, N'FAC-000403', 78, 8, 51, 21, N'INSTORE', N'PAID', 690.00, 0.00, 55.20, 103.50, 0.00, 738.30, '2026-11-14T09:01:38'),
        (404, N'FAC-000404', 75, 25, 68, 73, N'INSTORE', N'PAID', 760.00, 0.00, 45.60, 114.00, 0.00, 828.40, '2026-11-14T09:49:33'),
        (405, N'FAC-000405', 105, 8, 51, 21, N'INSTORE', N'PAID', 4984.00, 650.88, 0.00, 649.97, 0.00, 4983.09, '2026-11-14T10:54:32'),
        (406, N'FAC-000406', 104, 25, 68, 73, N'INSTORE', N'PAID', 1480.00, 177.60, 0.00, 195.36, 0.00, 1497.76, '2026-11-14T11:59:30'),
        (407, N'FAC-000407', 88, 25, 68, 73, N'INSTORE', N'PAID', 1520.00, 0.00, 0.00, 228.00, 0.00, 1748.00, '2026-11-14T13:04:01'),
        (408, N'FAC-000408', 93, 25, 68, 73, N'INSTORE', N'PAID', 1110.00, 70.80, 0.00, 155.88, 0.00, 1195.08, '2026-11-14T14:08:38'),
        (409, N'FAC-000409', 84, 8, 51, 21, N'INSTORE', N'PAID', 7990.00, 0.00, 0.00, 1198.50, 0.00, 9188.50, '2026-11-14T15:22:56'),
        (410, N'FAC-000410', 83, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 5130.00, 745.20, 0.00, 657.72, 50.00, 5092.52, '2026-11-16T01:02:23'),
        (411, N'FAC-000411', 90, 2, NULL, NULL, N'ONLINE', N'DELIVERED', 3730.00, 177.60, 0.00, 532.86, 80.00, 4165.26, '2026-11-16T03:15:22'),
        (412, N'FAC-000412', 91, 7, 50, 20, N'INSTORE', N'PAID', 2875.00, 230.40, 300.00, 396.69, 0.00, 2741.29, '2026-11-21T08:44:53'),
        (413, N'FAC-000413', 99, 4, 47, 8, N'INSTORE', N'PAID', 4608.00, 0.00, 0.00, 691.20, 0.00, 5299.20, '2026-11-21T08:51:12'),
        (414, N'FAC-000414', 80, 6, 49, 16, N'INSTORE', N'CANCELLED', 1446.00, 72.00, 0.00, 206.10, 0.00, 1580.10, '2026-11-21T08:56:30'),
        (415, N'FAC-000415', 78, 6, 49, 16, N'INSTORE', N'PAID', 1560.00, 100.80, 0.00, 218.88, 0.00, 1678.08, '2026-11-21T09:12:06'),
        (416, N'FAC-000416', 81, 6, 49, 16, N'INSTORE', N'PAID', 2756.00, 0.00, 0.00, 413.40, 0.00, 3169.40, '2026-11-21T09:12:50'),
        (417, N'FAC-000417', 80, 3, 46, 4, N'INSTORE', N'PAID', 2910.00, 0.00, 0.00, 436.50, 0.00, 3346.50, '2026-11-21T09:50:46'),
        (418, N'FAC-000418', 100, 7, 50, 20, N'INSTORE', N'PAID', 1900.00, 266.40, 98.02, 245.04, 0.00, 1780.62, '2026-11-21T09:56:42'),
        (419, N'FAC-000419', 95, 3, 46, 4, N'INSTORE', N'PAID', 3110.00, 0.00, 0.00, 466.50, 0.00, 3576.50, '2026-11-21T10:20:02'),
        (420, N'FAC-000420', 79, 3, 46, 4, N'INSTORE', N'PAID', 4410.00, 399.60, 401.04, 601.56, 0.00, 4210.92, '2026-11-21T10:26:17'),
        (421, N'FAC-000421', 106, 3, 46, 4, N'INSTORE', N'PAID', 420.00, 147.00, 13.65, 40.95, 0.00, 300.30, '2026-11-21T10:46:37'),
        (422, N'FAC-000422', 90, 6, 49, 16, N'INSTORE', N'PAID', 1290.00, 0.00, 0.00, 193.50, 0.00, 1483.50, '2026-11-21T10:49:53'),
        (423, N'FAC-000423', 84, 3, 46, 4, N'INSTORE', N'PAID', 2880.00, 73.50, 0.00, 420.98, 0.00, 3227.48, '2026-11-21T10:57:48'),
        (424, N'FAC-000424', 88, 5, 48, 12, N'INSTORE', N'PAID', 2568.00, 516.80, 0.00, 307.68, 0.00, 2358.88, '2026-11-21T11:04:39'),
        (425, N'FAC-000425', 98, 3, 46, 4, N'INSTORE', N'PAID', 4470.00, 561.60, 312.67, 586.26, 0.00, 4181.99, '2026-11-21T11:05:54'),
        (426, N'FAC-000426', 112, 4, 47, 8, N'INSTORE', N'CANCELLED', 4900.00, 316.80, 0.00, 687.48, 0.00, 5270.68, '2026-11-21T11:08:08'),
        (427, N'FAC-000427', 76, 5, 48, 12, N'INSTORE', N'PAID', 4560.00, 151.20, 0.00, 661.32, 0.00, 5070.12, '2026-11-21T11:31:27'),
        (428, N'FAC-000428', 98, 5, 48, 12, N'INSTORE', N'PAID', 3500.00, 1009.60, 0.00, 373.56, 0.00, 2863.96, '2026-11-21T11:34:58'),
        (429, N'FAC-000429', 104, 6, 49, 16, N'INSTORE', N'PAID', 1809.00, 0.00, 0.00, 271.35, 0.00, 2080.35, '2026-11-21T11:52:39'),
        (430, N'FAC-000430', 112, 7, 50, 20, N'INSTORE', N'PAID', 1150.00, 432.00, 0.00, 107.70, 0.00, 825.70, '2026-11-21T11:59:12');
    SET IDENTITY_INSERT dbo.Bill OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Shipment)
BEGIN
    SET IDENTITY_INSERT dbo.Shipment ON;
    INSERT INTO dbo.Shipment (Id, Bill_Id, Direction_Id, TrackingNumber, Carrier, Status, ShippingCost, ShippedDate, DeliveredDate) VALUES
        (1, 7, 59, N'HN-00000007', N'Servientrega', N'DELIVERED', 80.00, '2026-06-02', '2026-06-05'),
        (2, 8, 86, N'HN-00000008', N'Servientrega', N'DELIVERED', 120.00, '2026-06-03', '2026-06-06'),
        (3, 9, 67, N'HN-00000009', N'Honduras Express', N'DELIVERED', 80.00, '2026-06-03', '2026-06-06'),
        (4, 19, 72, N'HN-00000019', N'Honduras Express', N'DELIVERED', 80.00, '2026-06-07', '2026-06-10'),
        (5, 41, 74, N'HN-00000041', N'Honduras Express', N'DELIVERED', 80.00, '2026-06-16', '2026-06-19'),
        (6, 48, 79, N'HN-00000048', N'Honduras Express', N'SHIPPED', 80.00, '2026-06-20', NULL),
        (7, 66, 63, N'HN-00000066', N'Servientrega', N'DELIVERED', 80.00, '2026-06-25', '2026-06-28'),
        (8, 71, 83, N'HN-00000071', N'Cargo Expreso', N'SHIPPED', 50.00, '2026-06-29', NULL),
        (9, 81, 68, N'HN-00000081', N'Cargo Expreso', N'DELIVERED', 50.00, '2026-07-02', '2026-07-05'),
        (10, 87, 59, N'HN-00000087', N'Servientrega', N'DELIVERED', 120.00, '2026-07-04', '2026-07-07'),
        (11, 88, 70, N'HN-00000088', N'Honduras Express', N'DELIVERED', 80.00, '2026-07-04', '2026-07-07'),
        (12, 98, 86, N'HN-00000098', N'Honduras Express', N'DELIVERED', 80.00, '2026-07-06', '2026-07-09'),
        (13, 99, 82, N'HN-00000099', N'Cargo Expreso', N'PREPARING', 50.00, NULL, NULL),
        (14, 102, 81, N'HN-00000102', N'Honduras Express', N'DELIVERED', 50.00, '2026-07-10', '2026-07-13'),
        (15, 112, 90, N'HN-00000112', N'Honduras Express', N'PREPARING', 80.00, NULL, NULL),
        (16, 120, 91, N'HN-00000120', N'Cargo Expreso', N'DELIVERED', 120.00, '2026-07-20', '2026-07-23'),
        (17, 121, 65, N'HN-00000121', N'Honduras Express', N'SHIPPED', 80.00, '2026-07-21', NULL),
        (18, 131, 64, N'HN-00000131', N'Servientrega', N'SHIPPED', 120.00, '2026-07-24', NULL),
        (19, 142, 75, N'HN-00000142', N'Servientrega', N'SHIPPED', 80.00, '2026-07-31', NULL),
        (20, 162, 75, N'HN-00000162', N'Cargo Expreso', N'DELIVERED', 120.00, '2026-08-08', '2026-08-11'),
        (21, 163, 79, N'HN-00000163', N'Servientrega', N'SHIPPED', 50.00, '2026-08-08', NULL),
        (22, 164, 66, N'HN-00000164', N'Cargo Expreso', N'DELIVERED', 50.00, '2026-08-10', '2026-08-13'),
        (23, 178, 60, N'HN-00000178', N'Cargo Expreso', N'DELIVERED', 80.00, '2026-08-18', '2026-08-21'),
        (24, 185, 88, N'HN-00000185', N'Cargo Expreso', N'DELIVERED', 120.00, '2026-08-19', '2026-08-22'),
        (25, 186, 63, N'HN-00000186', N'Cargo Expreso', N'SHIPPED', 80.00, '2026-08-20', NULL),
        (26, 187, 63, N'HN-00000187', N'Cargo Expreso', N'DELIVERED', 120.00, '2026-08-20', '2026-08-23'),
        (27, 198, 84, N'HN-00000198', N'Servientrega', N'DELIVERED', 80.00, '2026-08-24', '2026-08-27'),
        (28, 199, 93, N'HN-00000199', N'Honduras Express', N'PREPARING', 80.00, NULL, NULL),
        (29, 207, 82, N'HN-00000207', N'Honduras Express', N'DELIVERED', 80.00, '2026-08-27', '2026-08-30'),
        (30, 212, 84, N'HN-00000212', N'Cargo Expreso', N'DELIVERED', 120.00, '2026-08-28', '2026-08-31'),
        (31, 213, 79, N'HN-00000213', N'Honduras Express', N'DELIVERED', 120.00, '2026-08-29', '2026-09-01'),
        (32, 217, 63, N'HN-00000217', N'Servientrega', N'PREPARING', 120.00, NULL, NULL),
        (33, 222, 81, N'HN-00000222', N'Honduras Express', N'DELIVERED', 50.00, '2026-09-07', '2026-09-10'),
        (34, 223, 78, N'HN-00000223', N'Servientrega', N'DELIVERED', 120.00, '2026-09-08', '2026-09-11'),
        (35, 234, 91, N'HN-00000234', N'Cargo Expreso', N'DELIVERED', 50.00, '2026-09-09', '2026-09-12'),
        (36, 241, 72, N'HN-00000241', N'Servientrega', N'SHIPPED', 80.00, '2026-09-13', NULL),
        (37, 244, 63, N'HN-00000244', N'Servientrega', N'DELIVERED', 80.00, '2026-09-13', '2026-09-16'),
        (38, 248, 77, N'HN-00000248', N'Servientrega', N'DELIVERED', 80.00, '2026-09-17', '2026-09-20'),
        (39, 274, 73, N'HN-00000274', N'Servientrega', N'DELIVERED', 50.00, '2026-09-26', '2026-09-29'),
        (40, 275, 85, N'HN-00000275', N'Servientrega', N'DELIVERED', 80.00, '2026-09-29', '2026-10-02'),
        (41, 290, 79, N'HN-00000290', N'Servientrega', N'DELIVERED', 80.00, '2026-10-02', '2026-10-05'),
        (42, 298, 60, N'HN-00000298', N'Servientrega', N'DELIVERED', 80.00, '2026-10-07', '2026-10-10'),
        (43, 299, 85, N'HN-00000299', N'Honduras Express', N'DELIVERED', 120.00, '2026-10-08', '2026-10-11'),
        (44, 313, 82, N'HN-00000313', N'Servientrega', N'SHIPPED', 80.00, '2026-10-10', NULL),
        (45, 325, 59, N'HN-00000325', N'Cargo Expreso', N'DELIVERED', 50.00, '2026-10-17', '2026-10-20'),
        (46, 328, 87, N'HN-00000328', N'Honduras Express', N'DELIVERED', 80.00, '2026-10-19', '2026-10-22'),
        (47, 337, 87, N'HN-00000337', N'Servientrega', N'PREPARING', 50.00, NULL, NULL),
        (48, 349, 89, N'HN-00000349', N'Servientrega', N'DELIVERED', 80.00, '2026-10-25', '2026-10-28'),
        (49, 350, 68, N'HN-00000350', N'Servientrega', N'DELIVERED', 80.00, '2026-10-26', '2026-10-29'),
        (50, 362, 66, N'HN-00000362', N'Cargo Expreso', N'PREPARING', 50.00, NULL, NULL),
        (51, 375, 85, N'HN-00000375', N'Cargo Expreso', N'PREPARING', 50.00, NULL, NULL),
        (52, 383, 87, N'HN-00000383', N'Cargo Expreso', N'DELIVERED', 80.00, '2026-11-05', '2026-11-08'),
        (53, 384, 61, N'HN-00000384', N'Cargo Expreso', N'DELIVERED', 120.00, '2026-11-06', '2026-11-09'),
        (54, 389, 74, N'HN-00000389', N'Cargo Expreso', N'DELIVERED', 50.00, '2026-11-08', '2026-11-11'),
        (55, 397, 74, N'HN-00000397', N'Servientrega', N'DELIVERED', 80.00, '2026-11-14', '2026-11-17'),
        (56, 398, 65, N'HN-00000398', N'Honduras Express', N'PREPARING', 80.00, NULL, NULL),
        (57, 399, 88, N'HN-00000399', N'Honduras Express', N'DELIVERED', 50.00, '2026-11-15', '2026-11-18'),
        (58, 410, 67, N'HN-00000410', N'Servientrega', N'DELIVERED', 50.00, '2026-11-17', '2026-11-20'),
        (59, 411, 74, N'HN-00000411', N'Servientrega', N'DELIVERED', 80.00, '2026-11-17', '2026-11-20');
    SET IDENTITY_INSERT dbo.Shipment OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.BillDetails)
BEGIN
    SET IDENTITY_INSERT dbo.BillDetails ON;
    INSERT INTO dbo.BillDetails (Id, Bill_Id, ClotheVariant_Id, Quantity, UnitPrice, DiscountAmount, TaxAmount) VALUES
        (1, 1, 80, 1, 1480.00, 177.60, 195.36),
        (2, 1, 35, 2, 760.00, 0, 228.00),
        (3, 2, 127, 2, 240.00, 0, 72.00),
        (4, 3, 154, 3, 210.00, 0, 94.50),
        (5, 4, 65, 1, 1600.00, 0, 240.00),
        (6, 4, 127, 3, 240.00, 0, 108.00),
        (7, 4, 42, 3, 640.00, 0, 288.00),
        (8, 5, 22, 3, 858.00, 0, 386.10),
        (9, 5, 134, 2, 310.00, 0, 93.00),
        (10, 6, 127, 2, 240.00, 0, 72.00),
        (11, 6, 106, 3, 385.00, 0, 173.25),
        (12, 7, 155, 1, 210.00, 0, 31.50),
        (13, 7, 140, 3, 520.00, 312.00, 187.20),
        (14, 8, 70, 2, 1350.00, 324.00, 356.40),
        (15, 8, 86, 1, 560.00, 0, 84.00),
        (16, 9, 97, 1, 480.00, 0, 72.00),
        (17, 9, 52, 1, 950.00, 0, 142.50),
        (18, 10, 152, 3, 1350.00, 0, 607.50),
        (19, 11, 90, 2, 540.00, 0, 162.00),
        (20, 11, 161, 3, 820.00, 0, 369.00),
        (21, 12, 94, 3, 540.00, 0, 243.00),
        (22, 12, 89, 2, 980.00, 0, 294.00),
        (23, 12, 88, 1, 980.00, 0, 147.00),
        (24, 13, 106, 3, 385.00, 0, 173.25),
        (25, 14, 88, 1, 980.00, 0, 147.00),
        (26, 14, 90, 3, 540.00, 0, 243.00),
        (27, 14, 126, 2, 240.00, 0, 72.00),
        (28, 15, 111, 2, 680.00, 0, 204.00),
        (29, 15, 60, 2, 1250.00, 0, 375.00),
        (30, 15, 152, 3, 1350.00, 0, 607.50),
        (31, 16, 152, 1, 1350.00, 0, 202.50),
        (32, 16, 133, 1, 310.00, 0, 46.50),
        (33, 16, 76, 1, 420.00, 50.40, 55.44),
        (34, 17, 152, 1, 1350.00, 0, 202.50),
        (35, 18, 17, 3, 495.00, 267.30, 182.66),
        (36, 18, 106, 1, 385.00, 0, 57.75),
        (37, 18, 133, 3, 310.00, 0, 139.50),
        (38, 19, 85, 3, 320.00, 0, 144.00),
        (39, 20, 124, 2, 264.00, 0, 79.20),
        (40, 20, 15, 1, 450.00, 81.00, 55.35),
        (41, 20, 161, 2, 820.00, 246.00, 209.10),
        (42, 21, 61, 1, 1250.00, 0, 187.50),
        (43, 21, 123, 1, 360.00, 0, 54.00),
        (44, 22, 108, 1, 350.00, 70.00, 42.00),
        (45, 22, 99, 2, 480.00, 0, 144.00),
        (46, 22, 15, 2, 450.00, 0, 135.00),
        (47, 23, 123, 1, 360.00, 0, 54.00),
        (48, 23, 99, 1, 480.00, 0, 72.00),
        (49, 24, 99, 1, 480.00, 0, 72.00),
        (50, 24, 130, 2, 430.00, 0, 129.00),
        (51, 24, 15, 2, 450.00, 0, 135.00),
        (52, 25, 47, 3, 1450.00, 783.00, 535.05),
        (53, 25, 161, 2, 820.00, 246.00, 209.10),
        (54, 26, 10, 1, 418.00, 0, 62.70),
        (55, 27, 42, 1, 640.00, 0, 96.00),
        (56, 28, 76, 2, 420.00, 100.80, 110.88),
        (57, 28, 51, 2, 1100.00, 396.00, 270.60),
        (58, 28, 136, 3, 572.00, 0, 257.40),
        (59, 29, 107, 3, 350.00, 210.00, 126.00),
        (60, 29, 129, 2, 430.00, 0, 129.00),
        (61, 30, 161, 3, 820.00, 0, 369.00),
        (62, 31, 42, 1, 640.00, 115.20, 78.72),
        (63, 32, 76, 3, 420.00, 0, 189.00),
        (64, 33, 32, 1, 760.00, 0, 114.00),
        (65, 33, 63, 3, 1600.00, 0, 720.00),
        (66, 33, 67, 1, 1150.00, 138.00, 151.80),
        (67, 34, 130, 2, 430.00, 0, 129.00),
        (68, 34, 109, 2, 350.00, 140.00, 84.00),
        (69, 34, 13, 1, 380.00, 57.00, 48.45),
        (70, 35, 64, 1, 1600.00, 0, 240.00),
        (71, 36, 67, 1, 1150.00, 0, 172.50),
        (72, 36, 26, 2, 690.00, 0, 207.00),
        (73, 36, 76, 2, 420.00, 0, 126.00),
        (74, 37, 156, 2, 260.00, 0, 78.00),
        (75, 37, 77, 3, 420.00, 0, 189.00),
        (76, 38, 77, 3, 420.00, 0, 189.00),
        (77, 38, 18, 3, 858.00, 0, 386.10),
        (78, 39, 77, 2, 420.00, 0, 126.00),
        (79, 39, 47, 2, 1450.00, 522.00, 356.70),
        (80, 39, 87, 3, 560.00, 0, 252.00),
        (81, 40, 109, 3, 350.00, 0, 157.50),
        (82, 41, 125, 1, 240.00, 0, 36.00),
        (83, 41, 68, 1, 1150.00, 0, 172.50),
        (84, 42, 55, 3, 950.00, 0, 427.50),
        (85, 42, 154, 3, 210.00, 0, 94.50),
        (86, 43, 55, 3, 950.00, 0, 427.50),
        (87, 43, 155, 3, 210.00, 0, 94.50),
        (88, 43, 108, 2, 350.00, 0, 105.00),
        (89, 44, 155, 1, 210.00, 0, 31.50),
        (90, 44, 108, 3, 350.00, 210.00, 126.00),
        (91, 45, 155, 1, 210.00, 0, 31.50),
        (92, 45, 111, 3, 680.00, 0, 306.00),
        (93, 46, 144, 3, 363.00, 217.80, 130.68),
        (94, 46, 4, 2, 420.00, 0, 126.00),
        (95, 46, 112, 3, 680.00, 0, 306.00),
        (96, 47, 6, 1, 560.00, 0, 84.00),
        (97, 47, 48, 3, 1100.00, 594.00, 405.90),
        (98, 47, 127, 2, 240.00, 0, 72.00),
        (99, 48, 98, 2, 480.00, 0, 144.00),
        (100, 49, 54, 1, 950.00, 0, 142.50),
        (101, 49, 116, 1, 590.00, 0, 88.50),
        (102, 49, 30, 2, 720.00, 0, 216.00),
        (103, 50, 138, 3, 572.00, 343.20, 205.92),
        (104, 50, 89, 3, 980.00, 0, 441.00),
        (105, 51, 82, 2, 1480.00, 355.20, 390.72),
        (106, 51, 142, 2, 330.00, 0, 99.00),
        (107, 51, 32, 1, 760.00, 0, 114.00),
        (108, 52, 119, 3, 590.00, 0, 265.50),
        (109, 52, 67, 2, 1150.00, 276.00, 303.60),
        (110, 53, 77, 1, 420.00, 0, 63.00),
        (111, 54, 131, 2, 473.00, 0, 141.90),
        (112, 54, 113, 1, 680.00, 0, 102.00),
        (113, 55, 107, 2, 350.00, 0, 105.00),
        (114, 55, 113, 2, 680.00, 0, 204.00),
        (115, 55, 93, 3, 540.00, 0, 243.00),
        (116, 56, 126, 3, 240.00, 0, 108.00),
        (117, 56, 64, 2, 1600.00, 0, 480.00),
        (118, 56, 137, 1, 572.00, 0, 85.80),
        (119, 57, 8, 2, 560.00, 0, 168.00),
        (120, 57, 29, 1, 720.00, 0, 108.00),
        (121, 57, 141, 1, 330.00, 0, 49.50),
        (122, 58, 29, 3, 720.00, 0, 324.00),
        (123, 58, 118, 3, 590.00, 0, 265.50),
        (124, 58, 142, 2, 330.00, 132.00, 79.20),
        (125, 59, 141, 3, 330.00, 0, 148.50),
        (126, 59, 52, 2, 950.00, 0, 285.00),
        (127, 59, 72, 2, 1350.00, 0, 405.00),
        (128, 60, 29, 3, 720.00, 0, 324.00),
        (129, 60, 122, 1, 360.00, 0, 54.00),
        (130, 61, 54, 3, 950.00, 0, 427.50),
        (131, 61, 72, 3, 1350.00, 486.00, 534.60),
        (132, 61, 143, 2, 330.00, 0, 99.00),
        (133, 62, 81, 1, 1480.00, 177.60, 195.36),
        (134, 63, 64, 1, 1600.00, 0, 240.00),
        (135, 63, 107, 1, 350.00, 0, 52.50),
        (136, 63, 159, 3, 690.00, 0, 310.50),
        (137, 64, 118, 1, 590.00, 0, 88.50),
        (138, 64, 35, 3, 760.00, 0, 342.00),
        (139, 65, 113, 3, 680.00, 0, 306.00),
        (140, 65, 131, 3, 473.00, 0, 212.85),
        (141, 66, 66, 3, 1150.00, 0, 517.50),
        (142, 67, 99, 3, 480.00, 0, 216.00),
        (143, 67, 138, 3, 572.00, 0, 257.40),
        (144, 68, 51, 3, 1100.00, 0, 495.00),
        (145, 68, 132, 1, 341.00, 0, 51.15),
        (146, 69, 41, 1, 640.00, 0, 96.00),
        (147, 69, 99, 2, 480.00, 0, 144.00),
        (148, 70, 99, 1, 480.00, 0, 72.00),
        (149, 70, 138, 2, 572.00, 0, 171.60),
        (150, 70, 41, 2, 640.00, 230.40, 157.44),
        (151, 71, 98, 3, 480.00, 0, 216.00),
        (152, 71, 101, 2, 290.00, 116.00, 69.60),
        (153, 71, 83, 2, 1480.00, 355.20, 390.72),
        (154, 72, 48, 1, 1100.00, 198.00, 135.30),
        (155, 72, 109, 2, 350.00, 0, 105.00),
        (156, 73, 47, 3, 1450.00, 0, 652.50),
        (157, 73, 105, 2, 385.00, 154.00, 92.40),
        (158, 73, 102, 2, 290.00, 116.00, 69.60),
        (159, 74, 157, 3, 260.00, 0, 117.00),
        (160, 74, 100, 3, 290.00, 174.00, 104.40),
        (161, 74, 17, 1, 495.00, 89.10, 60.89),
        (162, 75, 12, 3, 380.00, 205.20, 140.22),
        (163, 75, 99, 1, 480.00, 0, 72.00),
        (164, 75, 123, 3, 360.00, 0, 162.00),
        (165, 76, 12, 1, 380.00, 0, 57.00),
        (166, 77, 92, 3, 594.00, 0, 267.30),
        (167, 77, 94, 2, 540.00, 0, 162.00),
        (168, 77, 30, 1, 720.00, 0, 108.00),
        (169, 78, 159, 3, 690.00, 0, 310.50),
        (170, 78, 3, 3, 420.00, 0, 189.00),
        (171, 79, 126, 1, 240.00, 0, 36.00),
        (172, 80, 18, 3, 858.00, 0, 386.10),
        (173, 81, 140, 1, 520.00, 104.00, 62.40),
        (174, 81, 63, 1, 1600.00, 0, 240.00),
        (175, 81, 101, 2, 290.00, 116.00, 69.60),
        (176, 82, 122, 2, 360.00, 72.00, 97.20),
        (177, 83, 41, 3, 640.00, 0, 288.00),
        (178, 83, 105, 1, 385.00, 77.00, 46.20),
        (179, 84, 144, 2, 363.00, 0, 108.90),
        (180, 85, 128, 2, 473.00, 0, 141.90),
        (181, 85, 143, 1, 330.00, 0, 49.50),
        (182, 85, 77, 3, 420.00, 0, 189.00),
        (183, 86, 41, 3, 640.00, 0, 288.00),
        (184, 86, 105, 1, 385.00, 77.00, 46.20),
        (185, 86, 122, 3, 360.00, 0, 162.00),
        (186, 87, 136, 3, 572.00, 343.20, 205.92),
        (187, 87, 63, 2, 1600.00, 0, 480.00),
        (188, 87, 8, 2, 560.00, 201.60, 137.76),
        (189, 88, 125, 1, 240.00, 0, 36.00),
        (190, 88, 147, 1, 2100.00, 0, 315.00),
        (191, 88, 159, 3, 690.00, 0, 310.50),
        (192, 89, 38, 3, 890.00, 480.60, 328.41),
        (193, 89, 155, 3, 210.00, 0, 94.50),
        (194, 90, 38, 1, 890.00, 0, 133.50),
        (195, 90, 147, 2, 2100.00, 0, 630.00),
        (196, 90, 14, 2, 450.00, 0, 135.00),
        (197, 91, 14, 2, 450.00, 0, 135.00),
        (198, 91, 73, 2, 1350.00, 0, 405.00),
        (199, 92, 129, 2, 430.00, 0, 129.00),
        (200, 92, 116, 3, 590.00, 0, 265.50),
        (201, 93, 17, 2, 495.00, 0, 148.50),
        (202, 94, 106, 1, 385.00, 77.00, 46.20),
        (203, 94, 107, 2, 350.00, 140.00, 84.00),
        (204, 95, 99, 2, 480.00, 0, 144.00),
        (205, 96, 131, 1, 473.00, 0, 70.95),
        (206, 97, 129, 2, 430.00, 0, 129.00),
        (207, 98, 70, 3, 1350.00, 486.00, 534.60),
        (208, 99, 83, 2, 1480.00, 355.20, 390.72),
        (209, 100, 47, 2, 1450.00, 0, 435.00),
        (210, 100, 93, 2, 540.00, 0, 162.00),
        (211, 101, 102, 1, 290.00, 0, 43.50),
        (212, 102, 76, 2, 420.00, 100.80, 110.88),
        (213, 103, 72, 3, 1350.00, 486.00, 534.60),
        (214, 104, 118, 1, 590.00, 0, 88.50),
        (215, 104, 80, 1, 1480.00, 177.60, 195.36),
        (216, 104, 72, 2, 1350.00, 324.00, 356.40),
        (217, 105, 3, 1, 420.00, 75.60, 51.66),
        (218, 106, 122, 1, 360.00, 0, 54.00),
        (219, 106, 141, 2, 330.00, 0, 99.00),
        (220, 106, 80, 2, 1480.00, 0, 444.00),
        (221, 107, 52, 1, 950.00, 0, 142.50),
        (222, 107, 90, 2, 540.00, 0, 162.00),
        (223, 107, 51, 2, 1100.00, 0, 330.00),
        (224, 108, 52, 2, 950.00, 0, 285.00),
        (225, 108, 42, 3, 640.00, 0, 288.00),
        (226, 109, 109, 2, 350.00, 140.00, 84.00),
        (227, 109, 38, 1, 890.00, 160.20, 109.47),
        (228, 110, 57, 3, 1250.00, 0, 562.50),
        (229, 110, 63, 2, 1600.00, 0, 480.00),
        (230, 110, 38, 1, 890.00, 160.20, 109.47),
        (231, 111, 96, 1, 528.00, 0, 79.20),
        (232, 111, 8, 3, 560.00, 302.40, 206.64),
        (233, 111, 52, 2, 950.00, 0, 285.00),
        (234, 112, 42, 3, 640.00, 0, 288.00),
        (235, 113, 29, 1, 720.00, 0, 108.00),
        (236, 113, 36, 1, 890.00, 0, 133.50),
        (237, 114, 77, 2, 420.00, 84.00, 113.40),
        (238, 114, 7, 2, 560.00, 201.60, 137.76),
        (239, 114, 9, 3, 380.00, 0, 171.00),
        (240, 115, 7, 2, 560.00, 201.60, 137.76),
        (241, 115, 60, 3, 1250.00, 0, 562.50),
        (242, 116, 62, 3, 1600.00, 0, 720.00),
        (243, 117, 119, 3, 590.00, 0, 265.50),
        (244, 117, 113, 1, 680.00, 0, 102.00),
        (245, 117, 91, 3, 540.00, 0, 243.00),
        (246, 118, 119, 1, 590.00, 0, 88.50),
        (247, 118, 87, 2, 560.00, 0, 168.00),
        (248, 118, 20, 2, 780.00, 156.00, 210.60),
        (249, 119, 46, 3, 1595.00, 861.30, 588.56),
        (250, 119, 77, 3, 420.00, 0, 189.00),
        (251, 120, 79, 2, 1480.00, 296.00, 399.60),
        (252, 121, 140, 3, 520.00, 312.00, 187.20),
        (253, 121, 155, 3, 210.00, 0, 94.50),
        (254, 122, 126, 3, 240.00, 72.00, 97.20),
        (255, 123, 89, 1, 980.00, 0, 147.00),
        (256, 124, 60, 3, 1250.00, 0, 562.50),
        (257, 125, 87, 3, 560.00, 0, 252.00),
        (258, 125, 55, 1, 950.00, 0, 142.50),
        (259, 126, 87, 2, 560.00, 0, 168.00),
        (260, 126, 108, 2, 350.00, 140.00, 84.00),
        (261, 127, 46, 3, 1595.00, 861.30, 588.56),
        (262, 127, 159, 1, 690.00, 0, 103.50),
        (263, 128, 80, 1, 1480.00, 148.00, 199.80),
        (264, 128, 106, 3, 385.00, 0, 173.25),
        (265, 128, 87, 3, 560.00, 0, 252.00),
        (266, 129, 90, 2, 540.00, 0, 162.00),
        (267, 129, 35, 1, 760.00, 76.00, 102.60),
        (268, 130, 87, 2, 560.00, 0, 168.00),
        (269, 131, 86, 2, 560.00, 0, 168.00),
        (270, 131, 13, 2, 380.00, 0, 114.00),
        (271, 132, 99, 2, 480.00, 0, 144.00),
        (272, 132, 106, 2, 385.00, 154.00, 92.40),
        (273, 133, 99, 1, 480.00, 0, 72.00),
        (274, 133, 47, 3, 1450.00, 783.00, 535.05),
        (275, 133, 21, 3, 780.00, 0, 351.00),
        (276, 134, 38, 2, 890.00, 320.40, 218.94),
        (277, 134, 73, 1, 1350.00, 135.00, 182.25),
        (278, 135, 47, 2, 1450.00, 522.00, 356.70),
        (279, 135, 14, 1, 450.00, 0, 67.50),
        (280, 136, 48, 2, 1100.00, 0, 330.00),
        (281, 136, 123, 1, 360.00, 0, 54.00),
        (282, 136, 106, 2, 385.00, 154.00, 92.40),
        (283, 137, 52, 1, 950.00, 0, 142.50),
        (284, 137, 25, 2, 690.00, 0, 207.00),
        (285, 137, 154, 1, 210.00, 0, 31.50),
        (286, 138, 105, 1, 385.00, 0, 57.75),
        (287, 138, 47, 3, 1450.00, 783.00, 535.05),
        (288, 138, 102, 1, 290.00, 58.00, 34.80),
        (289, 139, 76, 3, 420.00, 0, 189.00),
        (290, 139, 156, 1, 260.00, 0, 39.00),
        (291, 140, 77, 2, 420.00, 0, 126.00),
        (292, 141, 142, 3, 330.00, 198.00, 118.80),
        (293, 141, 77, 2, 420.00, 84.00, 113.40),
        (294, 141, 80, 2, 1480.00, 0, 444.00),
        (295, 142, 42, 2, 640.00, 230.40, 157.44),
        (296, 143, 84, 3, 352.00, 0, 158.40),
        (297, 143, 83, 2, 1480.00, 0, 444.00),
        (298, 144, 83, 3, 1480.00, 444.00, 599.40),
        (299, 144, 84, 3, 352.00, 0, 158.40),
        (300, 145, 84, 1, 352.00, 0, 52.80),
        (301, 145, 46, 2, 1595.00, 0, 478.50),
        (302, 146, 45, 1, 1450.00, 0, 217.50),
        (303, 146, 92, 2, 594.00, 0, 178.20),
        (304, 147, 79, 3, 1480.00, 0, 666.00),
        (305, 148, 56, 3, 950.00, 0, 427.50),
        (306, 148, 124, 3, 264.00, 79.20, 106.92),
        (307, 149, 38, 2, 890.00, 320.40, 218.94),
        (308, 150, 79, 3, 1480.00, 0, 666.00),
        (309, 151, 38, 1, 890.00, 160.20, 109.47),
        (310, 152, 154, 1, 210.00, 0, 31.50),
        (311, 152, 1, 3, 420.00, 226.80, 154.98),
        (312, 153, 73, 1, 1350.00, 135.00, 182.25),
        (313, 153, 25, 3, 690.00, 207.00, 279.45),
        (314, 153, 6, 1, 560.00, 100.80, 68.88),
        (315, 154, 45, 2, 1450.00, 0, 435.00),
        (316, 154, 25, 3, 690.00, 207.00, 279.45),
        (317, 155, 24, 3, 690.00, 0, 310.50),
        (318, 155, 73, 1, 1350.00, 0, 202.50),
        (319, 155, 160, 3, 820.00, 0, 369.00),
        (320, 156, 160, 2, 820.00, 0, 246.00),
        (321, 156, 19, 3, 780.00, 0, 351.00),
        (322, 156, 1, 1, 420.00, 0, 63.00),
        (323, 157, 158, 1, 690.00, 0, 103.50),
        (324, 157, 55, 2, 950.00, 0, 285.00),
        (325, 157, 141, 2, 330.00, 0, 99.00),
        (326, 158, 95, 3, 480.00, 0, 216.00),
        (327, 159, 118, 2, 590.00, 0, 177.00),
        (328, 159, 55, 2, 950.00, 0, 285.00),
        (329, 160, 55, 1, 950.00, 0, 142.50),
        (330, 161, 158, 3, 690.00, 0, 310.50),
        (331, 161, 63, 1, 1600.00, 480.00, 168.00),
        (332, 162, 3, 2, 420.00, 0, 126.00),
        (333, 163, 41, 3, 640.00, 0, 288.00),
        (334, 163, 116, 1, 590.00, 0, 88.50),
        (335, 164, 48, 2, 1100.00, 396.00, 270.60),
        (336, 164, 126, 1, 240.00, 0, 36.00),
        (337, 164, 136, 1, 572.00, 114.40, 68.64),
        (338, 165, 133, 1, 310.00, 0, 46.50),
        (339, 166, 3, 3, 420.00, 226.80, 154.98),
        (340, 166, 133, 1, 310.00, 0, 46.50),
        (341, 167, 94, 2, 540.00, 0, 162.00),
        (342, 168, 82, 2, 1480.00, 355.20, 390.72),
        (343, 168, 139, 1, 520.00, 0, 78.00),
        (344, 169, 28, 1, 720.00, 0, 108.00),
        (345, 169, 154, 3, 210.00, 0, 94.50),
        (346, 169, 104, 3, 290.00, 0, 130.50),
        (347, 170, 139, 1, 520.00, 104.00, 62.40),
        (348, 171, 104, 1, 290.00, 58.00, 34.80),
        (349, 171, 107, 2, 350.00, 140.00, 84.00),
        (350, 171, 143, 1, 330.00, 0, 49.50),
        (351, 172, 132, 2, 341.00, 0, 102.30),
        (352, 173, 75, 2, 420.00, 100.80, 110.88),
        (353, 173, 41, 3, 640.00, 345.60, 236.16),
        (354, 174, 23, 2, 759.00, 0, 227.70),
        (355, 174, 49, 3, 1100.00, 594.00, 405.90),
        (356, 175, 51, 3, 1100.00, 594.00, 405.90),
        (357, 175, 49, 1, 1100.00, 0, 165.00),
        (358, 175, 102, 3, 290.00, 174.00, 104.40),
        (359, 176, 111, 1, 680.00, 0, 102.00),
        (360, 176, 39, 1, 890.00, 160.20, 109.47),
        (361, 177, 75, 3, 420.00, 0, 189.00),
        (362, 177, 128, 2, 473.00, 0, 141.90),
        (363, 177, 144, 3, 363.00, 217.80, 130.68),
        (364, 178, 3, 3, 420.00, 0, 189.00),
        (365, 179, 19, 2, 780.00, 0, 234.00),
        (366, 179, 130, 1, 430.00, 0, 64.50),
        (367, 180, 19, 2, 780.00, 0, 234.00),
        (368, 180, 1, 3, 420.00, 0, 189.00),
        (369, 180, 161, 2, 820.00, 0, 246.00),
        (370, 181, 73, 3, 1350.00, 0, 607.50),
        (371, 182, 154, 2, 210.00, 0, 63.00),
        (372, 183, 73, 2, 1350.00, 324.00, 356.40),
        (373, 183, 38, 3, 890.00, 0, 400.50),
        (374, 184, 1, 1, 420.00, 75.60, 51.66),
        (375, 184, 19, 1, 780.00, 0, 117.00),
        (376, 184, 25, 1, 690.00, 0, 103.50),
        (377, 185, 97, 1, 480.00, 0, 72.00),
        (378, 186, 154, 1, 210.00, 0, 31.50),
        (379, 187, 86, 3, 560.00, 0, 252.00),
        (380, 187, 29, 3, 720.00, 0, 324.00),
        (381, 187, 112, 1, 680.00, 0, 102.00),
        (382, 188, 10, 2, 418.00, 0, 125.40),
        (383, 189, 113, 2, 680.00, 0, 204.00),
        (384, 189, 48, 1, 1100.00, 198.00, 135.30),
        (385, 189, 131, 2, 473.00, 0, 141.90),
        (386, 190, 113, 2, 680.00, 0, 204.00),
        (387, 190, 64, 2, 1600.00, 0, 480.00),
        (388, 190, 63, 1, 1600.00, 480.00, 168.00),
        (389, 191, 108, 2, 350.00, 140.00, 84.00),
        (390, 192, 81, 2, 1480.00, 0, 444.00),
        (391, 192, 113, 2, 680.00, 0, 204.00),
        (392, 193, 108, 2, 350.00, 140.00, 84.00),
        (393, 193, 152, 3, 1350.00, 1215.00, 425.25),
        (394, 193, 20, 2, 780.00, 0, 234.00),
        (395, 194, 50, 1, 1210.00, 0, 181.50),
        (396, 194, 74, 2, 420.00, 100.80, 110.88),
        (397, 195, 56, 1, 950.00, 285.00, 99.75),
        (398, 195, 54, 2, 950.00, 0, 285.00),
        (399, 195, 142, 2, 330.00, 132.00, 79.20),
        (400, 196, 142, 2, 330.00, 0, 99.00);
    INSERT INTO dbo.BillDetails (Id, Bill_Id, ClotheVariant_Id, Quantity, UnitPrice, DiscountAmount, TaxAmount) VALUES
        (401, 196, 43, 3, 704.00, 380.16, 259.78),
        (402, 197, 4, 2, 420.00, 151.20, 103.32),
        (403, 197, 120, 3, 360.00, 108.00, 145.80),
        (404, 198, 159, 3, 690.00, 0, 310.50),
        (405, 198, 7, 3, 560.00, 0, 252.00),
        (406, 198, 155, 1, 210.00, 0, 31.50),
        (407, 199, 54, 2, 950.00, 0, 285.00),
        (408, 199, 70, 3, 1350.00, 486.00, 534.60),
        (409, 200, 42, 3, 640.00, 345.60, 236.16),
        (410, 201, 19, 1, 780.00, 0, 117.00),
        (411, 201, 18, 3, 858.00, 0, 386.10),
        (412, 201, 64, 2, 1600.00, 0, 480.00),
        (413, 202, 130, 3, 430.00, 0, 193.50),
        (414, 202, 13, 3, 380.00, 205.20, 140.22),
        (415, 202, 77, 2, 420.00, 0, 126.00),
        (416, 203, 101, 3, 290.00, 174.00, 104.40),
        (417, 203, 15, 2, 450.00, 162.00, 110.70),
        (418, 203, 18, 3, 858.00, 0, 386.10),
        (419, 204, 77, 1, 420.00, 50.40, 55.44),
        (420, 204, 18, 2, 858.00, 0, 257.40),
        (421, 205, 101, 3, 290.00, 174.00, 104.40),
        (422, 205, 109, 2, 350.00, 0, 105.00),
        (423, 206, 42, 1, 640.00, 0, 96.00),
        (424, 206, 8, 3, 560.00, 0, 252.00),
        (425, 206, 66, 2, 1150.00, 0, 345.00),
        (426, 207, 140, 1, 520.00, 0, 78.00),
        (427, 208, 153, 3, 1350.00, 1215.00, 425.25),
        (428, 208, 46, 1, 1595.00, 287.10, 196.19),
        (429, 208, 47, 3, 1450.00, 783.00, 535.05),
        (430, 209, 153, 3, 1350.00, 1215.00, 425.25),
        (431, 209, 46, 2, 1595.00, 0, 478.50),
        (432, 209, 20, 1, 780.00, 0, 117.00),
        (433, 210, 159, 2, 690.00, 0, 207.00),
        (434, 210, 157, 2, 260.00, 0, 78.00),
        (435, 211, 36, 2, 890.00, 0, 267.00),
        (436, 212, 120, 2, 360.00, 0, 108.00),
        (437, 213, 124, 1, 264.00, 26.40, 35.64),
        (438, 213, 147, 3, 2100.00, 1890.00, 661.50),
        (439, 214, 87, 1, 560.00, 0, 84.00),
        (440, 214, 10, 3, 418.00, 225.72, 154.24),
        (441, 214, 127, 2, 240.00, 48.00, 64.80),
        (442, 215, 87, 1, 560.00, 0, 84.00),
        (443, 215, 51, 1, 1100.00, 198.00, 135.30),
        (444, 216, 116, 2, 590.00, 0, 177.00),
        (445, 217, 154, 3, 210.00, 0, 94.50),
        (446, 217, 120, 2, 360.00, 0, 108.00),
        (447, 218, 155, 3, 210.00, 0, 94.50),
        (448, 218, 119, 2, 590.00, 0, 177.00),
        (449, 218, 96, 3, 528.00, 0, 237.60),
        (450, 219, 83, 1, 1480.00, 177.60, 195.36),
        (451, 219, 135, 2, 310.00, 0, 93.00),
        (452, 220, 135, 1, 310.00, 0, 46.50),
        (453, 220, 38, 2, 890.00, 0, 267.00),
        (454, 220, 62, 2, 1600.00, 960.00, 336.00),
        (455, 221, 62, 2, 1600.00, 0, 480.00),
        (456, 222, 96, 2, 528.00, 0, 158.40),
        (457, 222, 115, 3, 590.00, 0, 265.50),
        (458, 222, 54, 1, 950.00, 285.00, 99.75),
        (459, 223, 52, 2, 950.00, 0, 285.00),
        (460, 223, 126, 1, 240.00, 24.00, 32.40),
        (461, 223, 63, 1, 1600.00, 0, 240.00),
        (462, 224, 94, 1, 540.00, 0, 81.00),
        (463, 224, 27, 2, 720.00, 0, 216.00),
        (464, 225, 48, 2, 1100.00, 396.00, 270.60),
        (465, 225, 57, 2, 1250.00, 750.00, 262.50),
        (466, 225, 127, 2, 240.00, 48.00, 64.80),
        (467, 226, 2, 2, 420.00, 151.20, 103.32),
        (468, 227, 107, 2, 350.00, 0, 105.00),
        (469, 227, 118, 3, 590.00, 0, 265.50),
        (470, 227, 104, 2, 290.00, 0, 87.00),
        (471, 228, 2, 1, 420.00, 75.60, 51.66),
        (472, 228, 82, 1, 1480.00, 177.60, 195.36),
        (473, 228, 28, 3, 720.00, 540.00, 243.00),
        (474, 229, 47, 3, 1450.00, 783.00, 535.05),
        (475, 229, 27, 2, 720.00, 360.00, 162.00),
        (476, 230, 89, 1, 980.00, 0, 147.00),
        (477, 231, 82, 3, 1480.00, 532.80, 586.08),
        (478, 231, 154, 2, 210.00, 0, 63.00),
        (479, 231, 143, 3, 330.00, 0, 148.50),
        (480, 232, 79, 3, 1480.00, 0, 666.00),
        (481, 232, 38, 1, 890.00, 0, 133.50),
        (482, 233, 152, 1, 1350.00, 405.00, 141.75),
        (483, 233, 143, 1, 330.00, 0, 49.50),
        (484, 233, 82, 2, 1480.00, 0, 444.00),
        (485, 234, 55, 1, 950.00, 0, 142.50),
        (486, 235, 10, 1, 418.00, 0, 62.70),
        (487, 235, 12, 1, 380.00, 68.40, 46.74),
        (488, 236, 1, 3, 420.00, 226.80, 154.98),
        (489, 237, 110, 2, 680.00, 0, 204.00),
        (490, 237, 72, 2, 1350.00, 324.00, 356.40),
        (491, 238, 11, 3, 380.00, 0, 171.00),
        (492, 238, 116, 1, 590.00, 0, 88.50),
        (493, 238, 156, 2, 260.00, 0, 78.00),
        (494, 239, 94, 2, 540.00, 0, 162.00),
        (495, 239, 2, 2, 420.00, 151.20, 103.32),
        (496, 239, 146, 3, 2100.00, 1890.00, 661.50),
        (497, 240, 151, 1, 1485.00, 445.50, 155.93),
        (498, 240, 107, 3, 350.00, 0, 157.50),
        (499, 241, 13, 1, 380.00, 0, 57.00),
        (500, 241, 136, 1, 572.00, 0, 85.80),
        (501, 242, 100, 3, 290.00, 0, 130.50),
        (502, 243, 159, 1, 690.00, 0, 103.50),
        (503, 244, 126, 1, 240.00, 0, 36.00),
        (504, 245, 8, 1, 560.00, 0, 84.00),
        (505, 245, 13, 2, 380.00, 0, 114.00),
        (506, 246, 99, 1, 480.00, 0, 72.00),
        (507, 247, 5, 2, 560.00, 201.60, 137.76),
        (508, 247, 138, 2, 572.00, 0, 171.60),
        (509, 247, 151, 1, 1485.00, 445.50, 155.93),
        (510, 248, 10, 3, 418.00, 0, 188.10),
        (511, 248, 144, 1, 363.00, 0, 54.45),
        (512, 248, 52, 2, 950.00, 570.00, 199.50),
        (513, 249, 98, 1, 480.00, 72.00, 61.20),
        (514, 249, 140, 2, 520.00, 0, 156.00),
        (515, 250, 89, 2, 980.00, 0, 294.00),
        (516, 250, 151, 3, 1485.00, 0, 668.25),
        (517, 251, 98, 2, 480.00, 144.00, 122.40),
        (518, 251, 59, 2, 1250.00, 750.00, 262.50),
        (519, 251, 86, 1, 560.00, 0, 84.00),
        (520, 252, 111, 3, 680.00, 0, 306.00),
        (521, 253, 141, 1, 330.00, 0, 49.50),
        (522, 253, 118, 2, 590.00, 0, 177.00),
        (523, 253, 130, 3, 430.00, 258.00, 154.80),
        (524, 254, 118, 1, 590.00, 0, 88.50),
        (525, 255, 34, 1, 760.00, 0, 114.00),
        (526, 255, 2, 1, 420.00, 0, 63.00),
        (527, 256, 92, 3, 594.00, 0, 267.30),
        (528, 256, 139, 2, 520.00, 0, 156.00),
        (529, 257, 81, 2, 1480.00, 0, 444.00),
        (530, 257, 130, 1, 430.00, 0, 64.50),
        (531, 258, 154, 2, 210.00, 0, 63.00),
        (532, 259, 119, 3, 590.00, 0, 265.50),
        (533, 259, 57, 3, 1250.00, 1125.00, 393.75),
        (534, 260, 41, 1, 640.00, 0, 96.00),
        (535, 260, 1, 3, 420.00, 226.80, 154.98),
        (536, 260, 46, 3, 1595.00, 0, 717.75),
        (537, 261, 57, 2, 1250.00, 750.00, 262.50),
        (538, 261, 55, 1, 950.00, 285.00, 99.75),
        (539, 262, 108, 1, 350.00, 0, 52.50),
        (540, 262, 57, 1, 1250.00, 0, 187.50),
        (541, 262, 19, 2, 780.00, 0, 234.00),
        (542, 263, 108, 3, 350.00, 0, 157.50),
        (543, 264, 7, 1, 560.00, 100.80, 68.88),
        (544, 264, 52, 1, 950.00, 0, 142.50),
        (545, 264, 63, 1, 1600.00, 480.00, 168.00),
        (546, 265, 77, 1, 420.00, 50.40, 55.44),
        (547, 265, 145, 3, 2100.00, 1890.00, 661.50),
        (548, 265, 96, 3, 528.00, 0, 237.60),
        (549, 266, 122, 1, 360.00, 0, 54.00),
        (550, 267, 80, 1, 1480.00, 177.60, 195.36),
        (551, 267, 89, 2, 980.00, 0, 294.00),
        (552, 267, 106, 2, 385.00, 0, 115.50),
        (553, 268, 35, 1, 760.00, 0, 114.00),
        (554, 268, 142, 1, 330.00, 0, 49.50),
        (555, 268, 80, 2, 1480.00, 0, 444.00),
        (556, 269, 35, 3, 760.00, 0, 342.00),
        (557, 269, 65, 1, 1600.00, 480.00, 168.00),
        (558, 270, 10, 2, 418.00, 150.48, 102.83),
        (559, 270, 52, 3, 950.00, 0, 427.50),
        (560, 271, 65, 1, 1600.00, 0, 240.00),
        (561, 272, 141, 1, 330.00, 0, 49.50),
        (562, 273, 80, 3, 1480.00, 0, 666.00),
        (563, 273, 143, 2, 330.00, 0, 99.00),
        (564, 273, 122, 2, 360.00, 72.00, 97.20),
        (565, 274, 54, 2, 950.00, 570.00, 199.50),
        (566, 275, 59, 2, 1250.00, 0, 375.00),
        (567, 275, 84, 3, 352.00, 0, 158.40),
        (568, 276, 144, 3, 363.00, 0, 163.35),
        (569, 276, 28, 1, 720.00, 0, 108.00),
        (570, 277, 146, 2, 2100.00, 0, 630.00),
        (571, 277, 4, 3, 420.00, 226.80, 154.98),
        (572, 277, 6, 3, 560.00, 0, 252.00),
        (573, 278, 112, 1, 680.00, 0, 102.00),
        (574, 278, 28, 3, 720.00, 0, 324.00),
        (575, 278, 16, 3, 495.00, 267.30, 182.66),
        (576, 279, 144, 2, 363.00, 0, 108.90),
        (577, 280, 4, 2, 420.00, 151.20, 103.32),
        (578, 280, 155, 1, 210.00, 0, 31.50),
        (579, 281, 4, 2, 420.00, 0, 126.00),
        (580, 282, 108, 3, 350.00, 0, 157.50),
        (581, 283, 63, 3, 1600.00, 0, 720.00),
        (582, 283, 113, 2, 680.00, 0, 204.00),
        (583, 284, 48, 1, 1100.00, 0, 165.00),
        (584, 284, 58, 2, 1250.00, 750.00, 262.50),
        (585, 285, 133, 2, 310.00, 124.00, 74.40),
        (586, 285, 130, 1, 430.00, 86.00, 51.60),
        (587, 285, 10, 3, 418.00, 0, 188.10),
        (588, 286, 63, 1, 1600.00, 0, 240.00),
        (589, 286, 159, 2, 690.00, 0, 207.00),
        (590, 287, 129, 2, 430.00, 172.00, 103.20),
        (591, 288, 137, 2, 572.00, 0, 171.60),
        (592, 289, 81, 2, 1480.00, 0, 444.00),
        (593, 289, 10, 3, 418.00, 225.72, 154.24),
        (594, 290, 63, 3, 1600.00, 0, 720.00),
        (595, 290, 38, 2, 890.00, 0, 267.00),
        (596, 291, 105, 3, 385.00, 0, 173.25),
        (597, 292, 94, 3, 540.00, 0, 243.00),
        (598, 292, 105, 3, 385.00, 0, 173.25),
        (599, 292, 136, 1, 572.00, 0, 85.80),
        (600, 293, 111, 1, 680.00, 0, 102.00),
        (601, 293, 105, 1, 385.00, 0, 57.75),
        (602, 294, 67, 3, 1150.00, 0, 517.50),
        (603, 294, 60, 2, 1250.00, 0, 375.00),
        (604, 295, 125, 1, 240.00, 0, 36.00),
        (605, 295, 105, 1, 385.00, 0, 57.75),
        (606, 295, 143, 3, 330.00, 0, 148.50),
        (607, 296, 75, 2, 420.00, 100.80, 110.88),
        (608, 296, 145, 2, 2100.00, 1260.00, 441.00),
        (609, 296, 144, 2, 363.00, 0, 108.90),
        (610, 297, 143, 2, 330.00, 0, 99.00),
        (611, 297, 128, 3, 473.00, 0, 212.85),
        (612, 297, 75, 1, 420.00, 50.40, 55.44),
        (613, 298, 145, 2, 2100.00, 1260.00, 441.00),
        (614, 299, 83, 1, 1480.00, 177.60, 195.36),
        (615, 299, 125, 1, 240.00, 0, 36.00),
        (616, 300, 95, 3, 480.00, 0, 216.00),
        (617, 300, 55, 1, 950.00, 285.00, 99.75),
        (618, 301, 119, 2, 590.00, 0, 177.00),
        (619, 301, 83, 3, 1480.00, 532.80, 586.08),
        (620, 302, 118, 3, 590.00, 0, 265.50),
        (621, 302, 55, 2, 950.00, 0, 285.00),
        (622, 302, 21, 2, 780.00, 0, 234.00),
        (623, 303, 38, 3, 890.00, 0, 400.50),
        (624, 303, 62, 2, 1600.00, 960.00, 336.00),
        (625, 304, 2, 1, 420.00, 75.60, 51.66),
        (626, 304, 141, 3, 330.00, 0, 148.50),
        (627, 304, 83, 3, 1480.00, 532.80, 586.08),
        (628, 305, 129, 3, 430.00, 258.00, 154.80),
        (629, 305, 67, 3, 1150.00, 0, 517.50),
        (630, 306, 87, 1, 560.00, 196.00, 54.60),
        (631, 306, 67, 2, 1150.00, 276.00, 303.60),
        (632, 307, 130, 1, 430.00, 86.00, 51.60),
        (633, 307, 139, 3, 520.00, 0, 234.00),
        (634, 308, 81, 1, 1480.00, 177.60, 195.36),
        (635, 309, 62, 3, 1600.00, 1440.00, 504.00),
        (636, 309, 135, 1, 310.00, 0, 46.50),
        (637, 310, 62, 1, 1600.00, 480.00, 168.00),
        (638, 310, 67, 3, 1150.00, 0, 517.50),
        (639, 310, 87, 1, 560.00, 196.00, 54.60),
        (640, 311, 12, 3, 380.00, 205.20, 140.22),
        (641, 312, 156, 1, 260.00, 91.00, 25.35),
        (642, 313, 147, 3, 2100.00, 0, 945.00),
        (643, 313, 77, 2, 420.00, 100.80, 110.88),
        (644, 313, 52, 1, 950.00, 0, 142.50),
        (645, 314, 125, 1, 240.00, 0, 36.00),
        (646, 314, 90, 2, 540.00, 0, 162.00),
        (647, 314, 156, 2, 260.00, 0, 78.00),
        (648, 315, 156, 3, 260.00, 273.00, 76.05),
        (649, 316, 113, 1, 680.00, 0, 102.00),
        (650, 317, 91, 2, 540.00, 0, 162.00),
        (651, 317, 42, 1, 640.00, 0, 96.00),
        (652, 318, 119, 3, 590.00, 0, 265.50),
        (653, 319, 56, 2, 950.00, 0, 285.00),
        (654, 319, 96, 1, 528.00, 0, 79.20),
        (655, 320, 74, 2, 420.00, 0, 126.00),
        (656, 321, 99, 3, 480.00, 0, 216.00),
        (657, 321, 1, 3, 420.00, 0, 189.00),
        (658, 321, 26, 1, 690.00, 0, 103.50),
        (659, 322, 50, 1, 1210.00, 217.80, 148.83),
        (660, 323, 48, 3, 1100.00, 594.00, 405.90),
        (661, 324, 144, 3, 363.00, 0, 163.35),
        (662, 325, 12, 2, 380.00, 0, 114.00),
        (663, 325, 155, 3, 210.00, 220.50, 61.43),
        (664, 326, 59, 1, 1250.00, 0, 187.50),
        (665, 326, 89, 3, 980.00, 0, 441.00),
        (666, 326, 98, 1, 480.00, 105.60, 56.16),
        (667, 327, 86, 2, 560.00, 392.00, 109.20),
        (668, 327, 89, 3, 980.00, 1029.00, 286.65),
        (669, 327, 111, 1, 680.00, 0, 102.00),
        (670, 328, 17, 2, 495.00, 178.20, 121.77),
        (671, 329, 92, 2, 594.00, 0, 178.20),
        (672, 329, 59, 1, 1250.00, 375.00, 131.25),
        (673, 329, 151, 1, 1485.00, 445.50, 155.93),
        (674, 330, 120, 1, 360.00, 36.00, 48.60),
        (675, 330, 29, 1, 720.00, 0, 108.00),
        (676, 330, 86, 1, 560.00, 0, 84.00),
        (677, 331, 136, 3, 572.00, 0, 257.40),
        (678, 331, 77, 2, 420.00, 100.80, 110.88),
        (679, 332, 86, 1, 560.00, 0, 84.00),
        (680, 333, 136, 1, 572.00, 0, 85.80),
        (681, 333, 48, 2, 1100.00, 0, 330.00),
        (682, 333, 155, 3, 210.00, 0, 94.50),
        (683, 334, 80, 1, 1480.00, 0, 222.00),
        (684, 334, 136, 2, 572.00, 0, 171.60),
        (685, 335, 144, 1, 363.00, 0, 54.45),
        (686, 336, 142, 2, 330.00, 0, 99.00),
        (687, 336, 32, 2, 760.00, 0, 228.00),
        (688, 336, 155, 3, 210.00, 0, 94.50),
        (689, 337, 48, 3, 1100.00, 0, 495.00),
        (690, 337, 126, 2, 240.00, 48.00, 64.80),
        (691, 338, 130, 3, 430.00, 0, 193.50),
        (692, 338, 46, 1, 1595.00, 287.10, 196.19),
        (693, 338, 47, 1, 1450.00, 261.00, 178.35),
        (694, 339, 134, 3, 310.00, 0, 139.50),
        (695, 340, 46, 3, 1595.00, 0, 717.75),
        (696, 341, 61, 1, 1250.00, 375.00, 131.25),
        (697, 341, 52, 2, 950.00, 570.00, 199.50),
        (698, 342, 153, 1, 1350.00, 405.00, 141.75),
        (699, 343, 61, 1, 1250.00, 375.00, 131.25),
        (700, 343, 125, 2, 240.00, 0, 72.00),
        (701, 344, 6, 2, 560.00, 0, 168.00),
        (702, 345, 131, 1, 473.00, 0, 70.95),
        (703, 345, 133, 3, 310.00, 0, 139.50),
        (704, 346, 118, 1, 590.00, 0, 88.50),
        (705, 347, 6, 2, 560.00, 0, 168.00),
        (706, 347, 42, 3, 640.00, 0, 288.00),
        (707, 347, 12, 3, 380.00, 205.20, 140.22),
        (708, 348, 63, 1, 1600.00, 0, 240.00),
        (709, 348, 111, 3, 680.00, 0, 306.00),
        (710, 348, 112, 3, 680.00, 0, 306.00),
        (711, 349, 13, 3, 380.00, 0, 171.00),
        (712, 350, 155, 1, 210.00, 73.50, 20.48),
        (713, 350, 101, 1, 290.00, 0, 43.50),
        (714, 350, 97, 1, 480.00, 105.60, 56.16),
        (715, 351, 63, 1, 1600.00, 0, 240.00),
        (716, 351, 13, 2, 380.00, 136.80, 93.48),
        (717, 352, 76, 1, 420.00, 50.40, 55.44),
        (718, 353, 62, 2, 1600.00, 960.00, 336.00),
        (719, 353, 42, 2, 640.00, 0, 192.00),
        (720, 354, 77, 2, 420.00, 100.80, 110.88),
        (721, 354, 106, 2, 385.00, 169.40, 90.09),
        (722, 355, 46, 3, 1595.00, 861.30, 588.56),
        (723, 356, 86, 1, 560.00, 196.00, 54.60),
        (724, 357, 80, 2, 1480.00, 355.20, 390.72),
        (725, 357, 28, 2, 720.00, 0, 216.00),
        (726, 357, 155, 2, 210.00, 147.00, 40.95),
        (727, 358, 19, 3, 780.00, 0, 351.00),
        (728, 358, 142, 2, 330.00, 0, 99.00),
        (729, 359, 32, 1, 760.00, 0, 114.00),
        (730, 360, 29, 3, 720.00, 0, 324.00),
        (731, 360, 45, 2, 1450.00, 0, 435.00),
        (732, 360, 38, 2, 890.00, 0, 267.00),
        (733, 361, 39, 1, 890.00, 0, 133.50),
        (734, 361, 77, 3, 420.00, 0, 189.00),
        (735, 361, 60, 1, 1250.00, 375.00, 131.25),
        (736, 362, 53, 2, 950.00, 570.00, 199.50),
        (737, 362, 3, 2, 420.00, 151.20, 103.32),
        (738, 363, 36, 1, 890.00, 160.20, 109.47),
        (739, 364, 38, 2, 890.00, 320.40, 218.94),
        (740, 365, 38, 2, 890.00, 320.40, 218.94),
        (741, 366, 142, 1, 330.00, 0, 49.50),
        (742, 366, 132, 1, 341.00, 0, 51.15),
        (743, 366, 71, 2, 1350.00, 324.00, 356.40),
        (744, 367, 71, 2, 1350.00, 324.00, 356.40),
        (745, 367, 84, 2, 352.00, 246.40, 68.64),
        (746, 367, 43, 1, 704.00, 0, 105.60),
        (747, 368, 98, 3, 480.00, 316.80, 168.48),
        (748, 368, 127, 2, 240.00, 48.00, 64.80),
        (749, 369, 84, 3, 352.00, 369.60, 102.96),
        (750, 370, 71, 2, 1350.00, 0, 405.00),
        (751, 370, 142, 1, 330.00, 0, 49.50),
        (752, 371, 79, 3, 1480.00, 532.80, 586.08),
        (753, 371, 54, 3, 950.00, 0, 427.50),
        (754, 371, 46, 3, 1595.00, 861.30, 588.56),
        (755, 372, 77, 3, 420.00, 151.20, 166.32),
        (756, 372, 40, 2, 640.00, 230.40, 157.44),
        (757, 372, 7, 3, 560.00, 302.40, 206.64),
        (758, 373, 9, 3, 380.00, 0, 171.00),
        (759, 373, 57, 1, 1250.00, 0, 187.50),
        (760, 373, 42, 2, 640.00, 230.40, 157.44),
        (761, 374, 59, 3, 1250.00, 0, 562.50),
        (762, 374, 153, 3, 1350.00, 0, 607.50),
        (763, 374, 112, 3, 680.00, 244.80, 269.28),
        (764, 375, 113, 3, 680.00, 0, 306.00),
        (765, 375, 85, 1, 320.00, 112.00, 31.20),
        (766, 375, 51, 3, 1100.00, 0, 495.00),
        (767, 376, 131, 3, 473.00, 0, 212.85),
        (768, 377, 128, 3, 473.00, 0, 212.85),
        (769, 377, 40, 1, 640.00, 0, 96.00),
        (770, 377, 38, 3, 890.00, 480.60, 328.41),
        (771, 378, 40, 3, 640.00, 345.60, 236.16),
        (772, 379, 59, 1, 1250.00, 0, 187.50),
        (773, 380, 57, 2, 1250.00, 0, 375.00),
        (774, 380, 9, 1, 380.00, 68.40, 46.74),
        (775, 381, 9, 2, 380.00, 136.80, 93.48),
        (776, 381, 19, 3, 780.00, 0, 351.00),
        (777, 382, 142, 3, 330.00, 0, 148.50),
        (778, 383, 79, 3, 1480.00, 0, 666.00),
        (779, 384, 41, 3, 640.00, 0, 288.00),
        (780, 384, 115, 2, 590.00, 0, 177.00),
        (781, 384, 69, 1, 1265.00, 0, 189.75),
        (782, 385, 57, 1, 1250.00, 0, 187.50),
        (783, 386, 10, 2, 418.00, 150.48, 102.83),
        (784, 387, 93, 3, 540.00, 0, 243.00),
        (785, 387, 47, 1, 1450.00, 261.00, 178.35),
        (786, 387, 10, 1, 418.00, 0, 62.70),
        (787, 388, 10, 3, 418.00, 225.72, 154.24),
        (788, 388, 94, 1, 540.00, 0, 81.00),
        (789, 389, 154, 2, 210.00, 0, 63.00),
        (790, 389, 108, 2, 350.00, 154.00, 81.90),
        (791, 389, 42, 3, 640.00, 345.60, 236.16),
        (792, 390, 130, 2, 430.00, 0, 129.00),
        (793, 391, 151, 2, 1485.00, 0, 445.50),
        (794, 392, 87, 2, 560.00, 0, 168.00),
        (795, 392, 151, 1, 1485.00, 0, 222.75),
        (796, 393, 58, 3, 1250.00, 0, 562.50),
        (797, 393, 102, 2, 290.00, 0, 87.00),
        (798, 394, 11, 3, 380.00, 205.20, 140.22),
        (799, 394, 151, 2, 1485.00, 0, 445.50),
        (800, 395, 58, 3, 1250.00, 0, 562.50);
    INSERT INTO dbo.BillDetails (Id, Bill_Id, ClotheVariant_Id, Quantity, UnitPrice, DiscountAmount, TaxAmount) VALUES
        (801, 395, 156, 2, 260.00, 182.00, 50.70),
        (802, 395, 116, 2, 590.00, 0, 177.00),
        (803, 396, 72, 1, 1350.00, 0, 202.50),
        (804, 396, 11, 2, 380.00, 0, 114.00),
        (805, 397, 125, 3, 240.00, 72.00, 97.20),
        (806, 397, 3, 3, 420.00, 226.80, 154.98),
        (807, 398, 156, 1, 260.00, 91.00, 25.35),
        (808, 399, 86, 3, 560.00, 588.00, 163.80),
        (809, 399, 98, 3, 480.00, 0, 216.00),
        (810, 399, 124, 1, 264.00, 26.40, 35.64),
        (811, 400, 50, 1, 1210.00, 0, 181.50),
        (812, 401, 76, 1, 420.00, 0, 63.00),
        (813, 402, 63, 1, 1600.00, 0, 240.00),
        (814, 402, 142, 3, 330.00, 0, 148.50),
        (815, 403, 26, 1, 690.00, 0, 103.50),
        (816, 404, 32, 1, 760.00, 0, 114.00),
        (817, 405, 114, 2, 748.00, 179.52, 197.47),
        (818, 405, 82, 2, 1480.00, 355.20, 390.72),
        (819, 405, 96, 1, 528.00, 116.16, 61.78),
        (820, 406, 82, 1, 1480.00, 177.60, 195.36),
        (821, 407, 32, 2, 760.00, 0, 228.00),
        (822, 408, 119, 1, 590.00, 70.80, 77.88),
        (823, 408, 156, 2, 260.00, 0, 78.00),
        (824, 409, 112, 3, 680.00, 0, 306.00),
        (825, 409, 152, 3, 1350.00, 0, 607.50),
        (826, 409, 56, 2, 950.00, 0, 285.00),
        (827, 410, 143, 3, 330.00, 0, 148.50),
        (828, 410, 51, 3, 1100.00, 594.00, 405.90),
        (829, 410, 4, 2, 420.00, 151.20, 103.32),
        (830, 411, 112, 3, 680.00, 0, 306.00),
        (831, 411, 154, 1, 210.00, 0, 31.50),
        (832, 411, 83, 1, 1480.00, 177.60, 195.36),
        (833, 412, 42, 2, 640.00, 230.40, 157.44),
        (834, 412, 46, 1, 1595.00, 0, 239.25),
        (835, 413, 22, 1, 858.00, 0, 128.70),
        (836, 413, 60, 3, 1250.00, 0, 562.50),
        (837, 414, 144, 2, 363.00, 0, 108.90),
        (838, 414, 125, 3, 240.00, 72.00, 97.20),
        (839, 415, 122, 2, 360.00, 0, 108.00),
        (840, 415, 77, 2, 420.00, 100.80, 110.88),
        (841, 416, 122, 1, 360.00, 0, 54.00),
        (842, 416, 128, 2, 473.00, 0, 141.90),
        (843, 416, 47, 1, 1450.00, 0, 217.50),
        (844, 417, 154, 1, 210.00, 0, 31.50),
        (845, 417, 73, 2, 1350.00, 0, 405.00),
        (846, 418, 42, 1, 640.00, 115.20, 78.72),
        (847, 418, 77, 3, 420.00, 151.20, 166.32),
        (848, 419, 52, 2, 950.00, 0, 285.00),
        (849, 419, 130, 1, 430.00, 0, 64.50),
        (850, 419, 19, 1, 780.00, 0, 117.00),
        (851, 420, 130, 3, 430.00, 0, 193.50),
        (852, 420, 1, 1, 420.00, 75.60, 51.66),
        (853, 420, 73, 2, 1350.00, 324.00, 356.40),
        (854, 421, 154, 2, 210.00, 147.00, 40.95),
        (855, 422, 143, 1, 330.00, 0, 49.50),
        (856, 422, 122, 2, 360.00, 0, 108.00),
        (857, 422, 125, 1, 240.00, 0, 36.00),
        (858, 423, 154, 1, 210.00, 73.50, 20.48),
        (859, 423, 38, 3, 890.00, 0, 400.50),
        (860, 424, 52, 1, 950.00, 380.00, 85.50),
        (861, 424, 18, 1, 858.00, 0, 128.70),
        (862, 424, 12, 2, 380.00, 136.80, 93.48),
        (863, 425, 73, 3, 1350.00, 486.00, 534.60),
        (864, 425, 1, 1, 420.00, 75.60, 51.66),
        (865, 426, 89, 3, 980.00, 0, 441.00),
        (866, 426, 140, 1, 520.00, 0, 78.00),
        (867, 426, 98, 3, 480.00, 316.80, 168.48),
        (868, 427, 76, 3, 420.00, 151.20, 166.32),
        (869, 427, 51, 3, 1100.00, 0, 495.00),
        (870, 428, 125, 2, 240.00, 48.00, 64.80),
        (871, 428, 6, 2, 560.00, 201.60, 137.76),
        (872, 428, 52, 2, 950.00, 760.00, 171.00),
        (873, 429, 125, 3, 240.00, 0, 108.00),
        (874, 429, 144, 3, 363.00, 0, 163.35),
        (875, 430, 87, 1, 560.00, 196.00, 54.60),
        (876, 430, 117, 1, 590.00, 236.00, 53.10);
    SET IDENTITY_INSERT dbo.BillDetails OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.AppliedTaxes)
BEGIN
    INSERT INTO dbo.AppliedTaxes (BillDetails_Id, Taxes_Id, Percentage, Amount) VALUES
        (1, 1, 15.00, 195.36),
        (2, 1, 15.00, 228.00),
        (3, 1, 15.00, 72.00),
        (4, 1, 15.00, 94.50),
        (5, 1, 15.00, 240.00),
        (6, 1, 15.00, 108.00),
        (7, 1, 15.00, 288.00),
        (8, 1, 15.00, 386.10),
        (9, 1, 15.00, 93.00),
        (10, 1, 15.00, 72.00),
        (11, 1, 15.00, 173.25),
        (12, 1, 15.00, 31.50),
        (13, 1, 15.00, 187.20),
        (14, 1, 15.00, 356.40),
        (15, 1, 15.00, 84.00),
        (16, 1, 15.00, 72.00),
        (17, 1, 15.00, 142.50),
        (18, 1, 15.00, 607.50),
        (19, 1, 15.00, 162.00),
        (20, 1, 15.00, 369.00),
        (21, 1, 15.00, 243.00),
        (22, 1, 15.00, 294.00),
        (23, 1, 15.00, 147.00),
        (24, 1, 15.00, 173.25),
        (25, 1, 15.00, 147.00),
        (26, 1, 15.00, 243.00),
        (27, 1, 15.00, 72.00),
        (28, 1, 15.00, 204.00),
        (29, 1, 15.00, 375.00),
        (30, 1, 15.00, 607.50),
        (31, 1, 15.00, 202.50),
        (32, 1, 15.00, 46.50),
        (33, 1, 15.00, 55.44),
        (34, 1, 15.00, 202.50),
        (35, 1, 15.00, 182.66),
        (36, 1, 15.00, 57.75),
        (37, 1, 15.00, 139.50),
        (38, 1, 15.00, 144.00),
        (39, 1, 15.00, 79.20),
        (40, 1, 15.00, 55.35),
        (41, 1, 15.00, 209.10),
        (42, 1, 15.00, 187.50),
        (43, 1, 15.00, 54.00),
        (44, 1, 15.00, 42.00),
        (45, 1, 15.00, 144.00),
        (46, 1, 15.00, 135.00),
        (47, 1, 15.00, 54.00),
        (48, 1, 15.00, 72.00),
        (49, 1, 15.00, 72.00),
        (50, 1, 15.00, 129.00),
        (51, 1, 15.00, 135.00),
        (52, 1, 15.00, 535.05),
        (53, 1, 15.00, 209.10),
        (54, 1, 15.00, 62.70),
        (55, 1, 15.00, 96.00),
        (56, 1, 15.00, 110.88),
        (57, 1, 15.00, 270.60),
        (58, 1, 15.00, 257.40),
        (59, 1, 15.00, 126.00),
        (60, 1, 15.00, 129.00),
        (61, 1, 15.00, 369.00),
        (62, 1, 15.00, 78.72),
        (63, 1, 15.00, 189.00),
        (64, 1, 15.00, 114.00),
        (65, 1, 15.00, 720.00),
        (66, 1, 15.00, 151.80),
        (67, 1, 15.00, 129.00),
        (68, 1, 15.00, 84.00),
        (69, 1, 15.00, 48.45),
        (70, 1, 15.00, 240.00),
        (71, 1, 15.00, 172.50),
        (72, 1, 15.00, 207.00),
        (73, 1, 15.00, 126.00),
        (74, 1, 15.00, 78.00),
        (75, 1, 15.00, 189.00),
        (76, 1, 15.00, 189.00),
        (77, 1, 15.00, 386.10),
        (78, 1, 15.00, 126.00),
        (79, 1, 15.00, 356.70),
        (80, 1, 15.00, 252.00),
        (81, 1, 15.00, 157.50),
        (82, 1, 15.00, 36.00),
        (83, 1, 15.00, 172.50),
        (84, 1, 15.00, 427.50),
        (85, 1, 15.00, 94.50),
        (86, 1, 15.00, 427.50),
        (87, 1, 15.00, 94.50),
        (88, 1, 15.00, 105.00),
        (89, 1, 15.00, 31.50),
        (90, 1, 15.00, 126.00),
        (91, 1, 15.00, 31.50),
        (92, 1, 15.00, 306.00),
        (93, 1, 15.00, 130.68),
        (94, 1, 15.00, 126.00),
        (95, 1, 15.00, 306.00),
        (96, 1, 15.00, 84.00),
        (97, 1, 15.00, 405.90),
        (98, 1, 15.00, 72.00),
        (99, 1, 15.00, 144.00),
        (100, 1, 15.00, 142.50),
        (101, 1, 15.00, 88.50),
        (102, 1, 15.00, 216.00),
        (103, 1, 15.00, 205.92),
        (104, 1, 15.00, 441.00),
        (105, 1, 15.00, 390.72),
        (106, 1, 15.00, 99.00),
        (107, 1, 15.00, 114.00),
        (108, 1, 15.00, 265.50),
        (109, 1, 15.00, 303.60),
        (110, 1, 15.00, 63.00),
        (111, 1, 15.00, 141.90),
        (112, 1, 15.00, 102.00),
        (113, 1, 15.00, 105.00),
        (114, 1, 15.00, 204.00),
        (115, 1, 15.00, 243.00),
        (116, 1, 15.00, 108.00),
        (117, 1, 15.00, 480.00),
        (118, 1, 15.00, 85.80),
        (119, 1, 15.00, 168.00),
        (120, 1, 15.00, 108.00),
        (121, 1, 15.00, 49.50),
        (122, 1, 15.00, 324.00),
        (123, 1, 15.00, 265.50),
        (124, 1, 15.00, 79.20),
        (125, 1, 15.00, 148.50),
        (126, 1, 15.00, 285.00),
        (127, 1, 15.00, 405.00),
        (128, 1, 15.00, 324.00),
        (129, 1, 15.00, 54.00),
        (130, 1, 15.00, 427.50),
        (131, 1, 15.00, 534.60),
        (132, 1, 15.00, 99.00),
        (133, 1, 15.00, 195.36),
        (134, 1, 15.00, 240.00),
        (135, 1, 15.00, 52.50),
        (136, 1, 15.00, 310.50),
        (137, 1, 15.00, 88.50),
        (138, 1, 15.00, 342.00),
        (139, 1, 15.00, 306.00),
        (140, 1, 15.00, 212.85),
        (141, 1, 15.00, 517.50),
        (142, 1, 15.00, 216.00),
        (143, 1, 15.00, 257.40),
        (144, 1, 15.00, 495.00),
        (145, 1, 15.00, 51.15),
        (146, 1, 15.00, 96.00),
        (147, 1, 15.00, 144.00),
        (148, 1, 15.00, 72.00),
        (149, 1, 15.00, 171.60),
        (150, 1, 15.00, 157.44),
        (151, 1, 15.00, 216.00),
        (152, 1, 15.00, 69.60),
        (153, 1, 15.00, 390.72),
        (154, 1, 15.00, 135.30),
        (155, 1, 15.00, 105.00),
        (156, 1, 15.00, 652.50),
        (157, 1, 15.00, 92.40),
        (158, 1, 15.00, 69.60),
        (159, 1, 15.00, 117.00),
        (160, 1, 15.00, 104.40),
        (161, 1, 15.00, 60.89),
        (162, 1, 15.00, 140.22),
        (163, 1, 15.00, 72.00),
        (164, 1, 15.00, 162.00),
        (165, 1, 15.00, 57.00),
        (166, 1, 15.00, 267.30),
        (167, 1, 15.00, 162.00),
        (168, 1, 15.00, 108.00),
        (169, 1, 15.00, 310.50),
        (170, 1, 15.00, 189.00),
        (171, 1, 15.00, 36.00),
        (172, 1, 15.00, 386.10),
        (173, 1, 15.00, 62.40),
        (174, 1, 15.00, 240.00),
        (175, 1, 15.00, 69.60),
        (176, 1, 15.00, 97.20),
        (177, 1, 15.00, 288.00),
        (178, 1, 15.00, 46.20),
        (179, 1, 15.00, 108.90),
        (180, 1, 15.00, 141.90),
        (181, 1, 15.00, 49.50),
        (182, 1, 15.00, 189.00),
        (183, 1, 15.00, 288.00),
        (184, 1, 15.00, 46.20),
        (185, 1, 15.00, 162.00),
        (186, 1, 15.00, 205.92),
        (187, 1, 15.00, 480.00),
        (188, 1, 15.00, 137.76),
        (189, 1, 15.00, 36.00),
        (190, 1, 15.00, 315.00),
        (191, 1, 15.00, 310.50),
        (192, 1, 15.00, 328.41),
        (193, 1, 15.00, 94.50),
        (194, 1, 15.00, 133.50),
        (195, 1, 15.00, 630.00),
        (196, 1, 15.00, 135.00),
        (197, 1, 15.00, 135.00),
        (198, 1, 15.00, 405.00),
        (199, 1, 15.00, 129.00),
        (200, 1, 15.00, 265.50),
        (201, 1, 15.00, 148.50),
        (202, 1, 15.00, 46.20),
        (203, 1, 15.00, 84.00),
        (204, 1, 15.00, 144.00),
        (205, 1, 15.00, 70.95),
        (206, 1, 15.00, 129.00),
        (207, 1, 15.00, 534.60),
        (208, 1, 15.00, 390.72),
        (209, 1, 15.00, 435.00),
        (210, 1, 15.00, 162.00),
        (211, 1, 15.00, 43.50),
        (212, 1, 15.00, 110.88),
        (213, 1, 15.00, 534.60),
        (214, 1, 15.00, 88.50),
        (215, 1, 15.00, 195.36),
        (216, 1, 15.00, 356.40),
        (217, 1, 15.00, 51.66),
        (218, 1, 15.00, 54.00),
        (219, 1, 15.00, 99.00),
        (220, 1, 15.00, 444.00),
        (221, 1, 15.00, 142.50),
        (222, 1, 15.00, 162.00),
        (223, 1, 15.00, 330.00),
        (224, 1, 15.00, 285.00),
        (225, 1, 15.00, 288.00),
        (226, 1, 15.00, 84.00),
        (227, 1, 15.00, 109.47),
        (228, 1, 15.00, 562.50),
        (229, 1, 15.00, 480.00),
        (230, 1, 15.00, 109.47),
        (231, 1, 15.00, 79.20),
        (232, 1, 15.00, 206.64),
        (233, 1, 15.00, 285.00),
        (234, 1, 15.00, 288.00),
        (235, 1, 15.00, 108.00),
        (236, 1, 15.00, 133.50),
        (237, 1, 15.00, 113.40),
        (238, 1, 15.00, 137.76),
        (239, 1, 15.00, 171.00),
        (240, 1, 15.00, 137.76),
        (241, 1, 15.00, 562.50),
        (242, 1, 15.00, 720.00),
        (243, 1, 15.00, 265.50),
        (244, 1, 15.00, 102.00),
        (245, 1, 15.00, 243.00),
        (246, 1, 15.00, 88.50),
        (247, 1, 15.00, 168.00),
        (248, 1, 15.00, 210.60),
        (249, 1, 15.00, 588.56),
        (250, 1, 15.00, 189.00),
        (251, 1, 15.00, 399.60),
        (252, 1, 15.00, 187.20),
        (253, 1, 15.00, 94.50),
        (254, 1, 15.00, 97.20),
        (255, 1, 15.00, 147.00),
        (256, 1, 15.00, 562.50),
        (257, 1, 15.00, 252.00),
        (258, 1, 15.00, 142.50),
        (259, 1, 15.00, 168.00),
        (260, 1, 15.00, 84.00),
        (261, 1, 15.00, 588.56),
        (262, 1, 15.00, 103.50),
        (263, 1, 15.00, 199.80),
        (264, 1, 15.00, 173.25),
        (265, 1, 15.00, 252.00),
        (266, 1, 15.00, 162.00),
        (267, 1, 15.00, 102.60),
        (268, 1, 15.00, 168.00),
        (269, 1, 15.00, 168.00),
        (270, 1, 15.00, 114.00),
        (271, 1, 15.00, 144.00),
        (272, 1, 15.00, 92.40),
        (273, 1, 15.00, 72.00),
        (274, 1, 15.00, 535.05),
        (275, 1, 15.00, 351.00),
        (276, 1, 15.00, 218.94),
        (277, 1, 15.00, 182.25),
        (278, 1, 15.00, 356.70),
        (279, 1, 15.00, 67.50),
        (280, 1, 15.00, 330.00),
        (281, 1, 15.00, 54.00),
        (282, 1, 15.00, 92.40),
        (283, 1, 15.00, 142.50),
        (284, 1, 15.00, 207.00),
        (285, 1, 15.00, 31.50),
        (286, 1, 15.00, 57.75),
        (287, 1, 15.00, 535.05),
        (288, 1, 15.00, 34.80),
        (289, 1, 15.00, 189.00),
        (290, 1, 15.00, 39.00),
        (291, 1, 15.00, 126.00),
        (292, 1, 15.00, 118.80),
        (293, 1, 15.00, 113.40),
        (294, 1, 15.00, 444.00),
        (295, 1, 15.00, 157.44),
        (296, 1, 15.00, 158.40),
        (297, 1, 15.00, 444.00),
        (298, 1, 15.00, 599.40),
        (299, 1, 15.00, 158.40),
        (300, 1, 15.00, 52.80),
        (301, 1, 15.00, 478.50),
        (302, 1, 15.00, 217.50),
        (303, 1, 15.00, 178.20),
        (304, 1, 15.00, 666.00),
        (305, 1, 15.00, 427.50),
        (306, 1, 15.00, 106.92),
        (307, 1, 15.00, 218.94),
        (308, 1, 15.00, 666.00),
        (309, 1, 15.00, 109.47),
        (310, 1, 15.00, 31.50),
        (311, 1, 15.00, 154.98),
        (312, 1, 15.00, 182.25),
        (313, 1, 15.00, 279.45),
        (314, 1, 15.00, 68.88),
        (315, 1, 15.00, 435.00),
        (316, 1, 15.00, 279.45),
        (317, 1, 15.00, 310.50),
        (318, 1, 15.00, 202.50),
        (319, 1, 15.00, 369.00),
        (320, 1, 15.00, 246.00),
        (321, 1, 15.00, 351.00),
        (322, 1, 15.00, 63.00),
        (323, 1, 15.00, 103.50),
        (324, 1, 15.00, 285.00),
        (325, 1, 15.00, 99.00),
        (326, 1, 15.00, 216.00),
        (327, 1, 15.00, 177.00),
        (328, 1, 15.00, 285.00),
        (329, 1, 15.00, 142.50),
        (330, 1, 15.00, 310.50),
        (331, 1, 15.00, 168.00),
        (332, 1, 15.00, 126.00),
        (333, 1, 15.00, 288.00),
        (334, 1, 15.00, 88.50),
        (335, 1, 15.00, 270.60),
        (336, 1, 15.00, 36.00),
        (337, 1, 15.00, 68.64),
        (338, 1, 15.00, 46.50),
        (339, 1, 15.00, 154.98),
        (340, 1, 15.00, 46.50),
        (341, 1, 15.00, 162.00),
        (342, 1, 15.00, 390.72),
        (343, 1, 15.00, 78.00),
        (344, 1, 15.00, 108.00),
        (345, 1, 15.00, 94.50),
        (346, 1, 15.00, 130.50),
        (347, 1, 15.00, 62.40),
        (348, 1, 15.00, 34.80),
        (349, 1, 15.00, 84.00),
        (350, 1, 15.00, 49.50),
        (351, 1, 15.00, 102.30),
        (352, 1, 15.00, 110.88),
        (353, 1, 15.00, 236.16),
        (354, 1, 15.00, 227.70),
        (355, 1, 15.00, 405.90),
        (356, 1, 15.00, 405.90),
        (357, 1, 15.00, 165.00),
        (358, 1, 15.00, 104.40),
        (359, 1, 15.00, 102.00),
        (360, 1, 15.00, 109.47),
        (361, 1, 15.00, 189.00),
        (362, 1, 15.00, 141.90),
        (363, 1, 15.00, 130.68),
        (364, 1, 15.00, 189.00),
        (365, 1, 15.00, 234.00),
        (366, 1, 15.00, 64.50),
        (367, 1, 15.00, 234.00),
        (368, 1, 15.00, 189.00),
        (369, 1, 15.00, 246.00),
        (370, 1, 15.00, 607.50),
        (371, 1, 15.00, 63.00),
        (372, 1, 15.00, 356.40),
        (373, 1, 15.00, 400.50),
        (374, 1, 15.00, 51.66),
        (375, 1, 15.00, 117.00),
        (376, 1, 15.00, 103.50),
        (377, 1, 15.00, 72.00),
        (378, 1, 15.00, 31.50),
        (379, 1, 15.00, 252.00),
        (380, 1, 15.00, 324.00),
        (381, 1, 15.00, 102.00),
        (382, 1, 15.00, 125.40),
        (383, 1, 15.00, 204.00),
        (384, 1, 15.00, 135.30),
        (385, 1, 15.00, 141.90),
        (386, 1, 15.00, 204.00),
        (387, 1, 15.00, 480.00),
        (388, 1, 15.00, 168.00),
        (389, 1, 15.00, 84.00),
        (390, 1, 15.00, 444.00),
        (391, 1, 15.00, 204.00),
        (392, 1, 15.00, 84.00),
        (393, 1, 15.00, 425.25),
        (394, 1, 15.00, 234.00),
        (395, 1, 15.00, 181.50),
        (396, 1, 15.00, 110.88),
        (397, 1, 15.00, 99.75),
        (398, 1, 15.00, 285.00),
        (399, 1, 15.00, 79.20),
        (400, 1, 15.00, 99.00);
    INSERT INTO dbo.AppliedTaxes (BillDetails_Id, Taxes_Id, Percentage, Amount) VALUES
        (401, 1, 15.00, 259.78),
        (402, 1, 15.00, 103.32),
        (403, 1, 15.00, 145.80),
        (404, 1, 15.00, 310.50),
        (405, 1, 15.00, 252.00),
        (406, 1, 15.00, 31.50),
        (407, 1, 15.00, 285.00),
        (408, 1, 15.00, 534.60),
        (409, 1, 15.00, 236.16),
        (410, 1, 15.00, 117.00),
        (411, 1, 15.00, 386.10),
        (412, 1, 15.00, 480.00),
        (413, 1, 15.00, 193.50),
        (414, 1, 15.00, 140.22),
        (415, 1, 15.00, 126.00),
        (416, 1, 15.00, 104.40),
        (417, 1, 15.00, 110.70),
        (418, 1, 15.00, 386.10),
        (419, 1, 15.00, 55.44),
        (420, 1, 15.00, 257.40),
        (421, 1, 15.00, 104.40),
        (422, 1, 15.00, 105.00),
        (423, 1, 15.00, 96.00),
        (424, 1, 15.00, 252.00),
        (425, 1, 15.00, 345.00),
        (426, 1, 15.00, 78.00),
        (427, 1, 15.00, 425.25),
        (428, 1, 15.00, 196.19),
        (429, 1, 15.00, 535.05),
        (430, 1, 15.00, 425.25),
        (431, 1, 15.00, 478.50),
        (432, 1, 15.00, 117.00),
        (433, 1, 15.00, 207.00),
        (434, 1, 15.00, 78.00),
        (435, 1, 15.00, 267.00),
        (436, 1, 15.00, 108.00),
        (437, 1, 15.00, 35.64),
        (438, 1, 15.00, 661.50),
        (439, 1, 15.00, 84.00),
        (440, 1, 15.00, 154.24),
        (441, 1, 15.00, 64.80),
        (442, 1, 15.00, 84.00),
        (443, 1, 15.00, 135.30),
        (444, 1, 15.00, 177.00),
        (445, 1, 15.00, 94.50),
        (446, 1, 15.00, 108.00),
        (447, 1, 15.00, 94.50),
        (448, 1, 15.00, 177.00),
        (449, 1, 15.00, 237.60),
        (450, 1, 15.00, 195.36),
        (451, 1, 15.00, 93.00),
        (452, 1, 15.00, 46.50),
        (453, 1, 15.00, 267.00),
        (454, 1, 15.00, 336.00),
        (455, 1, 15.00, 480.00),
        (456, 1, 15.00, 158.40),
        (457, 1, 15.00, 265.50),
        (458, 1, 15.00, 99.75),
        (459, 1, 15.00, 285.00),
        (460, 1, 15.00, 32.40),
        (461, 1, 15.00, 240.00),
        (462, 1, 15.00, 81.00),
        (463, 1, 15.00, 216.00),
        (464, 1, 15.00, 270.60),
        (465, 1, 15.00, 262.50),
        (466, 1, 15.00, 64.80),
        (467, 1, 15.00, 103.32),
        (468, 1, 15.00, 105.00),
        (469, 1, 15.00, 265.50),
        (470, 1, 15.00, 87.00),
        (471, 1, 15.00, 51.66),
        (472, 1, 15.00, 195.36),
        (473, 1, 15.00, 243.00),
        (474, 1, 15.00, 535.05),
        (475, 1, 15.00, 162.00),
        (476, 1, 15.00, 147.00),
        (477, 1, 15.00, 586.08),
        (478, 1, 15.00, 63.00),
        (479, 1, 15.00, 148.50),
        (480, 1, 15.00, 666.00),
        (481, 1, 15.00, 133.50),
        (482, 1, 15.00, 141.75),
        (483, 1, 15.00, 49.50),
        (484, 1, 15.00, 444.00),
        (485, 1, 15.00, 142.50),
        (486, 1, 15.00, 62.70),
        (487, 1, 15.00, 46.74),
        (488, 1, 15.00, 154.98),
        (489, 1, 15.00, 204.00),
        (490, 1, 15.00, 356.40),
        (491, 1, 15.00, 171.00),
        (492, 1, 15.00, 88.50),
        (493, 1, 15.00, 78.00),
        (494, 1, 15.00, 162.00),
        (495, 1, 15.00, 103.32),
        (496, 1, 15.00, 661.50),
        (497, 1, 15.00, 155.93),
        (498, 1, 15.00, 157.50),
        (499, 1, 15.00, 57.00),
        (500, 1, 15.00, 85.80),
        (501, 1, 15.00, 130.50),
        (502, 1, 15.00, 103.50),
        (503, 1, 15.00, 36.00),
        (504, 1, 15.00, 84.00),
        (505, 1, 15.00, 114.00),
        (506, 1, 15.00, 72.00),
        (507, 1, 15.00, 137.76),
        (508, 1, 15.00, 171.60),
        (509, 1, 15.00, 155.93),
        (510, 1, 15.00, 188.10),
        (511, 1, 15.00, 54.45),
        (512, 1, 15.00, 199.50),
        (513, 1, 15.00, 61.20),
        (514, 1, 15.00, 156.00),
        (515, 1, 15.00, 294.00),
        (516, 1, 15.00, 668.25),
        (517, 1, 15.00, 122.40),
        (518, 1, 15.00, 262.50),
        (519, 1, 15.00, 84.00),
        (520, 1, 15.00, 306.00),
        (521, 1, 15.00, 49.50),
        (522, 1, 15.00, 177.00),
        (523, 1, 15.00, 154.80),
        (524, 1, 15.00, 88.50),
        (525, 1, 15.00, 114.00),
        (526, 1, 15.00, 63.00),
        (527, 1, 15.00, 267.30),
        (528, 1, 15.00, 156.00),
        (529, 1, 15.00, 444.00),
        (530, 1, 15.00, 64.50),
        (531, 1, 15.00, 63.00),
        (532, 1, 15.00, 265.50),
        (533, 1, 15.00, 393.75),
        (534, 1, 15.00, 96.00),
        (535, 1, 15.00, 154.98),
        (536, 1, 15.00, 717.75),
        (537, 1, 15.00, 262.50),
        (538, 1, 15.00, 99.75),
        (539, 1, 15.00, 52.50),
        (540, 1, 15.00, 187.50),
        (541, 1, 15.00, 234.00),
        (542, 1, 15.00, 157.50),
        (543, 1, 15.00, 68.88),
        (544, 1, 15.00, 142.50),
        (545, 1, 15.00, 168.00),
        (546, 1, 15.00, 55.44),
        (547, 1, 15.00, 661.50),
        (548, 1, 15.00, 237.60),
        (549, 1, 15.00, 54.00),
        (550, 1, 15.00, 195.36),
        (551, 1, 15.00, 294.00),
        (552, 1, 15.00, 115.50),
        (553, 1, 15.00, 114.00),
        (554, 1, 15.00, 49.50),
        (555, 1, 15.00, 444.00),
        (556, 1, 15.00, 342.00),
        (557, 1, 15.00, 168.00),
        (558, 1, 15.00, 102.83),
        (559, 1, 15.00, 427.50),
        (560, 1, 15.00, 240.00),
        (561, 1, 15.00, 49.50),
        (562, 1, 15.00, 666.00),
        (563, 1, 15.00, 99.00),
        (564, 1, 15.00, 97.20),
        (565, 1, 15.00, 199.50),
        (566, 1, 15.00, 375.00),
        (567, 1, 15.00, 158.40),
        (568, 1, 15.00, 163.35),
        (569, 1, 15.00, 108.00),
        (570, 1, 15.00, 630.00),
        (571, 1, 15.00, 154.98),
        (572, 1, 15.00, 252.00),
        (573, 1, 15.00, 102.00),
        (574, 1, 15.00, 324.00),
        (575, 1, 15.00, 182.66),
        (576, 1, 15.00, 108.90),
        (577, 1, 15.00, 103.32),
        (578, 1, 15.00, 31.50),
        (579, 1, 15.00, 126.00),
        (580, 1, 15.00, 157.50),
        (581, 1, 15.00, 720.00),
        (582, 1, 15.00, 204.00),
        (583, 1, 15.00, 165.00),
        (584, 1, 15.00, 262.50),
        (585, 1, 15.00, 74.40),
        (586, 1, 15.00, 51.60),
        (587, 1, 15.00, 188.10),
        (588, 1, 15.00, 240.00),
        (589, 1, 15.00, 207.00),
        (590, 1, 15.00, 103.20),
        (591, 1, 15.00, 171.60),
        (592, 1, 15.00, 444.00),
        (593, 1, 15.00, 154.24),
        (594, 1, 15.00, 720.00),
        (595, 1, 15.00, 267.00),
        (596, 1, 15.00, 173.25),
        (597, 1, 15.00, 243.00),
        (598, 1, 15.00, 173.25),
        (599, 1, 15.00, 85.80),
        (600, 1, 15.00, 102.00),
        (601, 1, 15.00, 57.75),
        (602, 1, 15.00, 517.50),
        (603, 1, 15.00, 375.00),
        (604, 1, 15.00, 36.00),
        (605, 1, 15.00, 57.75),
        (606, 1, 15.00, 148.50),
        (607, 1, 15.00, 110.88),
        (608, 1, 15.00, 441.00),
        (609, 1, 15.00, 108.90),
        (610, 1, 15.00, 99.00),
        (611, 1, 15.00, 212.85),
        (612, 1, 15.00, 55.44),
        (613, 1, 15.00, 441.00),
        (614, 1, 15.00, 195.36),
        (615, 1, 15.00, 36.00),
        (616, 1, 15.00, 216.00),
        (617, 1, 15.00, 99.75),
        (618, 1, 15.00, 177.00),
        (619, 1, 15.00, 586.08),
        (620, 1, 15.00, 265.50),
        (621, 1, 15.00, 285.00),
        (622, 1, 15.00, 234.00),
        (623, 1, 15.00, 400.50),
        (624, 1, 15.00, 336.00),
        (625, 1, 15.00, 51.66),
        (626, 1, 15.00, 148.50),
        (627, 1, 15.00, 586.08),
        (628, 1, 15.00, 154.80),
        (629, 1, 15.00, 517.50),
        (630, 1, 15.00, 54.60),
        (631, 1, 15.00, 303.60),
        (632, 1, 15.00, 51.60),
        (633, 1, 15.00, 234.00),
        (634, 1, 15.00, 195.36),
        (635, 1, 15.00, 504.00),
        (636, 1, 15.00, 46.50),
        (637, 1, 15.00, 168.00),
        (638, 1, 15.00, 517.50),
        (639, 1, 15.00, 54.60),
        (640, 1, 15.00, 140.22),
        (641, 1, 15.00, 25.35),
        (642, 1, 15.00, 945.00),
        (643, 1, 15.00, 110.88),
        (644, 1, 15.00, 142.50),
        (645, 1, 15.00, 36.00),
        (646, 1, 15.00, 162.00),
        (647, 1, 15.00, 78.00),
        (648, 1, 15.00, 76.05),
        (649, 1, 15.00, 102.00),
        (650, 1, 15.00, 162.00),
        (651, 1, 15.00, 96.00),
        (652, 1, 15.00, 265.50),
        (653, 1, 15.00, 285.00),
        (654, 1, 15.00, 79.20),
        (655, 1, 15.00, 126.00),
        (656, 1, 15.00, 216.00),
        (657, 1, 15.00, 189.00),
        (658, 1, 15.00, 103.50),
        (659, 1, 15.00, 148.83),
        (660, 1, 15.00, 405.90),
        (661, 1, 15.00, 163.35),
        (662, 1, 15.00, 114.00),
        (663, 1, 15.00, 61.43),
        (664, 1, 15.00, 187.50),
        (665, 1, 15.00, 441.00),
        (666, 1, 15.00, 56.16),
        (667, 1, 15.00, 109.20),
        (668, 1, 15.00, 286.65),
        (669, 1, 15.00, 102.00),
        (670, 1, 15.00, 121.77),
        (671, 1, 15.00, 178.20),
        (672, 1, 15.00, 131.25),
        (673, 1, 15.00, 155.93),
        (674, 1, 15.00, 48.60),
        (675, 1, 15.00, 108.00),
        (676, 1, 15.00, 84.00),
        (677, 1, 15.00, 257.40),
        (678, 1, 15.00, 110.88),
        (679, 1, 15.00, 84.00),
        (680, 1, 15.00, 85.80),
        (681, 1, 15.00, 330.00),
        (682, 1, 15.00, 94.50),
        (683, 1, 15.00, 222.00),
        (684, 1, 15.00, 171.60),
        (685, 1, 15.00, 54.45),
        (686, 1, 15.00, 99.00),
        (687, 1, 15.00, 228.00),
        (688, 1, 15.00, 94.50),
        (689, 1, 15.00, 495.00),
        (690, 1, 15.00, 64.80),
        (691, 1, 15.00, 193.50),
        (692, 1, 15.00, 196.19),
        (693, 1, 15.00, 178.35),
        (694, 1, 15.00, 139.50),
        (695, 1, 15.00, 717.75),
        (696, 1, 15.00, 131.25),
        (697, 1, 15.00, 199.50),
        (698, 1, 15.00, 141.75),
        (699, 1, 15.00, 131.25),
        (700, 1, 15.00, 72.00),
        (701, 1, 15.00, 168.00),
        (702, 1, 15.00, 70.95),
        (703, 1, 15.00, 139.50),
        (704, 1, 15.00, 88.50),
        (705, 1, 15.00, 168.00),
        (706, 1, 15.00, 288.00),
        (707, 1, 15.00, 140.22),
        (708, 1, 15.00, 240.00),
        (709, 1, 15.00, 306.00),
        (710, 1, 15.00, 306.00),
        (711, 1, 15.00, 171.00),
        (712, 1, 15.00, 20.48),
        (713, 1, 15.00, 43.50),
        (714, 1, 15.00, 56.16),
        (715, 1, 15.00, 240.00),
        (716, 1, 15.00, 93.48),
        (717, 1, 15.00, 55.44),
        (718, 1, 15.00, 336.00),
        (719, 1, 15.00, 192.00),
        (720, 1, 15.00, 110.88),
        (721, 1, 15.00, 90.09),
        (722, 1, 15.00, 588.56),
        (723, 1, 15.00, 54.60),
        (724, 1, 15.00, 390.72),
        (725, 1, 15.00, 216.00),
        (726, 1, 15.00, 40.95),
        (727, 1, 15.00, 351.00),
        (728, 1, 15.00, 99.00),
        (729, 1, 15.00, 114.00),
        (730, 1, 15.00, 324.00),
        (731, 1, 15.00, 435.00),
        (732, 1, 15.00, 267.00),
        (733, 1, 15.00, 133.50),
        (734, 1, 15.00, 189.00),
        (735, 1, 15.00, 131.25),
        (736, 1, 15.00, 199.50),
        (737, 1, 15.00, 103.32),
        (738, 1, 15.00, 109.47),
        (739, 1, 15.00, 218.94),
        (740, 1, 15.00, 218.94),
        (741, 1, 15.00, 49.50),
        (742, 1, 15.00, 51.15),
        (743, 1, 15.00, 356.40),
        (744, 1, 15.00, 356.40),
        (745, 1, 15.00, 68.64),
        (746, 1, 15.00, 105.60),
        (747, 1, 15.00, 168.48),
        (748, 1, 15.00, 64.80),
        (749, 1, 15.00, 102.96),
        (750, 1, 15.00, 405.00),
        (751, 1, 15.00, 49.50),
        (752, 1, 15.00, 586.08),
        (753, 1, 15.00, 427.50),
        (754, 1, 15.00, 588.56),
        (755, 1, 15.00, 166.32),
        (756, 1, 15.00, 157.44),
        (757, 1, 15.00, 206.64),
        (758, 1, 15.00, 171.00),
        (759, 1, 15.00, 187.50),
        (760, 1, 15.00, 157.44),
        (761, 1, 15.00, 562.50),
        (762, 1, 15.00, 607.50),
        (763, 1, 15.00, 269.28),
        (764, 1, 15.00, 306.00),
        (765, 1, 15.00, 31.20),
        (766, 1, 15.00, 495.00),
        (767, 1, 15.00, 212.85),
        (768, 1, 15.00, 212.85),
        (769, 1, 15.00, 96.00),
        (770, 1, 15.00, 328.41),
        (771, 1, 15.00, 236.16),
        (772, 1, 15.00, 187.50),
        (773, 1, 15.00, 375.00),
        (774, 1, 15.00, 46.74),
        (775, 1, 15.00, 93.48),
        (776, 1, 15.00, 351.00),
        (777, 1, 15.00, 148.50),
        (778, 1, 15.00, 666.00),
        (779, 1, 15.00, 288.00),
        (780, 1, 15.00, 177.00),
        (781, 1, 15.00, 189.75),
        (782, 1, 15.00, 187.50),
        (783, 1, 15.00, 102.83),
        (784, 1, 15.00, 243.00),
        (785, 1, 15.00, 178.35),
        (786, 1, 15.00, 62.70),
        (787, 1, 15.00, 154.24),
        (788, 1, 15.00, 81.00),
        (789, 1, 15.00, 63.00),
        (790, 1, 15.00, 81.90),
        (791, 1, 15.00, 236.16),
        (792, 1, 15.00, 129.00),
        (793, 1, 15.00, 445.50),
        (794, 1, 15.00, 168.00),
        (795, 1, 15.00, 222.75),
        (796, 1, 15.00, 562.50),
        (797, 1, 15.00, 87.00),
        (798, 1, 15.00, 140.22),
        (799, 1, 15.00, 445.50),
        (800, 1, 15.00, 562.50);
    INSERT INTO dbo.AppliedTaxes (BillDetails_Id, Taxes_Id, Percentage, Amount) VALUES
        (801, 1, 15.00, 50.70),
        (802, 1, 15.00, 177.00),
        (803, 1, 15.00, 202.50),
        (804, 1, 15.00, 114.00),
        (805, 1, 15.00, 97.20),
        (806, 1, 15.00, 154.98),
        (807, 1, 15.00, 25.35),
        (808, 1, 15.00, 163.80),
        (809, 1, 15.00, 216.00),
        (810, 1, 15.00, 35.64),
        (811, 1, 15.00, 181.50),
        (812, 1, 15.00, 63.00),
        (813, 1, 15.00, 240.00),
        (814, 1, 15.00, 148.50),
        (815, 1, 15.00, 103.50),
        (816, 1, 15.00, 114.00),
        (817, 1, 15.00, 197.47),
        (818, 1, 15.00, 390.72),
        (819, 1, 15.00, 61.78),
        (820, 1, 15.00, 195.36),
        (821, 1, 15.00, 228.00),
        (822, 1, 15.00, 77.88),
        (823, 1, 15.00, 78.00),
        (824, 1, 15.00, 306.00),
        (825, 1, 15.00, 607.50),
        (826, 1, 15.00, 285.00),
        (827, 1, 15.00, 148.50),
        (828, 1, 15.00, 405.90),
        (829, 1, 15.00, 103.32),
        (830, 1, 15.00, 306.00),
        (831, 1, 15.00, 31.50),
        (832, 1, 15.00, 195.36),
        (833, 1, 15.00, 157.44),
        (834, 1, 15.00, 239.25),
        (835, 1, 15.00, 128.70),
        (836, 1, 15.00, 562.50),
        (837, 1, 15.00, 108.90),
        (838, 1, 15.00, 97.20),
        (839, 1, 15.00, 108.00),
        (840, 1, 15.00, 110.88),
        (841, 1, 15.00, 54.00),
        (842, 1, 15.00, 141.90),
        (843, 1, 15.00, 217.50),
        (844, 1, 15.00, 31.50),
        (845, 1, 15.00, 405.00),
        (846, 1, 15.00, 78.72),
        (847, 1, 15.00, 166.32),
        (848, 1, 15.00, 285.00),
        (849, 1, 15.00, 64.50),
        (850, 1, 15.00, 117.00),
        (851, 1, 15.00, 193.50),
        (852, 1, 15.00, 51.66),
        (853, 1, 15.00, 356.40),
        (854, 1, 15.00, 40.95),
        (855, 1, 15.00, 49.50),
        (856, 1, 15.00, 108.00),
        (857, 1, 15.00, 36.00),
        (858, 1, 15.00, 20.48),
        (859, 1, 15.00, 400.50),
        (860, 1, 15.00, 85.50),
        (861, 1, 15.00, 128.70),
        (862, 1, 15.00, 93.48),
        (863, 1, 15.00, 534.60),
        (864, 1, 15.00, 51.66),
        (865, 1, 15.00, 441.00),
        (866, 1, 15.00, 78.00),
        (867, 1, 15.00, 168.48),
        (868, 1, 15.00, 166.32),
        (869, 1, 15.00, 495.00),
        (870, 1, 15.00, 64.80),
        (871, 1, 15.00, 137.76),
        (872, 1, 15.00, 171.00),
        (873, 1, 15.00, 108.00),
        (874, 1, 15.00, 163.35),
        (875, 1, 15.00, 54.60),
        (876, 1, 15.00, 53.10);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.AppliedDiscounts)
BEGIN
    INSERT INTO dbo.AppliedDiscounts (BillDetails_Id, Discounts_Id, Percentage, Amount) VALUES
        (1, 7, 12.00, 177.60),
        (13, 1, 20.00, 312.00),
        (14, 7, 12.00, 324.00),
        (33, 7, 12.00, 50.40),
        (35, 10, 18.00, 267.30),
        (40, 10, 18.00, 81.00),
        (41, 12, 15.00, 246.00),
        (44, 1, 20.00, 70.00),
        (52, 10, 18.00, 783.00),
        (53, 12, 15.00, 246.00),
        (56, 7, 12.00, 100.80),
        (57, 10, 18.00, 396.00),
        (59, 1, 20.00, 210.00),
        (62, 10, 18.00, 115.20),
        (66, 7, 12.00, 138.00),
        (68, 1, 20.00, 140.00),
        (69, 2, 15.00, 57.00),
        (79, 10, 18.00, 522.00),
        (90, 1, 20.00, 210.00),
        (93, 1, 20.00, 217.80),
        (97, 10, 18.00, 594.00),
        (103, 1, 20.00, 343.20),
        (105, 7, 12.00, 355.20),
        (109, 7, 12.00, 276.00),
        (124, 1, 20.00, 132.00),
        (131, 7, 12.00, 486.00),
        (133, 7, 12.00, 177.60),
        (150, 10, 18.00, 230.40),
        (152, 1, 20.00, 116.00),
        (153, 7, 12.00, 355.20),
        (154, 10, 18.00, 198.00),
        (157, 1, 20.00, 154.00),
        (158, 1, 20.00, 116.00),
        (160, 1, 20.00, 174.00),
        (161, 10, 18.00, 89.10),
        (162, 10, 18.00, 205.20),
        (173, 1, 20.00, 104.00),
        (175, 1, 20.00, 116.00),
        (176, 13, 10.00, 72.00),
        (178, 1, 20.00, 77.00),
        (184, 1, 20.00, 77.00),
        (186, 1, 20.00, 343.20),
        (188, 10, 18.00, 201.60),
        (192, 10, 18.00, 480.60),
        (202, 1, 20.00, 77.00),
        (203, 1, 20.00, 140.00),
        (207, 7, 12.00, 486.00),
        (208, 7, 12.00, 355.20),
        (212, 7, 12.00, 100.80),
        (213, 7, 12.00, 486.00),
        (215, 7, 12.00, 177.60),
        (216, 7, 12.00, 324.00),
        (217, 10, 18.00, 75.60),
        (226, 1, 20.00, 140.00),
        (227, 10, 18.00, 160.20),
        (230, 10, 18.00, 160.20),
        (232, 10, 18.00, 302.40),
        (237, 3, 10.00, 84.00),
        (238, 10, 18.00, 201.60),
        (240, 10, 18.00, 201.60),
        (248, 3, 10.00, 156.00),
        (249, 10, 18.00, 861.30),
        (251, 3, 10.00, 296.00),
        (252, 1, 20.00, 312.00),
        (254, 13, 10.00, 72.00),
        (260, 1, 20.00, 140.00),
        (261, 10, 18.00, 861.30),
        (263, 3, 10.00, 148.00),
        (267, 3, 10.00, 76.00),
        (272, 1, 20.00, 154.00),
        (274, 10, 18.00, 783.00),
        (276, 10, 18.00, 320.40),
        (277, 3, 10.00, 135.00),
        (278, 10, 18.00, 522.00),
        (282, 1, 20.00, 154.00),
        (287, 10, 18.00, 783.00),
        (288, 1, 20.00, 58.00),
        (292, 1, 20.00, 198.00),
        (293, 3, 10.00, 84.00),
        (295, 10, 18.00, 230.40),
        (298, 3, 10.00, 444.00),
        (306, 13, 10.00, 79.20),
        (307, 10, 18.00, 320.40),
        (309, 10, 18.00, 160.20),
        (311, 10, 18.00, 226.80),
        (312, 3, 10.00, 135.00),
        (313, 3, 10.00, 207.00),
        (314, 10, 18.00, 100.80),
        (316, 3, 10.00, 207.00),
        (331, 5, 30.00, 480.00),
        (335, 10, 18.00, 396.00),
        (337, 1, 20.00, 114.40),
        (339, 10, 18.00, 226.80),
        (342, 7, 12.00, 355.20),
        (347, 1, 20.00, 104.00),
        (348, 1, 20.00, 58.00),
        (349, 1, 20.00, 140.00),
        (352, 7, 12.00, 100.80),
        (353, 10, 18.00, 345.60),
        (355, 10, 18.00, 594.00),
        (356, 10, 18.00, 594.00),
        (358, 1, 20.00, 174.00),
        (360, 10, 18.00, 160.20),
        (363, 1, 20.00, 217.80),
        (372, 7, 12.00, 324.00),
        (374, 10, 18.00, 75.60),
        (384, 10, 18.00, 198.00),
        (388, 5, 30.00, 480.00),
        (389, 1, 20.00, 140.00),
        (392, 1, 20.00, 140.00),
        (393, 5, 30.00, 1215.00),
        (396, 7, 12.00, 100.80),
        (397, 5, 30.00, 285.00),
        (399, 1, 20.00, 132.00),
        (401, 10, 18.00, 380.16),
        (402, 10, 18.00, 151.20),
        (403, 13, 10.00, 108.00),
        (408, 7, 12.00, 486.00),
        (409, 10, 18.00, 345.60),
        (414, 10, 18.00, 205.20),
        (416, 1, 20.00, 174.00),
        (417, 10, 18.00, 162.00),
        (419, 7, 12.00, 50.40),
        (421, 1, 20.00, 174.00),
        (427, 5, 30.00, 1215.00),
        (428, 10, 18.00, 287.10),
        (429, 10, 18.00, 783.00),
        (430, 5, 30.00, 1215.00),
        (437, 13, 10.00, 26.40),
        (438, 5, 30.00, 1890.00),
        (440, 10, 18.00, 225.72),
        (441, 13, 10.00, 48.00),
        (443, 10, 18.00, 198.00),
        (450, 7, 12.00, 177.60),
        (454, 5, 30.00, 960.00),
        (458, 5, 30.00, 285.00),
        (460, 13, 10.00, 24.00),
        (464, 10, 18.00, 396.00),
        (465, 5, 30.00, 750.00),
        (466, 13, 10.00, 48.00),
        (467, 10, 18.00, 151.20),
        (471, 10, 18.00, 75.60),
        (472, 7, 12.00, 177.60),
        (473, 4, 25.00, 540.00),
        (474, 10, 18.00, 783.00),
        (475, 4, 25.00, 360.00),
        (477, 7, 12.00, 532.80),
        (482, 5, 30.00, 405.00),
        (487, 10, 18.00, 68.40),
        (488, 10, 18.00, 226.80),
        (490, 7, 12.00, 324.00),
        (495, 10, 18.00, 151.20),
        (496, 5, 30.00, 1890.00),
        (497, 5, 30.00, 445.50),
        (507, 10, 18.00, 201.60),
        (509, 5, 30.00, 445.50),
        (512, 5, 30.00, 570.00),
        (513, 6, 15.00, 72.00),
        (517, 6, 15.00, 144.00),
        (518, 5, 30.00, 750.00),
        (523, 11, 20.00, 258.00),
        (533, 5, 30.00, 1125.00),
        (535, 10, 18.00, 226.80),
        (537, 5, 30.00, 750.00),
        (538, 5, 30.00, 285.00),
        (543, 10, 18.00, 100.80),
        (545, 5, 30.00, 480.00),
        (546, 7, 12.00, 50.40),
        (547, 5, 30.00, 1890.00),
        (550, 7, 12.00, 177.60),
        (557, 5, 30.00, 480.00),
        (558, 10, 18.00, 150.48),
        (564, 13, 10.00, 72.00),
        (565, 5, 30.00, 570.00),
        (571, 10, 18.00, 226.80),
        (575, 10, 18.00, 267.30),
        (577, 10, 18.00, 151.20),
        (584, 5, 30.00, 750.00),
        (585, 11, 20.00, 124.00),
        (586, 11, 20.00, 86.00),
        (590, 11, 20.00, 172.00),
        (593, 10, 18.00, 225.72),
        (607, 7, 12.00, 100.80),
        (608, 5, 30.00, 1260.00),
        (612, 7, 12.00, 50.40),
        (613, 5, 30.00, 1260.00),
        (614, 7, 12.00, 177.60),
        (617, 5, 30.00, 285.00),
        (619, 7, 12.00, 532.80),
        (624, 5, 30.00, 960.00),
        (625, 10, 18.00, 75.60),
        (627, 7, 12.00, 532.80),
        (628, 11, 20.00, 258.00),
        (630, 8, 35.00, 196.00),
        (631, 7, 12.00, 276.00),
        (632, 11, 20.00, 86.00),
        (634, 7, 12.00, 177.60),
        (635, 5, 30.00, 1440.00),
        (637, 5, 30.00, 480.00),
        (639, 8, 35.00, 196.00),
        (640, 10, 18.00, 205.20),
        (641, 8, 35.00, 91.00),
        (643, 7, 12.00, 100.80),
        (648, 8, 35.00, 273.00),
        (659, 10, 18.00, 217.80),
        (660, 10, 18.00, 594.00),
        (663, 8, 35.00, 220.50),
        (666, 14, 22.00, 105.60),
        (667, 8, 35.00, 392.00),
        (668, 8, 35.00, 1029.00),
        (670, 10, 18.00, 178.20),
        (672, 5, 30.00, 375.00),
        (673, 5, 30.00, 445.50),
        (674, 13, 10.00, 36.00),
        (678, 7, 12.00, 100.80),
        (690, 13, 10.00, 48.00),
        (692, 10, 18.00, 287.10),
        (693, 10, 18.00, 261.00),
        (696, 5, 30.00, 375.00),
        (697, 5, 30.00, 570.00),
        (698, 5, 30.00, 405.00),
        (699, 5, 30.00, 375.00),
        (707, 10, 18.00, 205.20),
        (712, 8, 35.00, 73.50),
        (714, 14, 22.00, 105.60),
        (716, 10, 18.00, 136.80),
        (717, 7, 12.00, 50.40),
        (718, 5, 30.00, 960.00),
        (720, 7, 12.00, 100.80),
        (721, 14, 22.00, 169.40),
        (722, 10, 18.00, 861.30),
        (723, 8, 35.00, 196.00),
        (724, 7, 12.00, 355.20),
        (726, 8, 35.00, 147.00),
        (735, 5, 30.00, 375.00),
        (736, 5, 30.00, 570.00),
        (737, 10, 18.00, 151.20),
        (738, 10, 18.00, 160.20),
        (739, 10, 18.00, 320.40),
        (740, 10, 18.00, 320.40),
        (743, 7, 12.00, 324.00),
        (744, 7, 12.00, 324.00),
        (745, 8, 35.00, 246.40),
        (747, 14, 22.00, 316.80),
        (748, 13, 10.00, 48.00),
        (749, 8, 35.00, 369.60),
        (752, 7, 12.00, 532.80),
        (754, 10, 18.00, 861.30),
        (755, 7, 12.00, 151.20),
        (756, 10, 18.00, 230.40),
        (757, 10, 18.00, 302.40),
        (760, 10, 18.00, 230.40),
        (763, 15, 12.00, 244.80),
        (765, 8, 35.00, 112.00),
        (770, 10, 18.00, 480.60),
        (771, 10, 18.00, 345.60),
        (774, 10, 18.00, 68.40),
        (775, 10, 18.00, 136.80),
        (783, 10, 18.00, 150.48),
        (785, 10, 18.00, 261.00),
        (787, 10, 18.00, 225.72),
        (790, 14, 22.00, 154.00),
        (791, 10, 18.00, 345.60),
        (798, 10, 18.00, 205.20),
        (801, 8, 35.00, 182.00),
        (805, 13, 10.00, 72.00),
        (806, 10, 18.00, 226.80),
        (807, 8, 35.00, 91.00),
        (808, 8, 35.00, 588.00),
        (810, 13, 10.00, 26.40),
        (817, 15, 12.00, 179.52),
        (818, 7, 12.00, 355.20),
        (819, 14, 22.00, 116.16),
        (820, 7, 12.00, 177.60),
        (822, 15, 12.00, 70.80),
        (828, 10, 18.00, 594.00),
        (829, 10, 18.00, 151.20),
        (832, 7, 12.00, 177.60),
        (833, 10, 18.00, 230.40),
        (838, 13, 10.00, 72.00),
        (840, 7, 12.00, 100.80),
        (846, 10, 18.00, 115.20),
        (847, 7, 12.00, 151.20),
        (852, 10, 18.00, 75.60),
        (853, 7, 12.00, 324.00),
        (854, 8, 35.00, 147.00),
        (858, 8, 35.00, 73.50),
        (860, 9, 40.00, 380.00),
        (862, 10, 18.00, 136.80),
        (863, 7, 12.00, 486.00),
        (864, 10, 18.00, 75.60),
        (867, 14, 22.00, 316.80),
        (868, 7, 12.00, 151.20),
        (870, 13, 10.00, 48.00),
        (871, 10, 18.00, 201.60),
        (872, 9, 40.00, 760.00),
        (875, 8, 35.00, 196.00),
        (876, 9, 40.00, 236.00);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Bill_has_Coupons)
BEGIN
    INSERT INTO dbo.Bill_has_Coupons (Bill_Id, Coupons_Id, AppliedAmount) VALUES
        (3, 4, 31.50),
        (10, 14, 120.00),
        (13, 2, 100.00),
        (22, 2, 100.00),
        (28, 5, 150.00),
        (29, 12, 60.00),
        (41, 3, 111.20),
        (47, 5, 150.00),
        (57, 9, 108.50),
        (60, 2, 100.00),
        (68, 2, 100.00),
        (70, 3, 213.89),
        (78, 9, 166.50),
        (81, 4, 124.00),
        (84, 14, 120.00),
        (101, 3, 23.20),
        (111, 1, 380.56),
        (122, 12, 60.00),
        (124, 6, 262.50),
        (125, 12, 60.00),
        (142, 11, 62.98),
        (143, 1, 401.60),
        (148, 11, 213.77),
        (156, 13, 660.00),
        (161, 9, 159.50),
        (177, 4, 153.86),
        (179, 9, 99.50),
        (181, 13, 607.50),
        (192, 3, 345.60),
        (198, 14, 120.00),
        (211, 14, 120.00),
        (218, 11, 203.64),
        (219, 13, 288.36),
        (220, 14, 120.00),
        (221, 1, 320.00),
        (224, 1, 198.00),
        (237, 14, 120.00),
        (251, 9, 156.30),
        (253, 1, 254.20),
        (262, 12, 60.00),
        (268, 11, 243.00),
        (279, 12, 60.00),
        (284, 12, 60.00),
        (286, 9, 149.00),
        (289, 11, 239.30),
        (293, 8, 80.00),
        (315, 3, 40.56),
        (317, 3, 137.60),
        (319, 1, 242.80),
        (324, 2, 100.00),
        (332, 1, 56.00),
        (341, 8, 80.00),
        (342, 2, 100.00),
        (360, 9, 342.00),
        (361, 11, 181.50),
        (364, 3, 116.77),
        (371, 12, 60.00),
        (373, 1, 343.96),
        (381, 11, 177.79),
        (386, 15, 68.55),
        (389, 11, 152.42),
        (397, 12, 60.00),
        (403, 3, 55.20),
        (404, 11, 45.60),
        (412, 10, 300.00),
        (418, 11, 98.02),
        (420, 1, 401.04),
        (421, 9, 13.65),
        (425, 3, 312.67);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Bill_has_PaymentMethod)
BEGIN
    SET IDENTITY_INSERT dbo.Bill_has_PaymentMethod ON;
    INSERT INTO dbo.Bill_has_PaymentMethod (Id, Bill_Id, PaymentMethod_Id, PaymentCard_Id, PaidAmount, PaymentReference, RegistrationDate) VALUES
        (1, 1, 1, NULL, 3245.76, NULL, '2026-06-01T08:55:55'),
        (2, 2, 3, NULL, 552.00, N'SIM-000002-1', '2026-06-01T11:27:10'),
        (3, 3, 1, NULL, 415.80, NULL, '2026-06-01T11:49:31'),
        (4, 3, 2, NULL, 277.20, N'SIM-000003-2', '2026-06-01T11:49:31'),
        (5, 4, 2, NULL, 4876.00, N'SIM-000004-1', '2026-06-01T12:06:29'),
        (6, 5, 1, NULL, 3673.10, NULL, '2026-06-01T13:04:13'),
        (7, 7, 3, 1, 1756.70, N'SIM-000007-1', '2026-06-01T15:55:28'),
        (8, 8, 2, 32, 3496.40, N'SIM-000008-1', '2026-06-02T20:28:30'),
        (9, 9, 3, 10, 1724.50, N'SIM-000009-1', '2026-06-02T21:52:24'),
        (10, 10, 1, NULL, 4537.50, NULL, '2026-06-04T09:19:05'),
        (11, 11, 2, NULL, 4071.00, N'SIM-000011-1', '2026-06-04T09:53:56'),
        (12, 12, 3, NULL, 5244.00, N'SIM-000012-1', '2026-06-04T11:20:16'),
        (13, 13, 1, NULL, 736.95, NULL, '2026-06-04T12:08:41'),
        (14, 13, 2, NULL, 491.30, N'SIM-000013-2', '2026-06-04T12:08:41'),
        (15, 14, 1, NULL, 3542.00, NULL, '2026-06-04T13:44:48'),
        (16, 15, 1, NULL, 9096.50, NULL, '2026-06-04T14:48:46'),
        (17, 16, 1, NULL, 2334.04, NULL, '2026-06-04T15:18:10'),
        (18, 17, 1, NULL, 1552.50, NULL, '2026-06-04T15:29:13'),
        (19, 18, 2, NULL, 2912.61, N'SIM-000018-1', '2026-06-04T15:39:11'),
        (20, 19, 2, 16, 1184.00, N'SIM-000019-1', '2026-06-06T10:43:21'),
        (21, 20, 1, NULL, 2634.65, NULL, '2026-06-06T11:37:08'),
        (22, 21, 2, NULL, 1851.50, N'SIM-000021-1', '2026-06-06T12:02:54'),
        (23, 22, 1, NULL, 2361.00, NULL, '2026-06-06T13:58:15'),
        (24, 23, 1, NULL, 966.00, NULL, '2026-06-06T14:12:52'),
        (25, 24, 1, NULL, 2576.00, NULL, '2026-06-06T15:42:59'),
        (26, 25, 1, NULL, 5705.15, NULL, '2026-06-06T15:45:04'),
        (27, 26, 3, NULL, 480.70, N'SIM-000026-1', '2026-06-10T09:24:51'),
        (28, 27, 3, NULL, 736.00, N'SIM-000027-1', '2026-06-10T11:16:28'),
        (29, 28, 1, NULL, 4748.08, NULL, '2026-06-10T13:15:03'),
        (30, 29, 2, NULL, 1895.00, N'SIM-000029-1', '2026-06-10T15:22:15'),
        (31, 30, 1, NULL, 2829.00, NULL, '2026-06-10T15:53:04'),
        (32, 31, 2, NULL, 603.52, N'SIM-000031-1', '2026-06-10T15:53:15'),
        (33, 32, 3, NULL, 1449.00, N'SIM-000032-1', '2026-06-10T15:54:21'),
        (34, 33, 1, NULL, 7557.80, NULL, '2026-06-13T09:26:47'),
        (35, 34, 2, NULL, 2004.45, N'SIM-000034-1', '2026-06-13T10:43:01'),
        (36, 35, 3, NULL, 1840.00, N'SIM-000035-1', '2026-06-13T10:43:45'),
        (37, 36, 3, NULL, 3875.50, N'SIM-000036-1', '2026-06-13T11:09:05'),
        (38, 37, 3, NULL, 2047.00, N'SIM-000037-1', '2026-06-13T12:48:55'),
        (39, 38, 1, NULL, 4409.10, NULL, '2026-06-13T14:12:31'),
        (40, 39, 2, NULL, 5632.70, N'SIM-000039-1', '2026-06-13T14:56:52'),
        (41, 40, 2, NULL, 1207.50, N'SIM-000040-1', '2026-06-13T15:59:24'),
        (42, 41, 2, 18, 1567.30, N'SIM-000041-1', '2026-06-15T14:00:04'),
        (43, 42, 1, NULL, 4002.00, NULL, '2026-06-16T10:17:52'),
        (44, 43, 1, NULL, 4807.00, NULL, '2026-06-16T11:10:40'),
        (45, 44, 1, NULL, 1207.50, NULL, '2026-06-16T12:10:28'),
        (46, 45, 1, NULL, 1552.50, NULL, '2026-06-18T13:30:08'),
        (47, 45, 2, NULL, 1035.00, N'SIM-000045-2', '2026-06-18T13:30:08'),
        (48, 46, 1, NULL, 4313.88, NULL, '2026-06-18T13:49:31'),
        (49, 47, 2, NULL, 4157.90, N'SIM-000047-1', '2026-06-18T15:28:39'),
        (50, 48, 3, 24, 1184.00, N'SIM-000048-1', '2026-06-19T00:49:50'),
        (51, 50, 1, NULL, 4959.72, NULL, '2026-06-21T09:37:54'),
        (52, 51, 1, NULL, 4628.52, NULL, '2026-06-21T09:38:12'),
        (53, 52, 1, NULL, 4363.10, NULL, '2026-06-21T11:27:36'),
        (54, 54, 1, NULL, 1869.90, NULL, '2026-06-23T09:46:55'),
        (55, 55, 1, NULL, 2539.20, NULL, '2026-06-23T10:53:02'),
        (56, 55, 2, NULL, 1692.80, N'SIM-000055-2', '2026-06-23T10:53:02'),
        (57, 56, 2, NULL, 5165.80, N'SIM-000056-1', '2026-06-23T11:24:05'),
        (58, 57, 3, NULL, 2387.00, N'SIM-000057-1', '2026-06-23T11:41:45'),
        (59, 58, 2, NULL, 5126.70, N'SIM-000058-1', '2026-06-23T11:57:12'),
        (60, 59, 1, NULL, 3857.10, NULL, '2026-06-23T11:57:31'),
        (61, 59, 3, NULL, 2571.40, N'SIM-000059-2', '2026-06-23T11:57:31'),
        (62, 60, 1, NULL, 2798.00, NULL, '2026-06-23T12:37:07'),
        (63, 61, 1, NULL, 8135.10, NULL, '2026-06-23T13:39:23'),
        (64, 63, 1, NULL, 4623.00, NULL, '2026-06-23T14:24:06'),
        (65, 64, 1, NULL, 3300.50, NULL, '2026-06-23T14:54:38'),
        (66, 65, 1, NULL, 3977.85, NULL, '2026-06-23T15:11:11'),
        (67, 66, 3, 5, 4047.50, N'SIM-000066-1', '2026-06-24T20:48:35'),
        (68, 67, 3, NULL, 3629.40, N'SIM-000067-1', '2026-06-26T08:53:30'),
        (69, 68, 1, NULL, 2452.29, NULL, '2026-06-26T10:23:16'),
        (70, 68, 3, NULL, 1634.86, N'SIM-000068-2', '2026-06-26T10:23:16'),
        (71, 69, 1, NULL, 1840.00, NULL, '2026-06-26T11:34:48'),
        (72, 70, 3, NULL, 2860.75, N'SIM-000070-1', '2026-06-26T13:50:26'),
        (73, 71, 3, 29, 5235.12, N'SIM-000071-1', '2026-06-28T17:25:39'),
        (74, 72, 1, NULL, 1842.30, NULL, '2026-06-29T09:32:44'),
        (75, 73, 1, NULL, 3746.70, NULL, '2026-06-29T10:25:42'),
        (76, 73, 3, NULL, 2497.80, N'SIM-000073-2', '2026-06-29T10:25:42'),
        (77, 74, 2, NULL, 2164.19, N'SIM-000074-1', '2026-06-29T10:47:24'),
        (78, 75, 1, NULL, 2869.02, NULL, '2026-06-29T11:50:47'),
        (79, 76, 1, NULL, 437.00, NULL, '2026-06-29T12:24:34'),
        (80, 77, 1, NULL, 4119.30, NULL, '2026-06-29T12:46:09'),
        (81, 78, 1, NULL, 3663.00, NULL, '2026-06-29T13:37:54'),
        (82, 79, 1, NULL, 276.00, NULL, '2026-06-29T13:52:37'),
        (83, 80, 2, NULL, 2960.10, N'SIM-000080-1', '2026-06-29T14:31:22'),
        (84, 81, 2, 11, 2778.00, N'SIM-000081-1', '2026-07-01T03:01:05'),
        (85, 82, 2, NULL, 745.20, N'SIM-000082-1', '2026-07-02T11:27:15'),
        (86, 83, 3, NULL, 2562.20, N'SIM-000083-1', '2026-07-02T12:04:47'),
        (87, 84, 1, NULL, 714.90, NULL, '2026-07-02T13:13:18'),
        (88, 85, 1, NULL, 2916.40, NULL, '2026-07-02T15:02:20'),
        (89, 86, 3, NULL, 3804.20, N'SIM-000086-1', '2026-07-02T15:39:57'),
        (90, 87, 3, 1, 6434.88, N'SIM-000087-1', '2026-07-03T01:47:23'),
        (91, 88, 3, 14, 5151.50, N'SIM-000088-1', '2026-07-03T10:07:55'),
        (92, 89, 1, NULL, 1945.39, NULL, '2026-07-03T10:41:45'),
        (93, 89, 2, NULL, 1296.92, N'SIM-000089-2', '2026-07-03T10:41:45'),
        (94, 90, 1, NULL, 6888.50, NULL, '2026-07-03T13:36:27'),
        (95, 91, 1, NULL, 4140.00, NULL, '2026-07-03T15:19:55'),
        (96, 92, 1, NULL, 3024.50, NULL, '2026-07-05T09:20:25'),
        (97, 93, 1, NULL, 683.10, NULL, '2026-07-05T11:26:02'),
        (98, 93, 3, NULL, 455.40, N'SIM-000093-2', '2026-07-05T11:26:02'),
        (99, 94, 3, NULL, 998.20, N'SIM-000094-1', '2026-07-05T11:55:21'),
        (100, 95, 2, NULL, 1104.00, N'SIM-000095-1', '2026-07-05T14:02:26'),
        (101, 96, 2, NULL, 543.95, N'SIM-000096-1', '2026-07-05T14:24:39'),
        (102, 97, 1, NULL, 989.00, NULL, '2026-07-05T14:29:10'),
        (103, 98, 2, 32, 4178.60, N'SIM-000098-1', '2026-07-05T23:05:35'),
        (104, 99, 2, 27, 3045.52, N'SIM-000099-1', '2026-07-05T23:31:27'),
        (105, 100, 1, NULL, 4577.00, NULL, '2026-07-08T09:34:18'),
        (106, 101, 1, NULL, 310.30, NULL, '2026-07-08T10:40:09'),
        (107, 102, 3, 26, 900.08, N'SIM-000102-1', '2026-07-09T12:08:22'),
        (108, 103, 1, NULL, 4098.60, NULL, '2026-07-10T09:49:11'),
        (109, 104, 3, NULL, 4908.66, N'SIM-000104-1', '2026-07-10T12:32:56'),
        (110, 105, 1, NULL, 396.06, NULL, '2026-07-10T14:58:25'),
        (111, 106, 1, NULL, 4577.00, NULL, '2026-07-10T15:56:30'),
        (112, 107, 3, NULL, 4864.50, N'SIM-000107-1', '2026-07-11T10:38:26'),
        (113, 108, 1, NULL, 4393.00, NULL, '2026-07-11T11:10:18'),
        (114, 109, 1, NULL, 1483.27, NULL, '2026-07-13T10:07:26'),
        (115, 110, 1, NULL, 8831.77, NULL, '2026-07-13T10:14:03'),
        (116, 112, 2, 37, 2288.00, N'SIM-000112-1', '2026-07-15T12:43:06'),
        (117, 113, 2, NULL, 1851.50, N'SIM-000113-1', '2026-07-17T08:38:36'),
        (118, 114, 1, NULL, 3236.56, NULL, '2026-07-17T08:41:30'),
        (119, 115, 1, NULL, 5368.66, NULL, '2026-07-17T12:20:13'),
        (120, 116, 1, NULL, 5520.00, NULL, '2026-07-18T10:37:46'),
        (121, 117, 2, NULL, 4680.50, N'SIM-000117-1', '2026-07-18T11:22:28'),
        (122, 118, 2, NULL, 3581.10, N'SIM-000118-1', '2026-07-18T15:33:57'),
        (123, 119, 3, NULL, 5961.26, N'SIM-000119-1', '2026-07-18T15:55:19'),
        (124, 120, 3, 38, 3183.60, N'SIM-000120-1', '2026-07-19T00:49:05'),
        (125, 121, 3, 8, 2239.70, N'SIM-000121-1', '2026-07-20T08:38:40'),
        (126, 122, 2, NULL, 685.20, N'SIM-000122-1', '2026-07-20T10:43:02'),
        (127, 123, 1, NULL, 1127.00, NULL, '2026-07-20T13:23:54'),
        (128, 124, 3, NULL, 4050.00, N'SIM-000124-1', '2026-07-20T15:21:32'),
        (129, 125, 1, NULL, 2964.50, NULL, '2026-07-22T09:59:34'),
        (130, 126, 1, NULL, 1932.00, NULL, '2026-07-22T11:23:27'),
        (131, 127, 3, NULL, 5305.76, N'SIM-000127-1', '2026-07-22T11:44:44'),
        (132, 128, 1, NULL, 4792.05, NULL, '2026-07-23T09:07:37'),
        (133, 129, 1, NULL, 1217.16, NULL, '2026-07-23T10:30:23'),
        (134, 129, 2, NULL, 811.44, N'SIM-000129-2', '2026-07-23T10:30:23'),
        (135, 130, 1, NULL, 1288.00, NULL, '2026-07-23T12:40:35'),
        (136, 131, 2, 6, 2282.00, N'SIM-000131-1', '2026-07-23T23:41:17'),
        (137, 132, 2, NULL, 1812.40, N'SIM-000132-1', '2026-07-24T10:19:45'),
        (138, 133, 1, NULL, 7345.05, NULL, '2026-07-24T11:36:10'),
        (139, 134, 2, NULL, 3075.79, N'SIM-000134-1', '2026-07-24T12:00:10'),
        (140, 135, 2, NULL, 3252.20, N'SIM-000135-1', '2026-07-24T12:28:53'),
        (141, 136, 3, NULL, 3652.40, N'SIM-000136-1', '2026-07-24T13:20:52'),
        (142, 138, 1, NULL, 2886.96, NULL, '2026-07-24T15:17:10'),
        (143, 138, 2, NULL, 1924.64, N'SIM-000138-2', '2026-07-24T15:17:10'),
        (144, 140, 1, NULL, 966.00, NULL, '2026-07-29T08:52:56'),
        (145, 141, 1, NULL, 5184.20, NULL, '2026-07-29T14:45:34'),
        (146, 142, 3, 19, 1224.06, N'SIM-000142-1', '2026-07-30T03:49:23'),
        (147, 143, 2, NULL, 4216.80, N'SIM-000143-1', '2026-07-31T08:47:36'),
        (148, 144, 1, NULL, 5809.80, NULL, '2026-07-31T08:59:13'),
        (149, 145, 1, NULL, 2443.98, NULL, '2026-07-31T09:16:57'),
        (150, 145, 2, NULL, 1629.32, N'SIM-000145-2', '2026-07-31T09:16:57'),
        (151, 146, 1, NULL, 3033.70, NULL, '2026-07-31T09:40:16'),
        (152, 147, 1, NULL, 3063.60, NULL, '2026-07-31T14:57:00'),
        (153, 147, 3, NULL, 2042.40, N'SIM-000147-2', '2026-07-31T14:57:00'),
        (154, 148, 2, NULL, 3883.45, N'SIM-000148-1', '2026-07-31T15:03:51'),
        (155, 149, 3, NULL, 1678.54, N'SIM-000149-1', '2026-07-31T15:21:37'),
        (156, 150, 1, NULL, 5106.00, NULL, '2026-07-31T15:22:30'),
        (157, 151, 1, NULL, 839.27, NULL, '2026-08-01T08:31:14'),
        (158, 152, 1, NULL, 1429.68, NULL, '2026-08-01T09:42:02'),
        (159, 153, 2, NULL, 4067.78, N'SIM-000153-1', '2026-08-01T11:14:22'),
        (160, 154, 1, NULL, 5477.45, NULL, '2026-08-01T13:36:30'),
        (161, 155, 3, NULL, 6762.00, N'SIM-000155-1', '2026-08-01T15:19:10'),
        (162, 156, 1, NULL, 4400.00, NULL, '2026-08-01T15:45:52'),
        (163, 158, 1, NULL, 1656.00, NULL, '2026-08-03T11:54:44'),
        (164, 159, 1, NULL, 3542.00, NULL, '2026-08-03T12:56:11'),
        (165, 160, 1, NULL, 1092.50, NULL, '2026-08-03T15:25:36'),
        (166, 161, 3, NULL, 3509.00, N'SIM-000161-1', '2026-08-03T15:49:14'),
        (167, 162, 3, 19, 1086.00, N'SIM-000162-1', '2026-08-07T10:36:36'),
        (168, 163, 3, 24, 2936.50, N'SIM-000163-1', '2026-08-07T21:18:55'),
        (169, 164, 2, 9, 2926.84, N'SIM-000164-1', '2026-08-09T02:35:08'),
        (170, 165, 1, NULL, 213.90, NULL, '2026-08-11T11:47:32'),
        (171, 165, 3, NULL, 142.60, N'SIM-000165-2', '2026-08-11T11:47:32'),
        (172, 166, 1, NULL, 926.81, NULL, '2026-08-11T15:28:42'),
        (173, 166, 3, NULL, 617.87, N'SIM-000166-2', '2026-08-11T15:28:42'),
        (174, 168, 1, NULL, 3593.52, NULL, '2026-08-16T13:12:38'),
        (175, 169, 2, NULL, 2553.00, N'SIM-000169-1', '2026-08-16T14:49:25'),
        (176, 170, 1, NULL, 478.40, NULL, '2026-08-16T14:52:55'),
        (177, 171, 1, NULL, 1290.30, NULL, '2026-08-16T15:37:53'),
        (178, 172, 3, NULL, 784.30, N'SIM-000172-1', '2026-08-17T08:40:06'),
        (179, 173, 3, NULL, 2660.64, N'SIM-000173-1', '2026-08-17T08:44:14'),
        (180, 174, 3, NULL, 4857.60, N'SIM-000174-1', '2026-08-17T09:04:23'),
        (181, 175, 1, NULL, 3106.38, NULL, '2026-08-17T11:03:51'),
        (182, 175, 2, NULL, 2070.92, N'SIM-000175-2', '2026-08-17T11:03:51'),
        (183, 176, 2, NULL, 1621.27, N'SIM-000176-1', '2026-08-17T14:52:40'),
        (184, 177, 1, NULL, 3384.92, NULL, '2026-08-17T15:02:00'),
        (185, 178, 2, 2, 1529.00, N'SIM-000178-1', '2026-08-17T20:32:31'),
        (186, 179, 1, NULL, 2189.00, NULL, '2026-08-18T09:56:51'),
        (187, 180, 2, NULL, 5129.00, N'SIM-000180-1', '2026-08-18T10:49:52'),
        (188, 181, 1, NULL, 4050.00, NULL, '2026-08-18T14:04:48'),
        (189, 182, 2, NULL, 483.00, N'SIM-000182-1', '2026-08-18T14:16:59'),
        (190, 183, 1, NULL, 5802.90, NULL, '2026-08-18T14:36:11'),
        (191, 184, 1, NULL, 2086.56, NULL, '2026-08-18T15:16:26'),
        (192, 185, 2, 34, 672.00, N'SIM-000185-1', '2026-08-18T23:12:30'),
        (193, 186, 3, 5, 321.50, N'SIM-000186-1', '2026-08-19T02:45:19'),
        (194, 187, 3, 5, 5318.00, N'SIM-000187-1', '2026-08-19T18:14:57'),
        (195, 188, 1, NULL, 961.40, NULL, '2026-08-20T11:00:10'),
        (196, 189, 1, NULL, 3689.20, NULL, '2026-08-20T13:32:59'),
        (197, 190, 1, NULL, 6532.00, NULL, '2026-08-20T13:39:02'),
        (198, 191, 1, NULL, 644.00, NULL, '2026-08-20T13:47:05'),
        (199, 192, 3, NULL, 4622.40, N'SIM-000192-1', '2026-08-20T13:47:45'),
        (200, 193, 1, NULL, 5698.25, NULL, '2026-08-20T14:46:17'),
        (201, 194, 1, NULL, 2241.58, NULL, '2026-08-20T14:53:15'),
        (202, 195, 1, NULL, 3556.95, NULL, '2026-08-21T11:30:07'),
        (203, 196, 3, NULL, 2750.62, N'SIM-000196-1', '2026-08-21T12:05:31'),
        (204, 198, 2, 30, 4514.00, N'SIM-000198-1', '2026-08-23T13:49:49'),
        (205, 199, 3, 40, 6363.60, N'SIM-000199-1', '2026-08-23T15:33:29'),
        (206, 200, 1, NULL, 1086.34, NULL, '2026-08-24T08:48:11'),
        (207, 200, 3, NULL, 724.22, N'SIM-000200-2', '2026-08-24T08:48:11'),
        (208, 201, 1, NULL, 7537.10, NULL, '2026-08-24T11:47:49'),
        (209, 202, 1, NULL, 2114.71, NULL, '2026-08-24T12:10:41'),
        (210, 202, 2, NULL, 1409.81, N'SIM-000202-2', '2026-08-24T12:10:41'),
        (211, 203, 1, NULL, 2765.52, NULL, '2026-08-24T12:39:59'),
        (212, 203, 2, NULL, 1843.68, N'SIM-000203-2', '2026-08-24T12:39:59'),
        (213, 205, 3, NULL, 1605.40, N'SIM-000205-1', '2026-08-24T15:58:38'),
        (214, 207, 2, 27, 678.00, N'SIM-000207-1', '2026-08-26T08:54:42'),
        (215, 208, 3, NULL, 8866.39, N'SIM-000208-1', '2026-08-26T10:53:31'),
        (216, 209, 1, NULL, 7825.75, NULL, '2026-08-26T12:07:30'),
        (217, 210, 2, NULL, 2185.00, N'SIM-000210-1', '2026-08-27T08:57:06'),
        (218, 211, 1, NULL, 1156.20, NULL, '2026-08-27T13:20:01'),
        (219, 211, 2, NULL, 770.80, N'SIM-000211-2', '2026-08-27T13:20:01'),
        (220, 212, 2, 30, 948.00, N'SIM-000212-1', '2026-08-27T20:26:51'),
        (221, 213, 3, 24, 5464.74, N'SIM-000213-1', '2026-08-28T12:52:24'),
        (222, 214, 1, NULL, 2323.32, NULL, '2026-08-28T12:52:47'),
        (223, 216, 2, NULL, 1357.00, N'SIM-000216-1', '2026-08-28T15:52:23'),
        (224, 217, 3, 5, 1672.50, N'SIM-000217-1', '2026-09-02T21:37:02'),
        (225, 218, 1, NULL, 2219.68, NULL, '2026-09-04T11:14:11'),
        (226, 218, 2, NULL, 1479.78, N'SIM-000218-2', '2026-09-04T11:14:11'),
        (227, 219, 1, NULL, 1922.40, NULL, '2026-09-04T11:30:10'),
        (228, 220, 1, NULL, 2915.70, NULL, '2026-09-04T13:04:00'),
        (229, 220, 3, NULL, 1943.80, N'SIM-000220-2', '2026-09-04T13:04:00'),
        (230, 221, 3, NULL, 3360.00, N'SIM-000221-1', '2026-09-04T13:59:54'),
        (231, 222, 3, 26, 4064.65, N'SIM-000222-1', '2026-09-06T23:05:05'),
        (232, 223, 2, 23, 4393.40, N'SIM-000223-1', '2026-09-07T04:47:01'),
        (233, 224, 1, NULL, 2079.00, NULL, '2026-09-07T08:36:21'),
        (234, 225, 3, NULL, 4583.90, N'SIM-000225-1', '2026-09-07T09:15:38'),
        (235, 226, 1, NULL, 792.12, NULL, '2026-09-07T09:16:54'),
        (236, 227, 1, NULL, 3507.50, NULL, '2026-09-07T09:52:15'),
        (237, 228, 2, NULL, 3756.82, N'SIM-000228-1', '2026-09-07T09:56:54'),
        (238, 229, 3, NULL, 5344.05, N'SIM-000229-1', '2026-09-07T11:14:07'),
        (239, 230, 3, NULL, 1127.00, N'SIM-000230-1', '2026-09-07T12:51:00'),
        (240, 231, 2, NULL, 6114.78, N'SIM-000231-1', '2026-09-07T13:11:25'),
        (241, 232, 1, NULL, 6129.50, NULL, '2026-09-07T13:51:27'),
        (242, 233, 2, NULL, 4870.25, N'SIM-000233-1', '2026-09-07T14:56:43'),
        (243, 234, 3, 38, 1142.50, N'SIM-000234-1', '2026-09-08T06:22:24'),
        (244, 235, 1, NULL, 503.42, NULL, '2026-09-08T08:47:21'),
        (245, 235, 3, NULL, 335.62, N'SIM-000235-2', '2026-09-08T08:47:21'),
        (246, 236, 1, NULL, 1188.18, NULL, '2026-09-08T10:54:07'),
        (247, 237, 2, NULL, 4176.40, N'SIM-000237-1', '2026-09-08T12:22:17'),
        (248, 238, 2, NULL, 2587.50, N'SIM-000238-1', '2026-09-08T15:04:36'),
        (249, 239, 3, NULL, 7105.62, N'SIM-000239-1', '2026-09-09T12:50:25'),
        (250, 241, 2, 16, 1174.80, N'SIM-000241-1', '2026-09-12T03:28:49'),
        (251, 242, 3, NULL, 1000.50, N'SIM-000242-1', '2026-09-12T08:43:48'),
        (252, 243, 2, NULL, 793.50, N'SIM-000243-1', '2026-09-12T10:17:54'),
        (253, 244, 3, 5, 356.00, N'SIM-000244-1', '2026-09-12T13:55:46'),
        (254, 245, 2, NULL, 1518.00, N'SIM-000245-1', '2026-09-15T10:12:16'),
        (255, 246, 1, NULL, 552.00, NULL, '2026-09-15T13:45:39'),
        (256, 247, 1, NULL, 3567.19, NULL, '2026-09-15T14:10:09'),
        (257, 248, 3, 22, 3469.05, N'SIM-000248-1', '2026-09-16T02:01:11'),
        (258, 249, 2, NULL, 1665.20, N'SIM-000249-1', '2026-09-17T10:10:27'),
        (259, 251, 1, NULL, 3438.60, NULL, '2026-09-17T12:09:53'),
        (260, 252, 1, NULL, 2346.00, NULL, '2026-09-17T12:18:24'),
        (261, 253, 2, NULL, 2669.10, N'SIM-000253-1', '2026-09-20T08:30:58'),
        (262, 254, 1, NULL, 407.10, NULL, '2026-09-20T08:35:09'),
        (263, 254, 2, NULL, 271.40, N'SIM-000254-2', '2026-09-20T08:35:09'),
        (264, 255, 1, NULL, 1357.00, NULL, '2026-09-20T11:57:19'),
        (265, 256, 2, NULL, 3245.30, N'SIM-000256-1', '2026-09-20T13:05:18'),
        (266, 257, 1, NULL, 3898.50, NULL, '2026-09-20T13:08:10'),
        (267, 258, 1, NULL, 289.80, NULL, '2026-09-23T08:44:16'),
        (268, 258, 3, NULL, 193.20, N'SIM-000258-2', '2026-09-23T08:44:16'),
        (269, 259, 1, NULL, 3032.55, NULL, '2026-09-23T09:14:59'),
        (270, 259, 3, NULL, 2021.70, N'SIM-000259-2', '2026-09-23T09:14:59'),
        (271, 260, 1, NULL, 4456.16, NULL, '2026-09-23T11:08:51'),
        (272, 260, 2, NULL, 2970.77, N'SIM-000260-2', '2026-09-23T11:08:51'),
        (273, 261, 1, NULL, 2777.25, NULL, '2026-09-23T11:28:08'),
        (274, 262, 1, NULL, 3574.00, NULL, '2026-09-23T11:44:19'),
        (275, 263, 3, NULL, 1207.50, N'SIM-000263-1', '2026-09-23T13:50:15'),
        (276, 266, 1, NULL, 414.00, NULL, '2026-09-25T08:48:37'),
        (277, 267, 2, NULL, 4637.26, N'SIM-000267-1', '2026-09-25T11:00:13'),
        (278, 268, 1, NULL, 4414.50, NULL, '2026-09-25T11:42:42'),
        (279, 269, 1, NULL, 3910.00, NULL, '2026-09-25T14:24:59'),
        (280, 270, 3, NULL, 4065.85, N'SIM-000270-1', '2026-09-25T15:31:37'),
        (281, 271, 1, NULL, 1104.00, NULL, '2026-09-25T15:44:50'),
        (282, 271, 3, NULL, 736.00, N'SIM-000271-2', '2026-09-25T15:44:50'),
        (283, 272, 1, NULL, 379.50, NULL, '2026-09-25T15:55:33'),
        (284, 273, 1, NULL, 3966.12, NULL, '2026-09-25T15:58:09'),
        (285, 273, 3, NULL, 2644.08, N'SIM-000273-2', '2026-09-25T15:58:09'),
        (286, 274, 3, 17, 1579.50, N'SIM-000274-1', '2026-09-25T20:15:04'),
        (287, 275, 3, 31, 4169.40, N'SIM-000275-1', '2026-09-28T07:35:10'),
        (288, 276, 1, NULL, 2080.35, NULL, '2026-09-28T10:30:09'),
        (289, 277, 3, NULL, 7950.18, N'SIM-000277-1', '2026-09-28T10:38:01'),
        (290, 279, 3, NULL, 774.90, N'SIM-000279-1', '2026-09-28T13:31:25'),
        (291, 281, 1, NULL, 579.60, NULL, '2026-09-28T15:56:11'),
        (292, 281, 3, NULL, 386.40, N'SIM-000281-2', '2026-09-28T15:56:11'),
        (293, 282, 1, NULL, 1207.50, NULL, '2026-09-30T08:56:59'),
        (294, 283, 2, NULL, 7084.00, N'SIM-000283-1', '2026-09-30T10:30:48'),
        (295, 284, 2, NULL, 3217.50, N'SIM-000284-1', '2026-09-30T12:08:13'),
        (296, 285, 1, NULL, 2408.10, NULL, '2026-09-30T13:03:08'),
        (297, 286, 3, NULL, 3278.00, N'SIM-000286-1', '2026-09-30T13:35:57'),
        (298, 287, 1, NULL, 474.72, NULL, '2026-09-30T14:47:10'),
        (299, 287, 2, NULL, 316.48, N'SIM-000287-2', '2026-09-30T14:47:10'),
        (300, 288, 1, NULL, 789.36, NULL, '2026-09-30T15:11:54'),
        (301, 288, 2, NULL, 526.24, N'SIM-000288-2', '2026-09-30T15:11:54'),
        (302, 289, 1, NULL, 4347.22, NULL, '2026-09-30T15:24:01'),
        (303, 290, 3, 24, 7647.00, N'SIM-000290-1', '2026-10-01T01:36:42'),
        (304, 291, 3, NULL, 1328.25, N'SIM-000291-1', '2026-10-03T11:58:12'),
        (305, 292, 2, NULL, 3849.05, N'SIM-000292-1', '2026-10-03T12:18:16'),
        (306, 293, 3, NULL, 1144.75, N'SIM-000293-1', '2026-10-03T14:22:04'),
        (307, 294, 1, NULL, 6842.50, NULL, '2026-10-03T14:34:00'),
        (308, 295, 1, NULL, 1857.25, NULL, '2026-10-04T12:46:59'),
        (309, 296, 3, NULL, 5065.98, N'SIM-000296-1', '2026-10-04T13:01:02'),
        (310, 297, 2, NULL, 2815.89, N'SIM-000297-1', '2026-10-04T15:51:14'),
        (311, 298, 2, 2, 3461.00, N'SIM-000298-1', '2026-10-06T03:55:42'),
        (312, 299, 3, 31, 1893.76, N'SIM-000299-1', '2026-10-07T15:09:46'),
        (313, 300, 1, NULL, 2420.75, NULL, '2026-10-08T08:51:43'),
        (314, 301, 2, NULL, 5850.28, N'SIM-000301-1', '2026-10-08T09:03:46'),
        (315, 302, 1, NULL, 6014.50, NULL, '2026-10-08T09:31:02'),
        (316, 303, 1, NULL, 3387.90, NULL, '2026-10-08T10:51:45'),
        (317, 303, 2, NULL, 2258.60, N'SIM-000303-2', '2026-10-08T10:51:45'),
        (318, 304, 1, NULL, 6027.84, NULL, '2026-10-08T10:55:10'),
        (319, 305, 2, NULL, 5154.30, N'SIM-000305-1', '2026-10-08T12:51:56'),
        (320, 306, 3, NULL, 2746.20, N'SIM-000306-1', '2026-10-08T13:56:18'),
        (321, 307, 3, NULL, 2189.60, N'SIM-000307-1', '2026-10-08T14:07:35'),
        (322, 308, 3, NULL, 1497.76, N'SIM-000308-1', '2026-10-08T14:15:54'),
        (323, 310, 1, NULL, 5674.10, NULL, '2026-10-08T15:29:16'),
        (324, 311, 1, NULL, 1075.02, NULL, '2026-10-09T11:16:46'),
        (325, 312, 2, NULL, 194.35, N'SIM-000312-1', '2026-10-09T12:56:10'),
        (326, 313, 3, 28, 9267.58, N'SIM-000313-1', '2026-10-09T14:13:51'),
        (327, 314, 1, NULL, 2116.00, NULL, '2026-10-09T15:06:16'),
        (328, 315, 2, NULL, 542.49, N'SIM-000315-1', '2026-10-09T15:21:16'),
        (329, 316, 2, NULL, 782.00, N'SIM-000316-1', '2026-10-10T11:28:23'),
        (330, 317, 1, NULL, 1840.40, NULL, '2026-10-10T11:49:39'),
        (331, 319, 2, NULL, 2549.40, N'SIM-000319-1', '2026-10-12T12:43:02'),
        (332, 320, 2, NULL, 966.00, N'SIM-000320-1', '2026-10-12T14:46:05'),
        (333, 321, 2, NULL, 3898.50, N'SIM-000321-1', '2026-10-12T14:53:35'),
        (334, 322, 1, NULL, 1141.03, NULL, '2026-10-12T15:39:19'),
        (335, 323, 1, NULL, 3111.90, NULL, '2026-10-14T09:00:41'),
        (336, 324, 3, NULL, 1152.35, N'SIM-000324-1', '2026-10-14T15:45:24'),
        (337, 325, 3, 1, 1394.93, N'SIM-000325-1', '2026-10-16T20:51:00'),
        (338, 326, 1, NULL, 3149.44, NULL, '2026-10-18T09:09:09'),
        (339, 326, 2, NULL, 2099.62, N'SIM-000326-2', '2026-10-18T09:09:09'),
        (340, 327, 3, NULL, 3816.85, N'SIM-000327-1', '2026-10-18T10:19:17'),
        (341, 328, 3, 33, 1013.57, N'SIM-000328-1', '2026-10-18T12:08:17'),
        (342, 329, 2, NULL, 3567.88, N'SIM-000329-1', '2026-10-18T13:39:50'),
        (343, 331, 1, NULL, 1694.09, NULL, '2026-10-21T09:13:31'),
        (344, 331, 3, NULL, 1129.39, N'SIM-000331-2', '2026-10-21T09:13:31'),
        (345, 332, 1, NULL, 588.00, NULL, '2026-10-21T11:02:25'),
        (346, 333, 2, NULL, 3912.30, N'SIM-000333-1', '2026-10-21T12:21:31'),
        (347, 334, 1, NULL, 3017.60, NULL, '2026-10-21T14:39:25'),
        (348, 335, 1, NULL, 250.47, NULL, '2026-10-21T14:44:10'),
        (349, 335, 2, NULL, 166.98, N'SIM-000335-2', '2026-10-21T14:44:10'),
        (350, 336, 1, NULL, 1938.90, NULL, '2026-10-21T15:48:49'),
        (351, 336, 3, NULL, 1292.60, N'SIM-000336-2', '2026-10-21T15:48:49'),
        (352, 337, 3, 33, 4341.80, N'SIM-000337-1', '2026-10-23T06:24:30'),
        (353, 338, 3, NULL, 4354.94, N'SIM-000338-1', '2026-10-24T08:49:26'),
        (354, 339, 1, NULL, 1069.50, NULL, '2026-10-24T08:54:12'),
        (355, 340, 2, NULL, 5502.75, N'SIM-000340-1', '2026-10-24T09:10:17'),
        (356, 341, 2, NULL, 2455.75, N'SIM-000341-1', '2026-10-24T10:08:58'),
        (357, 342, 2, NULL, 986.75, N'SIM-000342-1', '2026-10-24T10:32:02'),
        (358, 343, 1, NULL, 1558.25, NULL, '2026-10-24T10:41:19'),
        (359, 344, 1, NULL, 1288.00, NULL, '2026-10-24T11:40:03'),
        (360, 345, 2, NULL, 1613.45, N'SIM-000345-1', '2026-10-24T12:25:11'),
        (361, 346, 1, NULL, 407.10, NULL, '2026-10-24T14:34:09'),
        (362, 346, 2, NULL, 271.40, N'SIM-000346-2', '2026-10-24T14:34:09'),
        (363, 347, 1, NULL, 2742.61, NULL, '2026-10-24T15:13:08'),
        (364, 347, 2, NULL, 1828.41, N'SIM-000347-2', '2026-10-24T15:13:08'),
        (365, 348, 1, NULL, 3919.20, NULL, '2026-10-24T15:29:30'),
        (366, 348, 2, NULL, 2612.80, N'SIM-000348-2', '2026-10-24T15:29:30'),
        (367, 349, 3, 36, 1391.00, N'SIM-000349-1', '2026-10-24T18:26:25'),
        (368, 350, 2, 11, 1001.04, N'SIM-000350-1', '2026-10-25T23:42:25'),
        (369, 353, 2, NULL, 4048.00, N'SIM-000353-1', '2026-10-28T09:36:06'),
        (370, 354, 1, NULL, 1540.77, NULL, '2026-10-28T13:41:36'),
        (371, 355, 3, NULL, 4512.26, N'SIM-000355-1', '2026-10-28T15:56:14'),
        (372, 357, 1, NULL, 4965.47, NULL, '2026-10-30T10:45:17'),
        (373, 358, 1, NULL, 3450.00, NULL, '2026-10-30T15:38:32'),
        (374, 359, 2, NULL, 874.00, N'SIM-000359-1', '2026-10-30T15:58:57'),
        (375, 360, 3, NULL, 7524.00, N'SIM-000360-1', '2026-10-31T08:37:14'),
        (376, 361, 1, NULL, 3297.25, NULL, '2026-10-31T10:23:39'),
        (377, 362, 2, 9, 2371.62, N'SIM-000362-1', '2026-10-31T10:34:53'),
        (378, 363, 1, NULL, 839.27, NULL, '2026-10-31T12:02:54'),
        (379, 364, 3, NULL, 1561.77, N'SIM-000364-1', '2026-10-31T14:41:12'),
        (380, 365, 2, NULL, 1678.54, N'SIM-000365-1', '2026-10-31T15:49:42'),
        (381, 366, 1, NULL, 3504.05, NULL, '2026-11-01T13:27:31'),
        (382, 367, 3, NULL, 4068.24, N'SIM-000367-1', '2026-11-01T13:43:25'),
        (383, 368, 1, NULL, 1073.09, NULL, '2026-11-01T13:46:52'),
        (384, 368, 2, NULL, 715.39, N'SIM-000368-2', '2026-11-01T13:46:52'),
        (385, 369, 3, NULL, 789.36, N'SIM-000369-1', '2026-11-01T14:13:00'),
        (386, 371, 1, NULL, 12223.04, NULL, '2026-11-01T15:41:03'),
        (387, 372, 2, NULL, 4066.40, N'SIM-000372-1', '2026-11-03T08:47:01'),
        (388, 373, 2, NULL, 3611.58, N'SIM-000373-1', '2026-11-03T09:39:39'),
        (389, 374, 1, NULL, 11034.48, NULL, '2026-11-03T10:05:04'),
        (390, 375, 3, 31, 6430.20, N'SIM-000375-1', '2026-11-03T10:15:02'),
        (391, 376, 3, NULL, 1631.85, N'SIM-000376-1', '2026-11-03T11:00:26'),
        (392, 378, 3, NULL, 1810.56, N'SIM-000378-1', '2026-11-03T11:50:13'),
        (393, 379, 3, NULL, 1437.50, N'SIM-000379-1', '2026-11-03T12:13:55'),
        (394, 380, 2, NULL, 3233.34, N'SIM-000380-1', '2026-11-03T12:18:15'),
        (395, 381, 1, NULL, 3229.89, NULL, '2026-11-03T13:43:00'),
        (396, 382, 3, NULL, 1138.50, N'SIM-000382-1', '2026-11-03T14:25:48'),
        (397, 383, 3, 33, 5186.00, N'SIM-000383-1', '2026-11-04T09:35:59'),
        (398, 384, 3, 3, 5139.75, N'SIM-000384-1', '2026-11-05T22:27:15'),
        (399, 385, 1, NULL, 1437.50, NULL, '2026-11-06T10:01:11'),
        (400, 386, 3, NULL, 719.80, N'SIM-000386-1', '2026-11-06T14:26:18');
    INSERT INTO dbo.Bill_has_PaymentMethod (Id, Bill_Id, PaymentMethod_Id, PaymentCard_Id, PaidAmount, PaymentReference, RegistrationDate) VALUES
        (401, 387, 1, NULL, 2226.63, NULL, '2026-11-06T14:36:00'),
        (402, 387, 2, NULL, 1484.42, N'SIM-000387-2', '2026-11-06T14:36:00'),
        (403, 388, 1, NULL, 1082.11, NULL, '2026-11-06T14:39:24'),
        (404, 388, 2, NULL, 721.41, N'SIM-000388-2', '2026-11-06T14:39:24'),
        (405, 389, 2, 18, 2819.04, N'SIM-000389-1', '2026-11-07T01:42:07'),
        (406, 391, 2, NULL, 3415.50, N'SIM-000391-1', '2026-11-12T09:11:41'),
        (407, 392, 1, NULL, 2995.75, NULL, '2026-11-12T10:02:05'),
        (408, 393, 1, NULL, 2987.70, NULL, '2026-11-12T11:58:40'),
        (409, 393, 2, NULL, 1991.80, N'SIM-000393-2', '2026-11-12T11:58:40'),
        (410, 394, 1, NULL, 4490.52, NULL, '2026-11-12T12:43:32'),
        (411, 395, 1, NULL, 3634.92, NULL, '2026-11-12T14:33:33'),
        (412, 395, 2, NULL, 2423.28, N'SIM-000395-2', '2026-11-12T14:33:33'),
        (413, 396, 1, NULL, 2426.50, NULL, '2026-11-12T14:57:10'),
        (414, 397, 2, 18, 1953.38, N'SIM-000397-1', '2026-11-13T11:13:22'),
        (415, 398, 3, 8, 274.35, N'SIM-000398-1', '2026-11-13T18:30:10'),
        (416, 399, 2, 34, 3235.04, N'SIM-000399-1', '2026-11-14T00:39:38'),
        (417, 400, 2, NULL, 1391.50, N'SIM-000400-1', '2026-11-14T08:50:19'),
        (418, 401, 3, NULL, 483.00, N'SIM-000401-1', '2026-11-14T08:50:37'),
        (419, 402, 1, NULL, 2978.50, NULL, '2026-11-14T09:01:20'),
        (420, 403, 2, NULL, 738.30, N'SIM-000403-1', '2026-11-14T09:01:38'),
        (421, 404, 1, NULL, 828.40, NULL, '2026-11-14T09:49:33'),
        (422, 405, 1, NULL, 4983.09, NULL, '2026-11-14T10:54:32'),
        (423, 406, 1, NULL, 1497.76, NULL, '2026-11-14T11:59:30'),
        (424, 407, 1, NULL, 1048.80, NULL, '2026-11-14T13:04:01'),
        (425, 407, 2, NULL, 699.20, N'SIM-000407-2', '2026-11-14T13:04:01'),
        (426, 408, 1, NULL, 717.05, NULL, '2026-11-14T14:08:38'),
        (427, 408, 2, NULL, 478.03, N'SIM-000408-2', '2026-11-14T14:08:38'),
        (428, 409, 1, NULL, 9188.50, NULL, '2026-11-14T15:22:56'),
        (429, 410, 3, 10, 5092.52, N'SIM-000410-1', '2026-11-16T01:02:23'),
        (430, 411, 2, 18, 4165.26, N'SIM-000411-1', '2026-11-16T03:15:22'),
        (431, 412, 2, NULL, 2741.29, N'SIM-000412-1', '2026-11-21T08:44:53'),
        (432, 413, 1, NULL, 3179.52, NULL, '2026-11-21T08:51:12'),
        (433, 413, 3, NULL, 2119.68, N'SIM-000413-2', '2026-11-21T08:51:12'),
        (434, 415, 3, NULL, 1678.08, N'SIM-000415-1', '2026-11-21T09:12:06'),
        (435, 416, 1, NULL, 3169.40, NULL, '2026-11-21T09:12:50'),
        (436, 417, 1, NULL, 3346.50, NULL, '2026-11-21T09:50:46'),
        (437, 418, 2, NULL, 1780.62, N'SIM-000418-1', '2026-11-21T09:56:42'),
        (438, 419, 1, NULL, 3576.50, NULL, '2026-11-21T10:20:02'),
        (439, 420, 2, NULL, 4210.92, N'SIM-000420-1', '2026-11-21T10:26:17'),
        (440, 421, 1, NULL, 300.30, NULL, '2026-11-21T10:46:37'),
        (441, 422, 1, NULL, 1483.50, NULL, '2026-11-21T10:49:53'),
        (442, 423, 1, NULL, 3227.48, NULL, '2026-11-21T10:57:48'),
        (443, 424, 1, NULL, 2358.88, NULL, '2026-11-21T11:04:39'),
        (444, 425, 1, NULL, 4181.99, NULL, '2026-11-21T11:05:54'),
        (445, 427, 3, NULL, 5070.12, N'SIM-000427-1', '2026-11-21T11:31:27'),
        (446, 428, 1, NULL, 2863.96, NULL, '2026-11-21T11:34:58'),
        (447, 429, 1, NULL, 2080.35, NULL, '2026-11-21T11:52:39'),
        (448, 430, 1, NULL, 825.70, NULL, '2026-11-21T11:59:12');
    SET IDENTITY_INSERT dbo.Bill_has_PaymentMethod OFF;
END
GO

-- Gestión de almacén
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovement)
BEGIN
    SET IDENTITY_INSERT dbo.StockMovement ON;
    INSERT INTO dbo.StockMovement (Id, MovementType, ClotheVariant_Id, Quantity, Batch_Id, BillDetails_Id, FromStore_Id, FromCubicle_Id, ToStore_Id, ToCubicle_Id, Reason, Employee_Id, RegistrationDate) VALUES
        (1, N'IN', 53, 42, 1, NULL, NULL, NULL, 1, 7, N'Recepción de orden OC-2026-0001', 74, '2026-09-09T10:00:00'),
        (2, N'IN', 50, 38, 2, NULL, NULL, NULL, 1, 1, N'Recepción de orden OC-2026-0001', 74, '2026-09-09T10:00:00'),
        (3, N'IN', 96, 23, 3, NULL, NULL, NULL, 1, 3, N'Recepción de orden OC-2026-0001', 74, '2026-09-09T10:00:00'),
        (4, N'IN', 1, 23, 4, NULL, NULL, NULL, 1, 4, N'Recepción de orden OC-2026-0002', 74, '2026-11-14T10:00:00'),
        (5, N'IN', 135, 10, 5, NULL, NULL, NULL, 1, 8, N'Recepción de orden OC-2026-0002', 74, '2026-11-14T10:00:00'),
        (6, N'IN', 105, 20, 6, NULL, NULL, NULL, 1, 5, N'Recepción de orden OC-2026-0003', 74, '2026-07-13T10:00:00'),
        (7, N'IN', 74, 12, 7, NULL, NULL, NULL, 1, 2, N'Recepción de orden OC-2026-0003', 74, '2026-07-13T10:00:00'),
        (8, N'IN', 86, 22, 8, NULL, NULL, NULL, 1, 7, N'Recepción de orden OC-2026-0003', 74, '2026-07-13T10:00:00'),
        (9, N'IN', 69, 46, 9, NULL, NULL, NULL, 1, 4, N'Recepción de orden OC-2026-0003', 74, '2026-07-13T10:00:00'),
        (10, N'IN', 28, 24, 10, NULL, NULL, NULL, 1, 4, N'Recepción de orden OC-2026-0004', 74, '2026-09-06T10:00:00'),
        (11, N'IN', 30, 22, 11, NULL, NULL, NULL, 1, 4, N'Recepción de orden OC-2026-0004', 74, '2026-09-06T10:00:00'),
        (12, N'IN', 65, 45, 12, NULL, NULL, NULL, 1, 3, N'Recepción de orden OC-2026-0004', 74, '2026-09-06T10:00:00'),
        (13, N'IN', 54, 58, 13, NULL, NULL, NULL, 1, 6, N'Recepción de orden OC-2026-0004', 74, '2026-09-06T10:00:00'),
        (14, N'IN', 38, 55, 14, NULL, NULL, NULL, 3, 14, N'Recepción de orden OC-2026-0005', 18, '2026-08-26T10:00:00'),
        (15, N'IN', 132, 12, 15, NULL, NULL, NULL, 3, 12, N'Recepción de orden OC-2026-0005', 18, '2026-08-26T10:00:00'),
        (16, N'IN', 25, 40, 16, NULL, NULL, NULL, 3, 12, N'Recepción de orden OC-2026-0005', 18, '2026-08-26T10:00:00'),
        (17, N'IN', 90, 58, 17, NULL, NULL, NULL, 5, 21, N'Recepción de orden OC-2026-0007', 20, '2026-07-22T10:00:00'),
        (18, N'IN', 51, 23, 18, NULL, NULL, NULL, 5, 22, N'Recepción de orden OC-2026-0007', 20, '2026-07-22T10:00:00'),
        (19, N'IN', 132, 12, 19, NULL, NULL, NULL, 5, 22, N'Recepción de orden OC-2026-0007', 20, '2026-07-22T10:00:00'),
        (20, N'IN', 46, 34, 20, NULL, NULL, NULL, 7, 27, N'Recepción de orden OC-2026-0009', 22, '2026-10-02T10:00:00'),
        (21, N'IN', 129, 16, 21, NULL, NULL, NULL, 7, 29, N'Recepción de orden OC-2026-0009', 22, '2026-10-02T10:00:00'),
        (22, N'IN', 15, 44, 22, NULL, NULL, NULL, 7, 29, N'Recepción de orden OC-2026-0009', 22, '2026-10-02T10:00:00'),
        (23, N'IN', 82, 27, 23, NULL, NULL, NULL, 8, 34, N'Recepción de orden OC-2026-0010', 23, '2026-10-17T10:00:00'),
        (24, N'IN', 74, 10, 24, NULL, NULL, NULL, 8, 31, N'Recepción de orden OC-2026-0010', 23, '2026-10-17T10:00:00'),
        (25, N'IN', 127, 54, 25, NULL, NULL, NULL, 9, 36, N'Recepción de orden OC-2026-0011', 24, '2026-08-10T10:00:00'),
        (26, N'IN', 144, 31, 26, NULL, NULL, NULL, 9, 36, N'Recepción de orden OC-2026-0011', 24, '2026-08-10T10:00:00'),
        (27, N'IN', 34, 32, 27, NULL, NULL, NULL, 10, 42, N'Recepción de orden OC-2026-0012', 25, '2026-06-21T10:00:00'),
        (28, N'IN', 55, 18, 28, NULL, NULL, NULL, 10, 42, N'Recepción de orden OC-2026-0012', 25, '2026-06-21T10:00:00'),
        (29, N'IN', 95, 24, 29, NULL, NULL, NULL, 10, 42, N'Recepción de orden OC-2026-0012', 25, '2026-06-21T10:00:00'),
        (30, N'IN', 7, 56, 30, NULL, NULL, NULL, 11, 45, N'Recepción de orden OC-2026-0013', 26, '2026-06-23T10:00:00'),
        (31, N'IN', 2, 26, 31, NULL, NULL, NULL, 11, 46, N'Recepción de orden OC-2026-0013', 26, '2026-06-23T10:00:00'),
        (32, N'IN', 83, 45, 32, NULL, NULL, NULL, 12, 50, N'Recepción de orden OC-2026-0014', 27, '2026-07-27T10:00:00'),
        (33, N'IN', 62, 45, 33, NULL, NULL, NULL, 12, 48, N'Recepción de orden OC-2026-0014', 27, '2026-07-27T10:00:00'),
        (34, N'IN', 5, 38, 34, NULL, NULL, NULL, 13, 54, N'Recepción de orden OC-2026-0015', 28, '2026-06-12T10:00:00'),
        (35, N'IN', 138, 11, 35, NULL, NULL, NULL, 13, 52, N'Recepción de orden OC-2026-0015', 28, '2026-06-12T10:00:00'),
        (36, N'IN', 111, 33, 36, NULL, NULL, NULL, 13, 54, N'Recepción de orden OC-2026-0015', 28, '2026-06-12T10:00:00'),
        (37, N'IN', 49, 56, 37, NULL, NULL, NULL, 13, 54, N'Recepción de orden OC-2026-0015', 28, '2026-06-12T10:00:00'),
        (38, N'IN', 145, 23, 38, NULL, NULL, NULL, 14, 56, N'Recepción de orden OC-2026-0016', 29, '2026-10-24T10:00:00'),
        (39, N'IN', 90, 24, 39, NULL, NULL, NULL, 14, 55, N'Recepción de orden OC-2026-0016', 29, '2026-10-24T10:00:00'),
        (40, N'IN', 126, 14, 40, NULL, NULL, NULL, 14, 56, N'Recepción de orden OC-2026-0016', 29, '2026-10-24T10:00:00'),
        (41, N'IN', 133, 15, 41, NULL, NULL, NULL, 15, 60, N'Recepción de orden OC-2026-0017', 30, '2026-10-08T10:00:00'),
        (42, N'IN', 106, 26, 42, NULL, NULL, NULL, 15, 60, N'Recepción de orden OC-2026-0017', 30, '2026-10-08T10:00:00'),
        (43, N'IN', 131, 57, 43, NULL, NULL, NULL, 15, 59, N'Recepción de orden OC-2026-0017', 30, '2026-10-08T10:00:00'),
        (44, N'IN', 152, 47, 44, NULL, NULL, NULL, 15, 61, N'Recepción de orden OC-2026-0017', 30, '2026-10-08T10:00:00'),
        (45, N'IN', 92, 31, 45, NULL, NULL, NULL, 17, 68, N'Recepción de orden OC-2026-0019', 32, '2026-07-09T10:00:00'),
        (46, N'IN', 98, 15, 46, NULL, NULL, NULL, 17, 67, N'Recepción de orden OC-2026-0019', 32, '2026-07-09T10:00:00'),
        (47, N'IN', 80, 27, 47, NULL, NULL, NULL, 19, 78, N'Recepción de orden OC-2026-0021', 34, '2026-09-30T10:00:00'),
        (48, N'IN', 62, 55, 48, NULL, NULL, NULL, 19, 78, N'Recepción de orden OC-2026-0021', 34, '2026-09-30T10:00:00'),
        (49, N'IN', 98, 46, 49, NULL, NULL, NULL, 19, 78, N'Recepción de orden OC-2026-0021', 34, '2026-09-30T10:00:00'),
        (50, N'IN', 132, 43, 50, NULL, NULL, NULL, 19, 78, N'Recepción de orden OC-2026-0021', 34, '2026-09-30T10:00:00'),
        (51, N'IN', 47, 50, 51, NULL, NULL, NULL, 20, 80, N'Recepción de orden OC-2026-0022', 35, '2026-07-04T10:00:00'),
        (52, N'IN', 63, 26, 52, NULL, NULL, NULL, 20, 82, N'Recepción de orden OC-2026-0022', 35, '2026-07-04T10:00:00'),
        (53, N'IN', 131, 13, 53, NULL, NULL, NULL, 20, 81, N'Recepción de orden OC-2026-0022', 35, '2026-07-04T10:00:00'),
        (54, N'IN', 1, 15, 54, NULL, NULL, NULL, 21, 83, N'Recepción de orden OC-2026-0023', 36, '2026-09-22T10:00:00'),
        (55, N'IN', 145, 14, 55, NULL, NULL, NULL, 21, 86, N'Recepción de orden OC-2026-0023', 36, '2026-09-22T10:00:00'),
        (56, N'IN', 159, 32, 56, NULL, NULL, NULL, 21, 86, N'Recepción de orden OC-2026-0023', 36, '2026-09-22T10:00:00'),
        (57, N'IN', 19, 32, 57, NULL, NULL, NULL, 21, 84, N'Recepción de orden OC-2026-0023', 36, '2026-09-22T10:00:00'),
        (58, N'IN', 63, 26, 58, NULL, NULL, NULL, 22, 89, N'Recepción de orden OC-2026-0024', 37, '2026-10-17T10:00:00'),
        (59, N'IN', 79, 10, 59, NULL, NULL, NULL, 22, 90, N'Recepción de orden OC-2026-0024', 37, '2026-10-17T10:00:00'),
        (60, N'IN', 48, 32, 60, NULL, NULL, NULL, 23, 91, N'Recepción de orden OC-2026-0025', 38, '2026-10-17T10:00:00'),
        (61, N'IN', 131, 38, 61, NULL, NULL, NULL, 23, 93, N'Recepción de orden OC-2026-0025', 38, '2026-10-17T10:00:00'),
        (62, N'IN', 113, 42, 62, NULL, NULL, NULL, 23, 92, N'Recepción de orden OC-2026-0025', 38, '2026-10-17T10:00:00'),
        (63, N'IN', 26, 39, 63, NULL, NULL, NULL, 25, 100, N'Recepción de orden OC-2026-0027', 40, '2026-10-30T10:00:00'),
        (64, N'IN', 47, 33, 64, NULL, NULL, NULL, 25, 99, N'Recepción de orden OC-2026-0027', 40, '2026-10-30T10:00:00'),
        (65, N'IN', 89, 47, 65, NULL, NULL, NULL, 25, 101, N'Recepción de orden OC-2026-0027', 40, '2026-10-30T10:00:00'),
        (66, N'IN', 82, 39, 66, NULL, NULL, NULL, 25, 102, N'Recepción de orden OC-2026-0027', 40, '2026-10-30T10:00:00'),
        (67, N'IN', 127, 19, 67, NULL, NULL, NULL, 26, 106, N'Recepción de orden OC-2026-0028', 41, '2026-10-25T10:00:00'),
        (68, N'IN', 151, 24, 68, NULL, NULL, NULL, 26, 106, N'Recepción de orden OC-2026-0028', 41, '2026-10-25T10:00:00'),
        (69, N'IN', 72, 53, 69, NULL, NULL, NULL, 26, 104, N'Recepción de orden OC-2026-0028', 41, '2026-10-25T10:00:00'),
        (70, N'IN', 87, 51, 70, NULL, NULL, NULL, 26, 105, N'Recepción de orden OC-2026-0028', 41, '2026-10-25T10:00:00'),
        (71, N'IN', 128, 55, 71, NULL, NULL, NULL, 27, 107, N'Recepción de orden OC-2026-0029', 42, '2026-08-31T10:00:00'),
        (72, N'IN', 38, 42, 72, NULL, NULL, NULL, 27, 109, N'Recepción de orden OC-2026-0029', 42, '2026-08-31T10:00:00'),
        (73, N'IN', 142, 27, 73, NULL, NULL, NULL, 27, 110, N'Recepción de orden OC-2026-0029', 42, '2026-08-31T10:00:00'),
        (74, N'IN', 65, 56, 74, NULL, NULL, NULL, 28, 111, N'Recepción de orden OC-2026-0030', 43, '2026-09-02T10:00:00'),
        (75, N'IN', 106, 20, 75, NULL, NULL, NULL, 28, 114, N'Recepción de orden OC-2026-0030', 43, '2026-09-02T10:00:00'),
        (76, N'IN', 10, 25, 76, NULL, NULL, NULL, 29, 115, N'Recepción de orden OC-2026-0031', 44, '2026-06-25T10:00:00'),
        (77, N'IN', 130, 33, 77, NULL, NULL, NULL, 29, 115, N'Recepción de orden OC-2026-0031', 44, '2026-06-25T10:00:00'),
        (78, N'IN', 138, 35, 78, NULL, NULL, NULL, 29, 118, N'Recepción de orden OC-2026-0031', 44, '2026-06-25T10:00:00'),
        (79, N'IN', 77, 28, 79, NULL, NULL, NULL, 29, 116, N'Recepción de orden OC-2026-0031', 44, '2026-06-25T10:00:00'),
        (80, N'IN', 21, 16, 80, NULL, NULL, NULL, 30, 121, N'Recepción de orden OC-2026-0032', 45, '2026-07-10T10:00:00'),
        (81, N'IN', 105, 49, 81, NULL, NULL, NULL, 30, 120, N'Recepción de orden OC-2026-0032', 45, '2026-07-10T10:00:00'),
        (82, N'IN', 18, 11, 82, NULL, NULL, NULL, 30, 122, N'Recepción de orden OC-2026-0032', 45, '2026-07-10T10:00:00'),
        (83, N'IN', 140, 48, 83, NULL, NULL, NULL, 4, 16, N'Recepción de orden OC-2026-0034', 19, '2026-10-08T10:00:00'),
        (84, N'IN', 151, 33, 84, NULL, NULL, NULL, 4, 15, N'Recepción de orden OC-2026-0034', 19, '2026-10-08T10:00:00'),
        (85, N'IN', 93, 57, 85, NULL, NULL, NULL, 4, 15, N'Recepción de orden OC-2026-0034', 19, '2026-10-08T10:00:00'),
        (86, N'IN', 45, 17, 86, NULL, NULL, NULL, 4, 17, N'Recepción de orden OC-2026-0034', 19, '2026-10-08T10:00:00'),
        (87, N'IN', 51, 14, 87, NULL, NULL, NULL, 5, 22, N'Recepción de orden OC-2026-0035', 20, '2026-08-19T10:00:00'),
        (88, N'IN', 125, 39, 88, NULL, NULL, NULL, 5, 22, N'Recepción de orden OC-2026-0035', 20, '2026-08-19T10:00:00'),
        (89, N'IN', 12, 16, 89, NULL, NULL, NULL, 5, 20, N'Recepción de orden OC-2026-0035', 20, '2026-08-19T10:00:00'),
        (90, N'IN', 145, 10, 90, NULL, NULL, NULL, 6, 25, N'Recepción de orden OC-2026-0036', 21, '2026-06-18T10:00:00'),
        (91, N'IN', 143, 12, 91, NULL, NULL, NULL, 6, 23, N'Recepción de orden OC-2026-0036', 21, '2026-06-18T10:00:00'),
        (92, N'IN', 75, 14, 92, NULL, NULL, NULL, 6, 24, N'Recepción de orden OC-2026-0036', 21, '2026-06-18T10:00:00'),
        (93, N'IN', 15, 40, 93, NULL, NULL, NULL, 7, 29, N'Recepción de orden OC-2026-0037', 22, '2026-08-27T10:00:00'),
        (94, N'IN', 77, 42, 94, NULL, NULL, NULL, 7, 27, N'Recepción de orden OC-2026-0037', 22, '2026-08-27T10:00:00'),
        (95, N'IN', 91, 51, 95, NULL, NULL, NULL, 7, 27, N'Recepción de orden OC-2026-0037', 22, '2026-08-27T10:00:00'),
        (96, N'IN', 129, 54, 96, NULL, NULL, NULL, 7, 29, N'Recepción de orden OC-2026-0037', 22, '2026-08-27T10:00:00'),
        (97, N'IN', 108, 10, 97, NULL, NULL, NULL, 9, 37, N'Recepción de orden OC-2026-0039', 24, '2026-08-15T10:00:00'),
        (98, N'IN', 48, 27, 98, NULL, NULL, NULL, 9, 35, N'Recepción de orden OC-2026-0039', 24, '2026-08-15T10:00:00'),
        (99, N'IN', 158, 46, 99, NULL, NULL, NULL, 10, 42, N'Recepción de orden OC-2026-0040', 25, '2026-09-22T10:00:00'),
        (100, N'IN', 141, 49, 100, NULL, NULL, NULL, 10, 41, N'Recepción de orden OC-2026-0040', 25, '2026-09-22T10:00:00'),
        (101, N'IN', 139, 30, 101, NULL, NULL, NULL, 10, 41, N'Recepción de orden OC-2026-0040', 25, '2026-09-22T10:00:00'),
        (102, N'IN', 28, 30, 102, NULL, NULL, NULL, 11, 44, N'Recepción de orden OC-2026-0041', 26, '2026-09-19T10:00:00'),
        (103, N'IN', 107, 55, 103, NULL, NULL, NULL, 11, 45, N'Recepción de orden OC-2026-0041', 26, '2026-09-19T10:00:00'),
        (104, N'IN', 132, 24, 104, NULL, NULL, NULL, 13, 52, N'Recepción de orden OC-2026-0043', 28, '2026-09-04T10:00:00'),
        (105, N'IN', 8, 41, 105, NULL, NULL, NULL, 13, 54, N'Recepción de orden OC-2026-0043', 28, '2026-09-04T10:00:00'),
        (106, N'IN', 5, 35, 106, NULL, NULL, NULL, 13, 54, N'Recepción de orden OC-2026-0043', 28, '2026-09-04T10:00:00'),
        (107, N'IN', 51, 24, 107, NULL, NULL, NULL, 13, 51, N'Recepción de orden OC-2026-0043', 28, '2026-09-04T10:00:00'),
        (108, N'IN', 161, 46, 108, NULL, NULL, NULL, 14, 56, N'Recepción de orden OC-2026-0044', 29, '2026-10-01T10:00:00'),
        (109, N'IN', 92, 26, 109, NULL, NULL, NULL, 14, 57, N'Recepción de orden OC-2026-0044', 29, '2026-10-01T10:00:00'),
        (110, N'IN', 145, 42, 110, NULL, NULL, NULL, 14, 56, N'Recepción de orden OC-2026-0044', 29, '2026-10-01T10:00:00'),
        (111, N'IN', 94, 50, 111, NULL, NULL, NULL, 14, 55, N'Recepción de orden OC-2026-0044', 29, '2026-10-01T10:00:00'),
        (112, N'IN', 133, 24, 112, NULL, NULL, NULL, 15, 60, N'Recepción de orden OC-2026-0045', 30, '2026-10-13T10:00:00'),
        (113, N'IN', 99, 55, 113, NULL, NULL, NULL, 15, 62, N'Recepción de orden OC-2026-0045', 30, '2026-10-13T10:00:00'),
        (114, N'IN', 32, 15, 114, NULL, NULL, NULL, 16, 63, N'Recepción de orden OC-2026-0046', 31, '2026-10-19T10:00:00'),
        (115, N'IN', 48, 14, 115, NULL, NULL, NULL, 16, 66, N'Recepción de orden OC-2026-0046', 31, '2026-10-19T10:00:00'),
        (116, N'IN', 58, 45, 116, NULL, NULL, NULL, 16, 63, N'Recepción de orden OC-2026-0046', 31, '2026-10-19T10:00:00'),
        (117, N'IN', 77, 26, 117, NULL, NULL, NULL, 16, 63, N'Recepción de orden OC-2026-0046', 31, '2026-10-19T10:00:00'),
        (118, N'IN', 92, 30, 118, NULL, NULL, NULL, 17, 68, N'Recepción de orden OC-2026-0047', 32, '2026-08-14T10:00:00'),
        (119, N'IN', 56, 44, 119, NULL, NULL, NULL, 17, 69, N'Recepción de orden OC-2026-0047', 32, '2026-08-14T10:00:00'),
        (120, N'IN', 157, 40, 120, NULL, NULL, NULL, 17, 70, N'Recepción de orden OC-2026-0047', 32, '2026-08-14T10:00:00'),
        (121, N'IN', 159, 32, 121, NULL, NULL, NULL, 17, 68, N'Recepción de orden OC-2026-0047', 32, '2026-08-14T10:00:00'),
        (122, N'IN', 3, 15, 122, NULL, NULL, NULL, 18, 71, N'Recepción de orden OC-2026-0048', 33, '2026-06-16T10:00:00'),
        (123, N'IN', 8, 59, 123, NULL, NULL, NULL, 18, 74, N'Recepción de orden OC-2026-0048', 33, '2026-06-16T10:00:00'),
        (124, N'IN', 10, 27, 124, NULL, NULL, NULL, 18, 74, N'Recepción de orden OC-2026-0048', 33, '2026-06-16T10:00:00'),
        (125, N'IN', 122, 43, 125, NULL, NULL, NULL, 18, 72, N'Recepción de orden OC-2026-0048', 33, '2026-06-16T10:00:00'),
        (126, N'IN', 80, 28, 126, NULL, NULL, NULL, 19, 78, N'Recepción de orden OC-2026-0049', 34, '2026-08-21T10:00:00'),
        (127, N'IN', 142, 49, 127, NULL, NULL, NULL, 19, 78, N'Recepción de orden OC-2026-0049', 34, '2026-08-21T10:00:00'),
        (128, N'IN', 79, 40, 128, NULL, NULL, NULL, 19, 78, N'Recepción de orden OC-2026-0049', 34, '2026-08-21T10:00:00'),
        (129, N'IN', 131, 40, 129, NULL, NULL, NULL, 20, 81, N'Recepción de orden OC-2026-0050', 35, '2026-07-08T10:00:00'),
        (130, N'IN', 111, 24, 130, NULL, NULL, NULL, 20, 82, N'Recepción de orden OC-2026-0050', 35, '2026-07-08T10:00:00'),
        (131, N'IN', 20, 58, 131, NULL, NULL, NULL, 20, 82, N'Recepción de orden OC-2026-0050', 35, '2026-07-08T10:00:00'),
        (132, N'IN', 155, 48, 132, NULL, NULL, NULL, 21, 84, N'Recepción de orden OC-2026-0051', 36, '2026-08-09T10:00:00'),
        (133, N'IN', 119, 17, 133, NULL, NULL, NULL, 21, 85, N'Recepción de orden OC-2026-0051', 36, '2026-08-09T10:00:00'),
        (134, N'IN', 154, 25, 134, NULL, NULL, NULL, 21, 86, N'Recepción de orden OC-2026-0051', 36, '2026-08-09T10:00:00'),
        (135, N'IN', 46, 50, 135, NULL, NULL, NULL, 21, 85, N'Recepción de orden OC-2026-0051', 36, '2026-08-09T10:00:00'),
        (136, N'IN', 113, 42, 136, NULL, NULL, NULL, 23, 92, N'Recepción de orden OC-2026-0053', 38, '2026-11-07T10:00:00'),
        (137, N'IN', 48, 58, 137, NULL, NULL, NULL, 23, 91, N'Recepción de orden OC-2026-0053', 38, '2026-11-07T10:00:00'),
        (138, N'IN', 131, 58, 138, NULL, NULL, NULL, 23, 93, N'Recepción de orden OC-2026-0053', 38, '2026-11-07T10:00:00'),
        (139, N'IN', 15, 11, 139, NULL, NULL, NULL, 24, 97, N'Recepción de orden OC-2026-0054', 39, '2026-09-02T10:00:00'),
        (140, N'IN', 99, 29, 140, NULL, NULL, NULL, 24, 95, N'Recepción de orden OC-2026-0054', 39, '2026-09-02T10:00:00'),
        (141, N'IN', 129, 18, 141, NULL, NULL, NULL, 24, 96, N'Recepción de orden OC-2026-0054', 39, '2026-09-02T10:00:00'),
        (142, N'IN', 47, 57, 142, NULL, NULL, NULL, 25, 99, N'Recepción de orden OC-2026-0055', 40, '2026-07-06T10:00:00'),
        (143, N'IN', 156, 13, 143, NULL, NULL, NULL, 25, 101, N'Recepción de orden OC-2026-0055', 40, '2026-07-06T10:00:00'),
        (144, N'IN', 87, 59, 144, NULL, NULL, NULL, 25, 101, N'Recepción de orden OC-2026-0055', 40, '2026-07-06T10:00:00'),
        (145, N'IN', 38, 37, 145, NULL, NULL, NULL, 27, 109, N'Recepción de orden OC-2026-0057', 42, '2026-06-14T10:00:00'),
        (146, N'IN', 39, 59, 146, NULL, NULL, NULL, 27, 107, N'Recepción de orden OC-2026-0057', 42, '2026-06-14T10:00:00'),
        (147, N'IN', 42, 41, 147, NULL, NULL, NULL, 27, 108, N'Recepción de orden OC-2026-0057', 42, '2026-06-14T10:00:00'),
        (148, N'IN', 130, 60, 148, NULL, NULL, NULL, 29, 115, N'Recepción de orden OC-2026-0059', 44, '2026-08-30T10:00:00'),
        (149, N'IN', 77, 53, 149, NULL, NULL, NULL, 29, 116, N'Recepción de orden OC-2026-0059', 44, '2026-08-30T10:00:00'),
        (150, N'IN', 123, 48, 150, NULL, NULL, NULL, 30, 122, N'Recepción de orden OC-2026-0060', 45, '2026-07-02T10:00:00'),
        (151, N'IN', 93, 14, 151, NULL, NULL, NULL, 30, 121, N'Recepción de orden OC-2026-0060', 45, '2026-07-02T10:00:00'),
        (152, N'IN', 102, 38, 152, NULL, NULL, NULL, 30, 122, N'Recepción de orden OC-2026-0060', 45, '2026-07-02T10:00:00'),
        (153, N'OUT', 80, 1, NULL, 1, 28, 113, NULL, NULL, N'Venta', 71, '2026-06-01T08:55:55'),
        (154, N'OUT', 127, 3, NULL, 6, 28, 113, NULL, NULL, N'Venta', 71, '2026-06-01T12:06:29'),
        (155, N'OUT', 140, 3, NULL, 13, 2, 9, NULL, NULL, N'Venta', NULL, '2026-06-01T15:55:28'),
        (156, N'OUT', 152, 3, NULL, 18, 15, 61, NULL, NULL, N'Venta', 58, '2026-06-04T09:19:05'),
        (157, N'OUT', 88, 1, NULL, 23, 14, 56, NULL, NULL, N'Venta', 57, '2026-06-04T11:20:16'),
        (158, N'OUT', 111, 2, NULL, 28, 14, 57, NULL, NULL, N'Venta', 57, '2026-06-04T14:48:46'),
        (159, N'OUT', 76, 1, NULL, 33, 15, 61, NULL, NULL, N'Venta', 58, '2026-06-04T15:18:10'),
        (160, N'OUT', 85, 3, NULL, 38, 2, 10, NULL, NULL, N'Venta', NULL, '2026-06-06T10:43:21'),
        (161, N'OUT', 123, 1, NULL, 43, 24, 97, NULL, NULL, N'Venta', 67, '2026-06-06T12:02:54'),
        (162, N'OUT', 99, 1, NULL, 48, 24, 95, NULL, NULL, N'Venta', 67, '2026-06-06T14:12:52'),
        (163, N'OUT', 161, 2, NULL, 53, 24, 95, NULL, NULL, N'Venta', 67, '2026-06-06T15:45:04'),
        (164, N'OUT', 136, 3, NULL, 58, 15, 61, NULL, NULL, N'Venta', 58, '2026-06-10T13:15:03'),
        (165, N'OUT', 76, 3, NULL, 63, 15, 61, NULL, NULL, N'Venta', 58, '2026-06-10T15:54:21'),
        (166, N'OUT', 109, 2, NULL, 68, 29, 117, NULL, NULL, N'Venta', 72, '2026-06-13T10:43:01'),
        (167, N'OUT', 76, 2, NULL, 73, 25, 99, NULL, NULL, N'Venta', 68, '2026-06-13T11:09:05'),
        (168, N'OUT', 77, 2, NULL, 78, 25, 99, NULL, NULL, N'Venta', 68, '2026-06-13T14:56:52'),
        (169, N'OUT', 68, 1, NULL, 83, 2, 10, NULL, NULL, N'Venta', NULL, '2026-06-15T14:00:04'),
        (170, N'OUT', 108, 2, NULL, 88, 21, 86, NULL, NULL, N'Venta', 64, '2026-06-16T11:10:40'),
        (171, N'OUT', 144, 3, NULL, 93, 9, 36, NULL, NULL, N'Venta', 52, '2026-06-18T13:49:31'),
        (172, N'OUT', 127, 2, NULL, 98, 9, 36, NULL, NULL, N'Venta', 52, '2026-06-18T15:28:39'),
        (173, N'OUT', 142, 2, NULL, 106, 25, 100, NULL, NULL, N'Venta', 68, '2026-06-21T09:38:12'),
        (174, N'OUT', 113, 1, NULL, 112, 23, 92, NULL, NULL, N'Venta', 66, '2026-06-23T09:46:55'),
        (175, N'OUT', 64, 2, NULL, 117, 23, 94, NULL, NULL, N'Venta', 66, '2026-06-23T11:24:05'),
        (176, N'OUT', 29, 3, NULL, 122, 18, 72, NULL, NULL, N'Venta', 61, '2026-06-23T11:57:12'),
        (177, N'OUT', 72, 2, NULL, 127, 18, 74, NULL, NULL, N'Venta', 61, '2026-06-23T11:57:31'),
        (178, N'OUT', 143, 2, NULL, 132, 18, 71, NULL, NULL, N'Venta', 61, '2026-06-23T13:39:23'),
        (179, N'OUT', 35, 3, NULL, 138, 18, 72, NULL, NULL, N'Venta', 61, '2026-06-23T14:54:38'),
        (180, N'OUT', 138, 3, NULL, 143, 13, 52, NULL, NULL, N'Venta', 56, '2026-06-26T08:53:30'),
        (181, N'OUT', 99, 1, NULL, 148, 13, 53, NULL, NULL, N'Venta', 56, '2026-06-26T13:50:26'),
        (182, N'OUT', 83, 2, NULL, 153, 2, 10, NULL, NULL, N'Venta', NULL, '2026-06-28T17:25:39'),
        (183, N'OUT', 102, 2, NULL, 158, 30, 122, NULL, NULL, N'Venta', 73, '2026-06-29T10:25:42'),
        (184, N'OUT', 99, 1, NULL, 163, 30, 119, NULL, NULL, N'Venta', 73, '2026-06-29T11:50:47'),
        (185, N'OUT', 30, 1, NULL, 168, 17, 67, NULL, NULL, N'Venta', 60, '2026-06-29T12:46:09'),
        (186, N'OUT', 140, 1, NULL, 173, 2, 9, NULL, NULL, N'Venta', NULL, '2026-07-01T03:01:05'),
        (187, N'OUT', 105, 1, NULL, 178, 6, 24, NULL, NULL, N'Venta', 49, '2026-07-02T12:04:47'),
        (188, N'OUT', 41, 3, NULL, 183, 6, 24, NULL, NULL, N'Venta', 49, '2026-07-02T15:39:57'),
        (189, N'OUT', 8, 2, NULL, 188, 2, 9, NULL, NULL, N'Venta', NULL, '2026-07-03T01:47:23'),
        (190, N'OUT', 155, 3, NULL, 193, 12, 48, NULL, NULL, N'Venta', 55, '2026-07-03T10:41:45'),
        (191, N'OUT', 73, 2, NULL, 198, 12, 48, NULL, NULL, N'Venta', 55, '2026-07-03T15:19:55'),
        (192, N'OUT', 107, 2, NULL, 203, 15, 60, NULL, NULL, N'Venta', 58, '2026-07-05T11:55:21'),
        (193, N'OUT', 83, 2, NULL, 208, 2, 10, NULL, NULL, N'Venta', NULL, '2026-07-05T23:31:27'),
        (194, N'OUT', 72, 3, NULL, 213, 18, 74, NULL, NULL, N'Venta', 61, '2026-07-10T09:49:11'),
        (195, N'OUT', 122, 1, NULL, 218, 18, 72, NULL, NULL, N'Venta', 61, '2026-07-10T15:56:30'),
        (196, N'OUT', 51, 2, NULL, 223, 5, 22, NULL, NULL, N'Venta', 48, '2026-07-11T10:38:26'),
        (197, N'OUT', 57, 3, NULL, 228, 22, 88, NULL, NULL, N'Venta', 65, '2026-07-13T10:14:03'),
        (198, N'OUT', 36, 1, NULL, 236, 27, 109, NULL, NULL, N'Venta', 70, '2026-07-17T08:38:36'),
        (199, N'OUT', 60, 3, NULL, 241, 27, 108, NULL, NULL, N'Venta', 70, '2026-07-17T12:20:13'),
        (200, N'OUT', 119, 1, NULL, 246, 7, 27, NULL, NULL, N'Venta', 50, '2026-07-18T15:33:57'),
        (201, N'OUT', 79, 2, NULL, 251, 2, 9, NULL, NULL, N'Venta', NULL, '2026-07-19T00:49:05'),
        (202, N'OUT', 60, 3, NULL, 256, 14, 58, NULL, NULL, N'Venta', 57, '2026-07-20T15:21:32'),
        (203, N'OUT', 46, 3, NULL, 261, 21, 85, NULL, NULL, N'Venta', 64, '2026-07-22T11:44:44'),
        (204, N'OUT', 90, 2, NULL, 266, 28, 113, NULL, NULL, N'Venta', 71, '2026-07-23T10:30:23'),
        (205, N'OUT', 99, 2, NULL, 271, 30, 119, NULL, NULL, N'Venta', 73, '2026-07-24T10:19:45'),
        (206, N'OUT', 38, 2, NULL, 276, 3, 14, NULL, NULL, N'Venta', 46, '2026-07-24T12:00:10'),
        (207, N'OUT', 123, 1, NULL, 281, 30, 122, NULL, NULL, N'Venta', 73, '2026-07-24T13:20:52'),
        (208, N'OUT', 77, 2, NULL, 291, 16, 63, NULL, NULL, N'Venta', 59, '2026-07-29T08:52:56'),
        (209, N'OUT', 84, 3, NULL, 296, 19, 77, NULL, NULL, N'Venta', 62, '2026-07-31T08:47:36'),
        (210, N'OUT', 46, 2, NULL, 301, 19, 78, NULL, NULL, N'Venta', 62, '2026-07-31T09:16:57'),
        (211, N'OUT', 124, 3, NULL, 306, 19, 77, NULL, NULL, N'Venta', 62, '2026-07-31T15:03:51'),
        (212, N'OUT', 1, 3, NULL, 311, 3, 13, NULL, NULL, N'Venta', 46, '2026-08-01T09:42:02'),
        (213, N'OUT', 25, 3, NULL, 316, 3, 12, NULL, NULL, N'Venta', 46, '2026-08-01T13:36:30'),
        (214, N'OUT', 19, 3, NULL, 321, 3, 13, NULL, NULL, N'Venta', 46, '2026-08-01T15:45:52'),
        (215, N'OUT', 55, 1, NULL, 329, 10, 42, NULL, NULL, N'Venta', 53, '2026-08-03T15:25:36'),
        (216, N'OUT', 116, 1, NULL, 334, 2, 9, NULL, NULL, N'Venta', NULL, '2026-08-07T21:18:55'),
        (217, N'OUT', 3, 3, NULL, 339, 24, 98, NULL, NULL, N'Venta', 67, '2026-08-11T15:28:42'),
        (218, N'OUT', 154, 3, NULL, 345, 11, 45, NULL, NULL, N'Venta', 54, '2026-08-16T14:49:25'),
        (219, N'OUT', 143, 1, NULL, 350, 11, 44, NULL, NULL, N'Venta', 54, '2026-08-16T15:37:53'),
        (220, N'OUT', 49, 3, NULL, 355, 13, 54, NULL, NULL, N'Venta', 56, '2026-08-17T09:04:23'),
        (221, N'OUT', 39, 1, NULL, 360, 13, 52, NULL, NULL, N'Venta', 56, '2026-08-17T14:52:40'),
        (222, N'OUT', 19, 2, NULL, 365, 3, 13, NULL, NULL, N'Venta', 46, '2026-08-18T09:56:51'),
        (223, N'OUT', 73, 3, NULL, 370, 3, 12, NULL, NULL, N'Venta', 46, '2026-08-18T14:04:48'),
        (224, N'OUT', 19, 1, NULL, 375, 3, 13, NULL, NULL, N'Venta', 46, '2026-08-18T15:16:26'),
        (225, N'OUT', 29, 3, NULL, 380, 2, 10, NULL, NULL, N'Venta', NULL, '2026-08-19T18:14:57'),
        (226, N'OUT', 131, 2, NULL, 385, 23, 93, NULL, NULL, N'Venta', 66, '2026-08-20T13:32:59'),
        (227, N'OUT', 81, 2, NULL, 390, 23, 92, NULL, NULL, N'Venta', 66, '2026-08-20T13:47:45'),
        (228, N'OUT', 50, 1, NULL, 395, 8, 33, NULL, NULL, N'Venta', 51, '2026-08-20T14:53:15'),
        (229, N'OUT', 142, 2, NULL, 400, 19, 78, NULL, NULL, N'Venta', 62, '2026-08-21T12:05:31'),
        (230, N'OUT', 54, 2, NULL, 407, 2, 9, NULL, NULL, N'Venta', NULL, '2026-08-23T15:33:29'),
        (231, N'OUT', 64, 2, NULL, 412, 29, 118, NULL, NULL, N'Venta', 72, '2026-08-24T11:47:49'),
        (232, N'OUT', 15, 2, NULL, 417, 29, 115, NULL, NULL, N'Venta', 72, '2026-08-24T12:39:59'),
        (233, N'OUT', 153, 3, NULL, 427, 20, 79, NULL, NULL, N'Venta', 63, '2026-08-26T10:53:31'),
        (234, N'OUT', 20, 1, NULL, 432, 20, 82, NULL, NULL, N'Venta', 63, '2026-08-26T12:07:30'),
        (235, N'OUT', 124, 1, NULL, 437, 2, 10, NULL, NULL, N'Venta', NULL, '2026-08-28T12:52:24'),
        (236, N'OUT', 116, 2, NULL, 444, 26, 106, NULL, NULL, N'Venta', 69, '2026-08-28T15:52:23'),
        (237, N'OUT', 96, 3, NULL, 449, 12, 48, NULL, NULL, N'Venta', 55, '2026-09-04T11:14:11'),
        (238, N'OUT', 62, 2, NULL, 454, 12, 48, NULL, NULL, N'Venta', 55, '2026-09-04T13:04:00'),
        (239, N'OUT', 52, 2, NULL, 459, 2, 9, NULL, NULL, N'Venta', NULL, '2026-09-07T04:47:01'),
        (240, N'OUT', 48, 2, NULL, 464, 22, 90, NULL, NULL, N'Venta', 65, '2026-09-07T09:15:38'),
        (241, N'OUT', 118, 3, NULL, 469, 11, 43, NULL, NULL, N'Venta', 54, '2026-09-07T09:52:15'),
        (242, N'OUT', 47, 3, NULL, 474, 22, 89, NULL, NULL, N'Venta', 65, '2026-09-07T11:14:07'),
        (243, N'OUT', 143, 3, NULL, 479, 11, 44, NULL, NULL, N'Venta', 54, '2026-09-07T13:11:25'),
        (244, N'OUT', 82, 2, NULL, 484, 11, 43, NULL, NULL, N'Venta', 54, '2026-09-07T14:56:43'),
        (245, N'OUT', 110, 2, NULL, 489, 26, 105, NULL, NULL, N'Venta', 69, '2026-09-08T12:22:17'),
        (246, N'OUT', 94, 2, NULL, 494, 11, 45, NULL, NULL, N'Venta', 54, '2026-09-09T12:50:25'),
        (247, N'OUT', 100, 3, NULL, 501, 17, 70, NULL, NULL, N'Venta', 60, '2026-09-12T08:43:48'),
        (248, N'OUT', 99, 1, NULL, 506, 13, 53, NULL, NULL, N'Venta', 56, '2026-09-15T13:45:39'),
        (249, N'OUT', 144, 1, NULL, 511, 2, 9, NULL, NULL, N'Venta', NULL, '2026-09-16T02:01:11'),
        (250, N'OUT', 59, 2, NULL, 518, 4, 17, NULL, NULL, N'Venta', 47, '2026-09-17T12:09:53'),
        (251, N'OUT', 130, 3, NULL, 523, 10, 41, NULL, NULL, N'Venta', 53, '2026-09-20T08:30:58'),
        (252, N'OUT', 139, 2, NULL, 528, 10, 41, NULL, NULL, N'Venta', 53, '2026-09-20T13:05:18'),
        (253, N'OUT', 57, 3, NULL, 533, 21, 84, NULL, NULL, N'Venta', 64, '2026-09-23T09:14:59'),
        (254, N'OUT', 55, 1, NULL, 538, 21, 86, NULL, NULL, N'Venta', 64, '2026-09-23T11:28:08'),
        (255, N'OUT', 122, 1, NULL, 549, 18, 72, NULL, NULL, N'Venta', 61, '2026-09-25T08:48:37'),
        (256, N'OUT', 142, 1, NULL, 554, 18, 72, NULL, NULL, N'Venta', 61, '2026-09-25T11:42:42'),
        (257, N'OUT', 52, 3, NULL, 559, 18, 71, NULL, NULL, N'Venta', 61, '2026-09-25T15:31:37'),
        (258, N'OUT', 122, 2, NULL, 564, 18, 72, NULL, NULL, N'Venta', 61, '2026-09-25T15:58:09'),
        (259, N'OUT', 28, 1, NULL, 569, 9, 38, NULL, NULL, N'Venta', 52, '2026-09-28T10:30:09'),
        (260, N'OUT', 4, 2, NULL, 579, 9, 36, NULL, NULL, N'Venta', 52, '2026-09-28T15:56:11'),
        (261, N'OUT', 58, 2, NULL, 584, 23, 92, NULL, NULL, N'Venta', 66, '2026-09-30T12:08:13'),
        (262, N'OUT', 159, 2, NULL, 589, 23, 94, NULL, NULL, N'Venta', 66, '2026-09-30T13:35:57'),
        (263, N'OUT', 63, 3, NULL, 594, 2, 9, NULL, NULL, N'Venta', NULL, '2026-10-01T01:36:42'),
        (264, N'OUT', 136, 1, NULL, 599, 14, 58, NULL, NULL, N'Venta', 57, '2026-10-03T12:18:16'),
        (265, N'OUT', 125, 1, NULL, 604, 6, 23, NULL, NULL, N'Venta', 49, '2026-10-04T12:46:59'),
        (266, N'OUT', 144, 2, NULL, 609, 6, 24, NULL, NULL, N'Venta', 49, '2026-10-04T13:01:02'),
        (267, N'OUT', 83, 1, NULL, 614, 2, 10, NULL, NULL, N'Venta', NULL, '2026-10-07T15:09:46'),
        (268, N'OUT', 83, 3, NULL, 619, 12, 50, NULL, NULL, N'Venta', 55, '2026-10-08T09:03:46'),
        (269, N'OUT', 62, 2, NULL, 624, 12, 48, NULL, NULL, N'Venta', 55, '2026-10-08T10:51:45'),
        (270, N'OUT', 67, 3, NULL, 629, 12, 50, NULL, NULL, N'Venta', 55, '2026-10-08T12:51:56'),
        (271, N'OUT', 81, 1, NULL, 634, 10, 41, NULL, NULL, N'Venta', 53, '2026-10-08T14:15:54'),
        (272, N'OUT', 156, 1, NULL, 641, 5, 22, NULL, NULL, N'Venta', 48, '2026-10-09T12:56:10'),
        (273, N'OUT', 90, 2, NULL, 646, 5, 21, NULL, NULL, N'Venta', 48, '2026-10-09T15:06:16'),
        (274, N'OUT', 42, 1, NULL, 651, 7, 30, NULL, NULL, N'Venta', 50, '2026-10-10T11:49:39'),
        (275, N'OUT', 1, 3, NULL, 657, 8, 33, NULL, NULL, N'Venta', 51, '2026-10-12T14:53:35'),
        (276, N'OUT', 12, 2, NULL, 662, 2, 10, NULL, NULL, N'Venta', NULL, '2026-10-16T20:51:00'),
        (277, N'OUT', 86, 2, NULL, 667, 4, 17, NULL, NULL, N'Venta', 47, '2026-10-18T10:19:17'),
        (278, N'OUT', 59, 1, NULL, 672, 4, 17, NULL, NULL, N'Venta', 47, '2026-10-18T13:39:50'),
        (279, N'OUT', 136, 1, NULL, 680, 16, 65, NULL, NULL, N'Venta', 59, '2026-10-21T12:21:31'),
        (280, N'OUT', 144, 1, NULL, 685, 16, 64, NULL, NULL, N'Venta', 59, '2026-10-21T14:44:10'),
        (281, N'OUT', 126, 2, NULL, 690, 2, 10, NULL, NULL, N'Venta', NULL, '2026-10-23T06:24:30'),
        (282, N'OUT', 46, 3, NULL, 695, 20, 82, NULL, NULL, N'Venta', 63, '2026-10-24T09:10:17'),
        (283, N'OUT', 125, 2, NULL, 700, 5, 22, NULL, NULL, N'Venta', 48, '2026-10-24T10:41:19'),
        (284, N'OUT', 6, 2, NULL, 705, 5, 19, NULL, NULL, N'Venta', 48, '2026-10-24T15:13:08'),
        (285, N'OUT', 112, 3, NULL, 710, 20, 80, NULL, NULL, N'Venta', 63, '2026-10-24T15:29:30'),
        (286, N'OUT', 62, 2, NULL, 718, 7, 29, NULL, NULL, N'Venta', 50, '2026-10-28T09:36:06'),
        (287, N'OUT', 80, 2, NULL, 724, 16, 63, NULL, NULL, N'Venta', 59, '2026-10-30T10:45:17'),
        (288, N'OUT', 32, 1, NULL, 729, 16, 63, NULL, NULL, N'Venta', 59, '2026-10-30T15:58:57'),
        (289, N'OUT', 77, 3, NULL, 734, 27, 109, NULL, NULL, N'Venta', 70, '2026-10-31T10:23:39'),
        (290, N'OUT', 38, 2, NULL, 739, 27, 109, NULL, NULL, N'Venta', 70, '2026-10-31T14:41:12'),
        (291, N'OUT', 71, 2, NULL, 744, 19, 75, NULL, NULL, N'Venta', 62, '2026-11-01T13:43:25'),
        (292, N'OUT', 84, 3, NULL, 749, 19, 77, NULL, NULL, N'Venta', 62, '2026-11-01T14:13:00'),
        (293, N'OUT', 40, 2, NULL, 756, 27, 107, NULL, NULL, N'Venta', 70, '2026-11-03T08:47:01'),
        (294, N'OUT', 59, 3, NULL, 761, 20, 82, NULL, NULL, N'Venta', 63, '2026-11-03T10:05:04'),
        (295, N'OUT', 51, 3, NULL, 766, 2, 10, NULL, NULL, N'Venta', NULL, '2026-11-03T10:15:02'),
        (296, N'OUT', 9, 1, NULL, 774, 20, 82, NULL, NULL, N'Venta', 63, '2026-11-03T12:18:15'),
        (297, N'OUT', 41, 3, NULL, 779, 2, 9, NULL, NULL, N'Venta', NULL, '2026-11-05T22:27:15'),
        (298, N'OUT', 93, 3, NULL, 784, 22, 87, NULL, NULL, N'Venta', 65, '2026-11-06T14:36:00'),
        (299, N'OUT', 154, 2, NULL, 789, 2, 9, NULL, NULL, N'Venta', NULL, '2026-11-07T01:42:07'),
        (300, N'OUT', 151, 1, NULL, 795, 26, 106, NULL, NULL, N'Venta', 69, '2026-11-12T10:02:05'),
        (301, N'OUT', 58, 3, NULL, 800, 26, 103, NULL, NULL, N'Venta', 69, '2026-11-12T14:33:33'),
        (302, N'OUT', 125, 3, NULL, 805, 2, 9, NULL, NULL, N'Venta', NULL, '2026-11-13T11:13:22'),
        (303, N'OUT', 124, 1, NULL, 810, 2, 10, NULL, NULL, N'Venta', NULL, '2026-11-14T00:39:38'),
        (304, N'OUT', 26, 1, NULL, 815, 8, 32, NULL, NULL, N'Venta', 51, '2026-11-14T09:01:38'),
        (305, N'OUT', 82, 1, NULL, 820, 25, 102, NULL, NULL, N'Venta', 68, '2026-11-14T11:59:30'),
        (306, N'OUT', 152, 3, NULL, 825, 8, 32, NULL, NULL, N'Venta', 51, '2026-11-14T15:22:56'),
        (307, N'OUT', 112, 3, NULL, 830, 2, 10, NULL, NULL, N'Venta', NULL, '2026-11-16T03:15:22'),
        (308, N'OUT', 22, 1, NULL, 835, 4, 18, NULL, NULL, N'Venta', 47, '2026-11-21T08:51:12'),
        (309, N'OUT', 128, 2, NULL, 842, 6, 25, NULL, NULL, N'Venta', 49, '2026-11-21T09:12:50'),
        (310, N'OUT', 77, 3, NULL, 847, 7, 27, NULL, NULL, N'Venta', 50, '2026-11-21T09:56:42'),
        (311, N'OUT', 1, 1, NULL, 852, 3, 13, NULL, NULL, N'Venta', 46, '2026-11-21T10:26:17'),
        (312, N'OUT', 125, 1, NULL, 857, 6, 23, NULL, NULL, N'Venta', 49, '2026-11-21T10:49:53'),
        (313, N'OUT', 12, 2, NULL, 862, 5, 20, NULL, NULL, N'Venta', 48, '2026-11-21T11:04:39'),
        (314, N'OUT', 125, 2, NULL, 870, 5, 22, NULL, NULL, N'Venta', 48, '2026-11-21T11:34:58'),
        (315, N'OUT', 87, 1, NULL, 875, 7, 28, NULL, NULL, N'Venta', 50, '2026-11-21T11:59:12'),
        (316, N'TRANSFER', 12, 9, NULL, NULL, 5, 20, 5, 22, N'Traslado de bodega a piso de venta', 20, '2026-10-08T13:25:19'),
        (317, N'TRANSFER', 96, 7, NULL, NULL, 8, 34, 8, 32, N'Traslado de bodega a piso de venta', 23, '2026-08-03T04:11:06'),
        (318, N'TRANSFER', 30, 6, NULL, NULL, 30, 121, 30, 119, N'Traslado de bodega a piso de venta', 45, '2026-06-04T01:28:49'),
        (319, N'TRANSFER', 105, 4, NULL, NULL, 14, 58, 14, 55, N'Traslado de bodega a piso de venta', 29, '2026-10-17T12:26:05'),
        (320, N'TRANSFER', 116, 7, NULL, NULL, 26, 106, 26, 103, N'Traslado de bodega a piso de venta', 41, '2026-10-06T06:25:15'),
        (321, N'TRANSFER', 129, 6, NULL, NULL, 23, 93, 23, 94, N'Traslado de bodega a piso de venta', 38, '2026-07-30T22:20:09'),
        (322, N'TRANSFER', 61, 10, NULL, NULL, 5, 22, 5, 21, N'Traslado de bodega a piso de venta', 20, '2026-09-24T15:46:27'),
        (323, N'TRANSFER', 89, 8, NULL, NULL, 25, 101, 25, 99, N'Traslado de bodega a piso de venta', 40, '2026-09-04T05:54:40'),
        (324, N'TRANSFER', 91, 5, NULL, NULL, 7, 27, 7, 29, N'Traslado de bodega a piso de venta', 22, '2026-06-30T20:47:26'),
        (325, N'TRANSFER', 3, 8, NULL, NULL, 17, 67, 17, 69, N'Traslado de bodega a piso de venta', 32, '2026-10-26T00:41:01'),
        (326, N'TRANSFER', 56, 3, NULL, NULL, 8, 33, 8, 31, N'Traslado de bodega a piso de venta', 23, '2026-11-20T05:29:37'),
        (327, N'TRANSFER', 102, 2, NULL, NULL, 26, 106, 26, 105, N'Traslado de bodega a piso de venta', 41, '2026-07-08T16:34:09'),
        (328, N'TRANSFER', 80, 4, NULL, NULL, 16, 63, 16, 64, N'Traslado de bodega a piso de venta', 31, '2026-10-02T13:07:16'),
        (329, N'TRANSFER', 10, 4, NULL, NULL, 23, 92, 23, 94, N'Traslado de bodega a piso de venta', 38, '2026-09-18T03:25:56'),
        (330, N'TRANSFER', 26, 3, NULL, NULL, 8, 32, 8, 33, N'Traslado de bodega a piso de venta', 23, '2026-09-11T01:28:53'),
        (331, N'TRANSFER', 19, 8, NULL, NULL, 29, 116, 29, 117, N'Traslado de bodega a piso de venta', 44, '2026-06-09T11:50:56'),
        (332, N'TRANSFER', 99, 2, NULL, NULL, 15, 62, 15, 61, N'Traslado de bodega a piso de venta', 30, '2026-10-14T06:56:30'),
        (333, N'TRANSFER', 6, 7, NULL, NULL, 9, 35, 9, 36, N'Traslado de bodega a piso de venta', 24, '2026-08-08T01:29:05'),
        (334, N'TRANSFER', 108, 10, NULL, NULL, 8, 33, 8, 32, N'Traslado de bodega a piso de venta', 23, '2026-09-23T01:32:11'),
        (335, N'TRANSFER', 155, 8, NULL, NULL, 16, 64, 16, 65, N'Traslado de bodega a piso de venta', 31, '2026-06-08T01:55:21'),
        (336, N'ADJUST', 102, 2, NULL, NULL, 30, 122, NULL, NULL, N'Pérdida detectada en inventario', 45, '2026-09-17T21:59:25'),
        (337, N'ADJUST', 123, 2, NULL, NULL, 30, 122, NULL, NULL, N'Prenda manchada', 45, '2026-10-26T01:07:44'),
        (338, N'ADJUST', 59, 2, NULL, NULL, 4, 17, NULL, NULL, N'Prenda manchada', 19, '2026-09-30T22:41:56'),
        (339, N'ADJUST', 67, 1, NULL, NULL, 29, 118, NULL, NULL, N'Prenda manchada', 44, '2026-06-07T00:12:35'),
        (340, N'ADJUST', 56, 4, NULL, NULL, 19, 77, NULL, NULL, N'Pérdida detectada en inventario', 34, '2026-06-28T20:14:07'),
        (341, N'ADJUST', 133, 1, NULL, NULL, 15, 60, NULL, NULL, N'Merma por daño', 30, '2026-10-19T01:28:41'),
        (342, N'ADJUST', 114, 4, NULL, NULL, 8, 33, NULL, NULL, N'Merma por daño', 23, '2026-07-11T20:07:03'),
        (343, N'ADJUST', 107, 1, NULL, NULL, 15, 60, NULL, NULL, N'Prenda manchada', 30, '2026-11-12T02:58:09'),
        (344, N'ADJUST', 113, 3, NULL, NULL, 7, 30, NULL, NULL, N'Prenda manchada', 22, '2026-06-15T22:17:43'),
        (345, N'ADJUST', 73, 4, NULL, NULL, 12, 48, NULL, NULL, N'Merma por daño', 27, '2026-08-25T08:01:53'),
        (346, N'ADJUST', 32, 4, NULL, NULL, 25, 99, NULL, NULL, N'Prenda manchada', 40, '2026-11-01T21:19:22'),
        (347, N'ADJUST', 12, 4, NULL, NULL, 30, 121, NULL, NULL, N'Pérdida detectada en inventario', 45, '2026-08-12T18:45:16'),
        (348, N'ADJUST', 42, 2, NULL, NULL, 27, 108, NULL, NULL, N'Pérdida detectada en inventario', 42, '2026-08-02T18:45:07'),
        (349, N'ADJUST', 10, 2, NULL, NULL, 29, 115, NULL, NULL, N'Merma por daño', 44, '2026-07-10T08:38:48'),
        (350, N'ADJUST', 80, 1, NULL, NULL, 16, 63, NULL, NULL, N'Merma por daño', 31, '2026-09-16T01:31:55');
    SET IDENTITY_INSERT dbo.StockMovement OFF;
END
GO

-- Gestión de tienda virtual
IF NOT EXISTS (SELECT 1 FROM dbo.Cart)
BEGIN
    SET IDENTITY_INSERT dbo.Cart ON;
    INSERT INTO dbo.Cart (Id, User_Id, Status, Bill_Id, RegistrationDate) VALUES
        (1, 1, N'CONVERTED', 7, '2026-06-01T14:55:28'),
        (2, 28, N'CONVERTED', 8, '2026-06-02T19:28:30'),
        (3, 9, N'CONVERTED', 9, '2026-06-02T20:52:24'),
        (4, 14, N'CONVERTED', 19, '2026-06-06T09:43:21'),
        (5, 16, N'CONVERTED', 41, '2026-06-15T13:00:04'),
        (6, 21, N'CONVERTED', 48, '2026-06-18T23:49:50'),
        (7, 8, N'CONVERTED', 49, '2026-06-19T17:02:10'),
        (8, 5, N'CONVERTED', 66, '2026-06-24T19:48:35'),
        (9, 25, N'CONVERTED', 71, '2026-06-28T16:25:39'),
        (10, 10, N'CONVERTED', 81, '2026-07-01T02:01:05'),
        (11, 1, N'CONVERTED', 87, '2026-07-03T00:47:23'),
        (12, 12, N'CONVERTED', 88, '2026-07-03T09:07:55'),
        (13, 28, N'CONVERTED', 98, '2026-07-05T22:05:35'),
        (14, 24, N'CONVERTED', 99, '2026-07-05T22:31:27'),
        (15, 23, N'CONVERTED', 102, '2026-07-09T11:08:22'),
        (16, 1, N'CONVERTED', 111, '2026-07-14T02:19:56'),
        (17, 32, N'CONVERTED', 112, '2026-07-15T11:43:06'),
        (18, 33, N'CONVERTED', 120, '2026-07-18T23:49:05'),
        (19, 7, N'CONVERTED', 121, '2026-07-20T07:38:40'),
        (20, 6, N'CONVERTED', 131, '2026-07-23T22:41:17'),
        (21, 21, N'CONVERTED', 139, '2026-07-27T13:35:34'),
        (22, 17, N'CONVERTED', 142, '2026-07-30T02:49:23'),
        (23, 17, N'CONVERTED', 162, '2026-08-07T09:36:36'),
        (24, 21, N'CONVERTED', 163, '2026-08-07T20:18:55'),
        (25, 8, N'CONVERTED', 164, '2026-08-09T01:35:08'),
        (26, 2, N'CONVERTED', 178, '2026-08-17T19:32:31'),
        (27, 30, N'CONVERTED', 185, '2026-08-18T22:12:30'),
        (28, 5, N'CONVERTED', 186, '2026-08-19T01:45:19'),
        (29, 5, N'CONVERTED', 187, '2026-08-19T17:14:57'),
        (30, 34, N'CONVERTED', 197, '2026-08-21T23:57:41'),
        (31, 26, N'CONVERTED', 198, '2026-08-23T12:49:49'),
        (32, 35, N'CONVERTED', 199, '2026-08-23T14:33:29'),
        (33, 23, N'CONVERTED', 206, '2026-08-25T07:54:06'),
        (34, 24, N'CONVERTED', 207, '2026-08-26T07:54:42'),
        (35, 26, N'CONVERTED', 212, '2026-08-27T19:26:51'),
        (36, 21, N'CONVERTED', 213, '2026-08-28T11:52:24'),
        (37, 5, N'CONVERTED', 217, '2026-09-02T20:37:02'),
        (38, 23, N'CONVERTED', 222, '2026-09-06T22:05:05'),
        (39, 20, N'CONVERTED', 223, '2026-09-07T03:47:01'),
        (40, 33, N'CONVERTED', 234, '2026-09-08T05:22:24'),
        (41, 14, N'CONVERTED', 241, '2026-09-12T02:28:49'),
        (42, 5, N'CONVERTED', 244, '2026-09-12T12:55:46'),
        (43, 19, N'CONVERTED', 248, '2026-09-16T01:01:11'),
        (44, 28, N'CONVERTED', 264, '2026-09-23T18:56:49'),
        (45, 10, N'CONVERTED', 265, '2026-09-24T14:06:16'),
        (46, 15, N'CONVERTED', 274, '2026-09-25T19:15:04'),
        (47, 27, N'CONVERTED', 275, '2026-09-28T06:35:10'),
        (48, 21, N'CONVERTED', 290, '2026-10-01T00:36:42'),
        (49, 2, N'CONVERTED', 298, '2026-10-06T02:55:42'),
        (50, 27, N'CONVERTED', 299, '2026-10-07T14:09:46'),
        (51, 24, N'CONVERTED', 313, '2026-10-09T13:13:51'),
        (52, 1, N'CONVERTED', 325, '2026-10-16T19:51:00'),
        (53, 29, N'CONVERTED', 328, '2026-10-18T11:08:17'),
        (54, 18, N'CONVERTED', 330, '2026-10-20T02:50:28'),
        (55, 29, N'CONVERTED', 337, '2026-10-23T05:24:30'),
        (56, 31, N'CONVERTED', 349, '2026-10-24T17:26:25'),
        (57, 10, N'CONVERTED', 350, '2026-10-25T22:42:25'),
        (58, 24, N'CONVERTED', 351, '2026-10-27T10:15:26'),
        (59, 1, N'CONVERTED', 352, '2026-10-27T18:16:02'),
        (60, 8, N'CONVERTED', 362, '2026-10-31T09:34:53'),
        (61, 27, N'CONVERTED', 375, '2026-11-03T09:15:02'),
        (62, 29, N'CONVERTED', 383, '2026-11-04T08:35:59'),
        (63, 3, N'CONVERTED', 384, '2026-11-05T21:27:15'),
        (64, 16, N'CONVERTED', 389, '2026-11-07T00:42:07'),
        (65, 4, N'CONVERTED', 390, '2026-11-09T15:50:47'),
        (66, 16, N'CONVERTED', 397, '2026-11-13T10:13:22'),
        (67, 7, N'CONVERTED', 398, '2026-11-13T17:30:10'),
        (68, 30, N'CONVERTED', 399, '2026-11-13T23:39:38'),
        (69, 9, N'CONVERTED', 410, '2026-11-16T00:02:23'),
        (70, 16, N'CONVERTED', 411, '2026-11-16T02:15:22'),
        (71, 1, N'ACTIVE', NULL, '2026-11-07T04:18:39'),
        (72, 2, N'ACTIVE', NULL, '2026-11-02T05:14:22'),
        (73, 3, N'ACTIVE', NULL, '2026-11-21T17:31:51'),
        (74, 4, N'ABANDONED', NULL, '2026-11-04T22:37:19'),
        (75, 5, N'ABANDONED', NULL, '2026-11-10T01:49:13'),
        (76, 6, N'ABANDONED', NULL, '2026-11-07T08:48:38');
    SET IDENTITY_INSERT dbo.Cart OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.CartDetail)
BEGIN
    SET IDENTITY_INSERT dbo.CartDetail ON;
    INSERT INTO dbo.CartDetail (Id, Cart_Id, ClotheVariant_Id, Quantity, AddedDate) VALUES
        (1, 1, 155, 1, '2026-06-01T14:55:28'),
        (2, 1, 140, 3, '2026-06-01T14:55:28'),
        (3, 2, 70, 2, '2026-06-02T19:28:30'),
        (4, 2, 86, 1, '2026-06-02T19:28:30'),
        (5, 3, 97, 1, '2026-06-02T20:52:24'),
        (6, 3, 52, 1, '2026-06-02T20:52:24'),
        (7, 4, 85, 3, '2026-06-06T09:43:21'),
        (8, 5, 125, 1, '2026-06-15T13:00:04'),
        (9, 5, 68, 1, '2026-06-15T13:00:04'),
        (10, 6, 98, 2, '2026-06-18T23:49:50'),
        (11, 7, 54, 1, '2026-06-19T17:02:10'),
        (12, 7, 116, 1, '2026-06-19T17:02:10'),
        (13, 7, 30, 2, '2026-06-19T17:02:10'),
        (14, 8, 66, 3, '2026-06-24T19:48:35'),
        (15, 9, 98, 3, '2026-06-28T16:25:39'),
        (16, 9, 101, 2, '2026-06-28T16:25:39'),
        (17, 9, 83, 2, '2026-06-28T16:25:39'),
        (18, 10, 140, 1, '2026-07-01T02:01:05'),
        (19, 10, 63, 1, '2026-07-01T02:01:05'),
        (20, 10, 101, 2, '2026-07-01T02:01:05'),
        (21, 11, 136, 3, '2026-07-03T00:47:23'),
        (22, 11, 63, 2, '2026-07-03T00:47:23'),
        (23, 11, 8, 2, '2026-07-03T00:47:23'),
        (24, 12, 125, 1, '2026-07-03T09:07:55'),
        (25, 12, 147, 1, '2026-07-03T09:07:55'),
        (26, 12, 159, 3, '2026-07-03T09:07:55'),
        (27, 13, 70, 3, '2026-07-05T22:05:35'),
        (28, 14, 83, 2, '2026-07-05T22:31:27'),
        (29, 15, 76, 2, '2026-07-09T11:08:22'),
        (30, 16, 96, 1, '2026-07-14T02:19:56'),
        (31, 16, 8, 3, '2026-07-14T02:19:56'),
        (32, 16, 52, 2, '2026-07-14T02:19:56'),
        (33, 17, 42, 3, '2026-07-15T11:43:06'),
        (34, 18, 79, 2, '2026-07-18T23:49:05'),
        (35, 19, 140, 3, '2026-07-20T07:38:40'),
        (36, 19, 155, 3, '2026-07-20T07:38:40'),
        (37, 20, 86, 2, '2026-07-23T22:41:17'),
        (38, 20, 13, 2, '2026-07-23T22:41:17'),
        (39, 21, 76, 3, '2026-07-27T13:35:34'),
        (40, 21, 156, 1, '2026-07-27T13:35:34'),
        (41, 22, 42, 2, '2026-07-30T02:49:23'),
        (42, 23, 3, 2, '2026-08-07T09:36:36'),
        (43, 24, 41, 3, '2026-08-07T20:18:55'),
        (44, 24, 116, 1, '2026-08-07T20:18:55'),
        (45, 25, 48, 2, '2026-08-09T01:35:08'),
        (46, 25, 126, 1, '2026-08-09T01:35:08'),
        (47, 25, 136, 1, '2026-08-09T01:35:08'),
        (48, 26, 3, 3, '2026-08-17T19:32:31'),
        (49, 27, 97, 1, '2026-08-18T22:12:30'),
        (50, 28, 154, 1, '2026-08-19T01:45:19'),
        (51, 29, 86, 3, '2026-08-19T17:14:57'),
        (52, 29, 29, 3, '2026-08-19T17:14:57'),
        (53, 29, 112, 1, '2026-08-19T17:14:57'),
        (54, 30, 4, 2, '2026-08-21T23:57:41'),
        (55, 30, 120, 3, '2026-08-21T23:57:41'),
        (56, 31, 159, 3, '2026-08-23T12:49:49'),
        (57, 31, 7, 3, '2026-08-23T12:49:49'),
        (58, 31, 155, 1, '2026-08-23T12:49:49'),
        (59, 32, 54, 2, '2026-08-23T14:33:29'),
        (60, 32, 70, 3, '2026-08-23T14:33:29'),
        (61, 33, 42, 1, '2026-08-25T07:54:06'),
        (62, 33, 8, 3, '2026-08-25T07:54:06'),
        (63, 33, 66, 2, '2026-08-25T07:54:06'),
        (64, 34, 140, 1, '2026-08-26T07:54:42'),
        (65, 35, 120, 2, '2026-08-27T19:26:51'),
        (66, 36, 124, 1, '2026-08-28T11:52:24'),
        (67, 36, 147, 3, '2026-08-28T11:52:24'),
        (68, 37, 154, 3, '2026-09-02T20:37:02'),
        (69, 37, 120, 2, '2026-09-02T20:37:02'),
        (70, 38, 96, 2, '2026-09-06T22:05:05'),
        (71, 38, 115, 3, '2026-09-06T22:05:05'),
        (72, 38, 54, 1, '2026-09-06T22:05:05'),
        (73, 39, 52, 2, '2026-09-07T03:47:01'),
        (74, 39, 126, 1, '2026-09-07T03:47:01'),
        (75, 39, 63, 1, '2026-09-07T03:47:01'),
        (76, 40, 55, 1, '2026-09-08T05:22:24'),
        (77, 41, 13, 1, '2026-09-12T02:28:49'),
        (78, 41, 136, 1, '2026-09-12T02:28:49'),
        (79, 42, 126, 1, '2026-09-12T12:55:46'),
        (80, 43, 10, 3, '2026-09-16T01:01:11'),
        (81, 43, 144, 1, '2026-09-16T01:01:11'),
        (82, 43, 52, 2, '2026-09-16T01:01:11'),
        (83, 44, 7, 1, '2026-09-23T18:56:49'),
        (84, 44, 52, 1, '2026-09-23T18:56:49'),
        (85, 44, 63, 1, '2026-09-23T18:56:49'),
        (86, 45, 77, 1, '2026-09-24T14:06:16'),
        (87, 45, 145, 3, '2026-09-24T14:06:16'),
        (88, 45, 96, 3, '2026-09-24T14:06:16'),
        (89, 46, 54, 2, '2026-09-25T19:15:04'),
        (90, 47, 59, 2, '2026-09-28T06:35:10'),
        (91, 47, 84, 3, '2026-09-28T06:35:10'),
        (92, 48, 63, 3, '2026-10-01T00:36:42'),
        (93, 48, 38, 2, '2026-10-01T00:36:42'),
        (94, 49, 145, 2, '2026-10-06T02:55:42'),
        (95, 50, 83, 1, '2026-10-07T14:09:46'),
        (96, 50, 125, 1, '2026-10-07T14:09:46'),
        (97, 51, 147, 3, '2026-10-09T13:13:51'),
        (98, 51, 77, 2, '2026-10-09T13:13:51'),
        (99, 51, 52, 1, '2026-10-09T13:13:51'),
        (100, 52, 12, 2, '2026-10-16T19:51:00'),
        (101, 52, 155, 3, '2026-10-16T19:51:00'),
        (102, 53, 17, 2, '2026-10-18T11:08:17'),
        (103, 54, 120, 1, '2026-10-20T02:50:28'),
        (104, 54, 29, 1, '2026-10-20T02:50:28'),
        (105, 54, 86, 1, '2026-10-20T02:50:28'),
        (106, 55, 48, 3, '2026-10-23T05:24:30'),
        (107, 55, 126, 2, '2026-10-23T05:24:30'),
        (108, 56, 13, 3, '2026-10-24T17:26:25'),
        (109, 57, 155, 1, '2026-10-25T22:42:25'),
        (110, 57, 101, 1, '2026-10-25T22:42:25'),
        (111, 57, 97, 1, '2026-10-25T22:42:25'),
        (112, 58, 63, 1, '2026-10-27T10:15:26'),
        (113, 58, 13, 2, '2026-10-27T10:15:26'),
        (114, 59, 76, 1, '2026-10-27T18:16:02'),
        (115, 60, 53, 2, '2026-10-31T09:34:53'),
        (116, 60, 3, 2, '2026-10-31T09:34:53'),
        (117, 61, 113, 3, '2026-11-03T09:15:02'),
        (118, 61, 85, 1, '2026-11-03T09:15:02'),
        (119, 61, 51, 3, '2026-11-03T09:15:02'),
        (120, 62, 79, 3, '2026-11-04T08:35:59'),
        (121, 63, 41, 3, '2026-11-05T21:27:15'),
        (122, 63, 115, 2, '2026-11-05T21:27:15'),
        (123, 63, 69, 1, '2026-11-05T21:27:15'),
        (124, 64, 154, 2, '2026-11-07T00:42:07'),
        (125, 64, 108, 2, '2026-11-07T00:42:07'),
        (126, 64, 42, 3, '2026-11-07T00:42:07'),
        (127, 65, 130, 2, '2026-11-09T15:50:47'),
        (128, 66, 125, 3, '2026-11-13T10:13:22'),
        (129, 66, 3, 3, '2026-11-13T10:13:22'),
        (130, 67, 156, 1, '2026-11-13T17:30:10'),
        (131, 68, 86, 3, '2026-11-13T23:39:38'),
        (132, 68, 98, 3, '2026-11-13T23:39:38'),
        (133, 68, 124, 1, '2026-11-13T23:39:38'),
        (134, 69, 143, 3, '2026-11-16T00:02:23'),
        (135, 69, 51, 3, '2026-11-16T00:02:23'),
        (136, 69, 4, 2, '2026-11-16T00:02:23'),
        (137, 70, 112, 3, '2026-11-16T02:15:22'),
        (138, 70, 154, 1, '2026-11-16T02:15:22'),
        (139, 70, 83, 1, '2026-11-16T02:15:22'),
        (140, 71, 79, 2, '2026-11-10T13:19:28'),
        (141, 71, 83, 2, '2026-11-19T02:41:29'),
        (142, 72, 52, 2, '2026-11-05T22:43:19'),
        (143, 72, 46, 1, '2026-11-14T21:19:02'),
        (144, 73, 46, 2, '2026-11-04T00:55:29'),
        (145, 73, 143, 1, '2026-11-14T12:25:07'),
        (146, 74, 101, 2, '2026-11-15T23:35:32'),
        (147, 74, 76, 2, '2026-11-18T02:23:12'),
        (148, 75, 92, 1, '2026-11-07T16:55:03'),
        (149, 75, 147, 2, '2026-11-14T22:02:04'),
        (150, 76, 156, 1, '2026-11-02T16:39:51'),
        (151, 76, 63, 2, '2026-11-11T05:41:46');
    SET IDENTITY_INSERT dbo.CartDetail OFF;
END
GO

-- Gestión de gastos
IF NOT EXISTS (SELECT 1 FROM dbo.ExpenseCategory)
BEGIN
    SET IDENTITY_INSERT dbo.ExpenseCategory ON;
    INSERT INTO dbo.ExpenseCategory (Id, Name, Description) VALUES
        (1, N'Energía eléctrica', N'Gastos de energía eléctrica'),
        (2, N'Agua', N'Gastos de agua'),
        (3, N'Alquiler', N'Gastos de alquiler'),
        (4, N'Internet y teléfono', N'Gastos de internet y teléfono'),
        (5, N'Papelería y suministros', N'Gastos de papelería y suministros'),
        (6, N'Mantenimiento', N'Gastos de mantenimiento'),
        (7, N'Publicidad', N'Gastos de publicidad'),
        (8, N'Seguridad', N'Gastos de seguridad'),
        (9, N'Limpieza', N'Gastos de limpieza'),
        (10, N'Transporte', N'Gastos de transporte'),
        (11, N'Seguros', N'Gastos de seguros'),
        (12, N'Impuestos municipales', N'Gastos de impuestos municipales'),
        (13, N'Capacitación', N'Gastos de capacitación'),
        (14, N'Material de empaque', N'Gastos de material de empaque'),
        (15, N'Otros', N'Gastos de otros');
    SET IDENTITY_INSERT dbo.ExpenseCategory OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Expense)
BEGIN
    SET IDENTITY_INSERT dbo.Expense ON;
    INSERT INTO dbo.Expense (Id, Store_Id, ExpenseCategory_Id, Amount, ExpenseDate, Description, Employee_Id, RegistrationDate) VALUES
        (1, 1, 3, 22000.00, '2026-08-21', N'Alquiler de Bodega Central', 74, '2026-08-28T09:00:00'),
        (2, 1, 7, 2256.00, '2026-08-08', N'Publicidad de Bodega Central', 74, '2026-08-28T09:00:00'),
        (3, 1, 3, 22000.00, '2026-09-27', N'Alquiler de Bodega Central', 74, '2026-09-28T09:00:00'),
        (4, 1, 1, 2460.00, '2026-09-20', N'Energía eléctrica de Bodega Central', 74, '2026-09-28T09:00:00'),
        (5, 1, 3, 25000.00, '2026-10-17', N'Alquiler de Bodega Central', 74, '2026-10-28T09:00:00'),
        (6, 1, 6, 6428.00, '2026-10-21', N'Mantenimiento de Bodega Central', 74, '2026-10-28T09:00:00'),
        (7, 2, 3, 22000.00, '2026-08-06', N'Alquiler de Tienda Virtual', 74, '2026-08-28T09:00:00'),
        (8, 2, 2, 5485.00, '2026-08-24', N'Agua de Tienda Virtual', 74, '2026-08-28T09:00:00'),
        (9, 2, 3, 22000.00, '2026-09-06', N'Alquiler de Tienda Virtual', 74, '2026-09-28T09:00:00'),
        (10, 2, 15, 1041.00, '2026-09-07', N'Otros de Tienda Virtual', 74, '2026-09-28T09:00:00'),
        (11, 2, 3, 22000.00, '2026-10-23', N'Alquiler de Tienda Virtual', 74, '2026-10-28T09:00:00'),
        (12, 2, 15, 3183.00, '2026-10-26', N'Otros de Tienda Virtual', 74, '2026-10-28T09:00:00'),
        (13, 3, 3, 22000.00, '2026-08-03', N'Alquiler de Pedestal Tegucigalpa Centro', 18, '2026-08-28T09:00:00'),
        (14, 3, 9, 3762.00, '2026-08-13', N'Limpieza de Pedestal Tegucigalpa Centro', 18, '2026-08-28T09:00:00'),
        (15, 3, 3, 22000.00, '2026-09-24', N'Alquiler de Pedestal Tegucigalpa Centro', 18, '2026-09-28T09:00:00'),
        (16, 3, 9, 3425.00, '2026-09-02', N'Limpieza de Pedestal Tegucigalpa Centro', 18, '2026-09-28T09:00:00'),
        (17, 3, 3, 25000.00, '2026-10-05', N'Alquiler de Pedestal Tegucigalpa Centro', 18, '2026-10-28T09:00:00'),
        (18, 3, 15, 3902.00, '2026-10-07', N'Otros de Pedestal Tegucigalpa Centro', 18, '2026-10-28T09:00:00'),
        (19, 4, 3, 30000.00, '2026-08-27', N'Alquiler de Pedestal Tegucigalpa Palmira', 19, '2026-08-28T09:00:00'),
        (20, 4, 5, 5444.00, '2026-08-01', N'Papelería y suministros de Pedestal Tegucigalpa Palmira', 19, '2026-08-28T09:00:00'),
        (21, 4, 3, 18000.00, '2026-09-09', N'Alquiler de Pedestal Tegucigalpa Palmira', 19, '2026-09-28T09:00:00'),
        (22, 4, 5, 1742.00, '2026-09-26', N'Papelería y suministros de Pedestal Tegucigalpa Palmira', 19, '2026-09-28T09:00:00'),
        (23, 4, 3, 22000.00, '2026-10-02', N'Alquiler de Pedestal Tegucigalpa Palmira', 19, '2026-10-28T09:00:00'),
        (24, 4, 2, 2221.00, '2026-10-05', N'Agua de Pedestal Tegucigalpa Palmira', 19, '2026-10-28T09:00:00'),
        (25, 5, 3, 25000.00, '2026-08-16', N'Alquiler de Pedestal Tegucigalpa Kennedy', 20, '2026-08-28T09:00:00'),
        (26, 5, 2, 4442.00, '2026-08-15', N'Agua de Pedestal Tegucigalpa Kennedy', 20, '2026-08-28T09:00:00'),
        (27, 5, 3, 25000.00, '2026-09-15', N'Alquiler de Pedestal Tegucigalpa Kennedy', 20, '2026-09-28T09:00:00'),
        (28, 5, 1, 5264.00, '2026-09-16', N'Energía eléctrica de Pedestal Tegucigalpa Kennedy', 20, '2026-09-28T09:00:00'),
        (29, 5, 3, 30000.00, '2026-10-16', N'Alquiler de Pedestal Tegucigalpa Kennedy', 20, '2026-10-28T09:00:00'),
        (30, 5, 7, 2677.00, '2026-10-16', N'Publicidad de Pedestal Tegucigalpa Kennedy', 20, '2026-10-28T09:00:00'),
        (31, 6, 3, 18000.00, '2026-08-14', N'Alquiler de Pedestal Tegucigalpa El Trapiche', 21, '2026-08-28T09:00:00'),
        (32, 6, 9, 6112.00, '2026-08-21', N'Limpieza de Pedestal Tegucigalpa El Trapiche', 21, '2026-08-28T09:00:00'),
        (33, 6, 3, 30000.00, '2026-09-05', N'Alquiler de Pedestal Tegucigalpa El Trapiche', 21, '2026-09-28T09:00:00'),
        (34, 6, 4, 2095.00, '2026-09-19', N'Internet y teléfono de Pedestal Tegucigalpa El Trapiche', 21, '2026-09-28T09:00:00'),
        (35, 6, 3, 25000.00, '2026-10-05', N'Alquiler de Pedestal Tegucigalpa El Trapiche', 21, '2026-10-28T09:00:00'),
        (36, 6, 8, 3371.00, '2026-10-18', N'Seguridad de Pedestal Tegucigalpa El Trapiche', 21, '2026-10-28T09:00:00'),
        (37, 7, 3, 22000.00, '2026-08-19', N'Alquiler de Pedestal San Pedro Sula Centro', 22, '2026-08-28T09:00:00'),
        (38, 7, 7, 3406.00, '2026-08-09', N'Publicidad de Pedestal San Pedro Sula Centro', 22, '2026-08-28T09:00:00'),
        (39, 7, 3, 30000.00, '2026-09-03', N'Alquiler de Pedestal San Pedro Sula Centro', 22, '2026-09-28T09:00:00'),
        (40, 7, 2, 1342.00, '2026-09-12', N'Agua de Pedestal San Pedro Sula Centro', 22, '2026-09-28T09:00:00'),
        (41, 7, 3, 18000.00, '2026-10-21', N'Alquiler de Pedestal San Pedro Sula Centro', 22, '2026-10-28T09:00:00'),
        (42, 7, 8, 5989.00, '2026-10-19', N'Seguridad de Pedestal San Pedro Sula Centro', 22, '2026-10-28T09:00:00'),
        (43, 8, 3, 22000.00, '2026-08-15', N'Alquiler de Pedestal San Pedro Sula Mall', 23, '2026-08-28T09:00:00'),
        (44, 8, 1, 1937.00, '2026-08-13', N'Energía eléctrica de Pedestal San Pedro Sula Mall', 23, '2026-08-28T09:00:00'),
        (45, 8, 3, 22000.00, '2026-09-15', N'Alquiler de Pedestal San Pedro Sula Mall', 23, '2026-09-28T09:00:00'),
        (46, 8, 4, 1703.00, '2026-09-14', N'Internet y teléfono de Pedestal San Pedro Sula Mall', 23, '2026-09-28T09:00:00'),
        (47, 8, 3, 30000.00, '2026-10-18', N'Alquiler de Pedestal San Pedro Sula Mall', 23, '2026-10-28T09:00:00'),
        (48, 8, 5, 1515.00, '2026-10-14', N'Papelería y suministros de Pedestal San Pedro Sula Mall', 23, '2026-10-28T09:00:00'),
        (49, 9, 3, 30000.00, '2026-08-25', N'Alquiler de Pedestal La Ceiba Centro', 24, '2026-08-28T09:00:00'),
        (50, 9, 2, 1038.00, '2026-08-15', N'Agua de Pedestal La Ceiba Centro', 24, '2026-08-28T09:00:00'),
        (51, 9, 3, 18000.00, '2026-09-01', N'Alquiler de Pedestal La Ceiba Centro', 24, '2026-09-28T09:00:00'),
        (52, 9, 8, 4820.00, '2026-09-15', N'Seguridad de Pedestal La Ceiba Centro', 24, '2026-09-28T09:00:00'),
        (53, 9, 3, 18000.00, '2026-10-17', N'Alquiler de Pedestal La Ceiba Centro', 24, '2026-10-28T09:00:00'),
        (54, 9, 15, 5659.00, '2026-10-02', N'Otros de Pedestal La Ceiba Centro', 24, '2026-10-28T09:00:00'),
        (55, 10, 3, 18000.00, '2026-08-04', N'Alquiler de Pedestal La Ceiba Paseo', 25, '2026-08-28T09:00:00'),
        (56, 10, 1, 1630.00, '2026-08-16', N'Energía eléctrica de Pedestal La Ceiba Paseo', 25, '2026-08-28T09:00:00'),
        (57, 10, 3, 22000.00, '2026-09-28', N'Alquiler de Pedestal La Ceiba Paseo', 25, '2026-09-28T09:00:00'),
        (58, 10, 2, 6095.00, '2026-09-05', N'Agua de Pedestal La Ceiba Paseo', 25, '2026-09-28T09:00:00'),
        (59, 10, 3, 22000.00, '2026-10-24', N'Alquiler de Pedestal La Ceiba Paseo', 25, '2026-10-28T09:00:00'),
        (60, 10, 6, 3738.00, '2026-10-06', N'Mantenimiento de Pedestal La Ceiba Paseo', 25, '2026-10-28T09:00:00'),
        (61, 11, 3, 30000.00, '2026-08-01', N'Alquiler de Pedestal El Progreso Centro', 26, '2026-08-28T09:00:00'),
        (62, 11, 2, 2239.00, '2026-08-03', N'Agua de Pedestal El Progreso Centro', 26, '2026-08-28T09:00:00'),
        (63, 11, 3, 18000.00, '2026-09-15', N'Alquiler de Pedestal El Progreso Centro', 26, '2026-09-28T09:00:00'),
        (64, 11, 4, 1200.00, '2026-09-25', N'Internet y teléfono de Pedestal El Progreso Centro', 26, '2026-09-28T09:00:00'),
        (65, 11, 3, 25000.00, '2026-10-13', N'Alquiler de Pedestal El Progreso Centro', 26, '2026-10-28T09:00:00'),
        (66, 11, 7, 2925.00, '2026-10-18', N'Publicidad de Pedestal El Progreso Centro', 26, '2026-10-28T09:00:00'),
        (67, 12, 3, 18000.00, '2026-08-23', N'Alquiler de Pedestal Yoro Centro', 27, '2026-08-28T09:00:00'),
        (68, 12, 1, 4258.00, '2026-08-12', N'Energía eléctrica de Pedestal Yoro Centro', 27, '2026-08-28T09:00:00'),
        (69, 12, 3, 18000.00, '2026-09-01', N'Alquiler de Pedestal Yoro Centro', 27, '2026-09-28T09:00:00'),
        (70, 12, 10, 1298.00, '2026-09-23', N'Transporte de Pedestal Yoro Centro', 27, '2026-09-28T09:00:00'),
        (71, 12, 3, 22000.00, '2026-10-06', N'Alquiler de Pedestal Yoro Centro', 27, '2026-10-28T09:00:00'),
        (72, 12, 15, 5325.00, '2026-10-01', N'Otros de Pedestal Yoro Centro', 27, '2026-10-28T09:00:00'),
        (73, 13, 3, 18000.00, '2026-08-16', N'Alquiler de Pedestal Juticalpa Centro', 28, '2026-08-28T09:00:00'),
        (74, 13, 4, 4592.00, '2026-08-02', N'Internet y teléfono de Pedestal Juticalpa Centro', 28, '2026-08-28T09:00:00'),
        (75, 13, 3, 30000.00, '2026-09-11', N'Alquiler de Pedestal Juticalpa Centro', 28, '2026-09-28T09:00:00'),
        (76, 13, 6, 3523.00, '2026-09-20', N'Mantenimiento de Pedestal Juticalpa Centro', 28, '2026-09-28T09:00:00'),
        (77, 13, 3, 18000.00, '2026-10-21', N'Alquiler de Pedestal Juticalpa Centro', 28, '2026-10-28T09:00:00'),
        (78, 13, 15, 3275.00, '2026-10-11', N'Otros de Pedestal Juticalpa Centro', 28, '2026-10-28T09:00:00'),
        (79, 14, 3, 30000.00, '2026-08-22', N'Alquiler de Pedestal Catacamas Centro', 29, '2026-08-28T09:00:00'),
        (80, 14, 9, 4680.00, '2026-08-23', N'Limpieza de Pedestal Catacamas Centro', 29, '2026-08-28T09:00:00'),
        (81, 14, 3, 25000.00, '2026-09-02', N'Alquiler de Pedestal Catacamas Centro', 29, '2026-09-28T09:00:00'),
        (82, 14, 6, 3460.00, '2026-09-11', N'Mantenimiento de Pedestal Catacamas Centro', 29, '2026-09-28T09:00:00'),
        (83, 14, 3, 25000.00, '2026-10-25', N'Alquiler de Pedestal Catacamas Centro', 29, '2026-10-28T09:00:00'),
        (84, 14, 8, 4952.00, '2026-10-22', N'Seguridad de Pedestal Catacamas Centro', 29, '2026-10-28T09:00:00'),
        (85, 15, 3, 30000.00, '2026-08-04', N'Alquiler de Pedestal Choluteca Centro', 30, '2026-08-28T09:00:00'),
        (86, 15, 7, 1103.00, '2026-08-01', N'Publicidad de Pedestal Choluteca Centro', 30, '2026-08-28T09:00:00'),
        (87, 15, 3, 25000.00, '2026-09-14', N'Alquiler de Pedestal Choluteca Centro', 30, '2026-09-28T09:00:00'),
        (88, 15, 5, 5301.00, '2026-09-06', N'Papelería y suministros de Pedestal Choluteca Centro', 30, '2026-09-28T09:00:00'),
        (89, 15, 3, 25000.00, '2026-10-22', N'Alquiler de Pedestal Choluteca Centro', 30, '2026-10-28T09:00:00'),
        (90, 15, 8, 3309.00, '2026-10-08', N'Seguridad de Pedestal Choluteca Centro', 30, '2026-10-28T09:00:00'),
        (91, 16, 3, 18000.00, '2026-08-28', N'Alquiler de Pedestal Choluteca Plaza', 31, '2026-08-28T09:00:00'),
        (92, 16, 1, 4688.00, '2026-08-12', N'Energía eléctrica de Pedestal Choluteca Plaza', 31, '2026-08-28T09:00:00'),
        (93, 16, 3, 30000.00, '2026-09-24', N'Alquiler de Pedestal Choluteca Plaza', 31, '2026-09-28T09:00:00'),
        (94, 16, 9, 2700.00, '2026-09-10', N'Limpieza de Pedestal Choluteca Plaza', 31, '2026-09-28T09:00:00'),
        (95, 16, 3, 25000.00, '2026-10-03', N'Alquiler de Pedestal Choluteca Plaza', 31, '2026-10-28T09:00:00'),
        (96, 16, 6, 3807.00, '2026-10-04', N'Mantenimiento de Pedestal Choluteca Plaza', 31, '2026-10-28T09:00:00'),
        (97, 17, 3, 30000.00, '2026-08-14', N'Alquiler de Pedestal Comayagua Centro', 32, '2026-08-28T09:00:00'),
        (98, 17, 7, 832.00, '2026-08-13', N'Publicidad de Pedestal Comayagua Centro', 32, '2026-08-28T09:00:00'),
        (99, 17, 3, 30000.00, '2026-09-14', N'Alquiler de Pedestal Comayagua Centro', 32, '2026-09-28T09:00:00'),
        (100, 17, 1, 5649.00, '2026-09-08', N'Energía eléctrica de Pedestal Comayagua Centro', 32, '2026-09-28T09:00:00'),
        (101, 17, 3, 18000.00, '2026-10-13', N'Alquiler de Pedestal Comayagua Centro', 32, '2026-10-28T09:00:00'),
        (102, 17, 10, 2129.00, '2026-10-16', N'Transporte de Pedestal Comayagua Centro', 32, '2026-10-28T09:00:00'),
        (103, 18, 3, 22000.00, '2026-08-27', N'Alquiler de Pedestal Siguatepeque Centro', 33, '2026-08-28T09:00:00'),
        (104, 18, 4, 2005.00, '2026-08-10', N'Internet y teléfono de Pedestal Siguatepeque Centro', 33, '2026-08-28T09:00:00'),
        (105, 18, 3, 22000.00, '2026-09-02', N'Alquiler de Pedestal Siguatepeque Centro', 33, '2026-09-28T09:00:00'),
        (106, 18, 15, 3695.00, '2026-09-19', N'Otros de Pedestal Siguatepeque Centro', 33, '2026-09-28T09:00:00'),
        (107, 18, 3, 25000.00, '2026-10-01', N'Alquiler de Pedestal Siguatepeque Centro', 33, '2026-10-28T09:00:00'),
        (108, 18, 8, 4109.00, '2026-10-11', N'Seguridad de Pedestal Siguatepeque Centro', 33, '2026-10-28T09:00:00'),
        (109, 19, 3, 30000.00, '2026-08-03', N'Alquiler de Pedestal Santa Rosa de Copán Centro', 34, '2026-08-28T09:00:00'),
        (110, 19, 6, 1796.00, '2026-08-17', N'Mantenimiento de Pedestal Santa Rosa de Copán Centro', 34, '2026-08-28T09:00:00'),
        (111, 19, 3, 18000.00, '2026-09-15', N'Alquiler de Pedestal Santa Rosa de Copán Centro', 34, '2026-09-28T09:00:00'),
        (112, 19, 6, 1630.00, '2026-09-15', N'Mantenimiento de Pedestal Santa Rosa de Copán Centro', 34, '2026-09-28T09:00:00'),
        (113, 19, 3, 22000.00, '2026-10-08', N'Alquiler de Pedestal Santa Rosa de Copán Centro', 34, '2026-10-28T09:00:00'),
        (114, 19, 7, 2769.00, '2026-10-04', N'Publicidad de Pedestal Santa Rosa de Copán Centro', 34, '2026-10-28T09:00:00'),
        (115, 20, 3, 18000.00, '2026-08-18', N'Alquiler de Pedestal Copán Ruinas', 35, '2026-08-28T09:00:00'),
        (116, 20, 5, 1572.00, '2026-08-17', N'Papelería y suministros de Pedestal Copán Ruinas', 35, '2026-08-28T09:00:00'),
        (117, 20, 3, 25000.00, '2026-09-28', N'Alquiler de Pedestal Copán Ruinas', 35, '2026-09-28T09:00:00'),
        (118, 20, 15, 3070.00, '2026-09-28', N'Otros de Pedestal Copán Ruinas', 35, '2026-09-28T09:00:00'),
        (119, 20, 3, 25000.00, '2026-10-18', N'Alquiler de Pedestal Copán Ruinas', 35, '2026-10-28T09:00:00'),
        (120, 20, 4, 1391.00, '2026-10-10', N'Internet y teléfono de Pedestal Copán Ruinas', 35, '2026-10-28T09:00:00'),
        (121, 21, 3, 30000.00, '2026-08-06', N'Alquiler de Pedestal Danlí Centro', 36, '2026-08-28T09:00:00'),
        (122, 21, 6, 2222.00, '2026-08-15', N'Mantenimiento de Pedestal Danlí Centro', 36, '2026-08-28T09:00:00'),
        (123, 21, 3, 25000.00, '2026-09-05', N'Alquiler de Pedestal Danlí Centro', 36, '2026-09-28T09:00:00'),
        (124, 21, 1, 1508.00, '2026-09-08', N'Energía eléctrica de Pedestal Danlí Centro', 36, '2026-09-28T09:00:00'),
        (125, 21, 3, 25000.00, '2026-10-04', N'Alquiler de Pedestal Danlí Centro', 36, '2026-10-28T09:00:00'),
        (126, 21, 4, 6059.00, '2026-10-09', N'Internet y teléfono de Pedestal Danlí Centro', 36, '2026-10-28T09:00:00'),
        (127, 22, 3, 18000.00, '2026-08-01', N'Alquiler de Pedestal Danlí Plaza', 37, '2026-08-28T09:00:00'),
        (128, 22, 4, 1827.00, '2026-08-10', N'Internet y teléfono de Pedestal Danlí Plaza', 37, '2026-08-28T09:00:00'),
        (129, 22, 3, 18000.00, '2026-09-03', N'Alquiler de Pedestal Danlí Plaza', 37, '2026-09-28T09:00:00'),
        (130, 22, 5, 3682.00, '2026-09-23', N'Papelería y suministros de Pedestal Danlí Plaza', 37, '2026-09-28T09:00:00'),
        (131, 22, 3, 30000.00, '2026-10-27', N'Alquiler de Pedestal Danlí Plaza', 37, '2026-10-28T09:00:00'),
        (132, 22, 7, 2647.00, '2026-10-18', N'Publicidad de Pedestal Danlí Plaza', 37, '2026-10-28T09:00:00'),
        (133, 23, 3, 25000.00, '2026-08-27', N'Alquiler de Pedestal Santa Bárbara Centro', 38, '2026-08-28T09:00:00'),
        (134, 23, 10, 4161.00, '2026-08-04', N'Transporte de Pedestal Santa Bárbara Centro', 38, '2026-08-28T09:00:00'),
        (135, 23, 3, 25000.00, '2026-09-24', N'Alquiler de Pedestal Santa Bárbara Centro', 38, '2026-09-28T09:00:00'),
        (136, 23, 10, 3878.00, '2026-09-25', N'Transporte de Pedestal Santa Bárbara Centro', 38, '2026-09-28T09:00:00'),
        (137, 23, 3, 18000.00, '2026-10-21', N'Alquiler de Pedestal Santa Bárbara Centro', 38, '2026-10-28T09:00:00'),
        (138, 23, 6, 1091.00, '2026-10-12', N'Mantenimiento de Pedestal Santa Bárbara Centro', 38, '2026-10-28T09:00:00'),
        (139, 24, 3, 30000.00, '2026-08-25', N'Alquiler de Pedestal Quimistán Centro', 39, '2026-08-28T09:00:00'),
        (140, 24, 15, 6202.00, '2026-08-06', N'Otros de Pedestal Quimistán Centro', 39, '2026-08-28T09:00:00'),
        (141, 24, 3, 22000.00, '2026-09-23', N'Alquiler de Pedestal Quimistán Centro', 39, '2026-09-28T09:00:00'),
        (142, 24, 1, 4062.00, '2026-09-09', N'Energía eléctrica de Pedestal Quimistán Centro', 39, '2026-09-28T09:00:00'),
        (143, 24, 3, 30000.00, '2026-10-23', N'Alquiler de Pedestal Quimistán Centro', 39, '2026-10-28T09:00:00'),
        (144, 24, 2, 1652.00, '2026-10-15', N'Agua de Pedestal Quimistán Centro', 39, '2026-10-28T09:00:00'),
        (145, 25, 3, 18000.00, '2026-08-27', N'Alquiler de Pedestal Gracias Centro', 40, '2026-08-28T09:00:00'),
        (146, 25, 8, 5344.00, '2026-08-28', N'Seguridad de Pedestal Gracias Centro', 40, '2026-08-28T09:00:00'),
        (147, 25, 3, 25000.00, '2026-09-08', N'Alquiler de Pedestal Gracias Centro', 40, '2026-09-28T09:00:00'),
        (148, 25, 15, 3204.00, '2026-09-10', N'Otros de Pedestal Gracias Centro', 40, '2026-09-28T09:00:00'),
        (149, 25, 3, 25000.00, '2026-10-28', N'Alquiler de Pedestal Gracias Centro', 40, '2026-10-28T09:00:00'),
        (150, 25, 8, 4418.00, '2026-10-20', N'Seguridad de Pedestal Gracias Centro', 40, '2026-10-28T09:00:00'),
        (151, 26, 3, 22000.00, '2026-08-25', N'Alquiler de Pedestal Gracias Plaza', 41, '2026-08-28T09:00:00'),
        (152, 26, 9, 2624.00, '2026-08-24', N'Limpieza de Pedestal Gracias Plaza', 41, '2026-08-28T09:00:00'),
        (153, 26, 3, 18000.00, '2026-09-06', N'Alquiler de Pedestal Gracias Plaza', 41, '2026-09-28T09:00:00'),
        (154, 26, 2, 4262.00, '2026-09-23', N'Agua de Pedestal Gracias Plaza', 41, '2026-09-28T09:00:00'),
        (155, 26, 3, 18000.00, '2026-10-27', N'Alquiler de Pedestal Gracias Plaza', 41, '2026-10-28T09:00:00'),
        (156, 26, 1, 1155.00, '2026-10-11', N'Energía eléctrica de Pedestal Gracias Plaza', 41, '2026-10-28T09:00:00'),
        (157, 27, 3, 22000.00, '2026-08-23', N'Alquiler de Pedestal Trujillo Centro', 42, '2026-08-28T09:00:00'),
        (158, 27, 5, 4889.00, '2026-08-16', N'Papelería y suministros de Pedestal Trujillo Centro', 42, '2026-08-28T09:00:00'),
        (159, 27, 3, 18000.00, '2026-09-06', N'Alquiler de Pedestal Trujillo Centro', 42, '2026-09-28T09:00:00'),
        (160, 27, 7, 6403.00, '2026-09-04', N'Publicidad de Pedestal Trujillo Centro', 42, '2026-09-28T09:00:00'),
        (161, 27, 3, 30000.00, '2026-10-16', N'Alquiler de Pedestal Trujillo Centro', 42, '2026-10-28T09:00:00'),
        (162, 27, 15, 2622.00, '2026-10-11', N'Otros de Pedestal Trujillo Centro', 42, '2026-10-28T09:00:00'),
        (163, 28, 3, 18000.00, '2026-08-18', N'Alquiler de Pedestal Tocoa Centro', 43, '2026-08-28T09:00:00'),
        (164, 28, 8, 4192.00, '2026-08-12', N'Seguridad de Pedestal Tocoa Centro', 43, '2026-08-28T09:00:00'),
        (165, 28, 3, 18000.00, '2026-09-19', N'Alquiler de Pedestal Tocoa Centro', 43, '2026-09-28T09:00:00'),
        (166, 28, 8, 3232.00, '2026-09-07', N'Seguridad de Pedestal Tocoa Centro', 43, '2026-09-28T09:00:00'),
        (167, 28, 3, 25000.00, '2026-10-26', N'Alquiler de Pedestal Tocoa Centro', 43, '2026-10-28T09:00:00'),
        (168, 28, 15, 2141.00, '2026-10-24', N'Otros de Pedestal Tocoa Centro', 43, '2026-10-28T09:00:00'),
        (169, 29, 3, 22000.00, '2026-08-12', N'Alquiler de Pedestal Roatán Centro', 44, '2026-08-28T09:00:00'),
        (170, 29, 1, 1917.00, '2026-08-13', N'Energía eléctrica de Pedestal Roatán Centro', 44, '2026-08-28T09:00:00'),
        (171, 29, 3, 18000.00, '2026-09-12', N'Alquiler de Pedestal Roatán Centro', 44, '2026-09-28T09:00:00'),
        (172, 29, 2, 6198.00, '2026-09-26', N'Agua de Pedestal Roatán Centro', 44, '2026-09-28T09:00:00'),
        (173, 29, 3, 25000.00, '2026-10-04', N'Alquiler de Pedestal Roatán Centro', 44, '2026-10-28T09:00:00'),
        (174, 29, 2, 1501.00, '2026-10-27', N'Agua de Pedestal Roatán Centro', 44, '2026-10-28T09:00:00'),
        (175, 30, 3, 18000.00, '2026-08-23', N'Alquiler de Pedestal Roatán West End', 45, '2026-08-28T09:00:00'),
        (176, 30, 8, 3852.00, '2026-08-12', N'Seguridad de Pedestal Roatán West End', 45, '2026-08-28T09:00:00'),
        (177, 30, 3, 25000.00, '2026-09-14', N'Alquiler de Pedestal Roatán West End', 45, '2026-09-28T09:00:00'),
        (178, 30, 4, 4421.00, '2026-09-12', N'Internet y teléfono de Pedestal Roatán West End', 45, '2026-09-28T09:00:00'),
        (179, 30, 3, 22000.00, '2026-10-02', N'Alquiler de Pedestal Roatán West End', 45, '2026-10-28T09:00:00'),
        (180, 30, 8, 1161.00, '2026-10-24', N'Seguridad de Pedestal Roatán West End', 45, '2026-10-28T09:00:00');
    SET IDENTITY_INSERT dbo.Expense OFF;
END
GO

-- Gestión de closet virtual
IF NOT EXISTS (SELECT 1 FROM dbo.UserClothes)
BEGIN
    SET IDENTITY_INSERT dbo.UserClothes ON;
    INSERT INTO dbo.UserClothes (Id, User_Id, ClotheVariant_Id, ClotheType_Id, Name, Origin, ImageFileId) VALUES
        (1, 1, 155, 14, N'Bufanda Tejida', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0037'),
        (2, 1, 140, 12, N'Traje de Baño Entero', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0033'),
        (3, 28, 70, 5, N'Zapato Casual Cuero', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0017'),
        (4, 28, 86, 6, N'Gafas de Sol', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0021'),
        (5, 9, 97, 7, N'Falda Jean', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0024'),
        (6, 9, 52, 4, N'Chaqueta de Mezclilla', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0013'),
        (7, 14, 85, 6, N'Cinturón de Cuero', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0020'),
        (8, 16, 125, 10, N'Pack Medias 5 pares', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0030'),
        (9, 16, 68, 5, N'Tenis Urbanos', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0016'),
        (10, 21, 98, 7, N'Falda Jean', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0024'),
        (11, 5, 66, 5, N'Tenis Urbanos', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0016'),
        (12, 25, 98, 7, N'Falda Jean', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0024'),
        (13, 25, 101, 8, N'Short Deportivo', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0025'),
        (14, 25, 83, 5, N'Zapatilla Deportiva', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0019'),
        (15, 10, 140, 12, N'Traje de Baño Entero', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0033'),
        (16, 10, 63, 4, N'Chaqueta Cuero Sintético', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0015'),
        (17, 10, 101, 8, N'Short Deportivo', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0025'),
        (18, 1, 136, 12, N'Traje de Baño Entero', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0033'),
        (19, 1, 63, 4, N'Chaqueta Cuero Sintético', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0015'),
        (20, 1, 8, 1, N'Camisa Lino Manga Larga', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0002'),
        (21, 12, 125, 10, N'Pack Medias 5 pares', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0030'),
        (22, 12, 147, 13, N'Abrigo Largo Lana', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0035'),
        (23, 12, 159, 15, N'Mochila Urbana', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0039'),
        (24, 24, 83, 5, N'Zapatilla Deportiva', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0019'),
        (25, 23, 76, 5, N'Sandalias de Playa', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0018'),
        (26, 32, 42, 3, N'Vestido Casual Verano', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0010'),
        (27, 33, 79, 5, N'Zapatilla Deportiva', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0019'),
        (28, 7, 140, 12, N'Traje de Baño Entero', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0033'),
        (29, 7, 155, 14, N'Bufanda Tejida', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0037'),
        (30, 6, 86, 6, N'Gafas de Sol', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0021'),
        (31, 6, 13, 1, N'Camisa Polo Clásica', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0003'),
        (32, 17, 42, 3, N'Vestido Casual Verano', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0010'),
        (33, 17, 3, 1, N'Camisa Oxford', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0001'),
        (34, 21, 41, 3, N'Vestido Casual Verano', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0010'),
        (35, 21, 116, 9, N'Sudadera Cuello Redondo', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0028'),
        (36, 8, 48, 3, N'Vestido Largo Negro', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0012'),
        (37, 8, 126, 10, N'Pack Medias 5 pares', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0030'),
        (38, 8, 136, 12, N'Traje de Baño Entero', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0033'),
        (39, 2, 3, 1, N'Camisa Oxford', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0001'),
        (40, 30, 97, 7, N'Falda Jean', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0024'),
        (41, 5, 154, 14, N'Bufanda Tejida', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0037'),
        (42, 5, 86, 6, N'Gafas de Sol', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0021'),
        (43, 5, 29, 2, N'Jean Recto', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0007'),
        (44, 5, 112, 9, N'Sudadera con Capucha', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0027'),
        (45, 26, 159, 15, N'Mochila Urbana', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0039'),
        (46, 26, 7, 1, N'Camisa Lino Manga Larga', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0002'),
        (47, 26, 155, 14, N'Bufanda Tejida', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0037'),
        (48, 35, 54, 4, N'Chaqueta de Mezclilla', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0013'),
        (49, 35, 70, 5, N'Zapato Casual Cuero', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0017'),
        (50, 24, 140, 12, N'Traje de Baño Entero', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0033'),
        (51, 26, 120, 10, N'Pack Boxer 3 pzas', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0029'),
        (52, 21, 124, 10, N'Pack Medias 5 pares', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0030'),
        (53, 21, 147, 13, N'Abrigo Largo Lana', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0035'),
        (54, 5, 120, 10, N'Pack Boxer 3 pzas', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0029'),
        (55, 23, 96, 7, N'Falda Jean', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0024'),
        (56, 23, 115, 9, N'Sudadera Cuello Redondo', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0028'),
        (57, 23, 54, 4, N'Chaqueta de Mezclilla', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0013'),
        (58, 20, 52, 4, N'Chaqueta de Mezclilla', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0013'),
        (59, 20, 126, 10, N'Pack Medias 5 pares', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0030'),
        (60, 20, 63, 4, N'Chaqueta Cuero Sintético', N'PURCHASED', N'SP-MUESTRA-CLOTHE-0015'),
        (61, 6, NULL, 10, N'Prenda propia 1', N'UPLOADED', N'SP-MUESTRA-USER-00061'),
        (62, 35, NULL, 11, N'Prenda propia 2', N'UPLOADED', N'SP-MUESTRA-USER-00062'),
        (63, 25, NULL, 4, N'Prenda propia 3', N'UPLOADED', N'SP-MUESTRA-USER-00063'),
        (64, 10, NULL, 9, N'Prenda propia 4', N'UPLOADED', N'SP-MUESTRA-USER-00064'),
        (65, 25, NULL, 7, N'Prenda propia 5', N'UPLOADED', N'SP-MUESTRA-USER-00065'),
        (66, 35, NULL, 2, N'Prenda propia 6', N'UPLOADED', N'SP-MUESTRA-USER-00066'),
        (67, 16, NULL, 13, N'Prenda propia 7', N'UPLOADED', N'SP-MUESTRA-USER-00067'),
        (68, 25, NULL, 6, N'Prenda propia 8', N'UPLOADED', N'SP-MUESTRA-USER-00068'),
        (69, 1, NULL, 10, N'Prenda propia 9', N'UPLOADED', N'SP-MUESTRA-USER-00069'),
        (70, 1, NULL, 15, N'Prenda propia 10', N'UPLOADED', N'SP-MUESTRA-USER-00070'),
        (71, 32, NULL, 2, N'Prenda propia 11', N'UPLOADED', N'SP-MUESTRA-USER-00071'),
        (72, 14, NULL, 11, N'Prenda propia 12', N'UPLOADED', N'SP-MUESTRA-USER-00072'),
        (73, 14, NULL, 14, N'Prenda propia 13', N'UPLOADED', N'SP-MUESTRA-USER-00073'),
        (74, 16, NULL, 10, N'Prenda propia 14', N'UPLOADED', N'SP-MUESTRA-USER-00074'),
        (75, 33, NULL, 12, N'Prenda propia 15', N'UPLOADED', N'SP-MUESTRA-USER-00075'),
        (76, 28, NULL, 9, N'Prenda propia 16', N'UPLOADED', N'SP-MUESTRA-USER-00076'),
        (77, 35, NULL, 9, N'Prenda propia 17', N'UPLOADED', N'SP-MUESTRA-USER-00077'),
        (78, 16, NULL, 14, N'Prenda propia 18', N'UPLOADED', N'SP-MUESTRA-USER-00078'),
        (79, 25, NULL, 8, N'Prenda propia 19', N'UPLOADED', N'SP-MUESTRA-USER-00079'),
        (80, 25, NULL, 5, N'Prenda propia 20', N'UPLOADED', N'SP-MUESTRA-USER-00080'),
        (81, 21, NULL, 3, N'Prenda propia 21', N'UPLOADED', N'SP-MUESTRA-USER-00081'),
        (82, 28, NULL, 14, N'Prenda propia 22', N'UPLOADED', N'SP-MUESTRA-USER-00082'),
        (83, 16, NULL, 11, N'Prenda propia 23', N'UPLOADED', N'SP-MUESTRA-USER-00083'),
        (84, 2, NULL, 4, N'Prenda propia 24', N'UPLOADED', N'SP-MUESTRA-USER-00084'),
        (85, 20, NULL, 12, N'Prenda propia 25', N'UPLOADED', N'SP-MUESTRA-USER-00085');
    SET IDENTITY_INSERT dbo.UserClothes OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Outfit)
BEGIN
    SET IDENTITY_INSERT dbo.Outfit ON;
    INSERT INTO dbo.Outfit (Id, User_Id, Name, Description) VALUES
        (1, 1, N'Outfit oficina 1', NULL),
        (2, 28, N'Outfit fiesta 2', NULL),
        (3, 14, N'Outfit oficina 3', NULL),
        (4, 16, N'Outfit casual 4', NULL),
        (5, 21, N'Outfit casual 5', NULL),
        (6, 5, N'Outfit viaje 6', NULL),
        (7, 25, N'Outfit fin de semana 7', NULL),
        (8, 10, N'Outfit viaje 8', NULL),
        (9, 12, N'Outfit oficina 9', NULL),
        (10, 23, N'Outfit casual 10', NULL),
        (11, 6, N'Outfit casual 11', NULL),
        (12, 8, N'Outfit casual 12', NULL),
        (13, 26, N'Outfit casual 13', NULL),
        (14, 35, N'Outfit fin de semana 14', NULL),
        (15, 20, N'Outfit viaje 15', NULL),
        (16, 1, N'Outfit fin de semana 16', NULL),
        (17, 28, N'Outfit fiesta 17', NULL),
        (18, 14, N'Outfit oficina 18', NULL),
        (19, 16, N'Outfit casual 19', NULL),
        (20, 21, N'Outfit casual 20', NULL),
        (21, 5, N'Outfit oficina 21', NULL),
        (22, 25, N'Outfit oficina 22', NULL),
        (23, 10, N'Outfit oficina 23', NULL),
        (24, 12, N'Outfit oficina 24', NULL),
        (25, 23, N'Outfit fiesta 25', NULL),
        (26, 6, N'Outfit oficina 26', NULL),
        (27, 8, N'Outfit oficina 27', NULL),
        (28, 26, N'Outfit casual 28', NULL),
        (29, 35, N'Outfit viaje 29', NULL),
        (30, 20, N'Outfit oficina 30', NULL),
        (31, 1, N'Outfit fin de semana 31', NULL),
        (32, 28, N'Outfit casual 32', NULL),
        (33, 14, N'Outfit fiesta 33', NULL),
        (34, 16, N'Outfit viaje 34', NULL),
        (35, 21, N'Outfit viaje 35', NULL),
        (36, 5, N'Outfit viaje 36', NULL);
    SET IDENTITY_INSERT dbo.Outfit OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Outfit_has_UserClothes)
BEGIN
    INSERT INTO dbo.Outfit_has_UserClothes (Outfit_Id, UserClothes_Id) VALUES
        (1, 2),
        (1, 69),
        (2, 4),
        (2, 76),
        (2, 82),
        (2, 3),
        (3, 73),
        (3, 72),
        (4, 83),
        (4, 8),
        (5, 81),
        (5, 52),
        (5, 53),
        (5, 35),
        (6, 43),
        (6, 44),
        (6, 11),
        (7, 80),
        (7, 12),
        (8, 17),
        (8, 64),
        (8, 16),
        (8, 15),
        (9, 22),
        (9, 21),
        (9, 23),
        (10, 55),
        (10, 25),
        (10, 56),
        (10, 57),
        (11, 61),
        (11, 31),
        (11, 30),
        (12, 36),
        (12, 38),
        (13, 46),
        (13, 45),
        (14, 77),
        (14, 48),
        (14, 66),
        (15, 59),
        (15, 85),
        (15, 60),
        (16, 70),
        (16, 1),
        (17, 76),
        (17, 82),
        (17, 3),
        (17, 4),
        (18, 7),
        (18, 72),
        (19, 74),
        (19, 83),
        (19, 67),
        (19, 78),
        (20, 53),
        (20, 10),
        (21, 41),
        (21, 44),
        (21, 54),
        (21, 42),
        (22, 65),
        (22, 12),
        (22, 14),
        (22, 79),
        (23, 15),
        (23, 64),
        (23, 16),
        (24, 22),
        (24, 23),
        (24, 21),
        (25, 56),
        (25, 57),
        (25, 55),
        (26, 61),
        (26, 31),
        (26, 30),
        (27, 36),
        (27, 38),
        (27, 37),
        (28, 46),
        (28, 51),
        (28, 47),
        (29, 48),
        (29, 49),
        (29, 62),
        (29, 66),
        (30, 85),
        (30, 60),
        (30, 58),
        (30, 59),
        (31, 19),
        (31, 70),
        (32, 82),
        (32, 4),
        (33, 73),
        (33, 72),
        (34, 78),
        (34, 67),
        (35, 53),
        (35, 81),
        (35, 34),
        (35, 35),
        (36, 41),
        (36, 42),
        (36, 54),
        (36, 44);
END
GO

-- =============================
-- 6. Crear las vistas
-- =============================

-- Ingresos = facturas PAID / SHIPPED / DELIVERED. Egresos = órdenes de compra RECEIVED + gastos + planillas pagadas.
-- Los promedios mensuales se calculan sobre los meses con movimiento.

-- Vistas base (las usan las demás)

-- Stock total por tienda y variante (suma de todos sus cubículos: bodega + piso de venta).
CREATE OR ALTER VIEW dbo.vw_StoreStock AS
SELECT r.Store_Id, cic.ClotheVariant_Id, SUM(cic.Quantity) AS Quantity
FROM dbo.ClothesInCubicle cic
JOIN dbo.Cubicle cu ON cu.Id = cic.Cubicle_Id
JOIN dbo.Rack r     ON r.Id = cu.Rack_Id
GROUP BY r.Store_Id, cic.ClotheVariant_Id;
GO

-- Ingresos mensuales por tienda.
CREATE OR ALTER VIEW dbo.vw_StoreIncome AS
SELECT b.Store_Id,
       DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1) AS PeriodMonth,
       SUM(b.Total) AS Income
FROM dbo.Bill b
WHERE b.Active = 1 AND b.Status IN ('PAID','SHIPPED','DELIVERED')
GROUP BY b.Store_Id, DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1);
GO

-- Detalle de egresos por tienda y origen (compras, gastos operativos, planillas).
CREATE OR ALTER VIEW dbo.vw_StoreExpenses AS
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

-- Nombre legible del proveedor (persona natural o empresa).
CREATE OR ALTER VIEW dbo.vw_SupplierInfo AS
SELECT s.Id AS Supplier_Id, s.SupplierType,
       CASE WHEN s.SupplierType = 'J' THEN COALESCE(le.TradeName, le.BusinessName)
            ELSE LTRIM(RTRIM(CONCAT(p.FirstName, N' ', p.FirstSurname))) END AS SupplierName
FROM dbo.Supplier s
LEFT JOIN dbo.Person p        ON p.Id  = s.Person_Id
LEFT JOIN dbo.LegalEntity le  ON le.Id = s.LegalEntity_Id;
GO

-- Nivel tienda

-- [1] Ingresos vs Egresos por tienda y mes (base del balance).
CREATE OR ALTER VIEW dbo.vw_StoreBalance AS
WITH inc AS (
    SELECT Store_Id, PeriodMonth, Income FROM dbo.vw_StoreIncome
),
ex AS (
    SELECT Store_Id,
           DATEFROMPARTS(YEAR(ExpenseDate), MONTH(ExpenseDate), 1) AS PeriodMonth,
           SUM(Amount) AS Expenses
    FROM dbo.vw_StoreExpenses
    GROUP BY Store_Id, DATEFROMPARTS(YEAR(ExpenseDate), MONTH(ExpenseDate), 1)
),
m AS (
    SELECT COALESCE(i.Store_Id, e.Store_Id)       AS Store_Id,
           COALESCE(i.PeriodMonth, e.PeriodMonth) AS PeriodMonth,
           ISNULL(i.Income, 0)                    AS Income,
           ISNULL(e.Expenses, 0)                  AS Expenses
    FROM inc i
    FULL OUTER JOIN ex e ON e.Store_Id = i.Store_Id AND e.PeriodMonth = i.PeriodMonth
)
SELECT m.Store_Id, s.Name AS StoreName, s.WorkArea_Id, m.PeriodMonth,
       m.Income, m.Expenses, m.Income - m.Expenses AS Profit
FROM m
JOIN dbo.Store s ON s.Id = m.Store_Id;
GO

-- [2] Ventas por empleado y mes; MonthRank = 1 es el empleado del mes de esa tienda.
CREATE OR ALTER VIEW dbo.vw_EmployeeSales AS
WITH sales AS (
    SELECT b.Store_Id, b.Employee_Id,
           DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1) AS PeriodMonth,
           COUNT(*)     AS BillCount,
           SUM(b.Total) AS TotalSold
    FROM dbo.Bill b
    WHERE b.Active = 1 AND b.Employee_Id IS NOT NULL AND b.Status IN ('PAID','SHIPPED','DELIVERED')
    GROUP BY b.Store_Id, b.Employee_Id, DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1)
)
SELECT s.Store_Id, s.Employee_Id,
       LTRIM(RTRIM(CONCAT(p.FirstName, N' ', p.FirstSurname))) AS EmployeeName,
       s.PeriodMonth, s.BillCount, s.TotalSold,
       RANK() OVER (PARTITION BY s.Store_Id, s.PeriodMonth ORDER BY s.TotalSold DESC) AS MonthRank
FROM sales s
JOIN dbo.Employee e ON e.Id = s.Employee_Id
JOIN dbo.Person p   ON p.Id = e.Person_Id;
GO

-- [2b] Empleado del mes de cada tienda (si hay empate, aparecen todos los empatados).
CREATE OR ALTER VIEW dbo.vw_EmployeeOfTheMonth AS
SELECT Store_Id, Employee_Id, EmployeeName, PeriodMonth, BillCount, TotalSold
FROM dbo.vw_EmployeeSales
WHERE MonthRank = 1;
GO

-- [3a] Compras a proveedores: a quién se le compra más (SpendRank = 1 es el mayor).
CREATE OR ALTER VIEW dbo.vw_SupplierPurchases AS
WITH purchases AS (
    SELECT po.Store_Id, po.Supplier_Id,
           COUNT(DISTINCT po.Id) AS OrderCount,
           SUM(pod.Quantity)     AS UnitsBought,
           SUM(pod.SubTotal)     AS TotalSpent
    FROM dbo.PurchaseOrder po
    JOIN dbo.PurchaseOrderDetail pod ON pod.PurchaseOrder_Id = po.Id
    WHERE po.Active = 1 AND po.Status = 'RECEIVED'
    GROUP BY po.Store_Id, po.Supplier_Id
)
SELECT pu.Store_Id, pu.Supplier_Id, si.SupplierName, pu.OrderCount, pu.UnitsBought, pu.TotalSpent,
       RANK() OVER (PARTITION BY pu.Store_Id ORDER BY pu.TotalSpent DESC) AS SpendRank
FROM purchases pu
JOIN dbo.vw_SupplierInfo si ON si.Supplier_Id = pu.Supplier_Id;
GO

-- [3b] Comparativo de precios entre proveedores por prenda (costo unitario promedio ponderado).
--      PriceRankDesc = 1 es el proveedor MÁS CARO; PriceRankAsc = 1 es el MÁS BARATO.
CREATE OR ALTER VIEW dbo.vw_SupplierPriceComparison AS
WITH prices AS (
    SELECT po.Store_Id, cv.Clothe_Id, po.Supplier_Id,
           SUM(pod.SubTotal) / NULLIF(SUM(pod.Quantity), 0) AS AvgUnitCost,
           MIN(pod.UnitCost) AS MinUnitCost,
           MAX(pod.UnitCost) AS MaxUnitCost,
           SUM(pod.Quantity) AS UnitsBought
    FROM dbo.PurchaseOrderDetail pod
    JOIN dbo.PurchaseOrder po  ON po.Id = pod.PurchaseOrder_Id
    JOIN dbo.ClotheVariant cv  ON cv.Id = pod.ClotheVariant_Id
    WHERE po.Active = 1 AND po.Status = 'RECEIVED'
    GROUP BY po.Store_Id, cv.Clothe_Id, po.Supplier_Id
)
SELECT pr.Store_Id, pr.Clothe_Id, c.Name AS ClotheName, pr.Supplier_Id, si.SupplierName,
       pr.AvgUnitCost, pr.MinUnitCost, pr.MaxUnitCost, pr.UnitsBought,
       RANK() OVER (PARTITION BY pr.Store_Id, pr.Clothe_Id ORDER BY pr.AvgUnitCost DESC) AS PriceRankDesc,
       RANK() OVER (PARTITION BY pr.Store_Id, pr.Clothe_Id ORDER BY pr.AvgUnitCost ASC)  AS PriceRankAsc
FROM prices pr
JOIN dbo.Clothe c           ON c.Id = pr.Clothe_Id
JOIN dbo.vw_SupplierInfo si ON si.Supplier_Id = pr.Supplier_Id;
GO

-- [4] Producto más vendido por tienda y mes (SalesRank = 1 es el más vendido en unidades).
CREATE OR ALTER VIEW dbo.vw_TopSellingProducts AS
WITH sold AS (
    SELECT b.Store_Id, cv.Clothe_Id,
           DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1) AS PeriodMonth,
           SUM(bd.Quantity) AS UnitsSold,
           SUM(bd.Total)    AS Revenue
    FROM dbo.Bill b
    JOIN dbo.BillDetails bd   ON bd.Bill_Id = b.Id
    JOIN dbo.ClotheVariant cv ON cv.Id = bd.ClotheVariant_Id
    WHERE b.Active = 1 AND b.Status IN ('PAID','SHIPPED','DELIVERED')
    GROUP BY b.Store_Id, cv.Clothe_Id, DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1)
)
SELECT so.Store_Id, so.PeriodMonth, so.Clothe_Id, c.Name AS ClotheName, t.Name AS ClotheTypeName,
       so.UnitsSold, so.Revenue,
       RANK() OVER (PARTITION BY so.Store_Id, so.PeriodMonth ORDER BY so.UnitsSold DESC) AS SalesRank
FROM sold so
JOIN dbo.Clothe c      ON c.Id = so.Clothe_Id
JOIN dbo.ClotheType t  ON t.Id = c.ClotheType_Id;
GO

-- [5] Ganancia promedio mensual de cada tienda.
CREATE OR ALTER VIEW dbo.vw_StoreAvgProfit AS
SELECT sb.Store_Id, sb.StoreName, sb.WorkArea_Id,
       COUNT(*)         AS MonthsCounted,
       SUM(sb.Income)   AS TotalIncome,
       SUM(sb.Expenses) AS TotalExpenses,
       SUM(sb.Profit)   AS TotalProfit,
       AVG(sb.Profit)   AS AvgMonthlyProfit
FROM dbo.vw_StoreBalance sb
GROUP BY sb.Store_Id, sb.StoreName, sb.WorkArea_Id;
GO

-- Nivel área

-- [7] Ingresos vs Egresos de cada tienda del área (para el gráfico de columnas; filtrar por WorkArea_Id).
CREATE OR ALTER VIEW dbo.vw_AreaStoreBalance AS
SELECT sb.WorkArea_Id, wa.Name AS AreaName, sb.Store_Id, sb.StoreName,
       sb.PeriodMonth, sb.Income, sb.Expenses, sb.Profit
FROM dbo.vw_StoreBalance sb
JOIN dbo.WorkArea wa ON wa.Id = sb.WorkArea_Id;
GO

-- Balance consolidado de cada área por mes (suma de sus tiendas).
CREATE OR ALTER VIEW dbo.vw_AreaBalance AS
SELECT WorkArea_Id, AreaName, PeriodMonth,
       SUM(Income) AS Income, SUM(Expenses) AS Expenses, SUM(Profit) AS Profit
FROM dbo.vw_AreaStoreBalance
GROUP BY WorkArea_Id, AreaName, PeriodMonth;
GO

-- [8] Ganancia promedio del área: por mes del área y por tienda del área.
CREATE OR ALTER VIEW dbo.vw_AreaAvgProfit AS
SELECT ab.WorkArea_Id, ab.AreaName,
       COUNT(*)         AS MonthsCounted,
       AVG(ab.Profit)   AS AvgMonthlyProfit,
       (SELECT AVG(sap.AvgMonthlyProfit)
        FROM dbo.vw_StoreAvgProfit sap
        WHERE sap.WorkArea_Id = ab.WorkArea_Id) AS AvgMonthlyProfitPerStore
FROM dbo.vw_AreaBalance ab
GROUP BY ab.WorkArea_Id, ab.AreaName;
GO

-- Nivel nacional

-- [9] Ingresos vs Egresos de cada área (gráfico de columnas): usar vw_AreaBalance.

-- Balance de toda la empresa por mes (suma de las áreas).
CREATE OR ALTER VIEW dbo.vw_CompanyBalance AS
SELECT PeriodMonth,
       SUM(Income) AS Income, SUM(Expenses) AS Expenses, SUM(Profit) AS Profit
FROM dbo.vw_AreaBalance
GROUP BY PeriodMonth;
GO

-- [10] Ganancia promedio de las áreas, con ranking y promedio general por área.
CREATE OR ALTER VIEW dbo.vw_NationalAreaAvgProfit AS
SELECT WorkArea_Id, AreaName, MonthsCounted, AvgMonthlyProfit, AvgMonthlyProfitPerStore,
       RANK() OVER (ORDER BY AvgMonthlyProfit DESC) AS ProfitRank,
       AVG(AvgMonthlyProfit) OVER ()                AS CompanyAvgPerArea
FROM dbo.vw_AreaAvgProfit;
GO

-- VISTAS ADICIONALES (gestión empresarial)

-- Desglose de egresos por tienda, mes y origen ("en qué se gasta").
CREATE OR ALTER VIEW dbo.vw_StoreExpenseBreakdown AS
SELECT Store_Id,
       DATEFROMPARTS(YEAR(ExpenseDate), MONTH(ExpenseDate), 1) AS PeriodMonth,
       Source, Detail, SUM(Amount) AS Amount
FROM dbo.vw_StoreExpenses
GROUP BY Store_Id, DATEFROMPARTS(YEAR(ExpenseDate), MONTH(ExpenseDate), 1), Source, Detail;
GO

-- Pérdidas de inventario (mermas): ajustes de SALIDA valorados al costo promedio de compra.
-- Convención: StockMovement tipo ADJUST con FromStore_Id y sin ToStore_Id = merma/pérdida.
-- No se restan en vw_StoreBalance porque el costo de la mercadería ya está en las compras.
CREATE OR ALTER VIEW dbo.vw_InventoryLosses AS
WITH cost AS (
    SELECT pod.ClotheVariant_Id,
           SUM(pod.SubTotal) / NULLIF(SUM(pod.Quantity), 0) AS AvgUnitCost
    FROM dbo.PurchaseOrderDetail pod
    JOIN dbo.PurchaseOrder po ON po.Id = pod.PurchaseOrder_Id
    WHERE po.Status = 'RECEIVED'
    GROUP BY pod.ClotheVariant_Id
)
SELECT sm.FromStore_Id AS Store_Id,
       DATEFROMPARTS(YEAR(sm.RegistrationDate), MONTH(sm.RegistrationDate), 1) AS PeriodMonth,
       sm.ClotheVariant_Id,
       SUM(sm.Quantity) AS UnitsLost,
       SUM(sm.Quantity * ISNULL(c.AvgUnitCost, 0)) AS LossValue
FROM dbo.StockMovement sm
LEFT JOIN cost c ON c.ClotheVariant_Id = sm.ClotheVariant_Id
WHERE sm.Active = 1 AND sm.MovementType = 'ADJUST'
  AND sm.FromStore_Id IS NOT NULL AND sm.ToStore_Id IS NULL
GROUP BY sm.FromStore_Id, DATEFROMPARTS(YEAR(sm.RegistrationDate), MONTH(sm.RegistrationDate), 1), sm.ClotheVariant_Id;
GO

-- Ventas por talla y color (para decidir qué reabastecer).
CREATE OR ALTER VIEW dbo.vw_VariantSales AS
SELECT b.Store_Id,
       DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1) AS PeriodMonth,
       cv.Id AS ClotheVariant_Id, cv.Sku, c.Name AS ClotheName, sz.Name AS SizeName, co.Name AS ColorName,
       SUM(bd.Quantity) AS UnitsSold, SUM(bd.Total) AS Revenue
FROM dbo.Bill b
JOIN dbo.BillDetails bd   ON bd.Bill_Id = b.Id
JOIN dbo.ClotheVariant cv ON cv.Id = bd.ClotheVariant_Id
JOIN dbo.Clothe c         ON c.Id = cv.Clothe_Id
JOIN dbo.Size sz          ON sz.Id = cv.Size_Id
JOIN dbo.Color co         ON co.Id = cv.Color_Id
WHERE b.Active = 1 AND b.Status IN ('PAID','SHIPPED','DELIVERED')
GROUP BY b.Store_Id, DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1),
         cv.Id, cv.Sku, c.Name, sz.Name, co.Name;
GO

-- Alerta de stock bajo: variantes cuyo stock en la tienda es menor o igual al mínimo definido.
CREATE OR ALTER VIEW dbo.vw_LowStock AS
SELECT ss.Store_Id, st.Name AS StoreName, ss.ClotheVariant_Id, cv.Sku,
       c.Name AS ClotheName, sz.Name AS SizeName, co.Name AS ColorName,
       ss.Quantity, cv.MinStock
FROM dbo.vw_StoreStock ss
JOIN dbo.Store st         ON st.Id = ss.Store_Id
JOIN dbo.ClotheVariant cv ON cv.Id = ss.ClotheVariant_Id
JOIN dbo.Clothe c         ON c.Id = cv.Clothe_Id
JOIN dbo.Size sz          ON sz.Id = cv.Size_Id
JOIN dbo.Color co         ON co.Id = cv.Color_Id
WHERE cv.Active = 1 AND ss.Quantity <= cv.MinStock;
GO

-- Ventas por canal (tienda física vs en línea) por tienda y mes.
CREATE OR ALTER VIEW dbo.vw_SalesByChannel AS
SELECT b.Store_Id,
       DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1) AS PeriodMonth,
       b.Channel, COUNT(*) AS BillCount, SUM(b.Total) AS Total
FROM dbo.Bill b
WHERE b.Active = 1 AND b.Status IN ('PAID','SHIPPED','DELIVERED')
GROUP BY b.Store_Id, DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1), b.Channel;
GO

-- Ingresos por método de pago (efectivo vs tarjeta; respeta los pagos mixtos).
CREATE OR ALTER VIEW dbo.vw_PaymentMethodBreakdown AS
SELECT b.Store_Id,
       DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1) AS PeriodMonth,
       pm.Id AS PaymentMethod_Id, pm.Name AS PaymentMethodName,
       COUNT(*) AS PaymentCount, SUM(bp.PaidAmount) AS PaidTotal
FROM dbo.Bill_has_PaymentMethod bp
JOIN dbo.Bill b           ON b.Id = bp.Bill_Id
JOIN dbo.PaymentMethod pm ON pm.Id = bp.PaymentMethod_Id
WHERE b.Active = 1 AND b.Status IN ('PAID','SHIPPED','DELIVERED')
GROUP BY b.Store_Id, DATEFROMPARTS(YEAR(b.RegistrationDate), MONTH(b.RegistrationDate), 1), pm.Id, pm.Name;
GO

-- Mejores clientes (CRM): total gastado, número de compras y última compra.
CREATE OR ALTER VIEW dbo.vw_TopCustomers AS
WITH spend AS (
    SELECT b.Person_Id, COUNT(*) AS BillCount, SUM(b.Total) AS TotalSpent, MAX(b.RegistrationDate) AS LastPurchaseDate
    FROM dbo.Bill b
    WHERE b.Active = 1 AND b.Status IN ('PAID','SHIPPED','DELIVERED')
    GROUP BY b.Person_Id
)
SELECT sp.Person_Id,
       LTRIM(RTRIM(CONCAT(p.FirstName, N' ', p.FirstSurname))) AS CustomerName,
       sp.BillCount, sp.TotalSpent, sp.LastPurchaseDate,
       RANK() OVER (ORDER BY sp.TotalSpent DESC) AS SpendRank
FROM spend sp
JOIN dbo.Person p ON p.Id = sp.Person_Id;
GO

-- Uso de cupones: veces usado, total descontado y usos restantes (sin contar facturas anuladas).
CREATE OR ALTER VIEW dbo.vw_CouponUsage AS
SELECT cp.Id AS Coupons_Id, cp.Code, cp.Name, cp.StartDate, cp.FinishDate, cp.Active, cp.MaxUses,
       COUNT(b.Id) AS TimesUsed,
       ISNULL(SUM(CASE WHEN b.Id IS NOT NULL THEN bc.AppliedAmount END), 0) AS TotalDiscounted,
       CASE WHEN cp.MaxUses IS NULL THEN NULL ELSE cp.MaxUses - COUNT(b.Id) END AS UsesLeft
FROM dbo.Coupons cp
LEFT JOIN dbo.Bill_has_Coupons bc ON bc.Coupons_Id = cp.Id
LEFT JOIN dbo.Bill b              ON b.Id = bc.Bill_Id AND b.Status <> 'CANCELLED'
GROUP BY cp.Id, cp.Code, cp.Name, cp.StartDate, cp.FinishDate, cp.Active, cp.MaxUses;
GO

-- Impacto de descuentos: líneas de factura afectadas y monto total descontado.
CREATE OR ALTER VIEW dbo.vw_DiscountImpact AS
SELECT d.Id AS Discounts_Id, d.Name, d.Percentage, d.StartDate, d.FinishDate, d.Active,
       COUNT(b.Id) AS LinesAffected,
       ISNULL(SUM(CASE WHEN b.Id IS NOT NULL THEN ad.Amount END), 0) AS TotalDiscounted
FROM dbo.Discounts d
LEFT JOIN dbo.AppliedDiscounts ad ON ad.Discounts_Id = d.Id
LEFT JOIN dbo.BillDetails bd      ON bd.Id = ad.BillDetails_Id
LEFT JOIN dbo.Bill b              ON b.Id = bd.Bill_Id AND b.Status <> 'CANCELLED'
GROUP BY d.Id, d.Name, d.Percentage, d.StartDate, d.FinishDate, d.Active;
GO

-- Resumen de cada turno de caja: ventas en efectivo y con tarjeta, efectivo esperado vs contado.
CREATE OR ALTER VIEW dbo.vw_CashShiftSummary AS
SELECT cs.Id AS CashShift_Id, cr.Store_Id, cr.Id AS CashRegister_Id, cr.Name AS CashRegisterName,
       cs.Employee_Id,
       LTRIM(RTRIM(CONCAT(p.FirstName, N' ', p.FirstSurname))) AS EmployeeName,
       cs.OpenedAt, cs.ClosedAt, cs.Status, cs.OpeningAmount,
       ISNULL(SUM(CASE WHEN pm.RequiresCard = 0 THEN bp.PaidAmount END), 0) AS CashSales,
       ISNULL(SUM(CASE WHEN pm.RequiresCard = 1 THEN bp.PaidAmount END), 0) AS CardSales,
       cs.OpeningAmount + ISNULL(SUM(CASE WHEN pm.RequiresCard = 0 THEN bp.PaidAmount END), 0) AS ExpectedCash,
       cs.ClosingAmount,
       cs.ClosingAmount - (cs.OpeningAmount + ISNULL(SUM(CASE WHEN pm.RequiresCard = 0 THEN bp.PaidAmount END), 0)) AS CashDifference
FROM dbo.CashShift cs
JOIN dbo.CashRegister cr ON cr.Id = cs.CashRegister_Id
JOIN dbo.Employee e      ON e.Id = cs.Employee_Id
JOIN dbo.Person p        ON p.Id = e.Person_Id
LEFT JOIN dbo.Bill b                     ON b.CashShift_Id = cs.Id AND b.Active = 1 AND b.Status IN ('PAID','SHIPPED','DELIVERED')
LEFT JOIN dbo.Bill_has_PaymentMethod bp  ON bp.Bill_Id = b.Id
LEFT JOIN dbo.PaymentMethod pm           ON pm.Id = bp.PaymentMethod_Id
GROUP BY cs.Id, cr.Store_Id, cr.Id, cr.Name, cs.Employee_Id, p.FirstName, p.FirstSurname,
         cs.OpenedAt, cs.ClosedAt, cs.Status, cs.OpeningAmount, cs.ClosingAmount;
GO


-- Permisos de cada rol sobre las VISTAS (se otorgan aquí porque las vistas ya existen)
CREATE TABLE #Grants (RoleName SYSNAME NOT NULL, PermissionName NVARCHAR(10) NOT NULL, ObjectName SYSNAME NOT NULL);
INSERT INTO #Grants (RoleName, PermissionName, ObjectName) VALUES
    (N'role_pedestal_customer', N'SELECT', N'vw_StoreStock'),
    (N'role_pedestal_staff', N'SELECT', N'vw_StoreStock'),
    (N'role_pedestal_staff', N'SELECT', N'vw_LowStock'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_StoreIncome'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_StoreExpenses'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_StoreBalance'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_EmployeeSales'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_EmployeeOfTheMonth'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_SupplierInfo'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_SupplierPurchases'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_SupplierPriceComparison'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_TopSellingProducts'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_StoreAvgProfit'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_StoreExpenseBreakdown'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_InventoryLosses'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_VariantSales'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_SalesByChannel'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_PaymentMethodBreakdown'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_TopCustomers'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_CouponUsage'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_DiscountImpact'),
    (N'role_pedestal_area_manager', N'SELECT', N'vw_AreaStoreBalance'),
    (N'role_pedestal_area_manager', N'SELECT', N'vw_AreaBalance'),
    (N'role_pedestal_area_manager', N'SELECT', N'vw_AreaAvgProfit'),
    (N'role_pedestal_national_manager', N'SELECT', N'vw_CompanyBalance'),
    (N'role_pedestal_national_manager', N'SELECT', N'vw_NationalAreaAvgProfit'),
    (N'role_pedestal_store_supervisor', N'SELECT', N'vw_CashShiftSummary');

DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'GRANT ' + PermissionName + N' ON dbo.' + QUOTENAME(ObjectName) + N' TO ' + QUOTENAME(RoleName) + N';' + NCHAR(10)
FROM #Grants;
EXEC sys.sp_executesql @sql;
DROP TABLE #Grants;
GO

SELECT t.name AS Tabla, SUM(p.rows) AS Filas
FROM sys.tables t
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY Filas;