using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pedestal.Api.Features.Auth.Dtos;

namespace Pedestal.Api.Features.Auth;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController : ControllerBase
{
    private readonly AuthService _authService;

    public AuthController(AuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Register([FromBody] RegisterRequestDto dto, CancellationToken ct)
    {
        var result = await _authService.RegisterAsync(dto, ct);
        return ToActionResult(result, StatusCodes.Status201Created);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto dto, CancellationToken ct)
    {
        var result = await _authService.LoginAsync(dto, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(typeof(SessionUserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Me(CancellationToken ct)
    {
        var accountId = GetCurrentAccountId();
        if (accountId is null)
            return Problem(statusCode: 401, title: "Sesión no válida", detail: "No se encontró el identificador de cuenta en el token.");

        var result = await _authService.GetMeAsync(accountId.Value, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpPost("change-password")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto, CancellationToken ct)
    {
        var accountId = GetCurrentAccountId();
        if (accountId is null)
            return Problem(statusCode: 401, title: "Sesión no válida", detail: "No se encontró el identificador de cuenta en el token.");

        var result = await _authService.ChangePasswordAsync(accountId.Value, dto, ct);
        if (!result.IsSuccess)
            return Problem(statusCode: result.StatusCode, title: result.ErrorTitle, detail: result.ErrorDetail);

        return NoContent();
    }

    private int? GetCurrentAccountId()
    {
        var raw = User.FindFirstValue("accountId") ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.TryParse(raw, out var id) ? id : null;
    }

    private IActionResult ToActionResult<T>(ServiceResult<T> result, int successStatus)
    {
        if (!result.IsSuccess)
            return Problem(statusCode: result.StatusCode, title: result.ErrorTitle, detail: result.ErrorDetail);

        return StatusCode(successStatus, result.Data);
    }
}