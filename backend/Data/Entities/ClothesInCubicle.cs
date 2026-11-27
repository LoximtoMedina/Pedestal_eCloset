using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class ClothesInCubicle
{
    public int CubicleId { get; set; }

    public int ClotheVariantId { get; set; }

    public int Quantity { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ClotheVariant ClotheVariant { get; set; } = null!;

    public virtual Cubicle Cubicle { get; set; } = null!;
}
