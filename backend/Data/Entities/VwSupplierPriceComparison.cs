using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwSupplierPriceComparison
{
    public int StoreId { get; set; }

    public int ClotheId { get; set; }

    public string ClotheName { get; set; } = null!;

    public int SupplierId { get; set; }

    public string? SupplierName { get; set; }

    public decimal? AvgUnitCost { get; set; }

    public decimal? MinUnitCost { get; set; }

    public decimal? MaxUnitCost { get; set; }

    public int? UnitsBought { get; set; }

    public long? PriceRankDesc { get; set; }

    public long? PriceRankAsc { get; set; }
}
