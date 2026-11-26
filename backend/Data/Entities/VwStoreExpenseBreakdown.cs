using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwStoreExpenseBreakdown
{
    public int StoreId { get; set; }

    public DateOnly? PeriodMonth { get; set; }

    public string Source { get; set; } = null!;

    public string? Detail { get; set; }

    public decimal? Amount { get; set; }
}
