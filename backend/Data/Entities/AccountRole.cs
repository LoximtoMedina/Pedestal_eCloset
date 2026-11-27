using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class AccountRole
{
    public int AccountId { get; set; }

    public int RoleId { get; set; }

    public DateTime RegistrationDate { get; set; }

    public virtual Account Account { get; set; } = null!;

    public virtual Role Role { get; set; } = null!;
}
