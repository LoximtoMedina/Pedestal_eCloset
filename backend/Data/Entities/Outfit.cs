using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Outfit
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual User User { get; set; } = null!;

    public virtual ICollection<UserClothe> UserClothes { get; set; } = new List<UserClothe>();
}
