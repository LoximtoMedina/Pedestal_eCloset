using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Phone
{
    public int Id { get; set; }

    public string Phone1 { get; set; } = null!;

    public int? PersonId { get; set; }

    public int? LegalEntityId { get; set; }

    public DateTime RegistrationDate { get; set; }

    public bool Active { get; set; }

    public virtual LegalEntity? LegalEntity { get; set; }

    public virtual Person? Person { get; set; }
}
