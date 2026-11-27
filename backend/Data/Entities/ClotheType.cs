using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class ClotheType
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<Clothe> Clothes { get; set; } = new List<Clothe>();

    public virtual ICollection<DiscountTarget> DiscountTargets { get; set; } = new List<DiscountTarget>();

    public virtual ICollection<UserClothe> UserClothes { get; set; } = new List<UserClothe>();
}
