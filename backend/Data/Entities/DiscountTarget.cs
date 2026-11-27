using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class DiscountTarget
{
    public int Id { get; set; }

    public int DiscountId { get; set; }

    public int? ClotheId { get; set; }

    public int? ClotheTypeId { get; set; }

    public virtual Clothe? Clothe { get; set; }

    public virtual ClotheType? ClotheType { get; set; }

    public virtual Discount Discount { get; set; } = null!;
}
