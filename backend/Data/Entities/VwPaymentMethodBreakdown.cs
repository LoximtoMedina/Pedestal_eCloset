using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwPaymentMethodBreakdown
{
    public int StoreId { get; set; }

    public DateOnly? PeriodMonth { get; set; }

    public int PaymentMethodId { get; set; }

    public string PaymentMethodName { get; set; } = null!;

    public int? PaymentCount { get; set; }

    public decimal? PaidTotal { get; set; }
}
