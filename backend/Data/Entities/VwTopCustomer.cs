using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwTopCustomer
{
    public int PersonId { get; set; }

    public string? CustomerName { get; set; }

    public int? BillCount { get; set; }

    public decimal? TotalSpent { get; set; }

    public DateTime? LastPurchaseDate { get; set; }

    public long? SpendRank { get; set; }
}
