using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwInventoryLoss
{
    public int? StoreId { get; set; }

    public DateOnly? PeriodMonth { get; set; }

    public int ClotheVariantId { get; set; }

    public int? UnitsLost { get; set; }

    public decimal? LossValue { get; set; }
}
