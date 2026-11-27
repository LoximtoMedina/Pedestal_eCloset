using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class CashShift
{
    public int Id { get; set; }

    public int CashRegisterId { get; set; }

    public int EmployeeId { get; set; }

    public DateTime OpenedAt { get; set; }

    public DateTime? ClosedAt { get; set; }

    public decimal OpeningAmount { get; set; }

    public decimal? ClosingAmount { get; set; }

    public string Status { get; set; } = null!;

    public virtual ICollection<Bill> Bills { get; set; } = new List<Bill>();

    public virtual CashRegister CashRegister { get; set; } = null!;

    public virtual Employee Employee { get; set; } = null!;
}
