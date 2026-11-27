using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Expense
{
    public int Id { get; set; }

    public int StoreId { get; set; }

    public int ExpenseCategoryId { get; set; }

    public decimal Amount { get; set; }

    public DateOnly ExpenseDate { get; set; }

    public string? Description { get; set; }

    public int? EmployeeId { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual Employee? Employee { get; set; }

    public virtual ExpenseCategory ExpenseCategory { get; set; } = null!;

    public virtual Store Store { get; set; } = null!;
}
