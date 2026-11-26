using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class AppliedTaxis
{
    public int BillDetailsId { get; set; }

    public int TaxesId { get; set; }

    public decimal Percentage { get; set; }

    public decimal Amount { get; set; }

    public virtual BillDetail BillDetails { get; set; } = null!;

    public virtual Taxis Taxes { get; set; } = null!;
}
