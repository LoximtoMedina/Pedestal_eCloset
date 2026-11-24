using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class BillHasCoupon
{
    public int BillId { get; set; }

    public int CouponsId { get; set; }

    public decimal AppliedAmount { get; set; }

    public virtual Bill Bill { get; set; } = null!;

    public virtual Coupon Coupons { get; set; } = null!;
}
