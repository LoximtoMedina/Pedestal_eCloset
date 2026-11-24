using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Color
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string? HexCode { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<ClotheVariant> ClotheVariants { get; set; } = new List<ClotheVariant>();
}
