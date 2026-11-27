using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class CashRegister
{
    public int Id { get; set; }

    public int StoreId { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual CashShift? CashShift { get; set; }

    public virtual Store Store { get; set; } = null!;
}
