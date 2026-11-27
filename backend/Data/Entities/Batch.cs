using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Batch
{
    public int Id { get; set; }

    public string BatchNumber { get; set; } = null!;

    public int PurchaseOrderDetailId { get; set; }

    public int Quantity { get; set; }

    public int Stock { get; set; }

    public DateOnly? ElaborationDate { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual PurchaseOrderDetail PurchaseOrderDetail { get; set; } = null!;

    public virtual ICollection<StockMovement> StockMovements { get; set; } = new List<StockMovement>();
}
