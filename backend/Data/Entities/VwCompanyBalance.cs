using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwCompanyBalance
{
    public DateOnly? PeriodMonth { get; set; }

    public decimal? Income { get; set; }

    public decimal? Expenses { get; set; }

    public decimal? Profit { get; set; }
}
