using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class VwEmployeeOfTheMonth
{
    public int StoreId { get; set; }

    public int? EmployeeId { get; set; }

    public string? EmployeeName { get; set; }

    public DateOnly? PeriodMonth { get; set; }

    public int? BillCount { get; set; }

    public decimal? TotalSold { get; set; }
}
