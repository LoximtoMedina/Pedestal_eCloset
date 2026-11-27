using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class BillHasPaymentMethod
{
    public int Id { get; set; }

    public int BillId { get; set; }

    public int PaymentMethodId { get; set; }

    public int? PaymentCardId { get; set; }

    public decimal PaidAmount { get; set; }

    public string? PaymentReference { get; set; }

    public DateTime RegistrationDate { get; set; }

    public virtual Bill Bill { get; set; } = null!;

    public virtual PaymentCard? PaymentCard { get; set; }

    public virtual PaymentMethod PaymentMethod { get; set; } = null!;
}
