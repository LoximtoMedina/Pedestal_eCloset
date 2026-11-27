using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Taxis
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public decimal Percentage { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<AppliedTaxis> AppliedTaxes { get; set; } = new List<AppliedTaxis>();
}
