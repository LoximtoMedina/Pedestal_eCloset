using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class StockMovement
{
    public int Id { get; set; }

    public string MovementType { get; set; } = null!;

    public int ClotheVariantId { get; set; }

    public int Quantity { get; set; }

    public int? BatchId { get; set; }

    public int? BillDetailsId { get; set; }

    public int? FromStoreId { get; set; }

    public int? FromCubicleId { get; set; }

    public int? ToStoreId { get; set; }

    public int? ToCubicleId { get; set; }

    public string? Reason { get; set; }

    public int? EmployeeId { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual Batch? Batch { get; set; }

    public virtual BillDetail? BillDetails { get; set; }

    public virtual ClotheVariant ClotheVariant { get; set; } = null!;

    public virtual Employee? Employee { get; set; }

    public virtual Cubicle? FromCubicle { get; set; }

    public virtual Store? FromStore { get; set; }

    public virtual Cubicle? ToCubicle { get; set; }

    public virtual Store? ToStore { get; set; }
}
