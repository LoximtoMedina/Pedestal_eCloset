using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class ClotheVariant
{
    public int Id { get; set; }

    public int ClotheId { get; set; }

    public int SizeId { get; set; }

    public int ColorId { get; set; }

    public string Sku { get; set; } = null!;

    public decimal? PriceOverride { get; set; }

    public int MinStock { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual ICollection<BillDetail> BillDetails { get; set; } = new List<BillDetail>();

    public virtual ICollection<CartDetail> CartDetails { get; set; } = new List<CartDetail>();

    public virtual Clothe Clothe { get; set; } = null!;

    public virtual ICollection<ClothesInCubicle> ClothesInCubicles { get; set; } = new List<ClothesInCubicle>();

    public virtual Color Color { get; set; } = null!;

    public virtual ICollection<PurchaseOrderDetail> PurchaseOrderDetails { get; set; } = new List<PurchaseOrderDetail>();

    public virtual Size Size { get; set; } = null!;

    public virtual ICollection<StockMovement> StockMovements { get; set; } = new List<StockMovement>();

    public virtual ICollection<UserClothe> UserClothes { get; set; } = new List<UserClothe>();
}
