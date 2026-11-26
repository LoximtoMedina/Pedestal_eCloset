using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class PaymentCard
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public string HolderName { get; set; } = null!;

    public string Brand { get; set; } = null!;

    public string CardType { get; set; } = null!;

    public string Last4 { get; set; } = null!;

    public DateOnly ExpirationDate { get; set; }

    public bool IsDefault { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<BillHasPaymentMethod> BillHasPaymentMethods { get; set; } = new List<BillHasPaymentMethod>();

    public virtual User User { get; set; } = null!;
}
