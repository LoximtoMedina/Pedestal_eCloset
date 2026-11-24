using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Clothe
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public int ClotheTypeId { get; set; }

    public string? Brand { get; set; }

    public string? Description { get; set; }

    public decimal BasePrice { get; set; }

    public string? ImageFileId { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual ClotheType ClotheType { get; set; } = null!;

    public virtual ICollection<ClotheVariant> ClotheVariants { get; set; } = new List<ClotheVariant>();

    public virtual ICollection<DiscountTarget> DiscountTargets { get; set; } = new List<DiscountTarget>();
}
