using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwCouponUsage
{
    public int CouponsId { get; set; }

    public string Code { get; set; } = null!;

    public string Name { get; set; } = null!;

    public DateTime StartDate { get; set; }

    public DateTime FinishDate { get; set; }

    public bool Active { get; set; }

    public int? MaxUses { get; set; }

    public int? TimesUsed { get; set; }

    public decimal TotalDiscounted { get; set; }

    public int? UsesLeft { get; set; }
}
