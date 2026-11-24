using System;
using System.Collections.Generic;

namespace Pedestal.Api.Data.Entities;

public partial class Person
{
    public int Id { get; set; }

    public string? DocumentId { get; set; }

    public string FirstName { get; set; } = null!;

    public string? MiddleName { get; set; }

    public string FirstSurname { get; set; } = null!;

    public string? SecondSurname { get; set; }

    public string? Email { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool Active { get; set; }

    public virtual Account? Account { get; set; }

    public virtual ICollection<Bill> Bills { get; set; } = new List<Bill>();

    public virtual ICollection<Direction> Directions { get; set; } = new List<Direction>();

    public virtual Employee? Employee { get; set; }

    public virtual ICollection<Phone> Phones { get; set; } = new List<Phone>();

    public virtual ICollection<Supplier> Suppliers { get; set; } = new List<Supplier>();

    public virtual User? User { get; set; }
}
