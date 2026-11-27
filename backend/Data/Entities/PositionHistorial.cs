using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class PositionHistorial
{
    public int Id { get; set; }

    public int EmployeeId { get; set; }

    public int PositionId { get; set; }

    public int? StoreId { get; set; }

    public int? WorkAreaId { get; set; }

    public DateOnly FirstDate { get; set; }

    public DateOnly? LastDate { get; set; }

    public decimal Salary { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual Employee Employee { get; set; } = null!;

    public virtual Position Position { get; set; } = null!;

    public virtual Store? Store { get; set; }

    public virtual WorkArea? WorkArea { get; set; }
}
