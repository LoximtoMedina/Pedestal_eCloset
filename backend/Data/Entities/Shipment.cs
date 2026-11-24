using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Shipment
{
    public int Id { get; set; }

    public int BillId { get; set; }

    public int DirectionId { get; set; }

    public string? TrackingNumber { get; set; }

    public string? Carrier { get; set; }

    public string Status { get; set; } = null!;

    public decimal ShippingCost { get; set; }

    public DateOnly? ShippedDate { get; set; }

    public DateOnly? DeliveredDate { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual Bill Bill { get; set; } = null!;

    public virtual Direction Direction { get; set; } = null!;
}
