using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Rack
{
    public int Id { get; set; }

    public int StoreId { get; set; }

    public string RackNumber { get; set; } = null!;

    public string Zone { get; set; } = null!;

    public string? Name { get; set; }

    public string? Description { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<Cubicle> Cubicles { get; set; } = new List<Cubicle>();

    public virtual Store Store { get; set; } = null!;
}
