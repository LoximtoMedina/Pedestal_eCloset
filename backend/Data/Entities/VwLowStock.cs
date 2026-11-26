using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwLowStock
{
    public int StoreId { get; set; }

    public string StoreName { get; set; } = null!;

    public int ClotheVariantId { get; set; }

    public string Sku { get; set; } = null!;

    public string ClotheName { get; set; } = null!;

    public string SizeName { get; set; } = null!;

    public string ColorName { get; set; } = null!;

    public int? Quantity { get; set; }

    public int MinStock { get; set; }
}
