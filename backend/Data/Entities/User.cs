using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class User
{
    public int Id { get; set; }

    public int PersonId { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual Cart? Cart { get; set; }

    public virtual ICollection<Outfit> Outfits { get; set; } = new List<Outfit>();

    public virtual ICollection<PaymentCard> PaymentCards { get; set; } = new List<PaymentCard>();

    public virtual Person Person { get; set; } = null!;

    public virtual ICollection<UserClothe> UserClothes { get; set; } = new List<UserClothe>();
}
