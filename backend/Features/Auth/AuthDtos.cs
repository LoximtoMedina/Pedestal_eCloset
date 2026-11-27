using System.ComponentModel.DataAnnotations;

namespace Pedestal.Api.Features.Auth.Dtos;

public sealed class RegisterRequestDto
{
    [Required, StringLength(30)]
    public string DocumentNumber { get; set; } = string.Empty;

    [Required, StringLength(20)]
    public string Phone { get; set; } = string.Empty;

    [Required, StringLength(45)]
    public string FirstName { get; set; } = string.Empty;

    [StringLength(45)]
    public string? MiddleName { get; set; }

    [Required, StringLength(45)]
    public string FirstSurname { get; set; } = string.Empty;

    [StringLength(45)]
    public string? SecondSurname { get; set; }

    [Required, EmailAddress, StringLength(100)]
    public string Email { get; set; } = string.Empty;

    [Required, StringLength(60)]
    public string Username { get; set; } = string.Empty;

    [Required, StringLength(60)]
    public string City { get; set; } = string.Empty;

    [Required, StringLength(200)]
    public string AddressLine { get; set; } = string.Empty;

    [Required, StringLength(128, MinimumLength = 8)]
    public string Password { get; set; } = string.Empty;

    [Required, Compare(nameof(Password), ErrorMessage = "Las contraseñas no coinciden.")]
    public string ConfirmPassword { get; set; } = string.Empty;
}

public sealed class LoginRequestDto
{
    [Required, StringLength(100)]
    public string Identifier { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;

    public bool RememberMe { get; set; }
}

public sealed class ChangePasswordDto
{
    [Required]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required, StringLength(128, MinimumLength = 8)]
    public string NewPassword { get; set; } = string.Empty;

    [Required, Compare(nameof(NewPassword), ErrorMessage = "Las contraseñas no coinciden.")]
    public string ConfirmNewPassword { get; set; } = string.Empty;
}

public sealed class AuthResponseDto
{
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public SessionUserDto User { get; set; } = new();
}

public sealed class SessionUserDto
{
    public int AccountId { get; set; }
    public int? UserId { get; set; }
    public int? EmployeeId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string FirstSurname { get; set; } = string.Empty;
    public List<string> Roles { get; set; } = [];
    public List<string> Permissions { get; set; } = [];
    public int? StoreId { get; set; }
    public int? AreaId { get; set; }
    public string InitialRoute { get; set; } = "/shop";
}