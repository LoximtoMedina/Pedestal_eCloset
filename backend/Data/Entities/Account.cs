using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Account
{
    public int Id { get; set; }

    public int PersonId { get; set; }

    public string Username { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public bool IsLocked { get; set; }

    public int FailedAttempts { get; set; }

    public DateTime? LastLoginDate { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<AccountRole> AccountRoles { get; set; } = new List<AccountRole>();

    public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();

    public virtual Person Person { get; set; } = null!;
}
