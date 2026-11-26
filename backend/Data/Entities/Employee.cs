using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Employee
{
    public int Id { get; set; }

    public int PersonId { get; set; }

    public DateOnly HireDate { get; set; }

    public decimal Salary { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<Bill> Bills { get; set; } = new List<Bill>();

    public virtual CashShift? CashShift { get; set; }

    public virtual ICollection<Expense> Expenses { get; set; } = new List<Expense>();

    public virtual ICollection<Payroll> Payrolls { get; set; } = new List<Payroll>();

    public virtual Person Person { get; set; } = null!;

    public virtual PositionHistorial? PositionHistorial { get; set; }

    public virtual ICollection<PurchaseOrder> PurchaseOrders { get; set; } = new List<PurchaseOrder>();

    public virtual ICollection<StockMovement> StockMovements { get; set; } = new List<StockMovement>();
}
