using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Pedestal.Api.Data.Entities;

namespace Pedestal.Api.Data;

public partial class PedestalDbContext : DbContext
{
    public PedestalDbContext()
    {
    }

    public PedestalDbContext(DbContextOptions<PedestalDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Account> Accounts { get; set; }

    public virtual DbSet<AccountRole> AccountRoles { get; set; }

    public virtual DbSet<AppliedDiscount> AppliedDiscounts { get; set; }

    public virtual DbSet<AppliedTaxis> AppliedTaxes { get; set; }

    public virtual DbSet<AuditLog> AuditLogs { get; set; }

    public virtual DbSet<Batch> Batches { get; set; }

    public virtual DbSet<Bill> Bills { get; set; }

    public virtual DbSet<BillDetail> BillDetails { get; set; }

    public virtual DbSet<BillHasCoupon> BillHasCoupons { get; set; }

    public virtual DbSet<BillHasPaymentMethod> BillHasPaymentMethods { get; set; }

    public virtual DbSet<Cart> Carts { get; set; }

    public virtual DbSet<CartDetail> CartDetails { get; set; }

    public virtual DbSet<CashRegister> CashRegisters { get; set; }

    public virtual DbSet<CashShift> CashShifts { get; set; }

    public virtual DbSet<Clothe> Clothes { get; set; }

    public virtual DbSet<ClotheType> ClotheTypes { get; set; }

    public virtual DbSet<ClotheVariant> ClotheVariants { get; set; }

    public virtual DbSet<ClothesInCubicle> ClothesInCubicles { get; set; }

    public virtual DbSet<Color> Colors { get; set; }

    public virtual DbSet<Coupon> Coupons { get; set; }

    public virtual DbSet<Cubicle> Cubicles { get; set; }

    public virtual DbSet<Direction> Directions { get; set; }

    public virtual DbSet<Discount> Discounts { get; set; }

    public virtual DbSet<DiscountTarget> DiscountTargets { get; set; }

    public virtual DbSet<Employee> Employees { get; set; }

    public virtual DbSet<Expense> Expenses { get; set; }

    public virtual DbSet<ExpenseCategory> ExpenseCategories { get; set; }

    public virtual DbSet<LegalEntity> LegalEntities { get; set; }

    public virtual DbSet<Outfit> Outfits { get; set; }

    public virtual DbSet<PaymentCard> PaymentCards { get; set; }

    public virtual DbSet<PaymentMethod> PaymentMethods { get; set; }

    public virtual DbSet<Payroll> Payrolls { get; set; }

    public virtual DbSet<Permission> Permissions { get; set; }

    public virtual DbSet<Person> People { get; set; }

    public virtual DbSet<Phone> Phones { get; set; }

    public virtual DbSet<Position> Positions { get; set; }

    public virtual DbSet<PositionHistorial> PositionHistorials { get; set; }

    public virtual DbSet<PurchaseOrder> PurchaseOrders { get; set; }

    public virtual DbSet<PurchaseOrderDetail> PurchaseOrderDetails { get; set; }

    public virtual DbSet<Rack> Racks { get; set; }

    public virtual DbSet<Role> Roles { get; set; }

    public virtual DbSet<Shipment> Shipments { get; set; }

    public virtual DbSet<Size> Sizes { get; set; }

    public virtual DbSet<StockMovement> StockMovements { get; set; }

    public virtual DbSet<Store> Stores { get; set; }

    public virtual DbSet<Supplier> Suppliers { get; set; }

    public virtual DbSet<Taxis> Taxes { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<UserClothe> UserClothes { get; set; }

    public virtual DbSet<VwAreaAvgProfit> VwAreaAvgProfits { get; set; }

    public virtual DbSet<VwAreaBalance> VwAreaBalances { get; set; }

    public virtual DbSet<VwAreaStoreBalance> VwAreaStoreBalances { get; set; }

    public virtual DbSet<VwCashShiftSummary> VwCashShiftSummaries { get; set; }

    public virtual DbSet<VwCompanyBalance> VwCompanyBalances { get; set; }

    public virtual DbSet<VwCouponUsage> VwCouponUsages { get; set; }

    public virtual DbSet<VwDiscountImpact> VwDiscountImpacts { get; set; }

    public virtual DbSet<VwEmployeeOfTheMonth> VwEmployeeOfTheMonths { get; set; }

    public virtual DbSet<VwEmployeeSale> VwEmployeeSales { get; set; }

    public virtual DbSet<VwInventoryLoss> VwInventoryLosses { get; set; }

    public virtual DbSet<VwLowStock> VwLowStocks { get; set; }

    public virtual DbSet<VwNationalAreaAvgProfit> VwNationalAreaAvgProfits { get; set; }

    public virtual DbSet<VwPaymentMethodBreakdown> VwPaymentMethodBreakdowns { get; set; }

    public virtual DbSet<VwSalesByChannel> VwSalesByChannels { get; set; }

    public virtual DbSet<VwStoreAvgProfit> VwStoreAvgProfits { get; set; }

    public virtual DbSet<VwStoreBalance> VwStoreBalances { get; set; }

    public virtual DbSet<VwStoreExpense> VwStoreExpenses { get; set; }

    public virtual DbSet<VwStoreExpenseBreakdown> VwStoreExpenseBreakdowns { get; set; }

    public virtual DbSet<VwStoreIncome> VwStoreIncomes { get; set; }

    public virtual DbSet<VwStoreStock> VwStoreStocks { get; set; }

    public virtual DbSet<VwSupplierInfo> VwSupplierInfos { get; set; }

    public virtual DbSet<VwSupplierPriceComparison> VwSupplierPriceComparisons { get; set; }

    public virtual DbSet<VwSupplierPurchase> VwSupplierPurchases { get; set; }

    public virtual DbSet<VwTopCustomer> VwTopCustomers { get; set; }

    public virtual DbSet<VwTopSellingProduct> VwTopSellingProducts { get; set; }

    public virtual DbSet<VwVariantSale> VwVariantSales { get; set; }

    public virtual DbSet<WorkArea> WorkAreas { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Account>(entity =>
        {
            entity.ToTable("Account");

            entity.HasIndex(e => e.PersonId, "UQ_Account_Person").IsUnique();

            entity.HasIndex(e => e.Username, "UQ_Account_Username").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Account_Active");
            entity.Property(e => e.PasswordHash).HasMaxLength(255);
            entity.Property(e => e.PersonId).HasColumnName("Person_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Account_RegistrationDate");
            entity.Property(e => e.Username).HasMaxLength(60);

            entity.HasOne(d => d.Person).WithOne(p => p.Account)
                .HasForeignKey<Account>(d => d.PersonId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Account_Person");
        });

        modelBuilder.Entity<AccountRole>(entity =>
        {
            entity.HasKey(e => new { e.AccountId, e.RoleId });

            entity.ToTable("AccountRole");

            entity.Property(e => e.AccountId).HasColumnName("Account_Id");
            entity.Property(e => e.RoleId).HasColumnName("Role_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_AccountRole_RegistrationDate");

            entity.HasOne(d => d.Account).WithMany(p => p.AccountRoles)
                .HasForeignKey(d => d.AccountId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AccountRole_Account");

            entity.HasOne(d => d.Role).WithMany(p => p.AccountRoles)
                .HasForeignKey(d => d.RoleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AccountRole_Role");
        });

        modelBuilder.Entity<AppliedDiscount>(entity =>
        {
            entity.HasKey(e => new { e.BillDetailsId, e.DiscountsId });

            entity.Property(e => e.BillDetailsId).HasColumnName("BillDetails_Id");
            entity.Property(e => e.DiscountsId).HasColumnName("Discounts_Id");
            entity.Property(e => e.Amount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Percentage).HasColumnType("decimal(5, 2)");

            entity.HasOne(d => d.BillDetails).WithMany(p => p.AppliedDiscounts)
                .HasForeignKey(d => d.BillDetailsId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AppliedDiscounts_Detail");

            entity.HasOne(d => d.Discounts).WithMany(p => p.AppliedDiscounts)
                .HasForeignKey(d => d.DiscountsId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AppliedDiscounts_Discount");
        });

        modelBuilder.Entity<AppliedTaxis>(entity =>
        {
            entity.HasKey(e => new { e.BillDetailsId, e.TaxesId });

            entity.Property(e => e.BillDetailsId).HasColumnName("BillDetails_Id");
            entity.Property(e => e.TaxesId).HasColumnName("Taxes_Id");
            entity.Property(e => e.Amount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Percentage).HasColumnType("decimal(5, 2)");

            entity.HasOne(d => d.BillDetails).WithMany(p => p.AppliedTaxes)
                .HasForeignKey(d => d.BillDetailsId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AppliedTaxes_Detail");

            entity.HasOne(d => d.Taxes).WithMany(p => p.AppliedTaxes)
                .HasForeignKey(d => d.TaxesId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AppliedTaxes_Tax");
        });

        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.ToTable("AuditLog");

            entity.HasIndex(e => e.AccountId, "IX_AuditLog_Account");

            entity.HasIndex(e => e.AuditDate, "IX_AuditLog_Date");

            entity.HasIndex(e => new { e.TableName, e.RecordId }, "IX_AuditLog_Record");

            entity.Property(e => e.AccountId).HasColumnName("Account_Id");
            entity.Property(e => e.ActionType).HasMaxLength(10);
            entity.Property(e => e.AuditDate).HasDefaultValueSql("(sysutcdatetime())", "DF_AuditLog_AuditDate");
            entity.Property(e => e.RecordId).HasMaxLength(50);
            entity.Property(e => e.TableName).HasMaxLength(60);

            entity.HasOne(d => d.Account).WithMany(p => p.AuditLogs)
                .HasForeignKey(d => d.AccountId)
                .HasConstraintName("FK_AuditLog_Account");
        });

        modelBuilder.Entity<Batch>(entity =>
        {
            entity.ToTable("Batch");

            entity.HasIndex(e => e.PurchaseOrderDetailId, "IX_Batch_OrderDetail");

            entity.HasIndex(e => e.BatchNumber, "UQ_Batch_Number").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Batch_Active");
            entity.Property(e => e.BatchNumber).HasMaxLength(45);
            entity.Property(e => e.PurchaseOrderDetailId).HasColumnName("PurchaseOrderDetail_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Batch_RegistrationDate");

            entity.HasOne(d => d.PurchaseOrderDetail).WithMany(p => p.Batches)
                .HasForeignKey(d => d.PurchaseOrderDetailId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Batch_OrderDetail");
        });

        modelBuilder.Entity<Bill>(entity =>
        {
            entity.ToTable("Bill");

            entity.HasIndex(e => e.CashShiftId, "IX_Bill_CashShift");

            entity.HasIndex(e => e.EmployeeId, "IX_Bill_Employee");

            entity.HasIndex(e => e.PersonId, "IX_Bill_Person");

            entity.HasIndex(e => new { e.StoreId, e.RegistrationDate }, "IX_Bill_Store_Date");

            entity.HasIndex(e => e.BillCode, "UQ_Bill_Code").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Bill_Active");
            entity.Property(e => e.BillCode).HasMaxLength(30);
            entity.Property(e => e.CashShiftId).HasColumnName("CashShift_Id");
            entity.Property(e => e.Channel).HasMaxLength(7);
            entity.Property(e => e.CouponTotal).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.DiscountTotal).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.EmployeeId).HasColumnName("Employee_Id");
            entity.Property(e => e.PersonId).HasColumnName("Person_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Bill_RegistrationDate");
            entity.Property(e => e.ShippingTotal).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Status)
                .HasMaxLength(10)
                .HasDefaultValue("PENDING", "DF_Bill_Status");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.SubTotal).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TaxTotal).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Total).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.CashShift).WithMany(p => p.Bills)
                .HasForeignKey(d => d.CashShiftId)
                .HasConstraintName("FK_Bill_CashShift");

            entity.HasOne(d => d.Employee).WithMany(p => p.Bills)
                .HasForeignKey(d => d.EmployeeId)
                .HasConstraintName("FK_Bill_Employee");

            entity.HasOne(d => d.Person).WithMany(p => p.Bills)
                .HasForeignKey(d => d.PersonId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Bill_Person");

            entity.HasOne(d => d.Store).WithMany(p => p.Bills)
                .HasForeignKey(d => d.StoreId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Bill_Store");
        });

        modelBuilder.Entity<BillDetail>(entity =>
        {
            entity.HasIndex(e => e.ClotheVariantId, "IX_BillDetails_Variant");

            entity.HasIndex(e => new { e.BillId, e.ClotheVariantId }, "UQ_BillDetails_Line").IsUnique();

            entity.Property(e => e.BillId).HasColumnName("Bill_Id");
            entity.Property(e => e.ClotheVariantId).HasColumnName("ClotheVariant_Id");
            entity.Property(e => e.DiscountAmount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.SubTotal)
                .HasComputedColumnSql("([Quantity]*[UnitPrice])", true)
                .HasColumnType("decimal(29, 2)");
            entity.Property(e => e.TaxAmount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Total)
                .HasComputedColumnSql("(([Quantity]*[UnitPrice]-[DiscountAmount])+[TaxAmount])", true)
                .HasColumnType("decimal(31, 2)");
            entity.Property(e => e.UnitPrice).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.Bill).WithMany(p => p.BillDetails)
                .HasForeignKey(d => d.BillId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_BillDetails_Bill");

            entity.HasOne(d => d.ClotheVariant).WithMany(p => p.BillDetails)
                .HasForeignKey(d => d.ClotheVariantId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_BillDetails_Variant");
        });

        modelBuilder.Entity<BillHasCoupon>(entity =>
        {
            entity.HasKey(e => new { e.BillId, e.CouponsId });

            entity.ToTable("Bill_has_Coupons");

            entity.Property(e => e.BillId).HasColumnName("Bill_Id");
            entity.Property(e => e.CouponsId).HasColumnName("Coupons_Id");
            entity.Property(e => e.AppliedAmount).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.Bill).WithMany(p => p.BillHasCoupons)
                .HasForeignKey(d => d.BillId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_BillCoupons_Bill");

            entity.HasOne(d => d.Coupons).WithMany(p => p.BillHasCoupons)
                .HasForeignKey(d => d.CouponsId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_BillCoupons_Coupon");
        });

        modelBuilder.Entity<BillHasPaymentMethod>(entity =>
        {
            entity.ToTable("Bill_has_PaymentMethod");

            entity.HasIndex(e => e.BillId, "IX_BillPayment_Bill");

            entity.Property(e => e.BillId).HasColumnName("Bill_Id");
            entity.Property(e => e.PaidAmount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.PaymentCardId).HasColumnName("PaymentCard_Id");
            entity.Property(e => e.PaymentMethodId).HasColumnName("PaymentMethod_Id");
            entity.Property(e => e.PaymentReference).HasMaxLength(60);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Bill_has_PaymentMethod_RegistrationDate");

            entity.HasOne(d => d.Bill).WithMany(p => p.BillHasPaymentMethods)
                .HasForeignKey(d => d.BillId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_BillPayment_Bill");

            entity.HasOne(d => d.PaymentCard).WithMany(p => p.BillHasPaymentMethods)
                .HasForeignKey(d => d.PaymentCardId)
                .HasConstraintName("FK_BillPayment_Card");

            entity.HasOne(d => d.PaymentMethod).WithMany(p => p.BillHasPaymentMethods)
                .HasForeignKey(d => d.PaymentMethodId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_BillPayment_Method");
        });

        modelBuilder.Entity<Cart>(entity =>
        {
            entity.ToTable("Cart");

            entity.HasIndex(e => e.UserId, "UX_Cart_ActivePerUser")
                .IsUnique()
                .HasFilter("([Status]='ACTIVE')");

            entity.Property(e => e.BillId).HasColumnName("Bill_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Cart_RegistrationDate");
            entity.Property(e => e.Status)
                .HasMaxLength(10)
                .HasDefaultValue("ACTIVE", "DF_Cart_Status");
            entity.Property(e => e.UserId).HasColumnName("User_Id");

            entity.HasOne(d => d.Bill).WithMany(p => p.Carts)
                .HasForeignKey(d => d.BillId)
                .HasConstraintName("FK_Cart_Bill");

            entity.HasOne(d => d.User).WithOne(p => p.Cart)
                .HasForeignKey<Cart>(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cart_User");
        });

        modelBuilder.Entity<CartDetail>(entity =>
        {
            entity.ToTable("CartDetail");

            entity.HasIndex(e => new { e.CartId, e.ClotheVariantId }, "UQ_CartDetail_Line").IsUnique();

            entity.Property(e => e.AddedDate).HasDefaultValueSql("(sysutcdatetime())", "DF_CartDetail_AddedDate");
            entity.Property(e => e.CartId).HasColumnName("Cart_Id");
            entity.Property(e => e.ClotheVariantId).HasColumnName("ClotheVariant_Id");

            entity.HasOne(d => d.Cart).WithMany(p => p.CartDetails)
                .HasForeignKey(d => d.CartId)
                .HasConstraintName("FK_CartDetail_Cart");

            entity.HasOne(d => d.ClotheVariant).WithMany(p => p.CartDetails)
                .HasForeignKey(d => d.ClotheVariantId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CartDetail_Variant");
        });

        modelBuilder.Entity<CashRegister>(entity =>
        {
            entity.ToTable("CashRegister");

            entity.HasIndex(e => new { e.StoreId, e.Name }, "UQ_CashRegister_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_CashRegister_Active");
            entity.Property(e => e.Description).HasMaxLength(100);
            entity.Property(e => e.Name).HasMaxLength(45);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_CashRegister_RegistrationDate");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");

            entity.HasOne(d => d.Store).WithMany(p => p.CashRegisters)
                .HasForeignKey(d => d.StoreId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CashRegister_Store");
        });

        modelBuilder.Entity<CashShift>(entity =>
        {
            entity.ToTable("CashShift");

            entity.HasIndex(e => e.EmployeeId, "UX_CashShift_OpenPerEmployee")
                .IsUnique()
                .HasFilter("([Status]='OPEN')");

            entity.HasIndex(e => e.CashRegisterId, "UX_CashShift_OpenPerRegister")
                .IsUnique()
                .HasFilter("([Status]='OPEN')");

            entity.Property(e => e.CashRegisterId).HasColumnName("CashRegister_Id");
            entity.Property(e => e.ClosingAmount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.EmployeeId).HasColumnName("Employee_Id");
            entity.Property(e => e.OpenedAt).HasDefaultValueSql("(sysutcdatetime())", "DF_CashShift_OpenedAt");
            entity.Property(e => e.OpeningAmount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Status)
                .HasMaxLength(6)
                .HasDefaultValue("OPEN", "DF_CashShift_Status");

            entity.HasOne(d => d.CashRegister).WithOne(p => p.CashShift)
                .HasForeignKey<CashShift>(d => d.CashRegisterId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CashShift_Register");

            entity.HasOne(d => d.Employee).WithOne(p => p.CashShift)
                .HasForeignKey<CashShift>(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CashShift_Employee");
        });

        modelBuilder.Entity<Clothe>(entity =>
        {
            entity.ToTable("Clothe");

            entity.HasIndex(e => e.ClotheTypeId, "IX_Clothe_Type");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Clothe_Active");
            entity.Property(e => e.BasePrice).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Brand).HasMaxLength(45);
            entity.Property(e => e.ClotheTypeId).HasColumnName("ClotheType_Id");
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.ImageFileId).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(60);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Clothe_RegistrationDate");

            entity.HasOne(d => d.ClotheType).WithMany(p => p.Clothes)
                .HasForeignKey(d => d.ClotheTypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Clothe_ClotheType");
        });

        modelBuilder.Entity<ClotheType>(entity =>
        {
            entity.ToTable("ClotheType");

            entity.HasIndex(e => e.Name, "UQ_ClotheType_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_ClotheType_Active");
            entity.Property(e => e.Description).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(45);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_ClotheType_RegistrationDate");
        });

        modelBuilder.Entity<ClotheVariant>(entity =>
        {
            entity.ToTable("ClotheVariant");

            entity.HasIndex(e => new { e.ClotheId, e.SizeId, e.ColorId }, "UQ_ClotheVariant_Combo").IsUnique();

            entity.HasIndex(e => e.Sku, "UQ_ClotheVariant_Sku").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_ClotheVariant_Active");
            entity.Property(e => e.ClotheId).HasColumnName("Clothe_Id");
            entity.Property(e => e.ColorId).HasColumnName("Color_Id");
            entity.Property(e => e.PriceOverride).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_ClotheVariant_RegistrationDate");
            entity.Property(e => e.SizeId).HasColumnName("Size_Id");
            entity.Property(e => e.Sku).HasMaxLength(40);

            entity.HasOne(d => d.Clothe).WithMany(p => p.ClotheVariants)
                .HasForeignKey(d => d.ClotheId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ClotheVariant_Clothe");

            entity.HasOne(d => d.Color).WithMany(p => p.ClotheVariants)
                .HasForeignKey(d => d.ColorId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ClotheVariant_Color");

            entity.HasOne(d => d.Size).WithMany(p => p.ClotheVariants)
                .HasForeignKey(d => d.SizeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ClotheVariant_Size");
        });

        modelBuilder.Entity<ClothesInCubicle>(entity =>
        {
            entity.HasKey(e => new { e.CubicleId, e.ClotheVariantId });

            entity.ToTable("ClothesInCubicle");

            entity.HasIndex(e => e.ClotheVariantId, "IX_ClothesInCubicle_Variant");

            entity.Property(e => e.CubicleId).HasColumnName("Cubicle_Id");
            entity.Property(e => e.ClotheVariantId).HasColumnName("ClotheVariant_Id");

            entity.HasOne(d => d.ClotheVariant).WithMany(p => p.ClothesInCubicles)
                .HasForeignKey(d => d.ClotheVariantId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ClothesInCubicle_Variant");

            entity.HasOne(d => d.Cubicle).WithMany(p => p.ClothesInCubicles)
                .HasForeignKey(d => d.CubicleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ClothesInCubicle_Cubicle");
        });

        modelBuilder.Entity<Color>(entity =>
        {
            entity.ToTable("Color");

            entity.HasIndex(e => e.Name, "UQ_Color_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Color_Active");
            entity.Property(e => e.HexCode)
                .HasMaxLength(7)
                .IsUnicode(false)
                .IsFixedLength();
            entity.Property(e => e.Name).HasMaxLength(30);
        });

        modelBuilder.Entity<Coupon>(entity =>
        {
            entity.HasIndex(e => e.Code, "UQ_Coupons_Code").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Coupons_Active");
            entity.Property(e => e.Amount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Code).HasMaxLength(30);
            entity.Property(e => e.DiscountKind)
                .HasMaxLength(1)
                .IsUnicode(false)
                .IsFixedLength();
            entity.Property(e => e.MinPurchaseAmount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Name).HasMaxLength(60);
            entity.Property(e => e.Percentage).HasColumnType("decimal(5, 2)");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Coupons_RegistrationDate");
        });

        modelBuilder.Entity<Cubicle>(entity =>
        {
            entity.ToTable("Cubicle");

            entity.HasIndex(e => new { e.RackId, e.CubicleNumber }, "UQ_Cubicle_Number").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Cubicle_Active");
            entity.Property(e => e.CubicleNumber).HasMaxLength(45);
            entity.Property(e => e.Description).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(45);
            entity.Property(e => e.RackId).HasColumnName("Rack_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Cubicle_RegistrationDate");

            entity.HasOne(d => d.Rack).WithMany(p => p.Cubicles)
                .HasForeignKey(d => d.RackId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cubicle_Rack");
        });

        modelBuilder.Entity<Direction>(entity =>
        {
            entity.HasIndex(e => e.PersonId, "IX_Directions_Person");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Directions_Active");
            entity.Property(e => e.City).HasMaxLength(60);
            entity.Property(e => e.Direction1)
                .HasMaxLength(200)
                .HasColumnName("Direction");
            entity.Property(e => e.DirectionType)
                .HasMaxLength(10)
                .HasDefaultValue("HOME", "DF_Directions_DirectionType");
            entity.Property(e => e.LegalEntityId).HasColumnName("LegalEntity_Id");
            entity.Property(e => e.PersonId).HasColumnName("Person_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Directions_RegistrationDate");

            entity.HasOne(d => d.LegalEntity).WithMany(p => p.Directions)
                .HasForeignKey(d => d.LegalEntityId)
                .HasConstraintName("FK_Directions_LegalEntity");

            entity.HasOne(d => d.Person).WithMany(p => p.Directions)
                .HasForeignKey(d => d.PersonId)
                .HasConstraintName("FK_Directions_Person");
        });

        modelBuilder.Entity<Discount>(entity =>
        {
            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Discounts_Active");
            entity.Property(e => e.Name).HasMaxLength(60);
            entity.Property(e => e.Percentage).HasColumnType("decimal(5, 2)");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Discounts_RegistrationDate");
        });

        modelBuilder.Entity<DiscountTarget>(entity =>
        {
            entity.ToTable("DiscountTarget");

            entity.HasIndex(e => e.DiscountId, "IX_DiscountTarget_Discount");

            entity.Property(e => e.ClotheId).HasColumnName("Clothe_Id");
            entity.Property(e => e.ClotheTypeId).HasColumnName("ClotheType_Id");
            entity.Property(e => e.DiscountId).HasColumnName("Discount_Id");

            entity.HasOne(d => d.Clothe).WithMany(p => p.DiscountTargets)
                .HasForeignKey(d => d.ClotheId)
                .HasConstraintName("FK_DiscountTarget_Clothe");

            entity.HasOne(d => d.ClotheType).WithMany(p => p.DiscountTargets)
                .HasForeignKey(d => d.ClotheTypeId)
                .HasConstraintName("FK_DiscountTarget_Type");

            entity.HasOne(d => d.Discount).WithMany(p => p.DiscountTargets)
                .HasForeignKey(d => d.DiscountId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_DiscountTarget_Discount");
        });

        modelBuilder.Entity<Employee>(entity =>
        {
            entity.ToTable("Employee");

            entity.HasIndex(e => e.PersonId, "UQ_Employee_Person").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Employee_Active");
            entity.Property(e => e.HireDate).HasDefaultValueSql("(CONVERT([date],sysutcdatetime()))", "DF_Employee_HireDate");
            entity.Property(e => e.PersonId).HasColumnName("Person_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Employee_RegistrationDate");
            entity.Property(e => e.Salary).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.Person).WithOne(p => p.Employee)
                .HasForeignKey<Employee>(d => d.PersonId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Employee_Person");
        });

        modelBuilder.Entity<Expense>(entity =>
        {
            entity.ToTable("Expense");

            entity.HasIndex(e => new { e.StoreId, e.ExpenseDate }, "IX_Expense_Store_Date");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Expense_Active");
            entity.Property(e => e.Amount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Description).HasMaxLength(200);
            entity.Property(e => e.EmployeeId).HasColumnName("Employee_Id");
            entity.Property(e => e.ExpenseCategoryId).HasColumnName("ExpenseCategory_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Expense_RegistrationDate");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");

            entity.HasOne(d => d.Employee).WithMany(p => p.Expenses)
                .HasForeignKey(d => d.EmployeeId)
                .HasConstraintName("FK_Expense_Employee");

            entity.HasOne(d => d.ExpenseCategory).WithMany(p => p.Expenses)
                .HasForeignKey(d => d.ExpenseCategoryId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Expense_Category");

            entity.HasOne(d => d.Store).WithMany(p => p.Expenses)
                .HasForeignKey(d => d.StoreId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Expense_Store");
        });

        modelBuilder.Entity<ExpenseCategory>(entity =>
        {
            entity.ToTable("ExpenseCategory");

            entity.HasIndex(e => e.Name, "UQ_ExpenseCategory_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_ExpenseCategory_Active");
            entity.Property(e => e.Description).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(60);
        });

        modelBuilder.Entity<LegalEntity>(entity =>
        {
            entity.ToTable("LegalEntity");

            entity.HasIndex(e => e.TaxId, "UX_LegalEntity_TaxId")
                .IsUnique()
                .HasFilter("([TaxId] IS NOT NULL)");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_LegalEntity_Active");
            entity.Property(e => e.BusinessName).HasMaxLength(100);
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_LegalEntity_RegistrationDate");
            entity.Property(e => e.TaxId).HasMaxLength(30);
            entity.Property(e => e.TradeName).HasMaxLength(100);
        });

        modelBuilder.Entity<Outfit>(entity =>
        {
            entity.ToTable("Outfit");

            entity.HasIndex(e => e.UserId, "IX_Outfit_User");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Outfit_Active");
            entity.Property(e => e.Description).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(60);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Outfit_RegistrationDate");
            entity.Property(e => e.UserId).HasColumnName("User_Id");

            entity.HasOne(d => d.User).WithMany(p => p.Outfits)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Outfit_User");

            entity.HasMany(d => d.UserClothes).WithMany(p => p.Outfits)
                .UsingEntity<Dictionary<string, object>>(
                    "OutfitHasUserClothe",
                    r => r.HasOne<UserClothe>().WithMany()
                        .HasForeignKey("UserClothesId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_OutfitClothes_Clothes"),
                    l => l.HasOne<Outfit>().WithMany()
                        .HasForeignKey("OutfitId")
                        .HasConstraintName("FK_OutfitClothes_Outfit"),
                    j =>
                    {
                        j.HasKey("OutfitId", "UserClothesId");
                        j.ToTable("Outfit_has_UserClothes");
                        j.IndexerProperty<int>("OutfitId").HasColumnName("Outfit_Id");
                        j.IndexerProperty<int>("UserClothesId").HasColumnName("UserClothes_Id");
                    });
        });

        modelBuilder.Entity<PaymentCard>(entity =>
        {
            entity.ToTable("PaymentCard");

            entity.HasIndex(e => e.UserId, "IX_PaymentCard_User");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_PaymentCard_Active");
            entity.Property(e => e.Brand).HasMaxLength(30);
            entity.Property(e => e.CardType).HasMaxLength(6);
            entity.Property(e => e.HolderName).HasMaxLength(60);
            entity.Property(e => e.Last4)
                .HasMaxLength(4)
                .IsUnicode(false)
                .IsFixedLength();
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_PaymentCard_RegistrationDate");
            entity.Property(e => e.UserId).HasColumnName("User_Id");

            entity.HasOne(d => d.User).WithMany(p => p.PaymentCards)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PaymentCard_User");
        });

        modelBuilder.Entity<PaymentMethod>(entity =>
        {
            entity.ToTable("PaymentMethod");

            entity.HasIndex(e => e.Name, "UQ_PaymentMethod_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_PaymentMethod_Active");
            entity.Property(e => e.AllowedInStore).HasDefaultValue(true, "DF_PaymentMethod_AllowedInStore");
            entity.Property(e => e.ApplyDiscounts).HasDefaultValue(true, "DF_PaymentMethod_ApplyDiscounts");
            entity.Property(e => e.Name).HasMaxLength(45);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_PaymentMethod_RegistrationDate");
        });

        modelBuilder.Entity<Payroll>(entity =>
        {
            entity.ToTable("Payroll");

            entity.HasIndex(e => new { e.StoreId, e.PeriodEnd }, "IX_Payroll_Store_Period");

            entity.HasIndex(e => new { e.EmployeeId, e.PeriodStart, e.PeriodEnd }, "UQ_Payroll_Period").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Payroll_Active");
            entity.Property(e => e.Deductions).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.EmployeeId).HasColumnName("Employee_Id");
            entity.Property(e => e.GrossAmount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.NetAmount)
                .HasComputedColumnSql("([GrossAmount]-[Deductions])", true)
                .HasColumnType("decimal(19, 2)");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Payroll_RegistrationDate");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");

            entity.HasOne(d => d.Employee).WithMany(p => p.Payrolls)
                .HasForeignKey(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Payroll_Employee");

            entity.HasOne(d => d.Store).WithMany(p => p.Payrolls)
                .HasForeignKey(d => d.StoreId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Payroll_Store");
        });

        modelBuilder.Entity<Permission>(entity =>
        {
            entity.ToTable("Permission");

            entity.HasIndex(e => e.Code, "UQ_Permission_Code").IsUnique();

            entity.Property(e => e.ActionType).HasMaxLength(10);
            entity.Property(e => e.Code).HasMaxLength(60);
            entity.Property(e => e.Module).HasMaxLength(30);
        });

        modelBuilder.Entity<Person>(entity =>
        {
            entity.ToTable("Person");

            entity.HasIndex(e => e.DocumentId, "UX_Person_DocumentId")
                .IsUnique()
                .HasFilter("([DocumentId] IS NOT NULL)");

            entity.HasIndex(e => e.Email, "UX_Person_Email")
                .IsUnique()
                .HasFilter("([Email] IS NOT NULL)");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Person_Active");
            entity.Property(e => e.DocumentId).HasMaxLength(30);
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.FirstName).HasMaxLength(45);
            entity.Property(e => e.FirstSurname).HasMaxLength(45);
            entity.Property(e => e.MiddleName).HasMaxLength(45);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Person_RegistrationDate");
            entity.Property(e => e.SecondSurname).HasMaxLength(45);
        });

        modelBuilder.Entity<Phone>(entity =>
        {
            entity.HasIndex(e => e.LegalEntityId, "IX_Phones_LegalEntity");

            entity.HasIndex(e => e.PersonId, "IX_Phones_Person");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Phones_Active");
            entity.Property(e => e.LegalEntityId).HasColumnName("LegalEntity_Id");
            entity.Property(e => e.PersonId).HasColumnName("Person_Id");
            entity.Property(e => e.Phone1)
                .HasMaxLength(20)
                .HasColumnName("Phone");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Phones_RegistrationDate");

            entity.HasOne(d => d.LegalEntity).WithMany(p => p.Phones)
                .HasForeignKey(d => d.LegalEntityId)
                .HasConstraintName("FK_Phones_LegalEntity");

            entity.HasOne(d => d.Person).WithMany(p => p.Phones)
                .HasForeignKey(d => d.PersonId)
                .HasConstraintName("FK_Phones_Person");
        });

        modelBuilder.Entity<Position>(entity =>
        {
            entity.ToTable("Position");

            entity.HasIndex(e => e.Name, "UQ_Position_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Position_Active");
            entity.Property(e => e.Description).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(45);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Position_RegistrationDate");
            entity.Property(e => e.RoleId).HasColumnName("Role_Id");

            entity.HasOne(d => d.Role).WithMany(p => p.Positions)
                .HasForeignKey(d => d.RoleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Position_Role");
        });

        modelBuilder.Entity<PositionHistorial>(entity =>
        {
            entity.ToTable("PositionHistorial");

            entity.HasIndex(e => e.WorkAreaId, "IX_PositionHistorial_Area");

            entity.HasIndex(e => e.EmployeeId, "IX_PositionHistorial_Employee");

            entity.HasIndex(e => e.StoreId, "IX_PositionHistorial_Store");

            entity.HasIndex(e => e.EmployeeId, "UX_PositionHistorial_Current")
                .IsUnique()
                .HasFilter("([LastDate] IS NULL)");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_PositionHistorial_Active");
            entity.Property(e => e.EmployeeId).HasColumnName("Employee_Id");
            entity.Property(e => e.PositionId).HasColumnName("Position_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_PositionHistorial_RegistrationDate");
            entity.Property(e => e.Salary).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.WorkAreaId).HasColumnName("WorkArea_Id");

            entity.HasOne(d => d.Employee).WithOne(p => p.PositionHistorial)
                .HasForeignKey<PositionHistorial>(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PositionHistorial_Employee");

            entity.HasOne(d => d.Position).WithMany(p => p.PositionHistorials)
                .HasForeignKey(d => d.PositionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PositionHistorial_Position");

            entity.HasOne(d => d.Store).WithMany(p => p.PositionHistorials)
                .HasForeignKey(d => d.StoreId)
                .HasConstraintName("FK_PositionHistorial_Store");

            entity.HasOne(d => d.WorkArea).WithMany(p => p.PositionHistorials)
                .HasForeignKey(d => d.WorkAreaId)
                .HasConstraintName("FK_PositionHistorial_WorkArea");
        });

        modelBuilder.Entity<PurchaseOrder>(entity =>
        {
            entity.ToTable("PurchaseOrder");

            entity.HasIndex(e => new { e.StoreId, e.ReceivedDate }, "IX_PurchaseOrder_Store");

            entity.HasIndex(e => e.SupplierId, "IX_PurchaseOrder_Supplier");

            entity.HasIndex(e => e.OrderNumber, "UQ_PurchaseOrder_Number").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_PurchaseOrder_Active");
            entity.Property(e => e.EmployeeId).HasColumnName("Employee_Id");
            entity.Property(e => e.Notes).HasMaxLength(300);
            entity.Property(e => e.OrderDate).HasDefaultValueSql("(CONVERT([date],sysutcdatetime()))", "DF_PurchaseOrder_OrderDate");
            entity.Property(e => e.OrderNumber).HasMaxLength(30);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_PurchaseOrder_RegistrationDate");
            entity.Property(e => e.Status)
                .HasMaxLength(10)
                .HasDefaultValue("DRAFT", "DF_PurchaseOrder_Status");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.SupplierId).HasColumnName("Supplier_Id");
            entity.Property(e => e.Total).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.Employee).WithMany(p => p.PurchaseOrders)
                .HasForeignKey(d => d.EmployeeId)
                .HasConstraintName("FK_PurchaseOrder_Employee");

            entity.HasOne(d => d.Store).WithMany(p => p.PurchaseOrders)
                .HasForeignKey(d => d.StoreId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PurchaseOrder_Store");

            entity.HasOne(d => d.Supplier).WithMany(p => p.PurchaseOrders)
                .HasForeignKey(d => d.SupplierId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PurchaseOrder_Supplier");
        });

        modelBuilder.Entity<PurchaseOrderDetail>(entity =>
        {
            entity.ToTable("PurchaseOrderDetail");

            entity.HasIndex(e => new { e.PurchaseOrderId, e.ClotheVariantId }, "UQ_PurchaseOrderDetail_Line").IsUnique();

            entity.Property(e => e.ClotheVariantId).HasColumnName("ClotheVariant_Id");
            entity.Property(e => e.PurchaseOrderId).HasColumnName("PurchaseOrder_Id");
            entity.Property(e => e.SubTotal)
                .HasComputedColumnSql("([Quantity]*[UnitCost])", true)
                .HasColumnType("decimal(29, 2)");
            entity.Property(e => e.UnitCost).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.ClotheVariant).WithMany(p => p.PurchaseOrderDetails)
                .HasForeignKey(d => d.ClotheVariantId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PurchaseOrderDetail_Variant");

            entity.HasOne(d => d.PurchaseOrder).WithMany(p => p.PurchaseOrderDetails)
                .HasForeignKey(d => d.PurchaseOrderId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PurchaseOrderDetail_Order");
        });

        modelBuilder.Entity<Rack>(entity =>
        {
            entity.ToTable("Rack");

            entity.HasIndex(e => new { e.StoreId, e.RackNumber }, "UQ_Rack_Number").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Rack_Active");
            entity.Property(e => e.Description).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(45);
            entity.Property(e => e.RackNumber).HasMaxLength(45);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Rack_RegistrationDate");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.Zone)
                .HasMaxLength(10)
                .HasDefaultValue("WAREHOUSE", "DF_Rack_Zone");

            entity.HasOne(d => d.Store).WithMany(p => p.Racks)
                .HasForeignKey(d => d.StoreId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Rack_Store");
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.ToTable("Role");

            entity.HasIndex(e => e.Name, "UQ_Role_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Role_Active");
            entity.Property(e => e.Description).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(45);
            entity.Property(e => e.ScopeType).HasMaxLength(10);

            entity.HasMany(d => d.Permissions).WithMany(p => p.Roles)
                .UsingEntity<Dictionary<string, object>>(
                    "RolePermission",
                    r => r.HasOne<Permission>().WithMany()
                        .HasForeignKey("PermissionId")
                        .HasConstraintName("FK_RolePermission_Permission"),
                    l => l.HasOne<Role>().WithMany()
                        .HasForeignKey("RoleId")
                        .HasConstraintName("FK_RolePermission_Role"),
                    j =>
                    {
                        j.HasKey("RoleId", "PermissionId");
                        j.ToTable("RolePermission");
                        j.IndexerProperty<int>("RoleId").HasColumnName("Role_Id");
                        j.IndexerProperty<int>("PermissionId").HasColumnName("Permission_Id");
                    });
        });

        modelBuilder.Entity<Shipment>(entity =>
        {
            entity.ToTable("Shipment");

            entity.HasIndex(e => e.BillId, "UQ_Shipment_Bill").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Shipment_Active");
            entity.Property(e => e.BillId).HasColumnName("Bill_Id");
            entity.Property(e => e.Carrier).HasMaxLength(45);
            entity.Property(e => e.DirectionId).HasColumnName("Direction_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Shipment_RegistrationDate");
            entity.Property(e => e.ShippingCost).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Status)
                .HasMaxLength(10)
                .HasDefaultValue("PREPARING", "DF_Shipment_Status");
            entity.Property(e => e.TrackingNumber).HasMaxLength(45);

            entity.HasOne(d => d.Bill).WithOne(p => p.Shipment)
                .HasForeignKey<Shipment>(d => d.BillId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Shipment_Bill");

            entity.HasOne(d => d.Direction).WithMany(p => p.Shipments)
                .HasForeignKey(d => d.DirectionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Shipment_Direction");
        });

        modelBuilder.Entity<Size>(entity =>
        {
            entity.ToTable("Size");

            entity.HasIndex(e => e.Name, "UQ_Size_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Size_Active");
            entity.Property(e => e.Name).HasMaxLength(10);
        });

        modelBuilder.Entity<StockMovement>(entity =>
        {
            entity.ToTable("StockMovement");

            entity.HasIndex(e => e.FromStoreId, "IX_StockMovement_FromStore");

            entity.HasIndex(e => e.ToStoreId, "IX_StockMovement_ToStore");

            entity.HasIndex(e => e.ClotheVariantId, "IX_StockMovement_Variant");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_StockMovement_Active");
            entity.Property(e => e.BatchId).HasColumnName("Batch_Id");
            entity.Property(e => e.BillDetailsId).HasColumnName("BillDetails_Id");
            entity.Property(e => e.ClotheVariantId).HasColumnName("ClotheVariant_Id");
            entity.Property(e => e.EmployeeId).HasColumnName("Employee_Id");
            entity.Property(e => e.FromCubicleId).HasColumnName("FromCubicle_Id");
            entity.Property(e => e.FromStoreId).HasColumnName("FromStore_Id");
            entity.Property(e => e.MovementType).HasMaxLength(8);
            entity.Property(e => e.Reason).HasMaxLength(200);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_StockMovement_RegistrationDate");
            entity.Property(e => e.ToCubicleId).HasColumnName("ToCubicle_Id");
            entity.Property(e => e.ToStoreId).HasColumnName("ToStore_Id");

            entity.HasOne(d => d.Batch).WithMany(p => p.StockMovements)
                .HasForeignKey(d => d.BatchId)
                .HasConstraintName("FK_StockMovement_Batch");

            entity.HasOne(d => d.BillDetails).WithMany(p => p.StockMovements)
                .HasForeignKey(d => d.BillDetailsId)
                .HasConstraintName("FK_StockMovement_BillDetails");

            entity.HasOne(d => d.ClotheVariant).WithMany(p => p.StockMovements)
                .HasForeignKey(d => d.ClotheVariantId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_StockMovement_Variant");

            entity.HasOne(d => d.Employee).WithMany(p => p.StockMovements)
                .HasForeignKey(d => d.EmployeeId)
                .HasConstraintName("FK_StockMovement_Employee");

            entity.HasOne(d => d.FromCubicle).WithMany(p => p.StockMovementFromCubicles)
                .HasForeignKey(d => d.FromCubicleId)
                .HasConstraintName("FK_StockMovement_FromCubicle");

            entity.HasOne(d => d.FromStore).WithMany(p => p.StockMovementFromStores)
                .HasForeignKey(d => d.FromStoreId)
                .HasConstraintName("FK_StockMovement_FromStore");

            entity.HasOne(d => d.ToCubicle).WithMany(p => p.StockMovementToCubicles)
                .HasForeignKey(d => d.ToCubicleId)
                .HasConstraintName("FK_StockMovement_ToCubicle");

            entity.HasOne(d => d.ToStore).WithMany(p => p.StockMovementToStores)
                .HasForeignKey(d => d.ToStoreId)
                .HasConstraintName("FK_StockMovement_ToStore");
        });

        modelBuilder.Entity<Store>(entity =>
        {
            entity.ToTable("Store");

            entity.HasIndex(e => e.WorkAreaId, "IX_Store_WorkArea");

            entity.HasIndex(e => e.Name, "UQ_Store_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Store_Active");
            entity.Property(e => e.Direction).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(60);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Store_RegistrationDate");
            entity.Property(e => e.StoreType)
                .HasMaxLength(10)
                .HasDefaultValue("PHYSICAL", "DF_Store_StoreType");
            entity.Property(e => e.WorkAreaId).HasColumnName("WorkArea_Id");

            entity.HasOne(d => d.WorkArea).WithMany(p => p.Stores)
                .HasForeignKey(d => d.WorkAreaId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Store_WorkArea");
        });

        modelBuilder.Entity<Supplier>(entity =>
        {
            entity.ToTable("Supplier");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Supplier_Active");
            entity.Property(e => e.LegalEntityId).HasColumnName("LegalEntity_Id");
            entity.Property(e => e.PersonId).HasColumnName("Person_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Supplier_RegistrationDate");
            entity.Property(e => e.SupplierType)
                .HasMaxLength(1)
                .IsUnicode(false)
                .IsFixedLength();

            entity.HasOne(d => d.LegalEntity).WithMany(p => p.Suppliers)
                .HasForeignKey(d => d.LegalEntityId)
                .HasConstraintName("FK_Supplier_LegalEntity");

            entity.HasOne(d => d.Person).WithMany(p => p.Suppliers)
                .HasForeignKey(d => d.PersonId)
                .HasConstraintName("FK_Supplier_Person");
        });

        modelBuilder.Entity<Taxis>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_Taxes_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_Taxes_Active");
            entity.Property(e => e.Name).HasMaxLength(45);
            entity.Property(e => e.Percentage).HasColumnType("decimal(5, 2)");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_Taxes_RegistrationDate");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("User");

            entity.HasIndex(e => e.PersonId, "UQ_User_Person").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_User_Active");
            entity.Property(e => e.PersonId).HasColumnName("Person_Id");
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_User_RegistrationDate");

            entity.HasOne(d => d.Person).WithOne(p => p.User)
                .HasForeignKey<User>(d => d.PersonId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_User_Person");
        });

        modelBuilder.Entity<UserClothe>(entity =>
        {
            entity.HasIndex(e => e.UserId, "IX_UserClothes_User");

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_UserClothes_Active");
            entity.Property(e => e.ClotheTypeId).HasColumnName("ClotheType_Id");
            entity.Property(e => e.ClotheVariantId).HasColumnName("ClotheVariant_Id");
            entity.Property(e => e.ImageFileId).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(60);
            entity.Property(e => e.Origin).HasMaxLength(9);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_UserClothes_RegistrationDate");
            entity.Property(e => e.UserId).HasColumnName("User_Id");

            entity.HasOne(d => d.ClotheType).WithMany(p => p.UserClothes)
                .HasForeignKey(d => d.ClotheTypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_UserClothes_Type");

            entity.HasOne(d => d.ClotheVariant).WithMany(p => p.UserClothes)
                .HasForeignKey(d => d.ClotheVariantId)
                .HasConstraintName("FK_UserClothes_Variant");

            entity.HasOne(d => d.User).WithMany(p => p.UserClothes)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_UserClothes_User");
        });

        modelBuilder.Entity<VwAreaAvgProfit>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_AreaAvgProfit");

            entity.Property(e => e.AreaName).HasMaxLength(45);
            entity.Property(e => e.AvgMonthlyProfit).HasColumnType("decimal(38, 6)");
            entity.Property(e => e.AvgMonthlyProfitPerStore).HasColumnType("decimal(38, 6)");
            entity.Property(e => e.WorkAreaId).HasColumnName("WorkArea_Id");
        });

        modelBuilder.Entity<VwAreaBalance>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_AreaBalance");

            entity.Property(e => e.AreaName).HasMaxLength(45);
            entity.Property(e => e.Expenses).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.Income).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.Profit).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.WorkAreaId).HasColumnName("WorkArea_Id");
        });

        modelBuilder.Entity<VwAreaStoreBalance>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_AreaStoreBalance");

            entity.Property(e => e.AreaName).HasMaxLength(45);
            entity.Property(e => e.Expenses).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.Income).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.Profit).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.StoreName).HasMaxLength(60);
            entity.Property(e => e.WorkAreaId).HasColumnName("WorkArea_Id");
        });

        modelBuilder.Entity<VwCashShiftSummary>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_CashShiftSummary");

            entity.Property(e => e.CardSales).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.CashDifference).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.CashRegisterId).HasColumnName("CashRegister_Id");
            entity.Property(e => e.CashRegisterName).HasMaxLength(45);
            entity.Property(e => e.CashSales).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.CashShiftId).HasColumnName("CashShift_Id");
            entity.Property(e => e.ClosingAmount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.EmployeeId).HasColumnName("Employee_Id");
            entity.Property(e => e.EmployeeName).HasMaxLength(91);
            entity.Property(e => e.ExpectedCash).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.OpeningAmount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Status).HasMaxLength(6);
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
        });

        modelBuilder.Entity<VwCompanyBalance>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_CompanyBalance");

            entity.Property(e => e.Expenses).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.Income).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.Profit).HasColumnType("decimal(38, 2)");
        });

        modelBuilder.Entity<VwCouponUsage>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_CouponUsage");

            entity.Property(e => e.Code).HasMaxLength(30);
            entity.Property(e => e.CouponsId).HasColumnName("Coupons_Id");
            entity.Property(e => e.Name).HasMaxLength(60);
            entity.Property(e => e.TotalDiscounted).HasColumnType("decimal(38, 2)");
        });

        modelBuilder.Entity<VwDiscountImpact>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_DiscountImpact");

            entity.Property(e => e.DiscountsId).HasColumnName("Discounts_Id");
            entity.Property(e => e.Name).HasMaxLength(60);
            entity.Property(e => e.Percentage).HasColumnType("decimal(5, 2)");
            entity.Property(e => e.TotalDiscounted).HasColumnType("decimal(38, 2)");
        });

        modelBuilder.Entity<VwEmployeeOfTheMonth>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_EmployeeOfTheMonth");

            entity.Property(e => e.EmployeeId).HasColumnName("Employee_Id");
            entity.Property(e => e.EmployeeName).HasMaxLength(91);
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.TotalSold).HasColumnType("decimal(38, 2)");
        });

        modelBuilder.Entity<VwEmployeeSale>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_EmployeeSales");

            entity.Property(e => e.EmployeeId).HasColumnName("Employee_Id");
            entity.Property(e => e.EmployeeName).HasMaxLength(91);
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.TotalSold).HasColumnType("decimal(38, 2)");
        });

        modelBuilder.Entity<VwInventoryLoss>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_InventoryLosses");

            entity.Property(e => e.ClotheVariantId).HasColumnName("ClotheVariant_Id");
            entity.Property(e => e.LossValue).HasColumnType("decimal(38, 6)");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
        });

        modelBuilder.Entity<VwLowStock>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_LowStock");

            entity.Property(e => e.ClotheName).HasMaxLength(60);
            entity.Property(e => e.ClotheVariantId).HasColumnName("ClotheVariant_Id");
            entity.Property(e => e.ColorName).HasMaxLength(30);
            entity.Property(e => e.SizeName).HasMaxLength(10);
            entity.Property(e => e.Sku).HasMaxLength(40);
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.StoreName).HasMaxLength(60);
        });

        modelBuilder.Entity<VwNationalAreaAvgProfit>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_NationalAreaAvgProfit");

            entity.Property(e => e.AreaName).HasMaxLength(45);
            entity.Property(e => e.AvgMonthlyProfit).HasColumnType("decimal(38, 6)");
            entity.Property(e => e.AvgMonthlyProfitPerStore).HasColumnType("decimal(38, 6)");
            entity.Property(e => e.CompanyAvgPerArea).HasColumnType("decimal(38, 6)");
            entity.Property(e => e.WorkAreaId).HasColumnName("WorkArea_Id");
        });

        modelBuilder.Entity<VwPaymentMethodBreakdown>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_PaymentMethodBreakdown");

            entity.Property(e => e.PaidTotal).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.PaymentMethodId).HasColumnName("PaymentMethod_Id");
            entity.Property(e => e.PaymentMethodName).HasMaxLength(45);
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
        });

        modelBuilder.Entity<VwSalesByChannel>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_SalesByChannel");

            entity.Property(e => e.Channel).HasMaxLength(7);
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.Total).HasColumnType("decimal(38, 2)");
        });

        modelBuilder.Entity<VwStoreAvgProfit>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_StoreAvgProfit");

            entity.Property(e => e.AvgMonthlyProfit).HasColumnType("decimal(38, 6)");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.StoreName).HasMaxLength(60);
            entity.Property(e => e.TotalExpenses).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.TotalIncome).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.TotalProfit).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.WorkAreaId).HasColumnName("WorkArea_Id");
        });

        modelBuilder.Entity<VwStoreBalance>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_StoreBalance");

            entity.Property(e => e.Expenses).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.Income).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.Profit).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.StoreName).HasMaxLength(60);
            entity.Property(e => e.WorkAreaId).HasColumnName("WorkArea_Id");
        });

        modelBuilder.Entity<VwStoreExpense>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_StoreExpenses");

            entity.Property(e => e.Amount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Detail).HasMaxLength(100);
            entity.Property(e => e.Source).HasMaxLength(9);
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
        });

        modelBuilder.Entity<VwStoreExpenseBreakdown>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_StoreExpenseBreakdown");

            entity.Property(e => e.Amount).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.Detail).HasMaxLength(100);
            entity.Property(e => e.Source).HasMaxLength(9);
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
        });

        modelBuilder.Entity<VwStoreIncome>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_StoreIncome");

            entity.Property(e => e.Income).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
        });

        modelBuilder.Entity<VwStoreStock>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_StoreStock");

            entity.Property(e => e.ClotheVariantId).HasColumnName("ClotheVariant_Id");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
        });

        modelBuilder.Entity<VwSupplierInfo>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_SupplierInfo");

            entity.Property(e => e.SupplierId).HasColumnName("Supplier_Id");
            entity.Property(e => e.SupplierName).HasMaxLength(100);
            entity.Property(e => e.SupplierType)
                .HasMaxLength(1)
                .IsUnicode(false)
                .IsFixedLength();
        });

        modelBuilder.Entity<VwSupplierPriceComparison>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_SupplierPriceComparison");

            entity.Property(e => e.AvgUnitCost).HasColumnType("decimal(38, 6)");
            entity.Property(e => e.ClotheId).HasColumnName("Clothe_Id");
            entity.Property(e => e.ClotheName).HasMaxLength(60);
            entity.Property(e => e.MaxUnitCost).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.MinUnitCost).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.SupplierId).HasColumnName("Supplier_Id");
            entity.Property(e => e.SupplierName).HasMaxLength(100);
        });

        modelBuilder.Entity<VwSupplierPurchase>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_SupplierPurchases");

            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
            entity.Property(e => e.SupplierId).HasColumnName("Supplier_Id");
            entity.Property(e => e.SupplierName).HasMaxLength(100);
            entity.Property(e => e.TotalSpent).HasColumnType("decimal(38, 2)");
        });

        modelBuilder.Entity<VwTopCustomer>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_TopCustomers");

            entity.Property(e => e.CustomerName).HasMaxLength(91);
            entity.Property(e => e.PersonId).HasColumnName("Person_Id");
            entity.Property(e => e.TotalSpent).HasColumnType("decimal(38, 2)");
        });

        modelBuilder.Entity<VwTopSellingProduct>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_TopSellingProducts");

            entity.Property(e => e.ClotheId).HasColumnName("Clothe_Id");
            entity.Property(e => e.ClotheName).HasMaxLength(60);
            entity.Property(e => e.ClotheTypeName).HasMaxLength(45);
            entity.Property(e => e.Revenue).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
        });

        modelBuilder.Entity<VwVariantSale>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_VariantSales");

            entity.Property(e => e.ClotheName).HasMaxLength(60);
            entity.Property(e => e.ClotheVariantId).HasColumnName("ClotheVariant_Id");
            entity.Property(e => e.ColorName).HasMaxLength(30);
            entity.Property(e => e.Revenue).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.SizeName).HasMaxLength(10);
            entity.Property(e => e.Sku).HasMaxLength(40);
            entity.Property(e => e.StoreId).HasColumnName("Store_Id");
        });

        modelBuilder.Entity<WorkArea>(entity =>
        {
            entity.ToTable("WorkArea");

            entity.HasIndex(e => e.Name, "UQ_WorkArea_Name").IsUnique();

            entity.Property(e => e.Active).HasDefaultValue(true, "DF_WorkArea_Active");
            entity.Property(e => e.Description).HasMaxLength(200);
            entity.Property(e => e.Name).HasMaxLength(45);
            entity.Property(e => e.RegistrationDate).HasDefaultValueSql("(sysutcdatetime())", "DF_WorkArea_RegistrationDate");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
