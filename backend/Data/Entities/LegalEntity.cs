using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class LegalEntity
{
    public int Id { get; set; }

    public string BusinessName { get; set; } = null!;

    public string? TradeName { get; set; }

    public string? TaxId { get; set; }

    public string? Email { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<Direction> Directions { get; set; } = new List<Direction>();

    public virtual ICollection<Phone> Phones { get; set; } = new List<Phone>();

    public virtual ICollection<Supplier> Suppliers { get; set; } = new List<Supplier>();
}
