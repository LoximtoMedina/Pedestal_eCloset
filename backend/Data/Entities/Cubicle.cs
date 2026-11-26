using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Cubicle
{
    public int Id { get; set; }

    public int RackId { get; set; }

    public string CubicleNumber { get; set; } = null!;

    public string? Name { get; set; }

    public string? Description { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<ClothesInCubicle> ClothesInCubicles { get; set; } = new List<ClothesInCubicle>();

    public virtual Rack Rack { get; set; } = null!;

    public virtual ICollection<StockMovement> StockMovementFromCubicles { get; set; } = new List<StockMovement>();

    public virtual ICollection<StockMovement> StockMovementToCubicles { get; set; } = new List<StockMovement>();
}
