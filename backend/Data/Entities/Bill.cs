using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Bill
{
    public int Id { get; set; }

    public string BillCode { get; set; } = null!;

    public int PersonId { get; set; }

    public int StoreId { get; set; }

    public int? EmployeeId { get; set; }

    public string Channel { get; set; } = null!;

    public string Status { get; set; } = null!;

    public int? CashShiftId { get; set; }

    public decimal SubTotal { get; set; }

    public decimal DiscountTotal { get; set; }

    public decimal CouponTotal { get; set; }

    public decimal TaxTotal { get; set; }

    public decimal ShippingTotal { get; set; }

    public decimal Total { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<BillDetail> BillDetails { get; set; } = new List<BillDetail>();

    public virtual ICollection<BillHasCoupon> BillHasCoupons { get; set; } = new List<BillHasCoupon>();

    public virtual ICollection<BillHasPaymentMethod> BillHasPaymentMethods { get; set; } = new List<BillHasPaymentMethod>();

    public virtual ICollection<Cart> Carts { get; set; } = new List<Cart>();

    public virtual CashShift? CashShift { get; set; }

    public virtual Employee? Employee { get; set; }

    public virtual Person Person { get; set; } = null!;

    public virtual Shipment? Shipment { get; set; }

    public virtual Store Store { get; set; } = null!;
}
