using System.ComponentModel.DataAnnotations;

namespace Pedestal.Api.Features.Pos.Dtos;

public sealed class CashRegisterDto
{
    public int Id { get; set; }
    public int StoreId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool Active { get; set; }
}

public sealed class CashRegisterUpsertDto
{
    [Required, StringLength(45, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    [StringLength(100)]
    public string? Description { get; set; }

    public bool Active { get; set; } = true;
}

public sealed class OpenShiftDto
{
    [Required]
    public int CashRegisterId { get; set; }

    [Range(0, double.MaxValue)]
    public decimal OpeningAmount { get; set; }
}

public sealed class CloseShiftDto
{
    [Range(0, double.MaxValue)]
    public decimal ClosingAmount { get; set; }
}

public sealed class ShiftSummaryDto
{
    public int CashShiftId { get; set; }
    public int StoreId { get; set; }
    public int CashRegisterId { get; set; }
    public string CashRegisterName { get; set; } = string.Empty;
    public int EmployeeId { get; set; }
    public string EmployeeName { get; set; } = string.Empty;
    public DateTime OpenedAt { get; set; }
    public DateTime? ClosedAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal OpeningAmount { get; set; }
    public decimal CashSales { get; set; }
    public decimal CardSales { get; set; }
    public decimal ExpectedCash { get; set; }
    public decimal? ClosingAmount { get; set; }
    public decimal? CashDifference { get; set; }
}

public sealed class PosProductDto
{
    public int ClotheVariantId { get; set; }
    public int ClotheId { get; set; }
    public string Sku { get; set; } = string.Empty;
    public string ClotheName { get; set; } = string.Empty;
    public string? SizeName { get; set; }
    public string? ColorName { get; set; }
    public decimal UnitPrice { get; set; }
    public int AvailableStock { get; set; }
}

public sealed class CustomerSearchResultDto
{
    public int PersonId { get; set; }
    public string? DocumentId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Phone { get; set; }
}

public sealed class QuickCustomerCreateDto
{
    [Required, StringLength(30)]
    public string DocumentId { get; set; } = string.Empty;

    [Required, StringLength(45)]
    public string FirstName { get; set; } = string.Empty;

    [StringLength(45)]
    public string? MiddleName { get; set; }

    [Required, StringLength(45)]
    public string FirstSurname { get; set; } = string.Empty;

    [StringLength(45)]
    public string? SecondSurname { get; set; }

    [StringLength(20)]
    public string? Phone { get; set; }

    [EmailAddress, StringLength(100)]
    public string? Email { get; set; }
}

public sealed class PosSaleLineDto
{
    [Required]
    public int ClotheVariantId { get; set; }

    [Range(1, int.MaxValue)]
    public int Quantity { get; set; }
}

public sealed class PosPaymentDto
{
    [Required]
    public int PaymentMethodId { get; set; }

    public int? PaymentCardId { get; set; }

    [Range(0.01, double.MaxValue)]
    public decimal Amount { get; set; }

    [StringLength(60)]
    public string? PaymentReference { get; set; }
}

public sealed class PosSaleRequestDto
{
    public int? PersonId { get; set; }

    [StringLength(30)]
    public string? CouponCode { get; set; }

    [Required, MinLength(1)]
    public List<PosSaleLineDto> Lines { get; set; } = [];

    [Required, MinLength(1)]
    public List<PosPaymentDto> Payments { get; set; } = [];
}

public sealed class ReceiptLineDto
{
    public int ClotheVariantId { get; set; }
    public string Sku { get; set; } = string.Empty;
    public string ClotheName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal SubTotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal Total { get; set; }
}

public sealed class ReceiptPaymentDto
{
    public int PaymentMethodId { get; set; }
    public string PaymentMethodName { get; set; } = string.Empty;
    public decimal PaidAmount { get; set; }
    public string? PaymentReference { get; set; }
}

public sealed class ReceiptDto
{
    public int BillId { get; set; }
    public string BillCode { get; set; } = string.Empty;
    public int StoreId { get; set; }
    public int? CashShiftId { get; set; }
    public int? EmployeeId { get; set; }
    public int? PersonId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string Channel { get; set; } = "POS";
    public string Status { get; set; } = "PAID";
    public DateTime RegistrationDate { get; set; }
    public decimal SubTotal { get; set; }
    public decimal DiscountTotal { get; set; }
    public decimal CouponTotal { get; set; }
    public decimal TaxTotal { get; set; }
    public decimal Total { get; set; }
    public List<ReceiptLineDto> Lines { get; set; } = [];
    public List<ReceiptPaymentDto> Payments { get; set; } = [];
}