using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Role
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public int HierarchyLevel { get; set; }

    public string ScopeType { get; set; } = null!;

    public bool Active { get; set; }

    public virtual ICollection<AccountRole> AccountRoles { get; set; } = new List<AccountRole>();

    public virtual ICollection<Position> Positions { get; set; } = new List<Position>();

    public virtual ICollection<Permission> Permissions { get; set; } = new List<Permission>();
}
