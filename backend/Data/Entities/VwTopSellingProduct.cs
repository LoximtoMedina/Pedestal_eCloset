using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwTopSellingProduct
{
    public int StoreId { get; set; }

    public DateOnly? PeriodMonth { get; set; }

    public int ClotheId { get; set; }

    public string ClotheName { get; set; } = null!;

    public string ClotheTypeName { get; set; } = null!;

    public int? UnitsSold { get; set; }

    public decimal? Revenue { get; set; }

    public long? SalesRank { get; set; }
}
