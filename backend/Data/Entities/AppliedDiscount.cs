using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class AppliedDiscount
{
    public int BillDetailsId { get; set; }

    public int DiscountsId { get; set; }

    public decimal Percentage { get; set; }

    public decimal Amount { get; set; }

    public virtual BillDetail BillDetails { get; set; } = null!;

    public virtual Discount Discounts { get; set; } = null!;
}
