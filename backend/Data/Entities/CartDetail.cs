using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class CartDetail
{
    public int Id { get; set; }

    public int CartId { get; set; }

    public int ClotheVariantId { get; set; }

    public int Quantity { get; set; }

    public DateTime AddedDate { get; set; }

    public virtual Cart Cart { get; set; } = null!;

    public virtual ClotheVariant ClotheVariant { get; set; } = null!;
}
