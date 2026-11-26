using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwSalesByChannel
{
    public int StoreId { get; set; }

    public DateOnly? PeriodMonth { get; set; }

    public string Channel { get; set; } = null!;

    public int? BillCount { get; set; }

    public decimal? Total { get; set; }
}
