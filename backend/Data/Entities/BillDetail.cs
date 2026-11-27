using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class BillDetail
{
    public int Id { get; set; }

    public int BillId { get; set; }

    public int ClotheVariantId { get; set; }

    public int Quantity { get; set; }

    public decimal UnitPrice { get; set; }

    public decimal DiscountAmount { get; set; }

    public decimal TaxAmount { get; set; }

    public decimal? SubTotal { get; set; }

    public decimal? Total { get; set; }

    public virtual ICollection<AppliedDiscount> AppliedDiscounts { get; set; } = new List<AppliedDiscount>();

    public virtual ICollection<AppliedTaxis> AppliedTaxes { get; set; } = new List<AppliedTaxis>();

    public virtual Bill Bill { get; set; } = null!;

    public virtual ClotheVariant ClotheVariant { get; set; } = null!;

    public virtual ICollection<StockMovement> StockMovements { get; set; } = new List<StockMovement>();
}
