using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Pedestal.Api.Data;
using Pedestal.Api.Data.Entities;
using Pedestal.Api.Features.Auth.Dtos;
using DbUser = Pedestal.Api.Data.Entities.User;

namespace Pedestal.Api.Features.Auth;

public sealed record ServiceResult<T>(
    bool IsSuccess,
    int StatusCode,
    string? ErrorTitle,
    string? ErrorDetail,
    T? Data = default)
{
    public static ServiceResult<T> Ok(T data, int statusCode = 200) => new(true, statusCode, null, null, data);
    public static ServiceResult<T> Fail(int statusCode, string title, string detail) => new(false, statusCode, title, detail);
}

public sealed class AuthService
{
    private const int MaxFailedAttempts = 5;

    private readonly PedestalDbContext _db;
    private readonly IConfiguration _config;
    private readonly PasswordHasher<string> _passwordHasher = new();

    public AuthService(PedestalDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    public async Task<ServiceResult<AuthResponseDto>> RegisterAsync(RegisterRequestDto dto, CancellationToken ct = default)
    {
        var emailNorm = dto.Email.Trim().ToLowerInvariant();
        var usernameNorm = dto.Username.Trim();
        var usernameLower = usernameNorm.ToLowerInvariant();
        var docNorm = dto.DocumentNumber.Trim();

        var duplicateAccount = await _db.Accounts
            .Include(a => a.Person)
            .AnyAsync(a =>
                a.Active &&
                (
                    a.Username.ToLower() == usernameLower ||
                    (a.Person != null && a.Person.Email != null && a.Person.Email.ToLower() == emailNorm)
                ), ct);

        if (duplicateAccount)
        {
            return ServiceResult<AuthResponseDto>.Fail(
                409,
                "Conflicto de registro",
                "Ya existe una cuenta activa con ese correo electrónico o nombre de usuario.");
        }

        var personByDoc = await _db.People
            .FirstOrDefaultAsync(p => p.DocumentId != null && p.DocumentId == docNorm, ct);

        var personByEmail = await _db.People
            .FirstOrDefaultAsync(p => p.Email != null && p.Email.ToLower() == emailNorm, ct);

        if (personByDoc is not null && personByEmail is not null && personByDoc.Id != personByEmail.Id)
        {
            return ServiceResult<AuthResponseDto>.Fail(
                409,
                "Conflicto de identidad",
                "El documento y el correo pertenecen a registros de persona distintos.");
        }

        var person = personByDoc ?? personByEmail;

        if (person is not null)
        {
            var alreadyHasAccount = await _db.Accounts
                .AnyAsync(a => a.PersonId == person.Id && a.Active, ct);

            if (alreadyHasAccount)
            {
                return ServiceResult<AuthResponseDto>.Fail(
                    409,
                    "Conflicto de registro",
                    "La persona ya cuenta con una cuenta activa registrada.");
            }
        }

        var customerRole = await _db.Roles
            .FirstOrDefaultAsync(r => r.Name == "Customer" && r.Active, ct);

        if (customerRole is null)
        {
            return ServiceResult<AuthResponseDto>.Fail(
                409,
                "Rol no configurado",
                "No se encontró el rol 'Customer' activo.");
        }

        var now = DateTime.UtcNow;
        var committed = false;

        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            if (person is null)
            {
                person = new Person
                {
                    DocumentId = docNorm,
                    FirstName = dto.FirstName.Trim(),
                    MiddleName = string.IsNullOrWhiteSpace(dto.MiddleName) ? null : dto.MiddleName.Trim(),
                    FirstSurname = dto.FirstSurname.Trim(),
                    SecondSurname = string.IsNullOrWhiteSpace(dto.SecondSurname) ? null : dto.SecondSurname.Trim(),
                    Email = emailNorm,
                    RegistrationDate = now,
                    UpdatedAt = now,
                    Active = true
                };
                _db.People.Add(person);
                await _db.SaveChangesAsync(ct);
            }
            else
            {
                person.FirstName = dto.FirstName.Trim();
                person.MiddleName = string.IsNullOrWhiteSpace(dto.MiddleName) ? person.MiddleName : dto.MiddleName.Trim();
                person.FirstSurname = dto.FirstSurname.Trim();
                person.SecondSurname = string.IsNullOrWhiteSpace(dto.SecondSurname) ? person.SecondSurname : dto.SecondSurname.Trim();
                person.Email ??= emailNorm;
                person.DocumentId ??= docNorm;
                person.UpdatedAt = now;
                person.Active = true;
            }

            _db.Phones.Add(new Phone
            {
                Phone1 = dto.Phone.Trim(),
                RegistrationDate = now,
                Active = true,
                PersonId = person.Id
            });

            _db.Directions.Add(new Direction
            {
                Direction1 = dto.AddressLine.Trim(),
                City = dto.City.Trim(),
                DirectionType = "SHIPPING",
                IsDefault = true,
                RegistrationDate = now,
                Active = true,
                PersonId = person.Id
            });

            var account = new Account
            {
                PersonId = person.Id,
                Username = usernameNorm,
                PasswordHash = _passwordHasher.HashPassword(usernameNorm, dto.Password),
                IsLocked = false,
                FailedAttempts = 0,
                RegistrationDate = now,
                UpdatedAt = now,
                Active = true
            };
            _db.Accounts.Add(account);
            await _db.SaveChangesAsync(ct);

            _db.AccountRoles.Add(new AccountRole
            {
                AccountId = account.Id,
                RoleId = customerRole.Id,
                RegistrationDate = now
            });

            _db.Users.Add(new DbUser
            {
                PersonId = person.Id,
                RegistrationDate = now,
                UpdatedAt = now,
                Active = true
            });

            await _db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);
            committed = true;

            var sessionUser = await BuildSessionUserAsync(account.Id, ct);
            if (sessionUser is null)
            {
                return ServiceResult<AuthResponseDto>.Fail(500, "Error de sesión", "No se pudo construir la sesión del usuario.");
            }

            var (token, expiresAt) = GenerateJwt(sessionUser, rememberMe: false);

            return ServiceResult<AuthResponseDto>.Ok(new AuthResponseDto
            {
                Token = token,
                ExpiresAt = expiresAt,
                User = sessionUser
            }, StatusCodes.Status201Created);
        }
        catch
        {
            if (!committed)
            {
                await tx.RollbackAsync(ct);
            }
            throw;
        }
    }

    public async Task<ServiceResult<AuthResponseDto>> LoginAsync(LoginRequestDto dto, CancellationToken ct = default)
    {
        var identifier = dto.Identifier.Trim();
        var identifierLower = identifier.ToLowerInvariant();

        var account = await _db.Accounts
            .Include(a => a.Person)
            .FirstOrDefaultAsync(a =>
                a.Active &&
                (
                    a.Username.ToLower() == identifierLower ||
                    (a.Person != null && a.Person.Email != null && a.Person.Email.ToLower() == identifierLower)
                ), ct);

        if (account is null || string.IsNullOrWhiteSpace(account.PasswordHash))
        {
            return ServiceResult<AuthResponseDto>.Fail(401, "Credenciales inválidas", "Usuario o contraseña incorrectos.");
        }

        if (account.IsLocked)
        {
            return ServiceResult<AuthResponseDto>.Fail(
                403,
                "Cuenta bloqueada",
                "La cuenta está bloqueada por superar el máximo de intentos fallidos.");
        }

        var passwordOk = _passwordHasher.VerifyHashedPassword(
            account.Username,
            account.PasswordHash,
            dto.Password);

        if (passwordOk == PasswordVerificationResult.Failed)
        {
            var attempts = account.FailedAttempts + 1;
            account.FailedAttempts = attempts;
            account.UpdatedAt = DateTime.UtcNow;

            if (attempts >= MaxFailedAttempts)
            {
                account.IsLocked = true;
            }

            await _db.SaveChangesAsync(ct);
            return ServiceResult<AuthResponseDto>.Fail(401, "Credenciales inválidas", "Usuario o contraseña incorrectos.");
        }

        var now = DateTime.UtcNow;
        account.FailedAttempts = 0;
        account.LastLoginDate = now;
        account.UpdatedAt = now;

        var auditPayload = JsonSerializer.Serialize(new
        {
            accountId = account.Id,
            username = account.Username
        });

        _db.AuditLogs.Add(new AuditLog
        {
            TableName = nameof(Account),
            ActionType = "LOGIN",
            RecordId = account.Id.ToString(),
            OldValues = null,
            NewValues = auditPayload,
            AuditDate = now,
            AccountId = account.Id
        });

        await _db.SaveChangesAsync(ct);

        var sessionUser = await BuildSessionUserAsync(account.Id, ct);
        if (sessionUser is null)
        {
            return ServiceResult<AuthResponseDto>.Fail(401, "Sesión no válida", "No se pudo cargar la sesión.");
        }

        var (token, expiresAt) = GenerateJwt(sessionUser, dto.RememberMe);

        return ServiceResult<AuthResponseDto>.Ok(new AuthResponseDto
        {
            Token = token,
            ExpiresAt = expiresAt,
            User = sessionUser
        });
    }

    public async Task<ServiceResult<SessionUserDto>> GetMeAsync(int accountId, CancellationToken ct = default)
    {
        var sessionUser = await BuildSessionUserAsync(accountId, ct);
        if (sessionUser is null)
        {
            return ServiceResult<SessionUserDto>.Fail(404, "Cuenta no encontrada", "No existe una cuenta activa para la sesión.");
        }

        return ServiceResult<SessionUserDto>.Ok(sessionUser);
    }

    public async Task<ServiceResult<bool>> ChangePasswordAsync(int accountId, ChangePasswordDto dto, CancellationToken ct = default)
    {
        var account = await _db.Accounts
            .FirstOrDefaultAsync(a => a.Id == accountId && a.Active, ct);

        if (account is null || string.IsNullOrWhiteSpace(account.PasswordHash))
        {
            return ServiceResult<bool>.Fail(404, "Cuenta no encontrada", "No se encontró la cuenta activa.");
        }

        var currentValid = _passwordHasher.VerifyHashedPassword(
            account.Username,
            account.PasswordHash,
            dto.CurrentPassword);

        if (currentValid == PasswordVerificationResult.Failed)
        {
            return ServiceResult<bool>.Fail(400, "Contraseña actual incorrecta", "La contraseña actual no coincide.");
        }

        account.PasswordHash = _passwordHasher.HashPassword(account.Username, dto.NewPassword);
        account.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);
        return ServiceResult<bool>.Ok(true);
    }

    private async Task<SessionUserDto?> BuildSessionUserAsync(int accountId, CancellationToken ct)
    {
        var account = await _db.Accounts
            .Include(a => a.Person)
            .FirstOrDefaultAsync(a => a.Id == accountId && a.Active, ct);

        if (account?.Person is null)
            return null;

        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.PersonId == account.PersonId && u.Active, ct);

        var employee = await _db.Employees
            .FirstOrDefaultAsync(e => e.PersonId == account.PersonId && e.Active, ct);

        int? storeId = null;
        int? areaId = null;

        if (employee is not null)
        {
            var currentPosition = await _db.PositionHistorials
                .Where(ph => ph.EmployeeId == employee.Id && ph.LastDate == null && ph.Active)
                .OrderByDescending(ph => ph.Id)
                .FirstOrDefaultAsync(ct);

            if (currentPosition is not null)
            {
                storeId = currentPosition.StoreId;
                areaId = currentPosition.WorkAreaId;
            }
        }

        var roleIds = await _db.AccountRoles
            .Where(ar => ar.AccountId == account.Id)
            .Select(ar => ar.RoleId)
            .Distinct()
            .ToListAsync(ct);

        var roles = await _db.Roles
            .Where(r => roleIds.Contains(r.Id) && r.Active)
            .Select(r => r.Name)
            .Distinct()
            .ToListAsync(ct);

        var permissions = await _db.Roles
            .Where(r => roleIds.Contains(r.Id) && r.Active)
            .SelectMany(r => r.Permissions)
            .Select(p => p.Code)
            .Distinct()
            .ToListAsync(ct);

        return new SessionUserDto
        {
            AccountId = account.Id,
            UserId = user?.Id,
            EmployeeId = employee?.Id,
            Username = account.Username,
            Email = account.Person.Email ?? string.Empty,
            FirstName = account.Person.FirstName ?? string.Empty,
            FirstSurname = account.Person.FirstSurname ?? string.Empty,
            Roles = roles,
            Permissions = permissions,
            StoreId = storeId,
            AreaId = areaId,
            InitialRoute = ResolveInitialRoute(roles)
        };
    }

    private (string Token, DateTime ExpiresAt) GenerateJwt(SessionUserDto user, bool rememberMe)
    {
        var jwtSection = _config.GetSection("Jwt");
        var secretKey = jwtSection["Key"] ?? throw new InvalidOperationException("Falta Jwt:Key en User Secrets.");
        var issuer = jwtSection["Issuer"] ?? "PedestalApi";
        var audience = jwtSection["Audience"] ?? "PedestalClient";
        var hours = rememberMe
            ? jwtSection.GetValue<int?>("RememberMeHours") ?? 168
            : jwtSection.GetValue<int?>("ExpirationHours") ?? 8;

        var expiresAt = DateTime.UtcNow.AddHours(hours);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.AccountId.ToString()),
            new("accountId", user.AccountId.ToString()),
            new(JwtRegisteredClaimNames.UniqueName, user.Username),
            new(JwtRegisteredClaimNames.Email, user.Email)
        };

        if (user.UserId.HasValue) claims.Add(new Claim("userId", user.UserId.Value.ToString()));
        if (user.EmployeeId.HasValue) claims.Add(new Claim("employeeId", user.EmployeeId.Value.ToString()));
        if (user.StoreId.HasValue) claims.Add(new Claim("storeId", user.StoreId.Value.ToString()));
        if (user.AreaId.HasValue) claims.Add(new Claim("areaId", user.AreaId.Value.ToString()));

        foreach (var role in user.Roles)
            claims.Add(new Claim(ClaimTypes.Role, role));

        foreach (var permission in user.Permissions)
            claims.Add(new Claim("permission", permission));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: creds
        );

        return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
    }

    private static string ResolveInitialRoute(IReadOnlyCollection<string> roles)
    {
        if (roles.Contains("Admin")) return "/admin/roles";
        if (roles.Contains("NationalManager")) return "/dashboards/national";
        if (roles.Contains("AreaManager")) return "/dashboards/area";
        if (roles.Contains("StoreSupervisor") || roles.Contains("Staff")) return "/pos";
        return "/shop/catalog";
    }
}