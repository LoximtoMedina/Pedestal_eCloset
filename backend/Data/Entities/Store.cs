using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Store
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Direction { get; set; }

    public string StoreType { get; set; } = null!;

    public int WorkAreaId { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<Bill> Bills { get; set; } = new List<Bill>();

    public virtual ICollection<CashRegister> CashRegisters { get; set; } = new List<CashRegister>();

    public virtual ICollection<Expense> Expenses { get; set; } = new List<Expense>();

    public virtual ICollection<Payroll> Payrolls { get; set; } = new List<Payroll>();

    public virtual ICollection<PositionHistorial> PositionHistorials { get; set; } = new List<PositionHistorial>();

    public virtual ICollection<PurchaseOrder> PurchaseOrders { get; set; } = new List<PurchaseOrder>();

    public virtual ICollection<Rack> Racks { get; set; } = new List<Rack>();

    public virtual ICollection<StockMovement> StockMovementFromStores { get; set; } = new List<StockMovement>();

    public virtual ICollection<StockMovement> StockMovementToStores { get; set; } = new List<StockMovement>();

    public virtual WorkArea WorkArea { get; set; } = null!;
}
