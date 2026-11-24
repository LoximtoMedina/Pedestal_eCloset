using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Payroll
{
    public int Id { get; set; }

    public int EmployeeId { get; set; }

    public int StoreId { get; set; }

    public DateOnly PeriodStart { get; set; }

    public DateOnly PeriodEnd { get; set; }

    public decimal GrossAmount { get; set; }

    public decimal Deductions { get; set; }

    public decimal? NetAmount { get; set; }

    public DateOnly? PaidDate { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual Employee Employee { get; set; } = null!;

    public virtual Store Store { get; set; } = null!;
}
