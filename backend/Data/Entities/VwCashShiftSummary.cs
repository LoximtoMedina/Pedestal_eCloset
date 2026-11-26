using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwCashShiftSummary
{
    public int CashShiftId { get; set; }

    public int StoreId { get; set; }

    public int CashRegisterId { get; set; }

    public string CashRegisterName { get; set; } = null!;

    public int EmployeeId { get; set; }

    public string? EmployeeName { get; set; }

    public DateTime OpenedAt { get; set; }

    public DateTime? ClosedAt { get; set; }

    public string Status { get; set; } = null!;

    public decimal OpeningAmount { get; set; }

    public decimal CashSales { get; set; }

    public decimal CardSales { get; set; }

    public decimal? ExpectedCash { get; set; }

    public decimal? ClosingAmount { get; set; }

    public decimal? CashDifference { get; set; }
}
