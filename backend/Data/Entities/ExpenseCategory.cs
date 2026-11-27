using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class ExpenseCategory
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<Expense> Expenses { get; set; } = new List<Expense>();
}
