using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwSupplierPurchase
{
    public int StoreId { get; set; }

    public int SupplierId { get; set; }

    public string? SupplierName { get; set; }

    public int? OrderCount { get; set; }

    public int? UnitsBought { get; set; }

    public decimal? TotalSpent { get; set; }

    public long? SpendRank { get; set; }
}
