using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Direction
{
    public int Id { get; set; }

    public string Direction1 { get; set; } = null!;

    public string? City { get; set; }

    public string DirectionType { get; set; } = null!;

    public bool IsDefault { get; set; }

    public int? PersonId { get; set; }

    public int? LegalEntityId { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual LegalEntity? LegalEntity { get; set; }

    public virtual Person? Person { get; set; }

    public virtual ICollection<Shipment> Shipments { get; set; } = new List<Shipment>();
}
