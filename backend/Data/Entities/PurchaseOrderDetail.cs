using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class PurchaseOrderDetail
{
    public int Id { get; set; }

    public int PurchaseOrderId { get; set; }

    public int ClotheVariantId { get; set; }

    public int Quantity { get; set; }

    public decimal UnitCost { get; set; }

    public decimal? SubTotal { get; set; }

    public virtual ICollection<Batch> Batches { get; set; } = new List<Batch>();

    public virtual ClotheVariant ClotheVariant { get; set; } = null!;

    public virtual PurchaseOrder PurchaseOrder { get; set; } = null!;
}
