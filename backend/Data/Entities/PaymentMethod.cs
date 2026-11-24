using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class PaymentMethod
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public bool RequiresCard { get; set; }

    public bool AllowedInStore { get; set; }

    public bool AllowedOnline { get; set; }

    public bool ApplyDiscounts { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<BillHasPaymentMethod> BillHasPaymentMethods { get; set; } = new List<BillHasPaymentMethod>();
}
