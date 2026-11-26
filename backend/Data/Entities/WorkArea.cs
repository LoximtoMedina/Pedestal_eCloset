using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class WorkArea
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<PositionHistorial> PositionHistorials { get; set; } = new List<PositionHistorial>();

    public virtual ICollection<Store> Stores { get; set; } = new List<Store>();
}
