using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwAreaBalance
{
    public int WorkAreaId { get; set; }

    public string AreaName { get; set; } = null!;

    public DateOnly? PeriodMonth { get; set; }

    public decimal? Income { get; set; }

    public decimal? Expenses { get; set; }

    public decimal? Profit { get; set; }
}
