using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwStoreAvgProfit
{
    public int? StoreId { get; set; }

    public string StoreName { get; set; } = null!;

    public int WorkAreaId { get; set; }

    public int? MonthsCounted { get; set; }

    public decimal? TotalIncome { get; set; }

    public decimal? TotalExpenses { get; set; }

    public decimal? TotalProfit { get; set; }

    public decimal? AvgMonthlyProfit { get; set; }
}
