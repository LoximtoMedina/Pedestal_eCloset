using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Discount
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public DateTime StartDate { get; set; }

    public DateTime FinishDate { get; set; }

    public decimal Percentage { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<AppliedDiscount> AppliedDiscounts { get; set; } = new List<AppliedDiscount>();

    public virtual ICollection<DiscountTarget> DiscountTargets { get; set; } = new List<DiscountTarget>();
}
