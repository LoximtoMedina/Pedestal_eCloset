using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwDiscountImpact
{
    public int DiscountsId { get; set; }

    public string Name { get; set; } = null!;

    public decimal Percentage { get; set; }

    public DateTime StartDate { get; set; }

    public DateTime FinishDate { get; set; }

    public bool Active { get; set; }

    public int? LinesAffected { get; set; }

    public decimal TotalDiscounted { get; set; }
}
