using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwAreaAvgProfit
{
    public int WorkAreaId { get; set; }

    public string AreaName { get; set; } = null!;

    public int? MonthsCounted { get; set; }

    public decimal? AvgMonthlyProfit { get; set; }

    public decimal? AvgMonthlyProfitPerStore { get; set; }
}
