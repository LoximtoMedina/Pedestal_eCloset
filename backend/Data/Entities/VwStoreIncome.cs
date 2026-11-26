using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwStoreIncome
{
    public int StoreId { get; set; }

    public DateOnly? PeriodMonth { get; set; }

    public decimal? Income { get; set; }
}
