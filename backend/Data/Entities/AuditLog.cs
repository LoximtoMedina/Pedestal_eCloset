using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class AuditLog
{
    public long Id { get; set; }

    public int? AccountId { get; set; }

    public string TableName { get; set; } = null!;

    public string RecordId { get; set; } = null!;

    public string ActionType { get; set; } = null!;

    public string? OldValues { get; set; }

    public string? NewValues { get; set; }

    public DateTime AuditDate { get; set; }

    public virtual Account? Account { get; set; }
}
