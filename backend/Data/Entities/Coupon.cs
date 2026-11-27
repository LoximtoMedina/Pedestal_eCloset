using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Coupon
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string Code { get; set; } = null!;

    public string DiscountKind { get; set; } = null!;

    public decimal? Percentage { get; set; }

    public decimal? Amount { get; set; }

    public DateTime StartDate { get; set; }

    public DateTime FinishDate { get; set; }

    public int? MaxUses { get; set; }

    public decimal MinPurchaseAmount { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<BillHasCoupon> BillHasCoupons { get; set; } = new List<BillHasCoupon>();
}
