using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwSupplierInfo
{
    public int SupplierId { get; set; }

    public string SupplierType { get; set; } = null!;

    public string? SupplierName { get; set; }
}
