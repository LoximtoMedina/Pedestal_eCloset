using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class PurchaseOrder
{
    public int Id { get; set; }

    public string OrderNumber { get; set; } = null!;

    public int SupplierId { get; set; }

    public int StoreId { get; set; }

    public int? EmployeeId { get; set; }

    public DateOnly OrderDate { get; set; }

    public DateOnly? ReceivedDate { get; set; }

    public string Status { get; set; } = null!;

    public decimal Total { get; set; }

    public string? Notes { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual Employee? Employee { get; set; }

    public virtual ICollection<PurchaseOrderDetail> PurchaseOrderDetails { get; set; } = new List<PurchaseOrderDetail>();

    public virtual Store Store { get; set; } = null!;

    public virtual Supplier Supplier { get; set; } = null!;
}
