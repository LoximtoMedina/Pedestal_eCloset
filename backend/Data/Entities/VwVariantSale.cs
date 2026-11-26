using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwVariantSale
{
    public int StoreId { get; set; }

    public DateOnly? PeriodMonth { get; set; }

    public int ClotheVariantId { get; set; }

    public string Sku { get; set; } = null!;

    public string ClotheName { get; set; } = null!;

    public string SizeName { get; set; } = null!;

    public string ColorName { get; set; } = null!;

    public int? UnitsSold { get; set; }

    public decimal? Revenue { get; set; }
}
