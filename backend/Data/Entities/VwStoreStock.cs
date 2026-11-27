using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwStoreStock
{
    public int StoreId { get; set; }

    public int ClotheVariantId { get; set; }

    public int? Quantity { get; set; }
}
