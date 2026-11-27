using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwStoreBalance
{
    public int? StoreId { get; set; }

    public string StoreName { get; set; } = null!;

    public int WorkAreaId { get; set; }

    public DateOnly? PeriodMonth { get; set; }

    public decimal Income { get; set; }

    public decimal Expenses { get; set; }

    public decimal? Profit { get; set; }
}
