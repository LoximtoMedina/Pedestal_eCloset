using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class UserClothe
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public int? ClotheVariantId { get; set; }

    public int ClotheTypeId { get; set; }

    public string Name { get; set; } = null!;

    public string Origin { get; set; } = null!;

    public string? ImageFileId { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual ClotheType ClotheType { get; set; } = null!;

    public virtual ClotheVariant? ClotheVariant { get; set; }

    public virtual User User { get; set; } = null!;

    public virtual ICollection<Outfit> Outfits { get; set; } = new List<Outfit>();
}
